"""24 节气查表（北京时间）。

数据：app/data/solar_terms.json，由 scripts/generate_solar_terms.py 按太阳视黄经每 15° 天文计算生成，
App（android-cn / ios-cn 的 lib/core/solar_term/solar_term_table.dart）用的是同一份表。
后端所有「今天是什么节气」都应走这里，不要再写固定月日表或「每月 X 日换节气」的近似。
"""

from __future__ import annotations

import json
import logging
from bisect import bisect_right
from datetime import date, datetime, timedelta, timezone
from functools import lru_cache
from pathlib import Path
from typing import Optional

logger = logging.getLogger(__name__)

DATA_PATH = Path(__file__).resolve().parent.parent / "data" / "solar_terms.json"
BEIJING = timezone(timedelta(hours=8))

# 公历顺序（小寒在 1 月，冬至在 12 月）
TERM_NAMES = (
    "小寒", "大寒", "立春", "雨水", "惊蛰", "春分", "清明", "谷雨", "立夏", "小满", "芒种", "夏至",
    "小暑", "大暑", "立秋", "处暑", "白露", "秋分", "寒露", "霜降", "立冬", "小雪", "大雪", "冬至",
)


@lru_cache(maxsize=1)
def load_document() -> dict:
    return json.loads(DATA_PATH.read_text(encoding="utf-8"))


@lru_cache(maxsize=1)
def _entries() -> tuple[tuple[date, str], ...]:
    rows = [(date.fromisoformat(item["date"]), item["name"]) for item in load_document()["terms"]]
    rows.sort()
    return tuple(rows)


def covered_years() -> tuple[int, int]:
    first, last = load_document()["years"]
    return int(first), int(last)


def beijing_today() -> date:
    """北京时间的今天：不受服务器时区影响。"""
    return datetime.now(BEIJING).date()


def term_dates(year: int) -> list[dict]:
    """某一年 24 个节气的交节日期（北京时间），按公历顺序。超出表的年份按最近一年的月日近似。"""
    first, last = covered_years()
    if first <= year <= last:
        return [{"name": name, "date": d.isoformat()} for d, name in _entries() if d.year == year]
    nearest = first if year < first else last
    logger.warning("节气表只覆盖 %s–%s 年，%s 年按 %s 年的日期近似", first, last, year, nearest)
    out = []
    for item in term_dates(nearest):
        d = date.fromisoformat(item["date"])
        out.append({"name": item["name"], "date": d.replace(year=year).isoformat(), "approximate": True})
    return out


def _approx_entries(day: date) -> list[tuple[date, str]]:
    rows = []
    for y in (day.year - 1, day.year):
        rows += [(date.fromisoformat(i["date"]), i["name"]) for i in term_dates(y)]
    return sorted(rows)


def term_on(day: Optional[date] = None) -> str:
    """某一天所处的节气名（交节当天即算新节气）。"""
    day = day or beijing_today()
    rows = list(_entries())
    first, last = covered_years()
    if not (rows[0][0] <= day and day.year <= last):
        rows = _approx_entries(day)
    index = bisect_right([d for d, _ in rows], day) - 1
    return rows[index][1]


def season_of(term_name: str) -> str:
    """节气所属季节（立春—谷雨为春，立夏—大暑为夏，立秋—霜降为秋，立冬—大寒为冬）。"""
    seasons = "冬冬春春春春春春夏夏夏夏夏夏秋秋秋秋秋秋冬冬冬冬"
    return seasons[TERM_NAMES.index(term_name)]


def current_term() -> str:
    return term_on(beijing_today())


def next_term(day: Optional[date] = None) -> tuple[str, date]:
    """day 之后（不含当天）的下一个节气及其日期。"""
    day = day or beijing_today()
    rows = list(_entries())
    if day.year >= covered_years()[1]:
        rows = rows + [(date.fromisoformat(i["date"]), i["name"]) for i in term_dates(day.year + 1)]
    for d, name in rows:
        if d > day:
            return name, d
    raise LookupError("节气表没有更晚的日期")


def term_start(day: Optional[date] = None) -> date:
    """day 所处节气的交节日期。"""
    day = day or beijing_today()
    rows = list(_entries())
    if not (rows[0][0] <= day and day.year <= covered_years()[1]):
        rows = _approx_entries(day)
    index = bisect_right([d for d, _ in rows], day) - 1
    return rows[index][0]
