#!/usr/bin/env python3
"""
Validate the bundled SeedCatalog.json against live Wikipedia.

Flags entries that would render as a title-only card (no real description),
plus dead/redirected/disambiguation pages — the ones worth weeding out before
shipping. This is a DATA check, deliberately kept OUT of the unit-test suite
(it needs the network and is non-deterministic). Run it on demand:

    python3 Scripts/validate_catalog.py                # full report
    python3 Scripts/validate_catalog.py --limit 20     # quick sample
    python3 Scripts/validate_catalog.py --json out.json # machine-readable

Exit code is non-zero if any entry is flagged, so it can gate a release step.

"Usable" mirrors WikiSummary.isUsable in the app: a non-disambiguation page
with an extract of at least MIN_EXTRACT_CHARS characters.
"""

import argparse
import json
import ssl
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

# python.org Python ships without system CA certs, so HTTPS fails with
# CERTIFICATE_VERIFY_FAILED unless we point at a real bundle. Prefer certifi;
# fall back to the default context (works on Homebrew/system Python).
try:
    import certifi
    SSL_CONTEXT = ssl.create_default_context(cafile=certifi.where())
except ImportError:
    SSL_CONTEXT = ssl.create_default_context()

REST_SUMMARY = "https://en.wikipedia.org/api/rest_v1/page/summary/"
# Keep in sync with AppConfig.wikimediaUserAgent.
USER_AGENT = "CriminallyIntrigued/1.0 (https://anthony-banks.github.io/criminally-intrigued/; criminallyintriguedsupport@gmail.com)"
MIN_EXTRACT_CHARS = 20          # keep in sync with WikiSummary.isUsable
REQUEST_PAUSE = 0.15            # be polite to the API
MAX_RETRIES = 4

DEFAULT_SEED = Path(__file__).resolve().parent.parent / "CriminallyIntrigued" / "Resources" / "SeedCatalog.json"

# Result buckets
OK = "ok"
MISSING = "missing"            # 404 / no page
DISAMBIGUATION = "disambiguation"
EMPTY = "empty"               # page exists but no extract at all
THIN = "thin"                # extract present but shorter than threshold
NETWORK = "network"          # could not reach the API (not the data's fault)


def fetch_summary(title):
    """Return (status_code, parsed_json_or_None). Retries 429/5xx with backoff.
    status is 404 for a missing page, None for an unreachable host."""
    # Spaces -> underscores (Wikipedia's canonical form); keep underscores
    # literal, percent-encode everything else (accents, parens, slashes).
    encoded = urllib.parse.quote(title.replace(" ", "_"), safe="_")
    url = REST_SUMMARY + encoded
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT, "Accept": "application/json"})
    backoff = 1.0
    for attempt in range(MAX_RETRIES):
        try:
            with urllib.request.urlopen(req, timeout=20, context=SSL_CONTEXT) as resp:
                return resp.status, json.loads(resp.read().decode("utf-8"))
        except urllib.error.HTTPError as e:
            if e.code == 404:
                return 404, None
            if e.code in (429, 500, 502, 503) and attempt < MAX_RETRIES - 1:
                time.sleep(backoff)
                backoff *= 2
                continue
            return e.code, None
        except (urllib.error.URLError, TimeoutError):
            if attempt < MAX_RETRIES - 1:
                time.sleep(backoff)
                backoff *= 2
                continue
            return None, None
    return None, None


def classify(status, payload):
    """Map an API response to a result bucket + the extract length."""
    if status is None:
        return NETWORK, 0
    if status == 404 or payload is None:
        return MISSING, 0
    page_type = payload.get("type")
    if page_type == "disambiguation":
        return DISAMBIGUATION, 0
    extract = (payload.get("extract") or "").strip()
    if not extract or page_type == "no-extract":
        return EMPTY, 0
    if len(extract) < MIN_EXTRACT_CHARS:
        return THIN, len(extract)
    return OK, len(extract)


def main():
    parser = argparse.ArgumentParser(description="Validate SeedCatalog.json against live Wikipedia.")
    parser.add_argument("seed", nargs="?", default=str(DEFAULT_SEED), help="Path to SeedCatalog.json")
    parser.add_argument("--limit", type=int, default=0, help="Only check the first N entries (0 = all)")
    parser.add_argument("--json", dest="json_out", help="Write a machine-readable report to this path")
    args = parser.parse_args()

    seed_path = Path(args.seed)
    if not seed_path.exists():
        print(f"error: seed file not found: {seed_path}", file=sys.stderr)
        return 2

    entries = json.loads(seed_path.read_text())["entries"]
    if args.limit > 0:
        entries = entries[:args.limit]

    total = len(entries)
    print(f"Checking {total} entries against Wikipedia...\n")

    flagged = {MISSING: [], DISAMBIGUATION: [], EMPTY: [], THIN: []}
    network_errors = []
    ok_count = 0
    report = []

    for i, entry in enumerate(entries, 1):
        title = entry["title"]
        status, payload = fetch_summary(title)
        bucket, length = classify(status, payload)
        report.append({"id": entry["id"], "title": title, "result": bucket, "extract_chars": length})

        if bucket == OK:
            ok_count += 1
        elif bucket == NETWORK:
            network_errors.append(title)
            print(f"  [{i:>3}/{total}] ⚠️  unreachable (network)        {title}")
        else:
            flagged[bucket].append(title)
            label = {MISSING: "❌ no page / 404", DISAMBIGUATION: "❌ disambiguation",
                     EMPTY: "❌ title-only (no description)", THIN: f"⚠️  thin ({length} chars)"}[bucket]
            print(f"  [{i:>3}/{total}] {label:<32} {title}")

        time.sleep(REQUEST_PAUSE)

    print("\n" + "=" * 56)
    print(f"  ✅ OK:              {ok_count}")
    print(f"  ❌ no page:         {len(flagged[MISSING])}")
    print(f"  ❌ disambiguation:  {len(flagged[DISAMBIGUATION])}")
    print(f"  ❌ title-only:      {len(flagged[EMPTY])}")
    print(f"  ⚠️  thin:            {len(flagged[THIN])}")
    if network_errors:
        print(f"  ⚠️  unreachable:     {len(network_errors)} (re-run; not a data problem)")
    print("=" * 56)

    total_flagged = sum(len(v) for v in flagged.values())
    if total_flagged:
        print(f"\n{total_flagged} entr{'y' if total_flagged == 1 else 'ies'} worth reviewing/removing in SeedCatalog.json.")

    if args.json_out:
        Path(args.json_out).write_text(json.dumps(report, indent=2))
        print(f"\nWrote machine-readable report to {args.json_out}")

    return 1 if total_flagged else 0


if __name__ == "__main__":
    sys.exit(main())
