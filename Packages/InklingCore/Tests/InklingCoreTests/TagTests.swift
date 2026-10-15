import XCTest
@testable import InklingCore

final class TagTests: XCTestCase {
    func testNormalizeCleansAndDeduplicates() {
        let tags = Tags.normalize(["#Work", " work ", "Deep Thoughts", "##Café!", "", "   "])
        XCTAssertEqual(tags, ["work", "deep-thoughts", "café"])
    }

    func testNormalizeKeepsOrderAndLimit() {
        let tags = Tags.normalize(["a1", "b2", "c3", "d4", "e5", "f6", "g7"])
        XCTAssertEqual(tags, ["a1", "b2", "c3", "d4", "e5"])
        XCTAssertEqual(Tags.normalize(["a1", "b2", "c3"], limit: 2), ["a1", "b2"])
    }

    func testRankedCountsEachEntryOnceAndBreaksTiesAlphabetically() {
        let ranked = Tags.ranked([["run", "run", "sleep"], ["run", "work"], ["sleep"], ["work"]])
        XCTAssertEqual(ranked.map(\.tag), ["run", "sleep", "work"])
        XCTAssertEqual(ranked.map(\.count), [2, 2, 2])
    }

    func testKeywordTaggerPicksRepeatedMeaningfulWords() {
        let text = "Running felt great. I love running before work, and work was calm. Running again tomorrow."
        XCTAssertEqual(KeywordTagger.tags(from: text, limit: 2), ["running", "work"])
    }

    func testKeywordTaggerIgnoresStopWordsAndShortWords() {
        XCTAssertEqual(KeywordTagger.tags(from: "the and with was it is to of"), [])
        XCTAssertEqual(KeywordTagger.tags(from: ""), [])
    }
}
