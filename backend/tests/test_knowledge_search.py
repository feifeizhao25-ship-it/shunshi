"""``/api/v1/knowledge/search``：客户端一直在调、服务端之前没有的路由。"""

from __future__ import annotations

import re

_CJK = re.compile(r"[\u3400-\u9fff]")


def test_route_exists_and_returns_shapes_clients_parse(client):
    r = client.get("/api/v1/knowledge/search", params={"q": "补气健脾", "top_k": 5})
    assert r.status_code == 200
    body = r.json()
    assert body["success"] is True
    # 全局搜索页读顶层 results，饮食推荐页读 data.results
    assert body["results"] == body["data"]["results"]
    assert body["data"]["total"] == len(body["results"]) <= 5
    assert body["results"], "the seeded Chinese library has entries about 补气/健脾"
    for item in body["results"]:
        assert item["id"] and item["title"]
        assert item["content"] == (item["description"] or "")
        assert "补气" in str(item) or "健脾" in str(item)


def test_content_type_filter_uses_client_vocabulary(client):
    r = client.get("/api/v1/knowledge/search", params={"q": "茶", "content_type": "tea"})
    assert r.status_code == 200
    results = r.json()["data"]["results"]
    assert results and all(i["type"] == "tea" for i in results)

    r = client.get("/api/v1/knowledge/search", params={"q": "粥", "content_type": "diet"})
    results = r.json()["data"]["results"]
    assert all(i["type"] == "diet" and i["content_type"] == "food_therapy" for i in results)


def test_type_with_no_content_returns_empty_not_other_types(client):
    r = client.get("/api/v1/knowledge/search", params={"q": "汤", "content_type": "herb"})
    assert r.status_code == 200
    assert r.json()["data"]["results"] == []


def test_global_market_gets_english_entries_only(client):
    r = client.get(
        "/api/v1/knowledge/search",
        params={"q": "ginger"},
        headers={"X-App-Market": "global"},
    )
    assert r.status_code == 200
    results = r.json()["data"]["results"]
    assert results, "the seeded English library has ginger entries"
    for item in results:
        assert item["locale"] == "en-US"
        assert not _CJK.search(item["title"])


def test_missing_query_is_rejected(client):
    assert client.get("/api/v1/knowledge/search").status_code == 422
