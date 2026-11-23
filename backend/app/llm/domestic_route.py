"""顺时问答路由。

症状、用药、剂量、疾病治疗、孕产用药、儿童用药、「能不能治」不调用模型，返回固定话术。
健康边界模糊题走通义千问 qwen3.5-plus。常规作息问答走 DeepSeek Flash，失败再按
豆包 lite → qwen-plus → 硅基流动（过渡）。
输出先过本地禁词，再过阿里云内容安全（配了密钥才发）。命中则丢弃，用千问重写一次；
仍命中则固定话术。超个人日帽或产品日帽时也不再调用模型。
"""

from __future__ import annotations

import logging
import os
import re

import httpx

from app.llm import cost_cap, domestic_gateway as gateway
from app.llm.guardrail import moderate_text
from app.safety.config import (
    DIET_GENERAL_NOTE,
    DIET_GENERAL_SYSTEM,
    HEALTH_BOUNDARY_REPLY,
    HEALTH_REFUSE_PATTERNS,
    is_general_diet_question,
)
from app.safety.pregnancy_drink import is_pregnancy_drink_question, pregnancy_drink_reply
from app.safety.scope import off_topic_kind, off_topic_reply

logger = logging.getLogger(__name__)

_REFUSE = [re.compile(pattern) for pattern in HEALTH_REFUSE_PATTERNS]
_BOUNDARY = [
    re.compile(pattern)
    for pattern in (
        r"体质",
        r"(孕期|孕妇|怀孕|哺乳|坐月子).{0,12}(作息|睡觉|睡眠|吃饭|饮食|运动)",
        r"(小孩|儿童|宝宝).{0,12}(作息|睡觉|睡眠|吃饭|几点)",
    )
]

SAFE_UNAVAILABLE = (
    "模型暂时不可用。可以先按平时的节奏休息、按时吃饭、早点睡。\n\n"
    "仅供作息安排参考，不是医疗诊断或治疗建议。"
)
_REWRITE_SYSTEM = (
    "你是顺时的作息助手，不是医生，也不要自称老师。"
    "把下面的草稿改写成只谈作息、饮食时间和走动的短句。"
    "禁止剂量、克数、疗效、可长期服用、诊断和体质诊断。"
    "如果做不到，只回复：仅供作息安排参考，不是医疗诊断或治疗建议。"
)


_DIET_REWRITE_SYSTEM = (
    "你是顺时的饮食作息助手，不是医生，也不要自称老师。"
    "把下面的草稿改写成平实的日常饮食建议（清淡、少盐少油、规律三餐、饮品适量这类常识）。"
    "禁止剂量、克数、疗程、疗效（不要写降血压、降血糖、治疗、预防疾病）、诊断，不推荐中药材、补品或保健品。"
    "结尾提醒有慢性病、孕期或哺乳期的人具体吃法请咨询医生。"
    "如果做不到，只回复：仅供作息安排参考，不是医疗诊断或治疗建议。"
)


def classify(text: str) -> str:
    sample = text or ""
    if off_topic_kind(sample):
        # 写代码、投资理财这类明显不在养生范围的请求：不调模型，礼貌引回（2026-11-23 真模型复测发现会直接写代码）。
        return "off_topic"
    if is_general_diet_question(sample):
        # 一般饮食 / 饮品咨询：主人 2026-11-22 批准不再固定拒答，走更谨慎的边界模型并带免责声明。
        return "diet"
    if any(pattern.search(sample) for pattern in _REFUSE):
        return "refuse"
    if any(pattern.search(sample) for pattern in _BOUNDARY):
        return "boundary"
    return "bulk"


def _last_user_text(messages: list[dict]) -> str:
    for message in reversed(messages):
        if message.get("role") == "user" and isinstance(message.get("content"), str):
            return message["content"]
    return ""


def _estimate_tokens(messages: list[dict], output: str = "") -> tuple[int, int]:
    incoming = sum(len(str(message.get("content") or "")) for message in messages)
    return max(1, incoming // 2), max(1, len(output) // 2)


def _over_cap(user_id: str, model: str, messages: list[dict], env: dict) -> bool:
    tokens_in, tokens_out = _estimate_tokens(messages, "x" * gateway.MAX_TOKENS_BY_TIER.get("free", 600))
    amount = cost_cap.estimate_cost_cny(model, tokens_in, tokens_out, env)
    user_scope = f"user:{user_id or 'anonymous'}"
    if cost_cap.would_exceed(user_scope, amount, cost_cap.user_daily_cap_cny(env)):
        return True
    return cost_cap.would_exceed("product", amount, cost_cap.product_daily_cap_cny(env))


def _charge(user_id: str, model: str, messages: list[dict], output: str, env: dict) -> None:
    tokens_in, tokens_out = _estimate_tokens(messages, output)
    amount = cost_cap.estimate_cost_cny(model, tokens_in, tokens_out, env)
    cost_cap.record(f"user:{user_id or 'anonymous'}", amount)
    cost_cap.record("product", amount)


def _output_blocked(text: str) -> bool:
    from app.safety.guard import safety_guard

    result = safety_guard.check_output(text, {"user_id": "route"})
    return bool(result.flag == "output_violation" or result.should_block)


_ROUTINE_DISCLAIMER = "仅供作息安排参考，不是医疗诊断或治疗建议。"
# 模型按系统提示自己写的「咨询医生」尾句；饮食固定尾注已经包含同样的意思。
_MODEL_DIET_TAIL = re.compile(r"有慢性病、?(正在)?孕期或哺乳期的(人)?，?具体(吃法|饮食)请咨询医生(或注册营养师)?[。.]?")


def _tidy_paragraphs(text: str) -> str:
    text = re.sub(r"[ \t]+\n", "\n", text)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip()


def _with_diet_note(text: str) -> str:
    """一般饮食回答只留一段尾注：去掉模型自己写的「仅供作息安排参考…」和「有慢性病…请咨询医生」，
    再补固定的饮食尾注（它已包含「不是医疗诊断」和「咨询医生」）。
    2026-11-23 真模型复测：茶饮回答末尾三段免责重复。"""
    body = (text or "").replace(DIET_GENERAL_NOTE, "")
    body = body.replace(_ROUTINE_DISCLAIMER, "")
    body = _MODEL_DIET_TAIL.sub("", body)
    body = _tidy_paragraphs(body)
    return f"{body}\n\n{DIET_GENERAL_NOTE}" if body else DIET_GENERAL_NOTE


def _dedupe_disclaimer(text: str) -> str:
    """作息回答里「仅供作息安排参考…」出现多次时只留最后一处。"""
    if (text or "").count(_ROUTINE_DISCLAIMER) <= 1:
        return text
    head, _, tail = text.rpartition(_ROUTINE_DISCLAIMER)
    return _tidy_paragraphs(head.replace(_ROUTINE_DISCLAIMER, "") + _ROUTINE_DISCLAIMER + tail)


async def _qwen(
    messages: list[dict],
    model: str,
    tier: str,
    client: httpx.AsyncClient,
    env: dict,
) -> str | None:
    provider = gateway.provider_by_name("dashscope")
    if provider is None:
        return None
    key = ""
    for name in provider.key_vars:
        key = (env.get(name) or "").strip()
        if key:
            break
    if not key:
        return None
    failures: list[str] = []
    return await gateway._post_provider(
        client,
        provider,
        key,
        messages,
        tier,
        env,
        failures,
        gateway.llm_timeout(env),
        model=model,
    )


async def answer(
    messages: list[dict[str, str]],
    tier: str = "free",
    *,
    user_id: str = "",
    client: httpx.AsyncClient | None = None,
    env: dict | None = None,
) -> str:
    source = os.environ if env is None else env
    from app.llm.offshore import warn_if_present

    warn_if_present(source)
    user_text = _last_user_text(messages)
    first = classify(user_text)
    if first == "off_topic":
        return off_topic_reply(off_topic_kind(user_text) or "")
    if first == "refuse":
        if is_pregnancy_drink_question(user_text):
            return pregnancy_drink_reply(user_text)
        return HEALTH_BOUNDARY_REPLY

    owns = client is None
    client = client or httpx.AsyncClient(timeout=gateway.llm_timeout(source))
    try:
        inbound = await moderate_text(user_text, client=client, env=source)
        if inbound.checked:
            cost_cap.record("product", cost_cap.guardrail_cost_cny(1, source))
            cost_cap.record(f"user:{user_id or 'anonymous'}", cost_cap.guardrail_cost_cny(1, source))
        if inbound.hit:
            return HEALTH_BOUNDARY_REPLY

        route = classify(user_text)
        if route == "diet":
            messages = [{"role": "system", "content": DIET_GENERAL_SYSTEM}, *messages]
        model = "qwen3.5-plus" if route in ("boundary", "diet") else "deepseek-flash"
        if _over_cap(user_id, model, messages, source):
            logger.info("domestic route cost cap: user=%s model=%s", user_id or "anonymous", model)
            return SAFE_UNAVAILABLE

        if route in ("boundary", "diet"):
            override = (source.get("SHUNSHI_QWEN_BOUNDARY_MODEL") or "qwen3.5-plus").strip()
            text = await _qwen(messages, override or "qwen3.5-plus", tier, client, source)
            used = override or "qwen3.5-plus"
            if not text:
                text = await gateway.complete(messages, tier, client=client, env=source)
                used = "deepseek-flash"
        else:
            text = await gateway.complete(messages, tier, client=client, env=source)
            used = "deepseek-flash"
        _charge(user_id, used, messages, text, source)

        outbound = await moderate_text(text, client=client, env=source)
        if outbound.checked:
            cost_cap.record("product", cost_cap.guardrail_cost_cny(1, source))
        blocked = _output_blocked(text) or outbound.hit
        if not blocked:
            return _with_diet_note(text) if route == "diet" else _dedupe_disclaimer(text)

        review_model = (source.get("SHUNSHI_QWEN_REVIEW_MODEL") or "qwen3.5-plus").strip() or "qwen3.5-plus"
        rewritten = await _qwen(
            [
                {"role": "system", "content": _DIET_REWRITE_SYSTEM if route == "diet" else _REWRITE_SYSTEM},
                {"role": "user", "content": text[:2000]},
            ],
            review_model,
            tier,
            client,
            source,
        )
        if rewritten and not _output_blocked(rewritten):
            again = await moderate_text(rewritten, client=client, env=source)
            if not again.hit:
                _charge(user_id, review_model, messages, rewritten, source)
                return _with_diet_note(rewritten) if route == "diet" else rewritten
        return HEALTH_BOUNDARY_REPLY
    finally:
        if owns:
            await client.aclose()
