"""顺时 - 桌面小组件测试"""
import pytest


class TestWidgetTypes:
    def test_types_returns_200(self, client):
        response = client.get("/api/v1/widget/types")
        assert response.status_code == 200

    def test_types_has_widgets(self, client):
        data = client.get("/api/v1/widget/types").json()
        assert "widgets" in data["data"]
        assert len(data["data"]["widgets"]) > 0

    def test_types_includes_solar_term(self, client):
        data = client.get("/api/v1/widget/types").json()
        widget_ids = [w["id"] for w in data["data"]["widgets"]]
        assert "solar_term" in widget_ids


class TestWidgetSolarTerm:
    def test_solar_term_returns_200(self, client):
        response = client.get("/api/v1/widget/data/solar-term")
        assert response.status_code == 200

    def test_solar_term_has_current_term(self, client):
        data = client.get("/api/v1/widget/data/solar-term").json()
        assert "current_solar_term" in data["data"]
        assert data["success"] is True


class TestWidgetDailyTip:
    def test_daily_tip_returns_200(self, client):
        response = client.get("/api/v1/widget/data/daily-tip")
        assert response.status_code == 200

    def test_daily_tip_has_tip(self, client):
        data = client.get("/api/v1/widget/data/daily-tip").json()
        assert "tip" in data["data"]


class TestWidgetShichen:
    def test_shichen_returns_200(self, client):
        response = client.get("/api/v1/widget/data/shichen")
        assert response.status_code == 200

    def test_shichen_has_name(self, client):
        data = client.get("/api/v1/widget/data/shichen").json()
        assert "shichen_name" in data["data"]
        assert "tip" in data["data"]


class TestWidgetWaterTracker:
    def test_water_tracker_returns_200(self, client):
        response = client.get("/api/v1/widget/data/water-tracker?user_id=test_user&today_ml=500&goal_ml=1700")
        assert response.status_code == 200

    def test_water_tracker_has_progress(self, client):
        data = client.get("/api/v1/widget/data/water-tracker?user_id=test_user").json()
        assert "progress_pct" in data["data"]

    def test_water_tracker_requires_user_id(self, client):
        response = client.get("/api/v1/widget/data/water-tracker")
        assert response.status_code == 422


class TestWidgetCheckinStreak:
    def test_checkin_streak_returns_200(self, client):
        response = client.get("/api/v1/widget/data/checkin-streak?user_id=test_user&streak_days=10")
        assert response.status_code == 200

    def test_checkin_streak_has_days(self, client):
        data = client.get("/api/v1/widget/data/checkin-streak?user_id=test_user&streak_days=35").json()
        assert "streak_days" in data["data"]
        assert "badge" in data["data"]

    def test_checkin_requires_user_id(self, client):
        response = client.get("/api/v1/widget/data/checkin-streak")
        assert response.status_code == 422
