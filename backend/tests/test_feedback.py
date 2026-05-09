"""顺时 - 用户反馈测试"""
import pytest


class TestFeedbackSubmit:
    def test_submit_returns_200(self, client):
        payload = {
            "user_id": "test_user",
            "type": "bug",
            "title": "页面加载问题",
            "content": "打开养生计划页面时闪退",
            "platform": "ios"
        }
        response = client.post("/api/v1/feedback/submit", json=payload)
        assert response.status_code == 200

    def test_submit_has_feedback_id(self, client):
        payload = {"user_id": "test_user", "type": "suggestion", "content": "建议增加更多食材"}
        data = client.post("/api/v1/feedback/submit", json=payload).json()
        assert data["success"] is True
        assert "feedback_id" in data["data"]

    def test_submit_requires_user_id(self, client):
        response = client.post("/api/v1/feedback/submit", json={"type": "bug", "content": "test"})
        assert response.status_code == 422


class TestFeedbackStatus:
    def test_status_returns_200(self, client):
        payload = {"user_id": "test_user", "type": "bug", "content": "Status test"}
        create_data = client.post("/api/v1/feedback/submit", json=payload).json()
        feedback_id = create_data["data"]["feedback_id"]
        response = client.get(f"/api/v1/feedback/{feedback_id}")
        assert response.status_code == 200

    def test_nonexistent_feedback_returns_404(self, client):
        assert client.get("/api/v1/feedback/nonexistent_feedback").status_code == 404


class TestFeedbackAdminList:
    def test_admin_list_returns_200(self, client):
        response = client.get("/api/v1/feedback/admin/list")
        assert response.status_code == 200

    def test_admin_list_has_items(self, client):
        data = client.get("/api/v1/feedback/admin/list").json()
        assert "feedbacks" in data["data"]


class TestFeedbackAdminUpdateStatus:
    def test_update_status_returns_200(self, client):
        payload = {"user_id": "test_user", "type": "bug", "content": "Update test"}
        create_data = client.post("/api/v1/feedback/submit", json=payload).json()
        feedback_id = create_data["data"]["feedback_id"]
        response = client.patch(f"/api/v1/feedback/admin/{feedback_id}/status",
                                json={"status": "resolved"})
        assert response.status_code == 200


class TestFeedbackTypes:
    def test_types_returns_200(self, client):
        response = client.get("/api/v1/feedback/types/list")
        assert response.status_code == 200


class TestFeedbackRating:
    def test_rating_returns_200(self, client):
        payload = {"user_id": "test_user", "rating": 5, "comment": "非常好用！"}
        response = client.post("/api/v1/feedback/rating", json=payload)
        assert response.status_code == 200
