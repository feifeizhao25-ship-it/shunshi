"""
顺时 - 睡眠端点测试
test_sleep.py
"""

import pytest


class TestSleepGuide:
    """睡眠指南端点测试"""

    def test_guide_returns_200(self, client):
        """GET /api/v1/sleep/guide 返回 200"""
        response = client.get("/api/v1/sleep/guide")
        assert response.status_code == 200

    def test_guide_has_bedtime(self, client):
        """响应包含 recommended_bedtime 键"""
        response = client.get("/api/v1/sleep/guide")
        assert response.status_code == 200
        data = response.json()
        assert "recommended_bedtime" in data["data"]
        assert "recommended_wake_time" in data["data"]

    def test_guide_north_hemisphere(self, client):
        """GET /api/v1/sleep/guide?hemisphere=north 返回 200"""
        response = client.get("/api/v1/sleep/guide?hemisphere=north")
        assert response.status_code == 200
        data = response.json()
        assert "season" in data["data"]

    def test_guide_south_hemisphere(self, client):
        """GET /api/v1/sleep/guide?hemisphere=south 返回 200"""
        response = client.get("/api/v1/sleep/guide?hemisphere=south")
        assert response.status_code == 200
        data = response.json()
        assert "season" in data["data"]

    def test_guide_with_constitution(self, client):
        """GET /api/v1/sleep/guide?constitution=yin_deficiency 返回 200，含 constitution_note"""
        response = client.get("/api/v1/sleep/guide?constitution=yin_deficiency")
        assert response.status_code == 200
        data = response.json()
        assert "constitution_note" in data["data"]
        assert "acupoint_suggestion" in data["data"]


class TestSleepSchedule:
    """睡眠时间表端点测试"""

    def test_schedule_returns_200(self, client):
        """GET /api/v1/sleep/schedule 返回 200"""
        response = client.get("/api/v1/sleep/schedule")
        assert response.status_code == 200

    def test_schedule_with_wake_time(self, client):
        """GET /api/v1/sleep/schedule?wake_time=07:00 包含 sleep_cycle_options"""
        response = client.get("/api/v1/sleep/schedule?wake_time=07:00")
        assert response.status_code == 200
        data = response.json()
        assert "sleep_cycle_options" in data["data"]
        assert isinstance(data["data"]["sleep_cycle_options"], list)

    def test_schedule_options_count(self, client):
        """sleep_cycle_options 包含 2 个选项（5 和 6 睡眠周期）"""
        response = client.get("/api/v1/sleep/schedule?wake_time=07:00")
        assert response.status_code == 200
        data = response.json()
        options = data["data"]["sleep_cycle_options"]
        assert len(options) == 2
        # 验证包含 5 和 6 周期
        cycles = [opt["cycles"] for opt in options]
        assert 5 in cycles
        assert 6 in cycles

    def test_schedule_south_hemisphere(self, client):
        """GET /api/v1/sleep/schedule?hemisphere=south 返回 200"""
        response = client.get("/api/v1/sleep/schedule?hemisphere=south")
        assert response.status_code == 200
        data = response.json()
        assert "season" in data["data"]


class TestSleepCheckin:
    """睡眠签到端点测试"""

    def test_checkin_returns_200(self, client):
        """GET /api/v1/sleep/checkin 返回 200"""
        response = client.get("/api/v1/sleep/checkin")
        assert response.status_code == 200

    def test_checkin_has_dimensions(self, client):
        """响应数据包含 'dimensions' 列表，至少 4 个维度"""
        response = client.get("/api/v1/sleep/checkin")
        assert response.status_code == 200
        data = response.json()
        assert "dimensions" in data["data"]
        dimensions = data["data"]["dimensions"]
        assert isinstance(dimensions, list)
        assert len(dimensions) >= 4
        # 验证维度结构
        for dim in dimensions:
            assert "key" in dim
            assert "label" in dim
            assert "options" in dim
