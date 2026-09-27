"""顺时 - 无障碍设置测试"""
import pytest


@pytest.fixture()
def accessibility_user(client, auth_headers, settings):
    from app.security import verify_token
    client.headers.update(auth_headers)
    return verify_token(settings, auth_headers["Authorization"].removeprefix("Bearer "))



class TestAccessibilityGetSettings:
    def test_get_settings_returns_200(self, client, accessibility_user):
        response = client.get(f"/api/v1/accessibility/settings/{accessibility_user}")
        assert response.status_code == 200

    def test_get_settings_has_config(self, client, accessibility_user):
        data = client.get(f"/api/v1/accessibility/settings/{accessibility_user}").json()
        assert "data" in data
        assert data["success"] is True


class TestAccessibilityUpdateSettings:
    def test_update_settings_returns_200(self, client, accessibility_user):
        payload = {
            "user_id": accessibility_user,
            "font_size": "large",
            "high_contrast": True,
            "color_blind_mode": "none"
        }
        response = client.post("/api/v1/accessibility/settings", json=payload)
        assert response.status_code == 200

    def test_update_settings_success(self, client, accessibility_user):
        payload = {"user_id": accessibility_user, "font_size": "extra_large"}
        data = client.post("/api/v1/accessibility/settings", json=payload).json()
        assert data["success"] is True


class TestAccessibilityReset:
    def test_reset_settings_returns_200(self, client, accessibility_user):
        response = client.post(f"/api/v1/accessibility/settings/{accessibility_user}/reset")
        assert response.status_code == 200

    def test_reset_returns_defaults(self, client, accessibility_user):
        data = client.post(f"/api/v1/accessibility/settings/{accessibility_user}/reset").json()
        assert data["success"] is True


class TestAccessibilityOptions:
    def test_options_returns_200(self, client, accessibility_user):
        response = client.get("/api/v1/accessibility/options")
        assert response.status_code == 200

    def test_options_has_font_sizes(self, client, accessibility_user):
        data = client.get("/api/v1/accessibility/options").json()
        assert "font_sizes" in data["data"]


class TestAccessibilityColorPalette:
    def test_color_palette_returns_200(self, client, accessibility_user):
        response = client.get("/api/v1/accessibility/color-palette/normal")
        assert response.status_code == 200

    def test_deuteranopia_palette_returns_200(self, client, accessibility_user):
        response = client.get("/api/v1/accessibility/color-palette/deuteranopia")
        assert response.status_code == 200
