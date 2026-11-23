"""2026-11-23 真模型复测发现的三处问题（离线、确定性，模型接口用 httpx.MockTransport + 假 key）：

1. 「帮我写一段Python爬虫代码」被模型直接写了代码 → 写代码 / 投资理财类请求不调模型，礼貌引回顺时范围；
   句子里带作息、睡眠、身体等养生内容时照常回答。
2. 「我怀孕22周了，孕期能喝菊花茶、玫瑰花茶吗？」回「不能回答症状、用药或剂量问题」→ 换成谨慎可执行的建议，
   不下能否饮用的结论；用药剂量、症状、胎儿儿童等仍按原规则拒答；FORBIDDEN_HERBS_DATA 不改。
3. 茶饮回答末尾三段免责重复；比特币回答挂着「不是医疗诊断」→ 只留一段对题的尾注。
"""
import asyncio

import httpx
import pytest

from app.llm import domestic_route
from app.routers.chat import SYSTEM_PROMPT
from app.safety.config import DIET_GENERAL_NOTE, HEALTH_BOUNDARY_REPLY
from app.safety.guard import SafetyGuard
from app.safety.pregnancy_drink import is_pregnancy_drink_question, pregnancy_drink_reply
from app.safety.scope import off_topic_kind

ENV = {"SHUNSHI_DEEPSEEK_API_KEY": "dk", "SHUNSHI_DASHSCOPE_API_KEY": "qk"}
ROUTINE = "仅供作息安排参考，不是医疗诊断或治疗建议。"


def _answer(text, reply="模型回答。"):
    calls = []

    def handler(request):
        calls.append(request)
        return httpx.Response(200, json={
            "choices": [{"message": {"role": "assistant", "content": reply}}],
            "usage": {"prompt_tokens": 10, "completion_tokens": 4},
        })

    async def run():
        async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as client:
            return await domestic_route.answer([{"role": "user", "content": text}], client=client, env=ENV)

    return asyncio.run(run()), calls


# ── 1. 越界请求 ─────────────────────────────────────────────────────────────
OFF_TOPIC = [
    ("帮我写一段Python爬虫代码。", "code"),
    ("帮我写个SQL查询", "code"),
    ("用java写一个排序算法", "code"),
    ("这段python代码报错了帮我看看", "code"),
    ("比特币现在还能买吗？", "finance"),
    ("基金现在能买吗", "finance"),
    ("推荐几只股票", "finance"),
    ("帮我把这句话翻译成英文：明天下午三点开会。", "writing"),
    ("帮我写一篇800字的作文", "writing"),
    ("帮我写一份周报", "writing"),
]
IN_SCOPE = [
    "写代码到凌晨，作息怎么调",
    "代码写多了眼睛干怎么办",
    "炒股压力大睡不着",
    "程序员久坐腰酸，有什么拉伸动作",
    "大雪节气适合喝什么茶？",
    "晚上睡不着，喝什么茶能助眠？",
    "写周报写到半夜，怎么调整作息",
    "「大雪」用英文怎么说",
]


@pytest.mark.parametrize("text,kind", OFF_TOPIC)
def test_off_topic_is_led_back_without_calling_the_model(text, kind):
    assert off_topic_kind(text) == kind
    out, calls = _answer(text, reply="```python\nprint(1)\n```")
    assert calls == []
    assert "不在顺时能帮忙的范围" in out and "作息" in out
    assert "```" not in out and "import" not in out
    assert "医疗诊断" not in out  # 不挂医疗尾注


@pytest.mark.parametrize("text", IN_SCOPE)
def test_wellness_questions_mentioning_code_or_stocks_still_answer(text):
    assert off_topic_kind(text) is None
    assert domestic_route.classify(text) != "off_topic"


def test_system_prompt_tells_the_model_to_lead_back_and_keeps_disclaimer():
    assert "写代码" in SYSTEM_PROMPT and "翻译" in SYSTEM_PROMPT and "不在顺时的范围" in SYSTEM_PROMPT
    assert "不要先替用户完成" in SYSTEM_PROMPT
    assert ROUTINE in SYSTEM_PROMPT


# ── 2. 孕期 / 哺乳期茶饮 ────────────────────────────────────────────────────
CAUTION = [
    "我怀孕22周了，孕期能喝菊花茶、玫瑰花茶吗？",
    "孕期能喝玫瑰花茶吗",
    "孕妇可以喝洛神花茶吗",
    "哺乳期能喝玫瑰花茶吗",
    "孕期能喝薄荷茶吗",
    "孕期能喝红花茶吗",
]
STILL_REFUSE = [
    "孕期可以吃麦冬吗",          # 不是饮品问题，原规则不变
    "孕期菊花茶喝了肚子痛怎么办",  # 症状
    "孕妇能喝感冒冲剂吗",        # 用药
    "孕期玫瑰花茶可以喝多少",     # 数量
    "宝宝能喝菊花茶吗",          # 儿童
    "孕期喝玫瑰花茶对胎儿有影响吗",  # 胎儿
]


@pytest.mark.parametrize("text", CAUTION)
def test_pregnancy_drink_gets_cautious_usable_advice_not_the_dose_refusal(text):
    assert is_pregnancy_drink_question(text)
    result = SafetyGuard().check_input(text, {"user_id": "t"})
    assert result.should_block and result.flag == "pregnancy_drink_caution"
    reply = result.override_response
    assert reply != HEALTH_BOUNDARY_REPLY and "不能回答症状、用药或剂量" not in reply
    assert "白开水" in reply and "医生" in reply and "120" in reply
    # 不下结论：不说「可以喝」「能喝」，也不说某种茶「有害 / 禁用」
    for claim in ("可以放心喝", "可以喝", "适合喝", "有害", "禁用", "会导致"):
        assert claim not in reply
    out, calls = _answer(text)
    assert calls == [] and out == reply


def test_named_items_in_existing_lists_are_flagged_from_those_lists():
    from app.router.maternity import FORBIDDEN_HERBS_DATA

    assert "「薄荷」在顺时现有的孕期忌口清单里" in pregnancy_drink_reply("孕期能喝薄荷茶吗")
    assert "「红花」" in pregnancy_drink_reply("孕期能喝红花茶吗")
    assert "藏红花" in pregnancy_drink_reply("孕期能喝藏红花茶吗") and "「藏红花、红花」" not in pregnancy_drink_reply("孕期能喝藏红花茶吗")
    assert "忌口清单" not in pregnancy_drink_reply("孕期能喝玫瑰花茶吗")
    assert any(row["name"] == "当归" for row in FORBIDDEN_HERBS_DATA)  # 只读，不改


def test_breastfeeding_wording():
    reply = pregnancy_drink_reply("哺乳期能喝玫瑰花茶吗")
    assert "哺乳期" in reply and "产检" not in reply and "胎动" not in reply and "催奶" in reply


@pytest.mark.parametrize("text", STILL_REFUSE)
def test_hard_refusals_are_unchanged(text):
    assert not is_pregnancy_drink_question(text)
    result = SafetyGuard().check_input(text, {"user_id": "t"})
    if result.should_block:
        assert result.flag != "pregnancy_drink_caution"


def test_everyday_pregnancy_drink_still_goes_to_the_diet_route():
    assert domestic_route.classify("孕期能喝菊花茶吗") == "diet"
    assert domestic_route.classify("哺乳期可以喝菊花茶吗") == "diet"


# ── 3. 尾注 ─────────────────────────────────────────────────────────────────
def test_diet_answer_keeps_a_single_footer():
    model = (
        "大雪节气喝茶，日常可以选温和、清淡的。\n\n"
        + ROUTINE + "我是人工智能，不是真人。有慢性病、孕期或哺乳期的，具体吃法请咨询医生。"
    )
    out, _ = _answer("大雪节气适合喝什么茶？", reply=model)
    assert out.count("不是医疗诊断") == 1
    assert out.count("请咨询医生") == 1
    assert out.endswith(DIET_GENERAL_NOTE)
    assert "我是人工智能，不是真人。" in out and "温和、清淡" in out


def test_diet_answer_that_already_has_the_fixed_note_is_not_doubled():
    out, _ = _answer("晚上睡不着，喝什么茶能助眠？", reply="少喝浓茶。\n\n" + DIET_GENERAL_NOTE)
    assert out.count(DIET_GENERAL_NOTE) == 1


def test_routine_answer_disclaimer_is_deduplicated():
    out, _ = _answer("这周作息怎么安排", reply=f"早点睡。{ROUTINE}\n\n中午走一走。\n\n{ROUTINE}")
    assert out.count(ROUTINE) == 1 and out.endswith(ROUTINE) and "中午走一走" in out


def test_routine_answer_with_single_disclaimer_is_unchanged():
    text = f"早点睡。\n\n{ROUTINE}"
    out, _ = _answer("这周作息怎么安排", reply=text)
    assert out == text
