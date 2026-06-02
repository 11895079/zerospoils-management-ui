"""Tests for scripts/fetch_canada_top_catalog.py."""

from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).parent))

from fetch_canada_top_catalog import (
    find_elbow_index,
    _category_hint_from_tags,
    _parse_quantity,
    fetch_top_region,
    fetch_top_canada,
)


# ---------------------------------------------------------------------------
# find_elbow_index
# ---------------------------------------------------------------------------

def test_elbow_detects_sharp_drop():
    # Counts drop >50% at index 3 (100 → 40 is 60% drop)
    counts = [1000, 800, 600, 100, 80, 60]
    assert find_elbow_index(counts, drop_threshold=0.50) == 3


def test_elbow_returns_full_length_when_no_drop():
    counts = [1000, 950, 900, 880, 860]
    assert find_elbow_index(counts, drop_threshold=0.50) == len(counts)


def test_elbow_single_entry():
    assert find_elbow_index([500], drop_threshold=0.50) == 1


def test_elbow_empty():
    assert find_elbow_index([], drop_threshold=0.50) == 0


def test_elbow_respects_threshold():
    # 900 → 500 is 44% drop; 0.50 threshold should NOT trigger
    counts = [1000, 900, 500]
    assert find_elbow_index(counts, drop_threshold=0.50) == len(counts)
    # But 0.40 threshold should trigger at index 2 (44% > 40%)
    assert find_elbow_index(counts, drop_threshold=0.40) == 2


def test_elbow_first_drop_wins():
    # Two drops: index 2 (50%+) and index 4 (50%+). First wins.
    counts = [1000, 800, 300, 280, 100]
    assert find_elbow_index(counts, drop_threshold=0.50) == 2


# ---------------------------------------------------------------------------
# _category_hint_from_tags
# ---------------------------------------------------------------------------

def test_category_hint_dairy():
    assert _category_hint_from_tags("en:dairies,en:yogurts") == "dairy"


def test_category_hint_protein_fish():
    assert _category_hint_from_tags("en:fish-and-seafood,en:canned-foods") == "protein"


def test_category_hint_beverages():
    assert _category_hint_from_tags("en:beverages,en:sodas") == "beverages"


def test_category_hint_defaults_to_pantry():
    assert _category_hint_from_tags("en:unknown-tag") == "pantry"
    assert _category_hint_from_tags("") == "pantry"


def test_category_hint_most_specific_wins():
    # en:meats is listed before en:canned-foods in priority map
    assert _category_hint_from_tags("en:meats,en:canned-foods") == "protein"


# ---------------------------------------------------------------------------
# _parse_quantity
# ---------------------------------------------------------------------------

def test_parse_quantity_ml():
    assert _parse_quantity("500 ml") == ("500", "ml")


def test_parse_quantity_g():
    assert _parse_quantity("250g") == ("250", "g")


def test_parse_quantity_kg_with_decimal():
    assert _parse_quantity("1.75 kg") == ("1.75", "kg")


def test_parse_quantity_empty():
    assert _parse_quantity("") == ("", "")


def test_parse_quantity_no_unit():
    assert _parse_quantity("12") == ("12", "")


# ---------------------------------------------------------------------------
# fetch_top_canada — unit test with mocked HTTP
# ---------------------------------------------------------------------------

def _make_ofx_product(code: str, name: str, scans: int, cats: str = "en:snacks") -> dict:
    return {
        "code": code,
        "product_name": name,
        "brands": "TestBrand",
        "categories_tags": cats,
        "unique_scans_n": scans,
        "quantity": "100 g",
    }


def test_fetch_top_canada_applies_elbow_and_category_cap(monkeypatch):
    """fetch_top_canada respects elbow detection and category cap (no real HTTP)."""

    page_responses = [
        # Page 1: 10 snack products with a sharp drop after index 4
        {
            "products": [
                _make_ofx_product("055000132152", "Chips A", 5000),
                _make_ofx_product("0059161402208", "Chips B", 4500),
                _make_ofx_product("012000161155", "Chips C", 4000),
                _make_ofx_product("0628154038675", "Chips D", 3800),
                # Sharp drop: 3800 → 500 is 87% drop (>50%), elbow at index 4
                _make_ofx_product("0014100085836", "Cracker E", 500),
                _make_ofx_product("0088491201073", "Cracker F", 480),
            ]
        }
    ]

    call_count = [0]

    def mock_fetch_page(page: int, page_size: int, country_query: str, *, timeout: int = 20, max_retries: int = 4) -> dict:
        idx = call_count[0]
        call_count[0] += 1
        assert country_query == "canada"
        if idx < len(page_responses):
            return page_responses[idx]
        return {"products": []}

    monkeypatch.setattr("fetch_canada_top_catalog._fetch_page", mock_fetch_page)

    rows, diagnostics = fetch_top_canada(
        drop_threshold=0.50,
        max_per_category=3,
        min_results=4,
        max_results=200,
        rate_limit_seconds=0,  # no sleep in tests
    )

    # Elbow is at index 4 (3800 → 500 is 87% drop), so 4 products pass
    # Category cap = 3, all 4 are snacks → 3 accepted
    assert diagnostics["after_basic_filter"] == 4
    assert diagnostics["accepted"] == 3
    assert diagnostics["category_counts"].get("snacks", 0) == 3


def test_fetch_top_canada_skips_entries_without_name_or_scans(monkeypatch):
    def mock_fetch_page(page: int, page_size: int, country_query: str, *, timeout: int = 20, max_retries: int = 4) -> dict:
        if page == 1:
            return {
                "products": [
                    _make_ofx_product("055000132152", "Valid Product", 1000),
                    {"code": "012000161155", "product_name": "", "unique_scans_n": 900, "brands": "B", "categories_tags": "en:snacks", "quantity": ""},
                    {"code": "0628154038675", "product_name": "No Scans", "unique_scans_n": 0, "brands": "B", "categories_tags": "en:snacks", "quantity": ""},
                ]
            }
        return {"products": []}

    monkeypatch.setattr("fetch_canada_top_catalog._fetch_page", mock_fetch_page)

    rows, diagnostics = fetch_top_canada(
        drop_threshold=0.50,
        max_per_category=10,
        min_results=1,
        max_results=50,
        rate_limit_seconds=0,
    )

    # Only the valid product should come through
    assert len(rows) == 1
    assert rows[0]["product_name"] == "Valid Product"


def test_fetch_top_region_uses_custom_country_query(monkeypatch):
    captured_queries = []

    def mock_fetch_page(page: int, page_size: int, country_query: str, *, timeout: int = 20, max_retries: int = 4) -> dict:
        captured_queries.append(country_query)
        if page == 1:
            return {
                "products": [
                    _make_ofx_product("055000132152", "Valid Product", 1000),
                ]
            }
        return {"products": []}

    monkeypatch.setattr("fetch_canada_top_catalog._fetch_page", mock_fetch_page)

    rows, diagnostics = fetch_top_region(
        country_query="united-states",
        drop_threshold=0.50,
        max_per_category=10,
        min_results=1,
        max_results=50,
        rate_limit_seconds=0,
    )

    assert len(rows) == 1
    assert diagnostics["country_query"] == "united-states"
    assert captured_queries[0] == "united-states"
