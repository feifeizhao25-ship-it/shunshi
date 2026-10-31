"""未成年人与老年用户：《人工智能拟人化互动服务管理暂行办法》与顺时红线。

- 未成年人（<18）不提供虚拟亲密关系类服务；<14 需监护人同意；
- 老年用户加强健康使用提示；
- 所有人：对话里的 AI 不得自称真人、不扮演恋人或亲人。

年龄来自用户自己在 /api/v1/settings/age-profile 填的出生日期——这是「自报」，
不是实名核验；真正的年龄/监护人核验需要外部资质，见最终报告。
"""

from datetime import date, timedelta

import pytest
from fastapi.testclient import TestClient

from app.main import create_app
from app.routers import chat as chat_module


def _birth(years_ago: int) -> str:
    today = date.today()
    return (today.replace(year=today.year - years_ago) - timedelta(days=30)).isoformat()


@pytest.fixture()
def env(settings, monkeypatch, chat_redis_url):
    settings.redis_url = chat_redis_url
    settings.model_router_url = "http://fake-gateway"
    calls = []

    async def fake_gateway(url, payload, tier=None):
        calls.append(payload)
        return "先从一件今天能完成的小事开始。"

    monkeypatch.setattr(chat_module, "request_gateway", fake_gateway)
    with TestClient(create_app(settings)) as client:
        login = client.post("/api/v1/auth/guest-login")
        headers = {"Authorization": f"Bearer {login.json()['access_token']}"}

        def declare(years_ago):
            return client.post("/api/v1/settings/age-profile", headers=headers, json={"birth_date": _birth(years_ago)})

        def send():
            return client.post("/api/v1/chat/send", headers=headers, json={"message": "今天想早点睡"})

        yield client, headers, declare, send, calls


def _system_text(payload):
    return "\n".join(m["content"] for m in payload["messages"] if m["role"] == "system")


def test_every_user_gets_a_prompt_that_forbids_pretending_to_be_human(env):
    client, headers, declare, send, calls = env
    assert send().status_code == 200
    text = _system_text(calls[-1])
    assert "不是真人" in text and "不扮演恋人" in text


def test_undeclared_age_is_reported_so_the_client_can_ask(env):
    client, headers, declare, send, calls = env
    body = send().json()
    assert body["age_declared"] is False
    assert "minor_mode" not in body or body["minor_mode"] is False
    assert client.get("/api/v1/settings/age-profile", headers=headers).json() == {
        "declared": False, "age_group": "unknown"}


def test_under_16_cannot_chat_even_with_a_guardian(env):
    client, headers, declare, send, calls = env
    assert declare(10).json()["age_group"] == "child"
    response = send()
    assert response.status_code == 403
    assert "监护人" in response.json()["detail"]
    assert calls == []  # 模型一次也没调


def test_16_to_17_chats_in_minor_mode_without_intimate_roleplay(env):
    client, headers, declare, send, calls = env
    assert declare(16).json()["age_group"] == "minor"
    body = send().json()
    assert body["minor_mode"] is True and "未成年" in body["minor_notice"]
    text = _system_text(calls[-1])
    assert "未成年人" in text and "不建立" in text and "亲密关系" in text


def test_seniors_get_a_stronger_health_use_notice(env):
    client, headers, declare, send, calls = env
    assert declare(70).json()["age_group"] == "senior"
    body = send().json()
    assert "不能替代医生" in body["senior_notice"] and "120" in body["senior_notice"]
    assert "老年" in _system_text(calls[-1])


def test_adults_get_neither(env):
    client, headers, declare, send, calls = env
    assert declare(30).json()["age_group"] == "adult"
    body = send().json()
    assert body["age_declared"] is True
    assert not body.get("minor_mode") and not body.get("senior_notice")


def test_a_minor_cannot_simply_re_declare_as_an_adult(env):
    client, headers, declare, send, calls = env
    declare(16)
    again = declare(30)
    assert again.status_code == 409
    assert "客服" in again.json()["detail"]
    assert client.get("/api/v1/settings/age-profile", headers=headers).json()["age_group"] == "minor"


def test_future_birth_date_is_rejected_in_chinese(env):
    client, headers, declare, send, calls = env
    tomorrow = (date.today() + timedelta(days=1)).isoformat()
    response = client.post("/api/v1/settings/age-profile", headers=headers, json={"birth_date": tomorrow})
    assert response.status_code == 422
    assert "出生日期" in str(response.json()["detail"])


def test_15_is_still_blocked_and_16_is_the_minimum_everywhere(env):
    """2026-10-31：最低使用年龄统一 16（所有产品、国内国际）。15 岁拒绝，16 岁进未成年人模式。"""
    from app.router.subscription_local import REGION_COMPLIANCE
    from app.services.age_policy import MIN_AGE
    assert MIN_AGE == 16
    assert {c["age_minimum"] for c in REGION_COMPLIANCE.values()} == {16}
    client, headers, declare, send, calls = env
    assert declare(15).json()["age_group"] == "child"
    assert send().status_code == 403 and calls == []
