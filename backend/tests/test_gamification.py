"""
顺时 — 成就与激励系统 API 测试
至少35个测试，包含徽章分类过滤、新用户初始状态、颁发徽章、打卡连续天数、积分升级、排行榜匿名化
"""

import pytest
from fastapi.testclient import TestClient
from app.router.gamification import router

# 创建测试客户端
from fastapi import FastAPI
app = FastAPI()
app.include_router(router)
client = TestClient(app)


# ─────────────────────────────────────────────────────────────────────────────
# 测试：GET /api/v1/gamification/badges
# ─────────────────────────────────────────────────────────────────────────────

def test_get_all_badges():
    """测试获取所有徽章。"""
    response = client.get("/api/v1/gamification/badges")
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert "badges" in data["data"]


def test_badges_list_contains_minimum_20():
    """测试徽章列表至少包含20个。"""
    response = client.get("/api/v1/gamification/badges")
    badges = response.json()["data"]["badges"]

    assert len(badges) >= 20


def test_badge_has_required_fields():
    """测试每个徽章包含必需字段。"""
    response = client.get("/api/v1/gamification/badges")
    badges = response.json()["data"]["badges"]

    for badge in badges:
        assert "id" in badge
        assert "name" in badge
        assert "description" in badge
        assert "category" in badge
        assert "icon_hint" in badge
        assert "points" in badge
        assert "rarity" in badge


def test_badges_by_category_filter():
    """测试按分类过滤徽章。"""
    categories = ["checkin", "solar_term", "constitution", "food_therapy", "exercise", "meditation"]

    for category in categories:
        response = client.get(f"/api/v1/gamification/badges?category={category}")
        assert response.status_code == 200
        badges = response.json()["data"]["badges"]
        assert all(b["category"] == category for b in badges)


def test_badges_by_rarity_filter():
    """测试按稀有度过滤徽章。"""
    rarities = ["common", "rare", "epic", "legendary"]

    for rarity in rarities:
        response = client.get(f"/api/v1/gamification/badges?rarity={rarity}")
        assert response.status_code == 200
        badges = response.json()["data"]["badges"]
        assert all(b["rarity"] == rarity for b in badges)


def test_badges_by_category_and_rarity_filter():
    """测试同时按分类和稀有度过滤徽章。"""
    response = client.get("/api/v1/gamification/badges?category=checkin&rarity=legendary")
    assert response.status_code == 200
    badges = response.json()["data"]["badges"]
    assert all(b["category"] == "checkin" and b["rarity"] == "legendary" for b in badges)


def test_badges_contain_all_categories():
    """测试徽章包含所有分类。"""
    response = client.get("/api/v1/gamification/badges")
    badges = response.json()["data"]["badges"]

    categories = set(b["category"] for b in badges)
    expected = {"checkin", "solar_term", "constitution", "food_therapy", "exercise", "meditation"}
    assert expected.issubset(categories)


# ─────────────────────────────────────────────────────────────────────────────
# 测试：GET /api/v1/gamification/badges/{badge_id}
# ─────────────────────────────────────────────────────────────────────────────

def test_get_specific_badge():
    """测试获取特定徽章。"""
    response = client.get("/api/v1/gamification/badges/checkin_7")
    assert response.status_code == 200
    data = response.json()
    assert data["data"]["id"] == "checkin_7"


def test_badge_detail_contains_unlock_condition():
    """测试徽章详情包含解锁条件。"""
    response = client.get("/api/v1/gamification/badges/checkin_7")
    badge = response.json()["data"]

    assert "unlock_condition" in badge


def test_invalid_badge_id_returns_404():
    """测试无效徽章ID返回404。"""
    response = client.get("/api/v1/gamification/badges/invalid_badge")
    assert response.status_code == 404


# ─────────────────────────────────────────────────────────────────────────────
# 测试：GET /api/v1/gamification/user/{user_id}
# ─────────────────────────────────────────────────────────────────────────────

def test_new_user_initial_state():
    """测试新用户初始状态。"""
    response = client.get("/api/v1/gamification/user/new_user_test_123")
    assert response.status_code == 200
    data = response.json()["data"]

    assert data["points"] == 0
    assert data["level"] == 1
    assert data["badges_unlocked"] == []
    assert data["streak_days"] == 0
    assert data["total_checkins"] == 0


def test_user_achievements_response_structure():
    """测试用户成就响应结构。"""
    response = client.get("/api/v1/gamification/user/user_test_1")
    assert response.status_code == 200
    data = response.json()["data"]

    required_fields = ["user_id", "points", "level", "level_name", "badges_unlocked", "badge_count", "streak_days", "total_checkins"]
    assert all(field in data for field in required_fields)


# ─────────────────────────────────────────────────────────────────────────────
# 测试：POST /api/v1/gamification/award
# ─────────────────────────────────────────────────────────────────────────────

def test_award_badge_new_unlock():
    """测试颁发新徽章时的解锁。"""
    response = client.post(
        "/api/v1/gamification/award",
        json={"user_id": "award_user_1", "badge_id": "checkin_7", "reason": "连续打卡7天"},
    )
    assert response.status_code == 200
    data = response.json()["data"]

    assert data["awarded"] is True
    assert data["is_new_unlock"] is True
    assert data["points_earned"] > 0


def test_award_badge_duplicate():
    """测试重复颁发徽章不增加积分。"""
    # 第一次颁发
    client.post(
        "/api/v1/gamification/award",
        json={"user_id": "award_user_2", "badge_id": "meditation_first", "reason": "第一次冥想"},
    )

    # 第二次颁发
    response = client.post(
        "/api/v1/gamification/award",
        json={"user_id": "award_user_2", "badge_id": "meditation_first", "reason": "重复颁发"},
    )
    data = response.json()["data"]

    assert data["awarded"] is True
    assert data["is_new_unlock"] is False
    assert data["points_earned"] == 0


def test_award_invalid_badge():
    """测试颁发无效徽章返回404。"""
    response = client.post(
        "/api/v1/gamification/award",
        json={"user_id": "award_user_3", "badge_id": "invalid_badge", "reason": "测试"},
    )
    assert response.status_code == 404


def test_award_badge_updates_user_level():
    """测试颁发徽章后更新用户等级。"""
    # 颁发多个高分徽章以提升等级
    badges_to_award = [
        "checkin_7",
        "checkin_30",
        "solar_term_first",
        "constitution_test",
    ]

    for badge_id in badges_to_award:
        client.post(
            "/api/v1/gamification/award",
            json={"user_id": "level_user_1", "badge_id": badge_id, "reason": "测试升级"},
        )

    # 检查用户等级
    response = client.get("/api/v1/gamification/user/level_user_1")
    user_level = response.json()["data"]["level"]
    assert user_level >= 2  # 应该至少升到等级2


# ─────────────────────────────────────────────────────────────────────────────
# 测试：POST /api/v1/gamification/checkin
# ─────────────────────────────────────────────────────────────────────────────

def test_checkin_first_time():
    """测试首次打卡。"""
    response = client.post(
        "/api/v1/gamification/checkin",
        json={"user_id": "checkin_user_1"},
    )
    assert response.status_code == 200
    data = response.json()["data"]

    assert data["checked_in"] is True
    assert data["current_streak"] == 1
    assert data["points_earned"] > 0


def test_checkin_same_day_fails():
    """测试同一天打卡两次失败。"""
    user_id = "checkin_user_2"
    # 第一次打卡
    client.post("/api/v1/gamification/checkin", json={"user_id": user_id})

    # 第二次打卡
    response = client.post(
        "/api/v1/gamification/checkin",
        json={"user_id": user_id},
    )
    assert response.status_code == 200
    data = response.json()["data"]
    assert data["checked_in"] is False


def test_checkin_increments_streak():
    """测试打卡增加连续天数计数（模拟）。"""
    # 由于我们无法真实改变日期，我们验证结构是正确的
    response = client.post(
        "/api/v1/gamification/checkin",
        json={"user_id": "checkin_user_3"},
    )
    assert response.status_code == 200
    data = response.json()["data"]

    assert "current_streak" in data
    assert data["current_streak"] >= 1


def test_checkin_response_contains_milestone_message():
    """测试打卡响应包含里程碑提醒。"""
    response = client.post(
        "/api/v1/gamification/checkin",
        json={"user_id": "checkin_user_4"},
    )
    assert response.status_code == 200
    data = response.json()["data"]

    assert "milestone_message" in data


def test_checkin_updates_total_checkins():
    """测试打卡更新总打卡次数。"""
    user_id = "checkin_user_5"

    # 首次打卡
    client.post("/api/v1/gamification/checkin", json={"user_id": user_id})

    # 检查用户总打卡次数
    response = client.get(f"/api/v1/gamification/user/{user_id}")
    user_data = response.json()["data"]

    assert user_data["total_checkins"] >= 1


# ─────────────────────────────────────────────────────────────────────────────
# 测试：GET /api/v1/gamification/leaderboard
# ─────────────────────────────────────────────────────────────────────────────

def test_get_leaderboard():
    """测试获取排行榜。"""
    # 先创建一些用户数据
    for i in range(5):
        for j in range(i + 1):
            client.post(
                "/api/v1/gamification/award",
                json={"user_id": f"leaderboard_user_{i}", "badge_id": "checkin_7", "reason": "测试"},
            )

    response = client.get("/api/v1/gamification/leaderboard")
    assert response.status_code == 200
    data = response.json()["data"]

    assert "leaderboard" in data
    assert "total_users" in data
    assert "limit" in data


def test_leaderboard_default_limit():
    """测试排行榜默认限制（10）。"""
    response = client.get("/api/v1/gamification/leaderboard")
    leaderboard = response.json()["data"]["leaderboard"]

    # 默认限制应该是10或更少（取决于用户数量）
    assert len(leaderboard) <= 10


def test_leaderboard_custom_limit():
    """测试排行榜自定义限制。"""
    response = client.get("/api/v1/gamification/leaderboard?limit=5")
    leaderboard = response.json()["data"]["leaderboard"]

    assert len(leaderboard) <= 5


def test_leaderboard_sorted_by_points():
    """测试排行榜按积分降序排列。"""
    # 先颁发不同数量的徽章给不同用户
    for i in range(3):
        for j in range(i + 2):  # user_0: 2个, user_1: 3个, user_2: 4个
            client.post(
                "/api/v1/gamification/award",
                json={"user_id": f"sort_user_{i}", "badge_id": "meditation_first", "reason": "测试排序"},
            )

    response = client.get("/api/v1/gamification/leaderboard?limit=10")
    leaderboard = response.json()["data"]["leaderboard"]

    # 验证排序（积分应该递减）
    for i in range(len(leaderboard) - 1):
        assert leaderboard[i]["points"] >= leaderboard[i + 1]["points"]


def test_leaderboard_anonymized_user_ids():
    """测试排行榜用户ID被匿名化。"""
    response = client.get("/api/v1/gamification/leaderboard")
    leaderboard = response.json()["data"]["leaderboard"]

    for entry in leaderboard:
        # user_id应该被截断为前4位+**
        user_id = entry["user_id"]
        assert user_id.endswith("**") or user_id == "**"


def test_leaderboard_contains_user_level():
    """测试排行榜包含用户等级。"""
    response = client.get("/api/v1/gamification/leaderboard")
    leaderboard = response.json()["data"]["leaderboard"]

    for entry in leaderboard:
        assert "level" in entry
        assert entry["level"] >= 1


def test_leaderboard_contains_badges_count():
    """测试排行榜包含徽章数量。"""
    response = client.get("/api/v1/gamification/leaderboard")
    leaderboard = response.json()["data"]["leaderboard"]

    for entry in leaderboard:
        assert "badges_count" in entry


# ─────────────────────────────────────────────────────────────────────────────
# 测试：GET /api/v1/gamification/levels
# ─────────────────────────────────────────────────────────────────────────────

def test_get_levels():
    """测试获取等级系统说明。"""
    response = client.get("/api/v1/gamification/levels")
    assert response.status_code == 200
    data = response.json()["data"]

    assert "levels" in data
    assert "description" in data
    assert "level_benefits" in data


def test_levels_contain_5_levels():
    """测试等级系统包含5个等级。"""
    response = client.get("/api/v1/gamification/levels")
    levels = response.json()["data"]["levels"]

    assert len(levels) == 5


def test_levels_progression():
    """测试等级积分范围递增。"""
    response = client.get("/api/v1/gamification/levels")
    levels = response.json()["data"]["levels"]

    for i in range(len(levels) - 1):
        assert levels[i]["max_points"] < levels[i + 1]["min_points"]


def test_level_names_correct():
    """测试等级名称正确。"""
    response = client.get("/api/v1/gamification/levels")
    levels = response.json()["data"]["levels"]

    expected_names = ["初学者", "养生入门", "顺时学者", "健康达人", "养生大师"]
    actual_names = [l["name"] for l in levels]

    assert actual_names == expected_names


def test_level_benefits_exist():
    """测试每个等级有对应的福利说明。"""
    response = client.get("/api/v1/gamification/levels")
    benefits = response.json()["data"]["level_benefits"]

    assert len(benefits) == 5
    for level in range(1, 6):
        assert str(level) in benefits or level in benefits


# ─────────────────────────────────────────────────────────────────────────────
# 集成测试
# ─────────────────────────────────────────────────────────────────────────────

def test_user_progression_flow():
    """测试用户成就进展流程。"""
    user_id = "progression_user"

    # 初始状态
    response = client.get(f"/api/v1/gamification/user/{user_id}")
    assert response.json()["data"]["points"] == 0

    # 颁发徽章
    client.post(
        "/api/v1/gamification/award",
        json={"user_id": user_id, "badge_id": "meditation_first", "reason": "冥想"},
    )

    # 检查积分增加
    response = client.get(f"/api/v1/gamification/user/{user_id}")
    assert response.json()["data"]["points"] > 0
    assert "meditation_first" in response.json()["data"]["badges_unlocked"]


def test_badge_filtering_combinations():
    """测试多个过滤条件的组合。"""
    # 测试分类过滤
    response = client.get("/api/v1/gamification/badges?category=checkin")
    checkin_badges = response.json()["data"]["badges"]
    assert all(b["category"] == "checkin" for b in checkin_badges)

    # 测试稀有度过滤
    response = client.get("/api/v1/gamification/badges?rarity=epic")
    epic_badges = response.json()["data"]["badges"]
    assert all(b["rarity"] == "epic" for b in epic_badges)
