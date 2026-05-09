"""
顺时 - 养生名言 API 路由测试
test_wisdom.py
"""

import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


class TestDailyWisdom:
    """每日名言端点测试"""

    def test_get_daily_wisdom_returns_200(self):
        """GET /api/v1/wisdom/daily 返回 200"""
        response = client.get("/api/v1/wisdom/daily")
        assert response.status_code == 200

    def test_daily_wisdom_has_data(self):
        """响应包含 data 键"""
        response = client.get("/api/v1/wisdom/daily")
        assert response.status_code == 200
        data = response.json()
        assert "data" in data

    def test_daily_wisdom_has_required_fields(self):
        """每日名言包含所需字段"""
        response = client.get("/api/v1/wisdom/daily")
        assert response.status_code == 200
        data = response.json()
        wisdom = data["data"]
        assert "text" in wisdom
        assert "source" in wisdom
        assert "date" in wisdom

    def test_daily_wisdom_has_season(self):
        """每日名言包含当前季节"""
        response = client.get("/api/v1/wisdom/daily")
        assert response.status_code == 200
        data = response.json()
        assert "season" in data["data"]

    def test_daily_wisdom_has_solar_term(self):
        """每日名言包含当前节气"""
        response = client.get("/api/v1/wisdom/daily")
        assert response.status_code == 200
        data = response.json()
        assert "solar_term" in data["data"]

    def test_daily_wisdom_with_constitution(self):
        """GET /api/v1/wisdom/daily?constitution=qixu 按体质返回名言"""
        response = client.get("/api/v1/wisdom/daily?constitution=qixu")
        assert response.status_code == 200
        data = response.json()
        assert "text" in data["data"]

    def test_daily_wisdom_with_category(self):
        """GET /api/v1/wisdom/daily?category=diet 按分类返回名言"""
        response = client.get("/api/v1/wisdom/daily?category=diet")
        assert response.status_code == 200
        data = response.json()
        assert "text" in data["data"]

    def test_daily_wisdom_deterministic(self):
        """同一天应该返回相同的名言"""
        response1 = client.get("/api/v1/wisdom/daily")
        response2 = client.get("/api/v1/wisdom/daily")
        assert response1.status_code == 200
        assert response2.status_code == 200
        data1 = response1.json()
        data2 = response2.json()
        assert data1["data"]["text"] == data2["data"]["text"]

    def test_daily_wisdom_different_constitutions(self):
        """不同体质可能返回不同名言"""
        response1 = client.get("/api/v1/wisdom/daily?constitution=qixu")
        response2 = client.get("/api/v1/wisdom/daily?constitution=yangxu")
        assert response1.status_code == 200
        assert response2.status_code == 200


class TestWisdomCollection:
    """养生名言集合端点测试"""

    def test_get_collection_returns_200(self):
        """GET /api/v1/wisdom/collection 返回 200"""
        response = client.get("/api/v1/wisdom/collection")
        assert response.status_code == 200

    def test_collection_has_items(self):
        """响应包含 items 列表"""
        response = client.get("/api/v1/wisdom/collection")
        assert response.status_code == 200
        data = response.json()
        assert "items" in data["data"]
        assert isinstance(data["data"]["items"], list)

    def test_collection_has_total(self):
        """响应包含 total 字段"""
        response = client.get("/api/v1/wisdom/collection")
        assert response.status_code == 200
        data = response.json()
        assert "total" in data["data"]

    def test_collection_has_pagination(self):
        """响应包含分页信息"""
        response = client.get("/api/v1/wisdom/collection")
        assert response.status_code == 200
        data = response.json()
        assert "limit" in data["data"]
        assert "offset" in data["data"]

    def test_collection_filter_by_category(self):
        """GET /api/v1/wisdom/collection?category=diet 按分类筛选"""
        response = client.get("/api/v1/wisdom/collection?category=diet")
        assert response.status_code == 200
        data = response.json()
        assert "items" in data["data"]

    def test_collection_filter_by_constitution(self):
        """GET /api/v1/wisdom/collection?constitution=qixu 按体质筛选"""
        response = client.get("/api/v1/wisdom/collection?constitution=qixu")
        assert response.status_code == 200
        data = response.json()
        assert "items" in data["data"]

    def test_collection_with_limit(self):
        """GET /api/v1/wisdom/collection?limit=5 限制返回数量"""
        response = client.get("/api/v1/wisdom/collection?limit=5")
        assert response.status_code == 200
        data = response.json()
        assert len(data["data"]["items"]) <= 5

    def test_collection_with_offset(self):
        """GET /api/v1/wisdom/collection?offset=10 支持分页"""
        response = client.get("/api/v1/wisdom/collection?offset=10&limit=5")
        assert response.status_code == 200

    def test_collection_item_has_text(self):
        """集合中的项包含 text 字段"""
        response = client.get("/api/v1/wisdom/collection?limit=1")
        assert response.status_code == 200
        data = response.json()
        if len(data["data"]["items"]) > 0:
            item = data["data"]["items"][0]
            assert "text" in item

    def test_collection_item_has_source(self):
        """集合中的项包含 source 字段"""
        response = client.get("/api/v1/wisdom/collection?limit=1")
        assert response.status_code == 200
        data = response.json()
        if len(data["data"]["items"]) > 0:
            item = data["data"]["items"][0]
            assert "source" in item


class TestWisdomCategories:
    """养生名言分类端点测试"""

    def test_get_categories_returns_200(self):
        """GET /api/v1/wisdom/categories 返回 200"""
        response = client.get("/api/v1/wisdom/categories")
        assert response.status_code == 200

    def test_categories_has_data(self):
        """响应包含 data 键"""
        response = client.get("/api/v1/wisdom/categories")
        assert response.status_code == 200
        data = response.json()
        assert "data" in data

    def test_categories_is_dict(self):
        """分类数据是字典"""
        response = client.get("/api/v1/wisdom/categories")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data["data"], dict)

    def test_categories_include_diet(self):
        """分类包含饮食养生"""
        response = client.get("/api/v1/wisdom/categories")
        assert response.status_code == 200
        data = response.json()
        assert "diet" in data["data"]

    def test_categories_include_exercise(self):
        """分类包含运动养生"""
        response = client.get("/api/v1/wisdom/categories")
        assert response.status_code == 200
        data = response.json()
        assert "exercise" in data["data"]

    def test_categories_include_sleep(self):
        """分类包含睡眠养生"""
        response = client.get("/api/v1/wisdom/categories")
        assert response.status_code == 200
        data = response.json()
        assert "sleep" in data["data"]

    def test_categories_include_emotion(self):
        """分类包含情志养生"""
        response = client.get("/api/v1/wisdom/categories")
        assert response.status_code == 200
        data = response.json()
        assert "emotion" in data["data"]

    def test_categories_include_season(self):
        """分类包含四季养生"""
        response = client.get("/api/v1/wisdom/categories")
        assert response.status_code == 200
        data = response.json()
        assert "season" in data["data"]

    def test_category_has_count(self):
        """分类包含名言数量"""
        response = client.get("/api/v1/wisdom/categories")
        assert response.status_code == 200
        data = response.json()
        if "diet" in data["data"]:
            category = data["data"]["diet"]
            assert "count" in category or "name" in category

    def test_category_has_name(self):
        """分类包含名称"""
        response = client.get("/api/v1/wisdom/categories")
        assert response.status_code == 200
        data = response.json()
        if "diet" in data["data"]:
            category = data["data"]["diet"]
            assert "name" in category

    def test_category_count_greater_than_zero(self):
        """分类数量应该大于 0"""
        response = client.get("/api/v1/wisdom/categories")
        assert response.status_code == 200
        data = response.json()
        if "diet" in data["data"]:
            category = data["data"]["diet"]
            if "count" in category:
                assert category["count"] > 0


class TestWisdomByCategory:
    """按分类获取名言端点测试"""

    def test_get_diet_wisdom(self):
        """GET /api/v1/wisdom/collection?category=diet 返回 200"""
        response = client.get("/api/v1/wisdom/collection?category=diet")
        assert response.status_code == 200

    def test_get_exercise_wisdom(self):
        """GET /api/v1/wisdom/collection?category=exercise 返回 200"""
        response = client.get("/api/v1/wisdom/collection?category=exercise")
        assert response.status_code == 200

    def test_get_sleep_wisdom(self):
        """GET /api/v1/wisdom/collection?category=sleep 返回 200"""
        response = client.get("/api/v1/wisdom/collection?category=sleep")
        assert response.status_code == 200

    def test_get_emotion_wisdom(self):
        """GET /api/v1/wisdom/collection?category=emotion 返回 200"""
        response = client.get("/api/v1/wisdom/collection?category=emotion")
        assert response.status_code == 200

    def test_get_season_wisdom(self):
        """GET /api/v1/wisdom/collection?category=season 返回 200"""
        response = client.get("/api/v1/wisdom/collection?category=season")
        assert response.status_code == 200

    def test_get_general_wisdom(self):
        """GET /api/v1/wisdom/collection?category=general 返回 200"""
        response = client.get("/api/v1/wisdom/collection?category=general")
        assert response.status_code == 200

    def test_category_filter_returns_items(self):
        """分类筛选应该返回相关名言"""
        response = client.get("/api/v1/wisdom/collection?category=diet&limit=1")
        assert response.status_code == 200
        data = response.json()
        if len(data["data"]["items"]) > 0:
            assert "text" in data["data"]["items"][0]


class TestWisdomByConstitution:
    """按体质获取名言端点测试"""

    def test_get_pinghe_wisdom(self):
        """GET /api/v1/wisdom/collection?constitution=pinghe 返回 200"""
        response = client.get("/api/v1/wisdom/collection?constitution=pinghe")
        assert response.status_code == 200

    def test_get_qixu_wisdom(self):
        """GET /api/v1/wisdom/collection?constitution=qixu 返回 200"""
        response = client.get("/api/v1/wisdom/collection?constitution=qixu")
        assert response.status_code == 200

    def test_get_yangxu_wisdom(self):
        """GET /api/v1/wisdom/collection?constitution=yangxu 返回 200"""
        response = client.get("/api/v1/wisdom/collection?constitution=yangxu")
        assert response.status_code == 200

    def test_get_yinxu_wisdom(self):
        """GET /api/v1/wisdom/collection?constitution=yinxu 返回 200"""
        response = client.get("/api/v1/wisdom/collection?constitution=yinxu")
        assert response.status_code == 200

    def test_constitution_filter_returns_items(self):
        """体质筛选应该返回相关名言"""
        response = client.get("/api/v1/wisdom/collection?constitution=qixu&limit=1")
        assert response.status_code == 200
        data = response.json()
        if len(data["data"]["items"]) > 0:
            assert "text" in data["data"]["items"][0]
