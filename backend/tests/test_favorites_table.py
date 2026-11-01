"""B20：收藏接口在全新数据库上端到端可用（以前 sa_favorites 没有任何模型/迁移，GET 必 500）。"""
import uuid

import pytest


@pytest.fixture()
def fav_client(client, auth_headers):
    client.headers.update(auth_headers)
    return client


def test_favorites_table_is_created_by_models():
    from app.db.database import Base
    import app.models  # noqa: F401

    assert "sa_favorites" in Base.metadata.tables


def test_list_empty_then_add_list_check_delete(fav_client):
    r = fav_client.get("/api/v1/favorites?limit=1")
    assert r.status_code == 200, r.text
    j = r.json()
    assert (j["items"], j["total"]) == ([], 0) and j["success"] is True and j["data"] == {"items": [], "total": 0}

    cid = f"recipe-{uuid.uuid4().hex[:8]}"
    a = fav_client.post("/api/v1/favorites", json={"content_id": cid, "content_type": "recipe"})
    assert a.status_code == 200, a.text
    fid = a.json()["id"]
    assert fid
    again = fav_client.post("/api/v1/favorites", json={"content_id": cid, "content_type": "recipe"})
    assert again.json()["id"] == fid  # 不重复收藏

    lst = fav_client.get("/api/v1/favorites").json()
    assert lst["total"] == 1 and lst["items"][0]["content_id"] == cid

    chk = fav_client.get(f"/api/v1/favorites/check?content_id={cid}").json()
    assert chk["is_favorited"] is True and chk["favorite_id"] == fid and chk["data"]["is_favorited"] is True

    d = fav_client.delete(f"/api/v1/favorites/{fid}")
    assert d.status_code == 200
    assert fav_client.get("/api/v1/favorites").json()["total"] == 0
    assert fav_client.delete(f"/api/v1/favorites/{fid}").status_code == 404


def test_delete_by_content_id_like_the_apps_do(fav_client):
    cid = f"recipe-{uuid.uuid4().hex[:8]}"
    fav_client.post("/api/v1/favorites", json={"content_id": cid, "content_type": "recipe"})
    assert fav_client.get("/api/v1/favorites").json()["data"]["total"] == 1
    assert fav_client.delete(f"/api/v1/favorites/{cid}").status_code == 200
    assert fav_client.get(f"/api/v1/favorites/check?content_id={cid}").json()["data"]["is_favorited"] is False


def test_global_messages_are_english(fav_client):
    hdr = {"X-App-Market": "global", "Accept-Language": "en-US"}
    cid = f"c-{uuid.uuid4().hex[:6]}"
    a = fav_client.post("/api/v1/favorites", json={"content_id": cid}, headers=hdr)
    assert a.json()["message"] == "Saved"
    fid = a.json()["id"]
    assert fav_client.delete(f"/api/v1/favorites/{fid}", headers=hdr).json()["message"] == "Removed"


def test_other_users_favorites_are_forbidden(fav_client):
    r = fav_client.get("/api/v1/favorites?user_id=someone-else")
    assert r.status_code == 403
