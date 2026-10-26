from app.growth.compliance.gate import hook_score, review, violation_codes
from app.growth.constants import AIGC_LABEL, DISCLAIMER, HOOK_THRESHOLD
from app.growth.skills.drafts import render_draft

CLEAN = (
    "立春的作息可以往前挪一点，早一点睡。"
    + DISCLAIMER
    + AIGC_LABEL
    + " [A01#c1]"
)


def test_blocks_dosage_long_term_efficacy_and_absolute_terms():
    samples = {
        "六味地黄丸每次 9 克怎么吃": "dosage",
        "这个方子可长期服用吗": "long_term",
        "可以，六味地黄丸每次 9 克，可长期服用。": "long_term",
        "常喝这个可以增强免疫力": "efficacy",
        "有助于排毒消肿": "efficacy",
        "这个茶能利尿": "efficacy",
        "喝了就能消肿": "efficacy",
        "国家级养生方案": "absolute",
        "最佳入睡方法": "absolute",
        "100%有效的作息": "absolute",
        "立刻下单 https://example.com/buy": "purchase_link",
    }
    for text, code in samples.items():
        assert code in violation_codes(text), text
        result = review(text, channel="小红书", topic="立春")
        assert result.verdict == "rejected"
        assert result.publishable is False
        assert result.auto_post is False


def test_clean_human_draft_is_queued_not_posted():
    result = review(CLEAN, channel="小红书", topic="立春")
    assert result.verdict == "ready_for_human"
    assert result.publishable is True
    assert result.auto_post is False


def test_own_channel_can_canary_and_unknown_channel_holds():
    assert review(CLEAN, channel="小程序", topic="立春").verdict == "ready_for_canary"
    held = review(CLEAN, channel="短信", topic="立春")
    assert held.verdict == "hold"
    assert held.publishable is False


def test_missing_aigc_label_is_rejected():
    text = "立春的作息可以往前挪一点，早一点睡。" + DISCLAIMER + " [A01#c1]"
    result = review(text, channel="站内", topic="立春")
    assert result.reasons == ["missing_aigc"]


def test_uncited_twelve_character_copy_is_rejected():
    stolen = "二十四节气只讨论睡觉和起床"
    text = CLEAN + stolen
    result = review(text, channel="站内", topic="立春", chunks=[("B09#c1", stolen + "时间安排")])
    assert result.reasons == ["uncited_copy"]
    cited = review(text, channel="站内", topic="立春", chunks=[("A01#c1", stolen)])
    assert "uncited_copy" not in cited.reasons


def test_weak_hook_holds():
    text = "嗯。" + DISCLAIMER + AIGC_LABEL + " [A01#c1]"
    assert hook_score(text, "立春") < HOOK_THRESHOLD
    assert review(text, channel="站内", topic="立春").verdict == "hold"


def test_hostile_input_becomes_refusal_without_echo():
    output = render_draft("xhs-note", "六味地黄丸每次 9 克怎么吃", "", "小红书")
    assert "不能写成发布稿" in output
    assert "9 克" not in output
    assert "六味地黄丸" not in output
    assert review(output, channel="小红书").publishable is False
