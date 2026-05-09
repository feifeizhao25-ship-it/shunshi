"""
食疗方剂 API 测试套件
覆盖所有端点、筛选条件、边界情况与错误处理。
"""

import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


# ─────────────────────────────────────────────────────────────────────────────
# 基础端点测试
# ─────────────────────────────────────────────────────────────────────────────

class TestListRecipes:
    """GET /api/v1/recipes/ 列表端点测试"""

    def test_list_recipes_success(self):
        """成功获取食疗方剂列表"""
        response = client.get("/api/v1/recipes/")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "data" in data
        assert "recipes" in data["data"]
        assert "total" in data["data"]
        assert len(data["data"]["recipes"]) > 0

    def test_list_recipes_default_limit(self):
        """默认限制为 10 条"""
        response = client.get("/api/v1/recipes/")
        data = response.json()
        assert len(data["data"]["recipes"]) <= 10

    def test_list_recipes_custom_limit(self):
        """自定义 limit 参数"""
        response = client.get("/api/v1/recipes/?limit=5")
        data = response.json()
        assert len(data["data"]["recipes"]) <= 5

    def test_list_recipes_limit_max(self):
        """limit 最多 20"""
        response = client.get("/api/v1/recipes/?limit=20")
        data = response.json()
        assert len(data["data"]["recipes"]) <= 20

    def test_list_recipes_limit_exceed_max(self):
        """limit 超过最大值返回 422"""
        response = client.get("/api/v1/recipes/?limit=25")
        assert response.status_code == 422

    def test_list_recipes_limit_zero(self):
        """limit 为 0 返回 422"""
        response = client.get("/api/v1/recipes/?limit=0")
        assert response.status_code == 422

    def test_list_recipes_all_have_required_fields(self):
        """每个食疗方都有必需字段"""
        response = client.get("/api/v1/recipes/")
        data = response.json()
        required_fields = ["id", "name", "name_en", "category", "seasons", "constitution_types"]
        for recipe in data["data"]["recipes"]:
            for field in required_fields:
                assert field in recipe

    def test_list_recipes_response_structure(self):
        """响应结构符合规范"""
        response = client.get("/api/v1/recipes/")
        data = response.json()
        assert "success" in data
        assert "data" in data
        assert isinstance(data["success"], bool)
        assert isinstance(data["data"], dict)


# ─────────────────────────────────────────────────────────────────────────────
# 季节筛选测试
# ─────────────────────────────────────────────────────────────────────────────

class TestListRecipesBySeason:
    """按季节筛选食疗方"""

    def test_filter_by_spring(self):
        """筛选春季食疗"""
        response = client.get("/api/v1/recipes/?season=spring")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        recipes = data["data"]["recipes"]
        for recipe in recipes:
            assert "spring" in recipe["seasons"]

    def test_filter_by_summer(self):
        """筛选夏季食疗"""
        response = client.get("/api/v1/recipes/?season=summer")
        assert response.status_code == 200
        recipes = response.json()["data"]["recipes"]
        for recipe in recipes:
            assert "summer" in recipe["seasons"]

    def test_filter_by_autumn(self):
        """筛选秋季食疗"""
        response = client.get("/api/v1/recipes/?season=autumn")
        assert response.status_code == 200
        recipes = response.json()["data"]["recipes"]
        for recipe in recipes:
            assert "autumn" in recipe["seasons"]

    def test_filter_by_winter(self):
        """筛选冬季食疗"""
        response = client.get("/api/v1/recipes/?season=winter")
        assert response.status_code == 200
        recipes = response.json()["data"]["recipes"]
        for recipe in recipes:
            assert "winter" in recipe["seasons"]

    def test_filter_by_invalid_season(self):
        """无效季节返回空列表"""
        response = client.get("/api/v1/recipes/?season=invalid_season")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["total"] == 0


# ─────────────────────────────────────────────────────────────────────────────
# 体质筛选测试
# ─────────────────────────────────────────────────────────────────────────────

class TestListRecipesByConstitution:
    """按体质筛选食疗方"""

    def test_filter_by_qi_deficiency(self):
        """筛选气虚食疗"""
        response = client.get("/api/v1/recipes/?constitution=qi_deficiency")
        assert response.status_code == 200
        recipes = response.json()["data"]["recipes"]
        for recipe in recipes:
            assert "qi_deficiency" in recipe["constitution_types"]

    def test_filter_by_yang_deficiency(self):
        """筛选阳虚食疗"""
        response = client.get("/api/v1/recipes/?constitution=yang_deficiency")
        assert response.status_code == 200
        recipes = response.json()["data"]["recipes"]
        for recipe in recipes:
            assert "yang_deficiency" in recipe["constitution_types"]

    def test_filter_by_yin_deficiency(self):
        """筛选阴虚食疗"""
        response = client.get("/api/v1/recipes/?constitution=yin_deficiency")
        assert response.status_code == 200
        recipes = response.json()["data"]["recipes"]
        for recipe in recipes:
            assert "yin_deficiency" in recipe["constitution_types"]

    def test_filter_by_blood_deficiency(self):
        """筛选血虚食疗"""
        response = client.get("/api/v1/recipes/?constitution=blood_deficiency")
        assert response.status_code == 200
        recipes = response.json()["data"]["recipes"]
        for recipe in recipes:
            assert "blood_deficiency" in recipe["constitution_types"]

    def test_filter_by_damp(self):
        """筛选湿气食疗"""
        response = client.get("/api/v1/recipes/?constitution=damp")
        assert response.status_code == 200
        recipes = response.json()["data"]["recipes"]
        for recipe in recipes:
            assert "damp" in recipe["constitution_types"]

    def test_filter_by_damp_heat(self):
        """筛选湿热食疗"""
        response = client.get("/api/v1/recipes/?constitution=damp_heat")
        assert response.status_code == 200
        recipes = response.json()["data"]["recipes"]
        for recipe in recipes:
            assert "damp_heat" in recipe["constitution_types"]

    def test_filter_by_qi_stagnation(self):
        """筛选气郁食疗"""
        response = client.get("/api/v1/recipes/?constitution=qi_stagnation")
        assert response.status_code == 200
        recipes = response.json()["data"]["recipes"]
        for recipe in recipes:
            assert "qi_stagnation" in recipe["constitution_types"]

    def test_filter_by_blood_stasis(self):
        """筛选血瘀食疗"""
        response = client.get("/api/v1/recipes/?constitution=blood_stasis")
        assert response.status_code == 200
        recipes = response.json()["data"]["recipes"]
        for recipe in recipes:
            assert "blood_stasis" in recipe["constitution_types"]

    def test_filter_by_invalid_constitution(self):
        """无效体质返回空列表"""
        response = client.get("/api/v1/recipes/?constitution=invalid_constitution")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["total"] == 0


# ─────────────────────────────────────────────────────────────────────────────
# 分类筛选测试
# ─────────────────────────────────────────────────────────────────────────────

class TestListRecipesByCategory:
    """按分类筛选食疗方"""

    def test_filter_by_porridge(self):
        """筛选粥类"""
        response = client.get("/api/v1/recipes/?category=粥")
        assert response.status_code == 200
        recipes = response.json()["data"]["recipes"]
        for recipe in recipes:
            assert recipe["category"] == "粥"

    def test_filter_by_soup(self):
        """筛选汤类"""
        response = client.get("/api/v1/recipes/?category=汤")
        assert response.status_code == 200
        recipes = response.json()["data"]["recipes"]
        for recipe in recipes:
            assert recipe["category"] == "汤"

    def test_filter_by_dish(self):
        """筛选菜类"""
        response = client.get("/api/v1/recipes/?category=菜")
        assert response.status_code == 200
        recipes = response.json()["data"]["recipes"]
        for recipe in recipes:
            assert recipe["category"] == "菜"

    def test_filter_by_tea(self):
        """筛选茶类（目前为空）"""
        response = client.get("/api/v1/recipes/?category=茶")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["total"] == 0

    def test_filter_by_invalid_category(self):
        """无效分类返回空列表"""
        response = client.get("/api/v1/recipes/?category=无效分类")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["total"] == 0


# ─────────────────────────────────────────────────────────────────────────────
# 难度筛选测试
# ─────────────────────────────────────────────────────────────────────────────

class TestListRecipesByDifficulty:
    """按难度筛选食疗方"""

    def test_filter_by_easy(self):
        """筛选简单食疗"""
        response = client.get("/api/v1/recipes/?difficulty=easy")
        assert response.status_code == 200
        recipes = response.json()["data"]["recipes"]
        for recipe in recipes:
            assert recipe["difficulty"] == "easy"

    def test_filter_by_medium(self):
        """筛选中等难度食疗"""
        response = client.get("/api/v1/recipes/?difficulty=medium")
        assert response.status_code == 200
        recipes = response.json()["data"]["recipes"]
        for recipe in recipes:
            assert recipe["difficulty"] == "medium"

    def test_filter_by_invalid_difficulty(self):
        """无效难度返回空列表"""
        response = client.get("/api/v1/recipes/?difficulty=invalid_difficulty")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["total"] == 0


# ─────────────────────────────────────────────────────────────────────────────
# 组合筛选测试
# ─────────────────────────────────────────────────────────────────────────────

class TestCombinedFilters:
    """组合多个筛选条件"""

    def test_filter_by_season_and_constitution(self):
        """按季节和体质同时筛选"""
        response = client.get("/api/v1/recipes/?season=summer&constitution=damp_heat")
        assert response.status_code == 200
        recipes = response.json()["data"]["recipes"]
        for recipe in recipes:
            assert "summer" in recipe["seasons"]
            assert "damp_heat" in recipe["constitution_types"]

    def test_filter_by_season_and_category(self):
        """按季节和分类同时筛选"""
        response = client.get("/api/v1/recipes/?season=winter&category=汤")
        assert response.status_code == 200
        recipes = response.json()["data"]["recipes"]
        for recipe in recipes:
            assert "winter" in recipe["seasons"]
            assert recipe["category"] == "汤"

    def test_filter_by_all_parameters(self):
        """组合所有筛选参数"""
        response = client.get("/api/v1/recipes/?season=winter&constitution=yang_deficiency&category=汤&difficulty=medium")
        assert response.status_code == 200
        recipes = response.json()["data"]["recipes"]
        for recipe in recipes:
            assert "winter" in recipe["seasons"]
            assert "yang_deficiency" in recipe["constitution_types"]
            assert recipe["category"] == "汤"
            assert recipe["difficulty"] == "medium"

    def test_filter_by_season_category_difficulty(self):
        """按季节、分类、难度筛选"""
        response = client.get("/api/v1/recipes/?season=spring&category=菜&difficulty=easy")
        assert response.status_code == 200
        recipes = response.json()["data"]["recipes"]
        for recipe in recipes:
            assert "spring" in recipe["seasons"]
            assert recipe["category"] == "菜"
            assert recipe["difficulty"] == "easy"


# ─────────────────────────────────────────────────────────────────────────────
# 今日推荐端点测试
# ─────────────────────────────────────────────────────────────────────────────

class TestDailyRecipes:
    """GET /api/v1/recipes/daily 今日推荐端点"""

    def test_daily_recipes_success(self):
        """成功获取今日推荐"""
        response = client.get("/api/v1/recipes/daily")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "data" in data

    def test_daily_recipes_has_required_fields(self):
        """今日推荐包含必需字段"""
        response = client.get("/api/v1/recipes/daily")
        data = response.json()["data"]
        assert "season" in data
        assert "date" in data
        assert "seasonal_note" in data
        assert "recommended_recipes" in data
        assert "tip" in data

    def test_daily_recipes_season_valid(self):
        """季节值有效"""
        response = client.get("/api/v1/recipes/daily")
        data = response.json()["data"]
        valid_seasons = ["spring", "summer", "autumn", "winter"]
        assert data["season"] in valid_seasons

    def test_daily_recipes_recommended_count(self):
        """推荐 2-3 个食疗"""
        response = client.get("/api/v1/recipes/daily")
        data = response.json()["data"]
        assert 2 <= len(data["recommended_recipes"]) <= 3

    def test_daily_recipes_with_constitution(self):
        """带体质参数的推荐"""
        response = client.get("/api/v1/recipes/daily?constitution=qi_deficiency")
        assert response.status_code == 200
        data = response.json()["data"]
        assert "recommended_recipes" in data

    def test_daily_recipes_hemisphere_north(self):
        """北半球季节计算"""
        response = client.get("/api/v1/recipes/daily?hemisphere=north")
        assert response.status_code == 200
        assert response.json()["data"]["season"] in ["spring", "summer", "autumn", "winter"]

    def test_daily_recipes_hemisphere_south(self):
        """南半球季节计算"""
        response = client.get("/api/v1/recipes/daily?hemisphere=south")
        assert response.status_code == 200
        assert response.json()["data"]["season"] in ["spring", "summer", "autumn", "winter"]

    def test_daily_recipes_invalid_constitution_ignored(self):
        """无效体质被忽略"""
        response = client.get("/api/v1/recipes/daily?constitution=invalid")
        assert response.status_code == 200
        data = response.json()["data"]
        assert len(data["recommended_recipes"]) > 0


# ─────────────────────────────────────────────────────────────────────────────
# 体质专属方案端点测试
# ─────────────────────────────────────────────────────────────────────────────

class TestConstitutionRecipes:
    """GET /api/v1/recipes/constitution/{type} 体质方案端点"""

    def test_constitution_qi_deficiency(self):
        """气虚体质方案"""
        response = client.get("/api/v1/recipes/constitution/qi_deficiency")
        assert response.status_code == 200
        data = response.json()["data"]
        assert data["constitution"] == "qi_deficiency"
        assert "recipes" in data
        assert "note" in data
        assert "schedule" in data

    def test_constitution_yang_deficiency(self):
        """阳虚体质方案"""
        response = client.get("/api/v1/recipes/constitution/yang_deficiency")
        assert response.status_code == 200
        assert response.json()["data"]["constitution"] == "yang_deficiency"

    def test_constitution_yin_deficiency(self):
        """阴虚体质方案"""
        response = client.get("/api/v1/recipes/constitution/yin_deficiency")
        assert response.status_code == 200
        assert response.json()["data"]["constitution"] == "yin_deficiency"

    def test_constitution_blood_deficiency(self):
        """血虚体质方案"""
        response = client.get("/api/v1/recipes/constitution/blood_deficiency")
        assert response.status_code == 200
        assert response.json()["data"]["constitution"] == "blood_deficiency"

    def test_constitution_damp(self):
        """湿气体质方案"""
        response = client.get("/api/v1/recipes/constitution/damp")
        assert response.status_code == 200
        assert response.json()["data"]["constitution"] == "damp"

    def test_constitution_damp_heat(self):
        """湿热体质方案"""
        response = client.get("/api/v1/recipes/constitution/damp_heat")
        assert response.status_code == 200
        assert response.json()["data"]["constitution"] == "damp_heat"

    def test_constitution_qi_stagnation(self):
        """气郁体质方案"""
        response = client.get("/api/v1/recipes/constitution/qi_stagnation")
        assert response.status_code == 200
        assert response.json()["data"]["constitution"] == "qi_stagnation"

    def test_constitution_blood_stasis(self):
        """血瘀体质方案"""
        response = client.get("/api/v1/recipes/constitution/blood_stasis")
        assert response.status_code == 200
        assert response.json()["data"]["constitution"] == "blood_stasis"

    def test_constitution_heat(self):
        """热性体质方案"""
        response = client.get("/api/v1/recipes/constitution/heat")
        assert response.status_code == 200
        assert response.json()["data"]["constitution"] == "heat"

    def test_constitution_balanced(self):
        """平和体质方案"""
        response = client.get("/api/v1/recipes/constitution/balanced")
        assert response.status_code == 200
        assert response.json()["data"]["constitution"] == "balanced"

    def test_constitution_invalid_404(self):
        """无效体质返回 404"""
        response = client.get("/api/v1/recipes/constitution/invalid_constitution")
        assert response.status_code == 404

    def test_constitution_invalid_error_message(self):
        """404 错误消息包含有效体质列表"""
        response = client.get("/api/v1/recipes/constitution/invalid_constitution")
        data = response.json()
        assert "detail" in data
        assert "Valid types" in data["detail"]

    def test_constitution_has_schedule(self):
        """体质方案包含食用周期"""
        response = client.get("/api/v1/recipes/constitution/qi_deficiency")
        data = response.json()["data"]
        schedule = data["schedule"]
        assert "monday" in schedule or "note" in schedule
        assert "note" in schedule


# ─────────────────────────────────────────────────────────────────────────────
# 季节特色食疗端点测试
# ─────────────────────────────────────────────────────────────────────────────

class TestSeasonalRecipes:
    """GET /api/v1/recipes/seasonal 季节特色端点"""

    def test_seasonal_recipes_success(self):
        """成功获取季节特色"""
        response = client.get("/api/v1/recipes/seasonal")
        assert response.status_code == 200
        data = response.json()["data"]
        assert "season" in data
        assert "seasonal_theme" in data
        assert "tcm_principle" in data
        assert "caution" in data
        assert "recipes" in data

    def test_seasonal_recipes_has_theme(self):
        """季节方案包含主题"""
        response = client.get("/api/v1/recipes/seasonal")
        data = response.json()["data"]
        assert len(data["seasonal_theme"]) > 0

    def test_seasonal_recipes_has_principle(self):
        """季节方案包含中医原理"""
        response = client.get("/api/v1/recipes/seasonal")
        data = response.json()["data"]
        assert len(data["tcm_principle"]) > 0

    def test_seasonal_recipes_has_caution(self):
        """季节方案包含注意事项"""
        response = client.get("/api/v1/recipes/seasonal")
        data = response.json()["data"]
        assert len(data["caution"]) > 0

    def test_seasonal_recipes_hemisphere_north(self):
        """北半球季节"""
        response = client.get("/api/v1/recipes/seasonal?hemisphere=north")
        assert response.status_code == 200

    def test_seasonal_recipes_hemisphere_south(self):
        """南半球季节"""
        response = client.get("/api/v1/recipes/seasonal?hemisphere=south")
        assert response.status_code == 200

    def test_seasonal_recipes_all_match_season(self):
        """所有推荐食疗都符合当前季节"""
        response = client.get("/api/v1/recipes/seasonal")
        data = response.json()["data"]
        season = data["season"]
        for recipe in data["recipes"]:
            assert season in recipe["seasons"]


# ─────────────────────────────────────────────────────────────────────────────
# 食疗详情端点测试
# ─────────────────────────────────────────────────────────────────────────────

class TestRecipeDetail:
    """GET /api/v1/recipes/{id} 详情端点"""

    def test_recipe_detail_yam_coix(self):
        """山药薏米粥详情"""
        response = client.get("/api/v1/recipes/yam_coix_porridge")
        assert response.status_code == 200
        data = response.json()["data"]
        assert data["id"] == "yam_coix_porridge"
        assert data["name"] == "山药薏米粥"

    def test_recipe_detail_jujube_longan(self):
        """红枣桂圆汤详情"""
        response = client.get("/api/v1/recipes/jujube_longan_soup")
        assert response.status_code == 200
        assert response.json()["data"]["id"] == "jujube_longan_soup"

    def test_recipe_detail_mung_bean(self):
        """绿豆薏仁汤详情"""
        response = client.get("/api/v1/recipes/mung_bean_coix_soup")
        assert response.status_code == 200
        assert response.json()["data"]["id"] == "mung_bean_coix_soup"

    def test_recipe_detail_angelica_lamb(self):
        """当归羊肉汤详情"""
        response = client.get("/api/v1/recipes/angelica_lamb_soup")
        assert response.status_code == 200
        assert response.json()["data"]["id"] == "angelica_lamb_soup"

    def test_recipe_detail_lotus_root(self):
        """莲藕排骨汤详情"""
        response = client.get("/api/v1/recipes/lotus_root_pork_rib_soup")
        assert response.status_code == 200
        assert response.json()["data"]["id"] == "lotus_root_pork_rib_soup"

    def test_recipe_detail_astragalus_chicken(self):
        """黄芪鸡汤详情"""
        response = client.get("/api/v1/recipes/astragalus_chicken_soup")
        assert response.status_code == 200
        assert response.json()["data"]["id"] == "astragalus_chicken_soup"

    def test_recipe_detail_hawthorn_peel(self):
        """山楂陈皮茶饭详情"""
        response = client.get("/api/v1/recipes/hawthorn_tangerine_peel_dish")
        assert response.status_code == 200
        assert response.json()["data"]["id"] == "hawthorn_tangerine_peel_dish"

    def test_recipe_detail_poria_lily(self):
        """茯苓百合粥详情"""
        response = client.get("/api/v1/recipes/poria_lily_bulb_porridge")
        assert response.status_code == 200
        assert response.json()["data"]["id"] == "poria_lily_bulb_porridge"

    def test_recipe_detail_walnut_sesame(self):
        """核桃黑芝麻糊详情"""
        response = client.get("/api/v1/recipes/walnut_black_sesame_paste")
        assert response.status_code == 200
        assert response.json()["data"]["id"] == "walnut_black_sesame_paste"

    def test_recipe_detail_bamboo_shoot(self):
        """春笋豆腐汤详情"""
        response = client.get("/api/v1/recipes/bamboo_shoot_tofu_soup")
        assert response.status_code == 200
        assert response.json()["data"]["id"] == "bamboo_shoot_tofu_soup"

    def test_recipe_detail_has_all_fields(self):
        """食疗详情包含所有字段"""
        response = client.get("/api/v1/recipes/yam_coix_porridge")
        data = response.json()["data"]
        required_fields = [
            "id", "name", "name_en", "category", "seasons", "constitution_types",
            "ingredients", "method", "benefits", "tcm_principle",
            "prep_time_minutes", "difficulty", "cultural_note"
        ]
        for field in required_fields:
            assert field in data

    def test_recipe_detail_ingredients_structure(self):
        """食材结构正确"""
        response = client.get("/api/v1/recipes/yam_coix_porridge")
        data = response.json()["data"]
        for ingredient in data["ingredients"]:
            assert "name" in ingredient
            assert "amount" in ingredient
            assert "tcm_property" in ingredient

    def test_recipe_detail_method_is_list(self):
        """烹饪步骤是列表"""
        response = client.get("/api/v1/recipes/yam_coix_porridge")
        data = response.json()["data"]
        assert isinstance(data["method"], list)
        assert len(data["method"]) > 0

    def test_recipe_detail_benefits_is_list(self):
        """功效是列表"""
        response = client.get("/api/v1/recipes/yam_coix_porridge")
        data = response.json()["data"]
        assert isinstance(data["benefits"], list)
        assert len(data["benefits"]) > 0

    def test_recipe_detail_invalid_id_404(self):
        """无效 ID 返回 404"""
        response = client.get("/api/v1/recipes/invalid_recipe_id")
        assert response.status_code == 404

    def test_recipe_detail_invalid_id_error_message(self):
        """404 错误消息清晰"""
        response = client.get("/api/v1/recipes/invalid_recipe_id")
        data = response.json()
        assert "detail" in data

    def test_recipe_detail_success_response(self):
        """成功响应包含 success 字段"""
        response = client.get("/api/v1/recipes/yam_coix_porridge")
        data = response.json()
        assert data["success"] is True


# ─────────────────────────────────────────────────────────────────────────────
# 数据完整性测试
# ─────────────────────────────────────────────────────────────────────────────

class TestDataIntegrity:
    """数据完整性检查"""

    def test_all_recipes_have_id(self):
        """所有食疗都有 ID"""
        response = client.get("/api/v1/recipes/?limit=20")
        recipes = response.json()["data"]["recipes"]
        for recipe in recipes:
            assert recipe["id"]
            assert isinstance(recipe["id"], str)

    def test_all_recipes_have_chinese_name(self):
        """所有食疗都有中文名"""
        response = client.get("/api/v1/recipes/?limit=20")
        recipes = response.json()["data"]["recipes"]
        for recipe in recipes:
            assert recipe["name"]
            assert isinstance(recipe["name"], str)

    def test_all_recipes_have_english_name(self):
        """所有食疗都有英文名"""
        response = client.get("/api/v1/recipes/?limit=20")
        recipes = response.json()["data"]["recipes"]
        for recipe in recipes:
            assert recipe["name_en"]
            assert isinstance(recipe["name_en"], str)

    def test_all_recipes_have_category(self):
        """所有食疗都有分类"""
        response = client.get("/api/v1/recipes/?limit=20")
        recipes = response.json()["data"]["recipes"]
        valid_categories = ["粥", "汤", "菜", "茶"]
        for recipe in recipes:
            assert recipe["category"] in valid_categories

    def test_all_recipes_have_seasons(self):
        """所有食疗都有季节"""
        response = client.get("/api/v1/recipes/?limit=20")
        recipes = response.json()["data"]["recipes"]
        for recipe in recipes:
            assert isinstance(recipe["seasons"], list)
            assert len(recipe["seasons"]) > 0

    def test_all_recipes_have_constitution(self):
        """所有食疗都有体质类型"""
        response = client.get("/api/v1/recipes/?limit=20")
        recipes = response.json()["data"]["recipes"]
        for recipe in recipes:
            assert isinstance(recipe["constitution_types"], list)
            assert len(recipe["constitution_types"]) > 0

    def test_recipe_detail_complete(self):
        """详情数据完整"""
        response = client.get("/api/v1/recipes/yam_coix_porridge")
        recipe = response.json()["data"]
        assert recipe["ingredients"]
        assert recipe["method"]
        assert recipe["benefits"]
        assert recipe["tcm_principle"]
        assert recipe["prep_time_minutes"] > 0
        assert recipe["difficulty"] in ["easy", "medium"]
        assert recipe["cultural_note"]


# ─────────────────────────────────────────────────────────────────────────────
# 边界情况与错误处理
# ─────────────────────────────────────────────────────────────────────────────

class TestEdgeCases:
    """边界情况测试"""

    def test_empty_season_filter(self):
        """空季节值被忽略"""
        response = client.get("/api/v1/recipes/?season=")
        assert response.status_code == 200

    def test_case_sensitive_season(self):
        """季节值大小写敏感"""
        response = client.get("/api/v1/recipes/?season=Spring")
        assert response.json()["data"]["total"] == 0

    def test_case_sensitive_constitution(self):
        """体质值大小写敏感"""
        response = client.get("/api/v1/recipes/?constitution=Qi_Deficiency")
        assert response.json()["data"]["total"] == 0

    def test_multiple_filters_intersection(self):
        """多个筛选条件求交集"""
        response = client.get("/api/v1/recipes/?season=winter&constitution=yang_deficiency&limit=20")
        data = response.json()
        recipes = data["data"]["recipes"]
        for recipe in recipes:
            assert "winter" in recipe["seasons"]
            assert "yang_deficiency" in recipe["constitution_types"]

    def test_limit_one(self):
        """limit 为 1"""
        response = client.get("/api/v1/recipes/?limit=1")
        recipes = response.json()["data"]["recipes"]
        assert len(recipes) == 1

    def test_special_characters_in_filter(self):
        """特殊字符在筛选中被处理"""
        response = client.get("/api/v1/recipes/?season=%E6%98%A5")  # URL 编码的 "春"
        assert response.status_code == 200

    def test_large_limit_returns_max(self):
        """超大 limit 返回最多 20 条"""
        response = client.get("/api/v1/recipes/?limit=1000")
        assert response.status_code == 422

    def test_negative_limit(self):
        """负数 limit 返回 422"""
        response = client.get("/api/v1/recipes/?limit=-1")
        assert response.status_code == 422
