"""顺时 - 社交分享测试"""
import pytest


class TestShareCard:
    def test_create_card_returns_200(self, client):
        payload = {"user_id": "test_user", "type": "wellness_plan", "content": "气虚质"}
        response = client.post("/api/v1/share/card", json=payload)
        assert response.status_code == 200

    def test_create_card_has_share_id(self, client):
        payload = {"user_id": "test_user", "type": "achievement"}
        data = client.post("/api/v1/share/card", json=payload).json()
        assert data["success"] is True
        assert "share_id" in data["data"]["card"]


class TestShareCardGet:
    def test_get_card_after_create(self, client):
        payload = {"user_id": "test_user", "type": "wellness_plan"}
        create_data = client.post("/api/v1/share/card", json=payload).json()
        share_id = create_data["data"]["card"]["share_id"]
        response = client.get(f"/api/v1/share/card/{share_id}")
        assert response.status_code == 200

    def test_get_nonexistent_card_returns_404(self, client):
        assert client.get("/api/v1/share/card/nonexistent_id").status_code == 404


class TestShareInvite:
    def test_invite_returns_200(self, client):
        payload = {"user_id": "test_user", "channel": "wechat"}
        response = client.post("/api/v1/share/invite", json=payload)
        assert response.status_code == 200

    def test_invite_has_link(self, client):
        payload = {"user_id": "test_user"}
        data = client.post("/api/v1/share/invite", json=payload).json()
        assert "invite_url" in data["data"]


class TestShareTemplates:
    def test_templates_returns_200(self, client):
        response = client.get("/api/v1/share/templates")
        assert response.status_code == 200


class TestShareStats:
    def test_stats_returns_200(self, client):
        response = client.get("/api/v1/share/stats/test_user")
        assert response.status_code == 200
