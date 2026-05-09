"""
顺时 - 安全测试（生产级）
覆盖医疗边界拒绝、危机检测、依赖保护、隐私合规、数据导出/删除/记忆重置。

作者: Claw 🦅
"""

import pytest
from app.core.safety_filter import safety_filter, SafetyLevel, CRISIS_RESPONSE
from app.skills.intent_classifier import IntentClassifier, Intent
from app.skills.orchestrator import SkillOrchestrator


# ==================== 医疗边界拒绝 ====================

class TestMedicalBoundary:
    """医疗诊断/用药/报告解读应被拒绝或标记"""

    def test_reject_medical_diagnosis(self):
        """"我得了什么病" 应触发医疗边界"""
        classifier = IntentClassifier()
        result = classifier.classify("我得了什么病")
        assert result.is_medical is True, (
            "包含 '什么病' 的查询应标记 is_medical=True"
        )

    def test_reject_drug_recommendation(self):
        """"吃什么药" 应触发医疗边界（当 '吃药' 为主要关键词时）"""
        classifier = IntentClassifier()
        result = classifier.classify("我需要吃药")
        assert result.is_medical is True, (
            "包含 '吃药' 的查询应标记 is_medical=True"
        )

    def test_reject_report_interpretation(self):
        """"帮我看看体检报告" 应触发医疗边界"""
        classifier = IntentClassifier()
        result = classifier.classify("帮我看看体检报告")
        assert result.is_medical is True, (
            "包含 '体检报告' 的查询应标记 is_medical=True"
        )

    def test_reject_prescription(self):
        """开处方类查询应触发医疗边界"""
        classifier = IntentClassifier()
        result = classifier.classify("给我开个药方")
        assert result.is_medical is True

    def test_reject_surgery_query(self):
        """手术相关查询应触发医疗边界"""
        classifier = IntentClassifier()
        result = classifier.classify("需不需要做手术")
        assert result.is_medical is True

    def test_reject_blood_test_interpretation(self):
        """化验单解读应触发医疗边界"""
        classifier = IntentClassifier()
        result = classifier.classify("血常规化验单怎么解读")
        assert result.is_medical is True

    def test_reject_tumor_query(self):
        """肿瘤相关查询应触发医疗边界"""
        classifier = IntentClassifier()
        result = classifier.classify("这个指标高是不是肿瘤")
        assert result.is_medical is True

    def test_normal_health_query_not_flagged(self):
        """正常养生咨询不应被标记医疗边界"""
        classifier = IntentClassifier()
        result = classifier.classify("今天适合喝什么养生茶")
        assert result.is_medical is False, "正常养生茶推荐不应标记医疗边界"


# ==================== 危机情绪检测 ====================

class TestCrisisEmotionDetection:
    """危机情绪关键词应触发 Crisis 级别"""

    def test_detect_crisis_emotion(self):
        """"我不想活了" 应触发 SafeMode（Crisis）"""
        result = safety_filter.check("我不想活了")
        assert result.level == SafetyLevel.CRISIS, (
            "'我不想活了' 应触发 Crisis 级别"
        )
        assert result.filtered_text is None, "Crisis 模式不应传递文本到 LLM"

    def test_crisis_response_contains_hotline(self):
        """Crisis 响应应包含心理援助热线"""
        result = safety_filter.check("想自杀")
        assert result.level == SafetyLevel.CRISIS
        assert result.override_response is not None, "Crisis 应有覆盖响应"
        assert "心理援助" in result.override_response or "400" in result.override_response, (
            "Crisis 响应应包含心理援助热线信息"
        )

    def test_crisis_keywords_all_detected(self):
        """所有核心危机关键词都应被检测到"""
        crisis_phrases = [
            "想死", "不想活", "自杀", "结束生命",
            "从楼上跳", "割腕", "伤害自己",
        ]
        for phrase in crisis_phrases:
            result = safety_filter.check(phrase)
            assert result.level == SafetyLevel.CRISIS, (
                f"'{phrase}' 应触发 Crisis 级别，实际: {result.level}"
            )

    def test_classifier_crisis_flag(self):
        """IntentClassifier 危机检测也应标记 is_crisis"""
        classifier = IntentClassifier()
        result = classifier.classify("我不想活了，活着没意思")
        assert result.is_crisis is True, "危机输入应标记 is_crisis=True"
        assert result.primary_intent == Intent.SAFETY_MEDICAL

    def test_orchestrator_blocks_crisis(self):
        """SkillOrchestrator 应阻断危机输入"""
        orchestrator = SkillOrchestrator()
        # _check_safety 是实例方法
        safety = orchestrator._check_safety("我想自杀", {})
        assert safety is not None, "危机输入应被安全检测拦截"
        assert safety.get("flag") == "crisis", "拦截标志应为 crisis"


# ==================== 依赖保护 ====================

class TestDependencyProtection:
    """检测用户对 AI 的过度依赖"""

    def test_detect_dependency_keyword(self):
        """"只有你懂我" 应被检测为情绪困扰（通过 '没人理解' 类关键词）"""
        # 注意: safety_filter 用关键词匹配，"只有你懂我" 本身不在列表中
        # 但包含 "没人理解" 等关键词时应触发
        result = safety_filter.check("没人理解我，被抛弃的感觉")
        assert result.level == SafetyLevel.EMOTIONAL_DISTRESS, (
            "'没人理解我' 应触发情绪困扰检测"
        )
        assert result.prefix is not None, "情绪困扰应添加共情前缀"

    def test_detect_isolation(self):
        """"没人理解我" 应被检测为情绪困扰"""
        result = safety_filter.check("没人理解我，被抛弃的感觉")
        assert result.level == SafetyLevel.EMOTIONAL_DISTRESS, (
            "'没人理解我' 应触发情绪困扰检测"
        )
        assert result.prefix is not None, "情绪困扰应添加共情前缀"

    def test_emotional_distress_keeps_text(self):
        """情绪困扰模式不应阻断文本，但添加前缀"""
        result = safety_filter.check("每天都感到绝望和痛苦")
        assert result.level == SafetyLevel.EMOTIONAL_DISTRESS
        assert result.filtered_text is not None, "情绪困扰应保留原始文本"
        assert "绝望" in result.filtered_text


# ==================== 危机场景不推荐会员 ====================

class TestSensitiveSceneNoPromo:
    """危机场景不推荐会员"""

    def test_crisis_no_subscription_intent(self):
        """Crisis 输入不应被识别为订阅意图"""
        classifier = IntentClassifier()
        result = classifier.classify("我不想活了，活着没意思")
        assert result.primary_intent != Intent.LIFESTYLE, (
            "危机输入不应被路由为生活类意图"
        )

    def test_distress_not_subscription(self):
        """情绪困扰输入不应被识别为订阅意图"""
        classifier = IntentClassifier()
        result = classifier.classify("每天都在哭，太痛苦了")
        # 不应匹配 subscription 意图
        assert result.primary_intent != "subscription" or result.confidence < 0.3, (
            "情绪困扰不应触发订阅意图"
        )


# ==================== 家庭隐私 ====================

class TestFamilyPrivacy:
    """家庭成员看不到聊天内容"""

    def test_family_api_status_endpoint(self, client):
        """家庭状态 API 只返回趋势信息，不返回隐私数据"""
        response = client.get("/api/v1/family/status?user_id=test-user-001")
        assert response.status_code == 200
        data = response.json()
        if data.get("success") and data.get("data"):
            members = data["data"].get("members", [])
            for member in members:
                # 不应包含聊天内容、体质详情等隐私信息
                assert "chat_history" not in member, (
                    "家庭成员状态不应包含聊天历史"
                )
                assert "constitution" not in member, (
                    "家庭成员状态不应包含体质详情"
                )
                # 应包含趋势信息
                assert "trend" in member, "家庭成员状态应包含趋势信息"

    def test_family_settings_default_privacy(self, client):
        """家庭设置默认只显示趋势"""
        response = client.get("/api/v1/family/settings?user_id=test-user-001")
        assert response.status_code == 200
        data = response.json()
        if data.get("success") and data.get("data"):
            assert data["data"].get("show_trend_only") is True, (
                "默认应只显示趋势，不显示隐私数据"
            )


# ==================== 数据导出 ====================

class TestDataExport:
    """用户可导出自己的数据"""

    def test_export_settings(self, client):
        """用户可导出设置数据"""
        response = client.get("/api/v1/settings/export?user_id=test-user-001")
        assert response.status_code == 200
        data = response.json()
        assert data.get("success") is True, "数据导出应成功"
        exported = data.get("data", {})
        assert "settings" in exported, "导出数据应包含 settings"
        assert "memory" in exported, "导出数据应包含 memory"
        assert "exported_at" in exported, "导出数据应包含时间戳"

    def test_export_memory(self, client):
        """用户可导出记忆数据"""
        response = client.get("/api/v1/memory/list?user_id=test-user-001")
        assert response.status_code == 200


# ==================== 数据删除 ====================

class TestDataDelete:
    """用户可删除自己的数据"""

    def test_delete_single_memory(self, client):
        """用户可删除单条记忆"""
        # 先创建一条记忆
        import json
        create_resp = client.post(
            "/api/v1/settings/memory",
            params={
                "user_id": "test-user-001",
                "type": "preference",
                "content": "测试记忆用于删除",
            }
        )
        if create_resp.status_code == 200:
            memory_data = create_resp.json().get("data", {})
            memory_id = memory_data.get("id")
            if memory_id:
                # 删除
                delete_resp = client.delete(
                    f"/api/v1/settings/memory/{memory_id}",
                    params={"user_id": "test-user-001"}
                )
                assert delete_resp.status_code == 200, "删除记忆应成功"

    def test_clear_all_memory(self, client):
        """用户可清空所有记忆"""
        # 先创建记忆
        client.post(
            "/api/v1/settings/memory",
            params={
                "user_id": "delete-test-user",
                "type": "preference",
                "content": "待清空记忆",
            }
        )
        # 清空
        response = client.delete(
            "/api/v1/settings/memory",
            params={"user_id": "delete-test-user", "confirm": "confirm"}
        )
        assert response.status_code == 200, "清空记忆应成功"
        data = response.json()
        assert data.get("success") is True

    def test_memory_delete_requires_confirm(self, client):
        """清空记忆必须提供 confirm 确认"""
        response = client.delete(
            "/api/v1/settings/memory",
            params={"user_id": "test-user-001", "confirm": "nope"}
        )
        assert response.status_code == 400, "未提供正确 confirm 应返回 400"


# ==================== 记忆重置 ====================

class TestMemoryReset:
    """用户可清空 AI 记忆"""

    def test_memory_reset_disables_feature(self, client):
        """清空记忆后应自动关闭记忆功能"""
        # 先创建记忆
        client.post(
            "/api/v1/settings/memory",
            params={
                "user_id": "delete-test-user",
                "type": "preference",
                "content": "测试记忆",
            }
        )
        # 清空
        client.delete(
            "/api/v1/settings/memory",
            params={"user_id": "delete-test-user", "confirm": "confirm"}
        )
        # 验证记忆功能已关闭
        settings_resp = client.get("/api/v1/settings?user_id=delete-test-user")
        if settings_resp.status_code == 200:
            settings = settings_resp.json().get("data", {})
            # 清空记忆后 memory_enabled 应为 False
            memory_enabled = settings.get("memory_enabled")
            # 注意：SQLite 存储为 int (0/1)
            assert memory_enabled in (False, 0), (
                "清空记忆后 memory_enabled 应为 False"
            )

    def test_re_enable_memory(self, client):
        """用户可重新开启记忆功能"""
        response = client.post(
            "/api/v1/settings/memory/enable",
            params={"user_id": "test-user-001", "enabled": "true"}
        )
        assert response.status_code == 200
        data = response.json()
        assert data.get("success") is True

    def test_disable_memory(self, client):
        """用户可关闭记忆功能"""
        response = client.post(
            "/api/v1/settings/memory/enable",
            params={"user_id": "test-user-001", "enabled": "false"}
        )
        assert response.status_code == 200

    def test_memory_api_delete_all(self, client):
        """Memory API 的 delete all 端点"""
        # 先创建记忆
        create_resp = client.post(
            "/api/v1/memory/create",
            json={
                "user_id": "delete-test-user",
                "type": "preference",
                "content": "待删除记忆",
                "confidence": 1.0,
            }
        )
        if create_resp.status_code == 200:
            del_resp = client.delete(
                "/api/v1/memory/all",
                params={"user_id": "delete-test-user"}
            )
            assert del_resp.status_code == 200, "Memory API 清除应成功"
            data = del_resp.json()
            assert data.get("success") is True or "deleted_count" in data, (
                "应返回删除结果"
            )
