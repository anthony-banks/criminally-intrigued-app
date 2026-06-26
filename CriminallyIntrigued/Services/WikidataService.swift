import Foundation

/// Talks to the Wikidata Query Service (SPARQL) to build the structured
/// Serial Killers catalog: victims, country, and dates as clean fields
/// (spec §6.1). [VERIFY] the QIDs/PIDs with a one-off live query before relying
/// on the data — they drift rarely but do change.
struct WikidataService: Sendable {
    let http: HTTPClient

    private static let endpoint = "https://query.wikidata.org/sparql"

    /// occupation = serial killer (Q484188); victims P1345; country P27;
    /// birth P569; death P570; image P18. Only rows with an enwiki article enter.
    private static let serialKillersQuery = """
    SELECT ?person ?personLabel ?victims ?countryLabel ?birth ?death ?image ?article WHERE {
      ?person wdt:P106 wd:Q484188 .
      OPTIONAL { ?person wdt:P1345 ?victims . }
      OPTIONAL { ?person wdt:P27 ?country . }
      OPTIONAL { ?person wdt:P569 ?birth . }
      OPTIONAL { ?person wdt:P570 ?death . }
      OPTIONAL { ?person wdt:P18 ?image . }
      ?article schema:about ?person ;
               schema:isPartOf <https://en.wikipedia.org/> .
      SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
    }
    LIMIT 1500
    """

    func fetchSerialKillers() async throws -> [CaseDraft] {
        guard var components = URLComponents(string: Self.endpoint) else { throw HTTPError.badURL }
        components.queryItems = [
            URLQueryItem(name: "query", value: Self.serialKillersQuery),
            URLQueryItem(name: "format", value: "json"),
        ]
        guard let url = components.url else { throw HTTPError.badURL }

        let response = try await http.getJSON(SPARQLResponse.self, url: url)
        var drafts: [String: CaseDraft] = [:]

        for binding in response.results.bindings {
            guard
                let articleURL = binding["article"]?.value,
                let title = binding["personLabel"]?.value,
                !title.isEmpty
            else { continue }

            // Prefer the QID as identity; fall back to the article title.
            let qid = binding["person"]?.value.components(separatedBy: "/").last
            let id = (qid?.isEmpty == false) ? "wd:\(qid!)" : "enwiki:\(title)"

            let victimsString = binding["victims"]?.value
            let victims = victimsString.flatMap { Double($0) }.map { Int($0) }
            let country = binding["countryLabel"]?.value
            let death = Self.parseWikidataDate(binding["death"]?.value)
            let birth = Self.parseWikidataDate(binding["birth"]?.value)

            let draft = CaseDraft(
                id: id,
                title: title,
                category: .serialKiller,
                summary: nil,
                articleURLString: articleURL,
                thumbnailURLString: binding["image"]?.value,
                victimCount: victims,
                countryCode: nil,
                countryName: country,
                startDate: death ?? birth
            )
            // De-dupe; keep the richer record (more non-nil fields).
            if let existing = drafts[id], Self.richness(existing) >= Self.richness(draft) {
                continue
            }
            drafts[id] = draft
        }
        return Array(drafts.values)
    }

    private static func richness(_ d: CaseDraft) -> Int {
        var score = 0
        if d.victimCount != nil { score += 1 }
        if d.countryName != nil { score += 1 }
        if d.startDate != nil { score += 1 }
        if d.thumbnailURLString != nil { score += 1 }
        return score
    }

    private static func parseWikidataDate(_ value: String?) -> Date? {
        guard let value, !value.isEmpty else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }
}
