from datetime import datetime, timedelta

import pytest


@pytest.fixture
def admin_headers(monkeypatch):
    from app.router import admin_auth
    token = "test-family-admin"
    monkeypatch.setitem(admin_auth._active_tokens, token, {
        "username": "test", "expires_at": datetime.now() + timedelta(hours=1),
    })
    return {"X-Admin-Token": token}


def test_family_admin_rejects_anonymous_and_regular_user(client, auth_headers):
    for headers in ({}, auth_headers, {"X-Admin-Token": "invalid"}):
        response = client.get("/api/v1/admin/families", headers=headers)
        assert response.status_code in (401, 403)


def test_family_admin_empty(client, admin_headers):
    response = client.get("/api/v1/admin/families", headers=admin_headers)
    assert response.status_code == 200
    assert response.json() == {
        "success": True, "data": [], "total": 0, "page": 1, "page_size": 20,
    }


def test_family_admin_counts_records_without_exposing_private_fields(client, admin_headers):
    from app.database.db import get_db, close_test_connection
    db = get_db()
    try:
        for ident, family, owner in [('1', 'a', 'u1'), ('2', 'a', 'u1'), ('3', 'a', 'u2'), ('4', 'b', 'u3')]:
            db.execute(
                """INSERT INTO family_relations
                   (id,user_id,family_id,family_name,member_name,relation,health_data,updated_at)
                   VALUES (?,?,?,?,?,?,?,?)""",
                (ident, owner, family, '家庭'+family, '隐私姓名', 'parent', '{"private":"secret"}', '2026-10-12'),
            )
        db.commit()
    finally:
        close_test_connection(db)
    first = client.get("/api/v1/admin/families?page_size=1", headers=admin_headers).json()
    second = client.get("/api/v1/admin/families?page_size=1&page=2", headers=admin_headers).json()
    assert first["total"] == second["total"] == 2
    assert first["data"] == [{
        "id": "a", "name": "家庭a", "record_count": 3,
        "account_count": 2, "updated_at": "2026-10-12",
    }]
    assert second["data"][0]["id"] == "b"
    assert second["data"][0]["record_count"] == 1
    assert client.get("/api/v1/admin/families?page=3&page_size=1", headers=admin_headers).json()["data"] == []


@pytest.mark.parametrize("query", ["page=0", "page_size=0", "page_size=101", "page=bad"])
def test_family_admin_rejects_invalid_pagination(client, admin_headers, query):
    assert client.get("/api/v1/admin/families?" + query, headers=admin_headers).status_code == 422


def test_family_admin_storage_error_is_not_empty_success(client, admin_headers, monkeypatch):
    def broken():
        raise RuntimeError("test storage unavailable")
    monkeypatch.setattr("app.database.db.get_db", broken)
    with pytest.raises(RuntimeError, match="test storage unavailable"):
        client.get("/api/v1/admin/families", headers=admin_headers)
