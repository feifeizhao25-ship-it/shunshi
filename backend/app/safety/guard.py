"""
安全守卫核心
SafetyGuard — 生产级安全过滤引擎

安全级别:
- NORMAL             正常，直接回复
- SENSITIVE          轻度敏感，正常回答但注意措辞
- EMOTIONAL_DISTRESS 情绪困扰，共情回复
- CRISIS             危机状态，触发安全协议

作者: Claw 🦅
日期: 2026-03-18
"""

import time
import hashlib
import json
import logging
from enum import Enum
from typing import Optional, List, Dict, Any

from pydantic import BaseModel

from app.safety.config import SAFETY_CONFIG
from app.safety.rules import (
    get_rules,
    reload_rules,
    SafetyRule,
    RuleCategory,
    RuleSeverity,
    RuleAction,
)
from app.safety.audit import SafetyAuditLog

logger = logging.getLogger(__name__)


class SafetyLevel(str, Enum):
    """安全级别"""
    NORMAL = "normal"
    SENSITIVE = "sensitive"                  # 轻度敏感，正常回答但注意措辞
    EMOTIONAL_DISTRESS = "emotional_distress" # 情绪困扰，共情回复
    CRISIS = "crisis"                        # 危机状态，触发安全协议


class SafetyResult(BaseModel):
    """安全过滤结果"""
    level: SafetyLevel = SafetyLevel.NORMAL
    flag: str = ""                         # 具体标记
    prefix: Optional[str] = None           # 注入到回复前的共情前缀
    should_block: bool = False             # 是否完全阻断
    redirect_to_resource: bool = False     # 是否建议联系专业资源
    log_reason: str = ""                   # 审计日志原因
    detection_rules: List[str] = []        # 触发的规则列表
    override_response: Optional[str] = None  # 直接返回的响应(危机/阻断模式)

    def to_dict(self) -> dict:
        return {
            "level": self.level.value,
            "flag": self.flag,
            "prefix": self.prefix,
            "should_block": self.should_block,
            "redirect_to_resource": self.redirect_to_resource,
            "log_reason": self.log_reason,
            "detection_rules": self.detection_rules,
            "override_response": self.override_response,
        }


# ==================== 响应模板 ====================

# 危机安全资源信息
CRISIS_RESPONSE_CN = (
    "我感受到你现在非常痛苦，你的感受很重要。\n\n"
    "在你继续之前，我想让你知道有人可以帮你：\n\n"
    "📞 **24小时心理援助热线**\n"
    "- 全国心理援助热线：400-161-9995\n"
    "- 北京心理危机研究与干预中心：010-82951332\n"
    "- 希望24热线：400-161-9995\n"
    "- 生命热线：400-821-1215\n\n"
    "🏥 **紧急情况**\n"
    "如果你或身边有人处于危险中，请立即拨打 120 或 110。\n\n"
    "你不需要独自面对这些。寻求帮助是勇敢的表现。"
)

CRISIS_RESPONSE_EN = (
    "I can feel that you're going through a really difficult time right now, "
    "and your feelings matter.\n\n"
    "Before we continue, I want you to know there are people who can help:\n\n"
    "📞 **24/7 Crisis Hotlines**\n"
    "- National Suicide Prevention Lifeline: 988\n"
    "- Crisis Text Line: Text HOME to 741741\n\n"
    "🏥 **Emergency**\n"
    "If you or someone nearby is in immediate danger, please call 911.\n\n"
    "You don't have to face this alone. Reaching out for help is an act of courage."
)

# 情绪困扰共情前缀
EMPATHY_PREFIX_CN = (
    "[系统指令：用户当前情绪状态不佳，请务必：\n"
    "1. 先表达共情和理解，不要急于给建议\n"
    "2. 用温暖、不评判的语气回应\n"
    "3. 不要说「你应该」「你不应该」\n"
    "4. 如果用户情绪很重，建议寻求专业帮助\n"
    "5. 回复中不要有任何可能加重用户负面情绪的内容]\n\n"
)

EMPATHY_PREFIX_EN = (
    "[System instruction: The user appears to be in emotional distress. "
    "Please:\n"
    "1. Start with empathy and understanding, don't rush to give advice\n"
    "2. Use a warm, non-judgmental tone\n"
    "3. Avoid saying 'you should' or 'you shouldn't'\n"
    "4. If emotions are intense, suggest seeking professional help\n"
    "5. Do not include anything that could worsen the user's emotional state]\n\n"
)

# 依赖检测响应后缀
DEPENDENCY_SUFFIX_CN = (
    "\n\n另外，虽然我很愿意陪伴你，但你的感受值得被更多的人听到。"
    "如果你愿意，也可以和身边信任的人聊聊，或者拨打心理援助热线 400-161-9995。"
)


class SafetyGuard:
    """
    生产级安全守卫

    负责:
    1. 输入安全检查 (用户消息)
    2. 输出安全检查 (AI回复)
    3. 危机响应构建
    4. 共情前缀生成
    5. 审计日志记录
    """

    def __init__(self):
        self._config = SAFETY_CONFIG
        self._audit = SafetyAuditLog()
        self._rules: List[SafetyRule] = get_rules()
        logger.info(
            "[SafetyGuard] 初始化完成，规则数量: %d", len(self._rules)
        )

    def _load_rules(self) -> List[SafetyRule]:
        """加载规则(兼容旧接口)"""
        return get_rules()

    def reload(self):
        """热重载规则"""
        reload_rules()
        self._rules = get_rules()

    # ==================== 输入检查 ====================

    def check_input(self, message: str, user_context: dict) -> SafetyResult:
        """
        检查用户输入

        按优先级: crisis > medical > forbidden > emotional_distress > child > dependency > normal

        Args:
            message: 用户消息
            user_context: 上下文 {"user_id": ..., "conversation_id": ...}

        Returns:
            SafetyResult
        """
        start = time.perf_counter()

        if not self._config.get("enable_input_check", True):
            return SafetyResult()

        triggered_rules: List[str] = []
        matched_contents: List[str] = []
        highest_severity = RuleSeverity.NORMAL
        highest_action = RuleAction.NONE
        response_template: Optional[str] = None

        for rule in self._rules:
            # 跳过输出检查专用规则
            if rule.category == RuleCategory.OUTPUT_VIOLATION:
                continue

            matched = rule.match(message)
            if matched:
                triggered_rules.append(rule.name)
                matched_contents.append(matched)

                # 取最高严重程度
                if _severity_rank(rule.severity) > _severity_rank(highest_severity):
                    highest_severity = rule.severity
                    highest_action = rule.action
                    if rule.response_template:
                        response_template = rule.response_template

                # 危机规则立即返回
                if rule.severity == RuleSeverity.CRISIS:
                    break

        elapsed_ms = (time.perf_counter() - start) * 1000

        # 构建结果
        result = SafetyResult()
        result.detection_rules = triggered_rules

        if highest_severity == RuleSeverity.CRISIS:
            lang = user_context.get("lang", self._config.get("default_lang", "cn"))
            result.level = SafetyLevel.CRISIS
            result.flag = "crisis"
            result.should_block = True
            result.redirect_to_resource = True
            result.override_response = self.build_crisis_response(result, lang)
            result.log_reason = f"Crisis detected: {', '.join(matched_contents)}"

            if self._config.get("log_all_checks"):
                self._audit.log(
                    user_id=user_context.get("user_id", "anonymous"),
                    event_type="crisis",
                    level=result.level.value,
                    content_hash=self._hash(message),
                    detection_rules=triggered_rules,
                    action_taken="crisis_override",
                    model_used=None,
                    latency_ms=elapsed_ms,
                )
            logger.warning(
                "[SafetyGuard] Crisis detected: user=%s, rules=%s, %.1fms",
                user_context.get("user_id", "?"), triggered_rules, elapsed_ms,
            )

        elif highest_severity == RuleSeverity.BLOCK:
            result.level = SafetyLevel.NORMAL  # block但不标记为危险
            result.should_block = True
            result.flag = "medical_boundary" if any("medical" in r for r in triggered_rules) else "blocked"
            result.override_response = response_template or "抱歉，这个问题超出了我的能力范围。建议咨询专业医生。"
            result.log_reason = f"Blocked: {', '.join(matched_contents)}"

            if self._config.get("log_all_checks"):
                self._audit.log(
                    user_id=user_context.get("user_id", "anonymous"),
                    event_type="input_check",
                    level="blocked",
                    content_hash=self._hash(message),
                    detection_rules=triggered_rules,
                    action_taken="blocked",
                    model_used=None,
                    latency_ms=elapsed_ms,
                )
            logger.info(
                "[SafetyGuard] Input blocked: user=%s, rules=%s, %.1fms",
                user_context.get("user_id", "?"), triggered_rules, elapsed_ms,
            )

        elif highest_severity == RuleSeverity.EMOTIONAL_DISTRESS:
            lang = user_context.get("lang", self._config.get("default_lang", "cn"))
            result.level = SafetyLevel.EMOTIONAL_DISTRESS
            result.flag = "emotional_distress"
            result.prefix = self.build_empathy_prefix(result, lang)
            result.log_reason = f"Emotional distress: {', '.join(matched_contents)}"

            if self._config.get("log_all_checks"):
                self._audit.log(
                    user_id=user_context.get("user_id", "anonymous"),
                    event_type="input_check",
                    level=result.level.value,
                    content_hash=self._hash(message),
                    detection_rules=triggered_rules,
                    action_taken="attach_prefix",
                    model_used=None,
                    latency_ms=elapsed_ms,
                )
            logger.info(
                "[SafetyGuard] Emotional distress: user=%s, rules=%s, %.1fms",
                user_context.get("user_id", "?"), triggered_rules, elapsed_ms,
            )

        elif highest_severity == RuleSeverity.SENSITIVE:
            result.level = SafetyLevel.SENSITIVE
            result.flag = "sensitive"
            result.prefix = self.build_empathy_prefix(result, "cn")

            # 依赖检测追加后缀
            if any("dependency" in r for r in triggered_rules):
                result.prefix = (result.prefix or "") + DEPENDENCY_SUFFIX_CN

            # 儿童保护有特殊模板
            if any("child" in r for r in triggered_rules) and response_template:
                result.should_block = True
                result.override_response = response_template

            result.log_reason = f"Sensitive: {', '.join(matched_contents)}"

            if self._config.get("log_all_checks"):
                self._audit.log(
                    user_id=user_context.get("user_id", "anonymous"),
                    event_type="input_check",
                    level=result.level.value,
                    content_hash=self._hash(message),
                    detection_rules=triggered_rules,
                    action_taken="sensitive_warning",
                    model_used=None,
                    latency_ms=elapsed_ms,
                )

        return result

    # ==================== 输出检查 ====================

    def check_output(self, ai_response: str, user_context: dict) -> SafetyResult:
        """
        检查AI输出（防止AI生成危险内容）

        Args:
            ai_response: AI回复文本
            user_context: 上下文

        Returns:
            SafetyResult
        """
        start = time.perf_counter()

        if not self._config.get("enable_output_check", True):
            return SafetyResult()

        triggered_rules: List[str] = []
        matched_contents: List[str] = []
        response_template: Optional[str] = None

        for rule in self._rules:
            if rule.category != RuleCategory.OUTPUT_VIOLATION:
                continue

            matched = rule.match(ai_response)
            if matched:
                triggered_rules.append(rule.name)
                matched_contents.append(matched)
                if rule.response_template:
                    response_template = rule.response_template

        elapsed_ms = (time.perf_counter() - start) * 1000

        result = SafetyResult()

        if triggered_rules:
            result.level = SafetyLevel.SENSITIVE
            result.flag = "output_violation"
            result.should_block = False
            result.prefix = response_template or ""
            result.log_reason = f"Output violation: {', '.join(matched_contents)}"
            result.detection_rules = triggered_rules

            if self._config.get("log_all_checks"):
                self._audit.log(
                    user_id=user_context.get("user_id", "anonymous"),
                    event_type="output_check",
                    level=result.level.value,
                    content_hash=self._hash(ai_response),
                    detection_rules=triggered_rules,
                    action_taken="warn_and_continue",
                    model_used=user_context.get("model"),
                    latency_ms=elapsed_ms,
                )
            logger.warning(
                "[SafetyGuard] Output violation: user=%s, rules=%s, %.1fms",
                user_context.get("user_id", "?"), triggered_rules, elapsed_ms,
            )

        return result

    # ==================== 响应构建 ====================

    def build_crisis_response(self, result: SafetyResult, lang: str = "cn") -> str:
        """生成危机响应"""
        if lang == "en":
            return CRISIS_RESPONSE_EN
        return CRISIS_RESPONSE_CN

    def build_empathy_prefix(self, result: SafetyResult, lang: str = "cn") -> str:
        """生成共情前缀"""
        if lang == "en":
            return EMPATHY_PREFIX_EN
        return EMPATHY_PREFIX_CN

    # ==================== 审计 ====================

    def audit(
        self,
        user_id: str,
        event_type: str,
        level: str,
        content_hash: str,
        detection_rules: List[str],
        action_taken: str,
        model_used: str = None,
    ):
        """记录审计日志"""
        self._audit.log(
            user_id=user_id,
            event_type=event_type,
            level=level,
            content_hash=content_hash,
            detection_rules=detection_rules,
            action_taken=action_taken,
            model_used=model_used,
        )

    # ==================== 工具方法 ====================

    @staticmethod
    def _hash(text: str) -> str:
        """计算文本hash（脱敏，不存储原始消息）"""
        return hashlib.sha256(text.encode("utf-8")).hexdigest()[:32]


# ==================== 内部函数 ====================

def _severity_rank(severity: RuleSeverity) -> int:
    """严重程度排名"""
    ranking = {
        RuleSeverity.NORMAL: 0,
        RuleSeverity.SENSITIVE: 1,
        RuleSeverity.EMOTIONAL_DISTRESS: 2,
        RuleSeverity.BLOCK: 3,
        RuleSeverity.CRISIS: 4,
    }
    return ranking.get(severity, 0)


# ==================== 全局实例 ====================

safety_guard = SafetyGuard()
