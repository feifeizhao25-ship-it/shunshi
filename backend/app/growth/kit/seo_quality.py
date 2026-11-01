"""Programmatic-page quality gate aligned with Google's scaled-content-abuse policy (G12/G13) and GEO evidence (G01/G02).

A page may only go live if it has: enough original substance, a real difference from sibling pages, dated sources,
title/body that match the user question it answers, no forbidden claims, and an AI-assistance note when AI wrote it.
Structured data is generated for rich-result eligibility only; we do NOT claim it improves AI citations (G03).
"""
from __future__ import annotations

import json
import re
from dataclasses import dataclass, field
from datetime import date

from . import claims

MIN_WORDS_EN = 150
MIN_CHARS_ZH = 300
MAX_SIBLING_SIMILARITY = 0.60
MIN_QUESTION_OVERLAP = 0.5
_WORD = re.compile(r"[a-z0-9']+")


@dataclass
class PageDraft:
    url: str
    locale: str                 # "en" | "zh"
    question: str               # the real user question this page answers
    title: str
    body: str
    sources: list = field(default_factory=list)   # [{"url":..., "date":"YYYY-MM-DD"}]
    ai_assisted: bool = True
    ai_note: str = ""


def _tokens(text: str, locale: str) -> list[str]:
    if locale == "zh":
        chars = [c for c in text if "\u3400" <= c <= "\u9fff"]
        return ["".join(chars[i:i + 2]) for i in range(max(len(chars) - 1, 0))]
    return _WORD.findall(text.lower())


def _shingles(tokens: list[str], k: int = 3) -> set:
    if len(tokens) < k:
        return {tuple(tokens)} if tokens else set()
    return {tuple(tokens[i:i + k]) for i in range(len(tokens) - k + 1)}


def similarity(a: str, b: str, locale: str) -> float:
    sa, sb = _shingles(_tokens(a, locale)), _shingles(_tokens(b, locale))
    if not sa or not sb:
        return 0.0
    return len(sa & sb) / len(sa | sb)


def question_overlap(question: str, title: str, body_head: str, locale: str) -> float:
    q = set(_tokens(question, locale))
    if not q:
        return 0.0
    t = set(_tokens(title + " " + body_head, locale))
    return len(q & t) / len(q)


def check(page: PageDraft, siblings: list[str], today: date | None = None, max_source_age_days: int = 365) -> dict:
    today = today or date.today()
    reasons: list[str] = []
    if page.locale == "en":
        if not claims.is_english_only(page.title + page.body):
            reasons.append("english_only_violation")
        if len(_WORD.findall(page.body.lower())) < MIN_WORDS_EN:
            reasons.append("thin_content")
    elif page.locale == "zh":
        if len([c for c in page.body if "\u3400" <= c <= "\u9fff"]) < MIN_CHARS_ZH:
            reasons.append("thin_content")
        if not claims.is_chinese_surface(page.title + page.body):
            reasons.append("chinese_surface_violation")
    else:
        reasons.append("locale")
    if question_overlap(page.question, page.title, page.body[:400], page.locale) < MIN_QUESTION_OVERLAP:
        reasons.append("question_mismatch")
    worst = max((similarity(page.body, s, page.locale) for s in siblings), default=0.0)
    if worst > MAX_SIBLING_SIMILARITY:
        reasons.append("near_duplicate")
    if not page.sources:
        reasons.append("no_sources")
    else:
        for s in page.sources:
            try:
                age = (today - date.fromisoformat(s.get("date", ""))).days
            except ValueError:
                reasons.append("source_date_invalid"); break
            if age > max_source_age_days:
                reasons.append("source_stale"); break
    for cat, m in claims.scan(page.title + " " + page.body):
        reasons.append(f"claim:{cat}")
    if page.ai_assisted and not page.ai_note.strip():
        reasons.append("missing_ai_note")
    return {"publish": not reasons, "noindex": bool(reasons), "reasons": sorted(set(reasons)), "max_sibling_similarity": round(worst, 3)}


def article_jsonld(page: PageDraft, published: str, author_name: str) -> str:
    """schema.org Article for rich-result eligibility. Validate in Search Console before relying on it (G05)."""
    data = {"@context": "https://schema.org", "@type": "Article", "headline": page.title[:110], "datePublished": published,
            "author": {"@type": "Organization", "name": author_name}, "mainEntityOfPage": page.url, "inLanguage": page.locale}
    return json.dumps(data, ensure_ascii=False, sort_keys=True)
