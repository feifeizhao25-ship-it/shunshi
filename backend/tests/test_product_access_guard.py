# -*- coding: utf-8 -*-
"""产品路由统一门禁（app/product_access.py）。

2026-09-21 把自动挂载的每一条产品路由都不带 token 调了一遍：370 条 200、209 条 422。
这里挑有代表性的几类固定下来：导出任意用户、后台接口、以官方名义推送、发券、
「user_id 默认 user-001」导致所有用户共用一份数据，以及国际版模块混在国内版里。
"""
from __future__ import annotations

import os
import pathlib
import sys
import uuid

import pytest

BACKEND = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BACKEND))

SECRET = "s" * 48
os.environ.setdefault("APP_ENV", "testing")
os.environ.setdefault("SHUNSHI_JWT_SECRET", SECRET)
os.environ.setdefault("ADMIN_PASSWORD_HASH", "x")
os.environ.setdefault("ADMIN_JWT_SECRET", SECRET)

from fastapi.testclient import TestClient  # noqa: E402


@pytest.fixture(scope="module")
def ctx(tmp_path_factory):
    from app.config import Settings
    from app.main import create_app
    from app.security import issue_token

    tmp = tmp_path_factory.mktemp("guard")
    settings = Settings(jwt_secret=os.environ["SHUNSHI_JWT_SECRET"], database_url=f"sqlite:///{tmp}/core.db")
    app = create_app(settings)

    def bearer(user_id: str) -> dict:
        return {"Authorization": "Bearer " + issue_token(settings, user_id)["access_token"]}

    from app.router import admin_auth

    admin_token = "adm-" + uuid.uuid4().hex
    admin_auth._active_tokens[admin_token] = {"username": "ops", "expires_at": None}
    with TestClient(app, raise_server_exceptions=False) as client:
        yield client, bearer, {"X-Admin-Token": admin_token}
    admin_auth._active_tokens.pop(admin_token, None)


def _ids():
    return "u-" + uuid.uuid4().hex[:10], "u-" + uuid.uuid4().hex[:10]


# ── 任意用户导出 ───────────────────────────────────────────────


def test_export_of_any_user_requires_login_and_ownership(ctx):
    client, bearer, _ = ctx
    alice, bob = _ids()
    assert client.get(f"/api/v1/users/{bob}/export").status_code == 401
    assert client.get(f"/api/v1/users/{bob}/export", headers=bearer(alice)).status_code == 403
    assert client.get(f"/api/v1/users/{alice}/export", headers=bearer(alice)).status_code not in (401, 403)


def test_delete_of_another_user_is_refused(ctx):
    client, bearer, _ = ctx
    alice, bob = _ids()
    assert client.delete(f"/api/v1/users/{bob}").status_code == 401
    assert client.delete(f"/api/v1/users/{bob}", headers=bearer(alice)).status_code == 403


# ── 后台与运营接口 ─────────────────────────────────────────────


@pytest.mark.parametrize(
    "method,path",
    [
        ("GET", "/api/v1/admin/dashboard"),
        ("GET", "/api/v1/admin/audit/recent"),
        ("GET", "/api/v1/admin/config/ai-models"),
        ("POST", "/api/v1/notifications/broadcast"),
        ("POST", "/api/v1/notifications/scheduler/stop"),
        ("POST", "/api/v1/coupon/issue"),
        ("POST", "/api/v1/gamification/award"),
        ("POST", "/api/v1/gifting/gift-cards/create"),
        ("POST", "/api/v1/cms/content"),
        ("GET", "/api/v1/feedback/admin/list"),
        ("GET", "/api/v1/followup/due"),
        ("GET", "/api/v1/subscription/check-expiry"),
    ],
)
def test_operator_endpoints_need_admin(ctx, method, path):
    client, bearer, admin = ctx
    alice, _ = _ids()
    assert client.request(method, path, json={}).status_code == 401
    assert client.request(method, path, json={}, headers=bearer(alice)).status_code == 403
    assert client.request(method, path, json={}, headers=admin).status_code not in (401, 403)


def test_admin_login_stays_public(ctx):
    client, _, _ = ctx
    response = client.post("/api/v1/admin/auth/login", json={"username": "x", "password": "y"})
    assert response.status_code not in (403,)
    assert response.status_code != 401 or "Missing admin token" not in response.text


# ── user_id 当身份 ─────────────────────────────────────────────


def test_family_data_is_per_user_not_shared_via_demo_default(ctx):
    """原来不传 user_id 就落到 user-001：所有用户共用一份家庭成员。"""
    client, bearer, _ = ctx
    alice, bob = _ids()
    added = client.post(
        "/api/v1/family/members",
        json={"name": "外婆", "relation": "grandma", "age": 78},
        headers=bearer(alice),
    )
    assert added.status_code == 200, added.text

    mine = client.get("/api/v1/family/members", headers=bearer(alice)).json()
    theirs = client.get("/api/v1/family/members", headers=bearer(bob)).json()
    assert "外婆" in str(mine)
    assert "外婆" not in str(theirs)


def test_query_user_id_of_someone_else_is_refused(ctx):
    client, bearer, _ = ctx
    alice, bob = _ids()
    assert client.get(f"/api/v1/family/members?user_id={alice}").status_code == 401
    assert client.get(f"/api/v1/family/members?user_id={alice}", headers=bearer(bob)).status_code == 403


def test_body_user_id_of_someone_else_is_refused(ctx):
    client, bearer, _ = ctx
    alice, bob = _ids()
    response = client.post(
        "/api/v1/coupon/redeem",
        json={"user_id": bob, "coupon_code": "SSX"},
        headers=bearer(alice),
    )
    assert response.status_code == 403


def test_path_user_id_of_someone_else_is_refused_on_reads(ctx):
    client, bearer, _ = ctx
    alice, bob = _ids()
    assert client.get(f"/api/v1/analytics/summary/{bob}").status_code == 401
    assert client.get(f"/api/v1/analytics/summary/{bob}", headers=bearer(alice)).status_code == 403


def test_writes_without_user_id_still_need_login(ctx):
    client, _, _ = ctx
    assert client.post("/api/v1/speech/tts", json={"text": "你好"}).status_code == 401
    assert client.post("/api/v1/food-therapy/recommend", json={}).status_code == 401


def test_refresh_token_is_not_a_pass(ctx):
    import jwt

    client, _, _ = ctx
    alice, _ = _ids()
    token = jwt.encode({"sub": alice, "type": "refresh"}, os.environ["SHUNSHI_JWT_SECRET"], algorithm="HS256")
    response = client.get(f"/api/v1/users/{alice}/export", headers={"Authorization": f"Bearer {token}"})
    assert response.status_code == 401


# ── 公开内容与登录不受影响 ───────────────────────────────────────


@pytest.mark.parametrize(
    "path",
    ["/api/v1/solar-terms/current", "/api/v1/tea/daily", "/api/v1/acupoints/daily", "/api/v1/skills"],
)
def test_public_catalogue_stays_public(ctx, path):
    client, _, _ = ctx
    assert client.get(path).status_code == 200


def test_login_endpoints_are_not_gated(ctx):
    client, _, _ = ctx
    assert client.post("/api/v1/auth/login", json={"email": "no@one.cn", "password": "x"}).status_code == 401
    assert client.post("/api/v1/auth/guest-login", json={}).status_code == 200


# ── 国际版模块不在国内版里 ───────────────────────────────────────


@pytest.mark.parametrize(
    "method,path",
    [
        ("GET", "/api/v1/stripe/config"),
        ("GET", "/api/v1/stripe/plans"),
        ("GET", "/api/v1/seasons/subscription/products"),
        ("POST", "/api/v1/seasons/user/someone/export"),
        ("DELETE", "/api/v1/seasons/user/someone"),
        ("POST", "/ai/daily-insight"),
    ],
)
def test_international_modules_are_not_mounted(ctx, method, path):
    client, _, _ = ctx
    assert client.request(method, path).status_code in (404, 405)


def test_legacy_ai_chat_path_goes_to_domestic_chat(ctx, monkeypatch):
    """国内客户端对话页调 POST /ai/chat；原来接住它的是国际版英文人设、不登录可用。"""
    client, bearer, _ = ctx
    assert client.post("/ai/chat", json={"message": "睡不好"}).status_code == 401

    from app.llm import domestic_gateway as gw
    from app.services import chat_quota

    async def fake_reserve(url, user_id, tier):
        return ("k", "t")

    async def fake_refund(url, reservation):
        return None

    async def fake_complete(messages, tier="free", **_):
        assert "SEASONS" not in messages[0]["content"]
        assert "顺时" in messages[0]["content"]
        return "早点休息。"

    monkeypatch.setattr(chat_quota, "reserve", fake_reserve)
    monkeypatch.setattr(chat_quota, "refund", fake_refund)
    monkeypatch.setattr(gw, "complete", fake_complete)
    alice, _ = _ids()
    response = client.post("/ai/chat", json={"message": "睡不好", "solar_term": "白露"}, headers=bearer(alice))
    assert response.status_code == 200, response.text
    assert response.json()["text"].startswith("早点休息")
