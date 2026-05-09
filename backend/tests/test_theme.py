"""顺时 - 主题定制测试"""
import pytest


class TestThemeList:
    def test_list_returns_200(self, client):
        response = client.get("/api/v1/theme/list")
        assert response.status_code == 200

    def test_list_has_themes(self, client):
        data = client.get("/api/v1/theme/list").json()
        assert "themes" in data["data"]
        assert len(data["data"]["themes"]) > 0


class TestThemeDetail:
    def test_valid_theme_returns_200(self, client):
        response = client.get("/api/v1/theme/spring")
        assert response.status_code == 200

    def test_invalid_theme_returns_404(self, client):
        assert client.get("/api/v1/theme/nonexistent_theme").status_code == 404


class TestThemeSettings:
    def test_set_settings_returns_200(self, client):
        payload = {"user_id": "test_user", "theme_id": "spring"}
        response = client.post("/api/v1/theme/settings", json=payload)
        assert response.status_code == 200

    def test_set_settings_has_confirmation(self, client):
        payload = {"user_id": "test_user", "theme_id": "winter"}
        data = client.post("/api/v1/theme/settings", json=payload).json()
        assert data["success"] is True


class TestThemeGetSettings:
    def test_get_settings_returns_200(self, client):
        response = client.get("/api/v1/theme/settings/test_user")
        assert response.status_code == 200


class TestThemeFonts:
    def test_fonts_returns_200(self, client):
        response = client.get("/api/v1/theme/fonts/list")
        assert response.status_code == 200


class TestThemeSeasonalCurrent:
    def test_seasonal_current_returns_200(self, client):
        response = client.get("/api/v1/theme/seasonal/current")
        assert response.status_code == 200
