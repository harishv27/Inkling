import Foundation

public struct ExportEntry: Sendable {
    public var date: Date
    public var text: String
    public var mood: Int?
    public var tags: [String]
    public var summary: String?

    public init(date: Date, text: String, mood: Int? = nil, tags: [String] = [], summary: String? = nil) {
        self.date = date; self.text = text; self.mood = mood; self.tags = tags; self.summary = summary
    }
}

public enum MarkdownExporter {
    /// A plain Markdown file, newest month first, entries in date order inside each month.
    /// Readable anywhere, and nothing in it depends on the app.
    public static func export(
        _ entries: [ExportEntry], calendar: Calendar = .current, locale: Locale = Locale(identifier: "en_US_POSIX")
    ) -> String {
        guard !entries.isEmpty else { return "# Inkling journal\n\nNo entries yet.\n" }
        let monthFormat = Date.FormatStyle(locale: locale, calendar: calendar, timeZone: calendar.timeZone)
            .month(.wide).year()
        let dayFormat = Date.FormatStyle(locale: locale, calendar: calendar, timeZone: calendar.timeZone)
            .weekday(.wide).day().month(.wide).year()

        let byMonth = Dictionary(grouping: entries) { calendar.dateInterval(of: .month, for: $0.date)?.start ?? $0.date }
        var out = "# Inkling journal\n\n\(entries.count) \(entries.count == 1 ? "entry" : "entries")\n"
        for month in byMonth.keys.sorted(by: >) {
            out += "\n## \(month.formatted(monthFormat))\n"
            for entry in byMonth[month, default: []].sorted(by: { $0.date < $1.date }) {
                out += "\n### \(entry.date.formatted(dayFormat))\n\n"
                var meta: [String] = []
                if let mood = entry.mood { meta.append("Mood: \(Mood(clamping: mood).label)") }
                if !entry.tags.isEmpty { meta.append(entry.tags.map { "#\($0)" }.joined(separator: " ")) }
                if !meta.isEmpty { out += "*\(meta.joined(separator: " · "))*\n\n" }
                if let summary = entry.summary, !summary.isEmpty { out += "> \(summary)\n\n" }
                out += entry.text.trimmingCharacters(in: .whitespacesAndNewlines) + "\n"
            }
        }
        return out
    }
}
