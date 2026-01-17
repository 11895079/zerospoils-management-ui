#!/usr/bin/env python3
"""
Validate telemetry event payloads against schemas.

Usage:
  python validate_events.py <event.json>
  python validate_events.py fixtures/events/*.json
"""

import json
import sys
from pathlib import Path
import jsonschema

SCHEMAS_DIR = Path(__file__).parent.parent / "schemas"
ALLOWLIST_FILE = SCHEMAS_DIR / "allowlist.json"

def load_schema(event_name: str) -> dict:
    """Load JSON schema for an event type."""
    schema_file = SCHEMAS_DIR / "events" / f"{event_name}.schema.json"
    if not schema_file.exists():
        raise FileNotFoundError(f"No schema found for event: {event_name}")
    with open(schema_file) as f:
        return json.load(f)

def load_envelope_schema() -> dict:
    """Load the envelope schema."""
    with open(SCHEMAS_DIR / "envelope.schema.json") as f:
        return json.load(f)

def load_allowlist() -> dict:
    """Load the event allowlist."""
    with open(ALLOWLIST_FILE) as f:
        return json.load(f)

def validate_envelope(event_dict: dict) -> bool:
    """Validate event structure and envelope fields."""
    schema = load_envelope_schema()
    try:
        jsonschema.validate(event_dict, schema)
        return True
    except jsonschema.ValidationError as e:
        print(f"❌ Envelope validation failed: {e.message}")
        return False

def validate_event_properties(event_dict: dict) -> bool:
    """Validate event-specific properties against allowlist."""
    event_name = event_dict.get("name")
    if not event_name:
        print("❌ Event missing 'name' field")
        return False

    allowlist = load_allowlist()
    allowed_props = allowlist.get("events", {}).get(event_name, {}).get("allowed_properties", [])
    
    props = event_dict.get("properties", {})
    for key in props:
        if key not in allowed_props:
            print(f"⚠️  Unknown property '{key}' in event '{event_name}' (not in allowlist)")
            # Don't fail; just warn for forward compatibility

    # Check event schema if available
    try:
        schema = load_schema(event_name)
        jsonschema.validate(event_dict, schema)
    except FileNotFoundError:
        print(f"⚠️  No specific schema for event: {event_name}")
    except jsonschema.ValidationError as e:
        print(f"❌ Event schema validation failed: {e.message}")
        return False

    return True

def validate_file(file_path: Path) -> bool:
    """Validate a single event JSON file."""
    try:
        with open(file_path) as f:
            event = json.load(f)
    except json.JSONDecodeError as e:
        print(f"❌ Invalid JSON in {file_path}: {e}")
        return False

    print(f"\nValidating {file_path.name}...")
    
    if not validate_envelope(event):
        return False
    if not validate_event_properties(event):
        return False

    print(f"✅ {file_path.name} is valid")
    return True

def main():
    if len(sys.argv) < 2:
        print("Usage: python validate_events.py <file> [<file2> ...]")
        sys.exit(1)

    results = []
    for arg in sys.argv[1:]:
        path = Path(arg)
        if path.is_glob() or "*" in str(path):
            # Handle glob patterns
            paths = list(Path(".").glob(arg))
            results.extend([validate_file(p) for p in paths])
        else:
            results.append(validate_file(path))

    print(f"\n{'='*50}")
    passed = sum(results)
    total = len(results)
    print(f"Results: {passed}/{total} passed")
    
    sys.exit(0 if all(results) else 1)

if __name__ == "__main__":
    main()
