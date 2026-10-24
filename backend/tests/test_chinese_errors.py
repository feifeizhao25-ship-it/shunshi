"""国内版界面全中文：用户不得看到英文原始报错、环境变量名或技术栈名。

带 ``signed_in`` 标记的模块里有上百处 ``HTTPException(detail="xxx not found")`` 之类的英文文案，
还有 ``SHUNSHI_JWT_SECRET``、``Stripe`` 这类运维信息直接放进了 detail。逐处改既改不完、新加的也会再漏，
所以在应用出口统一兜底：英文/技术性文案换成中文通用提示（原文进日志），校验错误与 500 也一样。
"""

import re

import pytest
from fastapi import APIRouter
from fastapi.testclient import TestClient

from app.main import create_app

CJK = re.compile(r"[一-鿿]")
LEAK = re.compile(r"SHUNSHI_|API_KEY|Stripe|Redis|PostgreSQL|SQLite|DeepSeek|SiliconFlow|Traceback|HTTP \d{3}|Error:", re.I)


def _texts(value):
    if isinstance(value, str):
        yield value
    elif isinstance(value, dict):
        for k, v in value.items():
            if k in ("input", "url", "loc", "type"):
                continue
            yield from _texts(v)
    elif isinstance(value, list):
        for v in value:
            yield from _texts(v)


def assert_chinese_only(response):
    for text in _texts(response.json()):
        assert CJK.search(text), f"没有中文的文案：{text!r}"
        assert not LEAK.search(text), f"露出技术信息：{text!r}"


@pytest.fixture()
def app(settings):
    app = create_app(settings)
    extra = APIRouter()

    @extra.get("/__test/english-400")
    def english_400():
        from fastapi import HTTPException
        raise HTTPException(status_code=400, detail="Invalid date format, use YYYY-MM-DD")

    @extra.get("/__test/english-dict")
    def english_dict():
        from fastapi import HTTPException
        raise HTTPException(status_code=503, detail={"detail": "Stripe is not configured", "configured": False})

    @extra.get("/__test/env-name")
    def env_name():
        from fastapi import HTTPException
        raise HTTPException(status_code=503, detail="境内模型未配置（需要 SHUNSHI_DEEPSEEK_API_KEY）")

    @extra.get("/__test/boom")
    def boom():
        raise RuntimeError("HTTP 401 Unauthorized sk-secret")

    app.include_router(extra)
    return app


@pytest.fixture()
def client(app):
    with TestClient(app, raise_server_exceptions=False) as c:
        yield c


def test_english_http_exception_becomes_chinese(client):
    r = client.get("/__test/english-400")
    assert r.status_code == 400
    assert_chinese_only(r)


def test_english_detail_inside_a_dict_is_translated_but_other_keys_survive(client):
    r = client.get("/__test/english-dict")
    assert r.status_code == 503
    assert r.json()["detail"]["configured"] is False
    assert_chinese_only(r)


def test_chinese_text_that_leaks_an_env_var_name_is_replaced(client):
    r = client.get("/__test/env-name")
    assert r.status_code == 503
    assert_chinese_only(r)


def test_unknown_path_and_wrong_method(client):
    for r in (client.get("/api/v1/definitely-not-here"), client.delete("/healthz")):
        assert r.status_code in (404, 405)
        assert_chinese_only(r)


def test_validation_errors_are_chinese(client):
    login = client.post("/api/v1/auth/guest-login")
    headers = {"Authorization": f"Bearer {login.json()['access_token']}"}
    for body in ({}, {"birth_date": "not-a-date"}):
        r = client.post("/api/v1/settings/age-profile", headers=headers, json=body)
        assert r.status_code == 422
        assert isinstance(r.json()["detail"], list)
        assert_chinese_only(r)


def test_unhandled_exception_returns_chinese_json_not_plain_english(client):
    r = client.get("/__test/boom")
    assert r.status_code == 500
    assert r.headers["content-type"].startswith("application/json")
    assert_chinese_only(r)
    assert "sk-secret" not in r.text


def test_real_mounted_modules_do_not_show_english(client):
    """抽几个真实模块里的英文报错（原先 404 的 detail 是 "Acupoint xxx not found"）。"""
    login = client.post("/api/v1/auth/guest-login")
    headers = {"Authorization": f"Bearer {login.json()['access_token']}"}
    for path in ("/api/v1/acupoint/no-such-point", "/api/v1/recipe/no-such-recipe", "/api/v1/gamification/badges/no-such"):
        r = client.get(path, headers=headers)
        if r.status_code >= 400:
            assert_chinese_only(r)


def test_no_chat_config_error_shows_env_var_names(settings, chat_redis_url, monkeypatch):
    settings.redis_url = chat_redis_url
    monkeypatch.delenv("SHUNSHI_DEEPSEEK_API_KEY", raising=False)
    monkeypatch.delenv("SHUNSHI_SILICONFLOW_API_KEY", raising=False)
    monkeypatch.delenv("DEEPSEEK_API_KEY", raising=False)
    monkeypatch.delenv("SILICONFLOW_API_KEY", raising=False)
    with TestClient(create_app(settings), raise_server_exceptions=False) as client:
        login = client.post("/api/v1/auth/guest-login")
        headers = {"Authorization": f"Bearer {login.json()['access_token']}"}
        r = client.post("/api/v1/chat/send", headers=headers, json={"message": "你好"})
    assert r.status_code == 503
    assert r.json()["detail"]["configured"] is False
    assert_chinese_only(r)
