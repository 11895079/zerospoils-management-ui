#!/usr/bin/env python3
"""Generate a M3/206 reference-pack manifest from a pack JSON artifact.

This script computes the SHA-256 checksum for a downloadable pack JSON file,
then writes (or updates) a manifest that the app can consume through
`reference_pack_manifest_url` (Remote Config).
"""

from __future__ import annotations

import argparse
import hashlib
import json
import logging
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

SUPPORTED_TYPES = {
    "barcode_catalog",
    "categories",
    "locations",
    "reference_list",
}


@dataclass
class Descriptor:
    pack_type: str
    region: str
    locale: str | None
    version: str
    checksum: str
    minimum_app_version: str
    download_url: str

    def as_dict(self) -> dict[str, str]:
        descriptor = {
            "type": self.pack_type,
            "region": self.region,
            "version": self.version,
            "checksum": self.checksum,
            "minimum_app_version": self.minimum_app_version,
            "download_url": self.download_url,
        }
        if self.locale:
            descriptor["locale"] = self.locale
        return descriptor


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate/update reference-pack manifest JSON",
    )
    parser.add_argument(
        "--pack-type",
        required=True,
        choices=sorted(SUPPORTED_TYPES),
        help="Reference pack type",
    )
    parser.add_argument("--region", required=True, help="Region code, e.g. ca")
    parser.add_argument(
        "--locale",
        help=(
            "Optional locale tag for localized packs, e.g. en, fr-CA, es-419"
        ),
    )
    parser.add_argument("--version", required=True, help="Pack semantic version")
    parser.add_argument(
        "--minimum-app-version",
        required=True,
        help="Minimum app version accepted by client, e.g. 1.0.0",
    )
    parser.add_argument(
        "--pack-json",
        required=True,
        help="Path to downloadable pack JSON file",
    )
    parser.add_argument(
        "--download-url",
        required=True,
        help="Absolute URL where the pack JSON will be hosted",
    )
    parser.add_argument(
        "--manifest-output",
        required=True,
        help="Path to manifest JSON output file",
    )
    parser.add_argument(
        "--base-manifest",
        help=(
            "Optional existing manifest JSON to update. "
            "When provided, matching (type, region, locale) entries are replaced."
        ),
    )
    parser.add_argument(
        "--schema-version",
        type=int,
        default=1,
        help="Manifest schema_version field (default: 1)",
    )
    parser.add_argument(
        "--generated-at",
        help=(
            "Optional ISO-8601 UTC timestamp for generated_at. "
            "Default: now in UTC"
        ),
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Enable verbose logging",
    )
    return parser.parse_args()


def configure_logging(verbose: bool) -> logging.Logger:
    level = logging.DEBUG if verbose else logging.INFO
    logging.basicConfig(level=level, format="%(levelname)s: %(message)s")
    return logging.getLogger("reference-pack-manifest")


def read_pack_bytes(path: Path) -> bytes:
    if not path.exists():
        raise FileNotFoundError(f"Pack file not found: {path}")
    data = path.read_bytes()
    if not data:
        raise ValueError(f"Pack file is empty: {path}")
    return data


def validate_json_bytes(data: bytes, label: str) -> Any:
    try:
        return json.loads(data.decode("utf-8"))
    except Exception as exc:  # noqa: BLE001
        raise ValueError(f"{label} is not valid UTF-8 JSON") from exc


def validate_absolute_url(url: str, field_name: str) -> None:
    if not (url.startswith("http://") or url.startswith("https://")):
        raise ValueError(f"{field_name} must be absolute http(s) URL")


def normalize_generated_at(raw: str | None) -> str:
    if raw:
        try:
            parsed = datetime.fromisoformat(raw.replace("Z", "+00:00"))
        except ValueError as exc:
            raise ValueError("--generated-at must be valid ISO-8601") from exc
        return parsed.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")

    now = datetime.now(tz=timezone.utc)
    return now.isoformat(timespec="seconds").replace("+00:00", "Z")


def load_existing_manifest(path: Path) -> dict[str, Any]:
    if not path.exists():
        raise FileNotFoundError(f"Base manifest not found: {path}")
    parsed = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(parsed, dict):
        raise ValueError("Base manifest must be a JSON object")
    packs = parsed.get("packs")
    if packs is not None and not isinstance(packs, list):
        raise ValueError("Base manifest packs must be an array")
    return parsed


def main() -> int:
    args = parse_args()
    logger = configure_logging(args.verbose)

    validate_absolute_url(args.download_url, "--download-url")

    pack_path = Path(args.pack_json)
    output_path = Path(args.manifest_output)
    logger.info("Pack JSON path: %s", pack_path.resolve())
    logger.info("Manifest output path: %s", output_path.resolve())

    pack_bytes = read_pack_bytes(pack_path)
    pack_json = validate_json_bytes(pack_bytes, "pack JSON")
    if not isinstance(pack_json, dict):
        raise ValueError("Pack JSON must be a JSON object")
    logger.info("Validated pack JSON object")

    checksum = hashlib.sha256(pack_bytes).hexdigest()
    logger.info("Computed pack checksum: %s", checksum)

    descriptor = Descriptor(
        pack_type=args.pack_type,
        region=args.region,
        locale=args.locale,
        version=args.version,
        checksum=checksum,
        minimum_app_version=args.minimum_app_version,
        download_url=args.download_url,
    )

    if args.base_manifest:
        base_manifest_path = Path(args.base_manifest)
        logger.info("Base manifest path: %s", base_manifest_path.resolve())
        manifest = load_existing_manifest(base_manifest_path)
        existing_packs = manifest.get("packs") or []
        logger.info("Loaded base manifest packs: %d", len(existing_packs))
    else:
        manifest = {}
        existing_packs = []
        logger.info("No base manifest provided; creating a new manifest")

    filtered: list[dict[str, Any]] = []
    for item in existing_packs:
        if not isinstance(item, dict):
            continue
        if (
            item.get("type") == descriptor.pack_type
            and item.get("region") == descriptor.region
            and item.get("locale") == descriptor.locale
        ):
            continue
        filtered.append(item)

    filtered.append(descriptor.as_dict())
    filtered.sort(
        key=lambda p: (
            str(p.get("type", "")),
            str(p.get("region", "")),
            str(p.get("locale", "")),
        )
    )
    logger.info("Manifest packs after update: %d", len(filtered))

    manifest["schema_version"] = args.schema_version
    manifest["generated_at"] = normalize_generated_at(args.generated_at)
    manifest["packs"] = filtered

    output_path.parent.mkdir(parents=True, exist_ok=True)
    logger.debug("Ensured output directory exists: %s", output_path.parent.resolve())
    output_path.write_text(
        json.dumps(manifest, indent=2, ensure_ascii=True) + "\n",
        encoding="utf-8",
    )

    logger.info("Manifest written: %s", output_path.resolve())
    logger.info(
        "Pack type/region/locale: %s/%s/%s",
        descriptor.pack_type,
        descriptor.region,
        descriptor.locale or "default",
    )
    logger.info("Pack version: %s", descriptor.version)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
