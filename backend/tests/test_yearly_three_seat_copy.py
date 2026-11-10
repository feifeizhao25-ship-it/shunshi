"""2026-11-10 decision: yearly plans only, 3 family seats including the buyer.

User-facing app copy and the family API message must not offer a monthly plan,
a 4-seat household, or an unlimited family.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SURFACES = [
    ROOT / "android-cn/lib",
    ROOT / "ios-cn/lib",
    ROOT / "android-global/lib",
    ROOT / "ios-global/lib",
    ROOT / "backend/app/router/family.py",
]
STALE = (
    "月付",
    "月度会员",
    "月度卡",
    "¥28",
    "period: 'month'",
    "periodName: 'month'",
    "4 seats",
    "(4人",
    "4 members maximum",
    "familySeats: 4",
    "需要SVIP",
    "无限家庭",
    "unlimited family",
)


def _files():
    for surface in SURFACES:
        if surface.is_file():
            yield surface
        else:
            yield from surface.rglob("*.dart")


def test_no_stale_monthly_or_four_seat_copy():
    hits = []
    for path in _files():
        for n, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            stripped = line.strip()
            if stripped.startswith("//") or stripped.startswith("#") or "zh-gate:allow" in line:
                continue
            for token in STALE:
                if token in line:
                    hits.append(f"{path.relative_to(ROOT)}:{n}: {token}: {stripped[:160]}")
    assert hits == [], "\n".join(hits)


def test_family_cap_message_comes_from_the_registry():
    text = (ROOT / "backend/app/router/family.py").read_text(encoding="utf-8")
    assert "get_registry()" in text
    assert '["family_members"]' in text
    assert "4人" not in text
    assert "4 members" not in text
