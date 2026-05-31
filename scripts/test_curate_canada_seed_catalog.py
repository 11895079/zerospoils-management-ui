"""Tests for scripts/curate_canada_seed_catalog.py."""

from pathlib import Path
import sys
from types import SimpleNamespace
import json

import pytest

sys.path.insert(0, str(Path(__file__).parent))

from curate_canada_seed_catalog import (
    build_seed_catalog,
    normalize_barcode,
    run_cli,
)


def test_normalize_barcode_rejects_invalid_values():
    assert normalize_barcode("abc") is None
    assert normalize_barcode("1234567") is None  # too short
    assert normalize_barcode("123456789012345") is None  # too long


def test_normalize_barcode_rejects_invalid_gtin_checksum():
    assert normalize_barcode("0678000012345") is None
    assert normalize_barcode("062639122245") is None


def test_build_seed_catalog_rejects_malformed_and_missing_required_fields():
    rows = [
        {
            "barcode": "055000132152",
            "product_name": "Instant Coffee",
            "brand": "Nescafe",
            "category_hint": "pantry",
            "quantity_hint": "475",
            "unit_hint": "g",
        },
        {
            "barcode": "not-a-barcode",
            "product_name": "Invalid",
            "brand": "Bad",
            "category_hint": "other",
            "quantity_hint": "1",
            "unit_hint": "ea",
        },
        {
            "barcode": "0059161402208",
            "product_name": "",  # missing required
            "brand": "Olympic",
            "category_hint": "dairy",
            "quantity_hint": "1.75",
            "unit_hint": "kg",
        },
    ]

    result = build_seed_catalog(
        rows=rows,
        source_name="unit-test-source",
        dataset_version="2026-04-13",
        generated_at="2026-04-13T00:00:00Z",
        max_bytes=10_000,
    )

    assert len(result["records"]) == 1
    assert result["report"]["rejected_malformed_barcode"] == 1
    assert result["report"]["rejected_missing_required"] == 1


def test_build_seed_catalog_deduplicates_and_prefers_richer_record():
    rows = [
        {
            "barcode": "0064200116442",
            "product_name": "Spaghetti",
            "brand": "",
            "category_hint": "pantry",
            "quantity_hint": "",
            "unit_hint": "",
        },
        {
            "barcode": "0064200116442",
            "product_name": "Spaghetti",
            "brand": "Catelli",
            "category_hint": "pantry",
            "quantity_hint": "500",
            "unit_hint": "g",
        },
    ]

    result = build_seed_catalog(
        rows=rows,
        source_name="unit-test-source",
        dataset_version="2026-04-13",
        generated_at="2026-04-13T00:00:00Z",
        max_bytes=10_000,
    )

    assert len(result["records"]) == 1
    record = result["records"][0]
    assert record["product_name"] == "Spaghetti"
    assert record["brand"] == "Catelli"
    assert record["quantity_hint"] == "500"
    assert result["report"]["duplicates_collapsed"] == 1


def test_build_seed_catalog_emits_required_schema_and_metadata():
    rows = [
        {
            "barcode": "0059161402208",
            "product_name": "Greek Plain Yogurt",
            "brand": "Olympic",
            "category_hint": "dairy",
            "quantity_hint": "1.75",
            "unit_hint": "kg",
        }
    ]

    result = build_seed_catalog(
        rows=rows,
        source_name="unit-test-source",
        dataset_version="2026-04-13",
        generated_at="2026-04-13T00:00:00Z",
        max_bytes=10_000,
    )

    assert result["metadata"]["schema_version"] == 1
    assert result["metadata"]["region"] == "ca"
    assert result["metadata"]["dataset_version"] == "2026-04-13"
    assert result["metadata"]["generated_at"] == "2026-04-13T00:00:00Z"
    assert result["metadata"]["record_count"] == 1

    record = result["records"][0]
    assert set(record.keys()) == {
        "barcode",
        "product_name",
        "brand",
        "category_hint",
        "quantity_hint",
        "unit_hint",
        "region",
        "source",
        "last_curated_at",
    }


def test_build_seed_catalog_fails_when_size_budget_is_exceeded():
    rows = [
        {
            "barcode": "0059161402208",
            "product_name": "Greek Plain Yogurt",
            "brand": "Olympic",
            "category_hint": "dairy",
            "quantity_hint": "1.75",
            "unit_hint": "kg",
        }
    ]

    with pytest.raises(ValueError, match="exceeds max bytes"):
        build_seed_catalog(
            rows=rows,
            source_name="unit-test-source",
            dataset_version="2026-04-13",
            generated_at="2026-04-13T00:00:00Z",
            max_bytes=50,
        )


def test_run_cli_respects_region_argument(tmp_path):
    input_csv = tmp_path / 'input.csv'
    input_csv.write_text(
        'barcode,product_name,brand,category_hint,quantity_hint,unit_hint\n'
        '055000132152,Instant Coffee,Nescafe,pantry,475,g\n',
        encoding='utf-8',
    )

    output_json = tmp_path / 'output.json'
    report_json = tmp_path / 'report.json'

    args = SimpleNamespace(
        input_csv=str(input_csv),
        output_json=str(output_json),
        report_json=str(report_json),
        source_name='unit-test-source',
        dataset_version='2026-05-31',
        generated_at='2026-05-31T00:00:00Z',
        max_bytes=10_000,
        region='us',
    )

    exit_code = run_cli(args)

    assert exit_code == 0
    payload = json.loads(output_json.read_text(encoding='utf-8'))
    assert payload['metadata']['region'] == 'us'
    assert payload['records'][0]['region'] == 'us'

