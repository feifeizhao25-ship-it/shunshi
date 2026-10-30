"""受限抓取：仅 https、仅白名单域名、限大小、限超时、不跟随跨域重定向。

返回的文本一律当数据处理（见 sources.as_data / scan_injection）。网络函数可注入，便于测试。
"""

from __future__ import annotations

import hashlib
import html
import re
import urllib.request
from typing import Callable
from urllib.parse import urlparse

from .sources import SourcePolicy

MAX_BYTES = 400_000
UA = "Mozilla/5.0 (compatible; SelfImproveBot/1.0; +official-sources-only)"
_TAG = re.compile(r"<(script|style|noscript)[^>]*>.*?</\1>|<[^>]+>", re.S | re.I)
_TITLE = re.compile(r"<title[^>]*>(.*?)</title>", re.S | re.I)


class FetchRefused(Exception):
    pass


class _SameDomainRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        if urlparse(newurl).hostname != urlparse(req.full_url).hostname:
            raise FetchRefused("cross_domain_redirect")
        return super().redirect_request(req, fp, code, msg, headers, newurl)


def _http_get(url: str, timeout: float) -> tuple[bytes, str]:
    opener = urllib.request.build_opener(_SameDomainRedirect)
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "text/html,*/*;q=0.5"})
    with opener.open(req, timeout=timeout) as r:  # noqa: S310 — scheme 已在 fetch_page 校验为 https
        return r.read(MAX_BYTES), r.headers.get_content_charset() or "utf-8"


def html_to_text(raw: str) -> tuple[str, str]:
    m = _TITLE.search(raw)
    title = html.unescape(m.group(1)).strip() if m else ""
    text = html.unescape(_TAG.sub(" ", raw))
    return title, re.sub(r"\s+", " ", text).strip()


def fetch_page(url: str, policy: SourcePolicy, *, timeout: float = 10.0, http: Callable[[str, float], tuple[bytes, str]] | None = None) -> dict:
    p = urlparse(url)
    if p.scheme != "https":
        raise FetchRefused("not_https")
    if not policy.domain_ok(p.hostname or ""):
        raise FetchRefused(f"domain_not_whitelisted:{p.hostname}")
    body, charset = (http or _http_get)(url, timeout)
    try:
        raw = body.decode(charset, "replace")
    except LookupError:
        raw = body.decode("utf-8", "replace")
    title, text = html_to_text(raw)
    return {"url": url, "title": title, "text": text[:20_000], "hash": hashlib.sha256(text.encode("utf-8")).hexdigest()}
