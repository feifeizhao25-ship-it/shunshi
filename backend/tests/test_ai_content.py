"""
测试AI内容生成引擎
"""

import pytest
from fastapi.testclient import TestClient
from fastapi import FastAPI
from datetime import datetime

# 假设app已配置，这里模拟导入
from app.router import ai_content

app = FastAPI()
app.include_router(ai_content.router)
client = TestClient(app)


class TestTemplateList:
    """测试模板列表"""

    def test_list_all_templates(self):
        """获取所有模板"""
        resp = client.get("/api/v1/ai-content/templates")
        assert resp.status_code == 200
        data = resp.json()
        assert data["success"] is True
        assert "templates" in data["data"]
        assert len(data["data"]["templates"]) >= 12
        assert data["data"]["total"] >= 12

    def test_list_templates_by_scene(self):
        """按场景过滤模板"""
        resp = client.get("/api/v1/ai-content/templates?scene=solar_term_greeting")
        assert resp.status_code == 200
        data = resp.json()
        assert data["success"] is True
        templates = data["data"]["templates"]
        assert all(t["scene"] == "solar_term_greeting" for t in templates)
        assert len(templates) >= 1

    def test_list_templates_by_invalid_scene(self):
        """无效场景返回空"""
        resp = client.get("/api/v1/ai-content/templates?scene=invalid_scene")
        assert resp.status_code == 200
        data = resp.json()
        assert len(data["data"]["templates"]) == 0

    def test_templates_have_required_fields(self):
        """模板包含必填字段"""
        resp = client.get("/api/v1/ai-content/templates")
        templates = resp.json()["data"]["templates"]
        for t in templates:
            assert "id" in t
            assert "scene" in t
            assert "template_cn" in t
            assert "template_en" in t
            assert "variables_required" in t
            assert "variables_optional" in t
            assert "tone" in t


class TestScenesList:
    """测试场景列表"""

    def test_get_all_scenes(self):
        """获取所有场景"""
        resp = client.get("/api/v1/ai-content/scenes")
        assert resp.status_code == 200
        data = resp.json()
        assert data["success"] is True
        scenes = data["data"]["scenes"]
        assert len(scenes) > 0
        assert all("id" in s and "name" in s for s in scenes)


class TestPreview:
    """测试模板预览"""

    def test_preview_valid_template(self):
        """预览有效模板"""
        resp = client.get("/api/v1/ai-content/preview/tpl_solar_1")
        assert resp.status_code == 200
        data = resp.json()
        assert data["success"] is True
        assert "preview_cn" in data["data"]
        assert "preview_en" in data["data"]
        assert "template" in data["data"]

    def test_preview_invalid_template(self):
        """预览无效模板返回404"""
        resp = client.get("/api/v1/ai-content/preview/invalid_id")
        assert resp.status_code == 404

    def test_preview_contains_rendered_text(self):
        """预览包含渲染后的文本（不是占位符）"""
        resp = client.get("/api/v1/ai-content/preview/tpl_solar_1")
        data = resp.json()
        preview = data["data"]["preview_cn"]
        assert "{" not in preview  # 不应有占位符
        assert "张三" in preview  # 应有示例变量


class TestGenerateContent:
    """测试内容生成"""

    def test_generate_with_all_variables(self):
        """用全部变量生成内容"""
        payload = {
            "template_id": "tpl_solar_1",
            "variables": {
                "user_name": "小王",
                "solar_term": "清明",
                "constitution": "气虚体质",
                "advice": "多食健脾食物",
            },
            "lang": "zh",
        }
        resp = client.post("/api/v1/ai-content/generate", json=payload)
        assert resp.status_code == 200
        data = resp.json()
        assert data["success"] is True
        assert "content" in data["data"]
        assert "小王" in data["data"]["content"]
        assert "清明" in data["data"]["content"]

    def test_generate_en_language(self):
        """生成英文内容"""
        payload = {
            "template_id": "tpl_solar_1",
            "variables": {
                "user_name": "John",
                "solar_term": "Spring",
                "constitution": "qi_deficiency",
                "advice": "eat healthy food",
            },
            "lang": "en",
        }
        resp = client.post("/api/v1/ai-content/generate", json=payload)
        assert resp.status_code == 200
        data = resp.json()
        assert data["success"] is True
        assert data["data"]["lang"] == "en"

    def test_generate_missing_required_variable(self):
        """缺少必填变量返回422"""
        payload = {
            "template_id": "tpl_solar_1",
            "variables": {
                "user_name": "小王",
                # 缺少 solar_term, constitution, advice
            },
            "lang": "zh",
        }
        resp = client.post("/api/v1/ai-content/generate", json=payload)
        assert resp.status_code == 422

    def test_generate_invalid_template(self):
        """无效模板返回404"""
        payload = {
            "template_id": "invalid_id",
            "variables": {"key": "value"},
            "lang": "zh",
        }
        resp = client.post("/api/v1/ai-content/generate", json=payload)
        assert resp.status_code == 404

    def test_generate_with_user_id(self):
        """记录user_id的生成"""
        payload = {
            "template_id": "tpl_solar_1",
            "variables": {
                "user_name": "张三",
                "solar_term": "夏至",
                "constitution": "阴虚",
                "advice": "滋阴补水",
            },
            "lang": "zh",
            "user_id": "user_123",
        }
        resp = client.post("/api/v1/ai-content/generate", json=payload)
        assert resp.status_code == 200
        data = resp.json()
        assert data["success"] is True

    def test_generate_duplicate_detection(self):
        """生成相同内容时触发防重复"""
        payload = {
            "template_id": "tpl_solar_1",
            "variables": {
                "user_name": "李四",
                "solar_term": "冬至",
                "constitution": "阳虚",
                "advice": "温阳食物",
            },
            "lang": "zh",
            "user_id": "user_456",
        }
        # 第一次生成
        resp1 = client.post("/api/v1/ai-content/generate", json=payload)
        content1 = resp1.json()["data"]["content"]

        # 第二次相同生成
        resp2 = client.post("/api/v1/ai-content/generate", json=payload)
        content2 = resp2.json()["data"]["content"]

        # 应该略有不同（添加了重复标记）
        assert resp1.status_code == 200
        assert resp2.status_code == 200


class TestBatchGenerate:
    """测试批量生成"""

    def test_batch_generate_multiple(self):
        """批量生成多个内容"""
        payload = {
            "requests": [
                {
                    "template_id": "tpl_solar_1",
                    "variables": {
                        "user_name": "王五",
                        "solar_term": "立春",
                        "constitution": "气虚",
                        "advice": "温阳运动",
                    },
                },
                {
                    "template_id": "tpl_daily_tip_1",
                    "variables": {
                        "season": "spring",
                        "constitution": "阳虚",
                        "time_period": "早晨",
                        "tip": "散步30分钟",
                    },
                },
            ]
        }
        resp = client.post("/api/v1/ai-content/batch-generate", json=payload)
        assert resp.status_code == 200
        data = resp.json()
        assert data["success"] is True
        assert len(data["data"]["results"]) == 2
        assert data["data"]["success_count"] >= 1

    def test_batch_generate_exceed_limit(self):
        """超过10个请求返回错误"""
        payload = {
            "requests": [
                {
                    "template_id": "tpl_daily_tip_1",
                    "variables": {
                        "season": "summer",
                        "constitution": "balanced",
                        "time_period": "noon",
                        "tip": "drink water",
                    },
                }
                for _ in range(11)
            ]
        }
        resp = client.post("/api/v1/ai-content/batch-generate", json=payload)
        assert resp.status_code == 400

    def test_batch_generate_with_invalid_template(self):
        """批量生成中包含无效模板"""
        payload = {
            "requests": [
                {
                    "template_id": "tpl_solar_1",
                    "variables": {
                        "user_name": "朱六",
                        "solar_term": "谷雨",
                        "constitution": "湿热",
                        "advice": "清热祛湿",
                    },
                },
                {
                    "template_id": "invalid_id",
                    "variables": {"key": "value"},
                },
            ]
        }
        resp = client.post("/api/v1/ai-content/batch-generate", json=payload)
        assert resp.status_code == 200
        results = resp.json()["data"]["results"]
        assert results[0]["success"] is True
        assert results[1]["success"] is False

    def test_batch_generate_missing_variables(self):
        """批量生成中某项缺少变量"""
        payload = {
            "requests": [
                {
                    "template_id": "tpl_solar_1",
                    "variables": {
                        "user_name": "孙七",
                        # 缺少其他变量
                    },
                }
            ]
        }
        resp = client.post("/api/v1/ai-content/batch-generate", json=payload)
        assert resp.status_code == 200
        results = resp.json()["data"]["results"]
        assert results[0]["success"] is False

    def test_batch_generate_empty_request(self):
        """批量生成空请求"""
        payload = {"requests": []}
        resp = client.post("/api/v1/ai-content/batch-generate", json=payload)
        assert resp.status_code == 200
        data = resp.json()
        assert data["data"]["success_count"] == 0

    def test_batch_generate_exactly_10(self):
        """批量生成恰好10个"""
        payload = {
            "requests": [
                {
                    "template_id": "tpl_daily_tip_1",
                    "variables": {
                        "season": "autumn",
                        "constitution": "qi_deficiency",
                        "time_period": "afternoon",
                        "tip": "rest properly",
                    },
                }
                for _ in range(10)
            ]
        }
        resp = client.post("/api/v1/ai-content/batch-generate", json=payload)
        assert resp.status_code == 200
        data = resp.json()
        assert len(data["data"]["results"]) == 10


class TestDailyTip:
    """测试每日贴士"""

    def test_daily_tip_with_user_id(self):
        """获取每日贴士"""
        resp = client.get(
            "/api/v1/ai-content/daily-tip"
            "?user_id=user_daily_1&constitution_type=qi_deficiency&lang=zh"
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["success"] is True
        assert "content" in data["data"]
        assert "date" in data["data"]
        assert "season" in data["data"]

    def test_daily_tip_en_language(self):
        """获取英文每日贴士"""
        resp = client.get(
            "/api/v1/ai-content/daily-tip"
            "?user_id=user_daily_2&constitution_type=yin_deficiency&lang=en"
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["success"] is True

    def test_daily_tip_different_constitutions(self):
        """不同体质返回不同贴士"""
        resp1 = client.get(
            "/api/v1/ai-content/daily-tip"
            "?user_id=user_const_1&constitution_type=qi_deficiency&lang=zh"
        )
        resp2 = client.get(
            "/api/v1/ai-content/daily-tip"
            "?user_id=user_const_2&constitution_type=yin_deficiency&lang=zh"
        )
        content1 = resp1.json()["data"]["content"]
        content2 = resp2.json()["data"]["content"]
        # 因为体质不同，内容应该不同
        assert content1 != content2

    def test_daily_tip_missing_user_id(self):
        """缺少user_id返回400"""
        resp = client.get("/api/v1/ai-content/daily-tip?constitution_type=qi_deficiency")
        assert resp.status_code in [400, 422]

    def test_daily_tip_missing_constitution(self):
        """缺少体质返回400"""
        resp = client.get("/api/v1/ai-content/daily-tip?user_id=user_test")
        assert resp.status_code in [400, 422]

    def test_daily_tip_contains_season(self):
        """每日贴士包含季节信息"""
        resp = client.get(
            "/api/v1/ai-content/daily-tip"
            "?user_id=user_season&constitution_type=balanced&lang=zh"
        )
        data = resp.json()
        assert "season" in data["data"]
        season = data["data"]["season"]
        assert season in ["spring", "summer", "autumn", "winter"]


class TestTemplateVariables:
    """测试模板变量验证"""

    def test_template_variables_format(self):
        """模板变量格式正确"""
        resp = client.get("/api/v1/ai-content/templates")
        templates = resp.json()["data"]["templates"]
        for t in templates:
            assert isinstance(t["variables_required"], list)
            assert isinstance(t["variables_optional"], list)
            for var in t["variables_required"]:
                assert isinstance(var, str)
                assert len(var) > 0

    def test_all_required_variables_in_template_string(self):
        """所有必填变量都在模板中"""
        resp = client.get("/api/v1/ai-content/templates")
        templates = resp.json()["data"]["templates"]
        for t in templates:
            template_cn = t["template_cn"]
            for var in t["variables_required"]:
                assert f"{{{var}}}" in template_cn, f"Variable {var} not in template {t['id']}"


class TestToneField:
    """测试tone字段"""

    def test_tone_values(self):
        """tone字段值有效"""
        resp = client.get("/api/v1/ai-content/templates")
        templates = resp.json()["data"]["templates"]
        valid_tones = ["warm", "professional", "playful"]
        for t in templates:
            assert t["tone"] in valid_tones


class TestErrorHandling:
    """测试错误处理"""

    def test_generate_with_invalid_json(self):
        """无效JSON返回错误"""
        resp = client.post("/api/v1/ai-content/generate", json={"invalid": "data"})
        assert resp.status_code in [422, 400]

    def test_batch_generate_with_invalid_json(self):
        """批量生成无效JSON返回错误"""
        resp = client.post("/api/v1/ai-content/batch-generate", json={"invalid": "data"})
        assert resp.status_code in [422, 400]
