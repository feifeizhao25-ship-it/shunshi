"""命令行入口。默认关闭（SIL_ENABLED=0 时每个子命令都只返回 disabled）。

  python -m app.self_improve.run weekly     # 每周日 03:00（Asia/Shanghai）
  python -m app.self_improve.run monthly    # 每月 1 日 04:00
  python -m app.self_improve.run daily      # 每日 02:00：过期扫描（只读）
  python -m app.self_improve.run serve      # 常驻调度进程（docker-compose 的 self-improve 服务）
  python -m app.self_improve.run decide <candidate_id> approve|reject <reviewer>   # 企业微信回调落地
  python -m app.self_improve.run eval       # 只跑评测并打印指标（不改任何东西）
  python -m app.self_improve.run library-check|library-discover   # 资料库来源核对 / 新候选暂存（LIBRARY_FRESHNESS_ENABLED=1 才运行）
"""

from __future__ import annotations

import json
import sys
from datetime import date, datetime

from .hooks import build_loop
from .scheduler import SCHEDULE_DEFAULTS, TZ, run_forever


def main(argv=None) -> int:
    argv = list(sys.argv[1:] if argv is None else argv)
    cmd = argv[0] if argv else "eval"
    loop, sh = build_loop()
    if cmd == "eval":
        from . import evals

        print(json.dumps(evals.evaluate_all(), ensure_ascii=False, indent=2, default=str))
        return 0
    if cmd == "weekly":
        print(json.dumps(loop.run_weekly(datetime.now(TZ)).__dict__, ensure_ascii=False, default=str))
        return 0
    if cmd == "monthly":
        print(json.dumps(loop.run_monthly(date.today()), ensure_ascii=False))
        return 0
    if cmd == "daily":
        print(json.dumps(loop.run_monthly(date.today()) if loop.cfg.enabled else {"status": "disabled"}, ensure_ascii=False))
        return 0
    if cmd in ("library-check", "library-discover"):
        from . import library_job

        print(json.dumps((library_job.run_check if cmd == "library-check" else library_job.run_discover)(), ensure_ascii=False))
        return 0
    if cmd in ("golden", "stale", "radar", "radar-stage", "monthly-report"):
        from . import continuous

        fn = {"golden": continuous.run_golden, "stale": continuous.run_stale, "radar": continuous.run_radar, "radar-stage": continuous.run_radar_stage,
              "monthly-report": continuous.run_monthly_report}[cmd]
        kw = {"force": "--force" in argv}  # --force：人工手动跑一次，不改任何开关
        if cmd == "monthly-report" and "--month" in argv:
            kw["month"] = argv[argv.index("--month") + 1]
        print(json.dumps(fn(**kw), ensure_ascii=False, default=str))
        return 0
    if cmd == "decide" and len(argv) == 4:
        c = loop.record_decision(argv[1], argv[3], argv[2] == "approve", datetime.now(TZ))
        print(c.state)
        return 0
    if cmd == "serve":
        jobs = {
            "daily": (SCHEDULE_DEFAULTS["daily_scan"], lambda now: loop.run_monthly(now.date())),
            "weekly": (SCHEDULE_DEFAULTS["weekly_cycle"], loop.run_weekly),
            "monthly": (SCHEDULE_DEFAULTS["monthly_maintenance"], lambda now: loop.run_monthly(now.date())),
        }
        from . import library_job

        jobs.update(library_job.jobs())  # 资料库核对复用同一个调度循环和时间槽
        from . import continuous

        for k, v in continuous.jobs().items():
            jobs.setdefault(k, v)  # 金标准评测 / 陈旧扫描 / 雷达 / 暂存 / 月报；雷达若已被别处注册就不重复
        run_forever(jobs)
        return 0
    print(__doc__)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
