#!/usr/bin/env python3
"""Generate Wave A barcode seed artifacts for configured regions.

This script wires the region-aware fetch and curation pipeline:
1) fetch top scanned products from OpenFoodFacts by country query
2) write source CSV for traceability
3) curate into app-ready seed JSON + size report
"""

from __future__ import annotations

import argparse
import csv
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from curate_canada_seed_catalog import build_seed_catalog
from extract_canada_top_from_dump import apply_elbow_and_cap, stream_country_products
from fetch_canada_top_catalog import fetch_top_region


_CSV_FIELDS = [
    "barcode",
    "product_name",
    "brand",
    "category_hint",
    "quantity_hint",
    "unit_hint",
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--config",
        default="scripts/reference_pack_barcode_sources.wave_a.json",
        help="Path to Wave A barcode source config JSON",
    )
    parser.add_argument(
        "--dataset-version",
        required=True,
        help="Dataset version label used in generated metadata",
    )
    parser.add_argument(
        "--generated-at",
        help="ISO-8601 UTC timestamp, defaults to now",
    )
    parser.add_argument(
        "--regions",
        help="Optional comma-separated region filter (for partial generation)",
    )
    parser.add_argument(
        "--dump-gz",
        help=(
            "Optional path to en.openfoodfacts.org.products.csv.gz. "
            "When provided, artifacts are generated from the local dump instead of the OFx API."
        ),
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print planned actions without fetching/writing outputs",
    )
    return parser.parse_args()


def _load_json(path: Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ValueError(f"{path} must contain a JSON object")
    return payload


def _write_csv(path: Path, rows: list[dict[str, str]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=_CSV_FIELDS)
        writer.writeheader()
        writer.writerows(rows)


def _utc_now_iso() -> str:
    now = datetime.now(tz=timezone.utc).replace(microsecond=0)
    return now.isoformat().replace("+00:00", "Z")


def _selected_regions(raw: str | None) -> set[str]:
    if not raw:
        return set()
    return {token.strip().lower() for token in raw.split(",") if token.strip()}


def _source_country_tags(source: dict[str, Any]) -> set[str]:
    raw = source.get("country_tags", [])
    if not isinstance(raw, list):
        return set()
    return {str(tag).strip().lower() for tag in raw if str(tag).strip()}


def generate_wave_a_barcode_artifacts(
    *,
    config: dict[str, Any],
    dataset_version: str,
    generated_at: str,
    selected_regions: set[str],
    dump_gz: Path | None,
    dry_run: bool,
) -> dict[str, Any]:
    defaults = config.get("defaults", {})
    sources = config.get("sources", [])
    if not isinstance(sources, list) or not sources:
        raise ValueError("config.sources must be a non-empty array")

    summary: dict[str, Any] = {"wave": config.get("wave", "A"), "regions": {}}

    for source in sources:
        region = str(source["region"]).lower()
        if selected_regions and region not in selected_regions:
            continue

        country_query = str(source["country_query"])
        output_csv = Path(str(source["output_csv"]))
        output_json = Path(str(source["output_json"]))
        report_json = Path(str(source["report_json"]))
        source_name = str(source["source_name"])
        country_label = str(source.get("country_label", region.upper()))
        country_tags = _source_country_tags(source)

        drop_threshold = float(source.get("drop_threshold", defaults.get("drop_threshold", 0.5)))
        max_per_category = int(source.get("max_per_category", defaults.get("max_per_category", 10)))
        min_results = int(source.get("min_results", defaults.get("min_results", 30)))
        max_results = int(source.get("max_results", defaults.get("max_results", 500)))
        max_bytes = int(source.get("max_bytes", defaults.get("max_bytes", 1_500_000)))

        if dry_run:
            print(
                f"[dry-run] region={region} country_query={country_query} "
                f"csv={output_csv} json={output_json} "
                f"mode={'dump' if dump_gz else 'api'}"
            )
            continue

        if dump_gz is not None:
            if not dump_gz.exists():
                raise FileNotFoundError(f"Dump file not found: {dump_gz}")
            if not country_tags:
                raise ValueError(f"source.country_tags is required for dump mode (region={region})")

            products = stream_country_products(
                dump_gz,
                allowed_country_tags=country_tags,
                country_label=country_label,
                verbose=True,
            )
            rows, diagnostics = apply_elbow_and_cap(
                products,
                drop_threshold=drop_threshold,
                max_per_category=max_per_category,
                min_results=min_results,
            )
            diagnostics = {
                **diagnostics,
                "country_label": country_label,
                "country_tags": sorted(country_tags),
                "source_mode": "dump",
                "dump_path": str(dump_gz),
            }
        else:
            rows, diagnostics = fetch_top_region(
                country_query=country_query,
                drop_threshold=drop_threshold,
                max_per_category=max_per_category,
                min_results=min_results,
                max_results=max_results,
                verbose=True,
            )
            diagnostics = {
                **diagnostics,
                "source_mode": "api",
            }

        _write_csv(output_csv, rows)

        curated = build_seed_catalog(
            rows=rows,
            source_name=source_name,
            dataset_version=dataset_version,
            generated_at=generated_at,
            max_bytes=max_bytes,
            region=region,
        )

        output_json.parent.mkdir(parents=True, exist_ok=True)
        output_json.write_text(
            json.dumps(
                {
                    "metadata": curated["metadata"],
                    "records": curated["records"],
                },
                indent=2,
                sort_keys=True,
                ensure_ascii=True,
            ),
            encoding="utf-8",
        )

        report_json.parent.mkdir(parents=True, exist_ok=True)
        report_json.write_text(
            json.dumps(
                {
                    **curated["report"],
                    "fetch_diagnostics": diagnostics,
                },
                indent=2,
                sort_keys=True,
                ensure_ascii=True,
            ),
            encoding="utf-8",
        )

        summary["regions"][region] = {
            "country_query": country_query,
            "rows": len(rows),
            "source_mode": diagnostics.get("source_mode", "api"),
            "output_csv": str(output_csv),
            "output_json": str(output_json),
            "report_json": str(report_json),
            "size_bytes": curated["report"]["size_bytes"],
        }

    return summary


def main() -> int:
    args = parse_args()
    config = _load_json(Path(args.config))
    generated_at = args.generated_at or _utc_now_iso()

    summary = generate_wave_a_barcode_artifacts(
        config=config,
        dataset_version=args.dataset_version,
        generated_at=generated_at,
        selected_regions=_selected_regions(args.regions),
        dump_gz=Path(args.dump_gz) if args.dump_gz else None,
        dry_run=args.dry_run,
    )

    if not args.dry_run:
        print(json.dumps(summary, indent=2, ensure_ascii=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
