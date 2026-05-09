"""
会员权益管理 (Membership Management) 测试套件
测试所有端点、默认免费等级、等级验证、剩余天数计算等。
"""

import pytest
from fastapi.testclient import TestClient
from app.router.membership import (
    router,
    _memberships,
    MEMBERSHIP_TIERS,
    DURATION_DISCOUNTS,
    _get_default_free_membership,
    _ensure_membership,
    _is_membership_active,
    _get_days_remaining,
)
from fastapi import FastAPI
from datetime import datetime, timedelta

# 创建测试应用
app = FastAPI()
app.include_router(router)
client = TestClient(app)


@pytest.fixture(autouse=True)
def clear_state():
    """每个测试前清空内存状态"""
    _memberships.clear()
    yield
    _memberships.clear()


# ─────────────────────────────────────────────────────────────────────────────
# GET /tiers 端点测试
# ─────────────────────────────────────────────────────────────────────────────

def test_list_tiers_returns_all_tiers():
    """获取所有会员等级"""
    response = client.get("/api/v1/membership/tiers")
    assert response.status_code == 200
    data = response.json()["data"]
    assert len(data["tiers"]) == 4
    tier_names = [t["tier"] for t in data["tiers"]]
    assert "free" in tier_names
    assert "basic" in tier_names
    assert "premium" in tier_names
    assert "family" in tier_names


def test_tiers_have_required_fields():
    """每个等级有必要字段"""
    response = client.get("/api/v1/membership/tiers")
    data = response.json()["data"]
    for tier in data["tiers"]:
        assert "tier" in tier
        assert "name" in tier
        assert "price_monthly" in tier
        assert "description" in tier
        assert "features" in tier


def test_tier_pricing():
    """等级价格正确"""
    response = client.get("/api/v1/membership/tiers")
    data = response.json()["data"]
    tier_dict = {t["tier"]: t for t in data["tiers"]}
    assert tier_dict["free"]["price_monthly"] == 0
    assert tier_dict["basic"]["price_monthly"] == 18
    assert tier_dict["premium"]["price_monthly"] == 38
    assert tier_dict["family"]["price_monthly"] == 58


def test_free_tier_basic_features():
    """免费版功能正确"""
    response = client.get("/api/v1/membership/tiers")
    data = response.json()["data"]
    free_tier = next(t for t in data["tiers"] if t["tier"] == "free")
    features = free_tier["features"]
    assert features["ai_questions_per_day"] == 3
    assert features["audio_per_day"] == 0
    assert features["companion"] == False


def test_premium_tier_unlimited_features():
    """高级版包含无限功能"""
    response = client.get("/api/v1/membership/tiers")
    data = response.json()["data"]
    premium_tier = next(t for t in data["tiers"] if t["tier"] == "premium")
    features = premium_tier["features"]
    assert features["ai_questions_per_day"] == float('inf')
    assert features["audio_per_day"] == float('inf')
    assert features["companion"] == True


def test_family_tier_5_members():
    """家庭版支持5个成员"""
    response = client.get("/api/v1/membership/tiers")
    data = response.json()["data"]
    family_tier = next(t for t in data["tiers"] if t["tier"] == "family")
    assert family_tier["features"]["family_members"] == 5


# ─────────────────────────────────────────────────────────────────────────────
# GET /user/{user_id} 端点测试
# ─────────────────────────────────────────────────────────────────────────────

def test_get_user_membership_default_free():
    """未激活的用户默认返回免费版"""
    response = client.get("/api/v1/membership/user/new_user")
    assert response.status_code == 200
    data = response.json()["data"]
    assert data["tier"] == "free"
    assert data["price_monthly"] == 0
    assert data["is_active"] == True


def test_get_user_membership_creates_default():
    """获取用户会员时自动创建默认档案"""
    response = client.get("/api/v1/membership/user/unknown_user")
    assert response.status_code == 200
    assert "unknown_user" in _memberships


def test_get_user_membership_free_never_expires():
    """免费版 expires_at 为 None"""
    response = client.get("/api/v1/membership/user/user1")
    data = response.json()["data"]
    assert data["expires_at"] is None
    assert data["days_remaining"] == -1


def test_get_user_membership_has_required_fields():
    """会员信息包含必要字段"""
    response = client.get("/api/v1/membership/user/user1")
    data = response.json()["data"]
    assert "user_id" in data
    assert "tier" in data
    assert "tier_name" in data
    assert "is_active" in data
    assert "features" in data


def test_get_user_membership_free_always_active():
    """免费版始终为活跃"""
    response = client.get("/api/v1/membership/user/user1")
    data = response.json()["data"]
    assert data["is_active"] == True


# ─────────────────────────────────────────────────────────────────────────────
# POST /activate 端点测试
# ─────────────────────────────────────────────────────────────────────────────

def test_activate_basic_tier_1_month():
    """激活基础版1个月"""
    response = client.post(
        "/api/v1/membership/activate",
        json={
            "user_id": "user1",
            "tier": "basic",
            "duration_months": 1,
        },
    )
    assert response.status_code == 200
    data = response.json()["data"]
    assert data["tier"] == "basic"
    assert data["duration_months"] == 1
    assert data["total_price"] == 18  # 18 * 1 * 1.0


def test_activate_applies_discount_3_months():
    """激活3个月应用5%折扣"""
    response = client.post(
        "/api/v1/membership/activate",
        json={
            "user_id": "user1",
            "tier": "basic",
            "duration_months": 3,
        },
    )
    data = response.json()["data"]
    assert data["discount_applied"] == 5
    assert data["total_price"] == 18 * 3 * 0.95


def test_activate_applies_discount_6_months():
    """激活6个月应用10%折扣"""
    response = client.post(
        "/api/v1/membership/activate",
        json={
            "user_id": "user1",
            "tier": "premium",
            "duration_months": 6,
        },
    )
    data = response.json()["data"]
    assert data["discount_applied"] == 10
    assert data["total_price"] == 38 * 6 * 0.90


def test_activate_applies_discount_12_months():
    """激活12个月应用15%折扣"""
    response = client.post(
        "/api/v1/membership/activate",
        json={
            "user_id": "user1",
            "tier": "family",
            "duration_months": 12,
        },
    )
    data = response.json()["data"]
    assert data["discount_applied"] == 15
    assert data["total_price"] == 58 * 12 * 0.85


def test_activate_sets_expiration():
    """激活后设置过期时间"""
    response = client.post(
        "/api/v1/membership/activate",
        json={
            "user_id": "user1",
            "tier": "basic",
            "duration_months": 1,
        },
    )
    data = response.json()["data"]
    assert data["expires_at"] is not None
    expires = datetime.fromisoformat(data["expires_at"])
    now = datetime.now()
    delta = (expires - now).days
    assert 29 <= delta <= 31  # 大约30天


def test_activate_free_tier_no_expiration():
    """激活免费版不设置过期"""
    response = client.post(
        "/api/v1/membership/activate",
        json={
            "user_id": "user1",
            "tier": "free",
            "duration_months": 1,
        },
    )
    data = response.json()["data"]
    assert data["expires_at"] is None


def test_activate_invalid_tier():
    """无效的等级被拒绝"""
    response = client.post(
        "/api/v1/membership/activate",
        json={
            "user_id": "user1",
            "tier": "gold",
            "duration_months": 1,
        },
    )
    assert response.status_code == 422


def test_activate_invalid_duration():
    """无效的期限被拒绝"""
    response = client.post(
        "/api/v1/membership/activate",
        json={
            "user_id": "user1",
            "tier": "basic",
            "duration_months": 2,
        },
    )
    assert response.status_code == 422


def test_activate_premium_includes_companion():
    """高级版包含AI伴侣"""
    response = client.post(
        "/api/v1/membership/activate",
        json={
            "user_id": "user1",
            "tier": "premium",
            "duration_months": 1,
        },
    )
    data = response.json()["data"]
    assert data["features"]["companion"] == True


def test_activate_basic_no_companion():
    """基础版不包含AI伴侣"""
    response = client.post(
        "/api/v1/membership/activate",
        json={
            "user_id": "user1",
            "tier": "basic",
            "duration_months": 1,
        },
    )
    data = response.json()["data"]
    assert data["features"]["companion"] == False


def test_activate_family_members_count():
    """家庭版支持5个成员"""
    response = client.post(
        "/api/v1/membership/activate",
        json={
            "user_id": "user1",
            "tier": "family",
            "duration_months": 1,
        },
    )
    data = response.json()["data"]
    assert data["features"]["family_members"] == 5


def test_activate_updates_membership_in_store():
    """激活后会员信息更新到存储"""
    client.post(
        "/api/v1/membership/activate",
        json={
            "user_id": "user1",
            "tier": "premium",
            "duration_months": 1,
        },
    )
    assert "user1" in _memberships
    assert _memberships["user1"]["tier"] == "premium"


def test_activate_returns_success_message():
    """激活返回成功消息"""
    response = client.post(
        "/api/v1/membership/activate",
        json={
            "user_id": "user1",
            "tier": "basic",
            "duration_months": 3,
        },
    )
    data = response.json()["data"]
    assert "message" in data
    assert "成功激活" in data["message"] or "激活" in data["message"]


# ─────────────────────────────────────────────────────────────────────────────
# GET /benefits/{tier} 端点测试
# ─────────────────────────────────────────────────────────────────────────────

def test_get_benefits_free_tier():
    """获取免费版权益"""
    response = client.get("/api/v1/membership/benefits/free")
    assert response.status_code == 200
    data = response.json()["data"]
    assert data["tier"] == "free"
    assert "benefits" in data
    assert len(data["benefits"]) > 0


def test_get_benefits_basic_tier():
    """获取基础版权益"""
    response = client.get("/api/v1/membership/benefits/basic")
    assert response.status_code == 200
    data = response.json()["data"]
    assert data["tier"] == "basic"
    assert data["price_monthly"] == 18


def test_get_benefits_premium_tier():
    """获取高级版权益"""
    response = client.get("/api/v1/membership/benefits/premium")
    assert response.status_code == 200
    data = response.json()["data"]
    assert data["tier"] == "premium"
    assert "无限" in str(data["benefits"])


def test_get_benefits_invalid_tier():
    """无效的等级返回404"""
    response = client.get("/api/v1/membership/benefits/platinum")
    assert response.status_code == 404


def test_get_benefits_case_insensitive():
    """等级名称不区分大小写"""
    response = client.get("/api/v1/membership/benefits/PREMIUM")
    assert response.status_code == 200
    data = response.json()["data"]
    assert data["tier"] == "premium"


def test_get_benefits_includes_companion_info():
    """权益详情包含AI伴侣信息"""
    response = client.get("/api/v1/membership/benefits/premium")
    data = response.json()["data"]
    benefits_text = str(data["benefits"])
    assert "伴侣" in benefits_text or "companion" in benefits_text.lower()


# ─────────────────────────────────────────────────────────────────────────────
# GET /compare 端点测试
# ─────────────────────────────────────────────────────────────────────────────

def test_compare_returns_all_tiers():
    """对比表包含所有等级"""
    response = client.get("/api/v1/membership/compare")
    assert response.status_code == 200
    data = response.json()["data"]
    assert len(data["tiers"]) == 4


def test_compare_has_feature_categories():
    """对比表包含功能分类"""
    response = client.get("/api/v1/membership/compare")
    data = response.json()["data"]
    assert "feature_categories" in data
    assert len(data["feature_categories"]) > 0


def test_compare_includes_ai_questions():
    """对比表包含AI问答次数对比"""
    response = client.get("/api/v1/membership/compare")
    data = response.json()["data"]
    for tier in data["tiers"]:
        assert "ai_questions" in tier


def test_compare_includes_pricing():
    """对比表包含价格信息"""
    response = client.get("/api/v1/membership/compare")
    data = response.json()["data"]
    for tier in data["tiers"]:
        assert "price" in tier


def test_compare_premium_shows_unlimited():
    """高级版对比显示无限"""
    response = client.get("/api/v1/membership/compare")
    data = response.json()["data"]
    premium = next(t for t in data["tiers"] if t["tier"] == "premium")
    assert "无限" in premium["ai_questions"]


# ─────────────────────────────────────────────────────────────────────────────
# 天数计算和激活状态测试
# ─────────────────────────────────────────────────────────────────────────────

def test_days_remaining_for_free():
    """免费版days_remaining=-1"""
    response = client.get("/api/v1/membership/user/user1")
    data = response.json()["data"]
    assert data["days_remaining"] == -1


def test_days_remaining_for_active_paid():
    """有效的付费版显示剩余天数"""
    client.post(
        "/api/v1/membership/activate",
        json={
            "user_id": "user1",
            "tier": "basic",
            "duration_months": 1,
        },
    )
    response = client.get("/api/v1/membership/user/user1")
    data = response.json()["data"]
    assert data["days_remaining"] > 0
    assert data["days_remaining"] <= 31


def test_days_remaining_calculates_correctly():
    """剩余天数计算准确"""
    client.post(
        "/api/v1/membership/activate",
        json={
            "user_id": "user1",
            "tier": "premium",
            "duration_months": 3,
        },
    )
    response = client.get("/api/v1/membership/user/user1")
    data = response.json()["data"]
    # 3个月 ≈ 90天
    assert 85 <= data["days_remaining"] <= 92


def test_expired_membership_shows_0_days():
    """过期的会员显示0天剩余"""
    # 手动设置过期的会员
    _memberships["user1"] = {
        "tier": "basic",
        "activated_at": datetime.now().isoformat(),
        "expires_at": (datetime.now() - timedelta(days=1)).isoformat(),
        "features": MEMBERSHIP_TIERS["basic"]["features"].copy(),
    }
    response = client.get("/api/v1/membership/user/user1")
    data = response.json()["data"]
    assert data["days_remaining"] == 0


def test_expired_membership_not_active():
    """过期会员状态为不活跃"""
    _memberships["user1"] = {
        "tier": "basic",
        "activated_at": datetime.now().isoformat(),
        "expires_at": (datetime.now() - timedelta(days=1)).isoformat(),
        "features": MEMBERSHIP_TIERS["basic"]["features"].copy(),
    }
    response = client.get("/api/v1/membership/user/user1")
    data = response.json()["data"]
    assert data["is_active"] == False


# ─────────────────────────────────────────────────────────────────────────────
# 多用户隔离测试
# ─────────────────────────────────────────────────────────────────────────────

def test_different_users_different_tiers():
    """不同用户可有不同的会员等级"""
    client.post(
        "/api/v1/membership/activate",
        json={"user_id": "user1", "tier": "basic", "duration_months": 1},
    )
    client.post(
        "/api/v1/membership/activate",
        json={"user_id": "user2", "tier": "premium", "duration_months": 1},
    )
    response1 = client.get("/api/v1/membership/user/user1")
    response2 = client.get("/api/v1/membership/user/user2")
    assert response1.json()["data"]["tier"] == "basic"
    assert response2.json()["data"]["tier"] == "premium"


def test_user_upgrade_changes_tier():
    """用户可以升级会员等级"""
    client.post(
        "/api/v1/membership/activate",
        json={"user_id": "user1", "tier": "basic", "duration_months": 1},
    )
    assert _memberships["user1"]["tier"] == "basic"

    client.post(
        "/api/v1/membership/activate",
        json={"user_id": "user1", "tier": "premium", "duration_months": 1},
    )
    assert _memberships["user1"]["tier"] == "premium"


# ─────────────────────────────────────────────────────────────────────────────
# 内存函数测试
# ─────────────────────────────────────────────────────────────────────────────

def test_get_default_free_membership():
    """获取默认免费会员"""
    membership = _get_default_free_membership()
    assert membership["tier"] == "free"
    assert membership["expires_at"] is None
    assert membership["features"]["ai_questions_per_day"] == 3


def test_ensure_membership_creates_default():
    """ensure_membership 创建默认档案"""
    membership = _ensure_membership("new_user")
    assert membership["tier"] == "free"
    assert "new_user" in _memberships


def test_is_membership_active_free():
    """免费版始终活跃"""
    membership = _get_default_free_membership()
    assert _is_membership_active(membership) == True


def test_is_membership_active_future():
    """未来过期日期的会员为活跃"""
    membership = {
        "tier": "basic",
        "activated_at": datetime.now().isoformat(),
        "expires_at": (datetime.now() + timedelta(days=30)).isoformat(),
        "features": {},
    }
    assert _is_membership_active(membership) == True


def test_is_membership_active_past():
    """过去过期日期的会员为不活跃"""
    membership = {
        "tier": "basic",
        "activated_at": datetime.now().isoformat(),
        "expires_at": (datetime.now() - timedelta(days=1)).isoformat(),
        "features": {},
    }
    assert _is_membership_active(membership) == False


def test_get_days_remaining_free():
    """免费版返回-1"""
    membership = _get_default_free_membership()
    assert _get_days_remaining(membership) == -1


def test_get_days_remaining_positive():
    """有效期未来显示正数天数"""
    membership = {
        "tier": "basic",
        "activated_at": datetime.now().isoformat(),
        "expires_at": (datetime.now() + timedelta(days=30)).isoformat(),
        "features": {},
    }
    days = _get_days_remaining(membership)
    assert 28 <= days <= 30


# ─────────────────────────────────────────────────────────────────────────────
# 边界和错误处理测试
# ─────────────────────────────────────────────────────────────────────────────

def test_empty_user_id():
    """空user_id被接受"""
    response = client.get("/api/v1/membership/user/")
    # FastAPI 路由可能返回404（未找到路由）或其他状态
    # 但我们可以用空字符串的user_id尝试
    response = client.get("/api/v1/membership/user/")
    assert response.status_code in [200, 404]


def test_special_characters_user_id():
    """user_id可包含特殊字符"""
    response = client.post(
        "/api/v1/membership/activate",
        json={
            "user_id": "user-123_abc@test",
            "tier": "basic",
            "duration_months": 1,
        },
    )
    assert response.status_code == 200


def test_unicode_user_id():
    """user_id支持unicode"""
    response = client.post(
        "/api/v1/membership/activate",
        json={
            "user_id": "用户123",
            "tier": "basic",
            "duration_months": 1,
        },
    )
    assert response.status_code == 200


def test_pricing_calculations_accuracy():
    """价格计算精确"""
    # 基础18元，6个月，10%折扣
    # 18 * 6 * 0.9 = 97.2
    response = client.post(
        "/api/v1/membership/activate",
        json={
            "user_id": "user1",
            "tier": "basic",
            "duration_months": 6,
        },
    )
    data = response.json()["data"]
    assert data["total_price"] == 18 * 6 * 0.9


def test_all_duration_options_supported():
    """支持所有时长选项"""
    for duration in [1, 3, 6, 12]:
        response = client.post(
            "/api/v1/membership/activate",
            json={
                "user_id": f"user_{duration}",
                "tier": "basic",
                "duration_months": duration,
            },
        )
        assert response.status_code == 200
