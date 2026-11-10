"""Flagged profiles must not be handed an item the repo already contraindicates.

The catalog is backend/app/safety/contraindications.py. 麦冬 is intentionally
absent: the knowledge files recommend it for 阴虚 and never say to withhold it
in pregnancy or breastfeeding.
"""

from app.router.constitution import CONSTITUTION_TYPES
from app.safety.contraindications import filter_text, flags_from_profile, names_for
from app.services.recommendation_engine import CONSTITUTION_TAGS


def _surfaces() -> list[str]:
    texts = []
    for info in CONSTITUTION_TYPES.values():
        texts.append(info["diet_advice"])
        texts.append(info["tea_advice"])
    texts.append("、".join(CONSTITUTION_TAGS["yinxu"]))
    texts.append("阴虚体质建议：多食滋阴食物（银耳、麦冬、百合）；避免过度运动；保证充足睡眠")
    return texts


def test_unflagged_yin_advice_still_includes_maidong_and_softshell_turtle():
    flags = flags_from_profile(life_stage="exploration", health_concerns=["睡眠"])
    assert flags == frozenset()
    tea = filter_text(CONSTITUTION_TYPES["yinxu"]["tea_advice"], flags)
    diet = filter_text(CONSTITUTION_TYPES["yinxu"]["diet_advice"], flags)
    assert "麦冬" in tea
    assert "甲鱼" in diet
    assert "鸭肉" in diet


def test_preparing_for_pregnancy_is_not_a_pregnancy_flag():
    assert flags_from_profile(life_stage="备孕") == frozenset()


def test_flagged_users_never_receive_contraindicated_items():
    cases = {
        "pregnancy": flags_from_profile(life_stage="孕期"),
        "breastfeeding": flags_from_profile(health_concerns=["哺乳期"]),
        "both": flags_from_profile(life_stage="pregnant", health_concerns=["breastfeeding"]),
    }
    assert cases["pregnancy"] == frozenset({"pregnancy"})
    assert cases["breastfeeding"] == frozenset({"breastfeeding"})
    assert cases["both"] == frozenset({"pregnancy", "breastfeeding"})

    for label, flags in cases.items():
        blocked = names_for(flags)
        assert blocked, label
        assert "麦冬" not in blocked
        for text in _surfaces():
            filtered = filter_text(text, flags)
            for name in blocked:
                assert name not in filtered, (label, name, text, filtered)


def test_pregnancy_drops_turtle_and_keeps_maidong_in_yin_advice():
    flags = flags_from_profile(life_stage="孕期")
    diet = filter_text(CONSTITUTION_TYPES["yinxu"]["diet_advice"], flags)
    tea = filter_text(CONSTITUTION_TYPES["yinxu"]["tea_advice"], flags)
    assert "甲鱼" not in diet
    assert "银耳" in diet and "百合" in diet
    assert "麦冬" in tea
    assert "百合银耳茶" in tea


def test_breastfeeding_drops_duck_and_ginseng_but_not_dangshen():
    flags = flags_from_profile(health_concerns=["哺乳"])
    diet = filter_text(CONSTITUTION_TYPES["yinxu"]["diet_advice"], flags)
    tea = filter_text(CONSTITUTION_TYPES["qixu"]["tea_advice"], flags)
    assert "鸭肉" not in diet
    assert "甲鱼" in diet
    assert "人参" not in tea
    assert "党参" in tea
    assert "黄芪" in tea


def test_dried_ginger_does_not_remove_fresh_ginger():
    flags = flags_from_profile(life_stage="pregnancy")
    text = filter_text("羊肉、生姜、桂圆；姜枣茶、肉桂茶", flags)
    assert "生姜" in text
    assert "姜枣茶" in text
    assert "肉桂" not in text
