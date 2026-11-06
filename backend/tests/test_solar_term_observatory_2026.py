"""2026 节气分钟以紫台（SS-01）和香港天文台（SS-02/SS-03）为准。"""

from datetime import datetime

import pytest

from app.utils import solar_term_publish as pub


def test_two_observatories_agree_to_the_minute_and_embedded_table_follows():
    official = pub.official_minutes()
    zhongqi = pub.zhongqi_minutes()
    assert zhongqi["大寒"] == "2026-01-20 09:45"
    assert zhongqi["雨水"] == "2026-02-18 23:52"
    doc = pub.load_official()
    assert doc["reviewer"] == "" and doc["review_status"] == "待审核"
    assert doc["content_hash"]
    urls = {s["url"] for s in doc["second_sources"]}
    assert "https://www.hko.gov.hk/tc/gts/astron2026/files/2026SolarTerms24.pdf" in urls
    assert "https://www.hko.gov.hk/tc/gts/astronomy/Solar_Term.htm" in urls
    assert "24jieqi" not in json_text()

    from app.utils.solar_term_calendar import load_document

    embedded = {t["name"]: t for t in load_document()["terms"] if t["date"].startswith("2026-")}
    for name, minute in official.items():
        assert embedded[name]["beijing_time"] == pub.published_beijing_time(minute)
        assert embedded[name]["date"] == minute[:10]


def test_truncation_and_half_up_do_not_override_the_observatories():
    dahan = "2026-01-20 09:44:41"
    daxue = "2026-12-07 10:52:17"
    assert pub.truncate_minute(dahan) == "2026-01-20 09:44"
    assert pub.half_up_minute(dahan) == "2026-01-20 09:45"
    assert pub.truncate_minute(daxue) == "2026-12-07 10:52"
    assert pub.half_up_minute(daxue) == "2026-12-07 10:52"
    official = pub.official_minutes()
    assert official["大寒"].endswith("09:45")
    assert official["大雪"].endswith("10:53")
    assert pub.published_beijing_time(official["大寒"]) == "2026-01-20 09:45:00"
    # 大雪的四舍五入分钟与公布分钟不同，仍采用天文台。
    assert not pub.published_beijing_time(official["大雪"]).startswith("2026-12-07 10:52")


def test_enhanced_2026_month_day_matches_the_observatory_date():
    from app.services.solar_term_enhanced import SOLAR_TERMS_2026

    official = pub.official_minutes()
    for term in SOLAR_TERMS_2026:
        moment = datetime.strptime(official[term["name"]], "%Y-%m-%d %H:%M")
        assert (term["month"], term["day"]) == (moment.month, moment.day)


def test_lunar_python_regression_uses_only_solar_term_and_lunar_date():
    fields = pub.solar_lunar_fields_only(2026, 1, 20)
    if fields is None:
        pytest.skip("lunar-python 未安装，离线回归跳过")
    assert set(fields) == set(pub.SOLAR_LUNAR_FIELDS)
    blob = " ".join(str(v) for v in fields.values())
    for forbidden in pub.FORBIDDEN_ALMANAC_FIELDS:
        assert forbidden not in blob
    assert fields["solar_term"] == "大寒"
    assert isinstance(fields["lunar_month"], int) and isinstance(fields["lunar_day"], int)


def json_text() -> str:
    return pub.OFFICIAL_PATH.read_text(encoding="utf-8")
