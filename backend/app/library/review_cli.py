"""人工审核命令行（只有人会用；定时任务从不调用）。

  python -m app.library.review_cli approve ss-lib-001 --reviewer 张三
  python -m app.library.review_cli update ss-lib-003 --reviewer 张三 --note "新增物质由 9 种改为 10 种"
  python -m app.library.review_cli confirm ss-lib-003 --reviewer 张三        # 看过来源变化，对本条没有影响
  python -m app.library.review_cli repeal ss-lib-011 --reviewer 张三 --note "该文件已被新文件替代"
  python -m app.library.review_cli promote ss-lib-s01 --reviewer 张三        # 把暂存区候选复制进工作文档（仍是“待审核”，之后再 approve）
写回 SHUNSHI_LIBRARY_DIR/reference_entries.json（第一次会从包内文件复制），审计日志 library_review_log.jsonl。
"""

from __future__ import annotations

import argparse
import json
import sys
from datetime import date

from ..library_live import review
from . import store


def main(argv=None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("action", choices=["approve", "update", "confirm", "repeal", "promote"])
    ap.add_argument("entry_id")
    ap.add_argument("--reviewer", required=True)
    ap.add_argument("--note", default="")
    ap.add_argument("--superseded-by")
    a = ap.parse_args(argv)
    d = store.data_dir()
    d.mkdir(parents=True, exist_ok=True)
    doc = store.load_document()
    st = store.load_state()
    today = date.today()
    log = d / "library_review_log.jsonl"
    snaps = d / "snapshots"
    try:
        if a.action == "promote":
            cand = next((e for e in store.load_staged() if e["id"] == a.entry_id), None)
            if cand is None:
                raise review.ReviewError("not in staged area")
            if any(e["id"] == a.entry_id for e in doc["entries"]):
                raise review.ReviewError("already in document")
            if not (a.reviewer or "").strip():
                raise review.ReviewError("reviewer required")
            doc["entries"].append({**cand, "review_status": "待审核"})
            review._log(log, {"at": date.today().isoformat(), "action": "promote", "id": a.entry_id, "reviewer": a.reviewer})
        elif a.action == "approve":
            review.approve(doc, st, a.entry_id, a.reviewer, today, snapshots_dir=snaps, log_path=log)
        elif a.action == "update":
            review.update(doc, st, a.entry_id, a.reviewer, today, a.note, snapshots_dir=snaps, log_path=log)
        elif a.action == "confirm":
            review.confirm_unchanged(doc, st, a.entry_id, a.reviewer, today, snapshots_dir=snaps, log_path=log)
        else:
            review.repeal(doc, a.entry_id, a.reviewer, today, note=a.note, superseded_by=a.superseded_by, log_path=log)
    except review.ReviewError as e:
        print(f"error: {e}", file=sys.stderr)
        return 2
    (d / "reference_entries.json").write_text(json.dumps(doc, ensure_ascii=False, indent=2), "utf-8")
    (d / "library_state.json").write_text(json.dumps(st, ensure_ascii=False, indent=1, sort_keys=True), "utf-8")
    print(f"{a.action} {a.entry_id} by {a.reviewer}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
