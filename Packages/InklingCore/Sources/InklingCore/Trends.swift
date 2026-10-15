import Foundation

public struct DayMood: Equatable, Sendable, Identifiable {
    public let day: Date
    public let average: Double
    public var id: Date { day }
}

public struct WeekWords: Equatable, Sendable, Identifiable {
    public let weekStart: Date
    public let words: Int
    public var id: Date { weekStart }
}

public enum Trends {
    /// One point per day that has at least one mood, averaged when there are several, oldest first.
    /// Only the last `days` days up to and including `today` are returned.
    public static func dailyMood(
        _ samples: [(date: Date, mood: Int)], days: Int = 30, today: Date = .now, calendar: Calendar = .current
    ) -> [DayMood] {
        let end = calendar.startOfDay(for: today)
        guard let start = calendar.date(byAdding: .day, value: -(days - 1), to: end) else { return [] }
        var buckets: [Date: [Int]] = [:]
        for sample in samples {
            let day = calendar.startOfDay(for: sample.date)
            if day >= start && day <= end { buckets[day, default: []].append(sample.mood) }
        }
        return buckets
            .map { DayMood(day: $0.key, average: Double($0.value.reduce(0, +)) / Double($0.value.count)) }
            .sorted { $0.day < $1.day }
    }

    public static func averageMood(_ points: [DayMood]) -> Double? {
        points.isEmpty ? nil : points.map(\.average).reduce(0, +) / Double(points.count)
    }

    /// Words written per calendar week for the last `weeks` weeks, including weeks with nothing written.
    public static func weeklyWords(
        _ samples: [(date: Date, words: Int)], weeks: Int = 8, today: Date = .now, calendar: Calendar = .current
    ) -> [WeekWords] {
        guard let thisWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start else { return [] }
        let starts = (0..<weeks).reversed().compactMap { calendar.date(byAdding: .weekOfYear, value: -$0, to: thisWeek) }
        var totals: [Date: Int] = [:]
        for sample in samples {
            guard let start = calendar.dateInterval(of: .weekOfYear, for: sample.date)?.start else { continue }
            totals[start, default: 0] += sample.words
        }
        return starts.map { WeekWords(weekStart: $0, words: totals[$0] ?? 0) }
    }

    /// Dates from earlier years that fall on today's month and day, newest year first.
    public static func onThisDay(_ dates: [Date], today: Date = .now, calendar: Calendar = .current) -> [Date] {
        let now = calendar.dateComponents([.year, .month, .day], from: today)
        return dates
            .filter {
                let c = calendar.dateComponents([.year, .month, .day], from: $0)
                return c.month == now.month && c.day == now.day && (c.year ?? 0) < (now.year ?? 0)
            }
            .sorted(by: >)
    }
}
