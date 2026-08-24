"""
顺时 - Follow-up 测试
test_followup.py
"""

import pytest


@pytest.fixture(autouse=True)
def seed_followup_users():
    """Follow-up rows must reference real users; seed explicit test owners."""
    from app.database.db import get_db

    db = get_db()
    for user_id in (
        "test-user-001",
        "due-test-user",
        "complete-test-user",
        "cancel-test-user",
    ):
        db.execute(
            """INSERT OR IGNORE INTO users
               (id, name, password_hash, created_at, updated_at)
               VALUES (?, '测试用户', '', datetime('now'), datetime('now'))""",
            (user_id,),
        )
    db.commit()


class TestFollowUpCreate:
    """Follow-up 创建测试"""

    def test_create_followup(self, client):
        response = client.post("/api/v1/followup/schedule", json={
            "user_id": "test-user-001",
            "title": "每日签到提醒",
            "type": "daily_checkin",
            "description": "记得打卡记录今日状态",
            "trigger_time": "20:00",
        })
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "followup" in data
        assert data["followup"]["type"] == "daily_checkin"
        # 实际 API 创建时状态为 "scheduled"
        assert data["followup"]["status"] == "scheduled"

    def test_create_followup_mood(self, client):
        response = client.post("/api/v1/followup/schedule", json={
            "user_id": "test-user-001",
            "title": "情绪跟进",
            "type": "mood_followup",
            "description": "最近心情好些了吗",
            "trigger_time": "2026-03-18T09:00:00",
        })
        assert response.status_code == 200
        data = response.json()
        assert data["followup"]["type"] == "mood_followup"

    def test_create_followup_sleep(self, client):
        response = client.post("/api/v1/followup/schedule", json={
            "user_id": "test-user-001",
            "title": "睡眠跟进",
            "type": "sleep_followup",
            "trigger_time": "22:00",
        })
        assert response.status_code == 200
        assert response.json()["followup"]["type"] == "sleep_followup"

    def test_create_followup_invalid_type(self, client):
        response = client.post("/api/v1/followup/schedule", json={
            "user_id": "test-user-001",
            "type": "invalid_type",
            "trigger_time": "20:00",
        })
        assert response.status_code == 400


class TestFollowUpList:
    """Follow-up 列表测试"""

    def test_get_list(self, client):
        response = client.get("/api/v1/followup/list?user_id=test-user-001")
        assert response.status_code == 200
        data = response.json()
        assert "followups" in data
        assert "count" in data

    def test_get_list_filter_by_type(self, client):
        response = client.get("/api/v1/followup/list?user_id=test-user-001&type=daily_checkin")
        assert response.status_code == 200

    def test_get_list_filter_by_status(self, client):
        response = client.get("/api/v1/followup/list?status=scheduled")
        assert response.status_code == 200


class TestFollowUpDueCheck:
    """到期检查测试"""

    def test_check_due_tasks(self, client):
        # 创建一个已过期的任务（user_id 需存在于 users 表）
        from datetime import datetime, timedelta
        past_time = (datetime.now() - timedelta(hours=1)).strftime("%Y-%m-%dT%H:%M:%S")
        client.post("/api/v1/followup/schedule", json={
            "user_id": "due-test-user",
            "title": "过期任务",
            "type": "care_reminder",
            "trigger_time": past_time,
        })

        response = client.get("/api/v1/followup/due")
        assert response.status_code == 200
        data = response.json()
        assert "due_followups" in data


class TestFollowUpComplete:
    """完成 Follow-up 测试"""

    def test_complete_followup(self, client):
        # 创建（user_id 需存在于 users 表）
        create_resp = client.post("/api/v1/followup/schedule", json={
            "user_id": "complete-test-user",
            "title": "待完成任务",
            "type": "daily_checkin",
            "trigger_time": "20:00",
        })
        task_id = create_resp.json()["followup"]["id"]

        # 更新状态为 sent（已完成）
        complete_resp = client.put(
            f"/api/v1/followup/{task_id}",
            json={"status": "sent"},
        )
        assert complete_resp.status_code == 200
        assert complete_resp.json()["followup"]["status"] == "sent"


class TestFollowUpCancel:
    """取消 Follow-up 测试"""

    def test_cancel_followup(self, client):
        create_resp = client.post("/api/v1/followup/schedule", json={
            "user_id": "cancel-test-user",
            "title": "待取消任务",
            "type": "care_reminder",
            "trigger_time": "20:00",
        })
        task_id = create_resp.json()["followup"]["id"]

        cancel_resp = client.delete(f"/api/v1/followup/{task_id}")
        assert cancel_resp.status_code == 200
        assert cancel_resp.json()["success"] is True


class TestFollowUpTypes:
    """Follow-up 类型列表测试"""

    def test_get_types(self, client):
        response = client.get("/api/v1/followup/types")
        assert response.status_code == 200
        data = response.json()
        assert "types" in data
        type_values = [t["value"] for t in data["types"]]
        assert "daily_checkin" in type_values
        assert "mood_followup" in type_values
        assert "sleep_followup" in type_values
        assert "care_reminder" in type_values


class TestFollowUpStats:
    """统计测试"""

    def test_get_stats(self, client):
        response = client.get("/api/v1/followup/stats?user_id=test-user-001")
        assert response.status_code == 200
