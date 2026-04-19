"""Curate a Canada-first offline seed barcode catalog for packaged-item lookup.

This script normalizes source rows into an app-ready artifact and emits a size report.
"""

from __future__ import annotations

import argparse
import csv
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

REQUIRED_FIELDS = ("barcode", "product_name", "category_hint")
SCHEMA_VERSION = 1


def _passes_gtin_checksum(barcode: str) -> bool:
    digits = [int(ch) for ch in barcode]
    check_digit = digits[-1]
    body = digits[:-1]
    total = 0
    for index, digit in enumerate(reversed(body), start=1):
        total += digit * (3 if index % 2 == 1 else 1)
    expected = (10 - (total % 10)) % 10
    return expected == check_digit


def normalize_barcode(raw_value: str | None) -> str | None:
    if not raw_value:
        return None
    digits_only = "".join(ch for ch in raw_value if ch.isdigit())
    if len(digits_only) < 8 or len(digits_only) > 14:
        return None
    if not _passes_gtin_checksum(digits_only):
        return None
    return digits_only


def _normalize_text(value: Any) -> str:
    return str(value).strip() if value is not None else ""


def _record_completeness_score(record: dict[str, str]) -> int:
    fields = (
        "product_name",
        "brand",
        "category_hint",
        "quantity_hint",
        "unit_hint",
    )
    return sum(1 for field in fields if record.get(field, ""))


def _to_normalized_record(
    raw: dict[str, Any],
    *,
    source_name: str,
    generated_at: str,
    region: str,
) -> dict[str, str] | None:
    barcode = normalize_barcode(_normalize_text(raw.get("barcode")))
    if barcode is None:
        return None

    record = {
        "barcode": barcode,
        "product_name": _normalize_text(raw.get("product_name")),
        "brand": _normalize_text(raw.get("brand")),
        "category_hint": _normalize_text(raw.get("category_hint")),
        "quantity_hint": _normalize_text(raw.get("quantity_hint")),
        "unit_hint": _normalize_text(raw.get("unit_hint")),
        "region": region,
        "source": source_name,
        "last_curated_at": generated_at,
    }

    for field in REQUIRED_FIELDS:
        if not record.get(field):
            return None

    return record


def build_seed_catalog(
    *,
    rows: list[dict[str, Any]],
    source_name: str,
    dataset_version: str,
    generated_at: str,
    max_bytes: int,
    region: str = "ca",
) -> dict[str, Any]:
    deduped: dict[str, dict[str, str]] = {}
    rejected_malformed_barcode = 0
    rejected_missing_required = 0
    duplicates_collapsed = 0

    for raw in rows:
        barcode_probe = normalize_barcode(_normalize_text(raw.get("barcode")))
        if barcode_probe is None:
            rejected_malformed_barcode += 1
            continue

        normalized = _to_normalized_record(
            raw,
            source_name=source_name,
            generated_at=generated_at,
            region=region,
        )
        if normalized is None:
            rejected_missing_required += 1
            continue

        existing = deduped.get(normalized["barcode"])
        if existing is None:
            deduped[normalized["barcode"]] = normalized
            continue

        duplicates_collapsed += 1
        if _record_completeness_score(normalized) > _record_completeness_score(existing):
            deduped[normalized["barcode"]] = normalized

    records = [deduped[key] for key in sorted(deduped.keys())]

    artifact = {
        "metadata": {
            "schema_version": SCHEMA_VERSION,
            "region": region,
            "dataset_version": dataset_version,
            "generated_at": generated_at,
            "record_count": len(records),
        },
        "records": records,
    }

    encoded = json.dumps(artifact, indent=2, sort_keys=True, ensure_ascii=True)
    size_bytes = len(encoded.encode("utf-8"))
    if size_bytes > max_bytes:
        raise ValueError(
            f"artifact size {size_bytes} exceeds max bytes {max_bytes}"
        )

    return {
        "metadata": artifact["metadata"],
        "records": records,
        "report": {
            "input_rows": len(rows),
            "record_count": len(records),
            "duplicates_collapsed": duplicates_collapsed,
            "rejected_malformed_barcode": rejected_malformed_barcode,
            "rejected_missing_required": rejected_missing_required,
            "size_bytes": size_bytes,
            "max_bytes": max_bytes,
        },
    }


def _read_csv_rows(path: Path) -> list[dict[str, Any]]:
    with path.open("r", encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle)
        return [dict(row) for row in reader]


def _utc_now_iso() -> str:
    return datetime.now(tz=timezone.utc).replace(microsecond=0).isoformat().replace(
        "+00:00", "Z"
    )


def run_cli(args: argparse.Namespace) -> int:
    rows = _read_csv_rows(Path(args.input_csv))
    generated_at = args.generated_at or _utc_now_iso()

    result = build_seed_catalog(
        rows=rows,
        source_name=args.source_name,
        dataset_version=args.dataset_version,
        generated_at=generated_at,
        max_bytes=args.max_bytes,
    )

    output_path = Path(args.output_json)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_payload = {
        "metadata": result["metadata"],
        "records": result["records"],
    }
    output_path.write_text(
        json.dumps(output_payload, indent=2, sort_keys=True, ensure_ascii=True),
        encoding="utf-8",
    )

    report_path = Path(args.report_json)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(
        json.dumps(result["report"], indent=2, sort_keys=True, ensure_ascii=True),
        encoding="utf-8",
    )

    print(f"Wrote catalog: {output_path}")
    print(f"Wrote report:  {report_path}")
    print(f"Records: {result['report']['record_count']}")
    print(f"Size bytes: {result['report']['size_bytes']}")
    return 0


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input-csv", required=True)
    parser.add_argument("--output-json", required=True)
    parser.add_argument("--report-json", required=True)
    parser.add_argument("--source-name", required=True)
    parser.add_argument("--dataset-version", required=True)
    parser.add_argument("--generated-at")
    parser.add_argument("--max-bytes", type=int, default=1_500_000)
    return parser


def main() -> int:
    parser = _build_parser()
    args = parser.parse_args()
    return run_cli(args)


if __name__ == "__main__":
    raise SystemExit(main())
