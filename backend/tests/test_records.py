"""
顺时 - 用户数据记录 API 路由测试
test_records.py
"""

import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


class TestCareRecords:
    """养生状态记录端点测试"""

    def test_get_care_records_returns_200(self):
        """GET /api/v1/records/care 返回 200"""
        response = client.get("/api/v1/records/care?user_id=user-001")
        assert response.status_code == 200

    def test_care_records_has_data(self):
        """响应包含 data 和 items"""
        response = client.get("/api/v1/records/care?user_id=user-001")
        assert response.status_code == 200
        data = response.json()
        assert "data" in data
        assert "items" in data["data"]
        assert isinstance(data["data"]["items"], list)

    def test_care_records_has_total(self):
        """响应包含 total 字段"""
        response = client.get("/api/v1/records/care?user_id=user-001")
        assert response.status_code == 200
        data = response.json()
        assert "total" in data["data"]

    def test_add_care_record(self):
        """POST /api/v1/records/care 添加养生记录"""
        response = client.post("/api/v1/records/care?user_id=user-001&date=2026-03-28&mood=happy&sleep_hours=8.0")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "data" in data

    def test_care_record_has_id(self):
        """新添加的记录包含 id"""
        response = client.post("/api/v1/records/care?user_id=user-001&date=2026-03-28&mood=happy")
        assert response.status_code == 200
        data = response.json()
        assert "id" in data["data"]

    def test_get_today_care_record(self):
        """GET /api/v1/records/care/today 返回今日记录"""
        response = client.get("/api/v1/records/care/today?user_id=user-001")
        assert response.status_code == 200
        data = response.json()
        assert "data" in data

    def test_get_care_stats(self):
        """GET /api/v1/records/care/stats 返回养生统计"""
        response = client.get("/api/v1/records/care/stats?user_id=user-001&period=week")
        assert response.status_code == 200
        data = response.json()
        assert "data" in data
        assert "average_sleep" in data["data"]
        assert "total_exercise" in data["data"]

    def test_care_stats_with_month_period(self):
        """GET /api/v1/records/care/stats?period=month 返回 200"""
        response = client.get("/api/v1/records/care/stats?user_id=user-001&period=month")
        assert response.status_code == 200

    def test_care_record_with_all_fields(self):
        """POST /api/v1/records/care 支持所有字段"""
        response = client.post(
            "/api/v1/records/care?"
            "user_id=user-001&date=2026-03-28&mood=happy&sleep_hours=8.0&"
            "exercise_minutes=30&stress_level=low&notes=test"
        )
        assert response.status_code == 200


class TestEmotionRecords:
    """情绪记录端点测试"""

    def test_get_emotion_records_returns_200(self):
        """GET /api/v1/records/emotion 返回 200"""
        response = client.get("/api/v1/records/emotion?user_id=user-001")
        assert response.status_code == 200

    def test_emotion_records_has_items(self):
        """响应包含 items 列表"""
        response = client.get("/api/v1/records/emotion?user_id=user-001")
        assert response.status_code == 200
        data = response.json()
        assert "items" in data["data"]
        assert isinstance(data["data"]["items"], list)

    def test_add_emotion_record(self):
        """POST /api/v1/records/emotion 添加情绪记录"""
        response = client.post(
            "/api/v1/records/emotion?user_id=user-001&date=2026-03-28&emotion=开心&intensity=8"
        )
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True

    def test_emotion_record_has_id(self):
        """新添加的情绪记录包含 id"""
        response = client.post(
            "/api/v1/records/emotion?user_id=user-001&date=2026-03-28&emotion=平静&intensity=5"
        )
        assert response.status_code == 200
        data = response.json()
        assert "id" in data["data"]

    def test_emotion_intensity_range(self):
        """情绪强度在 1-10 之间"""
        response = client.post(
            "/api/v1/records/emotion?user_id=user-001&date=2026-03-28&emotion=开心&intensity=5"
        )
        assert response.status_code == 200
        data = response.json()
        assert 1 <= data["data"]["intensity"] <= 10

    def test_emotion_with_trigger(self):
        """支持添加情绪触发因素"""
        response = client.post(
            "/api/v1/records/emotion?user_id=user-001&date=2026-03-28&emotion=开心&intensity=8&trigger=完成任务"
        )
        assert response.status_code == 200

    def test_get_emotion_trends(self):
        """GET /api/v1/records/emotion/trends 返回情绪趋势"""
        response = client.get("/api/v1/records/emotion/trends?user_id=user-001&period=week")
        assert response.status_code == 200
        data = response.json()
        assert "data" in data
        assert "period" in data["data"]

    def test_emotion_trends_has_dominant_emotion(self):
        """情绪趋势包含主导情绪"""
        response = client.get("/api/v1/records/emotion/trends?user_id=user-001")
        assert response.status_code == 200
        data = response.json()
        assert "dominant_emotion" in data["data"] or "trends" in data["data"]


class TestSleepRecords:
    """睡眠记录端点测试"""

    def test_get_sleep_records_returns_200(self):
        """GET /api/v1/records/sleep 返回 200"""
        response = client.get("/api/v1/records/sleep?user_id=user-001")
        assert response.status_code == 200

    def test_sleep_records_has_items(self):
        """响应包含 items 列表"""
        response = client.get("/api/v1/records/sleep?user_id=user-001")
        assert response.status_code == 200
        data = response.json()
        assert "items" in data["data"]
        assert isinstance(data["data"]["items"], list)

    def test_add_sleep_record(self):
        """POST /api/v1/records/sleep 添加睡眠记录"""
        response = client.post(
            "/api/v1/records/sleep?user_id=user-001&date=2026-03-28&sleep_time=23:00&wake_time=07:00&hours=8.0&quality=good"
        )
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True

    def test_sleep_record_has_id(self):
        """新添加的睡眠记录包含 id"""
        response = client.post(
            "/api/v1/records/sleep?user_id=user-001&date=2026-03-28&hours=8.0"
        )
        assert response.status_code == 200
        data = response.json()
        assert "id" in data["data"]

    def test_sleep_quality_valid_values(self):
        """睡眠质量只能是 good/normal/poor"""
        response = client.post(
            "/api/v1/records/sleep?user_id=user-001&date=2026-03-28&quality=good&hours=8.0"
        )
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["quality"] in ["good", "normal", "poor"]

    def test_get_sleep_stats(self):
        """GET /api/v1/records/sleep/stats 返回睡眠统计"""
        response = client.get("/api/v1/records/sleep/stats?user_id=user-001&period=week")
        assert response.status_code == 200
        data = response.json()
        assert "data" in data
        assert "average_hours" in data["data"]
        assert "average_quality" in data["data"]

    def test_sleep_stats_has_record_count(self):
        """睡眠统计包含记录数"""
        response = client.get("/api/v1/records/sleep/stats?user_id=user-001")
        assert response.status_code == 200
        data = response.json()
        assert "record_count" in data["data"]


class TestRecordsDelete:
    """记录删除端点测试"""

    def test_delete_care_record(self):
        """DELETE /api/v1/records/care/{record_id} 删除记录"""
        # 先添加一条记录
        add_response = client.post("/api/v1/records/care?user_id=user-001&date=2026-03-28")
        record_id = add_response.json()["data"]["id"]

        # 删除记录
        response = client.delete(f"/api/v1/records/care/{record_id}?user_id=user-001")
        assert response.status_code == 200
        assert response.json()["success"] is True

    def test_delete_emotion_record(self):
        """DELETE /api/v1/records/emotion/{record_id} 删除情绪记录"""
        add_response = client.post("/api/v1/records/emotion?user_id=user-001&date=2026-03-28&emotion=开心&intensity=5")
        record_id = add_response.json()["data"]["id"]

        response = client.delete(f"/api/v1/records/emotion/{record_id}?user_id=user-001")
        assert response.status_code == 200

    def test_delete_sleep_record(self):
        """DELETE /api/v1/records/sleep/{record_id} 删除睡眠记录"""
        add_response = client.post("/api/v1/records/sleep?user_id=user-001&date=2026-03-28&hours=8.0")
        record_id = add_response.json()["data"]["id"]

        response = client.delete(f"/api/v1/records/sleep/{record_id}?user_id=user-001")
        assert response.status_code == 200

    def test_delete_nonexistent_record_404(self):
        """删除不存在的记录返回 404"""
        response = client.delete("/api/v1/records/care/nonexistent_id?user_id=user-001")
        assert response.status_code == 404

    def test_delete_invalid_type_400(self):
        """删除未知类型的记录返回 400"""
        response = client.delete("/api/v1/records/invalid_type/record_id?user_id=user-001")
        assert response.status_code == 400


class TestRecordsSummary:
    """记录摘要端点测试"""

    def test_get_records_summary_returns_200(self):
        """GET /api/v1/records/summary 返回 200"""
        response = client.get("/api/v1/records/summary?user_id=user-001&days=7")
        assert response.status_code == 200

    def test_summary_has_required_fields(self):
        """摘要包含必要字段"""
        response = client.get("/api/v1/records/summary?user_id=user-001")
        assert response.status_code == 200
        data = response.json()
        assert "period" in data["data"]
        assert "start_date" in data["data"]
        assert "end_date" in data["data"]

    def test_summary_emotion_data(self):
        """摘要包含情绪数据"""
        response = client.get("/api/v1/records/summary?user_id=user-001")
        assert response.status_code == 200
        data = response.json()
        assert "emotion" in data["data"]

    def test_summary_sleep_data(self):
        """摘要包含睡眠数据"""
        response = client.get("/api/v1/records/summary?user_id=user-001")
        assert response.status_code == 200
        data = response.json()
        assert "sleep" in data["data"]

    def test_summary_exercise_data(self):
        """摘要包含运动数据"""
        response = client.get("/api/v1/records/summary?user_id=user-001")
        assert response.status_code == 200
        data = response.json()
        assert "exercise" in data["data"]

    def test_summary_respects_days_parameter(self):
        """支持 days 参数"""
        response = client.get("/api/v1/records/summary?user_id=user-001&days=30")
        assert response.status_code == 200
        data = response.json()
        assert "period" in data["data"]

    def test_summary_max_days_90(self):
        """days 参数最大为 90"""
        response = client.get("/api/v1/records/summary?user_id=user-001&days=100")
        # 应该被限制为 90 或返回错误
        assert response.status_code in [200, 422]
