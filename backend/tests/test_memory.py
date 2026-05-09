"""
顺时 - 记忆系统测试
test_memory.py
"""

import pytest
from unittest.mock import patch, MagicMock


class TestMemoryCreate:
    """记忆创建测试"""

    def test_create_memory(self, client):
        response = client.post("/api/v1/memory/create", json={
            "user_id": "test-user-001",
            "type": "preference",
            "content": "喜欢喝菊花茶",
            "confidence": 1.0,
            "source": "conversation",
        })
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "memory" in data
        assert data["memory"]["content"] == "喜欢喝菊花茶"
        assert data["memory"]["type"] == "preference"

    def test_create_memory_different_types(self, client):
        types = ["preference", "habit", "emotional_trend", "reflection_theme"]
        for mem_type in types:
            # user_id 必须存在于 users 表（FK 约束）
            response = client.post("/api/v1/memory/create", json={
                "user_id": f"test-user-{mem_type}",
                "type": mem_type,
                "content": f"测试{mem_type}内容",
            })
            assert response.status_code == 200
            assert response.json()["success"] is True

    def test_create_memory_invalid_type(self, client):
        response = client.post("/api/v1/memory/create", json={
            "user_id": "test-user-001",
            "type": "invalid_type",
            "content": "测试",
        })
        assert response.status_code == 400


class TestMemoryList:
    """记忆列表测试"""

    def test_get_memory_list(self, client):
        response = client.get("/api/v1/memory/list?user_id=test-user-001")
        assert response.status_code == 200
        data = response.json()
        assert "memories" in data
        assert "count" in data

    def test_get_memory_list_with_type_filter(self, client):
        response = client.get("/api/v1/memory/list?user_id=test-user-001&type=preference")
        assert response.status_code == 200
        data = response.json()
        for item in data["memories"]:
            assert item["type"] == "preference"

    def test_get_memory_list_empty_user(self, client):
        response = client.get("/api/v1/memory/list?user_id=nonexistent-user")
        assert response.status_code == 200
        data = response.json()
        assert len(data["memories"]) == 0


class TestUserContext:
    """用户上下文测试"""

    def test_get_user_context_empty(self, client):
        response = client.get("/api/v1/memory/context?user_id=new-user-no-memory")
        assert response.status_code == 200
        data = response.json()
        assert data["has_context"] is False
        assert data["preferences"] == []
        assert data["habits"] == []

    def test_get_user_context_with_data(self, client):
        # 先创建记忆（user_id 需存在于 users 表）
        client.post("/api/v1/memory/create", json={
            "user_id": "context-test-user",
            "type": "preference",
            "content": "喜欢吃素",
        })
        client.post("/api/v1/memory/create", json={
            "user_id": "context-test-user",
            "type": "habit",
            "content": "每天早起跑步",
        })

        response = client.get("/api/v1/memory/context?user_id=context-test-user")
        assert response.status_code == 200
        data = response.json()
        assert data["has_context"] is True
        assert len(data["preferences"]) > 0
        assert len(data["habits"]) > 0
        assert "summary" in data


class TestMemoryDelete:
    """记忆删除测试"""

    def test_delete_memory(self, client):
        # 创建（user_id 需存在于 users 表）
        create_resp = client.post("/api/v1/memory/create", json={
            "user_id": "delete-test-user",
            "type": "preference",
            "content": "待删除的记忆",
        })
        memory_id = create_resp.json()["memory"]["id"]

        # 删除
        delete_resp = client.delete(f"/api/v1/memory/{memory_id}?user_id=delete-test-user")
        assert delete_resp.status_code == 200
        assert delete_resp.json()["success"] is True

        # 验证已删除
        list_resp = client.get("/api/v1/memory/list?user_id=delete-test-user")
        items = list_resp.json()["memories"]
        ids = [i["id"] for i in items]
        assert memory_id not in ids

    def test_delete_nonexistent_memory(self, client):
        response = client.delete("/api/v1/memory/nonexistent-id?user_id=test-user-001")
        assert response.status_code == 404


class TestMemoryStats:
    """记忆统计测试"""

    def test_get_stats(self, client):
        response = client.get("/api/v1/memory/stats?user_id=test-user-001")
        assert response.status_code == 200
        data = response.json()
        assert "total" in data
        assert "by_type" in data


class TestMemoryExtraction:
    """记忆提取测试"""

    def test_extract_preferences(self):
        from app.services.memory_system import MemorySystem
        ms = MemorySystem()
        results = ms.extract_preferences("我喜欢吃红枣，不喜欢喝咖啡")
        types = [r["type"] for r in results]
        assert "preference" in types

    def test_extract_habits(self):
        from app.services.memory_system import MemorySystem
        ms = MemorySystem()
        results = ms.extract_preferences("我每天晚上11点睡觉，经常跑步")
        types = [r["type"] for r in results]
        assert "habit" in types

    def test_extract_emotional_trends(self):
        from app.services.memory_system import MemorySystem
        ms = MemorySystem()
        results = ms.extract_preferences("最近压力很大，每天都焦虑")
        types = [r["type"] for r in results]
        assert "emotional_trend" in types

    def test_extract_no_match(self):
        from app.services.memory_system import MemorySystem
        ms = MemorySystem()
        results = ms.extract_preferences("今天天气不错")
        assert len(results) == 0
