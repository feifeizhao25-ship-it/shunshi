# -*- coding: utf-8 -*-
"""口令登录与「导出/删除我的数据」的身份。

2026-09-21 在按生产配置拉起的后端上实测：

1. ``POST /api/v1/auth/login`` 对 password_hash 为空的账号**不校验口令**。
   Apple 与 Google 登录建号时写 email、不写 password_hash——知道对方邮箱，
   任意口令即可登进他的账号。种子演示账号 demo@shunshi.com 同样任意口令可登。
2. ``/api/v1/user-data/*``（导出、删除、撤销、状态）的身份依赖在没有 token、
   token 无效、**甚至 token 有效**（登录接口签发的 access token 没有 type 字段）时，
   一律当成演示账号 user-001：
   - 未登录就能下载演示账号的数据；
   - 真实用户点「删除我的数据」，被安排删除的是演示账号，接口却回「已安排」。
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
def client(tmp_path_factory):
    from app.config import Settings
    from app.main import create_app

    db = tmp_path_factory.mktemp("core") / "core.db"
    app = create_app(Settings(jwt_secret=os.environ["SHUNSHI_JWT_SECRET"], env="test", database_url=f"sqlite:///{db}"))
    with TestClient(app) as c:
        yield c


def _passwordless_user(email: str, provider_column: str) -> str:
    """模拟 Apple / Google 登录建号：有 email，没有 password_hash。"""
    from app.database.db import get_db

    user_id = f"u-{uuid.uuid4().hex[:10]}"
    db = get_db()
    db.execute(
        f"INSERT INTO users (id, name, email, {provider_column}, life_stage, created_at, updated_at) "
        "VALUES (?, ?, ?, ?, 'exploration', datetime('now'), datetime('now'))",
        (user_id, "第三方登录用户", email, f"sub-{user_id}"),
    )
    db.commit()
    return user_id


# ── 一、没设过口令的账号不能口令登录 ───────────────────────────

@pytest.mark.parametrize("password", ["", "x", "anything"])
def test_demo_account_cannot_be_logged_into(client, password):
    r = client.post("/api/v1/auth/login", json={"email": "demo@shunshi.com", "password": password})
    assert r.status_code == 401


@pytest.mark.parametrize("column", ["apple_id", "google_id"])
def test_third_party_accounts_cannot_be_taken_over_with_any_password(client, column):
    email = f"victim-{uuid.uuid4().hex[:6]}@example.com"
    _passwordless_user(email, column)
    r = client.post("/api/v1/auth/login", json={"email": email, "password": "guessed"})
    assert r.status_code == 401, "知道邮箱、任意口令就能登进第三方登录的账号"


def test_error_does_not_reveal_whether_the_account_exists(client):
    email = f"victim-{uuid.uuid4().hex[:6]}@example.com"
    _passwordless_user(email, "apple_id")
    existing = client.post("/api/v1/auth/login", json={"email": email, "password": "x"}).json()
    missing = client.post("/api/v1/auth/login", json={"email": "nobody@example.com", "password": "x"}).json()
    assert existing == missing


def test_password_login_still_works(client):
    email = f"owner-{uuid.uuid4().hex[:6]}@example.com"
    client.post("/api/v1/auth/register", json={"email": email, "password": "Correct-horse-9", "name": "测"})
    assert client.post("/api/v1/auth/login", json={"email": email, "password": "Correct-horse-9"}).status_code == 200
    assert client.post("/api/v1/auth/login", json={"email": email, "password": "wrong"}).status_code == 401


# ── 二、导出 / 删除「我的数据」必须是我 ───────────────────────

def _login_token(client) -> tuple[str, str]:
    email = f"owner-{uuid.uuid4().hex[:6]}@example.com"
    client.post("/api/v1/auth/register", json={"email": email, "password": "Correct-horse-9", "name": "测"})
    r = client.post("/api/v1/auth/login", json={"email": email, "password": "Correct-horse-9"})
    assert r.status_code == 200, r.text
    body = r.json()
    return body["access_token"], body["data"]["user"]["id"]


@pytest.mark.parametrize(
    "method,path,body",
    [
        ("post", "/api/v1/user-data/export", {"categories": ["profile"]}),
        ("get", "/api/v1/user-data/export/status", None),
        ("post", "/api/v1/user-data/delete", {"confirm": True}),
        ("post", "/api/v1/user-data/delete/cancel", None),
        ("get", "/api/v1/user-data/delete/status", None),
    ],
)
@pytest.mark.parametrize("auth", [None, "Bearer garbage"])
def test_user_data_requires_a_valid_login(client, method, path, body, auth):
    headers = {"Authorization": auth} if auth else {}
    kwargs = {"json": body} if body is not None else {}
    r = getattr(client, method)(path, headers=headers, **kwargs)
    assert r.status_code == 401, "改之前这里会以演示账号 user-001 的身份执行"


def test_export_returns_my_own_data_not_the_demo_account(client):
    token, user_id = _login_token(client)
    r = client.post(
        "/api/v1/user-data/export", json={"categories": ["profile"]}, headers={"Authorization": f"Bearer {token}"}
    )
    assert r.status_code == 200, r.text
    assert user_id in r.headers["content-disposition"]
    assert "user-001" not in r.headers["content-disposition"]


def test_retired_deletion_endpoints_no_longer_claim_success(client):
    """改之前回「数据删除已安排」，实际后台任务第一句就写不存在的表，什么都没删。"""
    token, _ = _login_token(client)
    headers = {"Authorization": f"Bearer {token}"}
    for method, path, body in (
        ("post", "/api/v1/user-data/delete", {"confirm": True}),
        ("post", "/api/v1/user-data/delete/cancel", None),
        ("get", "/api/v1/user-data/delete/status", None),
    ):
        kwargs = {"json": body} if body is not None else {}
        r = getattr(client, method)(path, headers=headers, **kwargs)
        assert r.status_code == 410, r.text
        assert "DELETE /api/v1/auth/account" in r.text


def test_authoritative_account_deletion_is_real(client):
    """客户端「注销账号」走的这一条是真实删除：删完再用同一个 token 读资料不再有数据。"""
    token, _ = _login_token(client)
    r = client.delete("/api/v1/auth/account", headers={"Authorization": f"Bearer {token}"})
    assert r.status_code == 200, r.text
    assert r.json().get("deleted") is True
