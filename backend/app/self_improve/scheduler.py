"""极简调度器（Asia/Shanghai）。给没有 celery/apscheduler 的后端用，也可被产品内已有调度器调用 next_run 校验。

支持三种写法：
  daily@02:00
  weekly:SUN@03:00     (MON..SUN)
  monthly:1@04:00
"""

from __future__ import annotations

import re
import time
from datetime import datetime, timedelta
from typing import Callable
from zoneinfo import ZoneInfo

TZ = ZoneInfo("Asia/Shanghai")
_DAYS = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"]

SCHEDULE_DEFAULTS = {
    "daily_scan": "daily@02:00",
    "weekly_cycle": "weekly:SUN@03:00",
    "weekly_report": "weekly:MON@09:30",
    "monthly_maintenance": "monthly:1@04:00",
}


def next_run(spec: str, now: datetime) -> datetime:
    now = now.astimezone(TZ) if now.tzinfo else now.replace(tzinfo=TZ)
    m = re.fullmatch(r"(daily|weekly:(MON|TUE|WED|THU|FRI|SAT|SUN)|monthly:(\d{1,2}))@(\d{2}):(\d{2})", spec)
    if not m:
        raise ValueError(f"bad_schedule:{spec}")
    hh, mm = int(m.group(4)), int(m.group(5))
    base = now.replace(hour=hh, minute=mm, second=0, microsecond=0)
    if m.group(1) == "daily":
        return base if base > now else base + timedelta(days=1)
    if m.group(2):
        target = _DAYS.index(m.group(2))
        delta = (target - now.weekday()) % 7
        cand = base + timedelta(days=delta)
        return cand if cand > now else cand + timedelta(days=7)
    dom = int(m.group(3))
    y, mo = now.year, now.month
    for _ in range(14):
        try:
            cand = base.replace(year=y, month=mo, day=dom)
            if cand > now:
                return cand
        except ValueError:
            pass
        mo += 1
        if mo == 13:
            y, mo = y + 1, 1
    raise ValueError("no_next_run")


def run_forever(jobs: dict[str, tuple[str, Callable[[datetime], object]]], *, sleep=time.sleep, clock=None, max_iterations=None) -> None:
    """jobs: name -> (spec, fn(now))。单线程；一次任务失败不影响其它任务和下一轮。"""
    clock = clock or (lambda: datetime.now(TZ))
    due = {n: next_run(s, clock()) for n, (s, _) in jobs.items()}
    i = 0
    while max_iterations is None or i < max_iterations:
        i += 1
        now = clock()
        for name, (spec, fn) in jobs.items():
            if now >= due[name]:
                try:
                    fn(now)
                except Exception:  # noqa: BLE001 — 任务失败不能拖垮调度；各任务自己写日志
                    pass
                due[name] = next_run(spec, now)
        nxt = min(due.values())
        sleep(max(1.0, min(60.0, (nxt - clock()).total_seconds())))
