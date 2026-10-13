import sqlite3
from concurrent.futures import ThreadPoolExecutor

import pytest

from app.feature_flags.store import FlagStore, flag_store


@pytest.fixture(autouse=True)
def isolated_flags(client, tmp_path, monkeypatch):
    from app.database import db as records
    path = tmp_path / "flags.db"
    monkeypatch.setattr(records, "DB_PATH", path)
    flag_store.ensure_tables()
    flag_store._load_cache()


@pytest.fixture
def admin_headers():
    from tests.admin_support import create_admin_session, remove_admin_session
    token = create_admin_session()
    yield {"X-Admin-Token": token}
    remove_admin_session(token)


def seed(key="prompt.test.gray", **kwargs):
    flag_store.set_flag(key, False, **kwargs)
    return flag_store.get_flag(key)


def test_flags_require_real_admin(client, auth_headers):
    for headers in ({}, auth_headers, {"Authorization": "Bearer dev-admin-token"}):
        assert client.get("/api/v1/admin/flags", headers=headers).status_code in (401, 403)


def test_empty_is_not_fake_defaults(client, admin_headers):
    assert client.get("/api/v1/admin/flags", headers=admin_headers).json() == {"success": True, "data": []}


def test_update_persists_and_other_worker_reads_it(client, admin_headers):
    row = seed(rollout_pct=30, description="测试灰度", category="prompt")
    response = client.patch("/api/v1/admin/flags/" + row.key, headers=admin_headers,
        json={"value": True, "expected_updated_at": row.updated_at})
    assert response.status_code == 200
    worker = FlagStore(read_through=True)
    result = worker.get_flag(row.key)
    assert result.value_default is True
    assert result.rollout_pct == 30
    assert result.description == "测试灰度" and result.category == "prompt"
    assert result.updated_at != row.updated_at
    # Stale update cannot overwrite the successful change.
    assert client.patch("/api/v1/admin/flags/" + row.key, headers=admin_headers,
        json={"value": False, "expected_updated_at": row.updated_at}).status_code == 409
    assert worker.get_flag(row.key).value_default is True


def test_read_through_does_not_keep_stale_enabled_state(client, admin_headers):
    row = seed()
    worker = FlagStore(read_through=True)
    assert worker.is_enabled(row.key, "user") is False
    flag_store.set_flag(row.key, True)
    assert worker.is_enabled(row.key, "user") is True
    row = worker.get_flag(row.key)
    assert client.patch("/api/v1/admin/flags/" + row.key, headers=admin_headers,
        json={"value": False, "expected_updated_at": row.updated_at}).status_code == 200
    assert worker.is_enabled(row.key, "user") is False


def test_unverified_binding_and_invalid_body_rejected(client, admin_headers):
    row = seed("payment.stripe_live")
    assert client.patch("/api/v1/admin/flags/" + row.key, headers=admin_headers,
        json={"value": True, "expected_updated_at": row.updated_at}).status_code == 422
    for payload in ({"value": "true", "expected_updated_at": row.updated_at},
                    {"enabled": True}, {"value": True, "expected_updated_at": row.updated_at, "rollout_pct": 100}):
        assert client.patch("/api/v1/admin/flags/" + row.key, headers=admin_headers, json=payload).status_code == 422
    assert client.patch("/api/v1/admin/flags/missing", headers=admin_headers,
        json={"value": True, "expected_updated_at": ""}).status_code == 404


def test_whitelist_not_exposed_and_disable_not_misleading(client, admin_headers):
    row = seed(user_whitelist=["private-user"])
    item = client.get("/api/v1/admin/flags", headers=admin_headers).json()["data"][0]
    assert item["whitelist_count"] == 1
    assert "user_whitelist" not in item
    assert "private-user" not in str(item)
    response = client.patch("/api/v1/admin/flags/" + row.key, headers=admin_headers,
        json={"value": False, "expected_updated_at": row.updated_at})
    assert response.status_code == 409


def test_anonymous_cannot_bypass_partial_rollout():
    flag_store.set_flag("prompt.test.gray", True, rollout_pct=0)
    assert flag_store.is_enabled("prompt.test.gray") is False
    flag_store.set_flag("prompt.test.gray", True, rollout_pct=50)
    assert flag_store.is_enabled("prompt.test.gray") is False


def test_parallel_update_only_one_wins(client, admin_headers):
    row = seed()
    def change(value):
        return client.patch("/api/v1/admin/flags/" + row.key, headers=admin_headers,
            json={"value": value, "expected_updated_at": row.updated_at}).status_code
    with ThreadPoolExecutor(max_workers=2) as pool:
        assert sorted(pool.map(change, [True, False])) == [200, 409]


def test_storage_failure_does_not_return_empty_success(client, admin_headers, monkeypatch):
    def broken():
        raise RuntimeError("test storage offline")
    monkeypatch.setattr("app.feature_flags.store.get_db", broken)
    with pytest.raises(RuntimeError, match="test storage offline"):
        client.get("/api/v1/admin/flags", headers=admin_headers)


def test_failed_commit_rolls_back(client, admin_headers, monkeypatch):
    row = seed()
    from app.database.db import get_db
    connection = get_db()
    class FailingCommit:
        def __getattr__(self, key):
            return getattr(connection, key)
        def commit(self):
            raise RuntimeError("test commit failure")
    monkeypatch.setattr("app.router.admin_flags.get_db", lambda: FailingCommit())
    with pytest.raises(RuntimeError, match="test commit failure"):
        client.patch("/api/v1/admin/flags/" + row.key, headers=admin_headers,
            json={"value": True, "expected_updated_at": row.updated_at})
    assert flag_store.get_flag(row.key).value_default is False
