"""顺时 - 中医文化测试"""
import pytest


class TestTcmClassics:
    def test_classics_returns_200(self, client):
        response = client.get("/api/v1/tcm-culture/classics")
        assert response.status_code == 200

    def test_classics_has_list(self, client):
        data = client.get("/api/v1/tcm-culture/classics").json()
        assert "classics" in data["data"]
        assert len(data["data"]["classics"]) > 0


class TestTcmClassicDetail:
    def test_valid_classic_returns_200(self, client):
        response = client.get("/api/v1/tcm-culture/classics/huangdi_neijing")
        assert response.status_code == 200

    def test_invalid_classic_returns_404(self, client):
        assert client.get("/api/v1/tcm-culture/classics/nonexistent").status_code == 404


class TestTcmFamousDoctors:
    def test_doctors_returns_200(self, client):
        response = client.get("/api/v1/tcm-culture/famous-doctors")
        assert response.status_code == 200

    def test_doctors_has_list(self, client):
        data = client.get("/api/v1/tcm-culture/famous-doctors").json()
        assert "doctors" in data["data"]


class TestTcmDoctorDetail:
    def test_valid_doctor_returns_200(self, client):
        response = client.get("/api/v1/tcm-culture/famous-doctors/huatuo")
        assert response.status_code == 200

    def test_invalid_doctor_returns_404(self, client):
        assert client.get("/api/v1/tcm-culture/famous-doctors/nonexistent").status_code == 404


class TestTcmPhilosophy:
    def test_philosophy_returns_200(self, client):
        response = client.get("/api/v1/tcm-culture/philosophy")
        assert response.status_code == 200

    def test_philosophy_has_concepts(self, client):
        data = client.get("/api/v1/tcm-culture/philosophy").json()
        assert "data" in data


class TestTcmStories:
    def test_stories_returns_200(self, client):
        response = client.get("/api/v1/tcm-culture/stories")
        assert response.status_code == 200


class TestTcmDailyWisdom:
    def test_daily_wisdom_returns_200(self, client):
        response = client.get("/api/v1/tcm-culture/daily-wisdom")
        assert response.status_code == 200

    def test_daily_wisdom_has_content(self, client):
        data = client.get("/api/v1/tcm-culture/daily-wisdom").json()
        assert "wisdom" in data["data"]
