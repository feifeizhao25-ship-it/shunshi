"""
顺时 - 首次洞察生成端点测试
test_first_insight.py
"""

import pytest


class TestFirstInsight:
    """首次洞察生成端点测试"""

    def test_first_insight_spring_calm(self, client):
        """测试春季、平静心态的首次洞察生成"""
        response = client.post(
            "/api/v1/ai/generate-first-insight",
            json={
                "hemisphere": "north",
                "feeling": "calm",
                "goal": "calm",
                "style": "gentle"
            }
        )
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "insight" in data
        insight = data["insight"]
        assert "text" in insight
        assert "season" in insight
        assert "hemisphere" in insight
        assert "generated_at" in insight
        assert "tone" in insight
        assert isinstance(insight["text"], str)
        assert len(insight["text"]) > 0

    def test_first_insight_autumn_anxious(self, client):
        """测试秋季、焦虑心态的首次洞察生成"""
        response = client.post(
            "/api/v1/ai/generate-first-insight",
            json={
                "hemisphere": "north",
                "feeling": "anxious",
                "goal": "balance",
                "style": "poetic"
            }
        )
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "insight" in data
        insight = data["insight"]
        assert "text" in insight
        assert isinstance(insight["text"], str)
        assert len(insight["text"]) > 0

    def test_first_insight_south_hemisphere(self, client):
        """测试南半球的首次洞察生成"""
        response = client.post(
            "/api/v1/ai/generate-first-insight",
            json={
                "hemisphere": "south",
                "feeling": "tired",
                "goal": "energy",
                "style": "practical"
            }
        )
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        insight = data["insight"]
        assert insight["hemisphere"] == "south"
        assert "text" in insight

    def test_first_insight_missing_hemisphere(self, client):
        """测试缺少必需的 hemisphere 字段"""
        response = client.post(
            "/api/v1/ai/generate-first-insight",
            json={
                "feeling": "calm",
                "goal": "calm",
                "style": "gentle"
            }
        )
        # hemisphere 有默认值 "north"，所以应该返回 200
        # 但如果在 Pydantic 中标记为必需，则返回 422
        assert response.status_code in [200, 422]
        if response.status_code == 200:
            data = response.json()
            assert data["success"] is True

    def test_first_insight_response_has_required_fields(self, client):
        """测试首次洞察响应包含必需的字段"""
        response = client.post(
            "/api/v1/ai/generate-first-insight",
            json={
                "hemisphere": "north",
                "feeling": "calm",
                "goal": "ritual",
                "style": "gentle",
                "user_id": "test-user-001"
            }
        )
        assert response.status_code == 200
        data = response.json()

        # 检查顶级响应结构
        assert "success" in data
        assert data["success"] is True
        assert "insight" in data

        insight = data["insight"]
        # 检查 insight 对象的必需字段
        assert "text" in insight
        assert "season" in insight
        assert "hemisphere" in insight
        assert "generated_at" in insight
        assert "tone" in insight

        # 验证字段类型
        assert isinstance(insight["text"], str)
        assert isinstance(insight["season"], str)
        assert isinstance(insight["hemisphere"], str)
        assert isinstance(insight["generated_at"], str)
        assert isinstance(insight["tone"], str)

    def test_first_insight_different_feelings(self, client):
        """测试不同情感的首次洞察生成"""
        feelings = ["calm", "anxious", "tired", "overwhelmed", "curious"]
        for feeling in feelings:
            response = client.post(
                "/api/v1/ai/generate-first-insight",
                json={
                    "hemisphere": "north",
                    "feeling": feeling,
                    "goal": "calm",
                    "style": "gentle"
                }
            )
            assert response.status_code == 200
            data = response.json()
            assert data["success"] is True
            assert "insight" in data

    def test_first_insight_different_goals(self, client):
        """测试不同目标的首次洞察生成"""
        goals = ["sleep", "unwind", "calm", "ritual", "reflect"]
        for goal in goals:
            response = client.post(
                "/api/v1/ai/generate-first-insight",
                json={
                    "hemisphere": "north",
                    "feeling": "calm",
                    "goal": goal,
                    "style": "gentle"
                }
            )
            assert response.status_code == 200
            data = response.json()
            assert data["success"] is True

    def test_first_insight_different_styles(self, client):
        """测试不同文风的首次洞察生成"""
        styles = ["gentle", "poetic", "practical"]
        for style in styles:
            response = client.post(
                "/api/v1/ai/generate-first-insight",
                json={
                    "hemisphere": "north",
                    "feeling": "calm",
                    "goal": "calm",
                    "style": style
                }
            )
            assert response.status_code == 200
            data = response.json()
            assert data["success"] is True
            insight = data["insight"]
            assert insight["tone"] == style

    def test_first_insight_with_user_id(self, client):
        """测试带 user_id 的首次洞察生成"""
        response = client.post(
            "/api/v1/ai/generate-first-insight",
            json={
                "hemisphere": "north",
                "feeling": "calm",
                "goal": "calm",
                "style": "gentle",
                "user_id": "test-user-001"
            }
        )
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "insight" in data

    def test_first_insight_without_optional_fields(self, client):
        """测试仅提供 hemisphere 的首次洞察生成"""
        response = client.post(
            "/api/v1/ai/generate-first-insight",
            json={
                "hemisphere": "north"
            }
        )
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "insight" in data
        insight = data["insight"]
        # 应该使用默认值
        assert insight["tone"] == "gentle"  # 默认 style

    def test_first_insight_empty_strings_use_defaults(self, client):
        """测试空字符串字段是否使用默认值"""
        response = client.post(
            "/api/v1/ai/generate-first-insight",
            json={
                "hemisphere": "north",
                "feeling": "",
                "goal": "",
                "style": ""
            }
        )
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True

    def test_first_insight_response_generated_at_is_iso_format(self, client):
        """测试 generated_at 字段为 ISO 格式"""
        response = client.post(
            "/api/v1/ai/generate-first-insight",
            json={
                "hemisphere": "north",
                "feeling": "calm",
                "goal": "calm",
                "style": "gentle"
            }
        )
        assert response.status_code == 200
        data = response.json()
        insight = data["insight"]
        generated_at = insight["generated_at"]
        # 检查是否为有效的 ISO 格式时间戳
        assert "T" in generated_at
        assert ":" in generated_at
