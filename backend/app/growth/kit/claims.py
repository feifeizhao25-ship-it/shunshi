"""Forbidden-claim scanner shared by share cards, SEO pages and loop candidates.

Covers: medical efficacy, fate/future prediction, investment promises, absolute superlatives, fake-review wording.
Lists are intentionally conservative; a hit means "hold for human review", never "auto-fix".
"""
from __future__ import annotations

import re

_EN = {
    "medical": [r"\bcures?\b", r"\btreats?\s+(?:depression|anxiety|insomnia|disease|cancer|diabetes)", r"\bheals?\s+(?:disease|illness)", r"\breplaces?\s+(?:your\s+)?medication", r"\bclinically\s+proven\b", r"\bdiagnos(?:e|es|is)\b"],
    "prediction": [r"\bpredicts?\s+your\s+(?:fate|future|destiny)", r"\bguaranteed\s+(?:reading|prediction|accuracy)", r"\btells?\s+your\s+fortune\b"],
    "investment": [r"\bguaranteed\s+returns?\b", r"\brisk[- ]free\b", r"\bsure\s+profit", r"\b(?:we|our\s+\w+)\s+(?:give|gives|provide|provides|offer|offers)\s+investment\s+advice\b"],
    "absolute": [r"\bthe\s+best\s+in\s+the\s+world\b", r"(?<!\w)#1\b", r"\bonly\s+solution\b"],
    "fake_review": [r"\b(?:5|five)[- ]star\s+review\s+for\s+(?:a\s+)?free\b", r"\bpaid\s+reviews?\b"],
}
_ZH = {
    "medical": [r"治愈", r"治疗(?:抑郁|焦虑|失眠|疾病|癌|糖尿病)", r"根治", r"替代药物", r"临床验证"],
    "prediction": [r"算出(?:你的)?命运", r"保证(?:算)?准", r"预测(?:你的)?(?:财运|命运|前途)"],
    "investment": [r"保证收益", r"稳赚", r"零风险", r"包赚"],
    "absolute": [r"全网第一", r"唯一(?:方案|选择)", r"最(?:好|强|佳)(?=的|产品|工具)"],
    "fake_review": [r"好评返现", r"刷(?:好评|单|量)"],
}
_C_EN = {k: [re.compile(p, re.I) for p in v] for k, v in _EN.items()}
_C_ZH = {k: [re.compile(p) for p in v] for k, v in _ZH.items()}


def scan(text: str) -> list[tuple[str, str]]:
    """Return [(category, matched_text)] over both languages."""
    hits: list[tuple[str, str]] = []
    for table in (_C_EN, _C_ZH):
        for cat, pats in table.items():
            for p in pats:
                for m in p.finditer(text or ""):
                    hits.append((cat, m.group(0)))
    return hits


_CJK = re.compile(r"[\u3400-\u9fff\uf900-\ufaff]")


def has_cjk(text: str) -> bool:
    return bool(_CJK.search(text or ""))


def is_english_only(text: str) -> bool:
    return not has_cjk(text)


def is_chinese_surface(text: str) -> bool:
    """Chinese surface: must contain CJK; Latin is allowed for brand names, URLs, units."""
    return has_cjk(text)
