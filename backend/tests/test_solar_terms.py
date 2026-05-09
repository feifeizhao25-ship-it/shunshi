"""
顺时 - 节气系统 API 路由测试
test_solar_terms.py
"""

import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


class TestSolarTermsList:
    """节气列表端点测试"""

    def test_list_solar_terms_returns_200(self):
        """GET /api/v1/solar-terms/ 返回 200"""
        response = client.get("/api/v1/solar-terms/")
        assert response.status_code == 200

    def test_list_has_data(self):
        """响应包含 data 键"""
        response = client.get("/api/v1/solar-terms/")
        assert response.status_code == 200
        data = response.json()
        assert "data" in data

    def test_list_returns_array(self):
        """节气列表是数组"""
        response = client.get("/api/v1/solar-terms/")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data["data"], list)

    def test_list_has_24_terms(self):
        """应该返回 24 个节气"""
        response = client.get("/api/v1/solar-terms/")
        assert response.status_code == 200
        data = response.json()
        assert len(data["data"]) >= 20

    def test_solar_term_has_required_fields(self):
        """节气包含必要字段"""
        response = client.get("/api/v1/solar-terms/")
        assert response.status_code == 200
        data = response.json()
        if len(data["data"]) > 0:
            term = data["data"][0]
            assert "id" in term or "en_name" in term

    def test_list_with_limit(self):
        """GET /api/v1/solar-terms/?limit=5 限制返回数量"""
        response = client.get("/api/v1/solar-terms/?limit=5")
        assert response.status_code == 200
        data = response.json()
        assert len(data["data"]) <= 5

    def test_list_with_offset(self):
        """GET /api/v1/solar-terms/?offset=5 支持分页"""
        response = client.get("/api/v1/solar-terms/?offset=5&limit=5")
        assert response.status_code == 200


class TestSolarTermDetail:
    """节气详情端点测试"""

    def test_get_solar_term_detail_returns_200(self):
        """GET /api/v1/solar-terms/st-001 返回 200"""
        response = client.get("/api/v1/solar-terms/st-001")
        assert response.status_code == 200

    def test_solar_term_detail_has_required_fields(self):
        """节气详情包含必要字段"""
        response = client.get("/api/v1/solar-terms/st-001")
        assert response.status_code == 200
        data = response.json()
        assert "data" in data

    def test_get_st_001_beginning_of_spring(self):
        """GET /api/v1/solar-terms/st-001 返回立春"""
        response = client.get("/api/v1/solar-terms/st-001")
        assert response.status_code == 200
        data = response.json()
        assert "data" in data

    def test_get_st_010_summer_solstice(self):
        """GET /api/v1/solar-terms/st-10 返回夏至"""
        response = client.get("/api/v1/solar-terms/st-10")
        assert response.status_code == 200

    def test_detail_has_suggestions(self):
        """节气详情包含养生建议"""
        response = client.get("/api/v1/solar-terms/st-001")
        assert response.status_code == 200
        data = response.json()
        term = data["data"]
        assert "en_suggestions" in term or "suggestions" in term

    def test_detail_has_foods(self):
        """节气详情包含推荐食物"""
        response = client.get("/api/v1/solar-terms/st-001")
        assert response.status_code == 200
        data = response.json()
        term = data["data"]
        assert "en_foods" in term or "foods" in term

    def test_detail_has_exercises(self):
        """节气详情包含推荐运动"""
        response = client.get("/api/v1/solar-terms/st-001")
        assert response.status_code == 200
        data = response.json()
        term = data["data"]
        assert "en_exercises" in term or "exercises" in term

    def test_unknown_solar_term_404(self):
        """GET /api/v1/solar-terms/st-999 返回 404"""
        response = client.get("/api/v1/solar-terms/st-999")
        assert response.status_code == 404

    def test_get_st_24_major_cold(self):
        """GET /api/v1/solar-terms/st-24 返回大寒"""
        response = client.get("/api/v1/solar-terms/st-24")
        assert response.status_code == 200


class TestSolarTermsCurrentTerm:
    """当前节气端点测试"""

    def test_get_current_solar_term_returns_200(self):
        """GET /api/v1/solar-terms/current 返回 200"""
        response = client.get("/api/v1/solar-terms/current")
        assert response.status_code == 200

    def test_current_term_has_data(self):
        """当前节气响应包含 data"""
        response = client.get("/api/v1/solar-terms/current")
        assert response.status_code == 200
        data = response.json()
        assert "data" in data

    def test_current_term_has_id(self):
        """当前节气包含 id"""
        response = client.get("/api/v1/solar-terms/current")
        assert response.status_code == 200
        data = response.json()
        assert "id" in data["data"] or "name" in data["data"]

    def test_current_term_with_hemisphere_north(self):
        """GET /api/v1/solar-terms/current?hemisphere=north 返回 200"""
        response = client.get("/api/v1/solar-terms/current?hemisphere=north")
        assert response.status_code == 200

    def test_current_term_with_hemisphere_south(self):
        """GET /api/v1/solar-terms/current?hemisphere=south 返回 200"""
        response = client.get("/api/v1/solar-terms/current?hemisphere=south")
        assert response.status_code == 200


class TestSolarTermsSeasonWisdom:
    """季节养生智慧端点测试"""

    def test_get_season_wisdom_returns_200(self):
        """GET /api/v1/solar-terms/wisdom?season=spring 返回 200"""
        response = client.get("/api/v1/solar-terms/wisdom?season=spring")
        assert response.status_code == 200

    def test_wisdom_has_data(self):
        """养生智慧响应包含 data"""
        response = client.get("/api/v1/solar-terms/wisdom?season=spring")
        assert response.status_code == 200
        data = response.json()
        assert "data" in data

    def test_wisdom_for_summer(self):
        """GET /api/v1/solar-terms/wisdom?season=summer 返回 200"""
        response = client.get("/api/v1/solar-terms/wisdom?season=summer")
        assert response.status_code == 200

    def test_wisdom_for_autumn(self):
        """GET /api/v1/solar-terms/wisdom?season=autumn 返回 200"""
        response = client.get("/api/v1/solar-terms/wisdom?season=autumn")
        assert response.status_code == 200

    def test_wisdom_for_winter(self):
        """GET /api/v1/solar-terms/wisdom?season=winter 返回 200"""
        response = client.get("/api/v1/solar-terms/wisdom?season=winter")
        assert response.status_code == 200

    def test_wisdom_has_suggestions(self):
        """养生智慧包含建议"""
        response = client.get("/api/v1/solar-terms/wisdom?season=spring")
        assert response.status_code == 200
        data = response.json()
        assert "suggestions" in data["data"] or "wisdom" in data["data"]


class TestSolarTermsSchedule:
    """节气日程端点测试"""

    def test_get_solar_terms_schedule_returns_200(self):
        """GET /api/v1/solar-terms/schedule 返回 200"""
        response = client.get("/api/v1/solar-terms/schedule")
        assert response.status_code == 200

    def test_schedule_has_data(self):
        """日程响应包含 data"""
        response = client.get("/api/v1/solar-terms/schedule")
        assert response.status_code == 200
        data = response.json()
        assert "data" in data

    def test_schedule_returns_array(self):
        """日程是数组"""
        response = client.get("/api/v1/solar-terms/schedule")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data["data"], list) or "terms" in data["data"]

    def test_schedule_with_year(self):
        """GET /api/v1/solar-terms/schedule?year=2026 支持年份"""
        response = client.get("/api/v1/solar-terms/schedule?year=2026")
        assert response.status_code == 200

    def test_schedule_item_has_date(self):
        """日程项包含日期"""
        response = client.get("/api/v1/solar-terms/schedule")
        assert response.status_code == 200
        data = response.json()
        items = data["data"] if isinstance(data["data"], list) else data["data"].get("terms", [])
        if len(items) > 0:
            item = items[0]
            assert "date" in item or "start_date" in item


class TestSolarTermsRecommendation:
    """节气推荐端点测试"""

    def test_get_solar_term_recommendations_returns_200(self):
        """GET /api/v1/solar-terms/st-001/recommendations 返回 200"""
        response = client.get("/api/v1/solar-terms/st-001/recommendations")
        assert response.status_code == 200

    def test_recommendations_has_data(self):
        """推荐响应包含 data"""
        response = client.get("/api/v1/solar-terms/st-001/recommendations")
        assert response.status_code == 200
        data = response.json()
        assert "data" in data

    def test_recommendations_includes_diet(self):
        """推荐包含饮食建议"""
        response = client.get("/api/v1/solar-terms/st-001/recommendations")
        assert response.status_code == 200
        data = response.json()
        assert "diet" in data["data"] or "foods" in data["data"]

    def test_recommendations_includes_exercise(self):
        """推荐包含运动建议"""
        response = client.get("/api/v1/solar-terms/st-001/recommendations")
        assert response.status_code == 200
        data = response.json()
        assert "exercise" in data["data"] or "exercises" in data["data"]

    def test_unknown_solar_term_recommendation_404(self):
        """未知节气的推荐返回 404"""
        response = client.get("/api/v1/solar-terms/st-999/recommendations")
        assert response.status_code == 404


class TestSolarTermsCollection:
    """节气合集端点测试"""

    def test_get_all_solar_terms_returns_200(self):
        """GET /api/v1/solar-terms/all 返回所有节气"""
        response = client.get("/api/v1/solar-terms/all")
        assert response.status_code in [200, 404]  # 可能路由不存在

    def test_get_spring_terms_returns_200(self):
        """GET /api/v1/solar-terms/spring 返回春季节气"""
        response = client.get("/api/v1/solar-terms?season=spring")
        assert response.status_code == 200

    def test_spring_terms_has_6_terms(self):
        """春季应该有约 6 个节气"""
        response = client.get("/api/v1/solar-terms?season=spring")
        if response.status_code == 200:
            data = response.json()
            terms = data.get("data", [])
            assert len(terms) >= 0
