#!/usr/bin/env python3
"""Normalize Firebase App Distribution tester feedback CSV into the ZeroSpoils
triage JSON schema.

Usage:
  python scripts/normalize_firebase_feedback.py \
      --input tmp/firebase_feedback_20260411.csv \
      --output tmp/triage_20260411.json \
      [--screenshot-dir docs/user_feedback/screenshots]

The script is idempotent: re-running with the same input produces identical
output (duplicate detection is keyed on the composite
platform+build_number+submitted_at+message_hash).
"""

import argparse
import csv
import hashlib
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional


# ──────────────────────────────────────────────────────────────────────────────
# Schema helpers
# ──────────────────────────────────────────────────────────────────────────────

TRIAGE_STATUS_NEW = "new"
VALID_PLATFORMS = {"android", "ios"}


def _hash_tester_id(raw_email: str) -> str:
    """Return a privacy-safe SHA-256 hash of the tester email."""
    return "sha256:" + hashlib.sha256(raw_email.strip().lower().encode()).hexdigest()


def _normalise_timestamp(raw: str) -> str:
    """Convert common Firebase timestamp formats to ISO 8601 UTC."""
    raw = raw.strip()
    for fmt in ("%Y-%m-%dT%H:%M:%SZ", "%Y-%m-%d %H:%M:%S", "%Y-%m-%dT%H:%M:%S"):
        try:
            dt = datetime.strptime(raw, fmt).replace(tzinfo=timezone.utc)
            return dt.strftime("%Y-%m-%dT%H:%M:%SZ")
        except ValueError:
            continue
    # Return as-is if unrecognised
    return raw


def _row_to_record(row: dict, screenshot_dir: Optional[Path]) -> Optional[dict]:
    """Convert a CSV row from Firebase Console export to a normalised record.

    Returns None if the row lacks required fields.
    """
    message = (row.get("Feedback text") or row.get("message") or "").strip()
    if not message:
        return None

    platform_raw = (row.get("Platform") or row.get("platform") or "android").lower()
    platform = platform_raw if platform_raw in VALID_PLATFORMS else "android"

    build_version = (
        row.get("App version") or row.get("build_version") or ""
    ).strip()
    build_number = (
        row.get("App version code")
        or row.get("Version code")
        or row.get("build_number")
        or ""
    ).strip()
    submitted_at = _normalise_timestamp(
        row.get("Submission time") or row.get("submitted_at") or ""
    )
    tester_email = (row.get("Tester email") or row.get("tester_email") or "").strip()
    tester_id_hash = _hash_tester_id(tester_email) if tester_email else ""

    # Screenshot reference: check for a downloaded file in screenshot_dir.
    screenshot_reference = ""
    if screenshot_dir and screenshot_dir.is_dir():
        # Firebase exports do not include screenshot filenames directly;
        # look for any file matching the feedback timestamp prefix.
        ts_prefix = submitted_at.replace(":", "-").replace("T", "-")[:16]
        candidates = list(screenshot_dir.glob(f"*{ts_prefix}*.png"))
        if candidates:
            screenshot_reference = os.path.relpath(candidates[0], start=Path.cwd())

    return {
        "platform": platform,
        "build_version": build_version,
        "build_number": build_number,
        "release_channel": (
            row.get("Distribution group") or row.get("release_channel") or ""
        ).strip(),
        "message": message,
        "screenshot_reference": screenshot_reference,
        "submitted_at": submitted_at,
        "triage_status": TRIAGE_STATUS_NEW,
        "tester_id_hash": tester_id_hash,
    }


def _deduplication_key(record: dict) -> str:
    """Composite key used to detect duplicate records across re-runs."""
    msg_hash = hashlib.sha256(record["message"].encode()).hexdigest()[:16]
    return f"{record['platform']}|{record['build_number']}|{record['submitted_at']}|{msg_hash}"


def _feedback_id(record: dict) -> str:
    """Stable identifier for linking triage records to issues."""
    return hashlib.sha256(_deduplication_key(record).encode()).hexdigest()[:20]


# ──────────────────────────────────────────────────────────────────────────────
# Core normalisation
# ──────────────────────────────────────────────────────────────────────────────


def normalize(
    input_path: Path,
    screenshot_dir: Optional[Path],
    existing_records: Optional[list[dict]] = None,
) -> list[dict]:
    """Read CSV and return deduplicated normalised records.

    If *existing_records* is provided, newly-parsed records that share a key
    with an existing record are silently dropped (idempotent re-run support).
    """
    existing_keys: set[str] = set()
    if existing_records:
        for record in existing_records:
            existing_keys.add(_deduplication_key(record))

    results: list[dict] = []
    seen_keys: set[str] = set(existing_keys)

    with open(input_path, newline="", encoding="utf-8-sig") as fh:
        reader = csv.DictReader(fh)
        for row in reader:
            record = _row_to_record(row, screenshot_dir)
            if record is None:
                continue
            key = _deduplication_key(record)
            if key in seen_keys:
                continue
            record["feedback_id"] = _feedback_id(record)
            seen_keys.add(key)
            results.append(record)

    return results


# ──────────────────────────────────────────────────────────────────────────────
# CLI entry-point
# ──────────────────────────────────────────────────────────────────────────────


def main(argv: Optional[list[str]] = None) -> int:
    parser = argparse.ArgumentParser(
        description="Normalise Firebase App Distribution tester feedback CSV."
    )
    parser.add_argument("--input", required=True, help="Path to the Firebase CSV export")
    parser.add_argument("--output", required=True, help="Path for the normalised JSON output")
    parser.add_argument(
        "--screenshot-dir",
        default=None,
        help="Directory containing downloaded tester screenshots",
    )

    args = parser.parse_args(argv)

    input_path = Path(args.input)
    output_path = Path(args.output)
    screenshot_dir = Path(args.screenshot_dir) if args.screenshot_dir else None

    if not input_path.is_file():
        print(f"ERROR: Input file not found: {input_path}", file=sys.stderr)
        return 1

    # Load existing output for deduplication if it already exists.
    existing_records: list[dict] = []
    if output_path.is_file():
        try:
            with open(output_path, encoding="utf-8") as fh:
                existing_records = json.load(fh)
        except (json.JSONDecodeError, OSError):
            existing_records = []

    new_records = normalize(input_path, screenshot_dir, existing_records)
    all_records = existing_records + new_records

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, "w", encoding="utf-8") as fh:
        json.dump(all_records, fh, indent=2, ensure_ascii=False)
        fh.write("\n")

    print(
        f"Done. {len(new_records)} new record(s) added "
        f"({len(all_records)} total). Output: {output_path}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
