"""
顺时 - 安全过滤系统测试
test_safety.py
"""

import pytest
from app.core.safety_filter import safety_filter, SafetyLevel, SafetyFilter, CRISIS_RESPONSE, EMPATHY_PREFIX


class TestNormalText:
    """Normal 文本通过测试"""

    def test_normal_greeting(self):
        result = safety_filter.check("你好呀")
        assert result.level == SafetyLevel.NORMAL
        assert result.filtered_text == "你好呀"
        assert result.prefix is None
        assert result.override_response is None
        assert result.matched_keywords == []

    def test_normal_health_question(self):
        result = safety_filter.check("今天适合吃什么养生餐？")
        assert result.level == SafetyLevel.NORMAL

    def test_normal_exercise_question(self):
        result = safety_filter.check("办公室久坐怎么缓解颈椎痛")
        assert result.level == SafetyLevel.NORMAL

    def test_normal_solar_term(self):
        result = safety_filter.check("立春有什么养生讲究")
        assert result.level == SafetyLevel.NORMAL

    def test_normal_food(self):
        result = safety_filter.check("推荐一个健脾祛湿的粥")
        assert result.level == SafetyLevel.NORMAL

    def test_normal_long_text(self):
        text = "我最近开始学习太极拳，每天早上打半个小时，感觉身体比以前好多了。" \
               "请问老师有什么进阶的建议吗？"
        result = safety_filter.check(text)
        assert result.level == SafetyLevel.NORMAL


class TestEmotionalDistress:
    """EmotionalDistress 检测测试"""

    def test_distress_breakdown(self):
        result = safety_filter.check("最近崩溃了")
        assert result.level == SafetyLevel.EMOTIONAL_DISTRESS
        assert result.prefix is not None
        assert "共情" in result.prefix
        assert result.override_response is None

    def test_distress_despair(self):
        result = safety_filter.check("每天都感到绝望和痛苦")
        assert result.level == SafetyLevel.EMOTIONAL_DISTRESS

    def test_distress_anxiety(self):
        result = safety_filter.check("严重焦虑，快疯了")
        assert result.level == SafetyLevel.EMOTIONAL_DISTRESS

    def test_distress_depression(self):
        result = safety_filter.check("重度抑郁，控制不住哭")
        assert result.level == SafetyLevel.EMOTIONAL_DISTRESS

    def test_distress_loneliness(self):
        result = safety_filter.check("没人理解我，被抛弃的感觉")
        assert result.level == SafetyLevel.EMOTIONAL_DISTRESS

    def test_distress_numbness(self):
        result = safety_filter.check("觉得很空虚麻木")
        assert result.level == SafetyLevel.EMOTIONAL_DISTRESS

    def test_distress_keeps_original_text(self):
        result = safety_filter.check("最近太累了扛不住")
        assert result.level == SafetyLevel.EMOTIONAL_DISTRESS
        assert result.filtered_text == "最近太累了扛不住"


class TestCrisisDetection:
    """Crisis 关键词检测测试"""

    def test_crisis_suicide(self):
        result = safety_filter.check("我想自杀")
        assert result.level == SafetyLevel.CRISIS
        assert result.override_response is not None
        assert "心理援助" in result.override_response

    def test_crisis_want_to_die(self):
        result = safety_filter.check("不想活了，想死")
        assert result.level == SafetyLevel.CRISIS

    def test_crisis_self_harm(self):
        result = safety_filter.check("想伤害自己，割腕")
        assert result.level == SafetyLevel.CRISIS

    def test_crisis_no_meaning(self):
        result = safety_filter.check("活着没意思，死了算了")
        assert result.level == SafetyLevel.CRISIS

    def test_crisis_cannot_hold_on(self):
        result = safety_filter.check("撑不下去，活不下去")
        assert result.level == SafetyLevel.CRISIS

    def test_crisis_jump(self):
        result = safety_filter.check("想从楼上跳下去")
        assert result.level == SafetyLevel.CRISIS

    def test_crisis_kill_self(self):
        result = safety_filter.check("让我死吧，杀死自己")
        assert result.level == SafetyLevel.CRISIS

    def test_crisis_no_llm(self):
        """Crisis 模式不应传递到 LLM，filtered_text 应为 None"""
        result = safety_filter.check("不想活了")
        assert result.level == SafetyLevel.CRISIS
        assert result.filtered_text is None


class TestForbiddenContent:
    """暴力/色情过滤测试"""

    def test_violence_keyword(self):
        result = safety_filter.check("怎么杀人")
        assert result is not None  # 匹配禁止模式

    def test_porn_keyword(self):
        result = safety_filter.check("色情内容")
        assert result is not None

    def test_obscene_keyword(self):
        result = safety_filter.check("淫秽信息")
        assert result is not None

    def test_normal_word_not_flagged(self):
        """正常词汇不应被误判"""
        result = safety_filter.check("养生茶的做法")
        assert result.level == SafetyLevel.NORMAL


class TestSafetyResult:
    """SafetyResult 输出测试"""

    def test_to_dict_normal(self):
        result = safety_filter.check("你好")
        d = result.to_dict()
        assert d["level"] == "Normal"
        assert "matched_keywords" in d
        assert "filtered_text" in d
        assert "prefix" in d

    def test_to_dict_crisis(self):
        result = safety_filter.check("想自杀")
        d = result.to_dict()
        assert d["level"] == "Crisis"
        assert d["override_response"] is not None

    def test_matched_keywords_recorded(self):
        result = safety_filter.check("崩溃了，太难过了")
        assert len(result.matched_keywords) > 0
        assert "崩溃" in result.matched_keywords


class TestSafetyFilterInstance:
    """SafetyFilter 实例测试"""

    def test_filter_has_crisis_keywords(self):
        sf = SafetyFilter()
        assert len(sf.crisis_keywords) > 0

    def test_filter_has_distress_keywords(self):
        sf = SafetyFilter()
        assert len(sf.distress_keywords) > 0

    def test_filter_has_forbidden_patterns(self):
        sf = SafetyFilter()
        assert len(sf.forbidden_patterns) > 0

    def test_check_returns_safety_result(self):
        sf = SafetyFilter()
        result = sf.check("测试文本")
        assert hasattr(result, "level")
        assert hasattr(result, "original_text")
