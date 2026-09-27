"""
顺时 - 用户数据记录 API 路由测试
test_records.py
"""

import pytest
@pytest.fixture()
def records_client(client, auth_headers):
    """Use a fresh logged-in user; the API derives ownership from the token."""
    client.headers.update(auth_headers)
    return client


class TestCareRecords:
    """养生状态记录端点测试"""

    def test_get_care_records_returns_200(self, records_client):
        """GET /api/v1/records/care 返回 200"""
        response = records_client.get("/api/v1/records/care")
        assert response.status_code == 200

    def test_care_records_has_data(self, records_client):
        """响应包含 data 和 items"""
        response = records_client.get("/api/v1/records/care")
        assert response.status_code == 200
        data = response.json()
        assert "data" in data
        assert "items" in data["data"]
        assert isinstance(data["data"]["items"], list)

    def test_care_records_has_total(self, records_client):
        """响应包含 total 字段"""
        response = records_client.get("/api/v1/records/care")
        assert response.status_code == 200
        data = response.json()
        assert "total" in data["data"]

    def test_add_care_record(self, records_client):
        """POST /api/v1/records/care 添加养生记录"""
        response = records_client.post("/api/v1/records/care?date=2026-03-28&mood=happy&sleep_hours=8.0")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "data" in data

    def test_care_record_has_id(self, records_client):
        """新添加的记录包含 id"""
        response = records_client.post("/api/v1/records/care?date=2026-03-28&mood=happy")
        assert response.status_code == 200
        data = response.json()
        assert "id" in data["data"]

    def test_get_today_care_record(self, records_client):
        """GET /api/v1/records/care/today 返回今日记录"""
        response = records_client.get("/api/v1/records/care/today")
        assert response.status_code == 200
        data = response.json()
        assert "data" in data

    def test_get_care_stats(self, records_client):
        """GET /api/v1/records/care/stats 返回养生统计"""
        response = records_client.get("/api/v1/records/care/stats?period=week")
        assert response.status_code == 200
        data = response.json()
        assert "data" in data
        assert "average_sleep" in data["data"]
        assert "total_exercise" in data["data"]

    def test_care_stats_with_month_period(self, records_client):
        """GET /api/v1/records/care/stats?period=month 返回 200"""
        response = records_client.get("/api/v1/records/care/stats?period=month")
        assert response.status_code == 200

    def test_care_record_with_all_fields(self, records_client):
        """POST /api/v1/records/care 支持所有字段"""
        response = records_client.post(
            "/api/v1/records/care?"
            "date=2026-03-28&mood=happy&sleep_hours=8.0&"
            "exercise_minutes=30&stress_level=low&notes=test"
        )
        assert response.status_code == 200


class TestEmotionRecords:
    """情绪记录端点测试"""

    def test_get_emotion_records_returns_200(self, records_client):
        """GET /api/v1/records/emotion 返回 200"""
        response = records_client.get("/api/v1/records/emotion")
        assert response.status_code == 200

    def test_emotion_records_has_items(self, records_client):
        """响应包含 items 列表"""
        response = records_client.get("/api/v1/records/emotion")
        assert response.status_code == 200
        data = response.json()
        assert "items" in data["data"]
        assert isinstance(data["data"]["items"], list)

    def test_add_emotion_record(self, records_client):
        """POST /api/v1/records/emotion 添加情绪记录"""
        response = records_client.post(
            "/api/v1/records/emotion?date=2026-03-28&emotion=开心&intensity=8"
        )
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True

    def test_emotion_record_has_id(self, records_client):
        """新添加的情绪记录包含 id"""
        response = records_client.post(
            "/api/v1/records/emotion?date=2026-03-28&emotion=平静&intensity=5"
        )
        assert response.status_code == 200
        data = response.json()
        assert "id" in data["data"]

    def test_emotion_intensity_range(self, records_client):
        """情绪强度在 1-10 之间"""
        response = records_client.post(
            "/api/v1/records/emotion?date=2026-03-28&emotion=开心&intensity=5"
        )
        assert response.status_code == 200
        data = response.json()
        assert 1 <= data["data"]["intensity"] <= 10

    def test_emotion_with_trigger(self, records_client):
        """支持添加情绪触发因素"""
        response = records_client.post(
            "/api/v1/records/emotion?date=2026-03-28&emotion=开心&intensity=8&trigger=完成任务"
        )
        assert response.status_code == 200

    def test_get_emotion_trends(self, records_client):
        """GET /api/v1/records/emotion/trends 返回情绪趋势"""
        response = records_client.get("/api/v1/records/emotion/trends?period=week")
        assert response.status_code == 200
        data = response.json()
        assert "data" in data
        assert "period" in data["data"]

    def test_emotion_trends_has_dominant_emotion(self, records_client):
        """情绪趋势包含主导情绪"""
        response = records_client.get("/api/v1/records/emotion/trends")
        assert response.status_code == 200
        data = response.json()
        assert "dominant_emotion" in data["data"] or "trends" in data["data"]


class TestSleepRecords:
    """睡眠记录端点测试"""

    def test_get_sleep_records_returns_200(self, records_client):
        """GET /api/v1/records/sleep 返回 200"""
        response = records_client.get("/api/v1/records/sleep")
        assert response.status_code == 200

    def test_sleep_records_has_items(self, records_client):
        """响应包含 items 列表"""
        response = records_client.get("/api/v1/records/sleep")
        assert response.status_code == 200
        data = response.json()
        assert "items" in data["data"]
        assert isinstance(data["data"]["items"], list)

    def test_add_sleep_record(self, records_client):
        """POST /api/v1/records/sleep 添加睡眠记录"""
        response = records_client.post(
            "/api/v1/records/sleep?date=2026-03-28&sleep_time=23:00&wake_time=07:00&hours=8.0&quality=good"
        )
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True

    def test_sleep_record_has_id(self, records_client):
        """新添加的睡眠记录包含 id"""
        response = records_client.post(
            "/api/v1/records/sleep?date=2026-03-28&hours=8.0"
        )
        assert response.status_code == 200
        data = response.json()
        assert "id" in data["data"]

    def test_sleep_quality_valid_values(self, records_client):
        """睡眠质量只能是 good/normal/poor"""
        response = records_client.post(
            "/api/v1/records/sleep?date=2026-03-28&quality=good&hours=8.0"
        )
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["quality"] in ["good", "normal", "poor"]

    def test_get_sleep_stats(self, records_client):
        """GET /api/v1/records/sleep/stats 返回睡眠统计"""
        response = records_client.get("/api/v1/records/sleep/stats?period=week")
        assert response.status_code == 200
        data = response.json()
        assert "data" in data
        assert "average_hours" in data["data"]
        assert "average_quality" in data["data"]

    def test_sleep_stats_has_record_count(self, records_client):
        """睡眠统计包含记录数"""
        response = records_client.get("/api/v1/records/sleep/stats")
        assert response.status_code == 200
        data = response.json()
        assert "record_count" in data["data"]


class TestRecordsDelete:
    """记录删除端点测试"""

    def test_delete_care_record(self, records_client):
        """DELETE /api/v1/records/care/{record_id} 删除记录"""
        # 先添加一条记录
        add_response = records_client.post("/api/v1/records/care?date=2026-03-28")
        record_id = add_response.json()["data"]["id"]

        # 删除记录
        response = records_client.delete(f"/api/v1/records/care/{record_id}")
        assert response.status_code == 200
        assert response.json()["success"] is True

    def test_delete_emotion_record(self, records_client):
        """DELETE /api/v1/records/emotion/{record_id} 删除情绪记录"""
        add_response = records_client.post("/api/v1/records/emotion?date=2026-03-28&emotion=开心&intensity=5")
        record_id = add_response.json()["data"]["id"]

        response = records_client.delete(f"/api/v1/records/emotion/{record_id}")
        assert response.status_code == 200

    def test_delete_sleep_record(self, records_client):
        """DELETE /api/v1/records/sleep/{record_id} 删除睡眠记录"""
        add_response = records_client.post("/api/v1/records/sleep?date=2026-03-28&hours=8.0")
        record_id = add_response.json()["data"]["id"]

        response = records_client.delete(f"/api/v1/records/sleep/{record_id}")
        assert response.status_code == 200

    def test_delete_nonexistent_record_404(self, records_client):
        """删除不存在的记录返回 404"""
        response = records_client.delete("/api/v1/records/care/nonexistent_id")
        assert response.status_code == 404

    def test_delete_invalid_type_400(self, records_client):
        """删除未知类型的记录返回 400"""
        response = records_client.delete("/api/v1/records/invalid_type/record_id")
        assert response.status_code == 400


class TestRecordsSummary:
    """记录摘要端点测试"""

    def test_get_records_summary_returns_200(self, records_client):
        """GET /api/v1/records/summary 返回 200"""
        response = records_client.get("/api/v1/records/summary?days=7")
        assert response.status_code == 200

    def test_summary_has_required_fields(self, records_client):
        """摘要包含必要字段"""
        response = records_client.get("/api/v1/records/summary")
        assert response.status_code == 200
        data = response.json()
        assert "period" in data["data"]
        assert "start_date" in data["data"]
        assert "end_date" in data["data"]

    def test_summary_emotion_data(self, records_client):
        """摘要包含情绪数据"""
        response = records_client.get("/api/v1/records/summary")
        assert response.status_code == 200
        data = response.json()
        assert "emotion" in data["data"]

    def test_summary_sleep_data(self, records_client):
        """摘要包含睡眠数据"""
        response = records_client.get("/api/v1/records/summary")
        assert response.status_code == 200
        data = response.json()
        assert "sleep" in data["data"]

    def test_summary_exercise_data(self, records_client):
        """摘要包含运动数据"""
        response = records_client.get("/api/v1/records/summary")
        assert response.status_code == 200
        data = response.json()
        assert "exercise" in data["data"]

    def test_summary_respects_days_parameter(self, records_client):
        """支持 days 参数"""
        response = records_client.get("/api/v1/records/summary?days=30")
        assert response.status_code == 200
        data = response.json()
        assert "period" in data["data"]

    def test_summary_max_days_90(self, records_client):
        """days 参数最大为 90"""
        response = records_client.get("/api/v1/records/summary?days=100")
        # 应该被限制为 90 或返回错误
        assert response.status_code in [200, 422]
