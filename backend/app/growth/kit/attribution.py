"""Channel attribution: parse UTM and referrer into a small, privacy-safe record.

- Only allow-listed keys are kept; values are lower-cased, length-capped and dropped if they look like personal data.
- Click ids (gclid, fbclid, ttclid, msclkid) are recorded as a boolean 'has_click_id', never stored.
- No cookies, no fingerprinting. The caller decides whether consent allows storing the record.
"""
from __future__ import annotations

import re
from urllib.parse import parse_qs, urlparse

ALLOWED = ("utm_source", "utm_medium", "utm_campaign", "utm_content", "utm_term", "ref")
CLICK_IDS = ("gclid", "fbclid", "ttclid", "msclkid", "wbraid", "gbraid")
MAX_LEN = 64
_PII = [re.compile(r"[^@\s]+@[^@\s]+\.[a-z]{2,}", re.I), re.compile(r"\d{8,}"), re.compile(r"https?://", re.I)]
_SAFE = re.compile(r"[^a-z0-9_\-\.\u4e00-\u9fff]")

AI_SEARCH = ("chatgpt.com", "chat.openai.com", "perplexity.ai", "gemini.google.com", "copilot.microsoft.com", "claude.ai", "kimi.com", "doubao.com", "yuanbao.tencent.com", "tongyi.aliyun.com")
SEARCH = ("google.", "bing.com", "duckduckgo.com", "baidu.com", "sogou.com", "so.com", "yahoo.", "yandex.")
SOCIAL = ("reddit.com", "x.com", "twitter.com", "t.co", "linkedin.com", "facebook.com", "instagram.com", "tiktok.com", "youtube.com", "xiaohongshu.com", "douyin.com", "weibo.com", "bilibili.com", "zhihu.com", "mp.weixin.qq.com", "producthunt.com")
PAID_MEDIUMS = ("cpc", "ppc", "paid", "paidsocial", "display", "cpm", "ads")


def _clean(v: str) -> str | None:
    v = (v or "").strip().lower()[:MAX_LEN]
    if not v:
        return None
    if any(p.search(v) for p in _PII):
        return None
    v = _SAFE.sub("-", v).strip("-")
    return v or None


def _host(url: str) -> str:
    try:
        return (urlparse(url).hostname or "").lower()
    except ValueError:
        return ""


def classify(medium: str | None, referrer: str | None, has_click_id: bool = False) -> str:
    m = (medium or "").lower()
    if m in PAID_MEDIUMS or (has_click_id and m not in ("email", "social", "organic")):
        return "paid"
    if m == "email":
        return "email"
    if m in ("social", "social-organic"):
        return "social"
    if m in ("referral", "affiliate"):
        return "referral"
    h = _host(referrer or "")
    if h:
        if any(h == d or h.endswith("." + d) for d in AI_SEARCH):
            return "ai_search"
        if any(d in h for d in SEARCH):
            return "organic_search"
        if any(h == d or h.endswith("." + d) for d in SOCIAL):
            return "social"
        return "referral"
    return "direct"


def parse_attribution(url: str, referrer: str | None = None, own_hosts: tuple[str, ...] = ()) -> dict:
    """Return {'channel', 'utm_*': ..., 'has_click_id': bool}. Never raises on malformed input."""
    try:
        q = parse_qs(urlparse(url or "").query, keep_blank_values=False)
    except ValueError:
        q = {}
    rec: dict = {}
    for k in ALLOWED:
        v = _clean((q.get(k) or [""])[0])
        if v:
            rec[k] = v
    has_cid = any(k in q for k in CLICK_IDS)
    ref = referrer if _host(referrer or "") not in own_hosts else None
    rec["has_click_id"] = has_cid
    rec["channel"] = classify(rec.get("utm_medium"), ref, has_cid)
    return rec


def build_tagged_url(base: str, source: str, medium: str, campaign: str, content: str | None = None) -> str:
    """Create a tagged link for OpenClaw-prepared posts. Values are validated with the same cleaner."""
    parts = {"utm_source": source, "utm_medium": medium, "utm_campaign": campaign}
    if content:
        parts["utm_content"] = content
    cleaned = {k: _clean(v) for k, v in parts.items()}
    if not all(cleaned.values()):
        raise ValueError("utm value empty or looks like personal data")
    sep = "&" if "?" in base else "?"
    return base + sep + "&".join(f"{k}={v}" for k, v in cleaned.items())
