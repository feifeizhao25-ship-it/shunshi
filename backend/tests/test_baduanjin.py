"""顺时 - 八段锦测试"""
import pytest


class TestBaduanjinSections:
    def test_sections_returns_200(self, client):
        response = client.get("/api/v1/baduanjin/sections")
        assert response.status_code == 200

    def test_sections_has_8(self, client):
        data = client.get("/api/v1/baduanjin/sections").json()
        assert "sections" in data["data"]
        assert len(data["data"]["sections"]) == 8


class TestBaduanjinSectionDetail:
    def test_valid_section_returns_200(self, client):
        response = client.get("/api/v1/baduanjin/sections/1")
        assert response.status_code == 200

    def test_section_has_steps(self, client):
        data = client.get("/api/v1/baduanjin/sections/1").json()
        assert "data" in data

    def test_invalid_section_returns_404(self, client):
        assert client.get("/api/v1/baduanjin/sections/9").status_code == 404


class TestBaduanjinGuide:
    def test_guide_returns_200(self, client):
        response = client.get("/api/v1/baduanjin/guide")
        assert response.status_code == 200

    def test_guide_has_tips(self, client):
        data = client.get("/api/v1/baduanjin/guide").json()
        assert data["success"] is True


class TestBaduanjinByOrgan:
    def test_by_organ_returns_200(self, client):
        response = client.get("/api/v1/baduanjin/by-organ/心")
        assert response.status_code == 200


class TestBaduanjinDailyPlan:
    def test_daily_plan_returns_200(self, client):
        response = client.get("/api/v1/baduanjin/daily-plan")
        assert response.status_code == 200
