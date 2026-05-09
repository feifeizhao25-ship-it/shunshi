"""
顺时 - 运动方案端点测试
test_exercise.py

包括 40+ 个测试用例，覆盖所有运动端点、过滤器、7 日计划、404 响应等。
"""

import pytest


class TestExerciseListBasic:
    """运动列表基础端点测试"""

    def test_list_returns_200(self, client):
        """GET /api/v1/exercise/ 返回 200"""
        response = client.get("/api/v1/exercise/")
        assert response.status_code == 200

    def test_list_has_success_flag(self, client):
        """响应包含 'success' 标志"""
        response = client.get("/api/v1/exercise/")
        data = response.json()
        assert "success" in data
        assert data["success"] is True

    def test_list_has_data_key(self, client):
        """响应包含 'data' 键"""
        response = client.get("/api/v1/exercise/")
        data = response.json()
        assert "data" in data

    def test_list_has_exercises_array(self, client):
        """响应的 data 包含 'exercises' 列表"""
        response = client.get("/api/v1/exercise/")
        data = response.json()
        assert "exercises" in data["data"]
        assert isinstance(data["data"]["exercises"], list)

    def test_list_has_total_count(self, client):
        """响应的 data 包含 'total' 字段"""
        response = client.get("/api/v1/exercise/")
        data = response.json()
        assert "total" in data["data"]
        assert data["data"]["total"] > 0

    def test_list_has_season_field(self, client):
        """响应的 data 包含 'season' 字段"""
        response = client.get("/api/v1/exercise/")
        data = response.json()
        assert "season" in data["data"]
        season = data["data"]["season"]
        assert season in ["spring", "summer", "autumn", "winter"]

    def test_list_has_filters_field(self, client):
        """响应的 data 包含 'filters' 字段"""
        response = client.get("/api/v1/exercise/")
        data = response.json()
        assert "filters" in data["data"]

    def test_list_exercise_has_required_fields(self, client):
        """列表中的每个运动包含必需字段"""
        response = client.get("/api/v1/exercise/")
        data = response.json()
        exercises = data["data"]["exercises"]
        if exercises:
            exercise = exercises[0]
            required_fields = [
                "id", "name", "name_en", "category", "seasons",
                "constitution_types", "intensity", "duration_minutes",
                "benefits", "contraindications", "steps", "tcm_principle",
                "best_time", "equipment_needed"
            ]
            for field in required_fields:
                assert field in exercise


class TestExerciseListFilterSeason:
    """按季节过滤测试"""

    def test_filter_season_spring(self, client):
        """GET /api/v1/exercise/?season=spring 返回春季运动"""
        response = client.get("/api/v1/exercise/?season=spring")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["season"] == "spring"
        exercises = data["data"]["exercises"]
        if exercises:
            for exercise in exercises:
                assert "spring" in exercise["seasons"]

    def test_filter_season_summer(self, client):
        """GET /api/v1/exercise/?season=summer 返回夏季运动"""
        response = client.get("/api/v1/exercise/?season=summer")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["season"] == "summer"
        exercises = data["data"]["exercises"]
        if exercises:
            for exercise in exercises:
                assert "summer" in exercise["seasons"]

    def test_filter_season_autumn(self, client):
        """GET /api/v1/exercise/?season=autumn 返回秋季运动"""
        response = client.get("/api/v1/exercise/?season=autumn")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["season"] == "autumn"

    def test_filter_season_winter(self, client):
        """GET /api/v1/exercise/?season=winter 返回冬季运动"""
        response = client.get("/api/v1/exercise/?season=winter")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["season"] == "winter"

    def test_filter_season_stored_in_filters(self, client):
        """季节过滤器被记录在 filters 字段"""
        response = client.get("/api/v1/exercise/?season=spring")
        data = response.json()
        assert data["data"]["filters"]["season"] == "spring"


class TestExerciseListFilterConstitution:
    """按体质过滤测试"""

    def test_filter_constitution_qi_deficiency(self, client):
        """GET /api/v1/exercise/?constitution=qi_deficiency 返回相关运动"""
        response = client.get("/api/v1/exercise/?constitution=qi_deficiency")
        assert response.status_code == 200
        data = response.json()
        exercises = data["data"]["exercises"]
        for exercise in exercises:
            assert "qi_deficiency" in exercise["constitution_types"] or "all" in exercise["constitution_types"]

    def test_filter_constitution_yang_deficiency(self, client):
        """GET /api/v1/exercise/?constitution=yang_deficiency 返回相关运动"""
        response = client.get("/api/v1/exercise/?constitution=yang_deficiency")
        assert response.status_code == 200
        data = response.json()
        exercises = data["data"]["exercises"]
        for exercise in exercises:
            assert "yang_deficiency" in exercise["constitution_types"] or "all" in exercise["constitution_types"]

    def test_filter_constitution_blood_stasis(self, client):
        """按血瘀体质筛选"""
        response = client.get("/api/v1/exercise/?constitution=blood_stasis")
        assert response.status_code == 200
        data = response.json()
        assert len(data["data"]["exercises"]) > 0

    def test_filter_constitution_damp_heat(self, client):
        """按湿热体质筛选"""
        response = client.get("/api/v1/exercise/?constitution=damp_heat")
        assert response.status_code == 200
        data = response.json()
        assert len(data["data"]["exercises"]) > 0

    def test_filter_constitution_stored_in_filters(self, client):
        """体质过滤器被记录在 filters 字段"""
        response = client.get("/api/v1/exercise/?constitution=qi_deficiency")
        data = response.json()
        assert data["data"]["filters"]["constitution"] == "qi_deficiency"


class TestExerciseListFilterIntensity:
    """按强度过滤测试"""

    def test_filter_intensity_very_light(self, client):
        """GET /api/v1/exercise/?intensity=very_light 返回极轻强度运动"""
        response = client.get("/api/v1/exercise/?intensity=very_light")
        assert response.status_code == 200
        data = response.json()
        exercises = data["data"]["exercises"]
        for exercise in exercises:
            assert exercise["intensity"] == "very_light"

    def test_filter_intensity_light(self, client):
        """GET /api/v1/exercise/?intensity=light 返回轻强度及以下运动"""
        response = client.get("/api/v1/exercise/?intensity=light")
        assert response.status_code == 200
        data = response.json()
        exercises = data["data"]["exercises"]
        for exercise in exercises:
            assert exercise["intensity"] in ["very_light", "light"]

    def test_filter_intensity_medium(self, client):
        """GET /api/v1/exercise/?intensity=medium 返回中等强度及以下运动"""
        response = client.get("/api/v1/exercise/?intensity=medium")
        assert response.status_code == 200
        data = response.json()
        exercises = data["data"]["exercises"]
        for exercise in exercises:
            assert exercise["intensity"] in ["very_light", "light", "medium"]

    def test_filter_intensity_stored_in_filters(self, client):
        """强度过滤器被记录在 filters 字段"""
        response = client.get("/api/v1/exercise/?intensity=light")
        data = response.json()
        assert data["data"]["filters"]["intensity"] == "light"


class TestExerciseListFilterCategory:
    """按类别过滤测试"""

    def test_filter_category_qigong(self, client):
        """GET /api/v1/exercise/?category=qigong 返回气功运动"""
        response = client.get("/api/v1/exercise/?category=qigong")
        assert response.status_code == 200
        data = response.json()
        exercises = data["data"]["exercises"]
        for exercise in exercises:
            assert exercise["category"] == "qigong"

    def test_filter_category_martial_arts(self, client):
        """GET /api/v1/exercise/?category=martial_arts 返回武术运动"""
        response = client.get("/api/v1/exercise/?category=martial_arts")
        assert response.status_code == 200
        data = response.json()
        exercises = data["data"]["exercises"]
        for exercise in exercises:
            assert exercise["category"] == "martial_arts"

    def test_filter_category_walking(self, client):
        """GET /api/v1/exercise/?category=walking 返回散步运动"""
        response = client.get("/api/v1/exercise/?category=walking")
        assert response.status_code == 200
        data = response.json()
        exercises = data["data"]["exercises"]
        for exercise in exercises:
            assert exercise["category"] == "walking"

    def test_filter_category_sports(self, client):
        """GET /api/v1/exercise/?category=sports 返回运动类项目"""
        response = client.get("/api/v1/exercise/?category=sports")
        assert response.status_code == 200
        data = response.json()
        exercises = data["data"]["exercises"]
        for exercise in exercises:
            assert exercise["category"] == "sports"

    def test_filter_category_stored_in_filters(self, client):
        """类别过滤器被记录在 filters 字段"""
        response = client.get("/api/v1/exercise/?category=qigong")
        data = response.json()
        assert data["data"]["filters"]["category"] == "qigong"


class TestExerciseListCombinedFilters:
    """组合过滤测试"""

    def test_filter_season_and_constitution(self, client):
        """同时按季节和体质过滤"""
        response = client.get("/api/v1/exercise/?season=spring&constitution=qi_deficiency")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["filters"]["season"] == "spring"
        assert data["data"]["filters"]["constitution"] == "qi_deficiency"

    def test_filter_season_constitution_and_intensity(self, client):
        """同时按季节、体质、强度过滤"""
        response = client.get("/api/v1/exercise/?season=summer&constitution=damp_heat&intensity=medium")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["filters"]["season"] == "summer"
        assert data["data"]["filters"]["constitution"] == "damp_heat"
        assert data["data"]["filters"]["intensity"] == "medium"

    def test_filter_all_four_parameters(self, client):
        """同时使用四个过滤参数"""
        response = client.get("/api/v1/exercise/?season=spring&constitution=qi_stagnation&intensity=light&category=walking")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True


class TestExerciseListPagination:
    """分页测试"""

    def test_limit_default_is_10(self, client):
        """默认 limit 为 10"""
        response = client.get("/api/v1/exercise/")
        data = response.json()
        exercises = data["data"]["exercises"]
        assert len(exercises) <= 10

    def test_limit_3(self, client):
        """GET /api/v1/exercise/?limit=3 最多返回 3 个"""
        response = client.get("/api/v1/exercise/?limit=3")
        data = response.json()
        exercises = data["data"]["exercises"]
        assert len(exercises) <= 3

    def test_limit_50(self, client):
        """GET /api/v1/exercise/?limit=50 最多返回 50 个"""
        response = client.get("/api/v1/exercise/?limit=50")
        data = response.json()
        exercises = data["data"]["exercises"]
        assert len(exercises) <= 50

    def test_limit_min_is_1(self, client):
        """limit 最小值为 1"""
        response = client.get("/api/v1/exercise/?limit=1")
        assert response.status_code == 200


class TestExerciseDailyEndpoint:
    """每日推荐运动端点测试"""

    def test_daily_returns_200(self, client):
        """GET /api/v1/exercise/daily 返回 200"""
        response = client.get("/api/v1/exercise/daily")
        assert response.status_code == 200

    def test_daily_has_success(self, client):
        """daily 响应包含 success"""
        response = client.get("/api/v1/exercise/daily")
        data = response.json()
        assert data["success"] is True

    def test_daily_has_recommended_exercises(self, client):
        """daily 响应包含 recommended_exercises 列表"""
        response = client.get("/api/v1/exercise/daily")
        data = response.json()
        assert "recommended_exercises" in data["data"]
        assert isinstance(data["data"]["recommended_exercises"], list)

    def test_daily_has_season(self, client):
        """daily 响应包含 season 字段"""
        response = client.get("/api/v1/exercise/daily")
        data = response.json()
        assert "season" in data["data"]
        season = data["data"]["season"]
        assert season in ["spring", "summer", "autumn", "winter"]

    def test_daily_has_date(self, client):
        """daily 响应包含 date 字段"""
        response = client.get("/api/v1/exercise/daily")
        data = response.json()
        assert "date" in data["data"]

    def test_daily_has_routine_tip(self, client):
        """daily 响应包含 daily_routine 和 tip"""
        response = client.get("/api/v1/exercise/daily")
        data = response.json()
        assert "daily_routine" in data["data"]
        assert "tip" in data["data"]

    def test_daily_with_constitution(self, client):
        """GET /api/v1/exercise/daily?constitution=qi_deficiency 返回体质匹配运动"""
        response = client.get("/api/v1/exercise/daily?constitution=qi_deficiency")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["constitution"] == "qi_deficiency"

    def test_daily_with_damp_heat_constitution(self, client):
        """GET /api/v1/exercise/daily?constitution=damp_heat"""
        response = client.get("/api/v1/exercise/daily?constitution=damp_heat")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["constitution"] == "damp_heat"

    def test_daily_without_constitution(self, client):
        """GET /api/v1/exercise/daily 不提供体质时返回通用运动"""
        response = client.get("/api/v1/exercise/daily")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["constitution"] is None


class TestExerciseSeasonalEndpoint:
    """季节特色运动端点测试"""

    def test_seasonal_returns_200(self, client):
        """GET /api/v1/exercise/seasonal 返回 200"""
        response = client.get("/api/v1/exercise/seasonal")
        assert response.status_code == 200

    def test_seasonal_has_success(self, client):
        """seasonal 响应包含 success"""
        response = client.get("/api/v1/exercise/seasonal")
        data = response.json()
        assert data["success"] is True

    def test_seasonal_has_season_name(self, client):
        """seasonal 响应包含 season_name"""
        response = client.get("/api/v1/exercise/seasonal")
        data = response.json()
        assert "season_name" in data["data"]

    def test_seasonal_has_featured_exercises(self, client):
        """seasonal 响应包含 featured_exercises"""
        response = client.get("/api/v1/exercise/seasonal")
        data = response.json()
        assert "featured_exercises" in data["data"]
        assert isinstance(data["data"]["featured_exercises"], list)

    def test_seasonal_has_season_wisdom(self, client):
        """seasonal 响应包含 season_wisdom"""
        response = client.get("/api/v1/exercise/seasonal")
        data = response.json()
        assert "season_wisdom" in data["data"]


class TestSevenDayPlanEndpoint:
    """7 日计划端点测试"""

    def test_plan_qi_deficiency_returns_200(self, client):
        """GET /api/v1/exercise/plan/qi_deficiency 返回 200"""
        response = client.get("/api/v1/exercise/plan/qi_deficiency")
        assert response.status_code == 200

    def test_plan_has_success(self, client):
        """plan 响应包含 success"""
        response = client.get("/api/v1/exercise/plan/qi_deficiency")
        data = response.json()
        assert data["success"] is True

    def test_plan_has_constitution(self, client):
        """plan 响应包含 constitution 字段"""
        response = client.get("/api/v1/exercise/plan/qi_deficiency")
        data = response.json()
        assert data["data"]["constitution"] == "qi_deficiency"

    def test_plan_has_weekly_plan(self, client):
        """plan 响应包含 weekly_plan 列表"""
        response = client.get("/api/v1/exercise/plan/qi_deficiency")
        data = response.json()
        assert "weekly_plan" in data["data"]
        assert isinstance(data["data"]["weekly_plan"], list)

    def test_plan_has_7_days(self, client):
        """plan 的 weekly_plan 包含 7 个元素"""
        response = client.get("/api/v1/exercise/plan/qi_deficiency")
        data = response.json()
        weekly_plan = data["data"]["weekly_plan"]
        assert len(weekly_plan) == 7

    def test_plan_day_structure(self, client):
        """plan 中每天包含必需字段"""
        response = client.get("/api/v1/exercise/plan/qi_deficiency")
        data = response.json()
        weekly_plan = data["data"]["weekly_plan"]
        for day_item in weekly_plan:
            required_fields = ["day", "exercise_name", "exercise_id", "duration_minutes", "intensity", "benefits", "best_time"]
            for field in required_fields:
                assert field in day_item

    def test_plan_total_weekly_minutes(self, client):
        """plan 包含 total_weekly_minutes"""
        response = client.get("/api/v1/exercise/plan/qi_deficiency")
        data = response.json()
        assert "total_weekly_minutes" in data["data"]
        assert data["data"]["total_weekly_minutes"] > 0

    def test_plan_has_tips(self, client):
        """plan 包含 tips 列表"""
        response = client.get("/api/v1/exercise/plan/qi_deficiency")
        data = response.json()
        assert "tips" in data["data"]
        assert isinstance(data["data"]["tips"], list)

    def test_plan_yang_deficiency(self, client):
        """GET /api/v1/exercise/plan/yang_deficiency 返回阳虚体质计划"""
        response = client.get("/api/v1/exercise/plan/yang_deficiency")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["constitution"] == "yang_deficiency"

    def test_plan_blood_stasis(self, client):
        """GET /api/v1/exercise/plan/blood_stasis 返回血瘀体质计划"""
        response = client.get("/api/v1/exercise/plan/blood_stasis")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["constitution"] == "blood_stasis"

    def test_plan_qi_stagnation(self, client):
        """GET /api/v1/exercise/plan/qi_stagnation 返回气滞体质计划"""
        response = client.get("/api/v1/exercise/plan/qi_stagnation")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["constitution"] == "qi_stagnation"

    def test_plan_damp_heat(self, client):
        """GET /api/v1/exercise/plan/damp_heat 返回湿热体质计划"""
        response = client.get("/api/v1/exercise/plan/damp_heat")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["constitution"] == "damp_heat"

    def test_plan_yin_deficiency(self, client):
        """GET /api/v1/exercise/plan/yin_deficiency 返回阴虚体质计划"""
        response = client.get("/api/v1/exercise/plan/yin_deficiency")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["constitution"] == "yin_deficiency"

    def test_plan_phlegm_dampness(self, client):
        """GET /api/v1/exercise/plan/phlegm_dampness 返回痰湿体质计划"""
        response = client.get("/api/v1/exercise/plan/phlegm_dampness")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["constitution"] == "phlegm_dampness"

    def test_plan_invalid_constitution_returns_404(self, client):
        """GET /api/v1/exercise/plan/invalid_type 返回 404"""
        response = client.get("/api/v1/exercise/plan/invalid_constitution")
        assert response.status_code == 404


class TestExerciseDetailEndpoint:
    """运动详情端点测试"""

    def test_detail_ba_duan_jin(self, client):
        """GET /api/v1/exercise/ba-duan-jin 返回八段锦详情"""
        response = client.get("/api/v1/exercise/ba-duan-jin")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        exercise = data["data"]
        assert exercise["id"] == "ba-duan-jin"
        assert exercise["name"] == "八段锦"

    def test_detail_tai_chi(self, client):
        """GET /api/v1/exercise/tai-chi-quan 返回太极拳详情"""
        response = client.get("/api/v1/exercise/tai-chi-quan")
        assert response.status_code == 200
        data = response.json()
        exercise = data["data"]
        assert exercise["id"] == "tai-chi-quan"

    def test_detail_five_animal_frolics(self, client):
        """GET /api/v1/exercise/wu-qin-xi 返回五禽戏详情"""
        response = client.get("/api/v1/exercise/wu-qin-xi")
        assert response.status_code == 200
        data = response.json()
        exercise = data["data"]
        assert exercise["id"] == "wu-qin-xi"

    def test_detail_yijin_jing(self, client):
        """GET /api/v1/exercise/yijin-jing 返回易筋经详情"""
        response = client.get("/api/v1/exercise/yijin-jing")
        assert response.status_code == 200
        data = response.json()
        exercise = data["data"]
        assert exercise["id"] == "yijin-jing"

    def test_detail_has_all_fields(self, client):
        """详情响应包含所有必需字段"""
        response = client.get("/api/v1/exercise/ba-duan-jin")
        data = response.json()
        exercise = data["data"]
        required_fields = [
            "id", "name", "name_en", "category", "seasons",
            "constitution_types", "intensity", "duration_minutes",
            "benefits", "contraindications", "steps", "tcm_principle",
            "best_time", "equipment_needed"
        ]
        for field in required_fields:
            assert field in exercise

    def test_detail_has_steps(self, client):
        """详情响应的 steps 是列表"""
        response = client.get("/api/v1/exercise/ba-duan-jin")
        data = response.json()
        exercise = data["data"]
        assert isinstance(exercise["steps"], list)
        assert len(exercise["steps"]) > 0

    def test_detail_has_benefits(self, client):
        """详情响应的 benefits 是列表"""
        response = client.get("/api/v1/exercise/ba-duan-jin")
        data = response.json()
        exercise = data["data"]
        assert isinstance(exercise["benefits"], list)
        assert len(exercise["benefits"]) > 0

    def test_detail_invalid_exercise_returns_404(self, client):
        """GET /api/v1/exercise/invalid-exercise 返回 404"""
        response = client.get("/api/v1/exercise/invalid-exercise")
        assert response.status_code == 404

    def test_detail_liu_zi_jue(self, client):
        """GET /api/v1/exercise/liu-zi-jue 返回六字诀详情"""
        response = client.get("/api/v1/exercise/liu-zi-jue")
        assert response.status_code == 200
        data = response.json()
        exercise = data["data"]
        assert exercise["name"] == "六字诀"

    def test_detail_walking_meditation(self, client):
        """GET /api/v1/exercise/san-bu-ming-xiang 返回散步冥想详情"""
        response = client.get("/api/v1/exercise/san-bu-ming-xiang")
        assert response.status_code == 200
        data = response.json()
        exercise = data["data"]
        assert exercise["category"] == "walking"

    def test_detail_summer_swimming(self, client):
        """GET /api/v1/exercise/xia-ri-you-yong 返回夏日游泳详情"""
        response = client.get("/api/v1/exercise/xia-ri-you-yong")
        assert response.status_code == 200
        data = response.json()
        exercise = data["data"]
        assert "summer" in exercise["seasons"]

    def test_detail_autumn_hiking(self, client):
        """GET /api/v1/exercise/qiu-ji-deng-shan 返回秋季登山详情"""
        response = client.get("/api/v1/exercise/qiu-ji-deng-shan")
        assert response.status_code == 200
        data = response.json()
        exercise = data["data"]
        assert "autumn" in exercise["seasons"]

    def test_detail_winter_warming(self, client):
        """GET /api/v1/exercise/dong-ji-nuan-shen-gong 返回冬季暖身功详情"""
        response = client.get("/api/v1/exercise/dong-ji-nuan-shen-gong")
        assert response.status_code == 200
        data = response.json()
        exercise = data["data"]
        assert "winter" in exercise["seasons"]


class TestExerciseErrorHandling:
    """错误处理测试"""

    def test_404_for_nonexistent_exercise(self, client):
        """不存在的运动 ID 返回 404"""
        response = client.get("/api/v1/exercise/nonexistent-exercise-xyz")
        assert response.status_code == 404
        data = response.json()
        assert "detail" in data

    def test_404_for_invalid_plan_constitution(self, client):
        """无效体质返回 404"""
        response = client.get("/api/v1/exercise/plan/invalid_constitution_xyz")
        assert response.status_code == 404
        data = response.json()
        assert "detail" in data
        assert "Constitution type" in data["detail"]

    def test_valid_routes_return_200(self, client):
        """所有有效路由都返回 200"""
        valid_routes = [
            "/api/v1/exercise/",
            "/api/v1/exercise/daily",
            "/api/v1/exercise/seasonal",
            "/api/v1/exercise/ba-duan-jin",
            "/api/v1/exercise/tai-chi-quan",
            "/api/v1/exercise/plan/qi_deficiency",
        ]
        for route in valid_routes:
            response = client.get(route)
            assert response.status_code == 200


class TestExerciseDataConsistency:
    """数据一致性测试"""

    def test_all_exercises_have_valid_ids(self, client):
        """所有运动 ID 非空且唯一"""
        response = client.get("/api/v1/exercise/?limit=50")
        data = response.json()
        exercises = data["data"]["exercises"]
        ids = [e["id"] for e in exercises]
        assert len(ids) == len(set(ids))  # 唯一性
        assert all(id for id in ids)  # 非空

    def test_all_exercises_have_all_seasons(self, client):
        """所有运动的季节列表非空"""
        response = client.get("/api/v1/exercise/?limit=50")
        data = response.json()
        exercises = data["data"]["exercises"]
        for exercise in exercises:
            assert isinstance(exercise["seasons"], list)
            assert len(exercise["seasons"]) > 0
            assert all(s in ["spring", "summer", "autumn", "winter"] for s in exercise["seasons"])

    def test_all_exercises_have_valid_intensity(self, client):
        """所有运动的强度有效"""
        response = client.get("/api/v1/exercise/?limit=50")
        data = response.json()
        exercises = data["data"]["exercises"]
        valid_intensities = ["very_light", "light", "medium", "high"]
        for exercise in exercises:
            assert exercise["intensity"] in valid_intensities

    def test_all_exercises_have_valid_category(self, client):
        """所有运动的类别有效"""
        response = client.get("/api/v1/exercise/?limit=50")
        data = response.json()
        exercises = data["data"]["exercises"]
        valid_categories = ["qigong", "martial_arts", "walking", "sports"]
        for exercise in exercises:
            assert exercise["category"] in valid_categories

    def test_detail_matches_list_data(self, client):
        """详情数据与列表数据一致"""
        response = client.get("/api/v1/exercise/?limit=1")
        data = response.json()
        if data["data"]["exercises"]:
            exercise_id = data["data"]["exercises"][0]["id"]
            detail_response = client.get(f"/api/v1/exercise/{exercise_id}")
            detail_data = detail_response.json()
            assert detail_data["data"]["id"] == exercise_id
            assert detail_data["data"]["name"] == data["data"]["exercises"][0]["name"]
