#!/usr/bin/env python3
"""Receipt corpus golden regression harness (phase 1).

Phase 1 focuses on validating the documented golden JSON references.
Phase 2 can extend this by comparing parser/OCR outputs against these goldens.
"""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any
import subprocess

TOLERANCE = 0.01


@dataclass
class ValidationIssue:
    set_id: str
    message: str


@dataclass
class ValidationResult:
    set_id: str
    passed: bool
    issues: list[ValidationIssue]


@dataclass
class ParserDiffResult:
    set_id: str
    passed: bool
    issues: list[str]


def _as_float(value: Any, default: float = 0.0) -> float:
    if value is None:
        return default
    if isinstance(value, (int, float)):
        return float(value)
    return float(str(value))


def _money_close(left: float, right: float, tolerance: float = TOLERANCE) -> bool:
    return abs(left - right) <= tolerance


def _validate_reference(reference_path: Path) -> ValidationResult:
    data = json.loads(reference_path.read_text(encoding="utf-8"))
    set_id = data.get("set_id", reference_path.parent.name)
    issues: list[ValidationIssue] = []

    required_top_level = [
        "schema_version",
        "set_id",
        "document_type",
        "currency",
        "images",
        "merchant",
        "transaction",
        "items",
        "other_items",
        "summary",
        "tax_breakdown",
        "notes",
    ]

    for key in required_top_level:
        if key not in data:
            issues.append(ValidationIssue(set_id, f"missing top-level key: {key}"))

    items = data.get("items", [])
    other_items = data.get("other_items", [])
    summary = data.get("summary", {})
    transaction = data.get("transaction", {})

    for index, item in enumerate(items):
        listed_price = _as_float(item.get("listed_price"), 0.0)
        discount = _as_float(item.get("discount"), 0.0)
        net_price = _as_float(item.get("net_price"), 0.0)

        expected_net = listed_price - discount
        if not _money_close(net_price, expected_net):
            issues.append(
                ValidationIssue(
                    set_id,
                    (
                        f"items[{index}] net mismatch: net_price={net_price:.2f}, "
                        f"listed_price-discount={expected_net:.2f}"
                    ),
                )
            )

    computed_items_total = sum(_as_float(item.get("net_price"), 0.0) for item in items)
    computed_other_total = sum(_as_float(entry.get("amount"), 0.0) for entry in other_items)

    subtotal = _as_float(summary.get("subtotal"), 0.0)
    tax = _as_float(summary.get("tax"), 0.0)
    total = _as_float(summary.get("total"), 0.0)

    expected_subtotal = computed_items_total + computed_other_total
    if not _money_close(subtotal, expected_subtotal):
        issues.append(
            ValidationIssue(
                set_id,
                (
                    f"subtotal mismatch: summary.subtotal={subtotal:.2f}, "
                    f"items+other_items={expected_subtotal:.2f}"
                ),
            )
        )

    expected_total = subtotal + tax
    if not _money_close(total, expected_total):
        issues.append(
            ValidationIssue(
                set_id,
                (
                    f"total mismatch: summary.total={total:.2f}, "
                    f"subtotal+tax={expected_total:.2f}"
                ),
            )
        )

    paid_amount = transaction.get("paid_amount")
    if paid_amount is not None:
        paid_amount_float = _as_float(paid_amount)
        if not _money_close(paid_amount_float, total):
            issues.append(
                ValidationIssue(
                    set_id,
                    (
                        f"paid amount mismatch: transaction.paid_amount={paid_amount_float:.2f}, "
                        f"summary.total={total:.2f}"
                    ),
                )
            )

    return ValidationResult(set_id=set_id, passed=not issues, issues=issues)


def _normalize_name(value: str) -> str:
    cleaned = []
    for ch in value.upper():
        if ch.isalnum() or ch.isspace():
            cleaned.append(ch)
        else:
            cleaned.append(" ")
    return " ".join("".join(cleaned).split())


def _signature(name: str, price: float) -> str:
    return f"{_normalize_name(name)}|{price:.2f}"


def _extract_ocr_text(swift_script: Path, image_path: Path) -> str:
    proc = subprocess.run(
        ["swift", str(swift_script), str(image_path)],
        capture_output=True,
        text=True,
        check=False,
    )
    if proc.returncode != 0:
        raise RuntimeError(
            f"Swift OCR failed for {image_path}: {proc.stderr.strip() or proc.stdout.strip()}"
        )
    return proc.stdout


def _parse_with_app_parser(app_root: Path, ocr_text: str) -> list[dict[str, Any]]:
    proc = subprocess.run(
        ["dart", "run", "tool/receipt_parser_cli.dart"],
        cwd=str(app_root),
        input=ocr_text,
        capture_output=True,
        text=True,
        check=False,
    )
    if proc.returncode != 0:
        raise RuntimeError(
            f"Parser CLI failed: {proc.stderr.strip() or proc.stdout.strip()}"
        )

    stdout_text = proc.stdout.strip()
    if not stdout_text:
        raise RuntimeError("Parser CLI produced no stdout")

    # `dart run` may print build hook status text around the JSON payload.
    start = stdout_text.find("{")
    end = stdout_text.rfind("}")
    if start < 0 or end < 0 or end <= start:
        raise RuntimeError(f"Parser CLI stdout did not contain JSON: {stdout_text}")

    payload = json.loads(stdout_text[start : end + 1])
    items = payload.get("items", [])
    if not isinstance(items, list):
        raise RuntimeError("Parser CLI output missing items array")
    return items


def _run_parser_diff(
    reference_path: Path,
    sample_root: Path,
    swift_script: Path,
    app_root: Path,
    expected_price_field: str,
) -> ParserDiffResult:
    data = json.loads(reference_path.read_text(encoding="utf-8"))
    set_id = data.get("set_id", reference_path.parent.name)
    images = data.get("images", [])
    issues: list[str] = []

    if not images:
        return ParserDiffResult(
            set_id=set_id,
            passed=False,
            issues=["reference has no images listed"],
        )

    primary_image = sample_root / set_id / images[0]
    if not primary_image.exists():
        return ParserDiffResult(
            set_id=set_id,
            passed=False,
            issues=[f"primary image missing: {primary_image}"],
        )

    try:
        ocr_text = _extract_ocr_text(swift_script, primary_image)
        parsed_items = _parse_with_app_parser(app_root, ocr_text)
    except Exception as error:  # noqa: BLE001
        return ParserDiffResult(set_id=set_id, passed=False, issues=[str(error)])

    expected_signatures = {
        _signature(item.get("description", ""), _as_float(item.get(expected_price_field), 0.0))
        for item in data.get("items", [])
    }

    actual_signatures = {
        _signature(item.get("name", ""), _as_float(item.get("price"), 0.0))
        for item in parsed_items
    }

    missing = sorted(expected_signatures - actual_signatures)
    unexpected = sorted(actual_signatures - expected_signatures)

    if missing:
        issues.append(f"missing signatures ({len(missing)}): {missing}")
    if unexpected:
        issues.append(f"unexpected signatures ({len(unexpected)}): {unexpected}")

    return ParserDiffResult(set_id=set_id, passed=not issues, issues=issues)


def run(root: Path) -> int:
    references = sorted(root.glob("*/receipt_reference.json"))
    if not references:
        print(f"No receipt_reference.json files found under {root}")
        return 1

    failures: list[ValidationIssue] = []

    for reference in references:
        result = _validate_reference(reference)
        status = "PASS" if result.passed else "FAIL"
        print(f"[{status}] {result.set_id} ({reference.relative_to(root.parent)})")
        failures.extend(result.issues)

    if failures:
        print("\nValidation issues:")
        for issue in failures:
            print(f"- {issue.set_id}: {issue.message}")
        return 1

    print(f"\nValidated {len(references)} receipt reference file(s).")
    return 0


def run_with_parser(root: Path, expected_price_field: str) -> int:
    references = sorted(root.glob("*/receipt_reference.json"))
    if not references:
        print(f"No receipt_reference.json files found under {root}")
        return 1

    scripts_dir = Path(__file__).resolve().parent
    swift_script = scripts_dir / "receipt_ocr_vision.swift"
    app_root = scripts_dir.parent.parent / "app"

    if not swift_script.exists():
        print(f"Swift OCR helper script is missing: {swift_script}")
        return 1

    failures: list[ParserDiffResult] = []
    for reference in references:
        result = _run_parser_diff(
            reference,
            root,
            swift_script,
            app_root,
            expected_price_field,
        )
        status = "PASS" if result.passed else "FAIL"
        print(f"[{status}] {result.set_id}")
        if not result.passed:
            failures.append(result)

    if failures:
        print("\nParser diff issues:")
        for failure in failures:
            for issue in failure.issues:
                print(f"- {failure.set_id}: {issue}")
        return 1

    print(f"\nParser diff passed for {len(references)} set(s).")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Validate receipt corpus golden references (phase 1)."
    )
    parser.add_argument(
        "--root",
        default="planning/sample_receipts",
        help="Path to the sample receipts root directory.",
    )
    parser.add_argument(
        "--with-parser",
        action="store_true",
        help="Run phase-2 parser diff against OCR text extracted from images.",
    )
    parser.add_argument(
        "--expected-price-field",
        default="listed_price",
        choices=["listed_price", "net_price"],
        help="Which expected price field to compare parser output against.",
    )
    args = parser.parse_args()

    root = Path(args.root).resolve()
    if not root.exists():
        print(f"Path does not exist: {root}")
        return 1

    if args.with_parser:
        return run_with_parser(root, args.expected_price_field)

    return run(root)


if __name__ == "__main__":
    sys.exit(main())
