"""节气日期：查表（天文计算，北京时间），后端各处与 App 用同一张表。

以前后端 today_plan 用固定月日表、solar_terms 用「每月 15 日换节气」近似，
2026-10-01 至 10-07 首页会提前显示寒露（实际 10-08 交节）；Skills、个性化问候、智慧语录又各有一套月日表。
"""

import datetime as dt
import importlib.util
import json
import pathlib
import re

import pytest

from app.utils import solar_term_calendar as cal

BACKEND = pathlib.Path(__file__).resolve().parent.parent
REPO = BACKEND.parent
DART_TABLES = [
    REPO / "android-cn" / "lib" / "core" / "solar_term" / "solar_term_table.dart",
    REPO / "ios-cn" / "lib" / "core" / "solar_term" / "solar_term_table.dart",
]

# 公开的 2026 年历（国家授时中心 / 紫金山天文台口径）中容易核对的几个日期
KNOWN = {
    "2026-02-04": "立春",
    "2026-03-20": "春分",
    "2026-06-21": "夏至",
    "2026-09-23": "秋分",
    "2026-10-08": "寒露",
    "2026-10-23": "霜降",
    "2026-12-22": "冬至",
    "2024-03-20": "春分",
    "2025-02-03": "立春",
}


def _terms():
    return cal.load_document()["terms"]


def test_table_covers_2024_to_2035_in_order():
    terms = _terms()
    assert cal.covered_years() == (2024, 2035)
    assert terms[0]["name"] == "冬至" and terms[0]["date"].startswith("2023-12")
    for year in range(2024, 2036):
        names = [t["name"] for t in terms if t["date"].startswith(f"{year}-")]
        assert tuple(names) == cal.TERM_NAMES, year
    dates = [t["date"] for t in terms]
    assert dates == sorted(dates) and len(set(dates)) == len(dates)
    gaps = [(dt.date.fromisoformat(b) - dt.date.fromisoformat(a)).days for a, b in zip(dates, dates[1:])]
    assert min(gaps) >= 13 and max(gaps) <= 17
    for t in terms:  # 交节时刻与日期一致，经度每 15° 一个
        assert t["beijing_time"].startswith(t["date"]) and t["longitude"] % 15 == 0


def test_known_dates():
    by_date = {t["date"]: t["name"] for t in _terms()}
    for day, name in KNOWN.items():
        assert by_date.get(day) == name, (day, name)


def _expected_2026():
    starts = [(dt.date.fromisoformat(t["date"]), t["name"]) for t in _terms()]
    expected = {}
    day = dt.date(2026, 1, 1)
    while day.year == 2026:
        expected[day] = [name for d, name in starts if d <= day][-1]
        day += dt.timedelta(days=1)
    return expected


def test_every_day_of_2026():
    expected = _expected_2026()
    assert len(expected) == 365
    for day, name in expected.items():
        assert cal.term_on(day) == name, day
    assert cal.term_on(dt.date(2026, 10, 7)) == "秋分"
    assert cal.term_on(dt.date(2026, 10, 8)) == "寒露"
    assert cal.term_on(dt.date(2026, 10, 22)) == "寒露"
    assert cal.term_on(dt.date(2026, 10, 23)) == "霜降"
    assert cal.term_on(dt.date(2026, 1, 4)) == "冬至"  # 2025-12-21 冬至，小寒 2026-01-05


def test_next_term_and_out_of_range_fallback():
    assert cal.next_term(dt.date(2026, 10, 7)) == ("寒露", dt.date(2026, 10, 8))
    assert cal.next_term(dt.date(2035, 12, 30))[0] == "小寒"
    assert cal.term_on(dt.date(2036, 10, 15)) in ("寒露",)  # 超出范围按 2035 月日近似
    assert len(cal.term_dates(2026)) == 24


@pytest.fixture()
def every_day_2026(monkeypatch):
    """逐日把「北京时间今天」换成 2026 的每一天。"""
    expected = _expected_2026()

    def run(check):
        for day, name in expected.items():
            monkeypatch.setattr(cal, "beijing_today", lambda d=day: d)
            check(day, name)

    return run


def test_today_plan_uses_table_every_day(every_day_2026):
    from app.router import today_plan

    def check(day, name):
        current = today_plan.get_current_solar_term()
        assert current["name"] == name and current["date"] == day.isoformat(), day

    every_day_2026(check)


def test_solar_terms_router_uses_table_every_day(every_day_2026):
    from app.router import solar_terms

    every_day_2026(lambda day, name: (solar_terms.get_current_solar_term()["name"] == name) or pytest.fail(str(day)))


def test_other_backend_term_helpers_use_table_every_day(every_day_2026):
    from app.rag import personalizer
    from app.router import wisdom
    from app.skills.core_skills import CoreSkillExecutor

    engine = CoreSkillExecutor.__new__(CoreSkillExecutor)

    def check(day, name):
        assert engine._get_current_solar_term() == name, ("core_skills", day)
        assert personalizer._get_current_solar_term_cn()[0] == name, ("personalizer", day)
        assert wisdom._get_solar_term() == name, ("wisdom", day)

    every_day_2026(check)


def test_schedule_endpoint_returns_real_dates_for_the_year():
    from fastapi import FastAPI
    from fastapi.testclient import TestClient

    from app.router.solar_terms import router

    app = FastAPI()
    app.include_router(router)
    rows = TestClient(app).get("/api/v1/solar-terms/schedule", params={"year": 2027}).json()["data"]
    by_name = {r["name"]: r["date"] for r in rows}
    table = {t["name"]: t["date"] for t in _terms() if t["date"].startswith("2027-")}
    assert by_name == table


def test_app_tables_are_generated_from_the_same_json():
    expected = [(t["date"], t["name"]) for t in _terms()]
    for path in DART_TABLES:
        if not path.parent.parent.parent.exists():
            pytest.skip(f"{path} 所在客户端不在本仓库")
        got = re.findall(r"SolarTermDate\('(\d{4}-\d{2}-\d{2})', '(\S+?)'\)", path.read_text(encoding="utf-8"))
        assert got == expected, f"{path} 与 app/data/solar_terms.json 不一致，请重新运行 scripts/generate_solar_terms.py"


def test_recompute_2026_with_ephem_when_available():
    pytest.importorskip("ephem")
    spec = importlib.util.spec_from_file_location("gen_solar_terms", BACKEND / "scripts" / "generate_solar_terms.py")
    gen = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(gen)
    fresh = [(t["date"], t["name"]) for t in gen.compute(2026, 2026)]
    stored = [(t["date"], t["name"]) for t in _terms() if t["date"] >= "2025-12-15" and t["date"] <= "2026-12-31"]
    assert fresh == stored
