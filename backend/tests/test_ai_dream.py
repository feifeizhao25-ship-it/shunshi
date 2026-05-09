"""顺时 - AI解梦测试"""
import pytest


class TestDreamLog:
    def test_log_dream_returns_200(self, client):
        payload = {
            "user_id": "test_user",
            "dream_description": "梦见大火，四处燃烧，感觉很热",
            "dream_quality": "nightmare",
            "emotions": ["fear"]
        }
        response = client.post("/api/v1/ai-dream/log", json=payload)
        assert response.status_code == 200

    def test_log_has_tcm_insight(self, client):
        payload = {
            "user_id": "test_user",
            "dream_description": "梦见洪水淹没一切，感到恐惧",
            "dream_quality": "nightmare"
        }
        data = client.post("/api/v1/ai-dream/log", json=payload).json()
        assert data["success"] is True
        assert "tcm_insight" in data["data"]

    def test_log_fire_dream_matches_heart(self, client):
        payload = {
            "user_id": "test_user",
            "dream_description": "梦见火焰和燃烧",
            "dream_quality": "vivid_dreams"
        }
        data = client.post("/api/v1/ai-dream/log", json=payload).json()
        assert "data" in data
        analysis = data["data"]["entry"]["tcm_analysis"]
        assert analysis["organ"] == "心"

    def test_log_requires_min_description(self, client):
        payload = {"user_id": "test_user", "dream_description": "梦"}
        response = client.post("/api/v1/ai-dream/log", json=payload)
        assert response.status_code == 422

    def test_log_requires_user_id(self, client):
        payload = {"dream_description": "梦见很多水"}
        response = client.post("/api/v1/ai-dream/log", json=payload)
        assert response.status_code == 422


class TestDreamHistory:
    def test_history_returns_200(self, client):
        response = client.get("/api/v1/ai-dream/history/test_user")
        assert response.status_code == 200

    def test_history_has_dreams(self, client):
        # Log a dream first
        client.post("/api/v1/ai-dream/log",
                    json={"user_id": "dream_hist_user", "dream_description": "梦见水和海洋",
                          "dream_quality": "vivid_dreams"})
        data = client.get("/api/v1/ai-dream/history/dream_hist_user").json()
        assert "dreams" in data["data"]
        assert len(data["data"]["dreams"]) >= 1

    def test_history_limit_param(self, client):
        response = client.get("/api/v1/ai-dream/history/test_user?limit=5")
        assert response.status_code == 200


class TestDreamMeanings:
    def test_meanings_returns_200(self, client):
        response = client.get("/api/v1/ai-dream/meanings")
        assert response.status_code == 200

    def test_meanings_has_list(self, client):
        data = client.get("/api/v1/ai-dream/meanings").json()
        assert "meanings" in data["data"]
        assert len(data["data"]["meanings"]) > 0


class TestDreamQualityGuide:
    def test_quality_guide_returns_200(self, client):
        response = client.get("/api/v1/ai-dream/quality-guide")
        assert response.status_code == 200

    def test_quality_guide_has_indicators(self, client):
        data = client.get("/api/v1/ai-dream/quality-guide").json()
        assert "quality_indicators" in data["data"]


class TestDreamSleepTips:
    def test_sleep_tips_returns_200(self, client):
        response = client.get("/api/v1/ai-dream/sleep-tips")
        assert response.status_code == 200

    def test_sleep_tips_has_tips(self, client):
        data = client.get("/api/v1/ai-dream/sleep-tips").json()
        assert "sleep_tips" in data["data"]
        assert len(data["data"]["sleep_tips"]) > 0
