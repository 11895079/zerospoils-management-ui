"""Extract top-scanned Canadian products from the OFx full CSV dump.

The full dump is a gzip-compressed, tab-separated CSV (~4 GB compressed).
This script streams it without loading the whole file into memory, filters
for Canadian products, then applies elbow detection and category diversity cap
before writing output compatible with curate_canada_seed_catalog.py.

Download the dump from:
  https://static.openfoodfacts.org/data/en.openfoodfacts.org.products.csv.gz

Usage
-----
    python scripts/extract_canada_top_from_dump.py \\
        --dump-gz /path/to/en.openfoodfacts.org.products.csv.gz \\
        --output-csv app/assets/reference-data/source/canada_top_ca_2026-04-19.csv \\
        --drop-threshold 0.50 \\
        --max-per-category 20

Progress is printed to stderr so you can pipe stdout if needed.
Expected runtime: 5–15 min depending on disk speed (reads ~4 GB compressed).
"""

from __future__ import annotations

import argparse
import csv
import gzip
import io
import json
import sys
import time
from pathlib import Path
from typing import Any

# Re-use the shared helpers from fetch_canada_top_catalog.
# Both scripts live in the same directory.
_SCRIPTS_DIR = Path(__file__).parent
sys.path.insert(0, str(_SCRIPTS_DIR))

from fetch_canada_top_catalog import (
    _category_hint_from_tags,
    _parse_quantity,
    find_elbow_index,
)

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

# Columns we actually need — subset keeps memory low.
_WANTED_COLS = {
    "code",
    "product_name",
    "brands",
    "categories_tags",
    "countries_tags",
    "quantity",
    "unique_scans_n",
}

# The dump uses tab as separator (per https://world.openfoodfacts.org/data/data-fields.txt)
_SEPARATOR = "\t"

# Output CSV fields — matches curate_canada_seed_catalog.py expectation.
_CSV_FIELDS = [
    "barcode",
    "product_name",
    "brand",
    "category_hint",
    "quantity_hint",
    "unit_hint",
]

_CANADA_TAGS = {"en:canada", "en:ca"}


# ---------------------------------------------------------------------------
# Streaming reader
# ---------------------------------------------------------------------------

def _is_canadian(countries_tags: str) -> bool:
    if not countries_tags:
        return False
    tags = {t.strip().lower() for t in countries_tags.split(",")}
    return bool(tags & _CANADA_TAGS)


def _clean(value: str) -> str:
    import re
    return re.sub(r"\s+", " ", (value or "").strip())


def _open_dump(dump_path: Path):
    """Open the dump file whether it is gzip-compressed or a plain CSV."""
    suffix = dump_path.suffix.lower()
    if suffix == ".gz":
        gz = gzip.open(dump_path, "rb")
        return io.TextIOWrapper(gz, encoding="utf-8", errors="replace", newline=""), gz
    else:
        # Plain (uncompressed) CSV — open directly
        fh = dump_path.open("r", encoding="utf-8", errors="replace", newline="")
        return fh, fh


def stream_canadian_products(
    dump_path: Path,
    *,
    verbose: bool = True,
) -> list[dict[str, Any]]:
    """Stream the dump (gzip or plain CSV) and return all Canadian products with scan counts."""
    products: list[dict[str, Any]] = []
    rows_read = 0
    canada_found = 0
    skipped_no_name = 0
    skipped_no_scans = 0
    report_every = 500_000

    start = time.monotonic()

    # Raise the CSV field size limit — OFx rows can contain very long ingredient lists
    csv.field_size_limit(10 * 1024 * 1024)  # 10 MB

    text_stream, handle = _open_dump(dump_path)
    try:
        reader = csv.DictReader(text_stream, delimiter=_SEPARATOR)

        # Validate expected columns exist
        if reader.fieldnames:
            missing = _WANTED_COLS - set(reader.fieldnames)
            if "code" in missing or "countries_tags" in missing:
                raise ValueError(
                    f"Dump is missing critical columns: {missing}. "
                    "Is this the correct OFx CSV file?"
                )

        for row in reader:
            rows_read += 1

            if verbose and rows_read % report_every == 0:
                elapsed = time.monotonic() - start
                print(
                    f"  Rows read: {rows_read:,}  |  Canadian found: {canada_found:,}  "
                    f"|  Elapsed: {elapsed:.0f}s",
                    file=sys.stderr,
                )

            if not _is_canadian(row.get("countries_tags", "")):
                continue

            name = _clean(row.get("product_name", ""))
            code = _clean(row.get("code", ""))
            if not name or not code:
                skipped_no_name += 1
                continue

            try:
                scans = int(row.get("unique_scans_n") or 0)
            except (ValueError, TypeError):
                scans = 0

            if scans <= 0:
                skipped_no_scans += 1
                continue

            cats = _clean(row.get("categories_tags", ""))
            qty_raw = _clean(row.get("quantity", ""))
            qty, unit = _parse_quantity(qty_raw)

            products.append(
                {
                    "barcode": code,
                    "product_name": name,
                    "brand": _clean(row.get("brands", "")),
                    "categories_tags": cats,
                    "category_hint": _category_hint_from_tags(cats),
                    "quantity_hint": qty,
                    "unit_hint": unit,
                    "unique_scans_n": scans,
                }
            )
            canada_found += 1
    finally:
        handle.close()

    elapsed = time.monotonic() - start
    if verbose:
        print(
            f"\n  Stream complete in {elapsed:.0f}s"
            f"\n  Total rows read:        {rows_read:,}"
            f"\n  Canadian products:      {canada_found:,}"
            f"\n  Skipped (no name/code): {skipped_no_name:,}"
            f"\n  Skipped (zero scans):   {skipped_no_scans:,}",
            file=sys.stderr,
        )

    return products


# ---------------------------------------------------------------------------
# Filter: sort → elbow → category cap
# ---------------------------------------------------------------------------

def apply_elbow_and_cap(
    products: list[dict[str, Any]],
    *,
    drop_threshold: float,
    max_per_category: int,
    min_results: int,
) -> tuple[list[dict[str, str]], dict[str, Any]]:
    """Sort by scan count, detect elbow, apply category cap, return (rows, diagnostics)."""
    # Sort descending by unique_scans_n
    products.sort(key=lambda p: p["unique_scans_n"], reverse=True)

    scan_counts = [p["unique_scans_n"] for p in products]

    # Elbow detection — only look after min_results
    elbow = len(products)
    if len(scan_counts) >= min_results:
        elbow_in_tail = find_elbow_index(scan_counts[min_results:], drop_threshold)
        elbow = min_results + elbow_in_tail

    before_cap = products[:elbow]

    # Category diversity cap
    category_counts: dict[str, int] = {}
    accepted: list[dict[str, Any]] = []
    rejected_cap = 0

    for p in before_cap:
        cat = p["category_hint"]
        if category_counts.get(cat, 0) >= max_per_category:
            rejected_cap += 1
            continue
        category_counts[cat] = category_counts.get(cat, 0) + 1
        accepted.append(p)

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
        "total_canadian_with_scans": len(products),
        "after_elbow": len(before_cap),
        "rejected_by_category_cap": rejected_cap,
        "accepted": len(rows),
        "elbow_at_index": elbow,
        "top_scan_count": products[0]["unique_scans_n"] if products else 0,
        "bottom_accepted_scan_count": accepted[-1]["unique_scans_n"] if accepted else 0,
        "category_counts": category_counts,
    }

    return rows, diagnostics


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def run_cli(args: argparse.Namespace) -> int:
    dump_path = Path(args.dump_gz)
    if not dump_path.exists():
        print(f"ERROR: dump file not found: {dump_path}", file=sys.stderr)
        return 1

    print(f"Streaming {dump_path.name} ({dump_path.stat().st_size / 1_073_741_824:.2f} GB) …", file=sys.stderr)

    products = stream_canadian_products(dump_path, verbose=True)

    if not products:
        print("ERROR: No Canadian products with scan counts found. Check the dump file.", file=sys.stderr)
        return 1

    rows, diagnostics = apply_elbow_and_cap(
        products,
        drop_threshold=args.drop_threshold,
        max_per_category=args.max_per_category,
        min_results=args.min_results,
    )

    print(
        f"\n  Canadian products with scans: {diagnostics['total_canadian_with_scans']:,}"
        f"\n  After elbow (index {diagnostics['elbow_at_index']}):     {diagnostics['after_elbow']:,}"
        f"\n  Rejected (category cap):      {diagnostics['rejected_by_category_cap']:,}"
        f"\n  Accepted for CSV:             {diagnostics['accepted']:,}"
        f"\n  Scan range:                   {diagnostics['bottom_accepted_scan_count']} – {diagnostics['top_scan_count']}"
        f"\n  Category breakdown:\n{json.dumps(diagnostics['category_counts'], indent=6)}",
        file=sys.stderr,
    )

    output_path = Path(args.output_csv)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("w", encoding="utf-8", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=_CSV_FIELDS)
        writer.writeheader()
        writer.writerows(rows)

    print(f"\nWrote {len(rows)} rows → {output_path}", file=sys.stderr)
    print(
        f"\nNext step — run through curation pipeline:\n"
        f"  python scripts/curate_canada_seed_catalog.py \\\n"
        f"    --input-csv {args.output_csv} \\\n"
        f"    --output-json app/assets/reference-data/barcode_seed_ca.v2.json \\\n"
        f"    --report-json app/assets/reference-data/barcode_seed_ca.v2.report.json \\\n"
        f"    --source-name openfoodfacts-full-dump-canada-top-scanned \\\n"
        f"    --dataset-version 2026-04-19",
        file=sys.stderr,
    )
    return 0


def _build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p.add_argument(
        "--dump-gz",
        required=True,
        help="Path to the downloaded en.openfoodfacts.org.products.csv.gz file.",
    )
    p.add_argument(
        "--output-csv",
        required=True,
        help="Path to write the output CSV (input for curate_canada_seed_catalog.py).",
    )
    p.add_argument(
        "--drop-threshold",
        type=float,
        default=0.50,
        help=(
            "Fraction drop in unique_scans_n that defines the elbow. "
            "Default: 0.50 (stop when a product's scans are <50%% of previous)."
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
        help="Minimum products to keep before elbow detection kicks in. Default: 30.",
    )
    return p


def main() -> int:
    return run_cli(_build_parser().parse_args())


if __name__ == "__main__":
    raise SystemExit(main())
