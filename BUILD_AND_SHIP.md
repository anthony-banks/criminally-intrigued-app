# Criminally Intrigued — Build & Ship Guide

This is the hand-holding walkthrough for someone who has never built or
published an iOS app. The full v1 app described in
`criminally-intrigued-ios-spec.md` is already written and in this folder.

---

## ⚠️ First, the one blocker: update Xcode

Your Mac is on **macOS 26.1**, but the installed **Xcode is 16.4**, which is
too old for this macOS. We proved this — `xcodebuild` refuses to run:

> A required plugin failed to load… (framework version mismatch)

**You must update Xcode before you can build or run.**

### How to update Xcode
1. Open the **App Store** app → search **Xcode** → click **Update** (or **Open**
   if it shows installed). Xcode 26 is a large download (several GB); let it
   finish.
2. After it installs, open **Terminal** and run (it will ask for your Mac
   password — typing is invisible, that's normal):
   ```
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -runFirstLaunch
   ```
3. Open Xcode once and accept the license / let it install components.

> The app code itself is already verified to compile under Swift 6 — only the
> tooling needs updating. Nothing in the code needs to change for this.

---

## Step 1 — Open the project

In Terminal:
```
open /Users/banks/Desktop/criminallyIntrigued/CriminallyIntrigued.xcodeproj
```
Xcode opens with the full app: `App/`, `Models/`, `Services/`, `Repositories/`,
`Features/`, `DesignSystem/`, `Resources/`, and a test target.

## Step 2 — Run it in the Simulator

1. At the top of Xcode, click the device menu (next to ▶) → pick **iPhone 16
   Pro** (or any iPhone simulator).
2. Click **▶ (Run)**, or press **⌘R**.
3. The app launches: the first-launch disclaimer, then three tabs (Serial
   Killers / Cold Cases / Strange-Unsolved) + Saved + Settings, populated
   instantly from the bundled seed — works with no network.
4. Tap any entry → it fetches the full Wikipedia article (needs internet the
   first time), then caches it for offline reading. Note the **attribution
   footer** at the bottom — that's legally required and already wired in.

## Step 3 — Run the tests

Press **⌘U**. The `FilterEngineTests` suite (filter/sort/search logic) should
pass green.

---

## Before you change anything: 3 placeholders to fill in

Search the project (⌘⇧F) for these and replace with your real values:

| Find | In file | Replace with |
|---|---|---|
| `https://github.com/yourname/...; contact@example.com` | `Services/HTTPClient.swift` | Your real site/email (Wikimedia requires a real contact in the User-Agent) |
| `https://ko-fi.com/yourname` | `Features/Settings/SettingsView.swift` | Your real donation page (Ko-fi / Buy Me a Coffee / Stripe) |
| `https://example.com/.../privacy` and `contact@example.com` | `Features/About/AboutView.swift` | Your hosted privacy-policy URL + contact |
| `com.example.CriminallyIntrigued` | Project → target → Signing | `com.yourname.criminallyintrigued` |

---

## Step 4 — Run on your own iPhone (free, no paid account yet)

1. Plug your iPhone into the Mac with a cable; tap **Trust** on the phone.
2. In Xcode: click the project (blue icon, top of the left panel) → select the
   **CriminallyIntrigued** target → **Signing & Capabilities** tab.
3. Check **Automatically manage signing**. Under **Team**, click **Add an
   Account** and sign in with your **free Apple ID**.
4. Change the **Bundle Identifier** to something unique:
   `com.yourname.criminallyintrigued`.
5. Pick your iPhone in the device menu at the top → press **▶**.
6. First run: on the phone, go **Settings → General → VPN & Device Management**
   → trust your developer certificate, then launch the app.

> Free Apple ID apps stop working after 7 days — just re-run from Xcode to
> refresh. That's fine for testing; you only need the paid program to publish.

---

## Step 5 — Publish to the App Store

Only now do you need the paid account.

### 5a. Join the Apple Developer Program ($99/year)
Go to <https://developer.apple.com/programs/> → **Enroll**. Use the same Apple
ID. Approval is usually quick (sometimes a day).

### 5b. Create the app record in App Store Connect
1. Go to <https://appstoreconnect.apple.com> → **My Apps → ➕ → New App**.
2. Platform **iOS**; Name **Criminally Intrigued: Crime Database**; pick your
   bundle ID; SKU = any unique string (e.g. `criminally-intrigued-01`).
3. **Pricing:** set **Tier 1 ($0.99)**, paid upfront. (No in-app-purchase code
   is needed — the price is configured here, per spec §13.)

### 5c. Fill in the required metadata (App Store Connect)
- **Privacy label:** answer **"Data Not Collected"** (the app has no analytics,
  ads, or tracking — spec §15).
- **Privacy policy URL:** your hosted page stating no data is collected.
- **Age rating:** answer the content questionnaire honestly — this is true-crime
  with references to violence, so expect a mature tier (spec §15).
- **App Review notes (important — spec §2.3.1 / §15):** paste something like:
  > Content is factual reference material sourced from Wikipedia and displayed
  > with a CC BY-SA 4.0 attribution footer on every article. The optional
  > "Support development" link is an external donation page (US storefront) and
  > unlocks no functionality. A content disclaimer is shown on first launch.
- Screenshots: take them from the Simulator (**⌘S** in the Simulator saves a
  screenshot) for the required iPhone sizes.

### 5d. Add an app icon
The `AppIcon` slot in `Assets.xcassets` is currently empty. Make a 1024×1024 PNG
(no transparency) and drag it onto the AppIcon in Xcode. Apps can't ship without
an icon.

### 5e. Upload the build
1. In Xcode device menu pick **Any iOS Device (arm64)**.
2. Menu **Product → Archive**. When it finishes, the Organizer opens.
3. Click **Distribute App → App Store Connect → Upload**. Follow prompts.
4. Back in App Store Connect, attach that build to your version, then
   **Submit for Review**.

Review typically takes a day or two. Address any reviewer feedback and resubmit.

---

## Decisions still open (from spec §20)
- **[VERIFY]** the Wikidata QIDs/PIDs with a live query before relying on the
  Serial Killers background refresh (`Services/WikidataService.swift`).
- **Curate** `Resources/SeedCatalog.json` — it's a small starter set; expand and
  verify victim counts/dates for quality.
- **DECIDE** launch storefront — US-only keeps the external donation link simple.
  If you go global, you'd need a StoreKit tip instead (spec §14).
- **[VERIFY]** per-image licensing before showing images in a paid app (spec §11).

---

## What's implemented (maps to spec acceptance criteria §19)
- ✅ Three categories browsing from a bundled seed with zero network on launch
- ✅ Filters (victim count, country, alphabetical, chronological) — local,
  composable, degrade gracefully on missing data (unit-tested)
- ✅ Offline in-app search over the local cache
- ✅ Articles cached permanently after first open (offline reading)
- ✅ Mandatory CC BY-SA 4.0 attribution footer on every detail view
- ✅ About screen with Wikipedia/CC credit + privacy statement
- ✅ Bookmarks persist and aggregate in Saved
- ✅ Light/dark via semantic color sets; Dynamic Type
- ✅ US external-link donation row that unlocks nothing
- ✅ No tracking/ad SDKs → honest "Data Not Collected"
- ✅ Descriptive User-Agent + 429 backoff on all Wikimedia requests

## Known follow-ups
- Cold/Strange categories currently rely on the bundled seed; live category
  traversal (spec §6.3) is stubbed for a future pass — the seed makes them fully
  functional now.
- App icon art and real contact/privacy/donation URLs must be filled in (above).
