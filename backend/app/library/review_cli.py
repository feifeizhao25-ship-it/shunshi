"""人工审核命令行（只有人会用；定时任务从不调用）。

  python -m app.library.review_cli approve ss-lib-001 --reviewer 张三
  python -m app.library.review_cli update ss-lib-003 --reviewer 张三 --note "新增物质由 9 种改为 10 种"
  python -m app.library.review_cli confirm ss-lib-003 --reviewer 张三        # 看过来源变化，对本条没有影响
  python -m app.library.review_cli repeal ss-lib-011 --reviewer 张三 --note "该文件已被新文件替代"
  python -m app.library.review_cli promote ss-lib-s01 --reviewer 张三        # 把暂存区候选复制进工作文档（仍是“待审核”，之后再 approve）
  python -m app.library.review_cli gate ss-lib-s01 --reviewer 张三           # “变好才上线”闸门：证据/安全/对照/不重复，只出报告不改任何东西
  python -m app.library.review_cli releases --reviewer 张三                  # 列出版本并校验哈希链
  python -m app.library.review_cli rollback v3 --reviewer 张三 --note "原因"  # 回滚到第 3 版（追加一条回滚记录，不删历史）
每次 promote/approve/update/repeal/rollback 都会在 SHUNSHI_LIBRARY_DIR/releases/ 留一份完整快照（哈希链）。
LIBRARY_PROMOTE_GATE=1 时 approve 必须先通过闸门（默认不强制，避免影响现有流程）。
写回 SHUNSHI_LIBRARY_DIR/reference_entries.json（第一次会从包内文件复制），审计日志 library_review_log.jsonl。
"""

from __future__ import annotations

import argparse
import json
import sys
from datetime import date

from ..library_live import review
from . import releases, store


def _domain_ok():
    try:
        from ..self_improve import library_job

        return library_job.policy().domain_ok
    except Exception:  # noqa: BLE001 — 没有白名单配置时不阻塞，证据分里就少这一项
        return None


def main(argv=None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("action", choices=["approve", "update", "confirm", "repeal", "promote", "gate", "releases", "rollback"])
    ap.add_argument("entry_id", nargs="?", default="-")
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
        if a.action == "releases":
            v = releases.verify(d)
            for r in releases.list_releases(d):
                print(f"v{r['version']} {r['at']} {r['action']} {r['entry_id']} by {r['reviewer']} {r.get('note','')}")
            print("chain " + ("ok" if v["ok"] else "BROKEN: " + "; ".join(v["problems"])))
            return 0 if v["ok"] else 3
        if a.action == "gate":
            from ..self_improve import promote_gate as PG

            cand = next((e for e in store.load_staged() if e["id"] == a.entry_id), None) or next((e for e in doc["entries"] if e["id"] == a.entry_id), None)
            if cand is None:
                raise review.ReviewError("unknown entry")
            others = [e for e in doc["entries"] if e["id"] != a.entry_id]
            r = PG.evaluate(cand, others, today=today, domain_ok=_domain_ok())
            print(json.dumps(r, ensure_ascii=False, indent=1))
            return 0 if r["decision"] == "keep" else 4
        if a.action == "rollback":
            if not (a.reviewer or "").strip():
                raise review.ReviewError("reviewer required")
            try:
                ver = int(a.entry_id.lstrip("vV"))
                doc = releases.rollback(d, ver, a.reviewer, a.note)
            except (ValueError, releases.ReleaseError) as e:
                raise review.ReviewError(str(e)) from e
            (d / "reference_entries.json").write_text(json.dumps(doc, ensure_ascii=False, indent=2), "utf-8")
            review._log(log, {"at": date.today().isoformat(), "action": "rollback", "to": ver, "reviewer": a.reviewer, "note": a.note})
            print(f"rollback to v{ver} by {a.reviewer}")
            return 0
        if not releases.list_releases(d) and (a.reviewer or "").strip():
            releases.record(d, doc, action="baseline", entry_id="-", reviewer=a.reviewer, note="第一次审核动作前的工作文档")
        gate_result = None
        if a.action == "approve":
            from ..self_improve import promote_gate as PG

            if PG.enforced():
                cand = next((e for e in doc["entries"] if e["id"] == a.entry_id), None)
                if cand is not None:
                    gate_result = PG.evaluate(cand, [e for e in doc["entries"] if e["id"] != a.entry_id], today=today, domain_ok=_domain_ok())
                    if gate_result["decision"] != "keep":
                        raise review.ReviewError("gate rejected: " + "; ".join(gate_result["reasons"]))
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
    releases.record(d, doc, action=a.action, entry_id=a.entry_id, reviewer=a.reviewer, note=a.note, gate=gate_result)
    (d / "library_state.json").write_text(json.dumps(st, ensure_ascii=False, indent=1, sort_keys=True), "utf-8")
    print(f"{a.action} {a.entry_id} by {a.reviewer}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
