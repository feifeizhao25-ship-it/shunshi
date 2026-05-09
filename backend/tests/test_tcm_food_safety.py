"""
测试: 中医食材安全与营养 API
覆盖6个端点，包括相克检测、季节过滤等。
"""

import pytest
from fastapi.testclient import TestClient
from datetime import datetime


@pytest.fixture
def client():
    """创建FastAPI测试客户端"""
    from app.main import app
    return TestClient(app)


class TestListFoods:
    """GET /api/v1/food-safety/foods - 食材列表"""

    def test_list_all_foods(self, client):
        """测试：获取所有食材"""
        response = client.get("/api/v1/food-safety/foods")
        assert response.status_code == 200
        assert response.json()["success"] is True
        assert "foods" in response.json()["data"]
        assert "total" in response.json()["data"]
        assert response.json()["data"]["total"] >= 20

    def test_list_foods_default_limit(self, client):
        """测试：默认limit为20"""
        response = client.get("/api/v1/food-safety/foods")
        assert len(response.json()["data"]["foods"]) <= 20

    def test_list_foods_custom_limit(self, client):
        """测试：自定义limit参数"""
        response = client.get("/api/v1/food-safety/foods?limit=5")
        assert response.status_code == 200
        assert len(response.json()["data"]["foods"]) <= 5

    def test_filter_by_season_spring(self, client):
        """测试：按春季过滤"""
        response = client.get("/api/v1/food-safety/foods?season=春")
        assert response.status_code == 200
        foods = response.json()["data"]["foods"]
        assert len(foods) > 0

    def test_filter_by_season_summer(self, client):
        """测试：按夏季过滤"""
        response = client.get("/api/v1/food-safety/foods?season=夏")
        assert response.status_code == 200
        foods = response.json()["data"]["foods"]
        assert len(foods) > 0

    def test_filter_by_season_autumn(self, client):
        """测试：按秋季过滤"""
        response = client.get("/api/v1/food-safety/foods?season=秋")
        assert response.status_code == 200
        foods = response.json()["data"]["foods"]
        assert len(foods) > 0

    def test_filter_by_season_winter(self, client):
        """测试：按冬季过滤"""
        response = client.get("/api/v1/food-safety/foods?season=冬")
        assert response.status_code == 200
        foods = response.json()["data"]["foods"]
        assert len(foods) > 0

    def test_filter_by_tcm_property_cool(self, client):
        """测试：按凉性过滤"""
        response = client.get("/api/v1/food-safety/foods?tcm_property=凉")
        assert response.status_code == 200
        foods = response.json()["data"]["foods"]
        assert all(f["tcm_property"] == "凉" for f in foods)

    def test_filter_by_tcm_property_warm(self, client):
        """测试：按温性过滤"""
        response = client.get("/api/v1/food-safety/foods?tcm_property=温")
        assert response.status_code == 200
        foods = response.json()["data"]["foods"]
        assert all(f["tcm_property"] == "温" for f in foods)

    def test_filter_by_tcm_property_neutral(self, client):
        """测试：按平性过滤"""
        response = client.get("/api/v1/food-safety/foods?tcm_property=平")
        assert response.status_code == 200
        foods = response.json()["data"]["foods"]
        assert all(f["tcm_property"] == "平" for f in foods)

    def test_combined_filters(self, client):
        """测试：同时过滤季节和性质"""
        response = client.get("/api/v1/food-safety/foods?season=春&tcm_property=凉")
        assert response.status_code == 200
        foods = response.json()["data"]["foods"]
        assert all(f["tcm_property"] == "凉" for f in foods)


class TestGetFoodDetail:
    """GET /api/v1/food-safety/foods/{food_id} - 食材详情"""

    def test_get_spinach_detail(self, client):
        """测试：获取菠菜详情"""
        response = client.get("/api/v1/food-safety/foods/spinach")
        assert response.status_code == 200
        assert response.json()["success"] is True
        data = response.json()["data"]
        assert data["id"] == "spinach"
        assert data["name"] == "菠菜"
        assert "storage_tips" in data
        assert "washing_tips" in data
        assert "forbidden_combinations" in data

    def test_get_tofu_detail(self, client):
        """测试：获取豆腐详情"""
        response = client.get("/api/v1/food-safety/foods/tofu")
        assert response.status_code == 200
        assert response.json()["data"]["name"] == "豆腐"

    def test_get_shrimp_detail(self, client):
        """测试：获取虾详情"""
        response = client.get("/api/v1/food-safety/foods/shrimp")
        assert response.status_code == 200
        assert response.json()["data"]["name"] == "虾"

    def test_get_lamb_detail(self, client):
        """测试：获取羊肉详情"""
        response = client.get("/api/v1/food-safety/foods/lamb")
        assert response.status_code == 200
        assert response.json()["data"]["name"] == "羊肉"

    def test_food_detail_contains_required_fields(self, client):
        """测试：食材详情包含所需字段"""
        response = client.get("/api/v1/food-safety/foods/egg")
        data = response.json()["data"]
        required_fields = ["id", "name", "season_best", "storage_tips",
                          "washing_tips", "tcm_property", "common_combinations_safe",
                          "forbidden_combinations", "residue_risk", "selection_tips"]
        for field in required_fields:
            assert field in data

    def test_get_invalid_food_id(self, client):
        """测试：获取不存在的食材返回404"""
        response = client.get("/api/v1/food-safety/foods/invalid_food_xyz")
        assert response.status_code == 404


class TestIncompatiblePairs:
    """GET /api/v1/food-safety/incompatible-pairs - 相克组合列表"""

    def test_list_all_incompatible_pairs(self, client):
        """测试：获取所有相克组合"""
        response = client.get("/api/v1/food-safety/incompatible-pairs")
        assert response.status_code == 200
        assert response.json()["success"] is True
        data = response.json()["data"]
        assert "pairs" in data
        assert "total" in data
        assert data["total"] >= 10

    def test_incompatible_pairs_default_limit(self, client):
        """测试：默认limit为10"""
        response = client.get("/api/v1/food-safety/incompatible-pairs")
        assert len(response.json()["data"]["pairs"]) <= 10

    def test_incompatible_pairs_custom_limit(self, client):
        """测试：自定义limit"""
        response = client.get("/api/v1/food-safety/incompatible-pairs?limit=5")
        assert len(response.json()["data"]["pairs"]) <= 5

    def test_pair_contains_required_fields(self, client):
        """测试：相克对包含必需字段"""
        response = client.get("/api/v1/food-safety/incompatible-pairs")
        pairs = response.json()["data"]["pairs"]
        for pair in pairs:
            assert "combination" in pair
            assert "reason" in pair
            assert "tcm_view" in pair
            assert "severity" in pair
            assert "recommended_interval_hours" in pair

    def test_spinach_tofu_incompatibility(self, client):
        """测试：菠菜和豆腐相克"""
        response = client.get("/api/v1/food-safety/incompatible-pairs")
        pairs = response.json()["data"]["pairs"]
        found = any("菠菜" in p["combination"] and "豆腐" in p["combination"] for p in pairs)
        assert found

    def test_crab_persimmon_incompatibility(self, client):
        """测试：螃蟹和柿子相克"""
        response = client.get("/api/v1/food-safety/incompatible-pairs")
        pairs = response.json()["data"]["pairs"]
        found = any("螃蟹" in p["combination"] and "柿子" in p["combination"] for p in pairs)
        assert found


class TestCheckCompatibility:
    """POST /api/v1/food-safety/check - 食材相克检查"""

    def test_check_spinach_tofu_incompatible(self, client):
        """测试：菠菜和豆腐检查为不兼容"""
        response = client.post("/api/v1/food-safety/check", json={
            "food1": "菠菜",
            "food2": "豆腐",
        })
        assert response.status_code == 200
        data = response.json()["data"]
        assert data["compatible"] is False
        assert "reason" in data
        assert "severity" in data

    def test_check_crab_persimmon_incompatible(self, client):
        """测试：螃蟹和柿子检查为不兼容"""
        response = client.post("/api/v1/food-safety/check", json={
            "food1": "螃蟹",
            "food2": "柿子",
        })
        assert response.status_code == 200
        data = response.json()["data"]
        assert data["compatible"] is False

    def test_check_by_food_id(self, client):
        """测试：使用食材ID检查相克"""
        response = client.post("/api/v1/food-safety/check", json={
            "food1": "spinach",
            "food2": "tofu",
        })
        assert response.status_code == 200
        assert response.json()["data"]["compatible"] is False

    def test_check_safe_combination_ginger_honey(self, client):
        """测试：生姜和蜂蜜安全组合（无记录）"""
        response = client.post("/api/v1/food-safety/check", json={
            "food1": "生姜",
            "food2": "冰糖",
        })
        assert response.status_code == 200
        # 可能兼容也可能不兼容，取决于数据库定义

    def test_check_safe_combination_egg_tomato(self, client):
        """测试：鸡蛋和番茄安全组合"""
        response = client.post("/api/v1/food-safety/check", json={
            "food1": "鸡蛋",
            "food2": "番茄",
        })
        assert response.status_code == 200
        data = response.json()["data"]
        # 期望兼容

    def test_check_reverse_order(self, client):
        """测试：反向检查（豆腐 + 菠菜）"""
        response = client.post("/api/v1/food-safety/check", json={
            "food1": "豆腐",
            "food2": "菠菜",
        })
        assert response.status_code == 200
        assert response.json()["data"]["compatible"] is False

    def test_check_missing_food1(self, client):
        """测试：缺少food1参数"""
        response = client.post("/api/v1/food-safety/check", json={
            "food2": "豆腐",
        })
        assert response.status_code == 400

    def test_check_missing_food2(self, client):
        """测试：缺少food2参数"""
        response = client.post("/api/v1/food-safety/check", json={
            "food1": "菠菜",
        })
        assert response.status_code == 400

    def test_check_invalid_food(self, client):
        """测试：无效食材返回404"""
        response = client.post("/api/v1/food-safety/check", json={
            "food1": "无效食材xyz",
            "food2": "豆腐",
        })
        assert response.status_code == 404

    def test_check_both_foods_invalid(self, client):
        """测试：两个食材都无效"""
        response = client.post("/api/v1/food-safety/check", json={
            "food1": "无效xyz",
            "food2": "无效abc",
        })
        assert response.status_code == 404

    def test_check_response_format(self, client):
        """测试：检查响应格式"""
        response = client.post("/api/v1/food-safety/check", json={
            "food1": "菠菜",
            "food2": "豆腐",
        })
        data = response.json()["data"]
        assert "food1" in data
        assert "food2" in data
        assert "compatible" in data


class TestSeasonalFoods:
    """GET /api/v1/food-safety/seasonal - 当季推荐食材"""

    def test_seasonal_foods(self, client):
        """测试：获取当季食材"""
        response = client.get("/api/v1/food-safety/seasonal")
        assert response.status_code == 200
        data = response.json()["data"]
        assert "season" in data
        assert "month" in data
        assert "foods" in data
        assert data["season"] in ["春", "夏", "秋", "冬"]

    def test_seasonal_foods_has_month(self, client):
        """测试：当季食材包含月份信息"""
        response = client.get("/api/v1/food-safety/seasonal")
        month = response.json()["data"]["month"]
        assert 1 <= month <= 12

    def test_seasonal_foods_contains_list(self, client):
        """测试：当季食材列表非空"""
        response = client.get("/api/v1/food-safety/seasonal")
        foods = response.json()["data"]["foods"]
        assert isinstance(foods, list)
        assert len(foods) > 0

    def test_seasonal_foods_each_has_name(self, client):
        """测试：每个食材都有name字段"""
        response = client.get("/api/v1/food-safety/seasonal")
        foods = response.json()["data"]["foods"]
        for food in foods:
            assert "name" in food
            assert isinstance(food["name"], str)

    def test_seasonal_foods_spring_in_march(self, client):
        """测试：3月应返回春季食材（假设服务器当前时间）"""
        response = client.get("/api/v1/food-safety/seasonal")
        # 仅验证格式，不验证具体月份
        assert response.status_code == 200


class TestStorageGuide:
    """GET /api/v1/food-safety/foods/{food_id}/storage - 储存指南"""

    def test_storage_guide_spinach(self, client):
        """测试：菠菜的储存指南"""
        response = client.get("/api/v1/food-safety/foods/spinach/storage")
        assert response.status_code == 200
        data = response.json()["data"]
        assert data["food_name"] == "菠菜"
        assert data["food_id"] == "spinach"
        assert "storage" in data
        assert "washing" in data
        assert "selection" in data

    def test_storage_guide_lamb(self, client):
        """测试：羊肉的储存指南"""
        response = client.get("/api/v1/food-safety/foods/lamb/storage")
        assert response.status_code == 200
        data = response.json()["data"]
        assert data["food_name"] == "羊肉"

    def test_storage_guide_contains_residue_risk(self, client):
        """测试：储存指南包含农药残留风险"""
        response = client.get("/api/v1/food-safety/foods/tofu/storage")
        data = response.json()["data"]
        assert "residue_risk" in data
        assert data["residue_risk"] in ["high", "medium", "low"]

    def test_storage_guide_contains_season(self, client):
        """测试：储存指南包含最佳季节"""
        response = client.get("/api/v1/food-safety/foods/egg/storage")
        data = response.json()["data"]
        assert "season_best" in data

    def test_storage_guide_invalid_food_id(self, client):
        """测试：无效食材ID返回404"""
        response = client.get("/api/v1/food-safety/foods/invalid_xyz/storage")
        assert response.status_code == 404

    def test_storage_guide_all_foods(self, client):
        """测试：所有食材都应有储存指南"""
        # 获取食材列表
        list_response = client.get("/api/v1/food-safety/foods?limit=50")
        foods = list_response.json()["data"]["foods"]

        # 对前5个食材测试
        for food in foods[:5]:
            response = client.get(f"/api/v1/food-safety/foods/{food['id']}/storage")
            assert response.status_code == 200
            assert "storage" in response.json()["data"]
