"""
AI伴侣 (AI Companion) 测试套件
测试所有端点、档案创建、亲密度追踪、历史分页等功能。
"""

import pytest
from fastapi.testclient import TestClient
from app.router.ai_companion import (
    router,
    _profiles,
    _messages,
    COMPANION_NAME,
    _ensure_profile,
)
from fastapi import FastAPI

# 创建测试应用
app = FastAPI()
app.include_router(router)
client = TestClient(app)


@pytest.fixture(autouse=True)
def clear_state():
    """每个测试前清空内存状态"""
    _profiles.clear()
    _messages.clear()
    yield
    _profiles.clear()
    _messages.clear()


# ─────────────────────────────────────────────────────────────────────────────
# POST /greet 端点测试
# ─────────────────────────────────────────────────────────────────────────────

def test_greet_basic():
    """基础问候——新用户"""
    response = client.post("/api/v1/companion/greet", json={"user_id": "user1"})
    assert response.status_code == 200
    data = response.json()["data"]
    assert data["companion_name"] == COMPANION_NAME
    assert "greeting" in data
    assert "season" in data
    assert "time_period" in data


def test_greet_with_user_name():
    """问候——带用户名"""
    response = client.post(
        "/api/v1/companion/greet",
        json={"user_id": "user1", "user_name": "小李"},
    )
    assert response.status_code == 200
    assert "user1" in _profiles


def test_greet_with_constitution():
    """问候——带体质类型"""
    response = client.post(
        "/api/v1/companion/greet",
        json={
            "user_id": "user1",
            "user_name": "小李",
            "constitution_type": "阳虚",
        },
    )
    assert response.status_code == 200
    assert _profiles["user1"]["constitution_type"] == "阳虚"


def test_greet_increments_interactions():
    """每次问候，交互计数+1"""
    response1 = client.post("/api/v1/companion/greet", json={"user_id": "user1"})
    interactions1 = response1.json()["data"]["intimacy_level"]

    response2 = client.post("/api/v1/companion/greet", json={"user_id": "user1"})
    interactions2 = response2.json()["data"]["intimacy_level"]

    assert _profiles["user1"]["total_interactions"] == 2


def test_greet_updates_last_seen():
    """问候更新 last_seen 时间戳"""
    response = client.post("/api/v1/companion/greet", json={"user_id": "user1"})
    assert "last_seen" in _profiles["user1"]
    assert _profiles["user1"]["last_seen"] is not None


def test_greet_adds_to_history():
    """问候添加到消息历史"""
    response = client.post("/api/v1/companion/greet", json={"user_id": "user1"})
    assert "user1" in _messages
    assert len(_messages["user1"]) > 0


def test_greet_returns_seasonal_insight():
    """问候包含季节性信息"""
    response = client.post("/api/v1/companion/greet", json={"user_id": "user1"})
    data = response.json()["data"]
    assert "seasonal_insight" in data
    assert "seasonal_advice" in data


# ─────────────────────────────────────────────────────────────────────────────
# POST /check-in 端点测试
# ─────────────────────────────────────────────────────────────────────────────

def test_checkin_basic():
    """基础签到"""
    response = client.post(
        "/api/v1/companion/check-in",
        json={"user_id": "user1", "mood": 3, "energy": 3},
    )
    assert response.status_code == 200
    data = response.json()["data"]
    assert data["mood"] == 3
    assert data["energy"] == 3
    assert "response" in data


def test_checkin_with_notes():
    """签到带备注"""
    response = client.post(
        "/api/v1/companion/check-in",
        json={
            "user_id": "user1",
            "mood": 2,
            "energy": 2,
            "notes": "今天工作很累",
        },
    )
    assert response.status_code == 200
    assert len(_messages["user1"]) > 0


def test_checkin_all_mood_energy_combinations():
    """测试所有心情-精力组合"""
    for mood in range(1, 6):
        for energy in range(1, 6):
            response = client.post(
                "/api/v1/companion/check-in",
                json={
                    "user_id": f"user_{mood}_{energy}",
                    "mood": mood,
                    "energy": energy,
                },
            )
            assert response.status_code == 200
            data = response.json()["data"]
            assert "response" in data


def test_checkin_invalid_mood():
    """无效的心情值（<1）"""
    response = client.post(
        "/api/v1/companion/check-in",
        json={"user_id": "user1", "mood": 0, "energy": 3},
    )
    assert response.status_code == 422


def test_checkin_invalid_energy():
    """无效的精力值（>5）"""
    response = client.post(
        "/api/v1/companion/check-in",
        json={"user_id": "user1", "mood": 3, "energy": 6},
    )
    assert response.status_code == 422


def test_checkin_creates_profile_if_missing():
    """签到时自动创建档案"""
    response = client.post(
        "/api/v1/companion/check-in",
        json={"user_id": "new_user", "mood": 3, "energy": 3},
    )
    assert response.status_code == 200
    assert "new_user" in _profiles


def test_checkin_increments_interactions():
    """签到增加交互计数"""
    client.post(
        "/api/v1/companion/check-in",
        json={"user_id": "user1", "mood": 3, "energy": 3},
    )
    assert _profiles["user1"]["total_interactions"] == 1

    client.post(
        "/api/v1/companion/check-in",
        json={"user_id": "user1", "mood": 4, "energy": 4},
    )
    assert _profiles["user1"]["total_interactions"] == 2


def test_checkin_includes_seasonal_practice():
    """签到返回季节实践建议"""
    response = client.post(
        "/api/v1/companion/check-in",
        json={"user_id": "user1", "mood": 3, "energy": 3},
    )
    data = response.json()["data"]
    assert "seasonal_practice" in data


def test_checkin_low_mood_low_energy():
    """低心情低精力时的特殊响应"""
    response = client.post(
        "/api/v1/companion/check-in",
        json={"user_id": "user1", "mood": 1, "energy": 1},
    )
    data = response.json()["data"]
    assert "休息" in data["response"] or "充电" in data["response"]


def test_checkin_high_mood_high_energy():
    """高心情高精力时的特殊响应"""
    response = client.post(
        "/api/v1/companion/check-in",
        json={"user_id": "user1", "mood": 5, "energy": 5},
    )
    data = response.json()["data"]
    response_text = data["response"]
    assert len(response_text) > 0


# ─────────────────────────────────────────────────────────────────────────────
# GET /profile/{user_id} 端点测试
# ─────────────────────────────────────────────────────────────────────────────

def test_get_profile_existing_user():
    """获取已存在用户的档案"""
    client.post("/api/v1/companion/greet", json={"user_id": "user1"})
    response = client.get("/api/v1/companion/profile/user1")
    assert response.status_code == 200
    data = response.json()["data"]
    assert data["user_id"] == "user1"
    assert "companion_name" in data
    assert "intimacy_level" in data
    assert "total_interactions" in data


def test_get_profile_new_user():
    """获取新用户档案（自动创建）"""
    response = client.get("/api/v1/companion/profile/new_user")
    assert response.status_code == 200
    data = response.json()["data"]
    assert data["user_id"] == "new_user"
    assert data["intimacy_level"] == 1


def test_get_profile_has_companion_name():
    """档案包含伴侣名字"""
    client.post("/api/v1/companion/greet", json={"user_id": "user1"})
    response = client.get("/api/v1/companion/profile/user1")
    data = response.json()["data"]
    assert data["companion_name"] == COMPANION_NAME


def test_get_profile_tracks_interactions():
    """档案正确追踪交互计数"""
    client.post("/api/v1/companion/greet", json={"user_id": "user1"})
    client.post(
        "/api/v1/companion/check-in",
        json={"user_id": "user1", "mood": 3, "energy": 3},
    )
    response = client.get("/api/v1/companion/profile/user1")
    data = response.json()["data"]
    assert data["total_interactions"] == 2


def test_get_profile_constitution_type():
    """档案保存体质类型"""
    client.post(
        "/api/v1/companion/greet",
        json={
            "user_id": "user1",
            "constitution_type": "痰湿",
        },
    )
    response = client.get("/api/v1/companion/profile/user1")
    data = response.json()["data"]
    assert data["constitution_type"] == "痰湿"


# ─────────────────────────────────────────────────────────────────────────────
# GET /history/{user_id} 端点测试
# ─────────────────────────────────────────────────────────────────────────────

def test_get_history_empty():
    """新用户历史为空"""
    response = client.get("/api/v1/companion/history/user1")
    assert response.status_code == 200
    data = response.json()["data"]
    assert data["messages"] == []
    assert data["total"] == 0


def test_get_history_after_greet():
    """问候后历史有记录"""
    client.post("/api/v1/companion/greet", json={"user_id": "user1"})
    response = client.get("/api/v1/companion/history/user1")
    data = response.json()["data"]
    assert len(data["messages"]) > 0


def test_get_history_pagination():
    """历史分页——limit参数"""
    for i in range(10):
        client.post(
            "/api/v1/companion/check-in",
            json={"user_id": "user1", "mood": 3, "energy": 3},
        )

    response = client.get("/api/v1/companion/history/user1?limit=5")
    data = response.json()["data"]
    assert len(data["messages"]) <= 5
    assert data["total"] >= 5


def test_get_history_default_limit():
    """历史默认limit=20"""
    for i in range(30):
        client.post(
            "/api/v1/companion/check-in",
            json={"user_id": "user1", "mood": 3, "energy": 3},
        )

    response = client.get("/api/v1/companion/history/user1")
    data = response.json()["data"]
    assert len(data["messages"]) <= 20


def test_get_history_limit_capped_at_50():
    """历史limit最多50"""
    for i in range(60):
        client.post(
            "/api/v1/companion/check-in",
            json={"user_id": "user1", "mood": 3, "energy": 3},
        )

    response = client.get("/api/v1/companion/history/user1?limit=100")
    data = response.json()["data"]
    assert len(data["messages"]) <= 50


def test_get_history_messages_have_timestamps():
    """历史消息有时间戳"""
    client.post("/api/v1/companion/greet", json={"user_id": "user1"})
    response = client.get("/api/v1/companion/history/user1")
    data = response.json()["data"]
    for msg in data["messages"]:
        assert "timestamp" in msg
        assert "role" in msg
        assert "content" in msg


def test_get_history_role_types():
    """历史消息角色为 user 或 assistant"""
    client.post("/api/v1/companion/greet", json={"user_id": "user1"})
    client.post(
        "/api/v1/companion/check-in",
        json={"user_id": "user1", "mood": 3, "energy": 3},
    )
    response = client.get("/api/v1/companion/history/user1")
    data = response.json()["data"]
    roles = [msg["role"] for msg in data["messages"]]
    assert all(role in ["user", "assistant"] for role in roles)


def test_get_history_max_size_50():
    """消息历史最多保留50条"""
    for i in range(100):
        client.post(
            "/api/v1/companion/check-in",
            json={"user_id": "user1", "mood": 3, "energy": 3},
        )

    assert len(_messages["user1"]) <= 50


# ─────────────────────────────────────────────────────────────────────────────
# POST /nudge/{user_id} 端点测试
# ─────────────────────────────────────────────────────────────────────────────

def test_nudge_basic():
    """基础养护建议"""
    response = client.post("/api/v1/companion/nudge/user1")
    assert response.status_code == 200
    data = response.json()["data"]
    assert "nudge" in data
    assert "season" in data
    assert data["companion_name"] == COMPANION_NAME


def test_nudge_returns_non_empty_nudge():
    """建议不为空"""
    response = client.post("/api/v1/companion/nudge/user1")
    data = response.json()["data"]
    assert len(data["nudge"]) > 0


def test_nudge_seasonal_content():
    """建议包含季节内容"""
    response = client.post("/api/v1/companion/nudge/user1")
    data = response.json()["data"]
    season = data["season"]
    assert season in ["spring", "summer", "autumn", "winter"]


def test_nudge_updates_last_seen():
    """建议更新 last_seen"""
    client.post("/api/v1/companion/nudge/user1")
    assert _profiles["user1"]["last_seen"] is not None


def test_nudge_creates_profile_if_missing():
    """建议自动创建档案"""
    response = client.post("/api/v1/companion/nudge/new_user")
    assert response.status_code == 200
    assert "new_user" in _profiles


def test_nudge_randomization():
    """建议随机化（多次调用返回不同内容——概率性）"""
    nudges = set()
    for i in range(20):
        response = client.post(f"/api/v1/companion/nudge/user{i}")
        nudges.add(response.json()["data"]["nudge"])

    # 由于每个季节有4+条建议，多次调用应该至少得到2种不同的建议
    assert len(nudges) >= 2


# ─────────────────────────────────────────────────────────────────────────────
# 亲密度追踪测试
# ─────────────────────────────────────────────────────────────────────────────

def test_intimacy_starts_at_1():
    """新用户亲密度从1开始"""
    client.post("/api/v1/companion/greet", json={"user_id": "user1"})
    assert _profiles["user1"]["intimacy_level"] == 1


def test_intimacy_increases_slowly():
    """亲密度缓慢增长（每5次交互+1）"""
    for i in range(5):
        client.post("/api/v1/companion/greet", json={"user_id": "user1"})

    initial_intimacy = _profiles["user1"]["intimacy_level"]

    for i in range(5):
        client.post("/api/v1/companion/greet", json={"user_id": "user1"})

    final_intimacy = _profiles["user1"]["intimacy_level"]
    assert final_intimacy >= initial_intimacy


def test_intimacy_capped_at_5():
    """亲密度最高为5"""
    for i in range(100):
        client.post(
            "/api/v1/companion/check-in",
            json={"user_id": "user1", "mood": 3, "energy": 3},
        )

    assert _profiles["user1"]["intimacy_level"] <= 5


def test_intimacy_reflected_in_profile():
    """档案反映亲密度"""
    for i in range(10):
        client.post("/api/v1/companion/greet", json={"user_id": "user1"})

    response = client.get("/api/v1/companion/profile/user1")
    data = response.json()["data"]
    assert data["intimacy_level"] == _profiles["user1"]["intimacy_level"]


# ─────────────────────────────────────────────────────────────────────────────
# 多用户隔离测试
# ─────────────────────────────────────────────────────────────────────────────

def test_multiple_users_isolated():
    """不同用户的数据隔离"""
    client.post("/api/v1/companion/greet", json={"user_id": "user1"})
    client.post("/api/v1/companion/greet", json={"user_id": "user2"})

    assert len(_messages["user1"]) > 0
    assert len(_messages["user2"]) > 0
    assert _messages["user1"] != _messages["user2"]


def test_multiple_users_independent_profiles():
    """不同用户的档案独立"""
    client.post("/api/v1/companion/greet", json={"user_id": "user1"})
    client.post(
        "/api/v1/companion/greet",
        json={"user_id": "user2", "user_name": "小李"},
    )

    assert _profiles["user1"]["user_name"] != _profiles["user2"]["user_name"]


# ─────────────────────────────────────────────────────────────────────────────
# 边界和错误处理测试
# ─────────────────────────────────────────────────────────────────────────────

def test_empty_user_id():
    """处理空user_id"""
    response = client.post(
        "/api/v1/companion/greet",
        json={"user_id": ""},
    )
    # 应该接受但可能返回空档案
    assert response.status_code == 200 or response.status_code == 422


def test_very_long_notes():
    """长备注（在限制内）"""
    long_notes = "x" * 500
    response = client.post(
        "/api/v1/companion/check-in",
        json={
            "user_id": "user1",
            "mood": 3,
            "energy": 3,
            "notes": long_notes,
        },
    )
    assert response.status_code == 200


def test_oversized_notes_rejected():
    """超长备注被拒绝"""
    long_notes = "x" * 501
    response = client.post(
        "/api/v1/companion/check-in",
        json={
            "user_id": "user1",
            "mood": 3,
            "energy": 3,
            "notes": long_notes,
        },
    )
    assert response.status_code == 422


def test_special_characters_in_user_id():
    """user_id可以包含特殊字符"""
    response = client.post(
        "/api/v1/companion/greet",
        json={"user_id": "user_123-abc@test"},
    )
    assert response.status_code == 200


def test_unicode_user_name():
    """用户名支持unicode"""
    response = client.post(
        "/api/v1/companion/greet",
        json={"user_id": "user1", "user_name": "小明🌟"},
    )
    assert response.status_code == 200
