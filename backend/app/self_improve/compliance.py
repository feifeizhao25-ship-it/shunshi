"""语义级合规预检（离线、确定性）。

字面匹配容易被拆字、全半角、插入标点绕过。这里先做归一化（NFKC、去零宽/分隔符、
繁简常见字、数字/英文同形），再用「词族」规则匹配，作为字面禁用词之外的第二层。
不能替代各产品自己的规则，只是统一的底线；任何命中都视为未通过。
"""

from __future__ import annotations

import re
import unicodedata
from dataclasses import dataclass, field
from typing import Iterable, Mapping

_ZERO_WIDTH = dict.fromkeys(map(ord, "\u200b\u200c\u200d\u2060\ufeff"), None)
# 少量常见变体；不追求完整，仅堵最常见的绕过。
_VARIANTS = str.maketrans(
    {"穩": "稳", "賺": "赚", "報": "报", "酬": "酬", "險": "险", "確": "确", "診": "诊", "斷": "断", "療": "疗", "買": "买", "賣": "卖"}
)


def normalize(text: str) -> str:
    t = unicodedata.normalize("NFKC", text or "").translate(_ZERO_WIDTH).translate(_VARIANTS).lower()
    # 去掉所有标点/符号/空白/控制字符（含各种破折号、间隔号），堵「稳—赚—不—赔」之类拆字
    return "".join(ch for ch in t if unicodedata.category(ch)[0] not in "PZSC")


# 词族：每个族 -> 一组正则（作用于归一化后的文本，因此不含分隔符）
FAMILIES: dict[str, tuple[str, ...]] = {
    "investment_advice": (
        r"(建议|推荐|强烈建议|务必|应该|可以)(你|您)?(立即|马上|现在)?(买入|卖出|加仓|减仓|清仓|满仓|抄底|重仓)",
        r"(买入|增持|持有|卖出|减持)评级",
        r"目标价(为|是|看到)?\d",
        r"(稳赚|稳赚不赔|包赚|必涨|必赚|翻倍|暴涨|保本|保收益|零风险|无风险)",
    ),
    "return_promise": (
        r"(年化|收益率?|回报率?|回报).{0,6}(保证|承诺|稳定在|不低于|可达到?)\d",
        r"(保证|确保|承诺).{0,4}(收益|回本|盈利|赚钱|回报)",
        r"\d+个?月(回本|收回成本)(保证|一定|必然)",
    ),
    "rating": (r"(强烈推荐|首选|首推|最佳|第一名|top1)(投资|标的|电站|项目|企业|公司|基金|股票)", r"(信用|投资|行业)评级(为|是|给予)"),
    "medical_diagnosis": (
        r"(你|您)(患有|得了|患上|是).{0,8}(病|症|炎|癌|综合征)",
        r"(诊断|确诊)(为|是|结果)",
        r"(治愈|根治|药到病除|包治|替代(药物|药品|医生|就医))",
        r"(停药|不用吃药|不必就医|无需就医)",
        r"(处方|剂量|每日).{0,6}\d+(克|g|mg|毫克|片|粒)",
    ),
    "deterministic_fate": (
        r"(你|您)(一定|必将|注定|必然|肯定)(会)?(发财|离婚|早逝|生病|破产|结婚|成功|失败|有灾)",
        r"(寿命|阳寿|大限|死期|何时去世|活到\d+岁)",
        r"(命中注定|命里注定|逃不过|在劫难逃)",
    ),
    "absolute_claim": (r"(百分之百|100|绝对|一定)(有效|安全|准确|不会出错|没有副作用|无副作用)", r"(最|第一|唯一|国家级|顶级)(有效|安全|权威)(?!的?参考)"),
}


@dataclass
class ComplianceResult:
    ok: bool
    hits: list[tuple[str, str]] = field(default_factory=list)  # (family, matched)

    @property
    def families(self) -> list[str]:
        return sorted({f for f, _ in self.hits})


def check(
    text: str,
    families: Iterable[str] | None = None,
    extra_literals: Iterable[str] = (),
    extra_patterns: Mapping[str, Iterable[str]] | None = None,
) -> ComplianceResult:
    """两层：词族正则 + 额外字面词（同样先归一化，所以拆字/全半角绕不过去）。"""
    norm = normalize(text)
    hits: list[tuple[str, str]] = []
    fams = list(families) if families is not None else list(FAMILIES)
    for fam in fams:
        for pat in FAMILIES.get(fam, ()):
            m = re.search(pat, norm)
            if m:
                hits.append((fam, m.group(0)))
    for fam, pats in (extra_patterns or {}).items():
        for pat in pats:
            m = re.search(pat, norm)
            if m:
                hits.append((fam, m.group(0)))
    for lit in extra_literals:
        n = normalize(lit)
        if n and n in norm:
            hits.append(("literal", lit))
    return ComplianceResult(ok=not hits, hits=hits)
