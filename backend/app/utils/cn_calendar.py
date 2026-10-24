"""国内法定节假日与调休（数据：app/data/cn_holidays.json，来源与核对日期写在数据文件里）。"""

from __future__ import annotations

import json
from datetime import date, timedelta
from functools import lru_cache
from pathlib import Path

DATA_PATH = Path(__file__).resolve().parent.parent / "data" / "cn_holidays.json"

HOLIDAY, MAKEUP_WORKDAY, WEEKEND, WORKDAY = "holiday", "makeup_workday", "weekend", "workday"


@lru_cache(maxsize=1)
def _load() -> dict:
    return json.loads(DATA_PATH.read_text(encoding="utf-8"))


@lru_cache(maxsize=1)
def _index() -> tuple[dict, dict]:
    holidays: dict[date, str] = {}
    makeup: dict[date, str] = {}
    for year in _load()["years"].values():
        for item in year["holidays"]:
            day, end = date.fromisoformat(item["start"]), date.fromisoformat(item["end"])
            while day <= end:
                holidays[day] = item["name"]
                day += timedelta(days=1)
        for item in year["makeup_workdays"]:
            makeup[date.fromisoformat(item["date"])] = item["for"]
    return holidays, makeup


def covered(day: date) -> bool:
    return str(day.year) in _load()["years"]


def source_for(day: date) -> dict | None:
    year = _load()["years"].get(str(day.year))
    return {"source": year["source"], "source_url": year["source_url"]} if year else None


def day_kind(day: date) -> tuple[str, str | None]:
    """(类型, 关联节日名)。类型：holiday 放假 / makeup_workday 调休上班 / weekend 周末 / workday 工作日。"""
    holidays, makeup = _index()
    if day in holidays:
        return HOLIDAY, holidays[day]
    if day in makeup:
        return MAKEUP_WORKDAY, makeup[day]
    return (WEEKEND, None) if day.weekday() >= 5 else (WORKDAY, None)


def is_rest_day(day: date) -> bool:
    return day_kind(day)[0] in (HOLIDAY, WEEKEND)
