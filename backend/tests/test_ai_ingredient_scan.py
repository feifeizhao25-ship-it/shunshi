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

        async def recognize(_url, **_kwargs):
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
        monkeypatch.delenv("SHUNSHI_MINIMAX_API_KEY", raising=False)
        monkeypatch.delenv("MINIMAX_API_KEY", raising=False)
        response = client.post(
            "/api/v1/ingredient-scan/scan",
            json={"image_url": "https://example.com/ingredient.jpg"},
        )
        assert response.status_code == 503

    def test_scan_low_confidence_image_is_unknown_not_guessed(self, client, monkeypatch):
        from app.router import ai_ingredient_scan

        async def recognize(_url, **_kwargs):
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
    """视觉识别走境内 MiniMax 接口：没配密钥 503，低把握记为未知，不连境外主机。
    调用前过日费用上限和图片内容安全审核，任何一步不确定都不调用模型。"""

    ENV = {
        "SHUNSHI_MINIMAX_API_KEY": "test-key-not-real",
        "SHUNSHI_GUARDRAIL_AK_ID": "akid",
        "SHUNSHI_GUARDRAIL_AK_SECRET": "test-secret-not-real",
    }
    MODERATION_PASS = {"Code": 200, "Data": {"RiskLevel": "none", "Result": [{"Label": "nonLabel"}]}}
    TEXT_PASS = {"Code": 200, "Data": {"Labels": ""}}

    @pytest.fixture(autouse=True)
    def _fresh_caps(self):
        from app.llm import cost_cap

        cost_cap.reset()
        yield
        cost_cap.reset()

    @staticmethod
    def _client(reply, status=200, seen=None, image=None, text=None, image_status=200, text_status=200):
        """按主机分流：MiniMax 视觉、内容安全。image/text 缺省为放行。"""
        import httpx

        image = TestDomesticVisionRecognition.MODERATION_PASS if image is None else image
        text = TestDomesticVisionRecognition.TEXT_PASS if text is None else text

        def handler(request):
            if seen is not None:
                seen.append(request)
            if request.url.host.startswith("green-cip"):
                if request.url.params.get("Action") == "ImageModeration":
                    return httpx.Response(image_status, json=image)
                return httpx.Response(text_status, json=text)
            return httpx.Response(status, json=reply)

        return httpx.AsyncClient(transport=httpx.MockTransport(handler))

    @staticmethod
    def _reply(text, usage=None):
        body = {"choices": [{"message": {"content": text}}]}
        if usage:
            body["usage"] = usage
        return body

    GOOD = '{"ingredient_name_cn":"枸杞","confidence":0.92}'

    def _run(self, **kwargs):
        import asyncio
        from app.router import ai_ingredient_scan as mod

        return asyncio.run(mod._recognize_ingredient_image("https://example.com/a.jpg", **kwargs))

    @staticmethod
    def _model_calls(seen):
        return [r for r in seen if not r.url.host.startswith("green-cip")]

    def test_confident_result_is_returned_with_model_name(self):
        import json

        seen = []
        client = self._client(self._reply(self.GOOD), seen=seen)
        name, confidence, model = self._run(client=client, env=self.ENV)
        assert (name, confidence) == ("枸杞", 0.92)
        assert model == "MiniMax-M3"
        request = self._model_calls(seen)[0]
        assert request.url.host == "api.minimax.cn"
        assert request.url.path == "/v1/chat/completions"
        assert request.headers["authorization"] == "Bearer test-key-not-real"
        body = json.loads(request.content)
        assert body["thinking"] == {"type": "disabled"}
        parts = body["messages"][0]["content"]
        assert {"type": "image_url", "image_url": {"url": "https://example.com/a.jpg", "detail": "low"}} in parts

    def test_model_name_can_be_overridden_and_flash_keeps_thinking_on(self):
        import json

        seen = []
        client = self._client(self._reply('{"ingredient_name_cn":"山药","confidence":0.9}'), seen=seen)
        env = {**self.ENV, "SHUNSHI_VISION_MODEL": "MiniMax-M3.1-Flash"}
        assert self._run(client=client, env=env)[2] == "MiniMax-M3.1-Flash"
        body = json.loads(self._model_calls(seen)[0].content)
        assert "thinking" not in body
        assert body["reasoning_effort"] == "low"

    def test_existing_minimax_key_name_is_accepted(self):
        env = {k: v for k, v in self.ENV.items() if k != "SHUNSHI_MINIMAX_API_KEY"}
        env["MINIMAX_API_KEY"] = "test-key-not-real"
        client = self._client(self._reply(self.GOOD))
        assert self._run(client=client, env=env)[0] == "枸杞"

    def test_low_confidence_becomes_unknown(self):
        client = self._client(self._reply('{"ingredient_name_cn":"枸杞","confidence":0.59}'))
        assert self._run(client=client, env=self.ENV)[0] == "未知"

    def test_code_fenced_json_and_think_tags_are_accepted(self):
        client = self._client(self._reply('<think>看起来像红枣</think>```json\n{"ingredient_name_cn":"红枣","confidence":0.8}\n```'))
        assert self._run(client=client, env=self.ENV)[0] == "红枣"

    def test_missing_key_is_503_and_nothing_is_called(self):
        from fastapi import HTTPException

        seen = []
        with pytest.raises(HTTPException) as exc:
            self._run(client=self._client({}, seen=seen), env={})
        assert exc.value.status_code == 503
        assert seen == []

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
        assert host_allowed("api.minimaxi.com")
        source = open(mod.__file__, encoding="utf-8").read().lower()
        assert "openrouter" not in source
        assert "dashscope" not in source

    # ---- 内容安全审核：先审图，再调模型，再审结果文字；不确定一律拒绝 ----

    def test_image_rejected_by_moderation_is_422_and_model_not_called(self):
        from fastapi import HTTPException

        seen = []
        client = self._client(
            self._reply(self.GOOD), seen=seen,
            image={"Code": 200, "Data": {"RiskLevel": "high", "Result": [{"Label": "pornographic_adultContent"}]}},
        )
        with pytest.raises(HTTPException) as exc:
            self._run(client=client, env=self.ENV)
        assert exc.value.status_code == 422
        assert self._model_calls(seen) == []

    def test_moderation_unavailable_is_503_and_model_not_called(self):
        from fastapi import HTTPException

        cases = [
            self._client(self._reply(self.GOOD), image_status=500),
            self._client(self._reply(self.GOOD), image={"Code": 588, "Msg": "quota"}),
            self._client(self._reply(self.GOOD), image={"Code": 200, "Data": {}}),
        ]
        for client in cases:
            seen = []
            with pytest.raises(HTTPException) as exc:
                self._run(client=client, env=self.ENV)
            assert exc.value.status_code == 503
        # 没配审核密钥同样不放行，也不调用模型
        seen = []
        env = {"SHUNSHI_MINIMAX_API_KEY": "test-key-not-real"}
        with pytest.raises(HTTPException) as exc:
            self._run(client=self._client(self._reply(self.GOOD), seen=seen), env=env)
        assert exc.value.status_code == 503
        assert self._model_calls(seen) == []

    def test_model_called_only_after_moderation_pass(self):
        seen = []
        self._run(client=self._client(self._reply(self.GOOD), seen=seen), env=self.ENV)
        hosts = [r.url.host for r in seen]
        assert hosts[0].startswith("green-cip") and hosts[1] == "api.minimax.cn"

    def test_result_text_hit_is_422_and_text_service_down_is_503(self):
        from fastapi import HTTPException

        hit = {"Code": 200, "Data": {"Labels": "ad", "Reason": "{\"riskLevel\":\"high\"}"}}
        with pytest.raises(HTTPException) as exc:
            self._run(client=self._client(self._reply(self.GOOD), text=hit), env=self.ENV)
        assert exc.value.status_code == 422
        with pytest.raises(HTTPException) as exc:
            self._run(client=self._client(self._reply(self.GOOD), text_status=500), env=self.ENV)
        assert exc.value.status_code == 503

    # ---- 日费用上限 ----

    def test_user_daily_cap_is_429_before_any_call(self):
        from fastapi import HTTPException

        seen = []
        env = {**self.ENV, "SHUNSHI_VISION_USER_DAILY_CAP_CNY": "0.0001"}
        with pytest.raises(HTTPException) as exc:
            self._run(client=self._client(self._reply(self.GOOD), seen=seen), env=env, user_id="u-cap")
        assert exc.value.status_code == 429
        assert "上限" in exc.value.detail
        assert seen == []

    def test_cost_is_recorded_and_cap_applies_per_user(self):
        from fastapi import HTTPException
        from app.llm import cost_cap

        usage = {"prompt_tokens": 600, "completion_tokens": 30}
        env = {**self.ENV, "SHUNSHI_VISION_USER_DAILY_CAP_CNY": "0.02"}
        self._run(client=self._client(self._reply(self.GOOD, usage)), env=env, user_id="u-a")
        spent = cost_cap.spent("vision:user:u-a")
        assert spent > 0
        assert cost_cap.spent("vision:product") == spent
        assert cost_cap.spent("user:u-a") == spent  # 同时计入与问答共用的个人日帽
        # 另一个用户不受影响；同一用户继续调用直到超限
        self._run(client=self._client(self._reply(self.GOOD, usage)), env=env, user_id="u-b")
        with pytest.raises(HTTPException) as exc:
            for _ in range(20):
                self._run(client=self._client(self._reply(self.GOOD, usage)), env=env, user_id="u-a")
        assert exc.value.status_code == 429

    def test_product_daily_cap_is_429(self):
        from fastapi import HTTPException

        env = {**self.ENV, "SHUNSHI_VISION_DAILY_BUDGET_CNY": "0.0001"}
        with pytest.raises(HTTPException) as exc:
            self._run(client=self._client(self._reply(self.GOOD)), env=env, user_id="anyone")
        assert exc.value.status_code == 429

    def test_http_route_maps_status_and_passes_user(self, client, monkeypatch):
        from fastapi import HTTPException
        from app.router import ai_ingredient_scan

        seen = {}

        async def recognize(_url, **kwargs):
            seen.update(kwargs)
            raise HTTPException(status_code=429, detail="今日图片识别次数已达上限，请明天再试，或直接输入食材名称")

        monkeypatch.setattr(ai_ingredient_scan, "_recognize_ingredient_image", recognize)
        response = client.post("/api/v1/ingredient-scan/scan", json={"image_url": "https://example.com/a.jpg"})
        assert response.status_code == 429
        assert seen["user_id"].startswith("signed-in-")


class TestImageModerationClient:
    def test_signature_and_request_shape_use_image_action(self):
        import asyncio
        import httpx
        from app.llm.guardrail import moderate_image

        seen = []

        def handler(request):
            seen.append(request)
            return httpx.Response(200, json={"Code": 200, "Data": {"RiskLevel": "low", "Result": []}})

        client = httpx.AsyncClient(transport=httpx.MockTransport(handler))
        env = {"SHUNSHI_GUARDRAIL_AK_ID": "akid", "SHUNSHI_GUARDRAIL_AK_SECRET": "s"}
        result = asyncio.run(moderate_image("https://example.com/a.jpg", client=client, env=env))
        assert result.status == "pass"
        params = seen[0].url.params
        assert params["Action"] == "ImageModeration" and params["Service"] == "baselineCheck"
        assert params["Signature"] and "s" != params["Signature"]
        assert "example.com/a.jpg" in params["ServiceParameters"]

    def test_not_configured_is_unavailable_without_a_request(self):
        import asyncio
        from app.llm.guardrail import moderate_image

        result = asyncio.run(moderate_image("https://example.com/a.jpg", env={}))
        assert result.status == "unavailable" and result.requested is False
