# App Store Submission Pack — Criminally Intrigued

Everything you need to paste into App Store Connect, plus the last values to fill in.

---

## 1. Fill these 3 values in code (only placeholders left)

Open `CriminallyIntrigued/App/AppConfig.swift` and replace:
- `supportEmail` → your real contact email
- `websiteURL` → a real page about the app (can be a simple site or even a GitHub page)
- `privacyPolicyURL` → the live URL where you host the policy from §3 below

That's it — every other placeholder in the app has been removed.

---

## 2. App Review notes (paste into App Store Connect → App Review Information → Notes)

> Criminally Intrigued is a respectful, factual true-crime *reference reader*.
> All article content is sourced from Wikipedia and displayed with a mandatory
> attribution footer on every article, linking the specific source article and
> the CC BY-SA 4.0 license (Wikipedia text is licensed for reuse, including
> commercial, with attribution).
>
> The app is more than a web view: it provides a bundled offline catalog,
> structured filtering (by victim count, country, alphabetical, chronological),
> offline full-text caching, in-app search, and bookmarks — none of which
> Wikipedia offers.
>
> Content references real crimes and violence and is presented neutrally for
> informational purposes. A content disclaimer is shown on first launch. The app
> is rated 17+ accordingly.
>
> Privacy: the app collects no data. There are no analytics, ads, tracking, or
> accounts. Bookmarks and cached articles are stored only on device.
>
> The app makes no in-app purchases and contains no donation or external-payment
> mechanism in this version.

---

## 3. Privacy policy (host this text at the privacyPolicyURL)

> **Privacy Policy — Criminally Intrigued**
> _Last updated: [DATE]_
>
> Criminally Intrigued does not collect, store, or share any personal data.
>
> - **No accounts, no analytics, no advertising, no tracking.** We do not use any
>   third-party analytics, advertising, or tracking SDKs.
> - **On-device only.** Your bookmarks and any articles you cache for offline
>   reading are stored locally on your device. We never receive them.
> - **Network requests.** To display article content, the app requests pages
>   directly from Wikimedia (Wikipedia/Wikidata) APIs. These requests are subject
>   to the [Wikimedia Foundation Privacy Policy](https://foundation.wikimedia.org/wiki/Policy:Privacy_policy).
>   We do not send Wikimedia any personal information about you.
> - **No data sale.** We have no data to sell or share.
>
> Contact: [your email]

---

## 4. App Store Connect — required fields

- **Name:** Criminally Intrigued: Crime Database
- **Subtitle (optional):** A factual true-crime reference reader
- **Price:** Tier 1 ($0.99), paid upfront. (No IAP — price is set here, no code.)
- **Privacy "Nutrition" label:** select **Data Not Collected**.
- **Age rating questionnaire:** answer honestly — references to realistic
  violence are *Frequent/Intense* for true-crime content → expect **17+**.
  Answer "No" to all the gambling/contests/unrestricted-web questions.
- **Privacy Policy URL:** the page from §3.
- **Screenshots:** required iPhone sizes. Capture from the Simulator (Cmd+S
  saves a screenshot). Good shots: a category list, the filter sheet showing the
  country list, a reading view with the attribution footer, the Saved tab.
- **Support URL:** your website or a simple contact page.
- **Description:** lead with the value — clean offline reading, structured
  filters Wikipedia doesn't offer, no ads/tracking, every article credited.

---

## 5. Pre-submission checklist

- [ ] Fill the 3 values in `AppConfig.swift` (§1)
- [ ] Host the privacy policy (§3) and confirm the URL loads
- [ ] Enroll in the Apple Developer Program ($99/yr)
- [ ] Set a unique Bundle ID + your distribution Team in Signing & Capabilities
- [ ] Confirm the app icon shows (it's wired in: olive "CI" monogram)
- [ ] Product → Archive → Distribute App → App Store Connect → Upload
- [ ] Fill all §4 fields, attach the build, set 17+, submit for review

---

## 6. Compliance summary (why this should pass)

| Area | Status |
|---|---|
| Attribution (CC BY-SA 4.0) | ✅ Footer on every article + About credit |
| Images / IP risk | ✅ Images disabled for v1 (`AppConfig.showArticleImages = false`) |
| Donations / payments | ✅ Removed for v1 — no external-payment review risk |
| Privacy label | ✅ Honest "Data Not Collected" (no SDKs) |
| Minimum functionality (4.2) | ✅ Native offline catalog, filters, search, bookmarks |
| Content / violence (1.1.1) | ⚠️ Approvable with neutral tone + disclaimer + 17+ rating |
| Wikimedia etiquette | ✅ Descriptive User-Agent (set real contact in AppConfig) + 429 backoff |

The one area to watch is content rating — answer the questionnaire honestly and
keep the store description neutral (no lurid language).
