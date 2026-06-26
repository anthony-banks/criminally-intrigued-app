import Foundation
import SwiftData

/// Owns the local catalog: seeds it from the bundle on first launch, serves it
/// to the UI, and refreshes from Wikimedia in the background when stale. The UI
/// never blocks on the network — it reads the local store, which is always
/// populated from the bundled seed (spec §6.4).
@MainActor
final class CatalogRepository {
    private let context: ModelContext
    private let wikidata: WikidataService
    private let wikipedia: WikipediaService

    /// Refresh the catalog if the newest row is older than this.
    private let maxAge: TimeInterval = 7 * 24 * 60 * 60

    init(context: ModelContext, wikidata: WikidataService, wikipedia: WikipediaService) {
        self.context = context
        self.wikidata = wikidata
        self.wikipedia = wikipedia
    }

    /// Called once on launch. Seeds from the bundle if empty, then kicks off a
    /// non-blocking background refresh when the catalog has gone stale.
    func bootstrap() async {
        syncSeed()
        if isStale {
            Task { await refresh() }
        }
    }

    private var isStale: Bool {
        var descriptor = FetchDescriptor<CaseEntry>(
            sortBy: [SortDescriptor(\.catalogUpdatedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        let newest = (try? context.fetch(descriptor))?.first?.catalogUpdatedAt ?? .distantPast
        return Date().timeIntervalSince(newest) > maxAge
    }

    // MARK: - Seed

    /// Inserts any bundled seed entries not already in the store. Runs every
    /// launch (not just the first) so adding rows to SeedCatalog.json shows up
    /// without wiping the app — existing entries, bookmarks, and cached bodies
    /// are left untouched.
    private func syncSeed() {
        guard
            let url = Bundle.main.url(forResource: "SeedCatalog", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let file = try? JSONDecoder().decode(SeedCatalogFile.self, from: data)
        else {
            assertionFailure("SeedCatalog.json missing or malformed")
            return
        }
        let now = Date()
        var inserted = 0
        for draft in file.entries.map({ $0.toDraft() }) {
            let id = draft.id
            let descriptor = FetchDescriptor<CaseEntry>(predicate: #Predicate { $0.id == id })
            let exists = ((try? context.fetchCount(descriptor)) ?? 0) > 0
            if !exists {
                insert(draft, updatedAt: now)
                inserted += 1
            }
        }
        if inserted > 0 { try? context.save() }
    }

    // MARK: - Background refresh (best-effort; never throws into the UI)

    func refresh() async {
        let now = Date()
        if let killers = try? await wikidata.fetchSerialKillers() {
            merge(killers, updatedAt: now)
        }
        try? context.save()
    }

    // MARK: - Merge

    private func merge(_ drafts: [CaseDraft], updatedAt: Date) {
        for draft in drafts { upsert(draft, updatedAt: updatedAt) }
    }

    private func upsert(_ draft: CaseDraft, updatedAt: Date) {
        let id = draft.id
        let descriptor = FetchDescriptor<CaseEntry>(predicate: #Predicate { $0.id == id })
        if let existing = try? context.fetch(descriptor).first {
            existing.title = draft.title
            existing.summary = draft.summary ?? existing.summary
            existing.articleURLString = draft.articleURLString
            existing.thumbnailURLString = draft.thumbnailURLString ?? existing.thumbnailURLString
            existing.victimCount = draft.victimCount ?? existing.victimCount
            existing.countryCode = draft.countryCode ?? existing.countryCode
            existing.countryName = draft.countryName ?? existing.countryName
            existing.startDate = draft.startDate ?? existing.startDate
            existing.catalogUpdatedAt = updatedAt
        } else {
            insert(draft, updatedAt: updatedAt)
        }
    }

    private func insert(_ draft: CaseDraft, updatedAt: Date) {
        let entry = CaseEntry(
            id: draft.id,
            title: draft.title,
            category: draft.category,
            summary: draft.summary,
            articleURLString: draft.articleURLString,
            thumbnailURLString: draft.thumbnailURLString,
            victimCount: draft.victimCount,
            countryCode: draft.countryCode,
            countryName: draft.countryName,
            startDate: draft.startDate,
            catalogUpdatedAt: updatedAt
        )
        context.insert(entry)
    }
}
