import XCTest
@testable import InklingCore

final class SearchPromptExportTests: XCTestCase {
    func testEmptyQueryMatchesEverything() {
        XCTAssertTrue(Search.matches(query: "  ", text: "anything"))
    }

    func testAllWordsMustMatchIgnoringCaseAndAccents() {
        XCTAssertTrue(Search.matches(query: "cafe MORNING", text: "A quiet morning at the Café"))
        XCTAssertFalse(Search.matches(query: "cafe evening", text: "A quiet morning at the Café"))
    }

    func testSearchAlsoLooksInTags() {
        XCTAssertTrue(Search.matches(query: "running", text: "Felt good", tags: ["running"]))
    }

    func testPromptIsStablePerDayAndChangesNextDay() {
        let today = date(2026, 10, 14)
        XCTAssertEqual(Prompts.forDay(today, calendar: cal), Prompts.forDay(date(2026, 10, 14, hour: 23), calendar: cal))
        XCTAssertNotEqual(Prompts.forDay(today, calendar: cal), Prompts.forDay(date(2026, 10, 15), calendar: cal))
    }

    func testNoRepeatedPromptsAndNoEmptyOnes() {
        XCTAssertEqual(Set(Prompts.all).count, Prompts.all.count)
        XCTAssertFalse(Prompts.all.contains { $0.isEmpty })
    }

    func testExportGroupsByMonthNewestFirst() {
        let md = MarkdownExporter.export([
            ExportEntry(date: date(2026, 9, 3), text: "September note"),
            ExportEntry(date: date(2026, 10, 14), text: "Today\n", mood: 4, tags: ["work", "calm"], summary: "A calm day."),
            ExportEntry(date: date(2026, 10, 2), text: "Early October"),
        ], calendar: cal)
        let october = md.range(of: "## October 2026")!.lowerBound
        let september = md.range(of: "## September 2026")!.lowerBound
        XCTAssertLessThan(october, september)
        XCTAssertLessThan(md.range(of: "Early October")!.lowerBound, md.range(of: "Today")!.lowerBound)
        XCTAssertTrue(md.contains("*Mood: Good · #work #calm*"))
        XCTAssertTrue(md.contains("> A calm day."))
        XCTAssertTrue(md.contains("3 entries"))
    }

    func testExportOfNothingIsStillValid() {
        XCTAssertTrue(MarkdownExporter.export([], calendar: cal).contains("No entries yet."))
    }
}
