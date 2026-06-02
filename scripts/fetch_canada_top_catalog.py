"""Fetch top-scanned grocery products for a country query from OpenFoodFacts.

Algorithm
---------
1. Hit OFx API v2 search sorted by unique_scans_n (country-scoped, food products).
2. Collect pages until an *elbow* is detected in the scan-count distribution:
   an entry whose scan count has dropped by more than `--drop-threshold` (default 0.50)
   relative to the previous entry signals the long tail boundary.
3. Apply a per-category diversity cap (default 10 entries per category).
4. Write a CSV compatible with curate_canada_seed_catalog.py.

Usage
-----
    python scripts/fetch_canada_top_catalog.py \
        --output-csv app/assets/reference-data/source/canada_top_ca_$(date +%F).csv \\
        --country-query canada \
        --region ca \
        --drop-threshold 0.50 \\
        --max-per-category 10 \\
        --min-results 30 \\
        --max-results 500

Dry-run (no network, shows arg parsing only):
    python scripts/fetch_canada_top_catalog.py --dry-run --output-csv /tmp/out.csv
"""

from __future__ import annotations

import argparse
import csv
import json
import sys
import time
import urllib.error
import urllib.request
import urllib.parse
from pathlib import Path
from typing import Any

# ---------------------------------------------------------------------------
# OFx category tag → app category_hint mapping
# ---------------------------------------------------------------------------

# Priority-ordered: first match wins (most specific first).
_OFX_CATEGORY_MAP: list[tuple[str, str]] = [
    ("en:beverages", "beverages"),
    ("en:plant-based-foods-and-beverages", "beverages"),
    ("en:dairies", "dairy"),
    ("en:cheeses", "dairy"),
    ("en:milks", "dairy"),
    ("en:yogurts", "dairy"),
    ("en:meats", "protein"),
    ("en:poultry", "protein"),
    ("en:fish-and-seafood", "protein"),
    ("en:seafood", "protein"),
    ("en:eggs", "protein"),
    ("en:plant-based-foods", "produce"),
    ("en:fruits", "produce"),
    ("en:vegetables", "produce"),
    ("en:fresh-foods", "produce"),
    ("en:frozen-foods", "frozen"),
    ("en:snacks", "snacks"),
    ("en:confectioneries", "snacks"),
    ("en:breakfast-cereals", "pantry"),
    ("en:cereals-and-potatoes", "pantry"),
    ("en:breads", "bakery"),
    ("en:baked-goods", "bakery"),
    ("en:condiments", "condiments"),
    ("en:sauces", "condiments"),
    ("en:spices-and-seasonings", "condiments"),
    ("en:canned-foods", "pantry"),
    ("en:pastas", "pantry"),
    ("en:rice", "pantry"),
    ("en:soups", "pantry"),
    ("en:sweeteners", "pantry"),
    ("en:oils-and-fats", "pantry"),
]


def _category_hint_from_tags(tags_raw: str) -> str:
    """Map a comma-separated OFx categories_tags string to an app category_hint."""
    if not tags_raw:
        return "pantry"
    tags = {t.strip().lower() for t in tags_raw.split(",")}
    for ofx_tag, hint in _OFX_CATEGORY_MAP:
        if ofx_tag in tags:
            return hint
    return "pantry"


# ---------------------------------------------------------------------------
# OFx API client
# ---------------------------------------------------------------------------

_OFX_SEARCH_URL_TEMPLATE = (
    "https://world.openfoodfacts.org/cgi/search.pl"
    "?action=process"
    "&tagtype_0=countries&tag_contains_0=contains&tag_0={country_query}"
    "&sort_by=unique_scans_n"
    "&page_size={page_size}"
    "&page={page}"
    "&fields=code,product_name,brands,categories_tags,unique_scans_n,quantity"
    "&json=1"
)

_USER_AGENT = "ZeroSpoils-CatalogFetcher/1.0 (github.com/11895079/zerospoils)"


def _fetch_page(
    page: int,
    page_size: int,
    country_query: str,
    *,
    timeout: int = 30,
    max_retries: int = 4,
) -> dict[str, Any]:
    encoded_country_query = urllib.parse.quote_plus(country_query)
    url = _OFX_SEARCH_URL_TEMPLATE.format(
        page=page,
        page_size=page_size,
        country_query=encoded_country_query,
    )
    req = urllib.request.Request(url, headers={"User-Agent": _USER_AGENT})
    delay = 5.0
    for attempt in range(max_retries):
        try:
            with urllib.request.urlopen(req, timeout=timeout) as resp:
                return json.loads(resp.read().decode("utf-8"))
        except urllib.error.HTTPError as exc:
            if exc.code in (429, 503, 502) and attempt < max_retries - 1:
                print(
                    f"  HTTP {exc.code} on page {page} attempt {attempt + 1}/"
                    f"{max_retries} — retrying in {delay:.0f}s …",
                    file=sys.stderr,
                )
                time.sleep(delay)
                delay *= 2
            else:
                raise
        except (urllib.error.URLError, TimeoutError) as exc:
            if attempt < max_retries - 1:
                print(
                    f"  Network error page {page} attempt {attempt + 1}/"
                    f"{max_retries} ({exc}) — retrying in {delay:.0f}s …",
                    file=sys.stderr,
                )
                time.sleep(delay)
                delay *= 2
            else:
                raise
    raise RuntimeError("unreachable")


def _clean_name(raw: str | None) -> str:
    if not raw:
        return ""
    # Strip leading/trailing whitespace, collapse internal whitespace
    import re
    return re.sub(r"\s+", " ", raw.strip())


# ---------------------------------------------------------------------------
# Elbow detection
# ---------------------------------------------------------------------------

def find_elbow_index(scan_counts: list[int], drop_threshold: float) -> int:
    """Return the index (exclusive) at which the natural elbow occurs.

    An elbow is defined as the first position i (i >= 1) where:
        scan_counts[i] / scan_counts[i - 1] < (1 - drop_threshold)

    If no elbow is found, returns len(scan_counts) (keep everything).

    Args:
        scan_counts: Descending list of unique_scans_n values (must all be > 0).
        drop_threshold: Fraction drop that constitutes a significant break.
                        E.g. 0.50 means a >50% drop triggers the elbow.
    """
    if len(scan_counts) < 2:
        return len(scan_counts)
    ratio_threshold = 1.0 - drop_threshold
    for i in range(1, len(scan_counts)):
        if scan_counts[i - 1] == 0:
            return i
        ratio = scan_counts[i] / scan_counts[i - 1]
        if ratio < ratio_threshold:
            return i
    return len(scan_counts)


# ---------------------------------------------------------------------------
# Core fetch + filter logic
# ---------------------------------------------------------------------------

def fetch_top_region(
    *,
    country_query: str,
    drop_threshold: float,
    max_per_category: int,
    min_results: int,
    max_results: int,
    page_size: int = 100,
    rate_limit_seconds: float = 1.0,
    verbose: bool = False,
) -> tuple[list[dict[str, str]], dict[str, Any]]:
    """Fetch OFx products for a country query and return (rows, diagnostics).

    rows are dicts matching curate_canada_seed_catalog.py column schema:
        barcode, product_name, brand, category_hint, quantity_hint, unit_hint
    """
    all_products: list[dict[str, Any]] = []
    page = 1
    total_fetched = 0

    while total_fetched < max_results:
        if verbose:
            print(f"  Fetching OFx page {page} …", file=sys.stderr)

        data = _fetch_page(
            page,
            page_size=min(page_size, max_results - total_fetched),
            country_query=country_query,
        )
        products = data.get("products", [])
        if not products:
            break

        for p in products:
            scans = p.get("unique_scans_n", 0)
            code = str(p.get("code") or "").strip()
            name = _clean_name(p.get("product_name"))
            brand = _clean_name(p.get("brands"))
            cats = p.get("categories_tags") or ""
            if isinstance(cats, list):
                cats = ",".join(cats)
            qty_raw = _clean_name(p.get("quantity") or "")

            if not code or not name or scans <= 0:
                continue

            qty, unit = _parse_quantity(qty_raw)
            all_products.append(
                {
                    "barcode": code,
                    "product_name": name,
                    "brand": brand,
                    "categories_tags": cats,
                    "category_hint": _category_hint_from_tags(cats),
                    "quantity_hint": qty,
                    "unit_hint": unit,
                    "unique_scans_n": int(scans),
                }
            )

        total_fetched += len(products)

        # Check if we have enough to detect the elbow and stop early
        if len(all_products) >= min_results:
            scan_counts = [p["unique_scans_n"] for p in all_products[min_results:]]
            elbow_offset = find_elbow_index(scan_counts, drop_threshold)
            elbow = min_results + elbow_offset
            if elbow < len(all_products):
                # Elbow found after the minimum required results — trim and stop fetching
                all_products = all_products[:elbow]
                if verbose:
                    print(
                        f"  Elbow detected at position {elbow} "
                        f"(scans dropped >{drop_threshold*100:.0f}%). Stopping.",
                        file=sys.stderr,
                    )
                break

        if len(products) < page_size:
            break  # Last page reached

        page += 1
        time.sleep(rate_limit_seconds)

    # --- Category diversity cap ---
    category_counts: dict[str, int] = {}
    accepted: list[dict[str, Any]] = []
    rejected_cat_cap = 0

    for p in all_products:
        cat = p["category_hint"]
        if category_counts.get(cat, 0) >= max_per_category:
            rejected_cat_cap += 1
            continue
        category_counts[cat] = category_counts.get(cat, 0) + 1
        accepted.append(p)

    # Build output rows
    rows = [
        {
            "barcode": p["barcode"],
            "product_name": p["product_name"],
            "brand": p["brand"],
            "category_hint": p["category_hint"],
            "quantity_hint": p["quantity_hint"],
            "unit_hint": p["unit_hint"],
        }
        for p in accepted
    ]

    diagnostics = {
        "country_query": country_query,
        "total_fetched_from_api": total_fetched,
        "after_basic_filter": len(all_products),
        "rejected_by_category_cap": rejected_cat_cap,
        "accepted": len(rows),
        "category_counts": category_counts,
        "top_scan_count": all_products[0]["unique_scans_n"] if all_products else 0,
        "bottom_scan_count": all_products[-1]["unique_scans_n"] if all_products else 0,
    }

    return rows, diagnostics


def fetch_top_canada(
    *,
    drop_threshold: float,
    max_per_category: int,
    min_results: int,
    max_results: int,
    page_size: int = 100,
    rate_limit_seconds: float = 1.0,
    verbose: bool = False,
) -> tuple[list[dict[str, str]], dict[str, Any]]:
    """Backward-compatible alias for Canada behavior."""
    return fetch_top_region(
        country_query="canada",
        drop_threshold=drop_threshold,
        max_per_category=max_per_category,
        min_results=min_results,
        max_results=max_results,
        page_size=page_size,
        rate_limit_seconds=rate_limit_seconds,
        verbose=verbose,
    )


def _parse_quantity(raw: str) -> tuple[str, str]:
    """Split '500 ml' into ('500', 'ml'). Returns ('', '') if unparseable."""
    import re
    m = re.match(r"^([\d.,]+)\s*([a-zA-Z%]+)?", raw)
    if not m:
        return ("", "")
    qty = m.group(1) or ""
    unit = (m.group(2) or "").lower()
    return (qty, unit)


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

_CSV_FIELDS = [
    "barcode",
    "product_name",
    "brand",
    "category_hint",
    "quantity_hint",
    "unit_hint",
]


def run_cli(args: argparse.Namespace) -> int:
    if args.dry_run:
        print("Dry-run mode: no network calls made.")
        print(f"  output-csv:        {args.output_csv}")
        print(f"  drop-threshold:    {args.drop_threshold}")
        print(f"  max-per-category:  {args.max_per_category}")
        print(f"  min-results:       {args.min_results}")
        print(f"  max-results:       {args.max_results}")
        print(f"  country-query:     {args.country_query}")
        print(f"  region:            {args.region}")
        return 0

    print(
        "Fetching from OpenFoodFacts "
        f"(country query: {args.country_query}, sorted by unique_scans_n) ..."
    )
    rows, diagnostics = fetch_top_region(
        country_query=args.country_query,
        drop_threshold=args.drop_threshold,
        max_per_category=args.max_per_category,
        min_results=args.min_results,
        max_results=args.max_results,
        verbose=True,
    )

    print(
        f"\n  API products fetched:    {diagnostics['total_fetched_from_api']}"
        f"\n  After elbow / filter:    {diagnostics['after_basic_filter']}"
        f"\n  Rejected (cat cap):      {diagnostics['rejected_by_category_cap']}"
        f"\n  Accepted for CSV:        {diagnostics['accepted']}"
        f"\n  Scan range:              {diagnostics['bottom_scan_count']} – "
        f"{diagnostics['top_scan_count']}"
        f"\n  Country query:           {diagnostics['country_query']}"
        f"\n  Category breakdown:      {json.dumps(diagnostics['category_counts'], indent=4)}"
    )

    output_path = Path(args.output_csv)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("w", encoding="utf-8", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=_CSV_FIELDS)
        writer.writeheader()
        writer.writerows(rows)

    print(f"\nWrote {len(rows)} rows → {output_path}")
    print(
        "\nNext step — run through curation pipeline:\n"
        f"  python scripts/curate_canada_seed_catalog.py \\\n"
        f"    --input-csv {args.output_csv} \\\n"
        f"    --output-json app/assets/reference-data/barcode_seed_{args.region}.v1.json \\\n "
        f"    --report-json app/assets/reference-data/barcode_seed_{args.region}.v1.report.json \\\n "
        f"    --source-name openfoodfacts-{args.country_query}-top-scanned \\\n "
        f"    --region {args.region} \\\n "
        f"    --dataset-version $(date +%F)"
    )
    return 0


def _build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--output-csv", required=True, help="Path to write the output CSV.")
    p.add_argument(
        "--country-query",
        default="canada",
        help=(
            "OpenFoodFacts country query value for tag_0 filter. "
            "Examples: canada, united-states. Default: canada."
        ),
    )
    p.add_argument(
        "--region",
        default="ca",
        help="Region code used downstream for seed artifact metadata. Default: ca.",
    )
    p.add_argument(
        "--drop-threshold",
        type=float,
        default=0.50,
        help=(
            "Fraction drop in unique_scans_n that defines the elbow. "
            "0.50 = stop when a product's scans are <50%% of the previous one. "
            "Lower values are more conservative (keep more). Default: 0.50."
        ),
    )
    p.add_argument(
        "--max-per-category",
        type=int,
        default=10,
        help="Maximum products per category_hint bucket. Default: 10.",
    )
    p.add_argument(
        "--min-results",
        type=int,
        default=30,
        help="Minimum products to fetch before looking for an elbow. Default: 30.",
    )
    p.add_argument(
        "--max-results",
        type=int,
        default=500,
        help="Hard cap on how many products to fetch from the API. Default: 500.",
    )
    p.add_argument(
        "--dry-run",
        action="store_true",
        help="Print arguments and exit without making any API calls.",
    )
    return p


def main() -> int:
    return run_cli(_build_parser().parse_args())


if __name__ == "__main__":
    raise SystemExit(main())
