#!/usr/bin/env python3
"""
Scan event JSON files for potential PII (Personal Identifiable Information).

Checks for common PII patterns and blocked keys per redaction policy.

Usage:
  python pii_scan.py <file.json> [<file2.json> ...]
"""

import json
import sys
import re
from pathlib import Path

REDACTION_POLICY = Path(__file__).parent.parent / "policies" / "redaction.yaml"

# Common PII patterns
PII_PATTERNS = {
    "email": r"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}",
    "phone": r"\b(\+?\d{1,3}[-.\s]?)?\(?([0-9]{3})\)?[-.\s]?([0-9]{3})[-.\s]?([0-9]{4})\b",
    "ssn": r"\b\d{3}-\d{2}-\d{4}\b",
    "credit_card": r"\b\d{4}[- ]?\d{4}[- ]?\d{4}[- ]?\d{4}\b",
    "ip_address": r"\b(?:\d{1,3}\.){3}\d{1,3}\b",
    "date_of_birth": r"\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b",
}

BLOCKED_KEYS = [
    "password", "auth_token", "credit_card", "ssn", "phone",
    "email_address", "ip_address", "latitude", "longitude",
]

def scan_value(key: str, value) -> list:
    """Scan a value for PII and policy violations."""
    issues = []
    
    # Check blocked keys
    if key in BLOCKED_KEYS:
        issues.append(f"Blocked key '{key}' present (should be removed)")
        return issues
    
    # Skip non-string values
    if not isinstance(value, str):
        return issues
    
    # Scan for PII patterns
    for pattern_name, pattern in PII_PATTERNS.items():
        if re.search(pattern, value):
            issues.append(f"Potential {pattern_name} detected in value: {value[:20]}...")
    
    return issues

def scan_event(event: dict) -> list:
    """Scan an event for PII."""
    issues = []
    props = event.get("properties", {})
    
    for key, value in props.items():
        issues.extend(scan_value(key, value))
    
    return issues

def main():
    if len(sys.argv) < 2:
        print("Usage: python pii_scan.py <file.json> [<file2.json> ...]")
        sys.exit(1)

    total_issues = 0
    for file_arg in sys.argv[1:]:
        path = Path(file_arg)
        if not path.exists():
            print(f"⚠️  File not found: {path}")
            continue

        try:
            with open(path) as f:
                event = json.load(f)
        except json.JSONDecodeError as e:
            print(f"❌ Invalid JSON in {path}: {e}")
            continue

        issues = scan_event(event)
        
        if issues:
            print(f"\n🚨 {path.name}:")
            for issue in issues:
                print(f"   - {issue}")
                total_issues += 1
        else:
            print(f"✅ {path.name} (no PII detected)")

    if total_issues > 0:
        print(f"\n⚠️  Found {total_issues} PII-related issue(s)")
        sys.exit(1)
    else:
        print(f"\n✅ All files scanned; no PII detected")
        sys.exit(0)

if __name__ == "__main__":
    main()
