import XCTest
@testable import InklingCore

final class StreakTests: XCTestCase {
    func testNoEntriesMeansNoStreak() {
        XCTAssertEqual(Streaks.current([], today: date(2026, 10, 14), calendar: cal), 0)
        XCTAssertEqual(Streaks.longest([], calendar: cal), 0)
    }

    func testStreakCountsConsecutiveDaysEndingToday() {
        let dates = [date(2026, 10, 14), date(2026, 10, 13), date(2026, 10, 12), date(2026, 10, 9)]
        XCTAssertEqual(Streaks.current(dates, today: date(2026, 10, 14), calendar: cal), 3)
    }

    func testStreakSurvivesUntilEndOfTodayIfYesterdayWasWritten() {
        let dates = [date(2026, 10, 13), date(2026, 10, 12)]
        XCTAssertEqual(Streaks.current(dates, today: date(2026, 10, 14), calendar: cal), 2)
    }

    func testStreakBreaksAfterAMissedDay() {
        let dates = [date(2026, 10, 12), date(2026, 10, 11)]
        XCTAssertEqual(Streaks.current(dates, today: date(2026, 10, 14), calendar: cal), 0)
    }

    func testSeveralEntriesInOneDayCountOnce() {
        let dates = [date(2026, 10, 14, hour: 8), date(2026, 10, 14, hour: 22), date(2026, 10, 13)]
        XCTAssertEqual(Streaks.current(dates, today: date(2026, 10, 14), calendar: cal), 2)
    }

    func testFutureEntriesDoNotInflateTheStreak() {
        let dates = [date(2026, 10, 16), date(2026, 10, 14)]
        XCTAssertEqual(Streaks.current(dates, today: date(2026, 10, 14), calendar: cal), 1)
    }

    func testLongestFindsTheBestRunAnywhere() {
        let dates = [date(2026, 9, 1), date(2026, 9, 2), date(2026, 9, 3), date(2026, 9, 4),
                     date(2026, 10, 13), date(2026, 10, 14)]
        XCTAssertEqual(Streaks.longest(dates, calendar: cal), 4)
    }

    func testStreakAcrossMonthAndYearBoundary() {
        let dates = [date(2027, 1, 1), date(2026, 12, 31), date(2026, 12, 30)]
        XCTAssertEqual(Streaks.current(dates, today: date(2027, 1, 1), calendar: cal), 3)
    }
}
