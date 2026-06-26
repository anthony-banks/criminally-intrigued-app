# Criminally Intrigued: Crime Database — iOS App Specification

> **App Store listing name:** "Criminally Intrigued: Crime Database"
> **Display name (under the icon):** "Criminally Intrigued" (`CFBundleDisplayName`)
> **Xcode project / target / scheme:** `CriminallyIntrigued` — no spaces or colon (those aren't valid in a target/bundle name). Bundle ID e.g. `com.{yourname}.criminallyintrigued`.
> **Audience for this document:** an autonomous coding agent (e.g. Claude Code) building the app end to end.
> **Status:** v1 scope, ready to build.

---

## 1. How to use this spec

This document is the single source of truth for v1. Build in the phase order in §18. Where a value is marked **[VERIFY]**, the agent must confirm it against a live source before relying on it (Wikidata identifiers drift rarely but do change; App Store policy is in active flux). Do not invent data, do not hardcode article text, and do not skip the attribution requirements in §12 — those are legally mandatory, not optional polish.

---

## 2. Product overview

A clean, fast iOS reader for true-crime reference content sourced entirely from Wikipedia/Wikidata. The user browses three curated categories — **Serial Killers**, **Cold Cases**, and **Strange/Unsolved Cases** — each presented as a simple, filterable list. Tapping an entry opens a distraction-free reading view of the case with mandatory source attribution.

The app is a **respectful, factual reference tool**, not entertainment that sensationalizes crime. Tone and copy throughout must reflect that (see §13).

### Core value
- Clean reading experience over Wikipedia's dense desktop-oriented layout.
- Structured browsing and filtering that Wikipedia itself doesn't offer (by victim count, country, alphabetical, chronological).
- Full offline reading once viewed.

---

## 3. Goals & non-goals

**Goals (v1)**
- Three categories, each a browsable list.
- Filters: victim count, country, alphabetical, chronological.
- Clean detail/reading view with light & dark mode.
- In-app search, bookmarks/favorites, offline caching, share.
- Mandatory source attribution on every article.
- About screen and a donations option.
- Paid app: **$0.99 upfront, no ads, no tracking.**

**Non-goals (v1)**
- No user accounts, login, or cloud sync.
- No user-generated content or comments.
- No backend server (the app talks directly to Wikimedia APIs + a local cache).
- No push notifications.
- No editing of source content.
- No Android/iPad-specific layouts beyond what comes free from adaptive SwiftUI (iPad support is a "nice if free," not a requirement).

---

## 4. Tech stack & standards

| Concern | Choice | Notes |
|---|---|---|
| Language | Swift 6 (strict concurrency) | |
| UI | SwiftUI | |
| Min iOS | iOS 17.0 | Enables SwiftData; **[VERIFY]** current minimum worth supporting at build time |
| Architecture | MVVM | Views ← ViewModels ← Repositories ← Services |
| Concurrency | `async`/`await`, actors for cache writes | No Combine unless a specific need arises |
| Networking | `URLSession` only | No third-party networking deps |
| Persistence | SwiftData | Local catalog + cached article bodies + bookmarks |
| Payments | App Store paid-upfront | No StoreKit code for the base price (§14) |
| Dependencies | Keep near-zero | Every dep must be justified; prefer first-party frameworks |
| Testing | XCTest (unit) + a few UI smoke tests | Repositories and filter logic must be unit-tested |
| Formatting | swift-format, default Apple style | |

**No analytics, ad, crash-reporting, or tracking SDKs.** This is deliberate — it keeps the App Store privacy label at "Data Not Collected," which is a genuine selling point for a paid app (see §15).

---

## 5. Architecture

```
SwiftUI Views
   │  (observe)
ViewModels  ──────────────┐
   │  (call)              │ format / sort / filter (in memory)
Repositories              │
   │            ┌─────────┴──────────┐
   │            │                    │
RemoteService            LocalStore (SwiftData)
 (Wikidata SPARQL,        (catalog cache,
  Wikipedia REST)          article cache, bookmarks)
```

- **Repositories** are the only thing ViewModels touch. A repository decides cache-vs-network and returns domain models.
- **Filtering, sorting, and search run locally** against the cached catalog — never as repeated live API calls (the Wikidata endpoint is throttled; see §6.4).
- ViewModels hold no networking logic; they orchestrate and expose view state (`idle / loading / loaded / empty / error`).

---

## 6. Data sources & integration

All content comes from Wikimedia. Two APIs, both free, no key required.

### 6.1 Wikidata Query Service (SPARQL) — the structured catalog
- Endpoint: `https://query.wikidata.org/sparql`
- Returns JSON with `Accept: application/sparql-results+json`.
- This is what makes the **filters** possible: victim count, country, and dates come back as clean fields. Wikipedia article text alone cannot power these filters.

**Serial Killers catalog query (reference implementation — [VERIFY] QIDs/PIDs):**
```sparql
SELECT ?person ?personLabel ?victims ?countryLabel ?birth ?death ?image ?article WHERE {
  ?person wdt:P106 wd:Q484188 .                 # occupation: serial killer
  OPTIONAL { ?person wdt:P1345 ?victims . }      # number of victims
  OPTIONAL { ?person wdt:P27   ?country . }       # country of citizenship
  OPTIONAL { ?person wdt:P569  ?birth . }         # date of birth
  OPTIONAL { ?person wdt:P570  ?death . }         # date of death
  OPTIONAL { ?person wdt:P18   ?image . }         # image
  OPTIONAL {
    ?article schema:about ?person ;
             schema:isPartOf <https://en.wikipedia.org/> .
  }
  SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
}
```

Identifiers used (confirm each with a one-off test query before wiring in):
- `Q5` human · `Q484188` serial killer · `P106` occupation · `P1345` number of victims · `P27` country of citizenship · `P569` date of birth · `P570` date of death · `P18` image.

Only rows with an English Wikipedia `?article` should enter the catalog (no article = nothing to read).

### 6.2 Wikipedia REST + Action API — the article text
- **Lead/summary (cards & detail header):** `GET https://en.wikipedia.org/api/rest_v1/page/summary/{title}` → clean extract, thumbnail, canonical URL, description.
- **Full clean body (reading view):** `GET https://en.wikipedia.org/w/api.php?action=query&prop=extracts&explaintext=1&exsectionformat=plain&titles={title}&format=json` → plain-text article, markup stripped. This is the "clean text" deliverable.
- Always capture the canonical article URL returned — it is reused for attribution (§12) and Share (§9.7).

### 6.3 Category sourcing strategy (important — read carefully)

The three categories do **not** map to one data source equally:

| Category | Primary source | Why |
|---|---|---|
| Serial Killers | Wikidata SPARQL (§6.1) | Clean person-centric structured data: victims, country, dates all present |
| Cold Cases | Wikipedia category traversal | Case/event-centric; structured fields are sparse |
| Strange / Unsolved | Wikipedia category traversal | Same — fuzzy, not a single Wikidata occupation |

For the latter two, use the Action API category members endpoint:
`GET https://en.wikipedia.org/w/api.php?action=query&list=categorymembers&cmtitle=Category:{name}&cmlimit=max&format=json`

Candidate seed categories (**[VERIFY]** existence and curate — some are large/noisy):
- Cold Cases: `Category:Cold case investigations`, `Category:Unsolved murders`, `Category:Missing person cases`.
- Strange/Unsolved: `Category:Unsolved deaths`, `Category:Unexplained disappearances`, plus a hand-curated allowlist (see below).

**Consequence for filters:** victim count and country may be missing for many cold/strange entries. Filters must **degrade gracefully** — an entry with no victim count is simply excluded from a victim-count filter, not crashed or shown as "0". Where possible, enrich a category-sourced entry by looking up its Wikidata item (via the article's `pageprops → wikibase_item`) to backfill country/date.

**Curation:** because category traversal is noisy, maintain a small bundled JSON allowlist/denylist (`SeedCatalog.json`) the agent can edit, so obviously-irrelevant or inappropriate entries can be excluded without a code change. This also seeds first launch (see §6.4).

### 6.4 Caching & sync (non-negotiable for performance + API etiquette)

The Wikidata endpoint is throttled (roughly 60s of query time per minute per client) and can be slow under load. **Do not query it on user interaction.** Strategy:

1. **Ship a bundled seed snapshot** (`SeedCatalog.json`) so the app is fully usable on first launch with zero network — list browses immediately.
2. **Background catalog refresh:** on launch, if the cached catalog is older than **7 days**, refresh it from Wikidata/Wikipedia in the background and merge into the local store. Never block the UI on this.
3. **Article bodies fetched on demand** when a detail view opens, then cached permanently in SwiftData → satisfies the **offline reading** requirement.
4. All filtering/sorting/search runs against the local store.

**Required HTTP etiquette (Wikimedia policy):** every request must send a descriptive `User-Agent` header identifying the app and a contact (e.g. `CriminallyIntrigued/1.0 (https://your-site-or-email)`). Generic/empty user agents get blocked. Respect `Retry-After` on 429s with exponential backoff.

---

## 7. Data model

Domain model (persisted via SwiftData unless noted):

```
CaseEntry
  id: String                 // Wikidata QID if present, else "enwiki:{title}"
  title: String              // display name
  category: Category         // .serialKiller | .coldCase | .strange
  summary: String?           // lead extract
  body: String?              // full plain text, nil until first opened (cached after)
  bodyFetchedAt: Date?
  articleURL: URL            // canonical Wikipedia URL (attribution + share)
  thumbnailURL: URL?
  victimCount: Int?          // nil when unknown — never coerce to 0
  countryCode: String?       // ISO; derived from Wikidata country label
  countryName: String?
  startDate: Date?           // for chronological sort: date of death, or case date
  isBookmarked: Bool
  lastViewedAt: Date?
  catalogUpdatedAt: Date

Category (enum): serialKiller, coldCase, strange
```

Notes:
- `startDate` is the unified chronological key: for serial killers use date of death (fallback date of birth); for cases use the event/case date (`P585` point in time **[VERIFY]**, or parse from the article as a last resort).
- Sorting/filtering operates on these fields only; nothing requires re-fetching to sort.

---

## 8. Content categories

Three top-level categories, each its own tab/section, each rendering the same list component:

1. **Serial Killers**
2. **Cold Cases**
3. **Strange / Unsolved**

A small content disclaimer is shown on first launch (§13).

---

## 9. Features

### 9.1 Browse / list
- One reusable list view, parameterized by category.
- Each row: thumbnail (or category placeholder), title, and 1–2 metadata chips (e.g. country, victim count, year) shown only when data exists.
- Lazy loading (`LazyVStack`/`List`), smooth scrolling, skeleton/redacted placeholders while the seed/cached data loads.
- Empty state and error state per §10.

### 9.2 Detail / reading view
- Clean, single-column, typographic reading layout (see §10 typography).
- Header: title, optional hero image, metadata chips.
- Body: full plain-text article, section breaks preserved.
- **Footer: mandatory attribution block (§12).**
- Toolbar: bookmark toggle, share, open-in-Wikipedia.
- First open triggers body fetch + cache; subsequent opens are instant and offline-capable.

### 9.3 Filters & sort
Available on every list. Implement as a single filter/sort sheet:
- **Victim count:** range or threshold (e.g. "10+"). Entries with unknown count are excluded from this filter, not shown as 0.
- **Country:** multi-select, populated from countries actually present in the current category's data.
- **Alphabetical:** A→Z / Z→A.
- **Chronological:** newest→oldest / oldest→newest, on `startDate`.
- Filters compose (country + victim count + a sort). Show active-filter count on the toolbar button; provide "Reset."
- All applied locally, instantly.

### 9.4 In-app search
- Searches the **local cached catalog** by title (and optionally summary) — fast, offline, no API call.
- Scope toggle: current category vs. all categories.
- Debounced, with a clear empty state.
- (Do **not** use SPARQL regex search — it's an antipattern and throttled.)

### 9.5 Bookmarks / favorites
- Toggle from list rows and detail toolbar.
- A dedicated "Saved" view aggregating bookmarks across categories.
- Persisted in SwiftData; available offline.

### 9.6 Offline caching / reading
- Seed catalog works offline from first launch.
- Any article opened once is readable offline forever (until cache cleared).
- Settings → "Clear cache" (keeps bookmarks list; re-downloads bodies on next open).
- Network-unavailable states must read gracefully: show cached content, queue refreshes.

### 9.7 Share
- Shares the **canonical Wikipedia URL** + title via the system share sheet (`ShareLink`).
- Never share scraped/cached body text as if original — share the link (also reinforces attribution).

### 9.8 About
- App name, version, one-paragraph description, and tone/ethics statement.
- **Sources & licensing section** (see §12): explains content is from Wikipedia, licensed CC BY-SA 4.0, with links to the license and to Wikipedia.
- Developer credit + contact.
- Link to privacy policy (required for App Store; can be a simple hosted page — content is "no data collected").

### 9.9 Donations
See §14 for the compliance details that dictate the implementation. UI: a simple "Support development" row in About/Settings that opens an external donation page (US storefront) or a StoreKit tip (if going global). Keep it understated and entirely optional.

### 9.10 Settings / appearance
- Theme: System / Light / Dark (default System).
- Text size respects Dynamic Type automatically; optionally an in-app size stepper for the reading view.
- Clear cache.
- Links: About, Privacy, Sources/licensing.

---

## 10. UI/UX design system

Goal: **clean, calm, legible, content-first.** No sensational red-and-black "crime" theming — restrained and editorial. (See `/mnt/skills/public/frontend-design` principles if generating any web companion, but this is native SwiftUI.)

- **Light & dark mode:** full support, driven by semantic colors only. No hardcoded hex that breaks in one mode. Verify contrast (WCAG AA) in both.
- **Color:** warm-neutral base with **subtle desaturated olive-green accents** (full palette below). Implement as named **Color Sets in `Assets.xcassets`**, each with an *Any Appearance* (light) and *Dark Appearance* value; reference by name only (`Color("AccentOlive")`), never raw hex in views. Set the catalog **AccentColor** to the olive set so system controls (links, switches, selection) tint correctly.

#### Color palette — "subtle olive" theme

| Token (asset name) | Role | Light | Dark |
|---|---|---|---|
| `BackgroundPrimary` | screen background | `#FAFAF7` | `#121310` |
| `BackgroundSecondary` | cards / grouped rows | `#F1F1EB` | `#1B1D17` |
| `BackgroundTertiary` | wells / chip fills | `#E7E8DD` | `#262922` |
| `LabelPrimary` | body & titles | `#1C1C18` | `#ECEDE5` |
| `LabelSecondary` | metadata, captions | `#5E5F55` | `#A2A398` |
| `LabelTertiary` | disabled / hints | `#8A8B7E` | `#76776B` |
| `Separator` | dividers, hairlines | `#D9DAD0` | `#2F322A` |
| `AccentOlive` (→ AccentColor) | links, selection, controls | `#5B6B3A` | `#A9B574` |
| `AccentPressed` | pressed / active accent | `#4A5730` | `#BCC78A` |
| `AccentFill` | selected chip / tag background | `#E3E7D1` | `#2C3120` |
| `AccentOnFill` | text / icon on `AccentFill` | `#3E4A25` | `#C3CE92` |

Rules:
- Olive is an **accent used sparingly** — interactive elements, active filter chips, bookmark-on state, and links (including the attribution-footer links). Backgrounds and text stay warm-neutral so the app reads calm and editorial, not "green."
- Light-mode accent is a deep olive (AA-compliant as text on light backgrounds); dark-mode accent is a lighter olive that stays legible on near-black. All pairings above meet **WCAG AA** for their intended text use — re-check any value you change.
- Backgrounds are a warm off-white / a near-black with a faint green lean, keeping both modes soft rather than stark.
- **Typography:** SF Pro / system font, generous line spacing and measure in the reading view (comfortable reading width, ~16–18pt body, clear heading hierarchy). Full **Dynamic Type** support.
- **Components:** reusable `CaseRow`, `MetadataChip`, `FilterSheet`, `AttributionFooter`, `EmptyState`, `ErrorState`, `SkeletonRow`.
- **Navigation:** `NavigationStack` per tab; `TabView` for the three categories + Saved + Settings (or a Browse/Saved/About structure — agent may choose the cleaner of the two, documented in code).
- **Motion:** subtle, standard system transitions only.
- **Imagery:** lazy-loaded, cached; tasteful placeholder when absent; never auto-display anything gratuitously graphic at full bleed.

### Screen inventory
1. Category list (×3, shared component)
2. Filter/sort sheet
3. Search
4. Detail/reading view
5. Saved (bookmarks)
6. Settings / appearance
7. About + Sources/licensing
8. First-launch content disclaimer

---

## 11. Attribution & licensing — MANDATORY

Wikipedia text is licensed **CC BY-SA 4.0** (and GFDL). Reuse is permitted, including in a paid app, **only if** attribution and the license are provided. This is a hard requirement; the app must not ship without it.

**Every detail/reading view must display an attribution footer**, e.g.:

> Source: *{Article Title}* from Wikipedia, licensed under CC BY-SA 4.0.

- "{Article Title}" links to that specific article's canonical URL (the per-article link is the attribution — Wikipedia's author list is the page history).
- "CC BY-SA 4.0" links to `https://creativecommons.org/licenses/by-sa/4.0/`.
- Footer may be visually quiet (caption style, secondary color) but must be present and the links must work. SwiftUI `Text` renders Markdown links natively.

**The About screen** must additionally carry a general statement: content sourced from Wikipedia, © its contributors, licensed CC BY-SA 4.0, with links to Wikipedia and the license.

**Share** shares the canonical link (reinforces attribution).

**Do not modify article text.** v1 reproduces text verbatim (reformatting/cleaning markup is fine — that's display, not a derivative). If a future version summarizes or rewrites content, ShareAlike then requires that derived text also be released under CC BY-SA, and modifications must be marked — out of scope for v1.

**Images:** only display images returned via Wikidata `P18` / the Wikipedia summary thumbnail, which are generally freely licensed, **but per-file licenses vary and some Wikipedia images are non-free/fair-use.** For v1 safety: prefer the summary thumbnail (Commons-backed) and **[VERIFY]** image licensing; when in doubt, omit the image rather than risk a non-free image in a commercial app.

**Trademark:** do not use the Wikipedia/Wikimedia name or logo in a way implying endorsement; a plain "Source: Wikipedia" text credit is fine.

---

## 12. Content sensitivity & ethics

This app covers real crimes, real victims, and real people. Build accordingly:

- **Neutral, factual tone** in all app copy. Do not glorify or sensationalize perpetrators or crimes. No lurid marketing language in UI strings.
- **First-launch disclaimer** (one time, dismissible): content is factual reference sourced from Wikipedia, may be disturbing, and is presented for informational purposes; respect for victims is intended.
- Avoid full-bleed graphic imagery; keep imagery restrained.
- Respect that some cases are recent/ongoing — present as the source does, without speculation added by the app.
- This neutral framing also supports App Store review under content guidelines (realistic depictions of violence are scrutinized).

---

## 13. Monetization

- **Model:** paid upfront, **$0.99 (Tier 1)**, no ads, no IAP for the base experience.
- **Implementation:** the price is configured in **App Store Connect** — there is **no StoreKit code** required for a paid-upfront app. The agent does not build a purchase flow for the base price.
- No ad SDKs, no paywalls inside the app.

---

## 14. Donations — compliance-driven implementation

> App Store payment rules are in active flux following the 2025 *Epic v. Apple* injunction. **[VERIFY]** the current App Store Review Guidelines (§3.1.1, 3.1.1(a), 3.1.3, 3.2.1) at submission time.

Current state (as researched June 2026):
- **US storefront:** Apple no longer prohibits external links/buttons/calls-to-action, and no special entitlement is required. An external donation link (Ko-fi, Buy Me a Coffee, Stripe, PayPal) is permissible. This avoids Apple's commission entirely.
- **Outside the US:** historically Apple has **rejected** external "tip jar"/donation links in non-reader apps, requiring IAP. The person-to-person gift exception (3.2.1(vii)) is narrow and has been interpreted strictly against developer tip jars.

**Recommended v1 approach:**
- **US-first launch:** "Support development" → opens an external donation page in `SFSafariViewController`. Simple, compliant on the US storefront, no Apple cut.
- **If launching globally:** either (a) gate the external link to the US storefront and hide the donation row elsewhere, or (b) implement a StoreKit 2 **consumable "tip"** (e.g. $0.99/$2.99/$4.99) as the donation mechanism worldwide (Apple takes its cut, but it's universally compliant).
- Whichever path: donations must be **clearly optional**, unlock **nothing**, and be described accurately in the App Store Connect review notes (§2.3.1 requires disclosing the feature).

Keep the UI understated — a single quiet row, not a nag.

---

## 15. Privacy & App Store compliance

- **Privacy label:** target **"Data Not Collected."** No analytics/ads/tracking SDKs makes this honest. If a crash reporter or external donation provider is added, re-evaluate and disclose accordingly.
- **No App Tracking Transparency prompt** needed (no tracking).
- **Privacy policy:** still required by App Store; host a simple page stating no personal data is collected; bookmarks/cache are stored locally on device only.
- **Age rating:** expect a **mature rating** (true-crime references to violence/real crimes). Answer the App Store Connect content questionnaire honestly regarding references to violence and mature/suggestive themes; **[VERIFY]** the exact tier under the current age-rating system at submission.
- **Review notes (§2.3.1):** describe the Wikipedia sourcing, the attribution footer, the donation mechanism, and the content disclaimer explicitly so review isn't surprised.
- **iPad:** if it runs adaptively, leave it enabled; otherwise iPhone-only is acceptable for v1.

---

## 16. Non-functional requirements

- **Performance:** list scroll at 60fps with cached data; cold launch usable in <1s using the bundled seed; no main-thread network or DB writes.
- **Offline-first:** every read path must have a cached fallback; no blank screens on no-network.
- **Accessibility:** full VoiceOver labels on rows/controls; Dynamic Type throughout; AA contrast in both themes; respect Reduce Motion.
- **Error handling:** typed errors per layer; user-facing states are friendly and actionable ("Couldn't refresh — showing saved content. Retry?"). Never surface raw API errors.
- **Resilience:** handle 429/5xx with backoff; partial catalog refresh must not corrupt the existing cache (atomic merge).
- **Localization-ready:** all user-facing strings in a String Catalog, even if v1 ships English only.

---

## 17. Project structure

```
CriminallyIntrigued/
├── App/                 // App entry, root TabView, theming
├── Models/              // CaseEntry, Category, DTOs
├── Services/
│   ├── WikidataService.swift     // SPARQL
│   ├── WikipediaService.swift    // REST + Action API
│   └── HTTPClient.swift          // URLSession wrapper, User-Agent, backoff
├── Persistence/         // SwiftData store, cache policy
├── Repositories/        // CatalogRepository, ArticleRepository, BookmarkRepository
├── Features/
│   ├── CategoryList/
│   ├── Detail/
│   ├── Filters/
│   ├── Search/
│   ├── Saved/
│   ├── Settings/
│   └── About/
├── DesignSystem/        // Colors, Typography, reusable components
├── Resources/           // SeedCatalog.json, Assets, String Catalog
└── Tests/
```

---

## 18. Build phases (do in order)

1. **Foundation:** project, design system (colors/type/light+dark), `TabView` shell, models, SwiftData store, `HTTPClient` with User-Agent + backoff.
2. **Data layer:** `WikidataService` + `WikipediaService`; `CatalogRepository` with seed-bundle load and 7-day background refresh; `ArticleRepository` with on-demand fetch + permanent cache. Unit-test filter/sort logic here.
3. **Browse + detail:** category lists with cached data; detail/reading view; **attribution footer** wired (§11). Verify offline reading.
4. **Filters, search, bookmarks, share:** all local; filter/sort sheet; debounced search; Saved view; `ShareLink`.
5. **About, settings, donations, disclaimer:** appearance toggle, clear cache, sources/licensing, donation row (§14), first-launch disclaimer.
6. **Polish & compliance:** accessibility pass, empty/error states, performance, privacy policy page, App Store Connect metadata + review notes, age-rating questionnaire, $0.99 pricing.

---

## 19. Acceptance criteria (v1 "done")

- [ ] Three categories each browse from a bundled seed with zero network on first launch.
- [ ] Filters (victim count, country, alphabetical, chronological) work locally, compose, and degrade gracefully on missing data.
- [ ] In-app search returns results offline from the cache.
- [ ] Any opened article is readable offline afterward.
- [ ] **Every** detail view shows a working attribution footer linking the specific article and the CC BY-SA 4.0 license.
- [ ] About screen carries the general Wikipedia/CC BY-SA credit and a privacy statement.
- [ ] Bookmarks persist and aggregate in Saved.
- [ ] Light/dark mode both pass AA contrast; Dynamic Type works.
- [ ] Donation flow is compliant for the launch storefront(s) and unlocks nothing.
- [ ] No tracking/ad SDKs; privacy label is "Data Not Collected."
- [ ] All Wikimedia requests send a descriptive User-Agent and back off on 429.

---

## 20. Open items / decisions to confirm before/at submission

- **[VERIFY]** Wikidata QIDs/PIDs in §6.1 via a one-off live query.
- **[VERIFY]** Final seed categories for Cold/Strange (§6.3) — curate for quality and appropriateness.
- **[VERIFY]** Current App Store donation/external-link rules and age-rating tiers at submission (§14, §15).
- **[VERIFY]** Per-image licensing before displaying any image in a paid app (§11).
- **DECIDE:** launch storefront(s) — US-only simplifies donations significantly.
- **RESOLVED:** app name = **Criminally Intrigued: Crime Database** (target `CriminallyIntrigued`).
- **FUTURE (not v1):** AI-cleaned summaries (triggers ShareAlike on derived text), iPad-optimized layout, additional categories, Wikidata enrichment for cold/strange entries.
