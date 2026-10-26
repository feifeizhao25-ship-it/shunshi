"""发布前的合规门。不改写文案，不通过就拒绝。

剂量、疗程和功效的判定复用 app.safety 里已经在用的模式，
广告法绝对化用语和购买链接在这里额外拦住。
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field

from app.growth.constants import (
    AIGC_LABEL,
    CITATION_RE,
    DISCLAIMER,
    HOOK_THRESHOLD,
    HOOK_WEIGHTS,
    HUMAN_CHANNELS,
    MIN_VERBATIM,
    OWN_CHANNELS,
    REFUSAL,
)

# 与 app/safety/config.py 的 output_violation_patterns 同一份。
# 不用 import app.safety：包初始化会打开内容库，cron 的 --dry-run 不能打出 [DB]。
def _output_patterns() -> tuple[str, ...]:
    import importlib.util
    from pathlib import Path

    path = Path(__file__).resolve().parents[2] / "safety" / "config.py"
    spec = importlib.util.spec_from_file_location("shunshi_safety_config_leaf", path)
    if spec is None or spec.loader is None:
        raise RuntimeError("缺少安全配置")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return tuple(module.SAFETY_CONFIG["output_violation_patterns"])


OUTPUT_PATTERNS = _output_patterns()

ABSOLUTE_TERMS = (
    "国家级",
    "最高级",
    "最佳",
    "独一无二",
    "100%有效",
    "绝对有效",
    "根治",
    "治愈",
    "药到病除",
    "全网第一",
    "史上最强",
    "无效退款",
    "包治",
)

# 与 app/safety/rules.py 的 medical_dosage_patterns 保持同一写法。
DOSAGE_PATTERNS = (
    r"(丸|散|膏|丹|颗粒|胶囊|口服液).{0,20}\d+(\.\d+)?\s*(克|g|毫克|mg)",
    r"(每次|每日|一日).{0,8}\d+(\.\d+)?\s*(克|g|毫克|mg)",
    r"(煎服|水煎|冲服|送服|温水送|空腹服|饭后服|饭前服)",
    r"(人参|黄芪|当归|川芎|党参|白术|茯苓|甘草|熟地|生地|枸杞|丹参|柴胡|半夏|附子|麻黄|桂枝|黄连|黄芩|大黄|红花|桃仁|杜仲|陈皮)"
    r"\s*\d+(\.\d+)?\s*(克|g|毫克|mg)",
)

LONG_TERM_RE = re.compile(r"可长期服用|长期服用")
EFFICACY_RE = re.compile(
    r"(增强|提高|提升).{0,4}免疫(力|功能)?"
    r"|排毒|利尿|消肿|祛湿排毒|抗病毒|降血压|降血糖|降血脂|治愈|根治|疗效"
)
PURCHASE_RE = re.compile(r"购买|下单|立即买|马上买")
LINK_RE = re.compile(r"https?://")


@dataclass(frozen=True)
class GateResult:
    verdict: str
    reasons: list[str] = field(default_factory=list)
    publishable: bool = False
    auto_post: bool = False


def violation_codes(text: str) -> list[str]:
    """返回命中的红线代号。空列表表示这段文字没有踩红线。"""
    codes: list[str] = []
    if LONG_TERM_RE.search(text):
        codes.append("long_term")
    if any(re.search(pattern, text) for pattern in DOSAGE_PATTERNS):
        codes.append("dosage")
    if EFFICACY_RE.search(text):
        codes.append("efficacy")
    if any(term in text for term in ABSOLUTE_TERMS):
        codes.append("absolute")
    if PURCHASE_RE.search(text) and LINK_RE.search(text):
        codes.append("purchase_link")
    for pattern in OUTPUT_PATTERNS:
        if re.search(pattern, text) and not _already_covered(codes, pattern):
            codes.append("safety_pattern")
            break
    return _dedupe(codes)


def _already_covered(codes: list[str], pattern: str) -> bool:
    if "长期服用" in pattern and "long_term" in codes:
        return True
    if any(token in pattern for token in ("免疫", "排毒", "治愈", "根治")) and "efficacy" in codes:
        return True
    if "dosage" in codes and any(token in pattern for token in ("克", "煎服", "配伍", "停药", "剂量")):
        return True
    return False


def _dedupe(codes: list[str]) -> list[str]:
    seen: list[str] = []
    for code in codes:
        if code not in seen:
            seen.append(code)
    return seen


def hook_score(text: str, topic: str) -> float:
    # 免责声明里本来就有「作息」，不拿它给钩子加分。
    body = text.replace(AIGC_LABEL, "").replace(DISCLAIMER, "")
    topic_score = 1.0 if topic and topic in body else (0.5 if "作息" in body else 0.0)
    length_score = 1.0 if 40 <= len(body) <= 800 else 0.2
    engagement = 1.0 if ("早一点睡" in body or "作息" in body) else 0.0
    labeled = 1.0 if AIGC_LABEL in text and DISCLAIMER in text else 0.0
    weights = HOOK_WEIGHTS
    parts = (topic_score, length_score, engagement, labeled)
    return round(sum(weight * part for weight, part in zip(weights, parts)), 4)


def cited_chunk_ids(text: str) -> set[str]:
    return {f"{source}#{chunk}" for source, chunk in CITATION_RE.findall(text)}


def has_uncited_verbatim(text: str, chunks: list[tuple[str, str]]) -> bool:
    """未标注的知识块若有连续 12 字被原文抄进稿子，就不许过门。"""
    cited = cited_chunk_ids(text)
    flattened = "".join(text.split())
    for chunk_id, chunk_text in chunks:
        if chunk_id in cited:
            continue
        compact = "".join(chunk_text.split())
        if len(compact) < MIN_VERBATIM:
            continue
        for index in range(len(compact) - MIN_VERBATIM + 1):
            if compact[index : index + MIN_VERBATIM] in flattened:
                return True
    return False


def review(
    text: str,
    *,
    channel: str,
    topic: str = "",
    chunks: list[tuple[str, str]] | None = None,
) -> GateResult:
    """判定一篇草稿能不能进队列。auto_post 永远是 False。"""
    if not text or REFUSAL in text:
        return GateResult("rejected", ["refusal"], False, False)

    reasons = violation_codes(text)
    if reasons:
        return GateResult("rejected", reasons, False, False)
    if AIGC_LABEL not in text:
        return GateResult("rejected", ["missing_aigc"], False, False)
    if DISCLAIMER not in text:
        return GateResult("rejected", ["missing_disclaimer"], False, False)
    if not cited_chunk_ids(text):
        return GateResult("rejected", ["missing_citation"], False, False)
    if chunks and has_uncited_verbatim(text, chunks):
        return GateResult("rejected", ["uncited_copy"], False, False)
    if hook_score(text, topic) < HOOK_THRESHOLD:
        return GateResult("hold", ["weak_hook"], False, False)
    if channel in HUMAN_CHANNELS:
        return GateResult("ready_for_human", [], True, False)
    if channel in OWN_CHANNELS:
        return GateResult("ready_for_canary", [], True, False)
    return GateResult("hold", ["unknown_channel"], False, False)
