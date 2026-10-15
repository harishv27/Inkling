import SwiftData
import SwiftUI
import InklingCore

enum EditorTarget: Identifiable {
    case new(prompt: String?)
    case existing(JournalEntry)

    var id: String {
        switch self {
        case .new: "new"
        case .existing(let entry): entry.id.uuidString
        }
    }
}

struct JournalView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    @State private var search = ""
    @State private var target: EditorTarget?

    private var filtered: [JournalEntry] {
        entries.filter { Search.matches(query: search, text: $0.text, tags: $0.tags) }
    }

    private var months: [(start: Date, entries: [JournalEntry])] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: filtered) { calendar.dateInterval(of: .month, for: $0.createdAt)?.start ?? $0.createdAt }
        return groups.keys.sorted(by: >).map { ($0, groups[$0] ?? []) }
    }

    private var wroteToday: Bool { entries.contains { Calendar.current.isDateInToday($0.createdAt) } }
    private var memories: [JournalEntry] {
        let hits = Set(Trends.onThisDay(entries.map(\.createdAt)))
        return entries.filter { hits.contains($0.createdAt) }
    }

    var body: some View {
        NavigationStack {
            List {
                if search.isEmpty {
                    Section {
                        PromptCard(wroteToday: wroteToday) { prompt in target = .new(prompt: prompt) }
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                    }
                    if !memories.isEmpty {
                        Section("On this day") {
                            ForEach(memories) { entry in
                                Button { target = .existing(entry) } label: { EntryRow(entry: entry, showYear: true) }
                                    .buttonStyle(.plain)
                            }
                        }
                    }
                }
                ForEach(months, id: \.start) { month in
                    Section(month.start.formatted(.dateTime.month(.wide).year())) {
                        ForEach(month.entries) { entry in
                            Button { target = .existing(entry) } label: { EntryRow(entry: entry) }
                                .buttonStyle(.plain)
                                .swipeActions {
                                    Button(role: .destructive) { context.delete(entry) } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
                if filtered.isEmpty && !search.isEmpty {
                    ContentUnavailableView.search(text: search)
                        .listRowBackground(Color.clear)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Journal")
            .searchable(text: $search, prompt: "Search entries and tags")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { target = .new(prompt: nil) } label: { Label("New entry", systemImage: "square.and.pencil") }
                }
            }
            .overlay {
                if entries.isEmpty { EmptyJournal { target = .new(prompt: nil) } }
            }
            .sheet(item: $target) { target in
                EntryEditorView(target: target)
            }
            .onChange(of: Router.shared.composeRequested) { _, requested in
                if requested { target = .new(prompt: nil); Router.shared.composeRequested = false }
            }
        }
    }
}

private struct PromptCard: View {
    let wroteToday: Bool
    let onWrite: (String) -> Void
    private let prompt = Prompts.forDay()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(wroteToday ? "Today's prompt" : "Write something today", systemImage: "sparkle")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tint)
            Text(prompt)
                .font(.system(.title3, design: .serif))
                .fixedSize(horizontal: false, vertical: true)
            Button { onWrite(prompt) } label: {
                Text("Write about this").font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .card()
    }
}

private struct EmptyJournal: View {
    let onWrite: () -> Void
    var body: some View {
        ContentUnavailableView {
            Label("A blank page", systemImage: "book.closed")
        } description: {
            Text("Write a few lines. Inkling summarises them privately, on this iPhone.")
        } actions: {
            Button("Write the first entry", action: onWrite).buttonStyle(.borderedProminent)
        }
        .background(Theme.background)
    }
}

struct EntryRow: View {
    @Environment(InsightEngine.self) private var engine
    let entry: JournalEntry
    var showYear = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(entry.title.isEmpty ? "Empty entry" : entry.title)
                    .font(.headline)
                    .lineLimit(1)
                Spacer(minLength: 8)
                if let mood = entry.mood {
                    Image(systemName: mood.symbol)
                        .foregroundStyle(mood.color)
                        .accessibilityLabel("Mood: \(mood.label)")
                }
            }
            summaryLine
            HStack(spacing: 6) {
                Text(entry.createdAt.formatted(showYear ? .dateTime.year().month().day() : .dateTime.weekday(.abbreviated).day().month(.abbreviated)))
                    .font(.caption).foregroundStyle(.secondary)
                ForEach(entry.tags.prefix(3), id: \.self) { TagChip(tag: $0) }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    @ViewBuilder private var summaryLine: some View {
        if engine.analyzing.contains(entry.id) {
            HStack(spacing: 6) {
                ProgressView().controlSize(.small)
                Text("Reflecting…").font(.subheadline).foregroundStyle(.secondary)
            }
        } else if let summary = entry.summary, !summary.isEmpty {
            Text(summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        } else {
            Text(entry.text.dropFirst(entry.title.count).trimmingCharacters(in: .whitespacesAndNewlines))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
    }
}
