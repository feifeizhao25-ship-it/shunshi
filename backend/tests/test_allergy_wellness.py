"""
顺时 — 季节性过敏TCM预防与调节 API 测试
至少30个测试，包含全年12个月日历、4种过敏类型、预防方案周数参数、无效类型404
"""

import pytest
from fastapi.testclient import TestClient
from datetime import datetime
from app.router.allergy_wellness import router

# 创建测试客户端
from fastapi import FastAPI
app = FastAPI()
app.include_router(router)
client = TestClient(app)


# ─────────────────────────────────────────────────────────────────────────────
# 测试：GET /api/v1/allergy/calendar
# ─────────────────────────────────────────────────────────────────────────────

def test_get_allergy_calendar():
    """测试获取全年过敏日历。"""
    response = client.get("/api/v1/allergy/calendar")
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert "calendar" in data["data"]


def test_calendar_contains_all_12_months():
    """测试日历包含全年12个月。"""
    response = client.get("/api/v1/allergy/calendar")
    calendar = response.json()["data"]["calendar"]

    assert len(calendar) == 12
    assert response.json()["data"]["total_months"] == 12


def test_calendar_months_in_order():
    """测试日历月份按顺序排列。"""
    response = client.get("/api/v1/allergy/calendar")
    calendar = response.json()["data"]["calendar"]

    months = [item["month"] for item in calendar]
    assert months == list(range(1, 13))


def test_calendar_each_month_has_required_fields():
    """测试每个月份数据包含必需字段。"""
    response = client.get("/api/v1/allergy/calendar")
    calendar = response.json()["data"]["calendar"]

    for month_data in calendar:
        assert "month" in month_data
        assert "season" in month_data
        assert "allergens" in month_data
        assert "risk_level" in month_data
        assert "description" in month_data


def test_calendar_risk_levels_valid():
    """测试日历风险等级有效。"""
    response = client.get("/api/v1/allergy/calendar")
    calendar = response.json()["data"]["calendar"]

    valid_levels = ["低", "中", "高"]
    for month_data in calendar:
        assert month_data["risk_level"] in valid_levels


def test_calendar_february_contains_tree_pollen():
    """测试2月包含树木花粉（柏树、桦树、杨树）。"""
    response = client.get("/api/v1/allergy/calendar")
    calendar = response.json()["data"]["calendar"]

    february = next(m for m in calendar if m["month"] == 2)
    assert any("树" in allergen for allergen in february["allergens"])


def test_calendar_september_contains_weed_pollen():
    """测试9月包含杂草花粉（艾蒿、豚草）。"""
    response = client.get("/api/v1/allergy/calendar")
    calendar = response.json()["data"]["calendar"]

    september = next(m for m in calendar if m["month"] == 9)
    allergen_str = " ".join(september["allergens"])
    assert "艾蒿" in allergen_str or "豚草" in allergen_str or "杂草" in allergen_str


def test_calendar_year_round_allergens():
    """测试全年存在尘螨和霉菌。"""
    response = client.get("/api/v1/allergy/calendar")
    calendar = response.json()["data"]["calendar"]

    # 检查是否全年都有尘螨或霉菌
    has_dust_mite = any(
        any("尘螨" in a or "霉菌" in a for a in m["allergens"])
        for m in calendar
    )
    assert has_dust_mite


# ─────────────────────────────────────────────────────────────────────────────
# 测试：GET /api/v1/allergy/types
# ─────────────────────────────────────────────────────────────────────────────

def test_get_allergy_types():
    """测试获取过敏类型列表。"""
    response = client.get("/api/v1/allergy/types")
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert "types" in data["data"]


def test_allergy_types_contains_four_types():
    """测试过敏类型包含4种。"""
    response = client.get("/api/v1/allergy/types")
    types = response.json()["data"]["types"]

    assert len(types) == 4
    assert response.json()["data"]["total"] == 4


def test_allergy_types_are_correct():
    """测试过敏类型正确。"""
    response = client.get("/api/v1/allergy/types")
    types = response.json()["data"]["types"]

    type_ids = [t["id"] for t in types]
    expected = ["pollen", "dust_mite", "food", "skin"]
    assert set(type_ids) == set(expected)


def test_allergy_types_have_required_fields():
    """测试每个过敏类型包含必需字段。"""
    response = client.get("/api/v1/allergy/types")
    types = response.json()["data"]["types"]

    for allergy_type in types:
        assert "id" in allergy_type
        assert "name" in allergy_type
        assert "tcm_pattern" in allergy_type


# ─────────────────────────────────────────────────────────────────────────────
# 测试：GET /api/v1/allergy/types/{allergy_type}
# ─────────────────────────────────────────────────────────────────────────────

def test_get_pollen_allergy():
    """测试获取花粉过敏详情。"""
    response = client.get("/api/v1/allergy/types/pollen")
    assert response.status_code == 200
    data = response.json()
    assert data["data"]["id"] == "pollen"


def test_get_dust_mite_allergy():
    """测试获取尘螨过敏详情。"""
    response = client.get("/api/v1/allergy/types/dust_mite")
    assert response.status_code == 200
    data = response.json()
    assert data["data"]["id"] == "dust_mite"


def test_get_food_allergy():
    """测试获取食物过敏详情。"""
    response = client.get("/api/v1/allergy/types/food")
    assert response.status_code == 200
    data = response.json()
    assert data["data"]["id"] == "food"


def test_get_skin_allergy():
    """测试获取皮肤过敏详情。"""
    response = client.get("/api/v1/allergy/types/skin")
    assert response.status_code == 200
    data = response.json()
    assert data["data"]["id"] == "skin"


def test_allergy_detail_contains_food_therapy():
    """测试过敏类型详情包含食疗方案。"""
    response = client.get("/api/v1/allergy/types/pollen")
    data = response.json()["data"]

    assert "food_therapy" in data
    assert len(data["food_therapy"]) > 0


def test_allergy_detail_contains_acupoints():
    """测试过敏类型详情包含穴位。"""
    response = client.get("/api/v1/allergy/types/pollen")
    data = response.json()["data"]

    assert "acupoints" in data
    assert len(data["acupoints"]) > 0


def test_allergy_detail_contains_tcm_theory():
    """测试过敏类型详情包含TCM理论。"""
    response = client.get("/api/v1/allergy/types/pollen")
    data = response.json()["data"]

    assert "tcm_theory" in data
    assert "特禀质" in data["tcm_theory"] or "肺卫" in data["tcm_theory"]


def test_invalid_allergy_type_returns_404():
    """测试无效过敏类型返回404。"""
    response = client.get("/api/v1/allergy/types/invalid_type")
    assert response.status_code == 404


# ─────────────────────────────────────────────────────────────────────────────
# 测试：GET /api/v1/allergy/prevention-plan
# ─────────────────────────────────────────────────────────────────────────────

def test_get_prevention_plan_default():
    """测试获取默认预防方案（4周）。"""
    response = client.get("/api/v1/allergy/prevention-plan")
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["data"]["weeks_before"] == 4


def test_prevention_plan_contains_three_stages():
    """测试预防方案包含3个阶段。"""
    response = client.get("/api/v1/allergy/prevention-plan")
    data = response.json()["data"]

    assert "prevention_stages" in data
    assert len(data["prevention_stages"]) == 3


def test_prevention_plan_stage_one():
    """测试预防方案第1阶段详情。"""
    response = client.get("/api/v1/allergy/prevention-plan")
    stages = response.json()["data"]["prevention_stages"]

    stage_1 = stages[0]
    assert "增强体表防御" in stage_1["objective"]
    assert "玉屏风散" in stage_1["core_formula"]


def test_prevention_plan_stage_two():
    """测试预防方案第2阶段详情。"""
    response = client.get("/api/v1/allergy/prevention-plan")
    stages = response.json()["data"]["prevention_stages"]

    stage_2 = stages[1]
    assert "疏风驱邪" in stage_2["objective"]


def test_prevention_plan_stage_three():
    """测试预防方案第3阶段详情。"""
    response = client.get("/api/v1/allergy/prevention-plan")
    stages = response.json()["data"]["prevention_stages"]

    stage_3 = stages[2]
    assert "维持防御" in stage_3["objective"]


def test_prevention_plan_with_custom_weeks():
    """测试预防方案支持自定义周期。"""
    response = client.get("/api/v1/allergy/prevention-plan?weeks_before=6")
    assert response.status_code == 200
    data = response.json()
    assert data["data"]["weeks_before"] == 6


def test_prevention_plan_with_min_weeks():
    """测试预防方案最少周期（2周）。"""
    response = client.get("/api/v1/allergy/prevention-plan?weeks_before=2")
    assert response.status_code == 200


def test_prevention_plan_with_max_weeks():
    """测试预防方案最多周期（8周）。"""
    response = client.get("/api/v1/allergy/prevention-plan?weeks_before=8")
    assert response.status_code == 200


def test_prevention_plan_with_invalid_weeks_below_min():
    """测试预防方案周数低于最小值返回422。"""
    response = client.get("/api/v1/allergy/prevention-plan?weeks_before=1")
    assert response.status_code == 422


def test_prevention_plan_with_invalid_weeks_above_max():
    """测试预防方案周数高于最大值返回422。"""
    response = client.get("/api/v1/allergy/prevention-plan?weeks_before=9")
    assert response.status_code == 422


# ─────────────────────────────────────────────────────────────────────────────
# 测试：GET /api/v1/allergy/acute-relief
# ─────────────────────────────────────────────────────────────────────────────

def test_get_acute_relief():
    """测试获取急性缓解方案。"""
    response = client.get("/api/v1/allergy/acute-relief")
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert "data" in data


def test_acute_relief_contains_acupoint_techniques():
    """测试急性缓解包含穴位操作。"""
    response = client.get("/api/v1/allergy/acute-relief")
    data = response.json()["data"]

    assert "acupoint_techniques" in data
    assert len(data["acupoint_techniques"]) > 0


def test_acute_relief_acupoints_have_details():
    """测试穴位操作包含详细信息。"""
    response = client.get("/api/v1/allergy/acute-relief")
    acupoints = response.json()["data"]["acupoint_techniques"]

    for ap in acupoints:
        assert "point" in ap
        assert "location" in ap
        assert "technique" in ap
        assert "effect" in ap


def test_acute_relief_contains_food_relief():
    """测试急性缓解包含食物方案。"""
    response = client.get("/api/v1/allergy/acute-relief")
    data = response.json()["data"]

    assert "food_relief" in data
    assert len(data["food_relief"]) > 0


def test_acute_relief_contains_precautions():
    """测试急性缓解包含注意事项。"""
    response = client.get("/api/v1/allergy/acute-relief")
    data = response.json()["data"]

    assert "precautions" in data
    assert len(data["precautions"]) > 0


# ─────────────────────────────────────────────────────────────────────────────
# 测试：GET /api/v1/allergy/current-risk
# ─────────────────────────────────────────────────────────────────────────────

def test_get_current_risk():
    """测试获取当前月份过敏风险。"""
    response = client.get("/api/v1/allergy/current-risk")
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert "data" in data


def test_current_risk_matches_current_month():
    """测试当前风险月份匹配系统时间。"""
    response = client.get("/api/v1/allergy/current-risk")
    data = response.json()["data"]

    current_month = datetime.now().month
    assert data["current_month"] == current_month


def test_current_risk_contains_required_fields():
    """测试当前风险包含必需字段。"""
    response = client.get("/api/v1/allergy/current-risk")
    data = response.json()["data"]

    assert "current_month" in data
    assert "month_name" in data
    assert "season" in data
    assert "allergens" in data
    assert "risk_level" in data
    assert "description" in data


def test_current_risk_contains_recommendation():
    """测试当前风险包含建议。"""
    response = client.get("/api/v1/allergy/current-risk")
    data = response.json()["data"]

    assert "recommendation" in data
