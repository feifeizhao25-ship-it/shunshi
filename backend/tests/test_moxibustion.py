"""
测试: 艾灸居家引导系统 API
覆盖6个端点，包括体质方案、穴位筛选、灸期检查等。
"""

import pytest
from fastapi.testclient import TestClient


@pytest.fixture
def client():
    """创建FastAPI测试客户端"""
    from app.main import app
    return TestClient(app)


class TestListPoints:
    """GET /api/v1/moxibustion/points - 穴位列表"""

    def test_list_all_points(self, client):
        """测试：获取所有穴位"""
        response = client.get("/api/v1/moxibustion/points")
        assert response.status_code == 200
        assert response.json()["success"] is True
        data = response.json()["data"]
        assert "points" in data
        assert "total" in data
        assert data["total"] >= 12

    def test_list_points_default_limit(self, client):
        """测试：默认limit为12"""
        response = client.get("/api/v1/moxibustion/points")
        assert len(response.json()["data"]["points"]) <= 12

    def test_list_points_custom_limit(self, client):
        """测试：自定义limit"""
        response = client.get("/api/v1/moxibustion/points?limit=5")
        assert len(response.json()["data"]["points"]) <= 5

    def test_filter_by_constitution_qi_deficiency(self, client):
        """测试：按气虚体质过滤"""
        response = client.get("/api/v1/moxibustion/points?constitution=qi_deficiency")
        assert response.status_code == 200
        points = response.json()["data"]["points"]
        assert len(points) > 0

    def test_filter_by_constitution_yang_deficiency(self, client):
        """测试：按阳虚体质过滤"""
        response = client.get("/api/v1/moxibustion/points?constitution=yang_deficiency")
        assert response.status_code == 200
        points = response.json()["data"]["points"]
        assert len(points) > 0

    def test_filter_by_constitution_yin_deficiency(self, client):
        """测试：按阴虚体质过滤"""
        response = client.get("/api/v1/moxibustion/points?constitution=yin_deficiency")
        assert response.status_code == 200
        points = response.json()["data"]["points"]
        assert len(points) > 0

    def test_filter_by_constitution_blood_deficiency(self, client):
        """测试：按血虚体质过滤"""
        response = client.get("/api/v1/moxibustion/points?constitution=blood_deficiency")
        assert response.status_code == 200
        points = response.json()["data"]["points"]
        assert len(points) > 0

    def test_filter_by_constitution_damp(self, client):
        """测试：按痰湿质过滤"""
        response = client.get("/api/v1/moxibustion/points?constitution=damp")
        assert response.status_code == 200
        points = response.json()["data"]["points"]
        assert len(points) > 0

    def test_filter_by_constitution_damp_heat(self, client):
        """测试：按湿热质过滤"""
        response = client.get("/api/v1/moxibustion/points?constitution=damp_heat")
        assert response.status_code == 200
        points = response.json()["data"]["points"]
        assert len(points) > 0

    def test_filter_by_constitution_qi_stagnation(self, client):
        """测试：按气郁质过滤"""
        response = client.get("/api/v1/moxibustion/points?constitution=qi_stagnation")
        assert response.status_code == 200
        points = response.json()["data"]["points"]
        assert len(points) > 0

    def test_filter_by_constitution_blood_stasis(self, client):
        """测试：按血瘀质过滤"""
        response = client.get("/api/v1/moxibustion/points?constitution=blood_stasis")
        assert response.status_code == 200
        points = response.json()["data"]["points"]
        assert len(points) > 0

    def test_filter_by_season_spring(self, client):
        """测试：按春季过滤"""
        response = client.get("/api/v1/moxibustion/points?season=spring")
        assert response.status_code == 200
        points = response.json()["data"]["points"]
        assert len(points) > 0

    def test_filter_by_season_summer(self, client):
        """测试：按夏季过滤"""
        response = client.get("/api/v1/moxibustion/points?season=summer")
        assert response.status_code == 200
        points = response.json()["data"]["points"]
        assert len(points) > 0

    def test_filter_by_season_autumn(self, client):
        """测试：按秋季过滤"""
        response = client.get("/api/v1/moxibustion/points?season=autumn")
        assert response.status_code == 200
        points = response.json()["data"]["points"]
        assert len(points) > 0

    def test_filter_by_season_winter(self, client):
        """测试：按冬季过滤"""
        response = client.get("/api/v1/moxibustion/points?season=winter")
        assert response.status_code == 200
        points = response.json()["data"]["points"]
        assert len(points) > 0

    def test_combined_filters(self, client):
        """测试：同时过滤体质和季节"""
        response = client.get("/api/v1/moxibustion/points?constitution=yang_deficiency&season=winter")
        assert response.status_code == 200
        points = response.json()["data"]["points"]
        assert len(points) > 0


class TestGetPointDetail:
    """GET /api/v1/moxibustion/points/{point_id} - 穴位详情"""

    def test_get_zusanli_point(self, client):
        """测试：获取足三里穴位详情"""
        response = client.get("/api/v1/moxibustion/points/zusanli")
        assert response.status_code == 200
        assert response.json()["success"] is True
        data = response.json()["data"]
        assert data["id"] == "zusanli"
        assert data["name"] == "足三里"
        assert "location" in data
        assert "benefits" in data

    def test_get_mingmen_point(self, client):
        """测试：获取命门穴位详情"""
        response = client.get("/api/v1/moxibustion/points/mingmen")
        assert response.status_code == 200
        assert response.json()["data"]["name"] == "命门"

    def test_get_shenque_point(self, client):
        """测试：获取神阙穴位详情"""
        response = client.get("/api/v1/moxibustion/points/shenque")
        assert response.status_code == 200
        assert response.json()["data"]["name"] == "神阙"

    def test_point_detail_contains_required_fields(self, client):
        """测试：穴位详情包含必需字段"""
        response = client.get("/api/v1/moxibustion/points/guanyuan")
        data = response.json()["data"]
        required_fields = ["id", "name", "location", "benefits", "constitution_suitable",
                          "moxibustion_duration_minutes", "technique", "contraindications",
                          "best_season", "tcm_function", "warning"]
        for field in required_fields:
            assert field in data

    def test_get_all_12_points(self, client):
        """测试：能获取所有12个穴位"""
        point_ids = ["zusanli", "shenque", "guanyuan", "qihai", "mingmen", "feishu",
                     "pishu", "shenshu", "sanyinjiao", "zhongwan", "taixi", "yongquan"]
        for pid in point_ids:
            response = client.get(f"/api/v1/moxibustion/points/{pid}")
            assert response.status_code == 200
            assert response.json()["data"]["id"] == pid

    def test_get_invalid_point(self, client):
        """测试：无效穴位ID返回404"""
        response = client.get("/api/v1/moxibustion/points/invalid_point_xyz")
        assert response.status_code == 404


class TestConstitutionPlan:
    """GET /api/v1/moxibustion/constitution-plan/{constitution_type} - 体质方案"""

    def test_get_qi_deficiency_plan(self, client):
        """测试：获取气虚体质方案"""
        response = client.get("/api/v1/moxibustion/constitution-plan/qi_deficiency")
        assert response.status_code == 200
        data = response.json()["data"]
        assert data["constitution"] == "qi_deficiency"
        assert data["name"] == "气虚质"
        assert "main_points" in data
        assert "auxiliary_points" in data
        assert len(data["main_points"]) > 0

    def test_get_yang_deficiency_plan(self, client):
        """测试：获取阳虚体质方案"""
        response = client.get("/api/v1/moxibustion/constitution-plan/yang_deficiency")
        assert response.status_code == 200
        data = response.json()["data"]
        assert data["name"] == "阳虚质"

    def test_get_yin_deficiency_plan(self, client):
        """测试：获取阴虚体质方案"""
        response = client.get("/api/v1/moxibustion/constitution-plan/yin_deficiency")
        assert response.status_code == 200
        data = response.json()["data"]
        assert data["name"] == "阴虚质"

    def test_get_blood_deficiency_plan(self, client):
        """测试：获取血虚体质方案"""
        response = client.get("/api/v1/moxibustion/constitution-plan/blood_deficiency")
        assert response.status_code == 200
        data = response.json()["data"]
        assert data["name"] == "血虚质"

    def test_get_damp_plan(self, client):
        """测试：获取痰湿体质方案"""
        response = client.get("/api/v1/moxibustion/constitution-plan/damp")
        assert response.status_code == 200
        data = response.json()["data"]
        assert data["name"] == "痰湿质"

    def test_get_damp_heat_plan(self, client):
        """测试：获取湿热体质方案"""
        response = client.get("/api/v1/moxibustion/constitution-plan/damp_heat")
        assert response.status_code == 200
        data = response.json()["data"]
        assert data["name"] == "湿热质"

    def test_get_qi_stagnation_plan(self, client):
        """测试：获取气郁体质方案"""
        response = client.get("/api/v1/moxibustion/constitution-plan/qi_stagnation")
        assert response.status_code == 200
        data = response.json()["data"]
        assert data["name"] == "气郁质"

    def test_get_blood_stasis_plan(self, client):
        """测试：获取血瘀体质方案"""
        response = client.get("/api/v1/moxibustion/constitution-plan/blood_stasis")
        assert response.status_code == 200
        data = response.json()["data"]
        assert data["name"] == "血瘀质"

    def test_get_balanced_plan(self, client):
        """测试：获取平和体质方案"""
        response = client.get("/api/v1/moxibustion/constitution-plan/balanced")
        assert response.status_code == 200
        data = response.json()["data"]
        assert data["name"] == "平和质"

    def test_plan_contains_required_fields(self, client):
        """测试：方案包含必需字段"""
        response = client.get("/api/v1/moxibustion/constitution-plan/qi_deficiency")
        data = response.json()["data"]
        required_fields = ["constitution", "name", "description", "main_points",
                          "auxiliary_points", "duration_minutes", "frequency", "tip"]
        for field in required_fields:
            assert field in data

    def test_invalid_constitution_type(self, client):
        """测试：无效体质类型返回404"""
        response = client.get("/api/v1/moxibustion/constitution-plan/invalid_constitution_xyz")
        assert response.status_code == 404

    def test_all_9_constitution_types(self, client):
        """测试：所有9种体质都有方案"""
        constitutions = ["qi_deficiency", "yang_deficiency", "yin_deficiency",
                        "blood_deficiency", "damp", "damp_heat",
                        "qi_stagnation", "blood_stasis", "balanced"]
        for const in constitutions:
            response = client.get(f"/api/v1/moxibustion/constitution-plan/{const}")
            assert response.status_code == 200
            assert response.json()["success"] is True


class TestSeasonalTherapy:
    """GET /api/v1/moxibustion/seasonal-therapy - 三伏灸/三九灸信息"""

    def test_seasonal_therapy_response(self, client):
        """测试：获取灸期信息"""
        response = client.get("/api/v1/moxibustion/seasonal-therapy")
        assert response.status_code == 200
        data = response.json()["data"]
        assert "current_month" in data
        assert "current_year" in data
        assert "sanfu_therapy" in data
        assert "sanjiu_therapy" in data

    def test_seasonal_therapy_month_range(self, client):
        """测试：月份范围正确"""
        response = client.get("/api/v1/moxibustion/seasonal-therapy")
        month = response.json()["data"]["current_month"]
        assert 1 <= month <= 12

    def test_sanfu_therapy_data_structure(self, client):
        """测试：三伏灸数据结构"""
        response = client.get("/api/v1/moxibustion/seasonal-therapy")
        data = response.json()["data"]
        if data["sanfu_therapy"]:
            therapy = data["sanfu_therapy"]
            assert "active" in therapy or "next_period" in therapy
            assert "periods" in therapy
            assert "main_points" in therapy or "description" in therapy

    def test_sanjiu_therapy_data_structure(self, client):
        """测试：三九灸数据结构"""
        response = client.get("/api/v1/moxibustion/seasonal-therapy")
        data = response.json()["data"]
        if data["sanjiu_therapy"]:
            therapy = data["sanjiu_therapy"]
            assert "active" in therapy or "next_period" in therapy
            assert "periods" in therapy
            assert "main_points" in therapy or "description" in therapy

    def test_multiple_years_data(self, client):
        """测试：三伏/三九灸包含多年数据"""
        response = client.get("/api/v1/moxibustion/seasonal-therapy")
        data = response.json()["data"]
        if data["sanfu_therapy"] and "periods" in data["sanfu_therapy"]:
            periods = data["sanfu_therapy"]["periods"]
            assert len(periods) > 0


class TestDailyRecommendation:
    """GET /api/v1/moxibustion/daily-recommendation - 今日艾灸建议"""

    def test_daily_recommendation_response(self, client):
        """测试：获取今日建议"""
        response = client.get("/api/v1/moxibustion/daily-recommendation")
        assert response.status_code == 200
        data = response.json()["data"]
        assert "current_season" in data
        assert "season_name" in data
        assert "principle" in data
        assert "recommended_points" in data
        assert "timchen_tip" in data
        assert "today" in data

    def test_current_season_valid(self, client):
        """测试：季节有效"""
        response = client.get("/api/v1/moxibustion/daily-recommendation")
        season = response.json()["data"]["current_season"]
        assert season in ["spring", "summer", "autumn", "winter"]

    def test_recommended_points_not_empty(self, client):
        """测试：推荐穴位非空"""
        response = client.get("/api/v1/moxibustion/daily-recommendation")
        points = response.json()["data"]["recommended_points"]
        assert isinstance(points, list)
        assert len(points) > 0

    def test_timchen_tip_exists(self, client):
        """测试：时辰建议存在"""
        response = client.get("/api/v1/moxibustion/daily-recommendation")
        tip = response.json()["data"]["timchen_tip"]
        assert isinstance(tip, str)
        assert len(tip) > 0

    def test_today_date_format(self, client):
        """测试：日期格式正确"""
        response = client.get("/api/v1/moxibustion/daily-recommendation")
        today = response.json()["data"]["today"]
        # 检查日期格式 YYYY-MM-DD
        assert len(today) == 10
        assert today[4] == "-" and today[7] == "-"


class TestSafetyGuide:
    """GET /api/v1/moxibustion/safety-guide - 安全指南"""

    def test_safety_guide_response(self, client):
        """测试：获取安全指南"""
        response = client.get("/api/v1/moxibustion/safety-guide")
        assert response.status_code == 200
        data = response.json()["data"]
        assert "contraindications" in data
        assert "precautions" in data
        assert "emergency_measures" in data
        assert "best_practice" in data

    def test_contraindications_not_empty(self, client):
        """测试：禁忌列表非空"""
        response = client.get("/api/v1/moxibustion/safety-guide")
        contraindications = response.json()["data"]["contraindications"]
        assert isinstance(contraindications, list)
        assert len(contraindications) > 0

    def test_precautions_not_empty(self, client):
        """测试：注意事项列表非空"""
        response = client.get("/api/v1/moxibustion/safety-guide")
        precautions = response.json()["data"]["precautions"]
        assert isinstance(precautions, list)
        assert len(precautions) > 0

    def test_emergency_measures_not_empty(self, client):
        """测试：急救措施列表非空"""
        response = client.get("/api/v1/moxibustion/safety-guide")
        emergency = response.json()["data"]["emergency_measures"]
        assert isinstance(emergency, list)
        assert len(emergency) > 0

    def test_best_practice_text(self, client):
        """测试：最佳实践建议存在"""
        response = client.get("/api/v1/moxibustion/safety-guide")
        practice = response.json()["data"]["best_practice"]
        assert isinstance(practice, str)
        assert len(practice) > 0
