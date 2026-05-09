"""
顺时 — TCM情志健康辅助 API 测试
至少35个测试，包含5种情志问题、情志打卡验证、冥想引导枚举、危机资源、专业帮助提醒
"""

import pytest
from fastapi.testclient import TestClient
from app.router.mental_wellness import router

# 创建测试客户端
from fastapi import FastAPI
app = FastAPI()
app.include_router(router)
client = TestClient(app)


# ─────────────────────────────────────────────────────────────────────────────
# 测试：GET /api/v1/mental/conditions
# ─────────────────────────────────────────────────────────────────────────────

def test_get_conditions_success():
    """测试获取所有情志问题列表成功。"""
    response = client.get("/api/v1/mental/conditions")
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert "data" in data
    assert "conditions" in data["data"]
    assert len(data["data"]["conditions"]) == 5
    assert data["data"]["total"] == 5


def test_conditions_contain_all_five_types():
    """测试情志问题列表包含5种情志。"""
    response = client.get("/api/v1/mental/conditions")
    conditions = response.json()["data"]["conditions"]
    condition_ids = [c["id"] for c in conditions]

    expected = ["anxiety", "low_mood", "irritability", "mood_swings", "overthinking"]
    assert set(condition_ids) == set(expected)


def test_conditions_have_required_fields():
    """测试每个情志问题条目有必需字段。"""
    response = client.get("/api/v1/mental/conditions")
    conditions = response.json()["data"]["conditions"]

    for cond in conditions:
        assert "id" in cond
        assert "name" in cond
        assert "pattern_count" in cond
        assert cond["pattern_count"] > 0


# ─────────────────────────────────────────────────────────────────────────────
# 测试：GET /api/v1/mental/conditions/{condition_id}
# ─────────────────────────────────────────────────────────────────────────────

def test_get_anxiety_condition():
    """测试获取焦虑问题详情。"""
    response = client.get("/api/v1/mental/conditions/anxiety")
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["data"]["id"] == "anxiety"
    assert "tcm_patterns" in data["data"]
    assert len(data["data"]["tcm_patterns"]) == 2


def test_get_low_mood_condition():
    """测试获取抑郁倾向详情。"""
    response = client.get("/api/v1/mental/conditions/low_mood")
    assert response.status_code == 200
    data = response.json()
    assert data["data"]["id"] == "low_mood"


def test_get_irritability_condition():
    """测试获取易怒详情。"""
    response = client.get("/api/v1/mental/conditions/irritability")
    assert response.status_code == 200
    data = response.json()
    assert data["data"]["id"] == "irritability"


def test_get_mood_swings_condition():
    """测试获取情绪波动详情。"""
    response = client.get("/api/v1/mental/conditions/mood_swings")
    assert response.status_code == 200
    data = response.json()
    assert data["data"]["id"] == "mood_swings"


def test_get_overthinking_condition():
    """测试获取思虑过度详情。"""
    response = client.get("/api/v1/mental/conditions/overthinking")
    assert response.status_code == 200
    data = response.json()
    assert data["data"]["id"] == "overthinking"


def test_condition_detail_contains_tcm_patterns():
    """测试情志问题详情包含TCM证型。"""
    response = client.get("/api/v1/mental/conditions/anxiety")
    patterns = response.json()["data"]["tcm_patterns"]

    for pattern in patterns:
        assert "pattern" in pattern
        assert "symptoms" in pattern
        assert "food_therapy" in pattern
        assert "acupoints" in pattern


def test_condition_detail_contains_breathing_exercises():
    """测试情志问题详情包含呼吸法。"""
    response = client.get("/api/v1/mental/conditions/anxiety")
    data = response.json()["data"]

    assert "breathing_exercises" in data
    assert len(data["breathing_exercises"]) > 0


def test_condition_detail_contains_lifestyle():
    """测试情志问题详情包含生活调理建议。"""
    response = client.get("/api/v1/mental/conditions/anxiety")
    data = response.json()["data"]

    assert "lifestyle_adjustments" in data
    assert len(data["lifestyle_adjustments"]) > 0


def test_condition_detail_contains_professional_help_reminder():
    """测试情志问题详情包含专业帮助提醒。"""
    response = client.get("/api/v1/mental/conditions/anxiety")
    data = response.json()["data"]

    assert "professional_help_reminder" in data
    assert "专业" in data["professional_help_reminder"]


def test_invalid_condition_id_returns_404():
    """测试无效情志ID返回404。"""
    response = client.get("/api/v1/mental/conditions/invalid_condition")
    assert response.status_code == 404


# ─────────────────────────────────────────────────────────────────────────────
# 测试：GET /api/v1/mental/five-elements-emotions
# ─────────────────────────────────────────────────────────────────────────────

def test_get_five_elements_emotions():
    """测试获取五行情志对应关系。"""
    response = client.get("/api/v1/mental/five-elements-emotions")
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert "data" in data
    assert "five_elements" in data["data"]


def test_five_elements_contains_all_emotions():
    """测试五行情志包含5种情绪。"""
    response = client.get("/api/v1/mental/five-elements-emotions")
    emotions = response.json()["data"]["five_elements"]

    expected_emotions = ["anger", "joy", "pensiveness", "sadness", "fear"]
    emotion_ids = [e["emotion_id"] for e in emotions]
    assert set(emotion_ids) == set(expected_emotions)


def test_five_elements_have_correct_mapping():
    """测试五行情志有正确的五脏对应。"""
    response = client.get("/api/v1/mental/five-elements-emotions")
    emotions = response.json()["data"]["five_elements"]

    mapping = {e["emotion_id"]: {"element": e["element"], "organ": e["organ"]} for e in emotions}

    assert mapping["anger"]["organ"] == "肝"
    assert mapping["anger"]["element"] == "木"
    assert mapping["joy"]["organ"] == "心"
    assert mapping["joy"]["element"] == "火"


def test_five_elements_contains_tcm_theory():
    """测试五行情志包含TCM理论说明。"""
    response = client.get("/api/v1/mental/five-elements-emotions")
    data = response.json()["data"]

    assert "tcm_theory" in data
    assert "五行" in data["tcm_theory"]


# ─────────────────────────────────────────────────────────────────────────────
# 测试：GET /api/v1/mental/meditation-guides
# ─────────────────────────────────────────────────────────────────────────────

def test_get_meditation_guides():
    """测试获取冥想引导列表。"""
    response = client.get("/api/v1/mental/meditation-guides")
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert "guides" in data["data"]
    assert data["data"]["total"] == 5


def test_meditation_guides_contain_required_fields():
    """测试冥想引导包含必需字段。"""
    response = client.get("/api/v1/mental/meditation-guides")
    guides = response.json()["data"]["guides"]

    for guide in guides:
        assert "id" in guide
        assert "name" in guide
        assert "duration_minutes" in guide
        assert "suitable_for" in guide


def test_meditation_guides_have_valid_durations():
    """测试冥想引导有有效的时长。"""
    response = client.get("/api/v1/mental/meditation-guides")
    guides = response.json()["data"]["guides"]

    for guide in guides:
        assert guide["duration_minutes"] > 0


# ─────────────────────────────────────────────────────────────────────────────
# 测试：GET /api/v1/mental/meditation-guides/{guide_id}
# ─────────────────────────────────────────────────────────────────────────────

def test_get_meditation_guide_detail():
    """测试获取冥想引导详情。"""
    response = client.get("/api/v1/mental/meditation-guides/heart_calming")
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert "data" in data


def test_meditation_guide_contains_steps():
    """测试冥想引导包含步骤。"""
    response = client.get("/api/v1/mental/meditation-guides/heart_calming")
    guide = response.json()["data"]

    assert "steps" in guide
    assert len(guide["steps"]) > 0


def test_meditation_guide_contains_tcm_theory():
    """测试冥想引导包含TCM理论。"""
    response = client.get("/api/v1/mental/meditation-guides/heart_calming")
    guide = response.json()["data"]

    assert "tcm_theory" in guide


def test_invalid_meditation_guide_id_returns_404():
    """测试无效冥想引导ID返回404。"""
    response = client.get("/api/v1/mental/meditation-guides/invalid_guide")
    assert response.status_code == 404


# ─────────────────────────────────────────────────────────────────────────────
# 测试：POST /api/v1/mental/check-in
# ─────────────────────────────────────────────────────────────────────────────

def test_checkin_with_valid_emotion():
    """测试有效情绪的打卡。"""
    response = client.post(
        "/api/v1/mental/check-in",
        json={"user_id": "user1", "dominant_emotion": "怒", "intensity": 3},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["data"]["checked_in"] is True


def test_checkin_with_all_emotions():
    """测试所有5种情绪的打卡。"""
    emotions = ["怒", "喜", "思", "悲", "恐"]

    for emotion in emotions:
        response = client.post(
            "/api/v1/mental/check-in",
            json={"user_id": "user_test", "dominant_emotion": emotion, "intensity": 2},
        )
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["emotion"] == emotion


def test_checkin_with_intensity_validation():
    """测试打卡强度验证（1-5）。"""
    # 有效强度
    for intensity in [1, 2, 3, 4, 5]:
        response = client.post(
            "/api/v1/mental/check-in",
            json={"user_id": "user2", "dominant_emotion": "思", "intensity": intensity},
        )
        assert response.status_code == 200


def test_checkin_with_invalid_intensity_below_range():
    """测试打卡强度验证（小于1应失败）。"""
    response = client.post(
        "/api/v1/mental/check-in",
        json={"user_id": "user3", "dominant_emotion": "悲", "intensity": 0},
    )
    assert response.status_code == 422


def test_checkin_with_invalid_intensity_above_range():
    """测试打卡强度验证（大于5应失败）。"""
    response = client.post(
        "/api/v1/mental/check-in",
        json={"user_id": "user4", "dominant_emotion": "恐", "intensity": 6},
    )
    assert response.status_code == 422


def test_checkin_with_invalid_emotion():
    """测试无效情绪返回422。"""
    response = client.post(
        "/api/v1/mental/check-in",
        json={"user_id": "user5", "dominant_emotion": "invalid", "intensity": 2},
    )
    assert response.status_code == 422


def test_checkin_with_notes():
    """测试打卡包含备注。"""
    response = client.post(
        "/api/v1/mental/check-in",
        json={"user_id": "user6", "dominant_emotion": "喜", "intensity": 4, "notes": "今天心情很好"},
    )
    assert response.status_code == 200


def test_checkin_response_contains_tcm_analysis():
    """测试打卡响应包含TCM分析。"""
    response = client.post(
        "/api/v1/mental/check-in",
        json={"user_id": "user7", "dominant_emotion": "怒", "intensity": 3},
    )
    data = response.json()["data"]

    assert "tcm_analysis" in data
    assert "organ" in data["tcm_analysis"]
    assert "element" in data["tcm_analysis"]


def test_checkin_response_contains_suggestions():
    """测试打卡响应包含调理建议。"""
    response = client.post(
        "/api/v1/mental/check-in",
        json={"user_id": "user8", "dominant_emotion": "思", "intensity": 2},
    )
    data = response.json()["data"]

    assert "suggestions" in data
    assert "immediate" in data["suggestions"]
    assert "short_term" in data["suggestions"]
    assert "long_term" in data["suggestions"]


def test_checkin_response_contains_professional_reminder():
    """测试打卡响应包含专业帮助提醒。"""
    response = client.post(
        "/api/v1/mental/check-in",
        json={"user_id": "user9", "dominant_emotion": "悲", "intensity": 4},
    )
    data = response.json()["data"]

    assert "professional_help_reminder" in data
    assert "专业" in data["professional_help_reminder"]


# ─────────────────────────────────────────────────────────────────────────────
# 测试：GET /api/v1/mental/crisis-resources
# ─────────────────────────────────────────────────────────────────────────────

def test_get_crisis_resources():
    """测试获取心理危机资源。"""
    response = client.get("/api/v1/mental/crisis-resources")
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert "data" in data


def test_crisis_resources_not_empty():
    """测试危机资源列表非空。"""
    response = client.get("/api/v1/mental/crisis-resources")
    resources = response.json()["data"]["resources"]

    assert len(resources) > 0


def test_crisis_resources_have_required_fields():
    """测试危机资源包含必需字段。"""
    response = client.get("/api/v1/mental/crisis-resources")
    resources = response.json()["data"]["resources"]

    for resource in resources:
        assert "region" in resource
        assert "organization" in resource
        assert "available" in resource
        assert "service" in resource


def test_crisis_resources_contain_china_resources():
    """测试危机资源包含中国资源。"""
    response = client.get("/api/v1/mental/crisis-resources")
    resources = response.json()["data"]["resources"]

    china_resources = [r for r in resources if r["region"] == "中国"]
    assert len(china_resources) > 0


def test_crisis_resources_contain_international_resources():
    """测试危机资源包含国际资源。"""
    response = client.get("/api/v1/mental/crisis-resources")
    resources = response.json()["data"]["resources"]

    intl_resources = [r for r in resources if r["region"] == "国际"]
    assert len(intl_resources) > 0


def test_crisis_resources_contains_emergency_note():
    """测试危机资源包含紧急提醒。"""
    response = client.get("/api/v1/mental/crisis-resources")
    data = response.json()["data"]

    assert "emergency_note" in data
    assert "危机" in data["emergency_note"] or "急" in data["emergency_note"]


def test_crisis_resources_contains_hotlines():
    """测试危机资源包含热线电话。"""
    response = client.get("/api/v1/mental/crisis-resources")
    data = response.json()["data"]

    assert "crisis_hotlines" in data
    assert "china" in data["crisis_hotlines"]
