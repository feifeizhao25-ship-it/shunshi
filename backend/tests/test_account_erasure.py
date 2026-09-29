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


# ─── 2026-09-29：注销漏掉的与误删的 ───
#
# 1. 产品库 users 行被 DELETE，而 sa_subscription_orders（付款记录，依法保留）对它有
#    ON DELETE CASCADE 外键——订单连带被删，接口却照样回「保留了 1 条订单」。
#    此前的测试跑在没开外键的 SQLite 上，永远看不到级联。
# 2. 家庭成员（owner_id / member_id）、家庭关系（inviter_id / invitee_id）、
#    家庭邀请（created_by）列名不叫 user_id，按 user_id 找不到；
#    核心库的验证码表以手机号为键；别人家庭席位里的 member_user_id 指向本人。


@pytest.fixture()
def product_engine_with_foreign_keys():
    """给产品库引擎打开 SQLite 外键——生产在 PostgreSQL 上，外键与级联本来就是开着的。"""
    from sqlalchemy import event

    from app.db.database import engine, init_db

    def _on(dbapi_connection, _record):
        dbapi_connection.execute("PRAGMA foreign_keys=ON")

    init_db()
    event.listen(engine, "connect", _on)
    engine.dispose()
    try:
        yield engine
    finally:
        event.remove(engine, "connect", _on)
        engine.dispose()


def _seed_product_user(engine, phone: str):
    import uuid

    from sqlalchemy import text

    uid = str(uuid.uuid4())
    with engine.begin() as c:
        c.execute(text("INSERT INTO users (id, phone, email, nickname) VALUES (:i, :p, :e, :n)"),
                  {"i": uid, "p": phone, "e": f"{phone}@x.cn", "n": f"昵称-{phone}"})
    return uid


def test_product_store_users_row_is_anonymized_so_retained_orders_survive(product_engine_with_foreign_keys):
    import uuid

    from sqlalchemy import text

    from app.services.account_erasure import erase_product_store

    engine = product_engine_with_foreign_keys
    me = _seed_product_user(engine, "13800000101")
    other = _seed_product_user(engine, "13800000102")
    with engine.begin() as c:
        c.execute(text(
            "INSERT INTO sa_subscription_products (id, product_id, name, tier, price, currency, duration_days,"
            " max_family_seats, status, sort_order, is_deleted, created_at, updated_at)"
            " VALUES ('p-x','pro_m','Pro','pro',18,'CNY',30,1,'active',1,0,CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)"))
        c.execute(text(
            "INSERT INTO sa_subscription_orders (id, order_no, user_id, amount, currency, status, product_id,"
            " is_deleted, created_at, updated_at) VALUES ('o-x', :no, :u, 18, 'CNY', 'paid', 'p-x', 0,"
            " CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)"), {"no": f"NO-{uuid.uuid4().hex[:8]}", "u": me})
        c.execute(text(
            "INSERT INTO sa_family_relations (id, inviter_id, invitee_id, relation_type, status, can_view_status,"
            " is_deleted, created_at, updated_at) VALUES ('fr-x', :a, :b, 'parent', 'accepted', 1, 0,"
            " CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)"), {"a": me, "b": other})
        c.execute(text("INSERT INTO family_members (id, owner_id, member_id, nickname) VALUES (:i, :o, :m, '外婆昵称')"),
                  {"i": str(uuid.uuid4()), "o": me, "m": other})

    deleted, retained, leftovers = erase_product_store(me)
    assert leftovers == []
    assert retained.get("sa_subscription_orders") == 1

    with engine.connect() as c:
        # 付款记录真的还在（原来被 users 的级联删除带走了）
        assert c.execute(text("SELECT count(*) FROM sa_subscription_orders WHERE id = 'o-x'")).scalar() == 1
        # users 行匿名化，不再有任何个人信息
        row = c.execute(text("SELECT phone, email, nickname, is_deleted FROM users WHERE id = :i"), {"i": me}).one()
        assert row[0] is None and row[1] is None and row[2] is None
        assert bool(row[3]) is True
        # 列名不叫 user_id 的关联行也删了（家庭关系的两端、家庭成员的两端）
        assert c.execute(text("SELECT count(*) FROM sa_family_relations WHERE id = 'fr-x'")).scalar() == 0
        assert c.execute(text("SELECT count(*) FROM family_members WHERE owner_id = :i"), {"i": me}).scalar() == 0
        # 别人的用户行不动
        assert c.execute(text("SELECT phone FROM users WHERE id = :i"), {"i": other}).scalar() == "13800000102"


def test_every_user_referencing_column_in_all_three_stores_is_handled_or_explained():
    """三处存储里凡是列名像「指向某个人」的列，要么会被注销找到，要么写明为什么不是用户。"""
    import re

    from app.database import db as record_db
    from app.db.database import Base, init_db
    from app.services.account_erasure import (
        EXTRA_USER_COLUMNS,
        NOT_USER_LINKED,
        USER_COLUMN,
    )
    from app.simple_models import Base as CoreBase

    # 「引用某个人」的列：注销必须能顺着它找到行；「记录某个人信息」的列：
    # 只要这张表的行整体能被找到（存在 user_id / 登记的额外列 / 是 users 表本身）就行。
    reference = re.compile(
        r"(owner|patient|child|author|sender|recipient|creator|created_by|elder|parent|inviter|invitee|uid|"
        r"(^|_)member(_id)?$)", re.I)
    value = re.compile(r"(email|phone|mobile|nickname|member_name)", re.I)
    init_db()
    record_db.init_db()
    tables: dict[str, list[str]] = {}
    for base in (Base, CoreBase):
        for name, table in base.metadata.tables.items():
            tables.setdefault(name, []).extend(c.name for c in table.columns)
    db = record_db.get_db()
    for (name,) in db.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'").fetchall():
        tables.setdefault(name, []).extend(r[1] for r in db.execute(f'PRAGMA table_info("{name}")').fetchall())
    assert len(tables) > 80  # 扫描器没坏

    unexplained = []
    for table, columns in tables.items():
        handled = set(EXTRA_USER_COLUMNS.get(table, ()))
        rows_findable = table == "users" or handled or any(USER_COLUMN.match(c) for c in columns)
        for column in columns:
            if USER_COLUMN.match(column) or column in handled:
                continue
            if (table, column) in NOT_USER_LINKED:
                continue
            if reference.search(column) or (value.search(column) and not rows_findable):
                unexplained.append(f"{table}.{column}")
    assert not unexplained, (
        "这些列看起来指向某个人，但注销找不到它们，也没有登记为「不是用户」：\n  "
        + "\n  ".join(sorted(set(unexplained)))
        + "\n在 account_erasure.EXTRA_USER_COLUMNS 里登记（注销会删这些行），或在 NOT_USER_LINKED 里写明理由。"
    )


def test_core_store_sms_codes_and_family_seat_references(client, tmp_path):
    """核心库：验证码表以手机号为键；别人家庭席位里的 member_user_id 指向本人。"""
    from sqlalchemy import create_engine, text

    alice, alice_headers = _login(client)
    bob, _ = _login(client)
    engine = create_engine(f"sqlite:///{tmp_path}/c.db")
    with engine.begin() as c:
        c.execute(text("UPDATE users SET phone = '13800000201' WHERE id = :i"), {"i": alice})
        c.execute(text("INSERT INTO sms_codes (phone, code_hash, expires_at, attempts) VALUES ('13800000201','h',9999999999,0)"))
        c.execute(text("INSERT INTO sms_codes (phone, code_hash, expires_at, attempts) VALUES ('13800000202','h',9999999999,0)"))
        c.execute(text("INSERT INTO family_seats (id, user_id, member_name, member_user_id, bound_at) VALUES ('seat1', :b, '爱丽丝', :a, 1)"),
                  {"a": alice, "b": bob})

    response = client.delete("/api/v1/auth/account", headers=alice_headers)
    assert response.status_code == 200, response.text

    with engine.connect() as c:
        assert c.execute(text("SELECT count(*) FROM sms_codes WHERE phone = '13800000201'")).scalar() == 0
        assert c.execute(text("SELECT count(*) FROM sms_codes WHERE phone = '13800000202'")).scalar() == 1  # 别人的不动
        seat = c.execute(text("SELECT user_id, member_name, member_user_id FROM family_seats WHERE id = 'seat1'")).one()
        assert seat[0] == bob  # 席位仍属于邀请方
        assert seat[1] == "已注销成员" and seat[2] is None  # 本人的名字与账号 ID 已抹掉
