"""Tests for scripts/generate_wave_a_reference_seed_artifacts.py."""

from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).parent))

from generate_wave_a_reference_seed_artifacts import generate_artifacts


def test_generate_artifacts_writes_locale_scoped_category_and_location_packs(tmp_path):
    matrix = {
        'wave': 'A',
        'regions': [
            {
                'code': 'ca',
                'default_locale': 'en',
                'locales': ['en', 'fr-CA'],
            }
        ],
        'pack_types': [
            {'type': 'categories', 'locale_scoped': True, 'size_budget_kib': 128},
            {'type': 'locations', 'locale_scoped': True, 'size_budget_kib': 64},
        ],
    }

    seed = {
        'categories': [
            {
                'id': 'produce',
                'app_category': 'produce',
                'emoji': '🥬',
                'labels': {'en': 'Produce', 'fr-CA': 'Fruits et legumes'},
                'synonyms': {
                    'en': ['fruit', 'vegetable'],
                    'fr-CA': ['fruit', 'legume'],
                },
            }
        ],
        'locations': [
            {
                'id': 'fridge',
                'app_location': 'fridge',
                'emoji': '❄️',
                'labels': {'en': 'Fridge', 'fr-CA': 'Refrigerateur'},
                'synonyms': {
                    'en': ['refrigerator'],
                    'fr-CA': ['frigo'],
                },
            }
        ],
    }

    generated = generate_artifacts(
        matrix=matrix,
        seed=seed,
        version='1.0.0',
        dataset_version='2026-05-31',
        generated_at='2026-05-31T00:00:00Z',
        output_root=tmp_path,
        source_name='wave-a-seed',
    )

    assert set(generated.keys()) == {'categories', 'locations'}

    categories_en = generated['categories']['ca']['en']
    assert categories_en['metadata']['locale'] == 'en'
    assert categories_en['records'][0]['label'] == 'Produce'
    assert categories_en['records'][0]['app_category'] == 'produce'

    locations_fr = generated['locations']['ca']['fr-CA']
    assert locations_fr['metadata']['locale'] == 'fr-CA'
    assert locations_fr['records'][0]['label'] == 'Refrigerateur'
    assert locations_fr['records'][0]['app_location'] == 'fridge'

    assert (tmp_path / 'categories' / 'ca' / 'en' / 'v1.0.0.json').exists()
    assert (tmp_path / 'locations' / 'ca' / 'fr-CA' / 'v1.0.0.json').exists()