"""Share-card payloads (Open Graph + text) with language and disclaimer checks.

Returns a dict; `errors` non-empty means the card must not be shown or posted.
"""
from __future__ import annotations

from dataclasses import dataclass

from . import claims
from .attribution import build_tagged_url

DISCLAIMERS = {
    ("en", "wellness"): "For general wellness. Not medical advice.",
    ("en", "culture"): "For reflection and entertainment only.",
    ("en", "energy"): "Estimates only. Not investment advice.",
    ("en", "content"): "AI-assisted. Review before publishing.",
    ("zh", "wellness"): "仅供日常养生参考，不构成医疗建议。",
    ("zh", "culture"): "文化参考，仅供参考与娱乐。",
    ("zh", "energy"): "测算结果仅供参考，不构成投资建议。",
    ("zh", "content"): "内容由 AI 辅助生成，发布前请人工审阅。",
}
MAX_TITLE = {"en": 60, "zh": 30}
MAX_DESC = {"en": 160, "zh": 80}


@dataclass(frozen=True)
class CardInput:
    locale: str            # "en" or "zh"
    topic: str             # wellness | culture | energy | content
    title: str
    description: str
    landing_url: str
    source: str = "share"  # utm_source
    campaign: str = "sharecard"
    image_url: str | None = None


def build(inp: CardInput) -> dict:
    errors: list[str] = []
    if inp.locale not in ("en", "zh"):
        errors.append("locale")
    if (inp.locale, inp.topic) not in DISCLAIMERS:
        errors.append("topic")
    text = f"{inp.title} {inp.description}"
    if inp.locale == "en" and not claims.is_english_only(text):
        errors.append("english_only_violation")
    if inp.locale == "zh" and not claims.is_chinese_surface(text):
        errors.append("chinese_surface_violation")
    if inp.locale in MAX_TITLE:
        if len(inp.title) > MAX_TITLE[inp.locale]:
            errors.append("title_too_long")
        if len(inp.description) > MAX_DESC[inp.locale]:
            errors.append("description_too_long")
    for cat, m in claims.scan(text):
        errors.append(f"claim:{cat}:{m}")
    if errors:
        return {"errors": errors}
    url = build_tagged_url(inp.landing_url, inp.source, "social-organic", inp.campaign)
    disc = DISCLAIMERS[(inp.locale, inp.topic)]
    return {
        "errors": [],
        "og": {"og:title": inp.title, "og:description": inp.description, "og:url": url, "og:type": "website",
               **({"og:image": inp.image_url} if inp.image_url else {})},
        "twitter": {"twitter:card": "summary_large_image", "twitter:title": inp.title, "twitter:description": inp.description},
        "text": f"{inp.title}\n{inp.description}\n{url}\n{disc}",
        "disclaimer": disc,
    }
