"""顺时 - AI食材扫描测试"""
import pytest


class TestIngredientScan:
    def test_scan_by_name_returns_200(self, client):
        payload = {"ingredient_name": "枸杞", "user_constitution": "yin_deficiency"}
        response = client.post("/api/v1/ingredient-scan/scan", json=payload)
        assert response.status_code == 200

    def test_scan_found_ingredient_has_info(self, client):
        payload = {"ingredient_name": "枸杞"}
        data = client.post("/api/v1/ingredient-scan/scan", json=payload).json()
        assert data["success"] is True
        assert "recognized" in data["data"]

    def test_scan_by_image_url(self, client, monkeypatch):
        from app.router import ai_ingredient_scan

        async def recognize(_url):
            return "枸杞", 0.94, "verified-test-model"

        monkeypatch.setattr(ai_ingredient_scan, "_recognize_ingredient_image", recognize)
        payload = {"image_url": "https://example.com/goji.jpg"}
        response = client.post("/api/v1/ingredient-scan/scan", json=payload)
        assert response.status_code == 200
        assert response.json()["data"]["recognition_model"] == "verified-test-model"

    def test_scan_by_image_fails_without_ai_configuration(self, client, monkeypatch):
        monkeypatch.delenv("OPENROUTER_API_KEY", raising=False)
        response = client.post(
            "/api/v1/ingredient-scan/scan",
            json={"image_url": "https://example.com/ingredient.jpg"},
        )
        assert response.status_code == 503

    def test_scan_no_input_returns_400(self, client):
        response = client.post("/api/v1/ingredient-scan/scan", json={})
        assert response.status_code == 400

    def test_scan_unknown_ingredient(self, client):
        payload = {"ingredient_name": "未知食材xyz"}
        data = client.post("/api/v1/ingredient-scan/scan", json=payload).json()
        assert data["success"] is True
        assert data["data"]["found_in_database"] is False


class TestIngredientSearch:
    def test_search_returns_200(self, client):
        response = client.get("/api/v1/ingredient-scan/search?q=枸杞")
        assert response.status_code == 200

    def test_search_has_results(self, client):
        data = client.get("/api/v1/ingredient-scan/search?q=山药").json()
        assert "results" in data["data"]

    def test_search_empty_query_returns_422(self, client):
        response = client.get("/api/v1/ingredient-scan/search")
        assert response.status_code == 422


class TestIngredientCombination:
    def test_analyze_combination_returns_200(self, client):
        payload = {"ingredients": ["枸杞", "红枣"], "user_constitution": "qi_deficiency"}
        response = client.post("/api/v1/ingredient-scan/analyze-combination", json=payload)
        assert response.status_code == 200

    def test_combination_has_analysis(self, client):
        payload = {"ingredients": ["山楂", "枸杞"]}
        data = client.post("/api/v1/ingredient-scan/analyze-combination", json=payload).json()
        assert "analysis" in data["data"]

    def test_combination_requires_min_2_ingredients(self, client):
        payload = {"ingredients": ["枸杞"]}
        response = client.post("/api/v1/ingredient-scan/analyze-combination", json=payload)
        assert response.status_code == 422


class TestIngredientByConstitution:
    def test_by_constitution_returns_200(self, client):
        response = client.get("/api/v1/ingredient-scan/by-constitution/yin_deficiency")
        assert response.status_code == 200

    def test_by_constitution_has_ingredients(self, client):
        data = client.get("/api/v1/ingredient-scan/by-constitution/qi_deficiency").json()
        assert "ingredients" in data["data"]
