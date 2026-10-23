"""首页 dashboard：以前固定返回 daily_insight=None、suggestions=[]，首页不随节气、假期、地区、年龄变化。

现在按节气表、国务院 2026 年节假日安排、用户自填的省份和年龄段、目标、最近 7 天行动记录给 3–5 张卡，
每张卡带 reason / basis。日期：2026-10-07（国庆最后一天，秋分）、10-08（节后第一天，寒露交节）、
10-10（周六调休上班）。
"""

import datetime as dt
import json
import time
import uuid

import pytest

from app.services import home_cards
from app.simple_models import UserSetting
from app.utils import cn_calendar


# ── 节假日数据：与国务院通知原文逐条核对（国办发明电〔2025〕7号） ────────────────────
def test_holiday_data_matches_the_state_council_notice():
    doc = json.loads(cn_calendar.DATA_PATH.read_text(encoding="utf-8"))["years"]["2026"]
    assert doc["source_url"].startswith("https://www.gov.cn/")
    assert "国办发明电〔2025〕7号" in doc["source"]
    ranges = {h["name"]: (h["start"], h["end"]) for h in doc["holidays"]}
    assert ranges == {
        "元旦": ("2026-01-01", "2026-01-03"),
        "春节": ("2026-02-15", "2026-02-23"),
        "清明节": ("2026-04-04", "2026-04-06"),
        "劳动节": ("2026-05-01", "2026-05-05"),
        "端午节": ("2026-06-19", "2026-06-21"),
        "中秋节": ("2026-09-25", "2026-09-27"),
        "国庆节": ("2026-10-01", "2026-10-07"),
    }
    makeup = [m["date"] for m in doc["makeup_workdays"]]
    assert makeup == ["2026-01-04", "2026-02-14", "2026-02-28", "2026-05-09", "2026-09-20", "2026-10-10"]
    # 通知原文里的星期：调休上班日都落在周末
    assert all(dt.date.fromisoformat(d).weekday() >= 5 for d in makeup)
    lengths = {name: (dt.date.fromisoformat(b) - dt.date.fromisoformat(a)).days + 1 for name, (a, b) in ranges.items()}
    assert lengths == {"元旦": 3, "春节": 9, "清明节": 3, "劳动节": 5, "端午节": 3, "中秋节": 3, "国庆节": 7}


def test_day_kind():
    d = dt.date
    assert cn_calendar.day_kind(d(2026, 10, 7)) == ("holiday", "国庆节")
    assert cn_calendar.day_kind(d(2026, 10, 8)) == ("workday", None)
    assert cn_calendar.day_kind(d(2026, 10, 10)) == ("makeup_workday", "国庆节")
    assert cn_calendar.day_kind(d(2026, 10, 11)) == ("weekend", None)
    assert cn_calendar.day_kind(d(2027, 10, 1))[0] in ("weekend", "workday")  # 未录入年份不编造
    assert not cn_calendar.covered(d(2027, 1, 1))


# ── 卡片生成 ────────────────────────────────────────────────────────────────
@pytest.fixture()
def session(client):
    s = client.app.state.session_factory()
    yield s
    s.rollback()
    s.close()


def _user(session, **settings):
    user_id = f"home-{uuid.uuid4().hex[:10]}"
    for key, value in settings.items():
        session.merge(UserSetting(user_id=user_id, key=key, value=json.dumps(value, ensure_ascii=False)))
    session.commit()
    return user_id


def _ids(board):
    return [c["id"] for c in board["suggestions"]]


def test_calendar_driven_cards(session):
    uid = _user(session)
    oct7 = home_cards.build_dashboard(session, uid, dt.date(2026, 10, 7))
    assert oct7["solar_term"]["name"] == "秋分"
    assert oct7["suggestions"][0]["title"] == "明天上班，今晚提前半小时睡"
    assert "国庆节" in oct7["suggestions"][0]["reason"]

    oct8 = home_cards.build_dashboard(session, uid, dt.date(2026, 10, 8))
    assert oct8["solar_term"] == {"name": "寒露", "season": "秋", "starts_today": True,
                                  "next": {"name": "霜降", "date": "2026-10-23"}}
    assert _ids(oct8)[:2] == ["day_first_workday", "term"]
    assert "今天寒露交节" in oct8["daily_insight"]["text"]

    oct10 = home_cards.build_dashboard(session, uid, dt.date(2026, 10, 10))
    assert oct10["day_type"]["kind"] == "makeup_workday"
    assert "调休上班" in oct10["suggestions"][0]["title"]
    assert oct10["day_type"]["source"]["source_url"].startswith("https://www.gov.cn/")

    oct14 = home_cards.build_dashboard(session, uid, dt.date(2026, 10, 14))  # 普通工作日、没填任何资料
    assert _ids(oct14) == ["term"]


def test_five_personas_differ_on_the_same_day(session):
    """同一天 5 个画像，至少 3 处可归因的不同（核查报告第 2 / 13 点验收口径）。"""
    now = int(time.time())
    personas = {
        "林晓": _user(session, **{"profile:region": {"province": "上海"}, "profile:onboarding": {"help_goal": "睡个好觉"}}),
        "王桂芳": _user(session, **{"profile:region": {"province": "四川"},
                                  "profile:age": {"birth_date": "1963-05-01", "declared_at": now}}),
        "陈悦": _user(session, **{"profile:region": {"province": "黑龙江"}, "profile:onboarding": {"help_goal": "放松减压"}}),
        "李浩": _user(session, **{"profile:region": {"province": "广东"},
                                "behavior:action_completions": [{"action_type": "breathing", "completed": True, "at": now}] * 5}),
        "张建国": _user(session, **{"profile:region": {"province": "北京"}, "profile:onboarding": {"help_goal": "白天更有精神"}}),
    }
    day = dt.date(2026, 10, 8)
    boards = {name: home_cards.build_dashboard(session, uid, day) for name, uid in personas.items()}
    titles = {name: [c["title"] for c in b["suggestions"]] for name, b in boards.items()}

    assert len({tuple(t) for t in titles.values()}) == 5, titles
    for name, board in boards.items():
        bases = {c["basis"] for c in board["suggestions"]}
        assert {"solar_term", "holiday_calendar", "region"} <= bases, (name, bases)
        assert 3 <= len(board["suggestions"]) <= 5
        assert all(c["reason"] for c in board["suggestions"])
    assert "四川" in str(boards["王桂芳"]) and "60 岁以上" in str(boards["王桂芳"])
    assert "严寒" in str(boards["陈悦"]) or "降温" in str(boards["陈悦"])
    assert "这一周你完成了 5 次" in str(boards["李浩"])


def test_cards_never_recommend_medicine(session):
    from tests.test_no_dosage_in_content import PATENT_MEDICINE

    for tips in home_cards.ZONE_TIPS.values():
        for text in tips.values():
            assert not PATENT_MEDICINE.search(text)
    for text in home_cards.TERM_TIPS.values():
        assert not PATENT_MEDICINE.search(text)
    assert set(home_cards.TERM_TIPS) == set(__import__("app.utils.solar_term_calendar", fromlist=["x"]).TERM_NAMES)


# ── 接口 ────────────────────────────────────────────────────────────────────
def test_region_setting_roundtrip(client, auth_headers):
    assert client.get("/api/v1/settings/region", headers=auth_headers).json()["declared"] is False
    saved = client.post("/api/v1/settings/region", json={"province": "广西壮族自治区"}, headers=auth_headers)
    assert saved.status_code == 200 and saved.json() == {"declared": True, "province": "广西", "zone": "华南"}
    assert client.post("/api/v1/settings/region", json={"province": "火星"}, headers=auth_headers).status_code == 422
    assert client.delete("/api/v1/settings/region", headers=auth_headers).json()["declared"] is False
    assert client.get("/api/v1/settings/region", headers=auth_headers).json()["declared"] is False


def test_dashboard_api_returns_cards(client, auth_headers):
    client.post("/api/v1/settings/region", json={"province": "四川"}, headers=auth_headers)
    data = client.get("/api/v1/seasons/home/dashboard", headers=auth_headers).json()
    assert data["daily_insight"]["text"]
    assert data["suggestions"] and data["gentle_suggestions"] == data["suggestions"]
    assert any(c["basis"] == "region" for c in data["suggestions"])
    for card in data["suggestions"]:
        assert {"id", "title", "reason", "basis", "duration_min"} <= set(card)
