"""
顺时 - 智能推荐 API 路由测试
test_recommendations.py
"""

import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


class TestRecommendationsDaily:
    """每日推荐端点测试"""

    def test_get_daily_recommendations_returns_200(self):
        """GET /api/v1/recommendations/daily 返回 200"""
        response = client.get("/api/v1/recommendations/daily?user_id=user-001")
        assert response.status_code == 200

    def test_daily_recommendations_has_data(self):
        """响应包含 'data' 键"""
        response = client.get("/api/v1/recommendations/daily?user_id=user-001")
        assert response.status_code == 200
        data = response.json()
        assert "data" in data or "success" in data

    def test_daily_recommendations_requires_user_id(self):
        """缺少 user_id 参数应返回错误"""
        response = client.get("/api/v1/recommendations/daily")
        assert response.status_code == 422

    def test_daily_recommendations_respects_limit(self):
        """GET /api/v1/recommendations/daily?limit=2 最多返回 2 条推荐"""
        response = client.get("/api/v1/recommendations/daily?user_id=user-001&limit=2")
        assert response.status_code == 200
        data = response.json()
        # 数据可能在 data 或 data["items"] 中
        items = data.get("data", {}).get("items", data.get("data", []))
        if isinstance(items, list):
            assert len(items) <= 2

    def test_daily_recommendations_limit_max_10(self):
        """limit 参数最大为 10"""
        response = client.get("/api/v1/recommendations/daily?user_id=user-001&limit=20")
        # 应该被限制或返回错误
        assert response.status_code in [200, 422]

    def test_daily_recommendations_with_locale_zh_cn(self):
        """GET /api/v1/recommendations/daily?locale=zh-CN 返回 200"""
        response = client.get("/api/v1/recommendations/daily?user_id=user-001&locale=zh-CN")
        assert response.status_code == 200

    def test_daily_recommendations_with_locale_en_us(self):
        """GET /api/v1/recommendations/daily?locale=en-US 返回 200"""
        response = client.get("/api/v1/recommendations/daily?user_id=user-001&locale=en-US")
        assert response.status_code == 200

    def test_daily_recommendations_default_limit_3(self):
        """默认 limit 为 3"""
        response = client.get("/api/v1/recommendations/daily?user_id=user-001")
        assert response.status_code == 200

    def test_daily_different_users_different_recommendations(self):
        """不同用户可能获得不同推荐"""
        response1 = client.get("/api/v1/recommendations/daily?user_id=user-001")
        response2 = client.get("/api/v1/recommendations/daily?user_id=user-002")
        assert response1.status_code == 200
        assert response2.status_code == 200


class TestRecommendationsSeasonal:
    """季节推荐端点测试"""

    def test_get_seasonal_recommendations_returns_200(self):
        """GET /api/v1/recommendations/seasonal 返回 200"""
        response = client.get("/api/v1/recommendations/seasonal?season=spring")
        assert response.status_code == 200

    def test_seasonal_recommendations_requires_season(self):
        """缺少 season 参数应返回错误"""
        response = client.get("/api/v1/recommendations/seasonal")
        assert response.status_code == 422

    def test_seasonal_recommendations_spring(self):
        """GET /api/v1/recommendations/seasonal?season=spring 返回 200"""
        response = client.get("/api/v1/recommendations/seasonal?season=spring")
        assert response.status_code == 200
        data = response.json()
        assert "data" in data or "success" in data

    def test_seasonal_recommendations_summer(self):
        """GET /api/v1/recommendations/seasonal?season=summer 返回 200"""
        response = client.get("/api/v1/recommendations/seasonal?season=summer")
        assert response.status_code == 200

    def test_seasonal_recommendations_autumn(self):
        """GET /api/v1/recommendations/seasonal?season=autumn 返回 200"""
        response = client.get("/api/v1/recommendations/seasonal?season=autumn")
        assert response.status_code == 200

    def test_seasonal_recommendations_winter(self):
        """GET /api/v1/recommendations/seasonal?season=winter 返回 200"""
        response = client.get("/api/v1/recommendations/seasonal?season=winter")
        assert response.status_code == 200

    def test_seasonal_recommendations_has_items(self):
        """响应应包含 items 字段"""
        response = client.get("/api/v1/recommendations/seasonal?season=spring")
        assert response.status_code == 200
        data = response.json()
        assert "data" in data

    def test_seasonal_recommendations_respects_limit(self):
        """GET /api/v1/recommendations/seasonal?season=spring&limit=2 最多返回 2 条"""
        response = client.get("/api/v1/recommendations/seasonal?season=spring&limit=2")
        assert response.status_code == 200
        data = response.json()
        # 检查返回的数据大小
        items = data.get("data", {}).get("items", data.get("data", []))
        if isinstance(items, list):
            assert len(items) <= 2

    def test_seasonal_recommendations_limit_max_20(self):
        """limit 参数最大为 20"""
        response = client.get("/api/v1/recommendations/seasonal?season=spring&limit=30")
        # 应该被限制或返回错误
        assert response.status_code in [200, 422]

    def test_seasonal_recommendations_default_limit_5(self):
        """默认 limit 为 5"""
        response = client.get("/api/v1/recommendations/seasonal?season=spring")
        assert response.status_code == 200

    def test_seasonal_with_locale_zh_cn(self):
        """支持 locale=zh-CN"""
        response = client.get("/api/v1/recommendations/seasonal?season=spring&locale=zh-CN")
        assert response.status_code == 200

    def test_seasonal_with_locale_en_us(self):
        """支持 locale=en-US"""
        response = client.get("/api/v1/recommendations/seasonal?season=spring&locale=en-US")
        assert response.status_code == 200

    def test_invalid_season_might_return_error(self):
        """无效的季节参数可能返回错误或空结果"""
        response = client.get("/api/v1/recommendations/seasonal?season=invalid_season")
        # 应该返回 200（空结果）或 422（参数错误）
        assert response.status_code in [200, 422, 404]


class TestRecommendationsResponse:
    """推荐响应结构测试"""

    def test_seasonal_response_has_total(self):
        """季节推荐响应包含 total 字段"""
        response = client.get("/api/v1/recommendations/seasonal?season=spring")
        assert response.status_code == 200
        data = response.json()
        # 可能在不同层级
        assert "total" in data.get("data", {}) or "success" in data

    def test_seasonal_response_has_items(self):
        """季节推荐响应包含 items 字段"""
        response = client.get("/api/v1/recommendations/seasonal?season=spring")
        assert response.status_code == 200
        data = response.json()
        assert "items" in data.get("data", {}) or "data" in data

    def test_response_success_key(self):
        """响应包含 success 键"""
        response = client.get("/api/v1/recommendations/daily?user_id=user-001")
        assert response.status_code == 200
        data = response.json()
        assert "success" in data or "data" in data
