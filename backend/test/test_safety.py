"""
SafetyGuard 单元测试

运行: cd ~/Documents/Shunshi/backend && source .venv/bin/activate && pytest test/test_safety.py -v
"""

import pytest
import sys
import os

# 确保能导入 app
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from app.safety.guard import (
    SafetyGuard,
    SafetyLevel,
    SafetyResult,
    safety_guard,
    CRISIS_RESPONSE_CN,
    EMPATHY_PREFIX_CN,
)
from app.safety.rules import (
    get_rules,
    reload_rules,
    build_rules,
    RuleCategory,
    RuleSeverity,
    SafetyRule,
)
from app.safety.audit import SafetyAuditLog
from app.safety.config import SAFETY_CONFIG


# ==================== Fixtures ====================

@pytest.fixture
def guard():
    """创建 SafetyGuard 实例"""
    reload_rules()  # 确保测试用最新规则
    return SafetyGuard()


@pytest.fixture
def user_context():
    """默认用户上下文"""
    return {"user_id": "test-user-001"}


# ==================== 规则引擎测试 ====================

class TestRulesEngine:
    """规则引擎测试"""

    def test_rules_loaded(self):
        """规则加载正确"""
        rules = get_rules()
        assert len(rules) >= 8, f"至少应有8条规则，实际 {len(rules)}"

    def test_rule_categories_exist(self):
        """所有规则分类都存在"""
        rules = get_rules()
        categories = {r.category for r in rules}
        expected = {
            RuleCategory.CRISIS,
            RuleCategory.EMOTIONAL_DISTRESS,
            RuleCategory.MEDICAL_BOUNDARY,
            RuleCategory.CHILD_PROTECTION,
            RuleCategory.DEPENDENCY_DETECTION,
            RuleCategory.OUTPUT_VIOLATION,
            RuleCategory.FORBIDDEN,
        }
        assert expected.issubset(categories), f"缺少规则分类: {expected - categories}"

    def test_crisis_rule_matches(self):
        """危机规则匹配"""
        rules = get_rules()
        crisis_rule = next(
            (r for r in rules if r.name == "crisis_keywords"), None
        )
        assert crisis_rule is not None
        assert crisis_rule.match("我想死") is not None
        assert crisis_rule.match("不想活了") is not None
        assert crisis_rule.match("自杀") is not None

    def test_crisis_rule_no_false_positive(self):
        """危机规则不应误报（安全系统宁可误报也不漏报）"""
        rules = get_rules()
        crisis_rule = next(
            (r for r in rules if r.name == "crisis_keywords"), None
        )
        # "笑着活下去" — 反义不触发
        assert crisis_rule.match("笑着活下去") is None
        # "想死一样热" — 包含"想死"，安全系统宁可误报
        # 注：在安全关键场景，误报可接受，漏报不可接受

    def test_medical_keyword_rule(self):
        """医疗关键词规则"""
        rules = get_rules()
        medical_kw = next(
            (r for r in rules if r.name == "medical_block_keywords"), None
        )
        assert medical_kw is not None
        assert medical_kw.match("我头疼该吃什么药") is not None
        assert medical_kw.match("推荐药物") is not None

    def test_medical_regex_rule(self):
        """医疗正则规则"""
        rules = get_rules()
        medical_rx = next(
            (r for r in rules if r.name == "medical_block_patterns"), None
        )
        assert medical_rx is not None
        assert medical_rx.match("帮我看看体检报告") is not None
        assert medical_rx.match("帮我解读CT结果") is not None

    def test_distress_rule(self):
        """情绪困扰规则"""
        rules = get_rules()
        distress = next(
            (r for r in rules if r.name == "distress_keywords"), None
        )
        assert distress is not None
        assert distress.match("我好崩溃") is not None
        assert distress.match("每天都哭") is not None

    def test_output_violation_rule(self):
        """输出违规规则"""
        rules = get_rules()
        output_rule = next(
            (r for r in rules if r.name == "output_violation"), None
        )
        assert output_rule is not None
        assert output_rule.match("建议服用阿莫西林") is not None
        assert output_rule.match("你可以吃药来缓解") is not None

    def test_reload_rules(self):
        """热重载规则"""
        old_count = len(get_rules())
        reload_rules()
        new_count = len(get_rules())
        assert new_count == old_count


# ==================== SafetyGuard 核心测试 ====================

class TestSafetyGuard:
    """SafetyGuard 核心测试"""

    # --- 危机输入 ---

    def test_crisis_input(self, guard, user_context):
        """危机输入应触发CRISIS级别"""
        result = guard.check_input("我想死", user_context)
        assert result.level == SafetyLevel.CRISIS
        assert result.should_block is True
        assert result.redirect_to_resource is True
        assert result.override_response is not None
        assert "400-161-9995" in result.override_response

    def test_crisis_input_variants(self, guard, user_context):
        """多种危机输入变体"""
        crisis_inputs = [
            "不想活了",
            "活着没意思",
            "自杀",
            "跳楼",
            "割腕",
            "死了算了",
            "活不下去",
            "让我死",
        ]
        for text in crisis_inputs:
            result = guard.check_input(text, user_context)
            assert result.level == SafetyLevel.CRISIS, f"输入 '{text}' 应触发CRISIS，实际 {result.level}"

    # --- 医疗边界 ---

    def test_medical_block(self, guard, user_context):
        """医疗边界应阻断"""
        result = guard.check_input("我头疼该吃什么药", user_context)
        assert result.should_block is True
        assert result.override_response is not None
        assert "不是医生" in result.override_response

    def test_medical_block_patterns(self, guard, user_context):
        """医疗边界正则阻断"""
        result = guard.check_input("帮我看看体检报告", user_context)
        assert result.should_block is True

    def test_medical_block_prescription(self, guard, user_context):
        """处方类阻断"""
        result = guard.check_input("给我开处方", user_context)
        assert result.should_block is True

    # --- 正常输入 ---

    def test_normal_input(self, guard, user_context):
        """正常输入应通过"""
        result = guard.check_input("失眠怎么办", user_context)
        assert result.level == SafetyLevel.NORMAL
        assert result.should_block is False

    def test_normal_wellness(self, guard, user_context):
        """养生相关正常通过"""
        normal_inputs = [
            "今天吃什么好",
            "推荐一款茶",
            "怎么养生",
            "失眠怎么办",
            "春天适合吃什么",
            "如何调理脾胃",
            "八段锦怎么做",
        ]
        for text in normal_inputs:
            result = guard.check_input(text, user_context)
            assert result.should_block is False, f"输入 '{text}' 不应被阻断"

    def test_normal_sleep_advice(self, guard, user_context):
        """睡眠建议不应被误判为医疗"""
        result = guard.check_input("失眠怎么办", user_context)
        assert result.level == SafetyLevel.NORMAL

    # --- 情绪困扰 ---

    def test_emotional_distress(self, guard, user_context):
        """情绪困扰应附加共情前缀"""
        result = guard.check_input("我好崩溃", user_context)
        assert result.level == SafetyLevel.EMOTIONAL_DISTRESS
        assert result.prefix is not None
        assert "共情" in result.prefix

    def test_distress_not_blocked(self, guard, user_context):
        """情绪困扰不应阻断，只是添加前缀"""
        result = guard.check_input("每天都哭", user_context)
        assert result.should_block is False
        assert result.prefix is not None

    # --- 儿童保护 ---

    def test_child_protection(self, guard, user_context):
        """儿童保护规则"""
        result = guard.check_input("孩子不想活", user_context)
        assert result.should_block is True
        assert result.override_response is not None

    # --- 依赖检测 ---

    def test_dependency_detection(self, guard, user_context):
        """依赖检测应标记为敏感"""
        result = guard.check_input("你是我的全部", user_context)
        assert result.level == SafetyLevel.SENSITIVE

    # --- 输出检查 ---

    def test_output_medical_advice(self, guard, user_context):
        """AI输出含医疗建议应触发警告"""
        ai_response = "建议你服用阿莫西林来缓解症状"
        result = guard.check_output(ai_response, user_context)
        assert result.level == SafetyLevel.SENSITIVE
        assert result.flag == "output_violation"
        assert result.prefix is not None

    def test_output_clean(self, guard, user_context):
        """正常AI输出应通过"""
        ai_response = "建议你每天泡脚15分钟，有助于改善睡眠质量。"
        result = guard.check_output(ai_response, user_context)
        assert result.level == SafetyLevel.NORMAL

    def test_output_no_false_positive(self, guard, user_context):
        """输出检查不应误报养生建议"""
        ai_response = "推荐饮用菊花茶，具有清热明目的功效。"
        result = guard.check_output(ai_response, user_context)
        assert result.level == SafetyLevel.NORMAL

    # --- 响应构建 ---

    def test_crisis_response_cn(self, guard):
        """危机响应(中文)包含热线"""
        result = SafetyResult(level=SafetyLevel.CRISIS)
        response = guard.build_crisis_response(result, "cn")
        assert "400-161-9995" in response
        assert "010-82951332" in response
        assert "120" in response
        assert "110" in response

    def test_crisis_response_en(self, guard):
        """危机响应(英文)包含热线"""
        result = SafetyResult(level=SafetyLevel.CRISIS)
        response = guard.build_crisis_response(result, "en")
        assert "988" in response
        assert "911" in response

    def test_empathy_prefix(self, guard):
        """共情前缀内容正确"""
        result = SafetyResult(level=SafetyLevel.EMOTIONAL_DISTRESS)
        prefix = guard.build_empathy_prefix(result, "cn")
        assert "共情" in prefix
        assert "不评判" in prefix

    # --- 延迟测试 ---

    def test_check_latency(self, guard, user_context):
        """安全检查延迟 < 50ms"""
        import time
        text = "我今天心情不好，感觉很焦虑"
        start = time.perf_counter()
        guard.check_input(text, user_context)
        elapsed_ms = (time.perf_counter() - start) * 1000
        assert elapsed_ms < 50, f"安全检查耗时 {elapsed_ms:.1f}ms，超过 50ms 限制"

    def test_output_check_latency(self, guard, user_context):
        """输出检查延迟 < 50ms"""
        import time
        ai_response = "这是一段很长的AI回复。" * 50  # ~500字
        start = time.perf_counter()
        guard.check_output(ai_response, user_context)
        elapsed_ms = (time.perf_counter() - start) * 1000
        assert elapsed_ms < 50, f"输出检查耗时 {elapsed_ms:.1f}ms，超过 50ms 限制"

    # --- 结果序列化 ---

    def test_result_to_dict(self):
        """SafetyResult 可序列化"""
        result = SafetyResult(
            level=SafetyLevel.CRISIS,
            flag="crisis",
            should_block=True,
            redirect_to_resource=True,
            log_reason="test",
            detection_rules=["crisis_keywords"],
        )
        d = result.to_dict()
        assert d["level"] == "crisis"
        assert d["should_block"] is True


# ==================== 审计日志测试 ====================

class TestAuditLog:
    """审计日志测试"""

    def test_audit_log_creation(self):
        """审计日志表可创建"""
        audit = SafetyAuditLog()
        # 不报错即可
        assert audit is not None

    def test_audit_log_write(self):
        """审计日志可写入"""
        audit = SafetyAuditLog()
        audit.log(
            user_id="test-user",
            event_type="input_check",
            level="normal",
            content_hash="abc123",
            detection_rules=["test_rule"],
            action_taken="none",
        )
        # 不报错即可

    def test_audit_stats(self):
        """审计统计可获取"""
        audit = SafetyAuditLog()
        stats = audit.get_stats()
        assert "total_events" in stats
        assert "crisis_events" in stats
        assert "by_level" in stats


# ==================== 配置测试 ====================

class TestConfig:
    """配置测试"""

    def test_crisis_hotlines(self):
        """危机热线配置正确"""
        assert SAFETY_CONFIG["crisis_hotline_cn"] == "400-161-9995"
        assert SAFETY_CONFIG["crisis_hotline_life"] == "010-82951332"
        assert SAFETY_CONFIG["crisis_emergency"] == "120"
        assert SAFETY_CONFIG["crisis_police"] == "110"

    def test_crisis_keywords_not_empty(self):
        """危机关键词不为空"""
        assert len(SAFETY_CONFIG["crisis_keywords"]) > 0

    def test_medical_keywords_not_empty(self):
        """医疗边界关键词不为空"""
        assert len(SAFETY_CONFIG["medical_block_keywords"]) > 0

    def test_output_patterns_not_empty(self):
        """输出违规模式不为空"""
        assert len(SAFETY_CONFIG["output_violation_patterns"]) > 0


# ==================== 全局实例测试 ====================

class TestGlobalInstance:
    """全局实例测试"""

    def test_safety_guard_global_exists(self):
        """全局 safety_guard 实例存在"""
        assert safety_guard is not None

    def test_safety_guard_has_rules(self):
        """全局实例已加载规则"""
        assert len(safety_guard._rules) >= 8


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
