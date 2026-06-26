# App Store Listing — copy/paste text

Paste these into App Store Connect when your account is ready. Character limits noted.

---

## ⚠️ App name — important constraint
Apple limits the **App Name to 30 characters**. The spec's full name
"Criminally Intrigued: Crime Database" is **36 characters** — too long.

**Recommended split:**
- **App Name (≤30):** `Criminally Intrigued` (20 chars)
- **Subtitle (≤30):** `Crime database & cold cases` (27 chars)

The display name under the icon is already "Criminally Intrigued" via
`CFBundleDisplayName`, so this is consistent.

---

## Subtitle (≤30 chars)
```
Crime database & cold cases
```

## Keywords (≤100 chars, comma-separated, no spaces after commas)
```
true crime,serial killer,cold case,unsolved,mystery,murder,criminal,detective,reference,cases
```

## Promotional text (≤170 chars — can be updated anytime without review)
```
A clean, respectful true-crime reference reader. Browse serial killers, cold cases, and unsolved mysteries from Wikipedia — fully offline, no ads, no tracking.
```

## Description (≤4000 chars)
```
Criminally Intrigued is a clean, respectful reference reader for true-crime topics, sourced entirely from Wikipedia. It is a factual reference tool — not entertainment that sensationalizes crime.

Browse three curated categories:
• Serial Killers
• Cold Cases
• Strange & Unsolved Mysteries

WHY IT'S BETTER THAN A WEB BROWSER
• Structured browsing Wikipedia doesn't offer — filter by victim count, country, alphabetically, or chronologically.
• A distraction-free reading view designed for comfortable long-form reading, with light and dark mode.
• Full offline reading. Any article you open is saved to your device, and you can pre-download the entire catalog for travel or no-signal reading.
• Fast in-app search across the whole catalog.
• Save the cases you're following with bookmarks.

PRIVACY BY DESIGN
• No ads. No tracking. No analytics. No account required.
• Your bookmarks and cached articles stay on your device.

RESPECTFUL BY DESIGN
This app covers real crimes, real victims, and real people. The tone is neutral and factual throughout. Content is presented for informational purposes, with respect intended for victims and the people affected.

SOURCES & LICENSING
All article content is from Wikipedia, © its contributors, licensed under Creative Commons Attribution-ShareAlike 4.0 (CC BY-SA 4.0). Every article links back to its original Wikipedia page.

A one-time paid app — $0.99, no in-app purchases, no subscriptions.
```

## What's New (for v1.0)
```
Initial release.
• Three categories: serial killers, cold cases, and strange/unsolved mysteries
• Filter by victim count, country, alphabetical, or chronological
• Offline reading and full-catalog download
• In-app search and bookmarks
• Light & dark mode
```

---

## Other App Store Connect fields
- **Primary category:** Reference
- **Secondary category:** Book (or News)
- **Age rating:** 17+ — answer the questionnaire honestly: realistic violence references = Frequent/Intense; everything else (gambling, contests, unrestricted web) = None.
- **Price:** Tier 1 ($0.99), paid upfront
- **Support URL:** https://anthony-banks.github.io/criminally-intrigued/
- **Marketing URL (optional):** https://anthony-banks.github.io/criminally-intrigued/
- **Privacy Policy URL:** https://anthony-banks.github.io/criminally-intrigued/privacy.html
- **Privacy label:** Data Not Collected
- **Copyright:** 2026 (your name)
- **Review notes:** see STORE_SUBMISSION.md §2

---

## Screenshot shot list (6.9" — iPhone 16 Pro Max)
Apple requires at least one set; the 6.9" set covers all modern iPhones.
Capture these 4–5 in the Simulator (Device > Trigger Screenshot, or ⌘S):
1. A category list (Serial Killers) showing rows + metadata chips
2. The Filter & Sort sheet, open, showing the country list
3. A reading view scrolled to show the article + the attribution footer
4. The Saved (bookmarks) tab with a few saved
5. (Optional) Settings showing the "Download all articles" offline toggle

Tip: take them in both light and dark mode if you want, but one mode is fine for v1.
```
