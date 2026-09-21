# -*- coding: utf-8 -*-
"""注销账号要删掉该用户在所有存储里的个人数据。

原来 DELETE /api/v1/auth/account 只删核心库；家庭成员（记录库）、饮水记录（产品库）等
约 120 个模块的数据注销后原样留着，接口却回「已删除」。
"""
from __future__ import annotations

import os
import pathlib
import sys

import pytest

BACKEND = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BACKEND))

SECRET = "s" * 48
os.environ.setdefault("APP_ENV", "testing")
os.environ.setdefault("SHUNSHI_JWT_SECRET", SECRET)
os.environ.setdefault("ADMIN_PASSWORD_HASH", "x")
os.environ.setdefault("ADMIN_JWT_SECRET", SECRET)

from fastapi.testclient import TestClient  # noqa: E402


@pytest.fixture()
def client(tmp_path):
    from app.config import Settings
    from app.main import create_app

    app = create_app(Settings(jwt_secret=os.environ["SHUNSHI_JWT_SECRET"], database_url=f"sqlite:///{tmp_path}/c.db"))
    with TestClient(app, raise_server_exceptions=False) as c:
        yield c


def _count_record_store(table: str, column: str, user_id: str) -> int:
    from app.database.db import get_db

    return get_db().execute(f"SELECT count(*) FROM {table} WHERE {column} = ?", (user_id,)).fetchone()[0]


def _count_product_store(table: str, user_id: str) -> int:
    from sqlalchemy import text

    from app.db.database import engine

    with engine.connect() as connection:
        return connection.execute(text(f'SELECT count(*) FROM "{table}" WHERE user_id = :u'), {"u": user_id}).scalar()


def _login(client) -> tuple[str, dict]:
    import jwt

    token = client.post("/api/v1/auth/guest-login", json={"device_id": "d"}).json()["access_token"]
    return jwt.decode(token, options={"verify_signature": False})["sub"], {"Authorization": f"Bearer {token}"}


def test_account_deletion_erases_product_and_record_stores(client):
    user_id, headers = _login(client)
    assert client.post("/api/v1/family/members", json={"name": "外婆", "relation": "grandma", "age": 78}, headers=headers).status_code == 200
    assert client.post("/api/v1/water-tracker/log", json={"amount_ml": 250}, headers=headers).status_code == 200
    assert _count_record_store("family_relations", "user_id", user_id) == 1
    assert _count_record_store("users", "id", user_id) == 1
    assert _count_product_store("sa_water_logs", user_id) == 1

    response = client.delete("/api/v1/auth/account", headers=headers)
    assert response.status_code == 200, response.text
    body = response.json()
    assert body["deleted_record_rows"].get("family_relations") == 1
    assert body["deleted_product_rows"].get("sa_water_logs") == 1
    assert body["erasure_incomplete_tables"] == []

    assert _count_record_store("family_relations", "user_id", user_id) == 0
    assert _count_record_store("users", "id", user_id) == 0
    assert _count_product_store("sa_water_logs", user_id) == 0


def test_other_users_data_is_untouched(client):
    alice, alice_headers = _login(client)
    bob, bob_headers = _login(client)
    client.post("/api/v1/water-tracker/log", json={"amount_ml": 300}, headers=bob_headers)
    client.delete("/api/v1/auth/account", headers=alice_headers)
    assert _count_product_store("sa_water_logs", bob) == 1
    assert _count_record_store("users", "id", bob) == 1


def test_token_stops_working_after_deletion(client):
    _, headers = _login(client)
    assert client.delete("/api/v1/auth/account", headers=headers).status_code == 200
    assert client.post("/api/v1/water-tracker/log", json={"amount_ml": 250}, headers=headers).status_code == 401


def test_export_includes_product_and_record_store_data_without_secrets(client):
    user_id, headers = _login(client)
    client.post("/api/v1/family/members", json={"name": "外婆", "relation": "grandma", "age": 78}, headers=headers)
    client.post("/api/v1/water-tracker/log", json={"amount_ml": 250}, headers=headers)
    body = client.post("/api/v1/auth/data/export", headers=headers).json()
    assert any(r.get("member_name") == "外婆" for r in body["record_store"]["family_relations"])
    assert body["product_store"]["sa_water_logs"][0]["amount_ml"] == 250
    assert all("password_hash" not in r for r in body["record_store"].get("users", []))


def test_export_does_not_include_other_users(client):
    alice, alice_headers = _login(client)
    bob, bob_headers = _login(client)
    client.post("/api/v1/water-tracker/log", json={"amount_ml": 999}, headers=bob_headers)
    body = client.post("/api/v1/auth/data/export", headers=alice_headers).json()
    assert "999" not in str(body.get("product_store"))
