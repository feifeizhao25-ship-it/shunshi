"""S14/S15：生命周期历史读取、单条记忆更新/搜索在 HTTP 层要登录、只能碰自己的数据。

服务层函数另有 test_memory_report_and_lifecycle_history.py 覆盖；这里走真实路由 +
product_access_guard，确认接口确实挂载、匿名被拒、换号看不到也改不了别人的数据。
"""
import base64
import json
import uuid


def _login(client):
    response = client.post("/api/v1/auth/guest-login", json={})
    assert response.status_code == 200, response.text
    token = response.json()["access_token"]
    # 只读令牌里的 sub 当本人 id（测试里不验签，服务端照常验签）。
    part = token.split(".")[1]
    user_id = json.loads(base64.urlsafe_b64decode(part + "=" * (-len(part) % 4)))["sub"]
    return {"Authorization": f"Bearer {token}"}, str(user_id)


def test_lifecycle_history_requires_login_and_is_user_scoped(client):
    a_headers, a_id = _login(client)
    b_headers, _ = _login(client)

    assert client.get("/api/v1/lifecycle/history").status_code == 401
    assert client.get("/api/v1/lifecycle/history", params={"user_id": a_id}).status_code == 401

    updated = client.put(
        "/api/v1/lifecycle/profile", headers=a_headers, params={"user_id": a_id}, json={"birth_year": 1990}
    )
    assert updated.status_code == 200, updated.text

    own = client.get("/api/v1/lifecycle/history", headers=a_headers)
    assert own.status_code == 200, own.text
    body = own.json()
    assert body["user_id"] == a_id
    assert body["count"] >= 1
    assert body["history"][0]["birth_year"] == 1990

    # 别人带着 A 的 user_id 来读：403；不带 user_id：只看到自己的（空）历史。
    assert client.get("/api/v1/lifecycle/history", headers=b_headers, params={"user_id": a_id}).status_code == 403
    other = client.get("/api/v1/lifecycle/history", headers=b_headers)
    assert other.status_code == 200
    assert other.json()["count"] == 0


def test_memory_search_and_update_require_login_and_are_user_scoped(client):
    a_headers, _ = _login(client)
    b_headers, _ = _login(client)
    marker = f"菊花茶-{uuid.uuid4().hex[:8]}"

    created = client.post(
        "/api/v1/memory/create",
        headers=a_headers,
        json={"type": "preference", "content": f"爱喝{marker}", "confidence": 0.6},
    )
    assert created.status_code == 200, created.text
    memory_id = created.json()["memory"]["id"]

    # 匿名
    assert client.get("/api/v1/memory/search", params={"q": marker}).status_code == 401
    assert client.put(f"/api/v1/memory/{memory_id}", json={"content": "x"}).status_code == 401

    # 本人能搜到
    found = client.get("/api/v1/memory/search", headers=a_headers, params={"q": marker})
    assert found.status_code == 200, found.text
    assert [m["id"] for m in found.json()["memories"]] == [memory_id]

    # 别人搜不到、改不了
    assert client.get("/api/v1/memory/search", headers=b_headers, params={"q": marker}).json()["count"] == 0
    denied = client.put(f"/api/v1/memory/{memory_id}", headers=b_headers, json={"content": "被别人改了"})
    assert denied.status_code == 404

    # 本人更新内容和置信度
    ok = client.put(
        f"/api/v1/memory/{memory_id}", headers=a_headers, json={"content": f"爱喝{marker}（少糖）", "confidence": 0.9}
    )
    assert ok.status_code == 200, ok.text
    after = client.get("/api/v1/memory/search", headers=a_headers, params={"q": "少糖"}).json()["memories"]
    assert len(after) == 1 and after[0]["id"] == memory_id
    assert after[0]["content"] == f"爱喝{marker}（少糖）"
    assert abs(float(after[0]["confidence"]) - 0.9) < 1e-9


def test_memory_search_treats_wildcards_literally(client):
    a_headers, _ = _login(client)
    client.post("/api/v1/memory/create", headers=a_headers, json={"type": "preference", "content": "喜欢清淡饮食"})
    # '%' / '_' 是用户输入的字面字符，不应变成「匹配全部」
    for q in ("%", "_"):
        res = client.get("/api/v1/memory/search", headers=a_headers, params={"q": q})
        assert res.status_code == 200
        assert res.json()["count"] == 0, q
