"""重新抓取每条资料的官方来源，发现变化，只写「状态文件」，从不改条目本身。"""

from __future__ import annotations

import difflib
import json
import re
from datetime import datetime, timedelta
from pathlib import Path
from typing import Callable, Iterable, Optional
from urllib.parse import urlparse

from .util import extract_links, extract_text, is_reviewed, iso, parse_day, sha256

BROKEN_STATUSES = (404, 410)
REPEAL_RE = re.compile(r"(已废止|已失效|失效日期|废止日期|不再适用|已被废止|被废止|已被.{0,12}替代|停止执行|has been repealed|no longer in force|withdrawn|superseded by)", re.I)
REVISION_RE = re.compile(r"(修订|修正|修改的决定|第[一二三四五六七八九十]+次修正|revised|updated version|amended)", re.I)
HEAD_CHARS = 400
MINOR_RATIO = 0.002  # 变动字数占全文比例低于它，且不涉及数字/废止/修订，只记录不拦截


class FetchError(Exception):
    """抓取失败。kind: broken（404/410）| unreachable | refused（域名不在白名单、跨域跳转等）。"""

    def __init__(self, kind: str, status: Optional[int] = None, detail: str = ""):
        super().__init__(f"{kind}:{status}:{detail}")
        self.kind, self.status, self.detail = kind, status, detail


Fetch = Callable[[str], dict]  # url -> {"url","status","title","text","raw"}


def _digits(s: str) -> list[str]:
    return re.findall(r"\d+(?:\.\d+)?", s)


def diff_summary(old: str, new: str, *, samples: int = 4) -> dict:
    a, b = old.splitlines(), new.splitlines()
    sm = difflib.SequenceMatcher(None, a, b, autojunk=False)
    added, removed, sample, changed_chars = [], [], [], 0
    for tag, i1, i2, j1, j2 in sm.get_opcodes():
        if tag == "equal":
            continue
        removed += a[i1:i2]
        added += b[j1:j2]
        if tag == "replace" and i2 - i1 == j2 - j1:  # 同样行数的替换：逐行比到字，措辞微调不会被算成整行变动
            for x, y in zip(a[i1:i2], b[j1:j2]):
                cm = difflib.SequenceMatcher(None, x, y, autojunk=False)
                changed_chars += sum(max(p2 - p1, q2 - q1) for t2, p1, p2, q1, q2 in cm.get_opcodes() if t2 != "equal")
        else:
            changed_chars += sum(len(x) for x in a[i1:i2]) + sum(len(x) for x in b[j1:j2])
        if len(sample) < samples:
            sample.append({"old": " / ".join(a[i1:i2])[:160], "new": " / ".join(b[j1:j2])[:160]})
    ratio = changed_chars / max(len(old) + len(new), 1)
    digits_changed = sorted(_digits("\n".join(added))) != sorted(_digits("\n".join(removed)))
    return {"added": len(added), "removed": len(removed), "ratio": round(ratio, 5), "digits_changed": digits_changed, "samples": sample}


def _marker_counts(text: str) -> dict:
    return {"repeal": len(REPEAL_RE.findall(text)), "revision": len(REVISION_RE.findall(text))}


def evaluate_source(entry: dict, prev: Optional[dict], page: Optional[dict], err: Optional[FetchError], now: datetime, *,
                    baseline_text: Optional[str] = None, injection=None) -> dict:
    """纯函数：上一次状态 + 这次抓取结果 -> 新状态（一条）。"""
    reviewed = is_reviewed(entry)
    st = dict(prev or {})
    st.setdefault("first_seen_at", iso(now))
    st["source_url"] = (entry.get("source") or {}).get("url", "")
    st["last_checked_at"] = iso(now)
    if err is not None:
        st["failures"] = int(st.get("failures", 0)) + 1
        st["http_status"] = err.status
        st["check"] = {"broken": "url_broken", "refused": "refused"}.get(err.kind, "unreachable")
        st["error"] = err.kind
        return st
    assert page is not None
    st["failures"] = 0
    st.pop("error", None)
    st["http_status"] = page.get("status", 200)
    title, text = page["title"], page["text"]
    h = sha256(text)
    st["title"], st["content_hash"], st["chars"] = title, h, len(text)
    signals: list[str] = []
    if injection:
        signals += [f"injection:{p}" for p in injection(text)]
    baseline_hash = (entry.get("reviewed_hash") if reviewed else None) or (prev or {}).get("baseline_hash")
    st["baseline_hash"] = baseline_hash or h
    if not prev and not entry.get("reviewed_hash"):
        st.update({"check": "ok", "baseline_title": title, "markers": _marker_counts(text), "baseline_unverified": True})
        st["last_ok_at"] = iso(now)
        st["signals"] = signals
        return st
    base_title = (prev or {}).get("baseline_title", title)
    base_markers = (prev or {}).get("markers") or _marker_counts(text)
    st.setdefault("baseline_title", base_title)
    st.setdefault("markers", base_markers)
    if h == st["baseline_hash"]:
        st.update({"check": "ok", "change": None, "last_ok_at": iso(now), "signals": signals})
        return st
    # 内容变了
    mk = _marker_counts(text)
    head = title + "\n" + text[:HEAD_CHARS]
    repeal = bool(REPEAL_RE.search(head)) or mk["repeal"] > base_markers.get("repeal", 0)
    revision = bool(REVISION_RE.search(title) and not REVISION_RE.search(base_title)) or mk["revision"] > base_markers.get("revision", 0)
    if title != base_title:
        signals.append("title_changed")
    if revision:
        signals.append("revision_marker")
    if repeal:
        signals.append("repeal_marker")
    ch = diff_summary(baseline_text, text) if baseline_text is not None else {"added": None, "removed": None, "ratio": None, "digits_changed": True, "samples": []}
    pc = (prev or {}).get("change") or {}
    ch["detected_at"] = pc.get("detected_at") if (prev or {}).get("content_hash") == h and pc.get("detected_at") else iso(now)
    minor = (ch["ratio"] is not None and ch["ratio"] < MINOR_RATIO and not ch["digits_changed"] and not repeal and not revision and title == base_title)
    if repeal:
        st["check"] = "repeal_signal"
    elif minor:
        st["check"] = "minor_change"
        st["last_ok_at"] = iso(now)
    else:
        st["check"] = "changed"
    st["change"], st["signals"] = ch, signals
    if not reviewed:  # 还没人审的条目：基线跟着最新走，只记录变化，免得刷屏
        st["baseline_hash"], st["baseline_title"], st["markers"] = h, title, mk
    return st


def _snap_path(d: Optional[Path], eid: str, kind: str) -> Optional[Path]:
    return None if d is None else Path(d) / f"{eid}.{kind}.txt"


def check_entries(entries: Iterable[dict], state: Optional[dict], fetch: Fetch, now: datetime, *, product: str = "",
                  snapshots_dir: Optional[Path] = None, injection=None, only_reviewed: bool = False,
                  manual_hosts: Optional[dict] = None) -> dict:
    """逐条抓取官方来源。单条失败不影响其它条。返回新的状态（含 entries/生成时间），不改入参。"""
    state = json.loads(json.dumps(state or {"schema": 1, "entries": {}, "candidates": []}))
    state.setdefault("entries", {})
    state.setdefault("candidates", [])
    state["schema"], state["product"], state["generated_at"] = 1, product or state.get("product", ""), iso(now)
    cache: dict[str, tuple] = {}
    manual_hosts = manual_hosts or {}
    for e in entries:
        if only_reviewed and not is_reviewed(e):
            continue
        url = (e.get("source") or {}).get("url")
        if not url or e.get("status") == "已废止":
            continue
        host = urlparse(url).hostname or ""
        if host in manual_hosts:  # 该站点拒绝程序访问：不抓取，也不装作核对过；靠人工到浏览器核对（超时就提示）
            prev = state["entries"].get(e["id"], {})
            state["entries"][e["id"]] = {**prev, "source_url": url, "check": "manual", "reason": manual_hosts[host], "last_checked_at": iso(now),
                                         "first_seen_at": prev.get("first_seen_at", iso(now))}
            continue
        if url in cache:
            page, err = cache[url]
        else:
            try:
                page, err = fetch(url), None
            except FetchError as ex:
                page, err = None, ex
            except Exception as ex:  # noqa: BLE001 一条出错不拖累其它
                page, err = None, FetchError("unreachable", None, type(ex).__name__)
            cache[url] = (page, err)
        base_p = _snap_path(snapshots_dir, e["id"], "baseline")
        baseline_text = base_p.read_text("utf-8") if base_p and base_p.exists() else None
        prev = state["entries"].get(e["id"])
        new = evaluate_source(e, prev, page, err, now, baseline_text=baseline_text, injection=injection)
        state["entries"][e["id"]] = new
        if snapshots_dir and page is not None:
            Path(snapshots_dir).mkdir(parents=True, exist_ok=True)
            first = _snap_path(snapshots_dir, e["id"], "baseline")
            if not first.exists() or not is_reviewed(e):
                first.write_text(page["text"], "utf-8")
            _snap_path(snapshots_dir, e["id"], "latest").write_text(page["text"], "utf-8")
    return state


def discover(watch: Iterable[dict], state: dict, fetch: Fetch, now: datetime, *, known_urls: Iterable[str] = (), url_ok=None,
             recent_days: int = 45, max_new: int = 20) -> dict:
    """从权威来源的列表页暂存新候选（只有标题、链接、日期；永远「待核实 / 待审核」，不进库、不进检索）。

    watch 每项：id、name、publisher、listing_url、title_include（任一关键词）、license_note、category_hint。
    第一次见到某个列表页时只记「已见」，只暂存标题命中且发布日期在 recent_days 内的链接。
    """
    state = json.loads(json.dumps(state))
    state.setdefault("candidates", [])
    seen = state.setdefault("seen_links", {})
    known = set(known_urls) | {c["url"] for c in state["candidates"]}
    added = 0
    for w in watch:
        lid = w["id"]
        try:
            page = fetch(w["listing_url"])
        except FetchError as ex:
            state.setdefault("listing_errors", {})[lid] = {"at": iso(now), "kind": ex.kind, "status": ex.status}
            continue
        except Exception as ex:  # noqa: BLE001
            state.setdefault("listing_errors", {})[lid] = {"at": iso(now), "kind": "unreachable", "error": type(ex).__name__}
            continue
        state.get("listing_errors", {}).pop(lid, None)
        first_time = lid not in seen
        known_here = set(seen.get(lid, []))
        links = extract_links(page.get("raw") or "", w["listing_url"])
        include = [k.lower() for k in w.get("title_include", [])]
        for ln in links:
            if url_ok and not url_ok(ln["url"]):
                continue
            is_new = ln["url"] not in known_here
            known_here.add(ln["url"])
            if not is_new or ln["url"] in known:
                continue
            if include and not any(k in ln["title"].lower() for k in include):
                continue
            d = parse_day(ln["date"])
            if first_time and not (d and (now.date() - d) <= timedelta(days=recent_days)):
                continue
            if added >= max_new:
                break
            cand = {
                "id": "cand-" + sha256(ln["url"])[:10], "title": ln["title"], "url": ln["url"], "listing_id": lid,
                "listing_url": w["listing_url"], "publisher": w.get("publisher", ""), "publish_date": ln["date"],
                "category_hint": w.get("category_hint", ""), "found_at": iso(now),
                "provenance": {"fetched_at": iso(now), "listing_hash": sha256(page["text"]), "read_scope": "仅列表页标题与日期，正文未读", "tier": "待核实（未达 A 级）"},
                "license_note": w.get("license_note", ""), "status": "待核实", "review_status": "待审核",
            }
            state["candidates"].append(cand)
            known.add(ln["url"])
            added += 1
        seen[lid] = sorted(known_here)[-800:]
    state["generated_at"] = iso(now)
    return state


CHECK_ZH = {"manual": "该站点拒绝程序访问，需人工到浏览器核对", "ok": "未变化", "minor_change": "细微变动（已记录）", "changed": "来源内容有变化", "repeal_signal": "来源出现「废止/失效」迹象",
            "url_broken": "链接失效", "unreachable": "暂时无法访问", "refused": "被抓取规则拒绝"}


def render_report(entries: list[dict], state: dict) -> str:
    """给审核人看的 Markdown 摘要（中文）。"""
    by = {e["id"]: e for e in entries}
    lines = [f"# 资料库来源核对报告（{state.get('generated_at', '')}）", ""]
    attn = [(i, s) for i, s in state.get("entries", {}).items() if s.get("check") not in ("ok",)]
    lines.append(f"- 已核对 {len(state.get('entries', {}))} 条；需要人看的 {len(attn)} 条；新候选 {len(state.get('candidates', []))} 条。")
    lines.append("- 以上只是提示，没有任何内容因此上线或被改写；是否更新由审核人决定。")
    lines.append("")
    if attn:
        lines.append("## 需要人工处理")
        for i, s in sorted(attn):
            e = by.get(i, {})
            lines.append(f"- **{i}** {e.get('title', '')}：{CHECK_ZH.get(s.get('check'), s.get('check'))}"
                         + (f"（{', '.join(s.get('signals', []))}）" if s.get("signals") else "") + f"  来源：{s.get('source_url', '')}")
            ch = s.get("change") or {}
            for smp in ch.get("samples", [])[:2]:
                lines.append(f"  - 旧：{smp['old']}\n  - 新：{smp['new']}")
    cands = state.get("candidates", [])
    if cands:
        lines.append("")
        lines.append("## 暂存的新候选（只读过标题，需人工读全文后才可能成为条目）")
        for c in cands:
            lines.append(f"- {c['title']}（{c.get('publisher', '')}，{c.get('publish_date') or '日期未知'}）{c['url']}")
    return "\n".join(lines) + "\n"
