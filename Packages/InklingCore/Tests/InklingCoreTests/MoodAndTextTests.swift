import XCTest
@testable import InklingCore

final class MoodAndTextTests: XCTestCase {
    func testMoodClampsOutOfRangeValues() {
        XCTAssertEqual(Mood(clamping: 0), .rough)
        XCTAssertEqual(Mood(clamping: -4), .rough)
        XCTAssertEqual(Mood(clamping: 3), .okay)
        XCTAssertEqual(Mood(clamping: 9), .great)
    }

    func testSentimentMapsAcrossTheScale() {
        XCTAssertEqual(Mood(sentiment: -1), .rough)
        XCTAssertEqual(Mood(sentiment: -0.4), .low)
        XCTAssertEqual(Mood(sentiment: 0), .okay)
        XCTAssertEqual(Mood(sentiment: 0.4), .good)
        XCTAssertEqual(Mood(sentiment: 1), .great)
    }

    func testWordCountIgnoresPunctuationOnlyTokens() {
        XCTAssertEqual(TextStats.wordCount(""), 0)
        XCTAssertEqual(TextStats.wordCount("  \n "), 0)
        XCTAssertEqual(TextStats.wordCount("One two\nthree — four"), 4)
        XCTAssertEqual(TextStats.wordCount("It's 5 o'clock!"), 3)
    }

    func testReadingMinutes() {
        XCTAssertEqual(TextStats.readingMinutes(""), 0)
        XCTAssertEqual(TextStats.readingMinutes("short"), 1)
        XCTAssertEqual(TextStats.readingMinutes(Array(repeating: "word", count: 410).joined(separator: " ")), 2)
    }

    func testTitleUsesFirstNonEmptyLineAndTruncates() {
        XCTAssertEqual(TextStats.title("\n\n  Hello there \nsecond"), "Hello there")
        XCTAssertEqual(TextStats.title(""), "")
        let long = String(repeating: "a", count: 100)
        let title = TextStats.title(long, limit: 10)
        XCTAssertEqual(title, String(repeating: "a", count: 10) + "…")
    }
}
