"""
测试推送智能管理系统
"""

import pytest
from fastapi.testclient import TestClient
from fastapi import FastAPI
from datetime import datetime, timedelta

# 模拟导入
from app.router import push_intelligence

app = FastAPI()
app.include_router(push_intelligence.router)
client = TestClient(app)


class TestGetPreferences:
    """测试获取推送偏好"""

    def test_get_default_preferences(self):
        """新用户获取默认偏好"""
        resp = client.get("/api/v1/push-intel/preferences/user_new_pref")
        assert resp.status_code == 200
        data = resp.json()
        assert data["success"] is True
        assert "preferences" in data["data"]
        assert data["data"]["is_default"] is True
        assert "enabled_types" in data["data"]["preferences"]
        assert "preferred_time" in data["data"]["preferences"]
        assert "frequency" in data["data"]["preferences"]

    def test_default_preferences_structure(self):
        """默认偏好包含必填字段"""
        resp = client.get("/api/v1/push-intel/preferences/user_pref_1")
        prefs = resp.json()["data"]["preferences"]
        assert isinstance(prefs["enabled_types"], list)
        assert len(prefs["enabled_types"]) > 0
        assert isinstance(prefs["preferred_time"], str)
        assert ":" in prefs["preferred_time"]
        assert prefs["frequency"] in ["daily", "weekly", "smart"]

    def test_get_custom_preferences(self):
        """获取自定义偏好"""
        # 先更新
        client.put(
            "/api/v1/push-intel/preferences/user_custom",
            json={
                "enabled_types": ["daily_tip", "weekly_report"],
                "preferred_time": "09:30",
                "frequency": "weekly",
            },
        )
        # 再获取
        resp = client.get("/api/v1/push-intel/preferences/user_custom")
        data = resp.json()
        assert data["data"]["is_default"] is False
        assert data["data"]["preferences"]["preferred_time"] == "09:30"


class TestUpdatePreferences:
    """测试更新推送偏好"""

    def test_update_valid_preferences(self):
        """更新有效偏好"""
        payload = {
            "enabled_types": ["daily_tip", "checkin_reminder"],
            "preferred_time": "07:00",
            "frequency": "daily",
        }
        resp = client.put("/api/v1/push-intel/preferences/user_update_1", json=payload)
        assert resp.status_code == 200
        data = resp.json()
        assert data["success"] is True
        assert data["data"]["preferences"]["preferred_time"] == "07:00"
        assert data["data"]["preferences"]["frequency"] == "daily"

    def test_update_all_frequencies(self):
        """更新所有频率选项"""
        for freq in ["daily", "weekly", "smart"]:
            payload = {
                "enabled_types": ["daily_tip"],
                "preferred_time": "10:00",
                "frequency": freq,
            }
            resp = client.put(f"/api/v1/push-intel/preferences/user_freq_{freq}", json=payload)
            assert resp.status_code == 200
            assert resp.json()["data"]["preferences"]["frequency"] == freq

    def test_update_invalid_push_type(self):
        """无效推送类型返回400"""
        payload = {
            "enabled_types": ["invalid_type"],
            "preferred_time": "08:00",
            "frequency": "daily",
        }
        resp = client.put("/api/v1/push-intel/preferences/user_invalid", json=payload)
        assert resp.status_code == 400

    def test_update_invalid_time_format(self):
        """无效时间格式返回400"""
        payload = {
            "enabled_types": ["daily_tip"],
            "preferred_time": "25:00",  # 无效
            "frequency": "daily",
        }
        resp = client.put("/api/v1/push-intel/preferences/user_time_invalid", json=payload)
        assert resp.status_code == 400

    def test_update_invalid_frequency(self):
        """无效频率返回400"""
        payload = {
            "enabled_types": ["daily_tip"],
            "preferred_time": "08:00",
            "frequency": "monthly",  # 无效
        }
        resp = client.put("/api/v1/push-intel/preferences/user_freq_invalid", json=payload)
        assert resp.status_code == 400

    def test_update_multiple_types(self):
        """更新多个启用的推送类型"""
        payload = {
            "enabled_types": [
                "daily_tip",
                "checkin_reminder",
                "content_recommendation",
                "weekly_report",
            ],
            "preferred_time": "09:00",
            "frequency": "smart",
        }
        resp = client.put("/api/v1/push-intel/preferences/user_multi", json=payload)
        assert resp.status_code == 200
        assert len(resp.json()["data"]["preferences"]["enabled_types"]) == 4

    def test_update_returns_timestamp(self):
        """更新返回时间戳"""
        payload = {
            "enabled_types": ["daily_tip"],
            "preferred_time": "08:00",
            "frequency": "daily",
        }
        resp = client.put("/api/v1/push-intel/preferences/user_ts", json=payload)
        assert "updated_at" in resp.json()["data"]


class TestSchedulePush:
    """测试推送调度"""

    def test_schedule_with_datetime(self):
        """用指定时间调度推送"""
        send_time = (datetime.now() + timedelta(hours=2)).isoformat()
        payload = {
            "user_id": "user_schedule_1",
            "push_type": "daily_tip",
            "content": "今日养生建议...",
            "send_at": send_time,
        }
        resp = client.post("/api/v1/push-intel/schedule", json=payload)
        assert resp.status_code == 200
        data = resp.json()
        assert data["success"] is True
        assert "push_id" in data["data"]
        assert data["data"]["status"] == "scheduled"

    def test_schedule_smart_mode(self):
        """smart模式调度推送"""
        payload = {
            "user_id": "user_smart",
            "push_type": "checkin_reminder",
            "content": "该打卡了！",
            "send_at": "smart",
        }
        resp = client.post("/api/v1/push-intel/schedule", json=payload)
        assert resp.status_code == 200
        data = resp.json()
        assert data["success"] is True
        # smart模式应该返回调度时间
        assert "scheduled_time" in data["data"]

    def test_schedule_no_time_immediate(self):
        """不指定时间立即调度"""
        payload = {
            "user_id": "user_immediate",
            "push_type": "health_alert",
            "content": "紧急提醒",
        }
        resp = client.post("/api/v1/push-intel/schedule", json=payload)
        assert resp.status_code == 200
        data = resp.json()
        assert data["success"] is True

    def test_schedule_invalid_push_type(self):
        """无效推送类型返回400"""
        payload = {
            "user_id": "user_invalid_type",
            "push_type": "invalid_push",
            "content": "内容",
        }
        resp = client.post("/api/v1/push-intel/schedule", json=payload)
        assert resp.status_code == 400

    def test_schedule_invalid_datetime(self):
        """无效时间格式返回400"""
        payload = {
            "user_id": "user_bad_dt",
            "push_type": "daily_tip",
            "content": "内容",
            "send_at": "not-a-datetime",
        }
        resp = client.post("/api/v1/push-intel/schedule", json=payload)
        assert resp.status_code == 400

    def test_schedule_all_push_types(self):
        """调度所有推送类型"""
        push_types = [
            "daily_tip",
            "solar_term_reminder",
            "checkin_reminder",
            "health_alert",
            "achievement_unlock",
            "content_recommendation",
            "weekly_report",
            "festival_reminder",
        ]
        for pt in push_types:
            payload = {
                "user_id": "user_all_types",
                "push_type": pt,
                "content": f"Test {pt}",
            }
            resp = client.post("/api/v1/push-intel/schedule", json=payload)
            assert resp.status_code == 200


class TestPushHistory:
    """测试推送历史"""

    def test_get_history_empty(self):
        """新用户的空历史"""
        resp = client.get("/api/v1/push-intel/history/user_empty_hist")
        assert resp.status_code == 200
        data = resp.json()
        assert data["success"] is True
        assert len(data["data"]["history"]) == 0

    def test_get_history_with_data(self):
        """获取历史数据"""
        user_id = "user_hist_data"
        for i in range(3):
            client.post("/api/v1/push-intel/schedule", json={
                "user_id": user_id,
                "push_type": "daily_tip",
                "content": f"Content {i}",
            })

        resp = client.get(f"/api/v1/push-intel/history/{user_id}")
        assert resp.status_code == 200
        data = resp.json()
        assert len(data["data"]["history"]) >= 3

    def test_history_filter_by_type(self):
        """按推送类型过滤历史"""
        user_id = "user_filter_hist"
        client.post("/api/v1/push-intel/schedule", json={
            "user_id": user_id,
            "push_type": "daily_tip",
            "content": "Tip",
        })
        client.post("/api/v1/push-intel/schedule", json={
            "user_id": user_id,
            "push_type": "checkin_reminder",
            "content": "Checkin",
        })

        resp = client.get(
            f"/api/v1/push-intel/history/{user_id}?push_type=daily_tip"
        )
        assert resp.status_code == 200
        history = resp.json()["data"]["history"]
        assert all(h["push_type"] == "daily_tip" for h in history)

    def test_history_limit_default(self):
        """历史默认limit为20"""
        user_id = "user_hist_limit_def"
        for _ in range(10):
            client.post("/api/v1/push-intel/schedule", json={
                "user_id": user_id,
                "push_type": "daily_tip",
                "content": "Content",
            })

        resp = client.get(f"/api/v1/push-intel/history/{user_id}")
        data = resp.json()
        assert data["data"]["limit"] == 20

    def test_history_custom_limit(self):
        """自定义历史limit"""
        user_id = "user_hist_custom_lim"
        for _ in range(15):
            client.post("/api/v1/push-intel/schedule", json={
                "user_id": user_id,
                "push_type": "daily_tip",
                "content": "Content",
            })

        resp = client.get(f"/api/v1/push-intel/history/{user_id}?limit=5")
        data = resp.json()
        assert len(data["data"]["history"]) <= 5

    def test_history_newest_first(self):
        """历史按最新优先排序"""
        user_id = "user_hist_order"
        for i in range(3):
            client.post("/api/v1/push-intel/schedule", json={
                "user_id": user_id,
                "push_type": "daily_tip",
                "content": f"Content {i}",
            })

        resp = client.get(f"/api/v1/push-intel/history/{user_id}")
        history = resp.json()["data"]["history"]
        # 验证时间戳递减
        for i in range(len(history) - 1):
            assert history[i]["created_at"] >= history[i + 1]["created_at"]


class TestOptimalTime:
    """测试最优推送时间"""

    def test_optimal_time_no_history(self):
        """无打开历史返回默认时间"""
        resp = client.get("/api/v1/push-intel/optimal-time/user_no_opens")
        assert resp.status_code == 200
        data = resp.json()
        assert data["success"] is True
        assert "optimal_time" in data["data"]
        # 无数据时应该返回默认时间
        assert data["data"]["optimal_time"] == "08:00"

    def test_optimal_time_with_confidence(self):
        """最优时间包含信心度"""
        resp = client.get("/api/v1/push-intel/optimal-time/user_conf")
        assert resp.status_code == 200
        data = resp.json()
        assert "confidence" in data["data"]
        assert 0 <= data["data"]["confidence"] <= 1

    def test_optimal_time_data_points(self):
        """最优时间返回数据点数"""
        resp = client.get("/api/v1/push-intel/optimal-time/user_points")
        assert resp.status_code == 200
        data = resp.json()
        assert "data_points" in data["data"]

    def test_optimal_time_recommendation(self):
        """最优时间包含建议"""
        resp = client.get("/api/v1/push-intel/optimal-time/user_rec")
        assert resp.status_code == 200
        data = resp.json()
        assert "recommendation" in data["data"]


class TestABTest:
    """测试A/B测试"""

    def test_create_ab_test(self):
        """创建A/B测试"""
        payload = {
            "name": "Daily Tip Title Test",
            "variant_a_title": "你的养生建议来了",
            "variant_b_title": "重要：今日养生提示",
            "target_push_type": "daily_tip",
            "sample_size": 1000,
        }
        resp = client.post("/api/v1/push-intel/ab-test", json=payload)
        assert resp.status_code == 200
        data = resp.json()
        assert data["success"] is True
        assert "test_id" in data["data"]
        assert data["data"]["name"] == "Daily Tip Title Test"

    def test_ab_test_allocation(self):
        """A/B测试包含分配信息"""
        payload = {
            "name": "Test Allocation",
            "variant_a_title": "Version A",
            "variant_b_title": "Version B",
            "target_push_type": "checkin_reminder",
            "sample_size": 500,
        }
        resp = client.post("/api/v1/push-intel/ab-test", json=payload)
        data = resp.json()
        assert "allocation_rule" in data["data"]

    def test_ab_test_minimum_sample_size(self):
        """最小样本量限制"""
        payload = {
            "name": "Small Sample",
            "variant_a_title": "A",
            "variant_b_title": "B",
            "target_push_type": "health_alert",
            "sample_size": 5,  # 太小
        }
        resp = client.post("/api/v1/push-intel/ab-test", json=payload)
        assert resp.status_code == 400

    def test_ab_test_invalid_push_type(self):
        """无效推送类型返回400"""
        payload = {
            "name": "Invalid Type Test",
            "variant_a_title": "A",
            "variant_b_title": "B",
            "target_push_type": "invalid_push",
            "sample_size": 100,
        }
        resp = client.post("/api/v1/push-intel/ab-test", json=payload)
        assert resp.status_code == 400

    def test_ab_test_all_push_types(self):
        """对所有推送类型创建测试"""
        push_types = [
            "daily_tip",
            "solar_term_reminder",
            "checkin_reminder",
            "health_alert",
            "achievement_unlock",
            "content_recommendation",
            "weekly_report",
            "festival_reminder",
        ]
        for pt in push_types:
            payload = {
                "name": f"Test {pt}",
                "variant_a_title": "Version A",
                "variant_b_title": "Version B",
                "target_push_type": pt,
                "sample_size": 100,
            }
            resp = client.post("/api/v1/push-intel/ab-test", json=payload)
            assert resp.status_code == 200

    def test_ab_test_created_at_timestamp(self):
        """A/B测试包含创建时间"""
        payload = {
            "name": "Timestamp Test",
            "variant_a_title": "A",
            "variant_b_title": "B",
            "target_push_type": "content_recommendation",
            "sample_size": 200,
        }
        resp = client.post("/api/v1/push-intel/ab-test", json=payload)
        data = resp.json()
        assert "created_at" in data["data"]


class TestPushTypes:
    """测试推送类型"""

    def test_get_all_push_types(self):
        """获取所有推送类型"""
        resp = client.get("/api/v1/push-intel/types")
        assert resp.status_code == 200
        data = resp.json()
        assert data["success"] is True
        assert len(data["data"]["push_types"]) == 8

    def test_push_types_structure(self):
        """推送类型包含必填字段"""
        resp = client.get("/api/v1/push-intel/types")
        types = resp.json()["data"]["push_types"]
        for pt in types:
            assert "id" in pt
            assert "name" in pt
            assert "description" in pt

    def test_push_types_contains_daily_tip(self):
        """推送类型包含daily_tip"""
        resp = client.get("/api/v1/push-intel/types")
        types = resp.json()["data"]["push_types"]
        type_ids = [t["id"] for t in types]
        assert "daily_tip" in type_ids

    def test_push_types_total_count(self):
        """推送类型总数正确"""
        resp = client.get("/api/v1/push-intel/types")
        data = resp.json()
        assert data["data"]["total"] == 8


class TestIntegration:
    """集成测试"""

    def test_full_workflow(self):
        """完整工作流"""
        user_id = "user_workflow"

        # 1. 获取默认偏好
        resp1 = client.get(f"/api/v1/push-intel/preferences/{user_id}")
        assert resp1.status_code == 200

        # 2. 更新偏好
        resp2 = client.put(
            f"/api/v1/push-intel/preferences/{user_id}",
            json={
                "enabled_types": ["daily_tip", "weekly_report"],
                "preferred_time": "09:00",
                "frequency": "smart",
            },
        )
        assert resp2.status_code == 200

        # 3. 调度推送
        resp3 = client.post(
            "/api/v1/push-intel/schedule",
            json={
                "user_id": user_id,
                "push_type": "daily_tip",
                "content": "Test content",
                "send_at": "smart",
            },
        )
        assert resp3.status_code == 200

        # 4. 查看历史
        resp4 = client.get(f"/api/v1/push-intel/history/{user_id}")
        assert resp4.status_code == 200
        assert len(resp4.json()["data"]["history"]) >= 1

        # 5. 获取最优时间
        resp5 = client.get(f"/api/v1/push-intel/optimal-time/{user_id}")
        assert resp5.status_code == 200

    def test_multiple_users_isolated(self):
        """多个用户数据隔离"""
        user1 = "user_iso_1"
        user2 = "user_iso_2"

        # 用户1更新偏好
        client.put(
            f"/api/v1/push-intel/preferences/{user1}",
            json={
                "enabled_types": ["daily_tip"],
                "preferred_time": "08:00",
                "frequency": "daily",
            },
        )

        # 用户2更新不同偏好
        client.put(
            f"/api/v1/push-intel/preferences/{user2}",
            json={
                "enabled_types": ["weekly_report"],
                "preferred_time": "18:00",
                "frequency": "weekly",
            },
        )

        # 验证隔离
        resp1 = client.get(f"/api/v1/push-intel/preferences/{user1}")
        resp2 = client.get(f"/api/v1/push-intel/preferences/{user2}")

        prefs1 = resp1.json()["data"]["preferences"]
        prefs2 = resp2.json()["data"]["preferences"]

        assert prefs1["preferred_time"] == "08:00"
        assert prefs2["preferred_time"] == "18:00"
