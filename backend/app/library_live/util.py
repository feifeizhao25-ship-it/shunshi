from __future__ import annotations

import hashlib
import html as _html
import re
from datetime import date, datetime
from typing import Optional

REVIEWED_LABELS = {"已审核", "Reviewed"}
PENDING_LABELS = {"待审核", "Pending review"}

STATUS_CODES = {
    "现行": "in_force", "In force": "in_force",
    "征求意见稿": "draft", "Draft": "draft",
    "已废止": "repealed", "Repealed": "repealed",
    "待核实": "unverified", "To be verified": "unverified",
}
STATUS_LABELS = {
    "zh": {"in_force": "现行", "draft": "征求意见稿", "repealed": "已废止", "unverified": "待核实"},
    "en": {"in_force": "In force", "draft": "Draft", "repealed": "Repealed", "unverified": "To be verified"},
}


def status_code(label: Optional[str]) -> str:
    return STATUS_CODES.get(str(label or "").strip(), "unverified")


def is_reviewed(entry: dict) -> bool:
    return str(entry.get("review_status", "")).strip() in REVIEWED_LABELS


def parse_day(value) -> Optional[date]:
    """'2026-10-31' / '2026-10' / '2026-10-31T08:00:00+08:00' -> date（仅到月的取当月 1 日）。"""
    if value in (None, ""):
        return None
    if isinstance(value, datetime):
        return value.date()
    if isinstance(value, date):
        return value
    s = str(value).strip()
    m = re.match(r"^(\d{4})-(\d{2})(?:-(\d{2}))?", s)
    if not m:
        return None
    try:
        return date(int(m.group(1)), int(m.group(2)), int(m.group(3) or 1))
    except ValueError:
        return None


def iso(dt: datetime) -> str:
    """保留调用方给的时区（调度用 Asia/Shanghai），日期部分就是本地日期。"""
    return dt.isoformat(timespec="seconds")


def sha256(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


_DROP_BLOCKS = re.compile(r"<(script|style|noscript|nav|header|footer|aside|form|iframe|svg)\b[^>]*>.*?</\1>", re.S | re.I)
_COMMENTS = re.compile(r"<!--.*?-->", re.S)
_BLOCK_BREAK = re.compile(r"</?(p|div|br|li|tr|h[1-6]|section|article|table|ul|ol)\b[^>]*>", re.I)
_TAG = re.compile(r"<[^>]+>")
_TITLE = re.compile(r"<title[^>]*>(.*?)</title>", re.S | re.I)
# 页面里天天变、与内容无关的行（浏览量、分享、字号、当前时间…）
_NOISE_LINE = re.compile(
    r"(浏览量|阅读量|点击量|访问量|阅读次数|浏览次数|字号[:：]|打印本页|关闭窗口|分享到|扫一扫|当前位置|责任编辑|网站地图|"
    r"隐私政策|版权所有|ICP备|京公网安备|Cookie|cookies|Share this|Print this|Back to top|Skip to main content)", re.I)


def extract_text(raw_html: str) -> tuple[str, str]:
    """(title, 正文文本)：去掉脚本/导航/页脚，按块换行，丢掉浏览量之类的噪声行，压缩空白。"""
    m = _TITLE.search(raw_html)
    title = re.sub(r"\s+", " ", _html.unescape(m.group(1))).strip() if m else ""
    body = _COMMENTS.sub(" ", raw_html)
    body = _DROP_BLOCKS.sub(" ", body)
    body = _BLOCK_BREAK.sub("\n", body)
    body = _html.unescape(_TAG.sub(" ", body))
    lines = []
    for ln in body.splitlines():
        ln = re.sub(r"[ \t\u00a0\u3000]+", " ", ln).strip()
        if not ln or _NOISE_LINE.search(ln):
            continue
        lines.append(ln)
    return title, "\n".join(lines)


_LINK = re.compile(r"<a\b[^>]*?href\s*=\s*[\"']([^\"'#][^\"']*)[\"'][^>]*>(.*?)</a>", re.S | re.I)
_DATE = re.compile(r"(20\d{2})[-年./](\d{1,2})[-月./](\d{1,2})")


def extract_links(raw_html: str, base_url: str) -> list[dict]:
    from urllib.parse import urljoin

    out, seen = [], set()
    for m in _LINK.finditer(raw_html):
        href, inner = m.group(1).strip(), m.group(2)
        text = re.sub(r"\s+", " ", _html.unescape(_TAG.sub(" ", inner))).strip()
        if not text or href.lower().startswith(("javascript:", "mailto:")):
            continue
        url = urljoin(base_url, href)
        if url in seen:
            continue
        seen.add(url)
        tail = raw_html[m.end(): m.end() + 160]
        head = raw_html[max(0, m.start() - 120): m.start()]
        dm = _DATE.search(tail) or _DATE.search(head)
        d = None
        if dm:
            try:
                d = date(int(dm.group(1)), int(dm.group(2)), int(dm.group(3))).isoformat()
            except ValueError:
                d = None
        out.append({"title": text, "url": url, "date": d})
    return out
