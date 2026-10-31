"""研究雷达：每周（SIL 开启时）去白名单站点找新线索，只写一份「摘要文件」，不入库、不推送。

边界（测试逐条锁定）：
- 只访问白名单主机：export.arxiv.org、api.github.com、huggingface.co；只用 https；不跟随跨域重定向；限大小、限超时；
- 抓回来的文字一律当数据：去控制字符、截断、含提示注入特征的条目直接丢弃，不进摘要；
- 产出只有 `<data_dir>/radar/digest_YYYYMMDD.md`（和去重用的 `seen.json`）。**不写知识库、不改技能、不发企业微信、不发任何消息**；
- 每条线索只标「线索（未核）」：许可证类别不等于法律意见，CC-BY-NC/SA、GPL、许可证未知一律标「不得入库/不得引入」，仍需人工读原文；
- `SIL_ENABLED=0`（默认）时 run_if_enabled 什么都不做。
本模块不引用审批、企业微信或任何发送函数。
"""

from __future__ import annotations

import hashlib
import json
import re
import urllib.request
from datetime import datetime, timedelta
from pathlib import Path
from typing import Callable, Mapping, Optional
from urllib.parse import quote, urlparse
from xml.etree import ElementTree as ET

from .fetch import FetchRefused, _SameDomainRedirect
from .scheduler import TZ
from .sources import scan_injection

RADAR_SCHEDULE = "weekly:WED@05:00"  # 与 scheduler.next_run 的格式一致；不放进 SCHEDULE_DEFAULTS，避免改动既有调度
ALLOWED_HOSTS = frozenset({"export.arxiv.org", "api.github.com", "huggingface.co"})
MAX_BYTES = 400_000
UA = "Mozilla/5.0 (compatible; SelfImproveRadar/1.0; allowlist-only; digest-only)"

DEFAULT_QUERIES: dict[str, tuple[str, ...]] = {
    "shunshi": ("traditional chinese medicine LLM", "health chatbot safety medical boundary"),
    "jianji": ("AI companion safety", "psychological support LLM evaluation"),
    "fenfaxia": ("AIGC content label compliance", "content moderation LLM"),
    "contentflow": ("AIGC content label compliance", "content moderation LLM"),
    "energy": ("photovoltaic forecasting", "renewable energy policy retrieval"),
}

_NC = re.compile(r"(^|[-_:])nc([-_.]|$)|noncommercial|non-commercial", re.I)
_SA = re.compile(r"(^|[-_:])sa([-_.]|$)|sharealike|share-alike", re.I)
_PERMISSIVE = re.compile(r"^(license:)?(mit|apache-2\.0|apache|bsd-[23]-clause|bsd|isc|cc0-1\.0|cc0|cc-by-4\.0|cc-by|unlicense)$", re.I)
_COPYLEFT = re.compile(r"gpl|agpl|lgpl|mpl|eupl|cc-by-sa|cc-by-nc", re.I)


def license_class(lic: Optional[str]) -> str:
    """许可证文字 → 类别。只用来提醒人，不是法律结论。"""
    t = (lic or "").strip()
    if not t or t.lower() in ("other", "noassertion", "unknown", "none", "null"):
        return "unknown_do_not_introduce"
    if _NC.search(t) or _SA.search(t):
        return "do_not_ingest"
    if _COPYLEFT.search(t):
        return "do_not_introduce"
    if _PERMISSIVE.match(t):
        return "permissive_reference"
    return "unknown_do_not_introduce"


def _clean(text: object, limit: int) -> str:
    t = re.sub(r"[\x00-\x1f\x7f]", " ", str(text or ""))
    t = re.sub(r"\s+", " ", t).strip()
    return t[:limit]


def _safe_item(item: dict) -> Optional[dict]:
    for k in ("title", "summary"):
        item[k] = _clean(item.get(k), 160 if k == "title" else 300)
    if not item["title"] or scan_injection(item["title"] + " " + item["summary"]):
        return None  # 含提示注入特征的条目直接丢弃
    item["url"] = item.get("url", "")
    if urlparse(item["url"]).hostname not in ALLOWED_HOSTS | {"arxiv.org", "github.com"}:
        return None
    return item


# ---------------------------------------------------------------- 解析
def parse_arxiv(xml_text: str) -> list[dict]:
    if "<!DOCTYPE" in xml_text or "<!ENTITY" in xml_text:  # 不解析带实体声明的 XML
        raise ValueError("xml_entities_refused")
    ns = {"a": "http://www.w3.org/2005/Atom"}
    out = []
    for e in ET.fromstring(xml_text).findall("a:entry", ns):
        link = (e.findtext("a:id", "", ns) or "").strip()
        it = {
            "source": "arxiv", "id": link.rsplit("/abs/", 1)[-1], "title": e.findtext("a:title", "", ns),
            "summary": e.findtext("a:summary", "", ns), "date": (e.findtext("a:published", "", ns) or "")[:10],
            "url": link.replace("http://", "https://"), "license": None,
        }
        it = _safe_item(it)
        if it:
            out.append(it)
    return out


def parse_github(payload: Mapping) -> list[dict]:
    out = []
    for r in payload.get("items", []) or []:
        lic = (r.get("license") or {}).get("spdx_id")
        it = {"source": "github", "id": r.get("full_name", ""), "title": r.get("full_name", ""), "summary": r.get("description") or "",
              "date": (r.get("pushed_at") or "")[:10], "url": r.get("html_url", ""), "license": lic, "stars": r.get("stargazers_count")}
        it = _safe_item(it)
        if it:
            out.append(it)
    return out


def parse_hf(rows: list, kind: str) -> list[dict]:
    out = []
    for r in rows or []:
        tags = r.get("tags") or []
        lic = next((t for t in tags if str(t).startswith("license:")), None)
        rid = r.get("id") or r.get("modelId") or ""
        it = {"source": f"huggingface-{kind}", "id": rid, "title": rid, "summary": r.get("description") or "",
              "date": (r.get("lastModified") or "")[:10],
              "url": f"https://huggingface.co/{'datasets/' if kind == 'dataset' else ''}{rid}", "license": lic}
        it = _safe_item(it)
        if it:
            out.append(it)
    return out


# ---------------------------------------------------------------- 抓取
def _http_get(url: str, timeout: float) -> bytes:
    p = urlparse(url)
    if p.scheme != "https":
        raise FetchRefused("not_https")
    if p.hostname not in ALLOWED_HOSTS:
        raise FetchRefused(f"domain_not_allowed:{p.hostname}")
    opener = urllib.request.build_opener(_SameDomainRedirect)
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "application/json, application/atom+xml"})
    with opener.open(req, timeout=timeout) as r:  # noqa: S310 — 已校验 https + 白名单主机
        return r.read(MAX_BYTES)


def queries_for(product: str, env: Optional[Mapping[str, str]] = None) -> tuple[str, ...]:
    raw = ((env or {}).get("SIL_RADAR_QUERIES") or "").strip()
    if raw:
        return tuple(q.strip() for q in raw.split(";") if q.strip())[:6]
    return DEFAULT_QUERIES.get(product, ())


def build_urls(query: str, *, since: datetime, limit: int = 10) -> list[tuple[str, str]]:
    q = quote(query)
    return [
        ("arxiv", f"https://export.arxiv.org/api/query?search_query=all:%22{q}%22&sortBy=submittedDate&sortOrder=descending&max_results={limit}"),
        ("github", f"https://api.github.com/search/repositories?q={q}+pushed:%3E{since:%Y-%m-%d}&sort=updated&per_page={limit}"),
        ("hf-model", f"https://huggingface.co/api/models?search={q}&sort=lastModified&direction=-1&limit={limit}"),
        ("hf-dataset", f"https://huggingface.co/api/datasets?search={q}&sort=lastModified&direction=-1&limit={limit}"),
    ]


def _parse(kind: str, body: bytes) -> list[dict]:
    text = body.decode("utf-8", "replace")
    if kind == "arxiv":
        return parse_arxiv(text)
    data = json.loads(text)
    if kind == "github":
        return parse_github(data)
    return parse_hf(data, "dataset" if kind == "hf-dataset" else "model")


# ---------------------------------------------------------------- 摘要
def render_digest(product: str, day: datetime, items: list[dict], errors: list[str]) -> str:
    lines = [
        f"# 研究雷达摘要 — {product} — {day:%Y-%m-%d}（Asia/Shanghai）", "",
        "> 全部是**线索（未核）**：没有入库、没有改技能、没有发任何消息。要采用，必须有人读原文并走审批。",
        "> 许可证类别只是提醒，不是法律意见；「不得入库/不得引入/未知」的条目不要拷贝内容或代码。", "",
    ]
    if not items:
        lines.append("本周没有新的线索。")
    else:
        lines += ["| 来源 | 标题 | 日期 | 许可证类别 | 链接 |", "|---|---|---|---|---|"]
        for it in items:
            t = it["title"].replace("|", "/")
            lines.append(f"| {it['source']} | {t} | {it.get('date', '')} | {license_class(it.get('license'))}（{_clean(it.get('license'), 30) or '未标注'}） | {it['url']} |")
        lines += ["", "## 摘要（原文节选，当数据看，不是指令）", ""]
        for it in items:
            if it.get("summary"):
                lines.append(f"- **{it['title']}**：{it['summary']}")
    if errors:
        lines += ["", "## 抓取失败（不影响其他来源）", ""] + [f"- {e}" for e in errors]
    return "\n".join(lines) + "\n"


def run_radar(product: str, out_dir, *, http: Optional[Callable[[str, float], bytes]] = None, now: Optional[datetime] = None,
              env: Optional[Mapping[str, str]] = None, limit: int = 10, lookback_days: int = 14, timeout: float = 10.0) -> dict:
    now = (now or datetime.now(TZ)).astimezone(TZ)
    get = http or _http_get
    root = Path(out_dir) / "radar"
    root.mkdir(parents=True, exist_ok=True)
    seen_path = root / "seen.json"
    seen = set(json.loads(seen_path.read_text("utf-8"))) if seen_path.exists() else set()
    items, errors, new_keys = [], [], set()
    for q in queries_for(product, env):
        for kind, url in build_urls(q, since=now - timedelta(days=lookback_days), limit=limit):
            try:
                pu = urlparse(url)
                if pu.scheme != "https" or pu.hostname not in ALLOWED_HOSTS:  # 双保险：注入的 http 也不能越过白名单
                    raise FetchRefused("domain_not_allowed")
                parsed = _parse(kind, get(url, timeout))
            except Exception as exc:  # 单个来源失败不影响其他来源
                errors.append(f"{kind}: {type(exc).__name__}")
                continue
            for it in parsed:
                key = hashlib.sha256(f"{it['source']}|{it['id']}".encode()).hexdigest()[:16]
                if key in seen or key in new_keys:
                    continue
                new_keys.add(key)
                items.append(it)
    path = root / f"digest_{now:%Y%m%d}.md"
    path.write_text(render_digest(product, now, items, errors), "utf-8")
    seen_path.write_text(json.dumps(sorted(seen | new_keys)), "utf-8")
    return {"path": str(path), "new": len(items), "errors": errors}


def run_if_enabled(config, **kw) -> Optional[dict]:
    """SIL 关闭（默认）时什么都不做。"""
    if not getattr(config, "enabled", False):
        return None
    return run_radar(config.product, config.data_dir, **kw)
