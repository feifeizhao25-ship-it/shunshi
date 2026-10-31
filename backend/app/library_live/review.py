"""人工审核后的写回。必须带审核人姓名；每一步写审计日志；不会被定时任务调用。

approve  ：待审核 -> 已审核，记下审核人/日期、当前来源内容摘要（之后来源再变就会被发现）
update   ：来源变了、人重新读过并改好条目后，写「更新于」「变更说明」，并把基线换成最新来源
repeal   ：标为已废止（用户端不再显示）
"""

from __future__ import annotations

import json
import shutil
from datetime import date, datetime
from pathlib import Path
from typing import Optional

from .util import iso


class ReviewError(ValueError):
    pass


def _find(doc: dict, eid: str) -> dict:
    for e in doc["entries"]:
        if e["id"] == eid:
            return e
    raise ReviewError(f"unknown entry {eid}")


def _log(log_path: Optional[Path], rec: dict) -> None:
    if log_path:
        Path(log_path).parent.mkdir(parents=True, exist_ok=True)
        with open(log_path, "a", encoding="utf-8") as f:
            f.write(json.dumps(rec, ensure_ascii=False) + "\n")


def _need(reviewer: str) -> str:
    reviewer = (reviewer or "").strip()
    if not reviewer:
        raise ReviewError("reviewer name is required")
    return reviewer


def _pin(doc_entry: dict, state: dict, snapshots_dir: Optional[Path]) -> None:
    st = (state or {}).get("entries", {}).get(doc_entry["id"])
    if st and st.get("content_hash"):
        doc_entry["reviewed_hash"] = st["content_hash"]
        st["baseline_hash"], st["baseline_title"] = st["content_hash"], st.get("title", "")
        st["check"], st["change"], st["baseline_unverified"] = "ok", None, False
        if snapshots_dir:
            latest = Path(snapshots_dir) / f"{doc_entry['id']}.latest.txt"
            if latest.exists():
                shutil.copyfile(latest, Path(snapshots_dir) / f"{doc_entry['id']}.baseline.txt")


def approve(doc: dict, state: dict, eid: str, reviewer: str, today: date, *, review_labels=("已审核", "待审核"),
            snapshots_dir=None, log_path=None) -> dict:
    reviewer = _need(reviewer)
    e = _find(doc, eid)
    if e.get("review_status") == review_labels[0]:
        raise ReviewError("already reviewed")
    e.update({"review_status": review_labels[0], "reviewer": reviewer, "reviewed_at": today.isoformat(), "last_verified_at": today.isoformat(),
              "version": int(e.get("version", 0)) + 1})
    e.setdefault("approved_at", today.isoformat())  # 首次上线日：推荐里的「新」只看它
    _pin(e, state, snapshots_dir)
    _log(log_path, {"at": iso(datetime.now().astimezone()), "action": "approve", "id": eid, "reviewer": reviewer, "reviewed_hash": e.get("reviewed_hash")})
    return e


def update(doc: dict, state: dict, eid: str, reviewer: str, today: date, change_note: str, *, snapshots_dir=None, log_path=None) -> dict:
    reviewer = _need(reviewer)
    if not (change_note or "").strip():
        raise ReviewError("change_note is required")
    e = _find(doc, eid)
    e.update({"updated_on": today.isoformat(), "change_note": change_note.strip(), "last_verified_at": today.isoformat(),
              "reviewer": reviewer, "reviewed_at": today.isoformat(), "version": int(e.get("version", 0)) + 1})
    _pin(e, state, snapshots_dir)
    _log(log_path, {"at": iso(datetime.now().astimezone()), "action": "update", "id": eid, "reviewer": reviewer, "note": change_note.strip(), "reviewed_hash": e.get("reviewed_hash")})
    return e


def confirm_unchanged(doc: dict, state: dict, eid: str, reviewer: str, today: date, *, snapshots_dir=None, log_path=None) -> dict:
    """人读过变化后确认「对本条没有影响」：只更新核对日和基线，不写『更新于』。"""
    reviewer = _need(reviewer)
    e = _find(doc, eid)
    e.update({"last_verified_at": today.isoformat(), "reviewer": reviewer, "reviewed_at": today.isoformat()})
    _pin(e, state, snapshots_dir)
    _log(log_path, {"at": iso(datetime.now().astimezone()), "action": "confirm_unchanged", "id": eid, "reviewer": reviewer})
    return e


def repeal(doc: dict, eid: str, reviewer: str, today: date, *, labels=("已废止",), note: str = "", superseded_by: Optional[str] = None, log_path=None) -> dict:
    reviewer = _need(reviewer)
    e = _find(doc, eid)
    e.update({"status": labels[0], "status_note": note or e.get("status_note", ""), "reviewer": reviewer, "reviewed_at": today.isoformat(), "updated_on": today.isoformat()})
    if superseded_by:
        e["superseded_by"] = superseded_by
    _log(log_path, {"at": iso(datetime.now().astimezone()), "action": "repeal", "id": eid, "reviewer": reviewer, "note": note})
    return e
