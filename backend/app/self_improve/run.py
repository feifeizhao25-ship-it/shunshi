"""命令行入口。默认关闭（SIL_ENABLED=0 时每个子命令都只返回 disabled）。

  python -m app.self_improve.run weekly     # 每周日 03:00（Asia/Shanghai）
  python -m app.self_improve.run monthly    # 每月 1 日 04:00
  python -m app.self_improve.run daily      # 每日 02:00：过期扫描（只读）
  python -m app.self_improve.run serve      # 常驻调度进程（docker-compose 的 self-improve 服务）
  python -m app.self_improve.run decide <candidate_id> approve|reject <reviewer>   # 企业微信回调落地
  python -m app.self_improve.run eval       # 只跑评测并打印指标（不改任何东西）
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
        run_forever(jobs)
        return 0
    print(__doc__)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
