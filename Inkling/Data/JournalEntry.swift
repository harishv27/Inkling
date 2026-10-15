import Foundation
import SwiftData
import InklingCore

enum InsightSource: String, Codable {
    case none, appleIntelligence, basic
}

@Model
final class JournalEntry {
    var id: UUID = UUID()
    var createdAt: Date = Date.now
    /// Changes only when the words change, so we know when the AI summary is out of date.
    var updatedAt: Date = Date.now
    var text: String = ""
    /// 0 means "no mood yet"; 1...5 is a `Mood` raw value.
    var moodValue: Int = 0
    var tags: [String] = []
    var summary: String?
    var insightSourceRaw: String = InsightSource.none.rawValue
    var analyzedAt: Date?
    /// When the person picks a mood or edits the tags themselves, the AI must not overwrite them.
    var moodIsManual: Bool = false
    var tagsAreManual: Bool = false

    init(text: String, createdAt: Date = .now) {
        self.text = text
        self.createdAt = createdAt
        self.updatedAt = createdAt
    }

    var mood: Mood? {
        get { Mood(rawValue: moodValue) }
        set { moodValue = newValue?.rawValue ?? 0 }
    }

    var insightSource: InsightSource {
        get { InsightSource(rawValue: insightSourceRaw) ?? .none }
        set { insightSourceRaw = newValue.rawValue }
    }

    var wordCount: Int { TextStats.wordCount(text) }
    var title: String { TextStats.title(text) }
    var needsAnalysis: Bool { wordCount >= 12 && (analyzedAt ?? .distantPast) < updatedAt }

    var exportEntry: ExportEntry {
        ExportEntry(date: createdAt, text: text, mood: mood?.rawValue, tags: tags, summary: summary)
    }
}
