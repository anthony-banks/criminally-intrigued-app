import Foundation
import SwiftData

/// The single persisted domain model. Backs every list row, the detail view,
/// bookmarks, and the offline article cache. Filtering/sorting/search all run
/// against these fields locally — nothing here requires a network round-trip.
@Model
final class CaseEntry {
    /// Wikidata QID when present, else "enwiki:{title}". Stable identity for merges.
    @Attribute(.unique) var id: String
    var title: String
    /// Stored as Category.rawValue; see `category` accessor.
    var categoryRaw: String

    var summary: String?
    /// Full plain-text article. nil until first opened, cached permanently after.
    var body: String?
    var bodyFetchedAt: Date?

    var articleURLString: String
    var thumbnailURLString: String?

    /// nil when unknown — never coerce to 0 (see spec §7).
    var victimCount: Int?
    var countryCode: String?
    var countryName: String?

    /// Unified chronological sort key (date of death, or case date).
    var startDate: Date?

    var isBookmarked: Bool
    var lastViewedAt: Date?
    var catalogUpdatedAt: Date

    init(
        id: String,
        title: String,
        category: Category,
        summary: String? = nil,
        body: String? = nil,
        bodyFetchedAt: Date? = nil,
        articleURLString: String,
        thumbnailURLString: String? = nil,
        victimCount: Int? = nil,
        countryCode: String? = nil,
        countryName: String? = nil,
        startDate: Date? = nil,
        isBookmarked: Bool = false,
        lastViewedAt: Date? = nil,
        catalogUpdatedAt: Date = .distantPast
    ) {
        self.id = id
        self.title = title
        self.categoryRaw = category.rawValue
        self.summary = summary
        self.body = body
        self.bodyFetchedAt = bodyFetchedAt
        self.articleURLString = articleURLString
        self.thumbnailURLString = thumbnailURLString
        self.victimCount = victimCount
        self.countryCode = countryCode
        self.countryName = countryName
        self.startDate = startDate
        self.isBookmarked = isBookmarked
        self.lastViewedAt = lastViewedAt
        self.catalogUpdatedAt = catalogUpdatedAt
    }

    var category: Category {
        get { Category(rawValue: categoryRaw) ?? .strange }
        set { categoryRaw = newValue.rawValue }
    }

    var articleURL: URL? { URL(string: articleURLString) }
    var thumbnailURL: URL? { thumbnailURLString.flatMap(URL.init(string:)) }

    /// True once the full body has been fetched and cached for offline reading.
    var hasCachedBody: Bool { (body?.isEmpty == false) }
}
