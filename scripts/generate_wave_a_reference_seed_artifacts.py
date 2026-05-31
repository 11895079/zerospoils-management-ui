#!/usr/bin/env python3
"""Generate Wave A locale-aware category and location seed artifacts."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        '--matrix-config',
        default='scripts/reference_pack_wave_a_matrix.json',
    )
    parser.add_argument(
        '--seed-source',
        default='app/assets/reference-data/source/reference_seed_wave_a.json',
    )
    parser.add_argument(
        '--output-root',
        default='app/assets/reference-data/reference-packs',
    )
    parser.add_argument('--version', default='1.0.0')
    parser.add_argument('--dataset-version', required=True)
    parser.add_argument('--generated-at', required=True)
    parser.add_argument('--source-name', default='wave-a-seed')
    return parser.parse_args()


def _load_json(path: Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding='utf-8'))
    if not isinstance(payload, dict):
        raise ValueError(f'{path} must contain a JSON object')
    return payload


def _build_record(entry: dict[str, Any], pack_type: str, locale: str, source_name: str) -> dict[str, Any]:
    labels = entry.get('labels', {})
    synonyms = entry.get('synonyms', {})
    if locale not in labels:
        raise ValueError(f"Missing label for locale '{locale}' in '{entry.get('id')}'")

    record = {
        'id': entry['id'],
        'label': labels[locale],
        'synonyms': synonyms.get(locale, []),
        'emoji': entry.get('emoji', ''),
        'source': source_name,
    }

    if pack_type == 'categories':
        record['app_category'] = entry['app_category']
    elif pack_type == 'locations':
        record['app_location'] = entry['app_location']
    else:
        raise ValueError(f'Unsupported pack type: {pack_type}')

    return record


def _build_document(
    *,
    pack_type: str,
    region: str,
    locale: str,
    version: str,
    dataset_version: str,
    generated_at: str,
    source_name: str,
    entries: list[dict[str, Any]],
) -> dict[str, Any]:
    records = [
        _build_record(entry, pack_type, locale, source_name)
        for entry in entries
    ]
    return {
        'metadata': {
            'schema_version': 1,
            'type': pack_type,
            'region': region,
            'locale': locale,
            'version': version,
            'dataset_version': dataset_version,
            'generated_at': generated_at,
            'record_count': len(records),
        },
        'records': records,
    }


def generate_artifacts(
    *,
    matrix: dict[str, Any],
    seed: dict[str, Any],
    version: str,
    dataset_version: str,
    generated_at: str,
    output_root: Path,
    source_name: str,
) -> dict[str, dict[str, dict[str, dict[str, Any]]]]:
    generated: dict[str, dict[str, dict[str, dict[str, Any]]]] = {}

    for pack in matrix.get('pack_types', []):
        pack_type = pack['type']
        if pack_type not in ('categories', 'locations'):
            continue

        entries = seed[pack_type]
        budget_bytes = int(pack['size_budget_kib']) * 1024
        generated.setdefault(pack_type, {})

        for region in matrix.get('regions', []):
            region_code = region['code']
            generated[pack_type].setdefault(region_code, {})

            for locale in region.get('locales', []):
                document = _build_document(
                    pack_type=pack_type,
                    region=region_code,
                    locale=locale,
                    version=version,
                    dataset_version=dataset_version,
                    generated_at=generated_at,
                    source_name=source_name,
                    entries=entries,
                )

                encoded = json.dumps(document, indent=2, ensure_ascii=True) + '\n'
                if len(encoded.encode('utf-8')) > budget_bytes:
                    raise ValueError(
                        f'{pack_type}/{region_code}/{locale} exceeds size budget {budget_bytes}'
                    )

                output_path = output_root / pack_type / region_code / locale / f'v{version}.json'
                output_path.parent.mkdir(parents=True, exist_ok=True)
                output_path.write_text(encoded, encoding='utf-8')

                generated[pack_type][region_code][locale] = document

    return generated


def main() -> int:
    args = parse_args()
    matrix = _load_json(Path(args.matrix_config))
    seed = _load_json(Path(args.seed_source))
    generate_artifacts(
        matrix=matrix,
        seed=seed,
        version=args.version,
        dataset_version=args.dataset_version,
        generated_at=args.generated_at,
        output_root=Path(args.output_root),
        source_name=args.source_name,
    )
    return 0


if __name__ == '__main__':
    raise SystemExit(main())