import XCTest
@testable import InklingCore

final class TrendTests: XCTestCase {
    func testDailyMoodAveragesSameDayAndSortsOldestFirst() {
        let samples = [(date(2026, 10, 14, hour: 9), 4), (date(2026, 10, 14, hour: 20), 2), (date(2026, 10, 12), 5)]
        let points = Trends.dailyMood(samples, days: 7, today: date(2026, 10, 14), calendar: cal)
        XCTAssertEqual(points.map(\.average), [5, 3])
        XCTAssertLessThan(points[0].day, points[1].day)
    }

    func testDailyMoodDropsEntriesOutsideTheWindow() {
        let samples = [(date(2026, 9, 1), 1), (date(2026, 10, 14), 4), (date(2026, 10, 20), 1)]
        let points = Trends.dailyMood(samples, days: 7, today: date(2026, 10, 14), calendar: cal)
        XCTAssertEqual(points.count, 1)
        XCTAssertEqual(points.first?.average, 4)
    }

    func testAverageMood() {
        XCTAssertNil(Trends.averageMood([]))
        let points = [DayMood(day: date(2026, 10, 1), average: 2), DayMood(day: date(2026, 10, 2), average: 4)]
        XCTAssertEqual(Trends.averageMood(points), 3)
    }

    func testWeeklyWordsFillsEmptyWeeksAndSumsEntries() {
        // 14 Oct 2026 is a Wednesday; weeks start on Monday (12 Oct).
        let samples = [(date(2026, 10, 14), 100), (date(2026, 10, 12), 50), (date(2026, 10, 1), 30)]
        let weeks = Trends.weeklyWords(samples, weeks: 3, today: date(2026, 10, 14), calendar: cal)
        XCTAssertEqual(weeks.count, 3)
        // 1 Oct is a Thursday, so it belongs to the week starting 28 Sep; the week of 5 Oct is empty.
        XCTAssertEqual(weeks.map(\.words), [30, 0, 150])
        XCTAssertEqual(weeks.last?.words, 150)
        XCTAssertEqual(weeks.last?.weekStart, date(2026, 10, 12, hour: 0))
    }

    func testOnThisDayOnlyReturnsEarlierYears() {
        let dates = [date(2025, 10, 14), date(2024, 10, 14), date(2026, 10, 14), date(2025, 10, 15), date(2025, 11, 14)]
        let hits = Trends.onThisDay(dates, today: date(2026, 10, 14), calendar: cal)
        XCTAssertEqual(hits, [date(2025, 10, 14), date(2024, 10, 14)])
    }
}
