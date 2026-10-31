"""资料库自动更新任务：挂在 SIL 已有的调度槽（daily_scan / weekly_cycle）上，复用 SIL 的白名单抓取和来源登记。

  library-check     每日 02:00（daily_scan 槽）：重新抓取每条已登记来源，比对内容摘要，写状态文件
  library-discover  每周日 03:00（weekly_cycle 槽）：读权威来源的列表页，把新文件的标题/链接暂存为候选
两个任务都只读网络、只写 SHUNSHI_LIBRARY_DIR 下的状态/快照/报告，不改条目，不让任何东西上线；
需要人看的变化追加到 SIL 的 worklist.jsonl（和「来源有更新」同一个工作清单）。
默认关闭：LIBRARY_FRESHNESS_ENABLED=1 才运行（与 SIL_ENABLED 无关，SIL 继续保持关闭也可以单独打开它）。
"""

from __future__ import annotations

import json
import os
from datetime import datetime
from pathlib import Path
from typing import Callable, Optional

from ..library import store
from ..library_live import FetchError, check_entries, discover, render_report
from .fetch import FetchRefused, _http_get, html_to_text  # noqa: F401
from .scheduler import SCHEDULE_DEFAULTS, TZ
from .sources import SourcePolicy, scan_injection
from .hooks import load_registry

SLOTS = {"library_check": SCHEDULE_DEFAULTS["daily_scan"], "library_discover": SCHEDULE_DEFAULTS["weekly_cycle"]}


def enabled(env=None) -> bool:
    env = os.environ if env is None else env
    return str(env.get("LIBRARY_FRESHNESS_ENABLED", "0")).strip().lower() in ("1", "true", "yes", "on")


def load_sources() -> dict:
    return json.loads((store.HERE / "data" / "sources.json").read_text("utf-8"))


def policy() -> SourcePolicy:
    src = load_sources()
    return SourcePolicy(allowed_domains=tuple(load_registry()["allowed_domains"]) + tuple(src.get("extra_allowed_domains", [])))


def make_fetch(pol: SourcePolicy, *, http: Optional[Callable] = None, timeout: float = 15.0):
    """SIL 的受限抓取（仅 https、仅白名单、不跨域跳转、限大小）+ 完整正文（SIL 自带的 fetch_page 只留前 2 万字）。"""
    from urllib.parse import urlparse

    upgrade = set(load_sources().get("http_upgrade_hosts", []))

    def fetch(url: str) -> dict:
        p = urlparse(url)
        if p.scheme == "http" and p.hostname in upgrade:
            url = url.replace("http://", "https://", 1)
            p = urlparse(url)
        if p.scheme != "https":
            raise FetchError("refused", None, "not_https")
        if not pol.domain_ok(p.hostname or ""):
            raise FetchError("refused", None, f"domain_not_whitelisted:{p.hostname}")
        try:
            body, charset = (http or _http_get)(url, timeout)
        except FetchRefused as e:
            raise FetchError("refused", None, str(e)) from e
        except OSError as e:  # URLError / HTTPError / timeout
            code = getattr(e, "code", None)
            raise FetchError("broken" if code in (404, 410) else "unreachable", code, type(e).__name__) from e
        try:
            raw = body.decode(charset, "replace")
        except LookupError:
            raw = body.decode("utf-8", "replace")
        from ..library_live.util import extract_text

        title, text = extract_text(raw)
        return {"url": url, "status": 200, "title": title, "text": text, "raw": raw}

    return fetch


def _write_json(path: Path, doc: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(".tmp")
    tmp.write_text(json.dumps(doc, ensure_ascii=False, indent=1, sort_keys=True), "utf-8")
    os.replace(tmp, path)


def _worklist(entries_changed: list, sil_dir: Path) -> None:
    sil_dir.mkdir(parents=True, exist_ok=True)
    with (sil_dir / "worklist.jsonl").open("a", encoding="utf-8") as f:
        for eid, st in entries_changed:
            f.write(json.dumps({"candidate": f"library-{eid}-{(st.get('content_hash') or '')[:8]}", "url": st.get("source_url"), "excerpt": "资料库条目来源有变化：" + ",".join(st.get("signals", []) or [st.get("check", "")])}, ensure_ascii=False) + "\n")


def run_check(now: Optional[datetime] = None, *, fetch=None, env=None, force: bool = False) -> dict:
    if not (force or enabled(env)):
        return {"status": "disabled"}
    now = now or datetime.now(TZ)
    d = store.data_dir()
    doc = store.load_document()
    prev = store.load_state()
    src = load_sources()
    new = check_entries(doc["entries"], prev, fetch or make_fetch(policy()), now, product="shunshi", snapshots_dir=d / "snapshots",
                        injection=scan_injection, manual_hosts=src.get("manual_hosts", {}))
    _write_json(d / "library_state.json", new)
    (d / "library_report.md").write_text(render_report(doc["entries"], new), "utf-8")
    attention = [(i, s) for i, s in new["entries"].items() if s.get("check") in ("changed", "repeal_signal", "url_broken") and prev.get("entries", {}).get(i, {}).get("check") != s["check"]]
    _worklist(attention, Path(os.environ.get("SIL_DATA_DIR", "var/self_improve/shunshi")))
    counts: dict = {}
    for s in new["entries"].values():
        counts[s["check"]] = counts.get(s["check"], 0) + 1
    return {"status": "ok", "checked": len(new["entries"]), "counts": counts, "attention": [i for i, _ in attention]}


def run_discover(now: Optional[datetime] = None, *, fetch=None, env=None, force: bool = False) -> dict:
    if not (force or enabled(env)):
        return {"status": "disabled"}
    now = now or datetime.now(TZ)
    d = store.data_dir()
    doc = store.load_document()
    st = store.load_state()
    pol = policy()
    known = [(e.get("source") or {}).get("url") for e in doc["entries"]]
    new = discover(load_sources()["watch"], st, fetch or make_fetch(pol), now, known_urls=[u for u in known if u], url_ok=lambda u: u.startswith("https://") and pol.domain_ok(__import__("urllib.parse", fromlist=["urlparse"]).urlparse(u).hostname or ""))
    _write_json(d / "library_state.json", new)
    rows = [{"id": c["id"], "type": "policy", "title": c["title"], "url": c["url"], "license": "政府公开", "license_class": "gov_public", "products": ["shunshi"], "grade": "B",
             "url_status": "listing", "flag": "待核：仅读过列表页标题，正文未读", "retrieved": c["found_at"][:10]} for c in new["candidates"]]
    (d / "library_candidates.jsonl").write_text("".join(json.dumps(r, ensure_ascii=False) + "\n" for r in rows), "utf-8")
    (d / "library_report.md").write_text(render_report(doc["entries"], new), "utf-8")
    return {"status": "ok", "candidates": len(new["candidates"]), "listing_errors": sorted(new.get("listing_errors", {}))}


def jobs() -> dict:
    """给 run.py serve 用：name -> (slot, fn(now))，与 SIL 其它任务同一个调度循环。"""
    return {"library_check": (SLOTS["library_check"], run_check), "library_discover": (SLOTS["library_discover"], run_discover)}
