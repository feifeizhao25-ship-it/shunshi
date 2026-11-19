"""注册来源题「从哪知道我们」：默认关闭、只存枚举、不和身份信息一起输出。"""

import logging
import time
import uuid

import pytest
from sqlalchemy import inspect

from app.config import Settings
from app.growth.models import GrowthEvent, GrowthSignupSource
from app.growth.signup_source import SIGNUP_SOURCES, normalize
from app.security import issue_token
from app.routers.user import _mirror_to_record_store
from app.simple_models import User

EXPECTED_LABELS = ["小红书", "抖音", "视频号", "公众号", "知乎", "哔哩哔哩", "搜索", "朋友推荐", "其他"]
# 记录库在整个 pytest 进程里共用，号码每次随机，免得和别的用例（如 test_user 的注册）撞号。
PHONE = "199" + f"{uuid.uuid4().int % 10**8:08d}"


def _phone():
    return "198" + f"{uuid.uuid4().int % 10**8:08d}"


def _user(client, *, phone=None, guest=False, age_seconds=0):
    phone = phone or _phone()
    session = client.app.state.session_factory()
    user = User(phone=None if guest else phone, is_guest=guest, nickname="测试昵称")
    user.created_at = int(time.time()) - age_seconds
    session.add(user)
    session.commit()
    user_id = user.id
    session.close()
    # 真实注册（短信验证、密码注册、游客登录）都会同步写一份到记录库，门禁据此核验账号。
    _mirror_to_record_store(user_id, phone=None if guest else phone, nickname="测试昵称")
    token = issue_token(client.app.state.settings, user_id)["access_token"]
    return user_id, {"Authorization": f"Bearer {token}"}


def _rows(client):
    session = client.app.state.session_factory()
    try:
        return [(r.event_id, r.source) for r in session.query(GrowthSignupSource).all()]
    finally:
        session.close()


def _enable(client):
    client.app.state.settings.growth_signup_source_enabled = True


def test_flag_defaults_off():
    assert Settings.model_fields["growth_signup_source_enabled"].default is False


def test_options_are_exactly_the_nine_choices():
    assert [label for _, label in SIGNUP_SOURCES] == EXPECTED_LABELS
    assert len({code for code, _ in SIGNUP_SOURCES}) == 9


def test_normalize_drops_unknown_and_free_text():
    assert normalize("douyin") == "douyin"
    for bad in ("", "抖音", "Douyin", "douyin ", "我在地铁广告看到的", None, 3, ["zhihu"]):
        assert normalize(bad) == ""


def test_flag_off_hides_question_and_drops_answers(client):
    body = client.get("/api/v1/growth/signup-source").json()["data"]
    assert body == {"enabled": False, "options": []}

    user_id, headers = _user(client)
    posted = client.post("/api/v1/growth/signup-source", headers=headers, json={"source": "zhihu"})
    assert posted.status_code == 200
    assert posted.json()["data"] == {"recorded": False}
    event = client.post(
        "/api/v1/growth/events",
        headers=headers,
        json={"event_type": "signup", "user_id": user_id, "signup_source": "zhihu"},
    )
    assert event.status_code == 200
    assert _rows(client) == []


def test_flag_on_lists_options_in_order(client):
    _enable(client)
    body = client.get("/api/v1/growth/signup-source").json()["data"]
    assert body["enabled"] is True
    assert body["skippable"] is True
    assert body["question"] == "从哪知道我们"
    assert [o["label"] for o in body["options"]] == EXPECTED_LABELS


def test_answer_recorded_once_and_never_echoed_with_identity(client, caplog):
    _enable(client)
    user_id, headers = _user(client, phone=PHONE)
    with caplog.at_level(logging.DEBUG):
        first = client.post(
            "/api/v1/growth/signup-source", headers=headers, json={"source": "xiaohongshu"}
        )
        again = client.post(
            "/api/v1/growth/signup-source", headers=headers, json={"source": "douyin"}
        )
    assert first.status_code == 200
    assert first.json() == {"success": True, "data": {"recorded": True}}
    assert again.json()["data"] == {"recorded": False}
    for response in (first, again):
        text = response.text
        assert PHONE not in text and "测试昵称" not in text and user_id not in text
    for record in caplog.records:
        message = record.getMessage()
        assert "xiaohongshu" not in message and "小红书" not in message

    rows = _rows(client)
    assert len(rows) == 1 and rows[0][1] == "xiaohongshu"
    session = client.app.state.session_factory()
    event = session.get(GrowthEvent, rows[0][0])
    assert event.event_type == "signup" and event.user_id == user_id
    session.close()


def test_unknown_or_free_text_is_dropped(client):
    _enable(client)
    _, headers = _user(client)
    for bad in ("抖音", "tv-ad", "我在电梯广告里看到"):
        posted = client.post("/api/v1/growth/signup-source", headers=headers, json={"source": bad})
        assert posted.status_code == 200
        assert posted.json()["data"] == {"recorded": False}
    extra = client.post(
        "/api/v1/growth/signup-source",
        headers=headers,
        json={"source": "", "note": "自由文本不收"},
    )
    assert extra.json()["data"] == {"recorded": False}
    assert _rows(client) == []


def test_guest_and_old_accounts_are_not_counted(client):
    _enable(client)
    _, guest_headers = _user(client, guest=True)
    _, old_headers = _user(client, phone=_phone(), age_seconds=4 * 24 * 3600)
    for headers in (guest_headers, old_headers):
        posted = client.post("/api/v1/growth/signup-source", headers=headers, json={"source": "zhihu"})
        assert posted.json()["data"] == {"recorded": False}
    assert _rows(client) == []


def test_requires_login(anonymous_client):
    anonymous_client.app.state.settings.growth_signup_source_enabled = True
    posted = anonymous_client.post("/api/v1/growth/signup-source", json={"source": "zhihu"})
    assert posted.status_code == 401


def test_signup_event_carries_source_without_echoing_it(client):
    _enable(client)
    user_id, headers = _user(client)
    event = client.post(
        "/api/v1/growth/events",
        headers=headers,
        json={"event_type": "signup", "user_id": user_id, "signup_source": "bilibili"},
    )
    assert event.status_code == 200
    data = event.json()["data"]
    assert set(data) == {"id", "event_type", "inviter_user_id"}
    assert "bilibili" not in event.text
    assert _rows(client) == [(data["id"], "bilibili")]

    # 非 signup 事件上的来源、未知值都丢弃。
    client.post("/api/v1/growth/events", json={"event_type": "landing_view", "signup_source": "zhihu"})
    client.post(
        "/api/v1/growth/events",
        headers=headers,
        json={"event_type": "signup", "user_id": user_id, "signup_source": "电视"},
    )
    assert _rows(client) == [(data["id"], "bilibili")]


def test_table_holds_no_identity_columns(client):
    engine = client.app.state.session_factory.kw["bind"]
    columns = {c["name"] for c in inspect(engine).get_columns("growth_signup_source")}
    assert columns == {"event_id", "source", "created_at"}


@pytest.mark.admin_signed_in
def test_admin_funnel_reports_only_aggregate_counts(client):
    _enable(client)
    session = client.app.state.session_factory()
    users = []
    for phone in ("13700000001", "13700000002", "13700000003"):
        user = User(phone=phone)
        session.add(user)
        session.flush()
        users.append(user.id)
    session.commit()
    session.close()
    for user_id, source in zip(users, ("zhihu", "zhihu", None)):
        token = issue_token(client.app.state.settings, user_id)["access_token"]
        payload = {"event_type": "signup", "user_id": user_id}
        if source:
            payload["signup_source"] = source
        assert client.post(
            "/api/v1/growth/events", headers={"Authorization": f"Bearer {token}"}, json=payload
        ).status_code == 200

    funnel = client.get("/api/v1/admin/growth/funnel")
    assert funnel.status_code == 200
    sources = funnel.json()["data"]["signup_sources"]
    assert sources["zhihu"] == 2
    assert sources["unanswered"] == 1
    assert sum(sources.values()) == 3
    for user_id in users:
        assert user_id not in funnel.text
    assert "1370000000" not in funnel.text
