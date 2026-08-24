"""记忆模块契约：路径/方法/请求体/响应与 Flutter 客户端 settings_page.dart 一致。"""


def test_memory_toggle_contract(client, auth_headers):
    # 客户端 _loadMemorySettings：GET 读 {"enabled": bool}
    default = client.get("/api/v1/settings/memory", headers=auth_headers)
    assert default.status_code == 200
    assert default.json() == {"enabled": False}

    # 客户端 _toggleAiMemory：POST {"enabled": value}
    toggle = client.post("/api/v1/settings/memory", headers=auth_headers, json={"enabled": True})
    assert toggle.status_code == 200
    assert toggle.json() == {"enabled": True}

    assert client.get("/api/v1/settings/memory", headers=auth_headers).json() == {"enabled": True}


def test_delete_memory_all_contract(client, auth_headers):
    client.post("/api/v1/settings/memory", headers=auth_headers, json={"enabled": True})
    response = client.delete("/api/v1/memory/all", headers=auth_headers)
    assert response.status_code == 200
    assert response.json() == {"deleted": True}
    # 清除后回到默认值
    assert client.get("/api/v1/settings/memory", headers=auth_headers).json() == {"enabled": False}


def test_delete_conversations_contract(client, auth_headers):
    response = client.delete("/api/v1/conversations", headers=auth_headers)
    assert response.status_code == 200
    assert response.json() == {"deleted": True}


def test_memory_requires_auth(client):
    assert client.post("/api/v1/settings/memory", json={"enabled": True}).status_code == 401
    assert client.delete("/api/v1/memory/all").status_code == 401
