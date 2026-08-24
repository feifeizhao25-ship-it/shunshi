"""顺时 - 专家问答测试"""
import pytest


class TestExpertList:
    def test_experts_returns_200(self, client):
        response = client.get("/api/v1/expert-qa/experts")
        assert response.status_code == 200

    def test_experts_has_list(self, client):
        data = client.get("/api/v1/expert-qa/experts").json()
        assert "experts" in data["data"]
        assert len(data["data"]["experts"]) > 0


class TestExpertDetail:
    def test_valid_expert_returns_200(self, client):
        response = client.get("/api/v1/expert-qa/experts/expert_001")
        assert response.status_code == 200

    def test_invalid_expert_returns_404(self, client):
        assert client.get("/api/v1/expert-qa/experts/nonexistent").status_code == 404


class TestExpertQuestions:
    def test_submit_question_returns_200(self, client):
        payload = {
            "user_id": "test_user",
            "question": "气虚体质应该如何调理饮食？",
            "category": "constitution",
            "expert_id": "expert_001"
        }
        response = client.post("/api/v1/expert-qa/questions", json=payload)
        assert response.status_code == 200

    def test_submit_question_has_id(self, client):
        payload = {"user_id": "test_user", "question": "Test question?", "category": "general"}
        data = client.post("/api/v1/expert-qa/questions", json=payload).json()
        assert data["success"] is True
        assert "question_id" in data["data"]


class TestExpertQuestionDetail:
    def test_question_detail_returns_200(self, client):
        payload = {"user_id": "test_user", "question": "Detail test?", "category": "general"}
        create_data = client.post("/api/v1/expert-qa/questions", json=payload).json()
        q_id = create_data["data"]["question_id"]
        response = client.get(f"/api/v1/expert-qa/questions/{q_id}")
        assert response.status_code == 200

    def test_nonexistent_question_returns_404(self, client):
        assert client.get("/api/v1/expert-qa/questions/nonexistent_q").status_code == 404


class TestExpertAnswer:
    def test_answer_question_returns_200(self, client):
        payload = {"user_id": "test_user", "question": "Answer test?", "category": "general"}
        create_data = client.post("/api/v1/expert-qa/questions", json=payload).json()
        q_id = create_data["data"]["question_id"]
        answer_payload = {"expert_id": "expert_001", "answer": "这是用于接口验证的完整示例回答。"}
        response = client.post(f"/api/v1/expert-qa/questions/{q_id}/answer", json=answer_payload)
        assert response.status_code == 200


class TestExpertFAQ:
    def test_faq_returns_200(self, client):
        response = client.get("/api/v1/expert-qa/faq")
        assert response.status_code == 200

    def test_faq_has_items(self, client):
        data = client.get("/api/v1/expert-qa/faq").json()
        assert "faq" in data["data"]
