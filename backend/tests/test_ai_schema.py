"""
顺时 - AI 输出 Schema 测试（生产级）
验证 LLM 输出的结构化 Schema 合规性、降级策略、Skill 路由和模型选择。

覆盖范围：
- 正常回复 Schema 结构
- 情绪支持回复 tone
- 危机关键词触发 safety_flag
- 医疗查询拦截 (safe_mode)
- follow_up 结构
- Schema 降级为纯文本
- 意图路由到正确 Skill
- 免费用户路由到低成本模型
- content_card 结构

作者: Claw 🦅
"""

import pytest
import json
from app.skills.schema_validator import (
    SchemaValidator,
    SkillOutput,
    FollowUp,
    ContentCard,
    ValidationResult,
)
from app.skills.intent_classifier import (
    IntentClassifier,
    Intent,
    INTENT_TO_CATEGORY,
)
from app.skills.skill_registry import (
    skill_registry,
    SkillDefinition,
    BASE_OUTPUT_SCHEMA,
)


# ==================== 正常回复 Schema ====================

class TestNormalResponseSchema:
    """正常回复必须包含 text/tone/care_status/follow_up/safety_flag"""

    def test_full_schema_required_fields(self):
        """完整 Schema 包含所有必填字段"""
        raw = json.dumps({
            "text": "建议你喝点菊花茶清热",
            "tone": "gentle",
            "care_status": "stable",
            "follow_up": {"in_days": 3, "intent": "sleep_check", "soft": True},
            "safety_flag": "none",
            "presence_level": "normal",
            "offline_encouraged": True,
            "suggestions": ["喝菊花茶", "早点休息"],
            "content_cards": [],
        })
        validator = SchemaValidator()
        result = validator.validate(raw)
        assert result.success is True, "标准 JSON Schema 校验应通过"
        assert "text" in result.data, "结果必须包含 text"
        assert "tone" in result.data, "结果必须包含 tone"
        assert "care_status" in result.data, "结果必须包含 care_status"
        assert "follow_up" in result.data, "结果必须包含 follow_up"
        assert "safety_flag" in result.data, "结果必须包含 safety_flag"

    def test_minimal_valid_schema(self):
        """仅提供 text 的最小合法 Schema"""
        raw = json.dumps({"text": "你好"})
        validator = SchemaValidator()
        result = validator.validate(raw)
        assert result.success is True, "最小 Schema（仅 text）应通过校验"
        assert result.data["text"] == "你好"
        # 缺失字段应自动补默认值
        assert result.data["tone"] == "gentle", "tone 缺失时应默认 gentle"
        assert result.data["care_status"] == "stable", "care_status 缺失时应默认 stable"
        assert result.data["safety_flag"] == "none", "safety_flag 缺失时应默认 none"


# ==================== 情绪支持回复 ====================

class TestEmotionResponse:
    """情绪支持回复 tone 应为 warm"""

    def test_warm_tone_for_emotion(self):
        """情绪支持回复应使用 warm 语气"""
        raw = json.dumps({
            "text": "我能感受到你最近压力很大",
            "tone": "warm",
            "care_status": "needs_attention",
            "safety_flag": "none",
        })
        validator = SchemaValidator()
        result = validator.validate(raw)
        assert result.success is True, "warm tone Schema 应校验通过"
        assert result.data["tone"] == "warm", "情绪支持回复的 tone 应为 warm"

    def test_encouraging_tone(self):
        """鼓励性回复使用 encouraging 语气"""
        raw = json.dumps({
            "text": "你已经坚持一周了，做得很好！",
            "tone": "encouraging",
            "care_status": "stable",
            "safety_flag": "none",
        })
        validator = SchemaValidator()
        result = validator.validate(raw)
        assert result.success is True
        assert result.data["tone"] == "encouraging"

    def test_invalid_tone_auto_corrected(self):
        """非法 tone 值应被自动修正为默认值"""
        raw = json.dumps({
            "text": "测试回复",
            "tone": "angry",
            "care_status": "stable",
        })
        validator = SchemaValidator()
        result = validator.validate(raw)
        assert result.success is True, "校验器应修复非法枚举值"
        assert result.data["tone"] == "gentle", "非法 tone 'angry' 应被修正为 'gentle'"

    def test_care_status_crisis(self):
        """危机状态 care_status 为 crisis"""
        raw = json.dumps({
            "text": "请立即联系心理援助热线",
            "tone": "warm",
            "care_status": "crisis",
            "safety_flag": "crisis",
        })
        validator = SchemaValidator()
        result = validator.validate(raw)
        assert result.success is True
        assert result.data["care_status"] == "crisis"


# ==================== 危机检测 ====================

class TestCrisisDetection:
    """危机关键词触发 safety_flag=crisis"""

    def test_crisis_safety_flag(self):
        """Schema 中 safety_flag=crisis 应通过校验"""
        raw = json.dumps({
            "text": "危机响应内容",
            "tone": "warm",
            "care_status": "crisis",
            "safety_flag": "crisis",
        })
        validator = SchemaValidator()
        result = validator.validate(raw)
        assert result.success is True
        assert result.data["safety_flag"] == "crisis", "安全标志应为 crisis"

    def test_invalid_safety_flag_corrected(self):
        """非法 safety_flag 应被修正为 none"""
        raw = json.dumps({
            "text": "测试",
            "safety_flag": "danger",
        })
        validator = SchemaValidator()
        result = validator.validate(raw)
        assert result.success is True
        assert result.data["safety_flag"] == "none", "非法 safety_flag 应被修正为 none"

    def test_medical_safety_flag(self):
        """医疗边界 safety_flag=medical 应通过"""
        raw = json.dumps({
            "text": "建议您咨询专业医生",
            "safety_flag": "medical",
        })
        validator = SchemaValidator()
        result = validator.validate(raw)
        assert result.success is True
        assert result.data["safety_flag"] == "medical"


# ==================== 医疗边界拦截 ====================

class TestMedicalBoundary:
    """医疗相关查询被拦截（返回 safe_mode）"""

    def test_medical_intent_classified_as_safety(self):
        """医疗诊断意图应被分类为 safety_medical"""
        classifier = IntentClassifier()
        result = classifier.classify("我得了什么病")
        assert result.is_medical is True, "包含医疗关键词 '什么病' 应标记 is_medical=True"

    def test_drug_recommendation_medical(self):
        """药物推荐意图应标记医疗边界（当 '吃药' 为主要关键词时）"""
        classifier = IntentClassifier()
        # '开点药' 匹配 '开药'（医疗关键词），不会被 diet 拦截
        result = classifier.classify("我需要吃药")
        assert result.is_medical is True, "包含 '吃药' 应标记 is_medical=True"

    def test_report_interpretation_medical(self):
        """体检报告解读应标记医疗边界"""
        classifier = IntentClassifier()
        result = classifier.classify("帮我看看体检报告")
        assert result.is_medical is True, "包含 '体检报告' 应标记 is_medical=True"

    def test_pregnancy_medical(self):
        """孕期相关问题应标记医疗边界"""
        classifier = IntentClassifier()
        result = classifier.classify("怀孕了能喝这个茶吗")
        assert result.is_medical is True, "包含 '怀孕' 应标记 is_medical=True"

    def test_normal_health_not_medical(self):
        """正常养生咨询不应标记医疗边界"""
        classifier = IntentClassifier()
        result = classifier.classify("今天适合吃什么养生餐")
        assert result.is_medical is False, "正常养生咨询不应标记医疗边界"


# ==================== Follow-up 结构 ====================

class TestFollowUpStructure:
    """follow_up 包含 in_days 和 intent"""

    def test_follow_up_complete_structure(self):
        """完整 follow_up 结构"""
        raw = json.dumps({
            "text": "注意休息",
            "follow_up": {
                "in_days": 3,
                "intent": "sleep_check",
                "soft": True,
            },
        })
        validator = SchemaValidator()
        result = validator.validate(raw)
        assert result.success is True
        fu = result.data["follow_up"]
        assert fu is not None, "follow_up 不应为 None"
        assert "in_days" in fu, "follow_up 必须包含 in_days"
        assert "intent" in fu, "follow_up 必须包含 intent"
        assert isinstance(fu["in_days"], int), "in_days 应为整数"
        assert isinstance(fu["intent"], str), "intent 应为字符串"

    def test_follow_up_in_days_range(self):
        """in_days 应在合理范围 (1-30)"""
        raw = json.dumps({
            "text": "测试",
            "follow_up": {"in_days": 15, "intent": "general_check"},
        })
        validator = SchemaValidator()
        result = validator.validate(raw)
        assert result.success is True
        assert 1 <= result.data["follow_up"]["in_days"] <= 30

    def test_follow_up_null_is_valid(self):
        """follow_up 为 null 是合法的"""
        raw = json.dumps({
            "text": "简单回复",
            "follow_up": None,
        })
        validator = SchemaValidator()
        result = validator.validate(raw)
        assert result.success is True
        assert result.data["follow_up"] is None

    def test_follow_up_soft_default(self):
        """follow_up.soft 默认为 True"""
        raw = json.dumps({
            "text": "测试",
            "follow_up": {"in_days": 3, "intent": "check"},
        })
        validator = SchemaValidator()
        result = validator.validate(raw)
        assert result.data["follow_up"]["soft"] is True, "soft 默认应为 True"


# ==================== Schema 降级 ====================

class TestSchemaFallback:
    """格式错误时降级为纯文本"""

    def test_plain_text_fallback(self):
        """纯非 JSON 文本应降级为纯文本模式"""
        validator = SchemaValidator()
        result = validator.validate("这不是JSON，只是一段普通文本回复。")
        assert result.success is False, "非 JSON 文本校验应失败"
        assert result.is_fallback is True, "应标记为降级模式"
        assert result.data["text"] is not None, "降级后 text 不应为空"
        assert result.data.get("_fallback") is True, "降级数据应包含 _fallback 标记"

    def test_broken_json_fallback(self):
        """破损 JSON 应尝试修复，修复失败则降级"""
        validator = SchemaValidator()
        result = validator.validate('{text: "缺少引号", broken: {}}')
        # 修复后应包含 text 字段
        assert result.data.get("text") is not None, "破损 JSON 修复后应有 text"

    def test_empty_response_fallback(self):
        """空响应应降级"""
        validator = SchemaValidator()
        result = validator.validate("")
        assert result.is_fallback is True, "空响应应降级"

    def test_markdown_wrapped_json(self):
        """Markdown 代码块包裹的 JSON 应能解析"""
        raw = '''```json
{"text": "建议泡脚", "tone": "warm", "care_status": "stable"}
```'''
        validator = SchemaValidator()
        result = validator.validate(raw)
        assert result.success is True, "Markdown 代码块包裹的 JSON 应能解析"
        assert result.data["text"] == "建议泡脚"

    def test_long_text_truncation(self):
        """超长文本应被截断到 2000 字符"""
        long_text = "A" * 5000
        validator = SchemaValidator()
        result = validator.validate(long_text)
        assert len(result.data["text"]) <= 2003, "降级文本不应超过 2003 字符（含省略号）"

    def test_stats_tracking(self):
        """降级统计应正确累加"""
        validator = SchemaValidator()
        # 触发几次降级
        validator.validate("纯文本1")
        validator.validate("纯文本2")
        stats = validator.get_stats()
        assert stats["fallback_count"] == 2, "应有 2 次降级记录"
        assert stats["success_rate"] < 100, "成功率应小于 100%"


# ==================== Skill 路由 ====================

class TestSkillRouting:
    """不同意图路由到正确 Skill"""

    def test_sleep_intent_routes_to_sleep_category(self):
        """睡眠意图应路由到 sleep 分类"""
        classifier = IntentClassifier()
        result = classifier.classify("我最近总是失眠")
        assert result.primary_intent == Intent.SLEEP, f"失眠查询应路由到 sleep，实际: {result.primary_intent}"

    def test_diet_intent_routes_to_diet_category(self):
        """食疗意图应路由到 diet 分类"""
        classifier = IntentClassifier()
        result = classifier.classify("今天适合吃什么养生餐")
        assert result.primary_intent == Intent.DIET, f"食疗查询应路由到 diet，实际: {result.primary_intent}"

    def test_emotion_intent_routes_to_emotion_category(self):
        """情绪意图应路由到 emotion 分类"""
        classifier = IntentClassifier()
        result = classifier.classify("最近压力很大，很焦虑")
        assert result.primary_intent == Intent.EMOTION, f"情绪查询应路由到 emotion，实际: {result.primary_intent}"

    def test_exercise_intent_routes_to_exercise_category(self):
        """运动意图应路由到 exercise 分类"""
        classifier = IntentClassifier()
        result = classifier.classify("办公室久坐怎么缓解颈椎痛")
        assert result.primary_intent == Intent.EXERCISE, f"运动查询应路由到 exercise，实际: {result.primary_intent}"

    def test_constitution_intent_routes_to_constitution_category(self):
        """体质意图应路由到 constitution 分类"""
        classifier = IntentClassifier()
        result = classifier.classify("我是气虚体质怎么调理")
        assert result.primary_intent == Intent.CONSTITUTION, f"体质查询应路由到 constitution，实际: {result.primary_intent}"

    def test_crisis_intent_routes_to_safety_medical(self):
        """危机意图应路由到 safety_medical"""
        classifier = IntentClassifier()
        result = classifier.classify("我不想活了")
        assert result.primary_intent == Intent.SAFETY_MEDICAL, f"危机输入应路由到 safety_medical，实际: {result.primary_intent}"
        assert result.is_crisis is True, "危机标记应为 True"

    def test_intent_to_category_mapping(self):
        """IntentClassifier 意图映射应在 INTENT_TO_CATEGORY 中有对应"""
        classifier = IntentClassifier()
        result = classifier.classify("立春养生吃什么")
        category = INTENT_TO_CATEGORY.get(result.primary_intent)
        assert category is not None, f"意图 {result.primary_intent} 应有对应的 Skill 分类映射"

    def test_registry_has_skills_for_category(self):
        """SkillRegistry 中各分类应有注册的 Skill"""
        categories = INTENT_TO_CATEGORY.values()
        for cat in categories:
            skills = skill_registry.get_by_category(cat)
            assert len(skills) > 0, f"分类 '{cat}' 应至少有 1 个注册的 Skill"


# ==================== 模型选择 ====================

class TestModelSelection:
    """免费用户路由到低成本模型"""

    def test_free_skills_use_low_cost_model(self):
        """免费 Skill 应使用低成本模型（deepseek-v3.2 或 minimax-m2）"""
        free_skills = skill_registry.get_free_skills()
        assert len(free_skills) > 0, "应有免费 Skill"

        low_cost_models = {"deepseek-v3.2", "minimax-m2", "glm-4.6"}
        # 至少部分免费 Skill 使用低成本模型
        low_cost_count = sum(
            1 for s in free_skills
            if s.recommended_model in low_cost_models
        )
        assert low_cost_count > 0, "应有部分免费 Skill 使用低成本模型"

    def test_premium_skills_exist(self):
        """应存在会员专属 Skill"""
        premium_skills = skill_registry.get_premium_skills()
        assert len(premium_skills) > 0, "应至少有 1 个会员专属 Skill"

    def test_premium_skills_have_higher_cost_model(self):
        """会员 Skill 应使用高质量模型（glm-4.6, qwen3-235b, kimi-k2-thinking）"""
        premium_skills = skill_registry.get_premium_skills()
        high_cost_models = {"glm-4.6", "qwen3-235b", "kimi-k2-thinking"}
        high_cost_count = sum(
            1 for s in premium_skills
            if s.recommended_model in high_cost_models
        )
        assert high_cost_count > 0, "应有部分会员 Skill 使用高质量模型"

    def test_season_daily_tip_uses_minimax(self):
        """节气每日小贴士应使用 minimax-m2（低成本）"""
        skill = skill_registry.get("generate_solar_term_daily_tip")
        assert skill is not None, "节气每日小贴士 Skill 应存在"
        assert skill.recommended_model == "minimax-m2", (
            f"节气每日小贴士应使用 minimax-m2，实际: {skill.recommended_model}"
        )

    def test_constitution_analysis_uses_kimi(self):
        """体质分析应使用 kimi-k2-thinking（深度推理）"""
        skill = skill_registry.get("analyze_constitution")
        assert skill is not None, "体质分析 Skill 应存在"
        assert skill.recommended_model == "kimi-k2-thinking", (
            f"体质分析应使用 kimi-k2-thinking，实际: {skill.recommended_model}"
        )


# ==================== Content Card 结构 ====================

class TestContentCardStructure:
    """content_card 包含 type/title/summary"""

    def test_valid_content_card(self):
        """合法 content_card 结构"""
        raw = json.dumps({
            "text": "推荐养生食谱",
            "content_cards": [
                {"type": "food", "title": "枸杞山药粥", "summary": "健脾养胃的滋补粥"},
                {"type": "tea", "title": "玫瑰花茶", "summary": "疏肝解郁的养生花茶"},
            ],
        })
        validator = SchemaValidator()
        result = validator.validate(raw)
        assert result.success is True
        cards = result.data["content_cards"]
        assert len(cards) == 2, "应有 2 个 content_card"

        for card in cards:
            assert "type" in card, "content_card 必须包含 type"
            assert "title" in card, "content_card 必须包含 title"
            assert "summary" in card, "content_card 必须包含 summary"

    def test_content_card_type_validation(self):
        """content_card type 应为合法值"""
        raw = json.dumps({
            "text": "测试",
            "content_cards": [
                {"type": "food", "title": "T", "summary": "S"},
                {"type": "exercise", "title": "T", "summary": "S"},
                {"type": "sleep", "title": "T", "summary": "S"},
                {"type": "tea", "title": "T", "summary": "S"},
                {"type": "acupoint", "title": "T", "summary": "S"},
            ],
        })
        validator = SchemaValidator()
        result = validator.validate(raw)
        assert result.success is True
        valid_types = {"food", "tea", "exercise", "acupoint", "sleep"}
        for card in result.data["content_cards"]:
            assert card["type"] in valid_types, (
                f"content_card type 应为合法值，实际: {card['type']}"
            )

    def test_content_card_max_count(self):
        """content_cards 数量应限制在 10 个以内"""
        raw = json.dumps({
            "text": "测试",
            "content_cards": [
                {"type": "food", "title": f"卡{i}", "summary": "摘要"}
                for i in range(20)
            ],
        })
        validator = SchemaValidator()
        result = validator.validate(raw)
        assert len(result.data["content_cards"]) <= 10, (
            f"content_cards 不应超过 10 个，实际: {len(result.data['content_cards'])}"
        )

    def test_suggestions_max_count(self):
        """suggestions 数量应限制在 5 个以内"""
        raw = json.dumps({
            "text": "测试",
            "suggestions": [f"建议{i}" for i in range(10)],
        })
        validator = SchemaValidator()
        result = validator.validate(raw)
        assert len(result.data["suggestions"]) <= 5, (
            f"suggestions 不应超过 5 个，实际: {len(result.data['suggestions'])}"
        )
