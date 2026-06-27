import XCTest
@testable import CriminallyIntrigued

/// Offline, deterministic checks on the core value types — the decoding,
/// enums, and predicates every screen depends on. No network, no SwiftData.
final class ModelTests: XCTestCase {

    // MARK: - Category

    func testCategoryHasThreeCasesWithStableRawValues() {
        XCTAssertEqual(Category.allCases.count, 3)
        XCTAssertEqual(Set(Category.allCases.map(\.rawValue)),
                       ["serialKiller", "coldCase", "strange"])
    }

    func testCategoryRawValueRoundTrips() {
        for category in Category.allCases {
            XCTAssertEqual(Category(rawValue: category.rawValue), category)
        }
    }

    func testEveryCategoryHasTitleAndSymbol() {
        for category in Category.allCases {
            XCTAssertFalse(category.title.isEmpty, "\(category) missing title")
            XCTAssertFalse(category.symbolName.isEmpty, "\(category) missing SF Symbol")
        }
    }

    // MARK: - Seed decoding

    func testSeedEntryDecodesAndMapsToDraft() throws {
        let json = """
        {
          "id": "enwiki:Ted_Bundy",
          "title": "Ted Bundy",
          "category": "serialKiller",
          "articleURL": "https://en.wikipedia.org/wiki/Ted_Bundy",
          "victimCount": 30,
          "countryCode": "US",
          "countryName": "United States",
          "startDate": "1989-01-24"
        }
        """.data(using: .utf8)!

        let entry = try JSONDecoder().decode(SeedEntry.self, from: json)
        XCTAssertEqual(entry.title, "Ted Bundy")
        XCTAssertEqual(entry.category, .serialKiller)

        let draft = entry.toDraft()
        XCTAssertEqual(draft.id, "enwiki:Ted_Bundy")
        XCTAssertEqual(draft.articleURLString, "https://en.wikipedia.org/wiki/Ted_Bundy")
        XCTAssertEqual(draft.victimCount, 30)
        XCTAssertNotNil(draft.startDate)
    }

    func testSeedEntryToleratesMissingOptionalFields() throws {
        let json = """
        { "id": "enwiki:Cipher", "title": "Cipher case", "category": "strange",
          "articleURL": "https://en.wikipedia.org/wiki/Cipher" }
        """.data(using: .utf8)!

        let draft = try JSONDecoder().decode(SeedEntry.self, from: json).toDraft()
        XCTAssertNil(draft.victimCount)
        XCTAssertNil(draft.countryName)
        XCTAssertNil(draft.startDate, "missing date must stay nil, never a default")
    }

    // MARK: - Date parsing

    func testParseDateHandlesFullDatesYearsAndJunk() {
        XCTAssertNotNil(SeedEntry.parseDate("1978-12-11"), "full ISO date should parse")
        XCTAssertNotNil(SeedEntry.parseDate("1978"), "year-only should fall back to Jan 1")
        XCTAssertNil(SeedEntry.parseDate(nil))
        XCTAssertNil(SeedEntry.parseDate(""))
        XCTAssertNil(SeedEntry.parseDate("not-a-date"))
    }

    func testParseDateYearOnlyLandsOnJanuaryFirst() throws {
        let date = try XCTUnwrap(SeedEntry.parseDate("1994"))
        let comps = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: date)
        XCTAssertEqual(comps.year, 1994)
        XCTAssertEqual(comps.month, 1)
        XCTAssertEqual(comps.day, 1)
    }

    // MARK: - WikiSummary.isUsable (the weed-out predicate)

    private func summary(type: String?, extract: String?) throws -> WikiSummary {
        var fields = ["\"title\": \"X\""]
        if let type { fields.append("\"type\": \"\(type)\"") }
        if let extract { fields.append("\"extract\": \"\(extract)\"") }
        let data = "{ \(fields.joined(separator: ", ")) }".data(using: .utf8)!
        return try JSONDecoder().decode(WikiSummary.self, from: data)
    }

    func testUsableSummaryWithRealExtract() throws {
        let s = try summary(type: "standard", extract: "An American serial killer active in the 1970s.")
        XCTAssertTrue(s.isUsable)
    }

    func testTitleOnlySummaryIsNotUsable() throws {
        XCTAssertFalse(try summary(type: "standard", extract: nil).isUsable)
        XCTAssertFalse(try summary(type: "standard", extract: "   ").isUsable)
    }

    func testDisambiguationAndNoExtractAreNotUsable() throws {
        XCTAssertFalse(try summary(type: "disambiguation", extract: "Could refer to several people.").isUsable)
        XCTAssertFalse(try summary(type: "no-extract", extract: nil).isUsable)
    }

    func testVeryShortExtractIsNotUsable() throws {
        XCTAssertFalse(try summary(type: "standard", extract: "A killer.").isUsable,
                       "extract under the minimum length should be treated as title-only")
    }
}
