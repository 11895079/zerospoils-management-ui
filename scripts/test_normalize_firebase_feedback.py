"""Tests for scripts/normalize_firebase_feedback.py"""

import json
import textwrap
from pathlib import Path

import pytest

# The script lives one level up from the tests directory.
import sys

sys.path.insert(0, str(Path(__file__).parent.parent / "scripts"))

from normalize_firebase_feedback import normalize, _deduplication_key, _hash_tester_id


# ──────────────────────────────────────────────────────────────────────────────
# Helpers
# ──────────────────────────────────────────────────────────────────────────────

def _write_csv(tmp_path: Path, content: str) -> Path:
    csv_file = tmp_path / "feedback.csv"
    csv_file.write_text(textwrap.dedent(content), encoding="utf-8")
    return csv_file


# ──────────────────────────────────────────────────────────────────────────────
# Tests
# ──────────────────────────────────────────────────────────────────────────────

SAMPLE_CSV = """\
    Platform,App version,App version code,Submission time,Tester email,Feedback text,Distribution group
    Android,1.2.3,42,2026-04-11T14:23:00Z,alice@example.com,The expiry scan button crashes.,internal_beta
    Android,1.2.3,42,2026-04-11T15:00:00Z,bob@example.com,Works great on my Pixel 7.,internal_beta
    """


def test_basic_normalisation(tmp_path):
    csv_file = _write_csv(tmp_path, SAMPLE_CSV)
    records = normalize(csv_file, screenshot_dir=None)
    assert len(records) == 2

    first = records[0]
    assert first["platform"] == "android"
    assert first["build_version"] == "1.2.3"
    assert first["build_number"] == "42"
    assert first["release_channel"] == "internal_beta"
    assert first["message"] == "The expiry scan button crashes."
    assert first["submitted_at"] == "2026-04-11T14:23:00Z"
    assert first["triage_status"] == "new"
    # PII: raw email must NOT appear in the output.
    assert "alice@example.com" not in json.dumps(first)
    # Hash must be present.
    assert first["tester_id_hash"].startswith("sha256:")


def test_duplicate_records_are_dropped(tmp_path):
    """Re-running with the same CSV should not produce duplicate records."""
    csv_file = _write_csv(tmp_path, SAMPLE_CSV)
    first_run = normalize(csv_file, screenshot_dir=None)
    second_run = normalize(csv_file, screenshot_dir=None, existing_records=first_run)

    # No new records should be added on the second run.
    assert len(second_run) == 0


def test_empty_message_rows_are_skipped(tmp_path):
    csv_content = """\
        Platform,App version,App version code,Submission time,Tester email,Feedback text,Distribution group
        Android,1.0.0,1,2026-01-01T00:00:00Z,tester@x.com,,beta
        """
    csv_file = _write_csv(tmp_path, csv_content)
    records = normalize(csv_file, screenshot_dir=None)
    assert len(records) == 0


def test_hash_tester_id_is_deterministic():
    hash1 = _hash_tester_id("Alice@Example.COM")
    hash2 = _hash_tester_id("alice@example.com")
    # Case normalisation must make both hashes identical.
    assert hash1 == hash2
    assert hash1.startswith("sha256:")


def test_hash_tester_id_is_not_raw_email():
    email = "tester@example.com"
    hashed = _hash_tester_id(email)
    assert email not in hashed


def test_deduplication_key_varies_by_message(tmp_path):
    csv_content = """\
        Platform,App version,App version code,Submission time,Tester email,Feedback text
        Android,1.0.0,1,2026-01-01T00:00:00Z,a@b.com,First message
        Android,1.0.0,1,2026-01-01T00:00:00Z,a@b.com,Second message
        """
    csv_file = _write_csv(tmp_path, csv_content)
    records = normalize(csv_file, screenshot_dir=None)
    keys = {_deduplication_key(r) for r in records}
    # Different messages must produce different deduplication keys.
    assert len(keys) == 2


def test_unknown_platform_defaults_to_android(tmp_path):
    csv_content = """\
        Platform,App version,App version code,Submission time,Tester email,Feedback text
        WebAssembly,2.0.0,99,2026-03-01T09:00:00Z,t@z.com,Message here
        """
    csv_file = _write_csv(tmp_path, csv_content)
    records = normalize(csv_file, screenshot_dir=None)
    assert records[0]["platform"] == "android"
