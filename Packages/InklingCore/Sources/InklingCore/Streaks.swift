import Foundation

public enum Streaks {
    /// Distinct calendar days, newest first.
    static func days(_ dates: [Date], calendar: Calendar) -> [Date] {
        Array(Set(dates.map { calendar.startOfDay(for: $0) })).sorted(by: >)
    }

    /// Consecutive days with at least one entry, ending today. If there is no entry yet today the streak is
    /// still alive when yesterday has one: you haven't missed the day, you just haven't written yet.
    public static func current(_ dates: [Date], today: Date = .now, calendar: Calendar = .current) -> Int {
        let days = days(dates, calendar: calendar)
        guard var cursor = days.first else { return 0 }
        let start = calendar.startOfDay(for: today)
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: start), cursor >= yesterday else {
            return 0
        }
        if cursor > start { cursor = start } // an entry dated in the future never counts extra
        var streak = 0
        for day in days where day <= start {
            guard day == cursor else { break }
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }

    public static func longest(_ dates: [Date], calendar: Calendar = .current) -> Int {
        let ascending = days(dates, calendar: calendar).reversed()
        var best = 0, run = 0
        var previous: Date?
        for day in ascending {
            if let previous, calendar.date(byAdding: .day, value: 1, to: previous) == day { run += 1 } else { run = 1 }
            best = max(best, run)
            previous = day
        }
        return best
    }
}
