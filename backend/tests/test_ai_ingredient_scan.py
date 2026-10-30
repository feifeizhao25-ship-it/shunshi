"""顺时 - AI食材扫描测试"""
import pytest

pytestmark = pytest.mark.signed_in


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
        # 图片识别结果来自模型：带显式「AI 生成」标识
        assert response.json()["ai_generated"] is True
        assert response.json()["ai_label"] == "AI 生成"

    def test_scan_by_name_is_not_labelled_ai(self, client):
        data = client.post("/api/v1/ingredient-scan/scan", json={"ingredient_name": "枸杞"}).json()
        assert "ai_generated" not in data

    def test_scan_by_image_fails_without_ai_configuration(self, client, monkeypatch):
        monkeypatch.delenv("SHUNSHI_DASHSCOPE_API_KEY", raising=False)
        response = client.post(
            "/api/v1/ingredient-scan/scan",
            json={"image_url": "https://example.com/ingredient.jpg"},
        )
        assert response.status_code == 503

    def test_scan_low_confidence_image_is_unknown_not_guessed(self, client, monkeypatch):
        from app.router import ai_ingredient_scan

        async def recognize(_url):
            return "未知", 0.3, "verified-test-model"

        monkeypatch.setattr(ai_ingredient_scan, "_recognize_ingredient_image", recognize)
        data = client.post(
            "/api/v1/ingredient-scan/scan", json={"image_url": "https://example.com/blur.jpg"}
        ).json()["data"]
        assert data["found_in_database"] is False
        assert "ingredient" not in data

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


class TestDomesticVisionRecognition:
    """视觉识别走境内百炼接口：没配密钥 503，低把握记为未知，不连境外主机。"""

    ENV = {"SHUNSHI_DASHSCOPE_API_KEY": "test-key-not-real"}

    @staticmethod
    def _client(reply, status=200, seen=None):
        import httpx

        def handler(request):
            if seen is not None:
                seen.append(request)
            return httpx.Response(status, json=reply)

        return httpx.AsyncClient(transport=httpx.MockTransport(handler))

    @staticmethod
    def _reply(text):
        return {"choices": [{"message": {"content": text}}]}

    def _run(self, **kwargs):
        import asyncio
        from app.router import ai_ingredient_scan as mod

        return asyncio.run(mod._recognize_ingredient_image("https://example.com/a.jpg", **kwargs))

    def test_confident_result_is_returned_with_model_name(self):
        seen = []
        client = self._client(self._reply('{"ingredient_name_cn":"枸杞","confidence":0.92}'), seen=seen)
        name, confidence, model = self._run(client=client, env=self.ENV)
        assert (name, confidence) == ("枸杞", 0.92)
        assert model == "qwen-vl-plus"
        request = seen[0]
        assert request.url.host == "dashscope.aliyuncs.com"
        body = __import__("json").loads(request.content)
        parts = body["messages"][0]["content"]
        assert {"type": "image_url", "image_url": {"url": "https://example.com/a.jpg"}} in parts

    def test_model_name_can_be_overridden(self):
        client = self._client(self._reply('{"ingredient_name_cn":"山药","confidence":0.9}'))
        env = {**self.ENV, "SHUNSHI_VISION_MODEL": "qwen-vl-max"}
        assert self._run(client=client, env=env)[2] == "qwen-vl-max"

    def test_low_confidence_becomes_unknown(self):
        client = self._client(self._reply('{"ingredient_name_cn":"枸杞","confidence":0.59}'))
        assert self._run(client=client, env=self.ENV)[0] == "未知"

    def test_code_fenced_json_is_accepted(self):
        client = self._client(self._reply('```json\n{"ingredient_name_cn":"红枣","confidence":0.8}\n```'))
        assert self._run(client=client, env=self.ENV)[0] == "红枣"

    def test_missing_key_is_503(self):
        from fastapi import HTTPException

        with pytest.raises(HTTPException) as exc:
            self._run(client=self._client({}), env={})
        assert exc.value.status_code == 503

    def test_provider_error_and_bad_format_are_502(self):
        from fastapi import HTTPException

        for client in (
            self._client({}, status=500),
            self._client(self._reply("not json")),
            self._client({"choices": []}),
        ):
            with pytest.raises(HTTPException) as exc:
                self._run(client=client, env=self.ENV)
            assert exc.value.status_code == 502

    def test_non_https_image_rejected(self):
        import asyncio
        from fastapi import HTTPException
        from app.router import ai_ingredient_scan as mod

        with pytest.raises(HTTPException) as exc:
            asyncio.run(mod._recognize_ingredient_image("http://example.com/a.jpg", env=self.ENV))
        assert exc.value.status_code == 400

    def test_endpoint_is_domestic_and_no_offshore_provider_referenced(self):
        from app.llm.domestic_gateway import host_allowed
        from app.router import ai_ingredient_scan as mod
        import httpx

        assert host_allowed(httpx.URL(mod.VISION_ENDPOINT).host)
        source = open(mod.__file__, encoding="utf-8").read().lower()
        assert "openrouter" not in source
