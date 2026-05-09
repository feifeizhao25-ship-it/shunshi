"""
顺时 - 客户端指标批量摄入端点测试
test_client_metrics.py
"""

import pytest


class TestMetricsBatch:
    """客户端指标批量摄入端点测试"""

    def test_metrics_batch_empty_list(self, client):
        """测试发送空事件列表"""
        response = client.post(
            "/api/v1/metrics/batch",
            json={"events": []}
        )
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "ok"
        assert data["received"] == 0

    def test_metrics_batch_single_event(self, client):
        """测试发送单个事件"""
        response = client.post(
            "/api/v1/metrics/batch",
            json={
                "events": [
                    {
                        "event": "app_open",
                        "user_id": "test-user-001",
                        "timestamp": "2024-11-15T10:00:00Z",
                        "platform": "ios",
                        "properties": {}
                    }
                ]
            }
        )
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "ok"
        assert data["received"] == 1
        assert "received_at" in data

    def test_metrics_batch_multiple_events(self, client):
        """测试发送多个事件"""
        response = client.post(
            "/api/v1/metrics/batch",
            json={
                "events": [
                    {
                        "event": "app_open",
                        "user_id": "test-user-001",
                        "timestamp": "2024-11-15T10:00:00Z",
                        "platform": "ios",
                        "properties": {"version": "1.0.0"}
                    },
                    {
                        "event": "content_view",
                        "user_id": "test-user-001",
                        "timestamp": "2024-11-15T10:01:00Z",
                        "platform": "ios",
                        "properties": {"content_id": "tea-recipe-001"}
                    },
                    {
                        "event": "app_close",
                        "user_id": "test-user-001",
                        "timestamp": "2024-11-15T10:05:00Z",
                        "platform": "ios",
                        "properties": {"session_duration": 300}
                    }
                ]
            }
        )
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "ok"
        assert data["received"] == 3
        assert "received_at" in data

    def test_metrics_batch_invalid_body(self, client):
        """测试发送格式错误的请求体"""
        response = client.post(
            "/api/v1/metrics/batch",
            json={"wrong_key": []}
        )
        # 期望 422 (Unprocessable Entity) 或 200（取决于错误处理策略）
        # 根据 FastAPI 默认行为，应该返回 422
        assert response.status_code in [200, 422]
        if response.status_code == 200:
            data = response.json()
            assert data.get("received", 0) == 0

    def test_metrics_batch_large_batch(self, client):
        """测试发送大批量事件（50个）"""
        events = []
        for i in range(50):
            events.append({
                "event": f"event_{i}",
                "user_id": "test-user-001",
                "timestamp": f"2024-11-15T10:{i:02d}:00Z",
                "platform": "android",
                "properties": {"index": i}
            })

        response = client.post(
            "/api/v1/metrics/batch",
            json={"events": events}
        )
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "ok"
        assert data["received"] == 50
        assert "received_at" in data

    def test_metrics_batch_with_optional_fields(self, client):
        """测试事件中省略可选字段"""
        response = client.post(
            "/api/v1/metrics/batch",
            json={
                "events": [
                    {
                        "event": "simple_event",
                        "properties": {}
                        # user_id, timestamp, platform 都省略
                    }
                ]
            }
        )
        assert response.status_code == 200
        data = response.json()
        assert data["received"] == 1

    def test_metrics_batch_with_complex_properties(self, client):
        """测试包含复杂属性的事件"""
        response = client.post(
            "/api/v1/metrics/batch",
            json={
                "events": [
                    {
                        "event": "content_interaction",
                        "user_id": "test-user-001",
                        "timestamp": "2024-11-15T10:00:00Z",
                        "platform": "ios",
                        "properties": {
                            "content_id": "recipe-001",
                            "duration_seconds": 45,
                            "scrolled": True,
                            "shared": False,
                            "tags": ["tea", "health"],
                            "metadata": {
                                "category": "beverage",
                                "season": "winter"
                            }
                        }
                    }
                ]
            }
        )
        assert response.status_code == 200
        data = response.json()
        assert data["received"] == 1

    def test_metrics_health_endpoint(self, client):
        """测试健康检查端点"""
        response = client.get("/api/v1/metrics/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "ok"
