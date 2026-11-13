"""2026 年 24 节气与紫台公布分钟一致，lunar-python 只核对时刻，相差不超过 1 分钟。"""

from pathlib import Path

import pytest

from app.utils import solar_term_crosscheck as cross
from app.utils.solar_term_publish import official_minutes

TABLE = Path(__file__).resolve().parents[1] / "app" / "data" / "solar_terms.json"
PMO = Path(__file__).resolve().parents[1] / "app" / "self_improve" / "data" / "solar_terms_pmo_2026.json"


def test_all_24_terms_in_2026_match_within_one_minute_and_minutes_stay_published():
    before_table = TABLE.read_bytes()
    before_pmo = PMO.read_bytes()
    official = official_minutes()
    report = cross.crosscheck_2026()
    assert report["ok"] is True and report["blocked"] is False
    assert report["n"] == 24
    assert report["max_delta_seconds"] <= 60
    assert report["fields"] == "jieqi_time"
    lunar = cross.lunar_term_times(2026)
    assert set(lunar) == set(official)
    for name, minute in official.items():
        delta = abs((lunar[name] - __import__("datetime").datetime.strptime(minute, "%Y-%m-%d %H:%M")).total_seconds())
        assert delta <= 60, (name, minute, lunar[name], delta)
    assert TABLE.read_bytes() == before_table
    assert PMO.read_bytes() == before_pmo
    text = TABLE.read_text(encoding="utf-8")
    assert "2026-01-20 09:45:00" in text
    assert "2026-12-07 10:53:00" in text


def test_an_altered_term_is_blocked_and_the_published_table_is_not_rewritten():
    before = TABLE.read_bytes()
    published = cross.published_minutes_2026()
    altered = dict(published)
    altered["立春"] = "2026-02-04 05:02"
    with pytest.raises(cross.SolarTermBlocked) as caught:
        cross.crosscheck_2026(altered)
    assert any(item.startswith("published:立春") for item in caught.value.problems)
    assert TABLE.read_bytes() == before
    assert "2026-02-04 04:02:00" in TABLE.read_text(encoding="utf-8")


def test_crosscheck_reads_term_times_only():
    source = Path(cross.__file__).read_text(encoding="utf-8").split('"""', 2)[-1]
    for banned in ("getDayYi", "getDayJi", "getTimeYi", "getTimeJi", "getEightChar", "宜忌", "吉凶"):
        assert banned not in source
    assert "getJieQiTable" in source
