"""SS-B1: old monthly prices, 4-seat notes, and retired tooling are marked historical.

The entitlements registry is not edited.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MARKER = "> **历史口径.**"
FILES = [
    "docs/round3-subscription-system.md",
    "docs/SHUNSHI_PRODUCTION_BIBLE.md",
    "docs/PRODUCT_BIBLE_PART1.md",
    "docs/PRD-SHUNSHI-FINAL.md",
    "docs/round3-family-system.md",
    "docs/round2-widget-tree.md",
    "docs/round1-product-overview.md",
    "docs/SEASONS_BUILD_STATUS_20260320.md",
    "docs/IOS_MEMBERSHIP_UI_2026-10-11.md",
    "android-cn/docs/API.md",
    "ios-cn/docs/API.md",
    "android-cn/business/business-plan.md",
    "ios-cn/business/business-plan.md",
    "android-cn/README.md",
    "ios-cn/README.md",
    "android-cn/round3-subscription-system.md",
    "ios-cn/round3-subscription-system.md",
    "ios-cn/round4-roadmap-growth.md",
    "ios-cn/testing/qa-testing.md",
]


def test_legacy_docs_open_with_the_historical_banner():
    missing = [rel for rel in FILES if not (ROOT / rel).read_text(encoding="utf-8").startswith(MARKER)]
    assert missing == []


def test_registry_family_seat_count_is_unchanged():
    registry = json.loads((ROOT / "backend/app/entitlements_registry.json").read_text(encoding="utf-8"))
    assert registry["tiers"]["family"]["collaboration"]["family_members"] == 3
