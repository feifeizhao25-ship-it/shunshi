"""
顺时 - 体质辨识 API 路由测试
test_constitution.py
"""

import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


class TestConstitutionList:
    """体质列表端点测试"""

    def test_list_constitutions_returns_200(self):
        """GET /api/v1/constitution/ 返回 200"""
        response = client.get("/api/v1/constitution/")
        assert response.status_code == 200

    def test_list_constitutions_has_data(self):
        """响应包含 'data' 键且有体质列表"""
        response = client.get("/api/v1/constitution/")
        assert response.status_code == 200
        data = response.json()
        assert "data" in data
        assert isinstance(data["data"], list)
        assert len(data["data"]) > 0

    def test_list_constitutions_has_required_fields(self):
        """体质对象包含所需字段"""
        response = client.get("/api/v1/constitution/")
        data = response.json()
        constitution = data["data"][0]
        assert "id" in constitution
        assert "name" in constitution
        assert "description" in constitution

    def test_list_includes_balanced_constitution(self):
        """列表包含平和质"""
        response = client.get("/api/v1/constitution/")
        data = response.json()
        ids = [c.get("id") for c in data["data"]]
        assert "pinghe" in ids


class TestConstitutionDetail:
    """体质详情端点测试"""

    def test_get_pinghe_constitution(self):
        """GET /api/v1/constitution/pinghe 返回 200，id 为 pinghe"""
        response = client.get("/api/v1/constitution/pinghe")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["id"] == "pinghe"
        assert "name" in data["data"]
        assert "characteristics" in data["data"]

    def test_get_qixu_constitution(self):
        """GET /api/v1/constitution/qixu 返回 200"""
        response = client.get("/api/v1/constitution/qixu")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["id"] == "qixu"

    def test_get_yangxu_constitution(self):
        """GET /api/v1/constitution/yangxu 返回 200"""
        response = client.get("/api/v1/constitution/yangxu")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["id"] == "yangxu"

    def test_get_yinxu_constitution(self):
        """GET /api/v1/constitution/yinxu 返回 200"""
        response = client.get("/api/v1/constitution/yinxu")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["id"] == "yinxu"

    def test_detail_has_all_fields(self):
        """体质详情包含所有必要字段"""
        response = client.get("/api/v1/constitution/pinghe")
        data = response.json()
        constitution = data["data"]
        assert "id" in constitution
        assert "name" in constitution
        assert "description" in constitution
        assert "characteristics" in constitution
        assert "diet_advice" in constitution
        assert "exercise_advice" in constitution

    def test_unknown_constitution_404(self):
        """GET /api/v1/constitution/unknown_type 返回 404"""
        response = client.get("/api/v1/constitution/unknown_type")
        assert response.status_code == 404

    def test_tanshi_constitution(self):
        """GET /api/v1/constitution/tanshi 返回 200"""
        response = client.get("/api/v1/constitution/tanshi")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["id"] == "tanshi"

    def test_characteristics_is_list(self):
        """体质特征应该是列表"""
        response = client.get("/api/v1/constitution/pinghe")
        data = response.json()
        assert isinstance(data["data"]["characteristics"], list)
        assert len(data["data"]["characteristics"]) > 0


class TestConstitutionQuestions:
    """体质问卷端点测试"""

    def test_get_questions_returns_200(self):
        """GET /api/v1/constitution/questions 返回 200"""
        response = client.get("/api/v1/constitution/questions")
        assert response.status_code == 200

    def test_questions_has_question_list(self):
        """响应包含问题列表"""
        response = client.get("/api/v1/constitution/questions")
        assert response.status_code == 200
        data = response.json()
        assert "data" in data
        assert "questions" in data["data"]
        assert isinstance(data["data"]["questions"], list)

    def test_questions_have_required_fields(self):
        """每个问题包含必要字段"""
        response = client.get("/api/v1/constitution/questions")
        data = response.json()
        questions = data["data"]["questions"]
        if len(questions) > 0:
            question = questions[0]
            assert "id" in question
            assert "text" in question or "content" in question

    def test_get_questions_with_limit(self):
        """GET /api/v1/constitution/questions?limit=5 最多返回 5 个问题"""
        response = client.get("/api/v1/constitution/questions?limit=5")
        assert response.status_code == 200
        data = response.json()
        assert len(data["data"]["questions"]) <= 5


class TestConstitutionAssess:
    """体质评估端点测试"""

    def test_assess_with_answers(self):
        """POST /api/v1/constitution/assess 接受答案并返回结果"""
        payload = {
            "answers": [
                {"question_id": "q1", "score": 1},
                {"question_id": "q2", "score": 0},
            ]
        }
        response = client.post("/api/v1/constitution/assess", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert "data" in data
        assert "constitution" in data["data"] or "result" in data["data"]

    def test_assess_empty_answers(self):
        """空答案应该返回错误或默认结果"""
        payload = {"answers": []}
        response = client.post("/api/v1/constitution/assess", json=payload)
        # 可能返回 400 或 200（使用默认值）
        assert response.status_code in [200, 400]

    def test_assess_returns_constitution_type(self):
        """评估结果应该包含体质类型"""
        payload = {
            "answers": [
                {"question_id": "q1", "score": 5},
                {"question_id": "q2", "score": 5},
            ]
        }
        response = client.post("/api/v1/constitution/assess", json=payload)
        if response.status_code == 200:
            data = response.json()
            result = data["data"]
            # 应该有体质类型或主导体质
            assert any(key in result for key in ["constitution", "result", "type", "main_constitution"])

    def test_assess_includes_recommendations(self):
        """评估结果应该包含建议"""
        payload = {
            "answers": [
                {"question_id": "q1", "score": 3},
                {"question_id": "q2", "score": 3},
            ]
        }
        response = client.post("/api/v1/constitution/assess", json=payload)
        if response.status_code == 200:
            data = response.json()
            # 应该有某种建议字段
            assert any(key in data["data"] for key in ["recommendations", "diet_advice", "exercise_advice"])


class TestConstitutionFood:
    """体质食物建议端点测试"""

    def test_get_food_recommendations(self):
        """GET /api/v1/constitution/pinghe/foods 返回推荐食物"""
        response = client.get("/api/v1/constitution/pinghe/foods")
        assert response.status_code == 200
        data = response.json()
        assert "data" in data

    def test_food_recommendations_has_list(self):
        """食物建议包含列表"""
        response = client.get("/api/v1/constitution/pinghe/foods")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data["data"], list) or "foods" in data["data"]

    def test_unknown_constitution_food_404(self):
        """未知体质的食物建议返回 404"""
        response = client.get("/api/v1/constitution/unknown_type/foods")
        assert response.status_code == 404

    def test_qixu_foods(self):
        """GET /api/v1/constitution/qixu/foods 返回 200"""
        response = client.get("/api/v1/constitution/qixu/foods")
        assert response.status_code == 200


class TestConstitutionExercise:
    """体质运动建议端点测试"""

    def test_get_exercise_recommendations(self):
        """GET /api/v1/constitution/pinghe/exercises 返回运动建议"""
        response = client.get("/api/v1/constitution/pinghe/exercises")
        assert response.status_code == 200
        data = response.json()
        assert "data" in data

    def test_unknown_constitution_exercise_404(self):
        """未知体质的运动建议返回 404"""
        response = client.get("/api/v1/constitution/unknown_type/exercises")
        assert response.status_code == 404

    def test_yangxu_exercises(self):
        """GET /api/v1/constitution/yangxu/exercises 返回 200"""
        response = client.get("/api/v1/constitution/yangxu/exercises")
        assert response.status_code == 200
        data = response.json()
        assert "data" in data
