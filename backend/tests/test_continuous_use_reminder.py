"""连续使用满 2 小时，要有温和提醒（《人工智能拟人化互动服务管理暂行办法》）。

「连续」的口径：同一用户相邻两条消息间隔不超过 30 分钟算同一段使用；
这一段从第一条到当前满 2 小时（之后每再满 2 小时）提醒一次，提醒当次的响应里带
``usage_reminder``，并把一句话拼在回答末尾，客户端即使不认这个字段用户也能看到。
"""

import time

import pytest
from fastapi.testclient import TestClient

from app.main import create_app
from app.routers import chat as chat_module
from app.security import verify_token
from app.simple_models import Message

MIN = 60


@pytest.fixture()
def env(settings, monkeypatch, chat_redis_url):
    settings.redis_url = chat_redis_url
    settings.model_router_url = "http://fake-gateway"

    async def fake_gateway(url, payload, tier=None):
        return "先从一件今天能完成的小事开始。"

    monkeypatch.setattr(chat_module, "request_gateway", fake_gateway)
    with TestClient(create_app(settings)) as client:
        login = client.post("/api/v1/auth/guest-login")
        token = login.json()["access_token"]
        user_id = verify_token(settings, token)
        headers = {"Authorization": f"Bearer {token}"}

        def seed(offsets_minutes_ago):
            now = int(time.time())
            with client.app.state.session_factory() as db:
                for ago in offsets_minutes_ago:
                    db.add(Message(user_id=user_id, role="user", content="嗯", created_at=now - ago * MIN))
                db.commit()

        def send():
            return client.post("/api/v1/chat/send", headers=headers, json={"message": "今天想早点睡"}).json()

        yield seed, send


def test_first_message_has_no_reminder(env):
    seed, send = env
    body = send()
    assert body["usage_reminder"] is None


def test_two_hours_of_continuous_use_triggers_a_gentle_reminder(env):
    seed, send = env
    seed([125, 105, 85, 65, 45, 25, 5])  # 每 20 分钟一条，最早一条在 125 分钟前
    body = send()
    reminder = body["usage_reminder"]
    assert reminder and reminder["type"] == "continuous_use"
    assert reminder["continuous_minutes"] >= 120
    assert "2 小时" in reminder["text"]
    assert reminder["text"] in body["content"] and body["content"] == body["message"] == body["text"]


def test_reminder_is_given_once_per_two_hours_not_on_every_message(env):
    seed, send = env
    seed([125, 105, 85, 65, 45, 25, 5])
    assert send()["usage_reminder"] is not None
    assert send()["usage_reminder"] is None


def test_a_long_break_starts_a_new_session(env):
    seed, send = env
    # 3 小时前到 2 小时前聊过，中间隔了一个多小时，这一段只有几分钟
    seed([180, 160, 140, 120, 100, 20, 10])
    assert send()["usage_reminder"] is None


def test_under_two_hours_is_not_reminded(env):
    seed, send = env
    seed([90, 70, 50, 30, 10])
    assert send()["usage_reminder"] is None
