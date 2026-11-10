"""Copy gates for the 2026-11-10 leftover CN surfaces.

Profile streak matches the achievement wording, both CN login pages use the
specified slogan, constitution result pages do not present a diagnosis, and
the family skill guide does not sell jiahe while it is off sale.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

RESULT_PAGES = [
    "android-cn/lib/presentation/pages/constitution_report",
    "ios-cn/lib/presentation/pages/constitution_report",
    "android-cn/lib/presentation/pages/constitution/constitution_test_v2.dart",
    "ios-cn/lib/presentation/pages/constitution/constitution_test_v2.dart",
    "ios-cn/lib/presentation/pages/constitution/constitution_test_page.dart",
    "android-cn/lib/presentation/pages/solar/constitution_test_page.dart",
    "ios-cn/lib/presentation/pages/solar/constitution_test_page.dart",
    "android-cn/lib/presentation/pages/body_type/body_type_essence_page.dart",
    "ios-cn/lib/presentation/pages/body_type/body_type_essence_page.dart",
    "android-cn/lib/presentation/pages/body_type/body_type_essence_v2.dart",
]

# Result screens must not title the outcome as a constitution or pattern diagnosis.
RESULT_BANNED = (
    "您的体质",
    "你的体质",
    "体质类型",
    "体质本质",
    "体质得分",
    "体质评分",
    "体质强弱",
    "证型",
)

SLOGAN = "跟着节气，把日子过得舒服一点"


def _dart_files(rel: str):
    path = ROOT / rel
    if path.is_file():
        yield path
        return
    yield from path.rglob("*.dart")


def test_profile_streak_matches_achievement_wording():
    profile = (ROOT / "android-cn/lib/presentation/pages/profile/profile_page_v2.dart").read_text(encoding="utf-8")
    achievement = (ROOT / "android-cn/lib/presentation/pages/achievement/achievement_page_v2.dart").read_text(encoding="utf-8")
    assert "连续打卡" not in profile
    assert "已记下 $_checkinDays 天" in profile
    assert "已记下" in achievement


def test_cn_login_slogan():
    for rel in (
        "android-cn/lib/presentation/pages/login/login_page.dart",
        "ios-cn/lib/presentation/pages/login/login_page.dart",
    ):
        text = (ROOT / rel).read_text(encoding="utf-8")
        assert SLOGAN in text, rel
        assert "顺应时节，安排作息" not in text, rel


def test_result_pages_are_habit_tendency_not_diagnosis():
    hits = []
    for rel in RESULT_PAGES:
        for path in _dart_files(rel):
            for n, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
                stripped = line.strip()
                if stripped.startswith("//") or stripped.startswith("///"):
                    continue
                for token in RESULT_BANNED:
                    if token in line:
                        hits.append(f"{path.relative_to(ROOT)}:{n}: {token}")
    assert hits == [], "\n".join(hits)


def test_privacy_date_follows_the_latest_body_edit():
    # Body last changed in 427160db (2026-11-10): 体质测试结果 → 节气生活习惯自测结果.
    for rel in (
        "android-cn/lib/presentation/pages/legal/privacy_policy_page.dart",
        "ios-cn/lib/presentation/pages/legal/privacy_policy_page.dart",
    ):
        text = (ROOT / rel).read_text(encoding="utf-8")
        assert "最后更新日期：2026年11月10日" in text, rel
        assert "2026年10月23日" not in text, rel
        assert "节气生活习惯自测结果" in text, rel


def test_family_guide_says_jiahe_is_not_on_sale():
    sub = (ROOT / "backend/app/router/subscription.py").read_text(encoding="utf-8")
    marker = '"id": "jiahe"'
    start = sub.index(marker)
    block = sub[start:start + 400]
    assert '"on_sale": False' in block
    for rel in (
        "android-cn/docs/SKILLS_USER_GUIDE.md",
        "ios-cn/docs/SKILLS_USER_GUIDE.md",
    ):
        text = (ROOT / rel).read_text(encoding="utf-8")
        assert "尚未开售" in text, rel
        assert '需要订阅"家庭计划"' not in text, rel
        assert "3 人（含购买人）" in text, rel
