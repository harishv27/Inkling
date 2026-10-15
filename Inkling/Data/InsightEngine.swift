import Foundation
import FoundationModels
import NaturalLanguage
import Observation
import SwiftData
import InklingCore

struct EntryInsight: Sendable {
    var summary: String
    var mood: Mood
    var tags: [String]
    var source: InsightSource
}

/// What the on-device model is asked to produce. `@Generable` makes it return this struct directly
/// instead of text we would have to parse.
@Generable
struct GeneratedInsight {
    @Guide(description: "One or two plain sentences saying what the entry is about, in a neutral voice")
    var summary: String
    @Guide(description: "How the writer felt overall, from 1 (rough) to 5 (great)", .range(1...5))
    var mood: Int
    @Guide(description: "Short lowercase topic tags, one or two words each", .maximumCount(4))
    var tags: [String]
}

@Generable
struct GeneratedReflection {
    @Guide(description: "Two short, kind, open questions that help the writer think further", .count(2))
    var questions: [String]
}

/// Turns journal text into a summary, a mood and tags. Uses Apple's on-device model when it is available and
/// a simple NaturalLanguage fallback when it is not, so the app works the same on every iPhone.
/// Nothing here ever touches the network.
@MainActor @Observable
final class InsightEngine {
    private(set) var availability: SystemLanguageModel.Availability
    private(set) var analyzing: Set<UUID> = []

    init() { availability = SystemLanguageModel.default.availability }

    var isAIAvailable: Bool {
        if case .available = availability { return true }
        return false
    }

    func refresh() { availability = SystemLanguageModel.default.availability }

    var statusTitle: String { isAIAvailable ? "Apple Intelligence" : "Basic on-device" }

    var statusDetail: String {
        switch availability {
        case .available:
            return "Summaries, moods and tags are written by Apple's on-device model. Your entries never leave this iPhone."
        case .unavailable(.deviceNotEligible):
            return "This iPhone can't run Apple Intelligence, so Inkling uses a simpler on-device method for summaries and moods."
        case .unavailable(.appleIntelligenceNotEnabled):
            return "Turn on Apple Intelligence in Settings for richer summaries. Until then Inkling uses a simpler on-device method."
        case .unavailable(.modelNotReady):
            return "The language model is still getting ready. Inkling uses a simpler method until it is."
        case .unavailable:
            return "The language model isn't available right now, so Inkling uses a simpler on-device method."
        }
    }

    // MARK: Analysis

    /// Analyses an entry in the background and writes the result back. Safe to call from a view that is about
    /// to go away: the engine outlives it.
    func analyze(_ entry: JournalEntry, in context: ModelContext) {
        guard entry.needsAnalysis, !analyzing.contains(entry.id) else { return }
        let id = entry.id
        let text = entry.text
        let stamp = entry.updatedAt
        analyzing.insert(id)
        Task {
            let insight = await insight(for: text)
            analyzing.remove(id)
            // The text may have been edited again while the model was thinking. Then this result is stale
            // and the newer save will have started its own analysis.
            guard entry.updatedAt == stamp else { return }
            entry.summary = insight.summary
            if !entry.moodIsManual { entry.mood = insight.mood }
            if !entry.tagsAreManual { entry.tags = insight.tags }
            entry.insightSource = insight.source
            entry.analyzedAt = .now
            try? context.save()
        }
    }

    /// Never throws: any model failure (guardrails, context size, not ready) falls back to the basic method.
    func insight(for text: String) async -> EntryInsight {
        guard isAIAvailable else { return Self.basicInsight(for: text) }
        do {
            let session = LanguageModelSession(instructions: """
                You read private journal entries and summarise them in one or two short sentences. \
                Start straight with what happened, like a diary headline: "Finished a first draft and felt proud." \
                Never say "the writer", "the author" or "the user". Never give advice. \
                Judge the mood only from what is said about feelings.
                """)
            let response = try await session.respond(to: "Journal entry:\n\(Self.clip(text))", generating: GeneratedInsight.self)
            let g = response.content
            let summary = g.summary.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !summary.isEmpty else { return Self.basicInsight(for: text) }
            return EntryInsight(
                summary: summary,
                mood: Mood(clamping: g.mood),
                tags: Tags.normalize(g.tags, limit: 4),
                source: .appleIntelligence
            )
        } catch {
            return Self.basicInsight(for: text)
        }
    }

    /// Two gentle follow-up questions. Only offered when the real model is available, because the fallback
    /// can't write good ones.
    func reflections(for text: String) async throws -> [String] {
        let session = LanguageModelSession(instructions: """
            You are a thoughtful, kind journaling companion. Ask open questions that help the writer go deeper. \
            Do not give advice, diagnose, or judge.
            """)
        let response = try await session.respond(to: "Journal entry:\n\(Self.clip(text))", generating: GeneratedReflection.self)
        return response.content.questions
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    // MARK: Fallback

    /// The model has a small context window, so very long entries are cut. The start and end carry the most.
    nonisolated static func clip(_ text: String, limit: Int = 6000) -> String {
        guard text.count > limit else { return text }
        return String(text.prefix(limit / 2)) + "\n…\n" + String(text.suffix(limit / 2))
    }

    nonisolated static func basicInsight(for text: String) -> EntryInsight {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text
        var scores: [Double] = []
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .paragraph, scheme: .sentimentScore, options: []) { tag, _ in
            if let raw = tag?.rawValue, let value = Double(raw) { scores.append(value) }
            return true
        }
        let average = scores.isEmpty ? 0 : scores.reduce(0, +) / Double(scores.count)

        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text
        var sentences: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let sentence = text[range].trimmingCharacters(in: .whitespacesAndNewlines)
            if !sentence.isEmpty { sentences.append(sentence) }
            return sentences.count < 2
        }
        var summary = sentences.joined(separator: " ")
        if summary.count > 160 { summary = String(summary.prefix(160)).trimmingCharacters(in: .whitespaces) + "…" }

        return EntryInsight(
            summary: summary,
            mood: Mood(sentiment: average),
            tags: KeywordTagger.tags(from: text, limit: 3),
            source: .basic
        )
    }
}
