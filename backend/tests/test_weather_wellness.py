"""顺时 - 天气养生测试"""
import pytest


class TestWeatherAdvice:
    def test_advice_returns_200(self, client):
        payload = {"weather_type": "sunny", "temperature": 25, "humidity": 60}
        response = client.post("/api/v1/weather-wellness/advice", json=payload)
        assert response.status_code == 200

    def test_advice_requires_observed_temperature_and_humidity(self, client):
        payload = {"weather_type": "rainy"}
        response = client.post("/api/v1/weather-wellness/advice", json=payload)
        assert response.status_code == 422

    def test_advice_requires_weather_type(self, client):
        response = client.post("/api/v1/weather-wellness/advice", json={})
        assert response.status_code == 422


class TestWeatherTypes:
    def test_types_returns_200(self, client):
        response = client.get("/api/v1/weather-wellness/types")
        assert response.status_code == 200

    def test_types_has_weather_list(self, client):
        data = client.get("/api/v1/weather-wellness/types").json()
        assert "weather_types" in data["data"]
        assert len(data["data"]["weather_types"]) > 0


class TestAQIGuide:
    def test_aqi_guide_returns_200(self, client):
        response = client.get("/api/v1/weather-wellness/aqi-guide")
        assert response.status_code == 200

    def test_aqi_guide_has_levels(self, client):
        data = client.get("/api/v1/weather-wellness/aqi-guide").json()
        assert "data" in data
        assert data["success"] is True
