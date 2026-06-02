#!/usr/bin/env python3
"""Generate Wave A reference-pack job scaffolding from a matrix config.

Produces two optional outputs:
- machine-readable job list JSON
- human-readable markdown checklist with publish/manifest commands
"""

from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any


@dataclass(frozen=True)
class RegionConfig:
    code: str
    default_locale: str
    locales: list[str]


@dataclass(frozen=True)
class PackTypeConfig:
    pack_type: str
    locale_scoped: bool
    size_budget_kib: int


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate Wave A reference-pack coverage jobs",
    )
    parser.add_argument(
        "--matrix-config",
        default="scripts/reference_pack_wave_a_matrix.json",
        help="Path to Wave A matrix configuration JSON",
    )
    parser.add_argument(
        "--output-json",
        help="Optional path to write machine-readable job list JSON",
    )
    parser.add_argument(
        "--output-markdown",
        help="Optional path to write markdown checklist",
    )
    return parser.parse_args()


def load_matrix(path: Path) -> tuple[str, list[RegionConfig], list[PackTypeConfig]]:
    data = json.loads(path.read_text(encoding="utf-8"))
    wave = str(data.get("wave", "A"))

    regions_raw = data.get("regions")
    if not isinstance(regions_raw, list) or not regions_raw:
        raise ValueError("regions must be a non-empty array")

    pack_types_raw = data.get("pack_types")
    if not isinstance(pack_types_raw, list) or not pack_types_raw:
        raise ValueError("pack_types must be a non-empty array")

    regions = [
        RegionConfig(
            code=str(r["code"]),
            default_locale=str(r["default_locale"]),
            locales=[str(locale) for locale in r.get("locales", [])],
        )
        for r in regions_raw
    ]

    pack_types = [
        PackTypeConfig(
            pack_type=str(p["type"]),
            locale_scoped=bool(p.get("locale_scoped", False)),
            size_budget_kib=int(p.get("size_budget_kib", 0)),
        )
        for p in pack_types_raw
    ]

    for region in regions:
        if not region.locales:
            raise ValueError(f"region {region.code} must define at least one locale")

    return wave, regions, pack_types


def build_jobs(
    wave: str,
    regions: list[RegionConfig],
    pack_types: list[PackTypeConfig],
) -> list[dict[str, Any]]:
    jobs: list[dict[str, Any]] = []

    for region in regions:
        for pack in pack_types:
            locales = region.locales if pack.locale_scoped else [None]
            for locale in locales:
                artifact_path = _artifact_path(pack.pack_type, region.code, locale)
                jobs.append(
                    {
                        "wave": wave,
                        "pack_type": pack.pack_type,
                        "region": region.code,
                        "locale": locale,
                        "size_budget_kib": pack.size_budget_kib,
                        "artifact_path": artifact_path,
                        "download_url": (
                            "https://storage.googleapis.com/<bucket>/"
                            f"{artifact_path}"
                        ),
                        "manifest_command": _manifest_command(
                            pack_type=pack.pack_type,
                            region=region.code,
                            locale=locale,
                            artifact_path=artifact_path,
                        ),
                    }
                )

    jobs.sort(
        key=lambda row: (
            str(row["pack_type"]),
            str(row["region"]),
            str(row.get("locale") or ""),
        )
    )
    return jobs


def _artifact_path(pack_type: str, region: str, locale: str | None) -> str:
    if locale:
        return f"reference-packs/{pack_type}/{region}/{locale}/vX.Y.Z.json"
    return f"reference-packs/{pack_type}/{region}/vX.Y.Z.json"


def _manifest_command(
    pack_type: str,
    region: str,
    locale: str | None,
    artifact_path: str,
) -> str:
    locale_arg = f" \\\n  --locale {locale}" if locale else ""
    return (
        "python3 scripts/generate_reference_pack_manifest.py \\\n  --pack-type "
        f"{pack_type} \\\n  --region {region}{locale_arg} \\\n  --version X.Y.Z \\\n  --minimum-app-version 1.0.0 \\\n  --pack-json ./dist/<artifact>.json \\\n  --download-url https://storage.googleapis.com/<bucket>/"
        f"{artifact_path} \\\n  --base-manifest ./dist/latest.manifest.json \\\n  --manifest-output ./dist/latest.manifest.json"
    )


def markdown_for_jobs(jobs: list[dict[str, Any]]) -> str:
    lines = [
        "# Wave A Reference Pack Job Scaffold",
        "",
        "Use this checklist to stage region/locale pack artifacts before publish.",
        "",
        "| Pack Type | Region | Locale | Budget (KiB) | Artifact Path |",
        "| --- | --- | --- | ---: | --- |",
    ]

    for row in jobs:
        locale = row["locale"] if row["locale"] is not None else "default"
        lines.append(
            "| "
            f"{row['pack_type']} | {row['region']} | {locale} | "
            f"{row['size_budget_kib']} | {row['artifact_path']} |"
        )

    lines.append("")
    lines.append("## Manifest Command Templates")
    lines.append("")

    for row in jobs:
        locale = row["locale"] if row["locale"] is not None else "default"
        lines.append(f"### {row['pack_type']} / {row['region']} / {locale}")
        lines.append("")
        lines.append("```bash")
        lines.append(str(row["manifest_command"]))
        lines.append("```")
        lines.append("")

    return "\n".join(lines)


def write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def write_json(path: Path, data: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, ensure_ascii=True) + "\n", encoding="utf-8")


def main() -> int:
    args = parse_args()
    wave, regions, pack_types = load_matrix(Path(args.matrix_config))
    jobs = build_jobs(wave=wave, regions=regions, pack_types=pack_types)

    payload = {
        "wave": wave,
        "job_count": len(jobs),
        "jobs": jobs,
    }

    if args.output_json:
        write_json(Path(args.output_json), payload)
    else:
        print(json.dumps(payload, indent=2, ensure_ascii=True))

    if args.output_markdown:
        write_text(Path(args.output_markdown), markdown_for_jobs(jobs))

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
