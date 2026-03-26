"""
安全规则引擎
Safety Rules Engine — 分类规则定义与匹配

规则分类:
- medical_boundary: 医疗边界 → block
- crisis: 危机情绪 → crisis
- emotional_distress: 情绪困扰 → emotional_distress
- child_protection: 儿童保护 → sensitive
- dependency_detection: 依赖检测 → sensitive
- output_violation: 输出违规 → 修正+警告
- forbidden: 禁止内容 → block
"""

import re
import json
import logging
from dataclasses import dataclass, field
from enum import Enum
from typing import List, Optional, Pattern

from app.safety.config import SAFETY_CONFIG

logger = logging.getLogger(__name__)


class RuleCategory(str, Enum):
    """规则分类"""
    MEDICAL_BOUNDARY = "medical_boundary"
    CRISIS = "crisis"
    EMOTIONAL_DISTRESS = "emotional_distress"
    CHILD_PROTECTION = "child_protection"
    DEPENDENCY_DETECTION = "dependency_detection"
    OUTPUT_VIOLATION = "output_violation"
    FORBIDDEN = "forbidden"


class RuleSeverity(str, Enum):
    """规则严重程度"""
    NORMAL = "normal"
    SENSITIVE = "sensitive"
    EMOTIONAL_DISTRESS = "emotional_distress"
    CRISIS = "crisis"
    BLOCK = "block"


class RuleAction(str, Enum):
    """触发动作"""
    NONE = "none"                   # 无动作
    ATTACH_PREFIX = "attach_prefix" # 添加共情前缀
    BLOCK = "block"                 # 完全阻断
    CRISIS_OVERRIDE = "crisis_override"  # 危机模式覆盖
    WARN_AND_CONTINUE = "warn_and_continue"  # 警告但继续


@dataclass
class SafetyRule:
    """安全规则"""
    name: str
    category: RuleCategory
    patterns: List[str]               # 关键词或正则
    is_regex: bool = False            # 是否为正则模式
    severity: RuleSeverity = RuleSeverity.NORMAL
    action: RuleAction = RuleAction.NONE
    response_template: Optional[str] = None  # 响应模板
    compiled_patterns: List[Pattern] = field(default_factory=list, init=False)

    def __post_init__(self):
        if self.is_regex:
            self.compiled_patterns = [
                re.compile(p, re.IGNORECASE) for p in self.patterns
            ]

    def match(self, text: str) -> Optional[str]:
        """匹配文本, 返回匹配到的内容或None（大小写不敏感）"""
        text_lower = text.lower()  # Case-insensitive matching
        if self.is_regex:
            for pattern in self.compiled_patterns:
                m = pattern.search(text_lower)
                if m:
                    return m.group(0)
        else:
            for kw in self.patterns:
                if kw.lower() in text_lower:
                    return kw
        return None


def build_rules() -> List[SafetyRule]:
    """构建安全规则列表"""
    config = SAFETY_CONFIG

    rules: List[SafetyRule] = []

    # ===== 1. 危机情绪规则 =====
    rules.append(SafetyRule(
        name="crisis_keywords",
        category=RuleCategory.CRISIS,
        patterns=config["crisis_keywords"],
        severity=RuleSeverity.CRISIS,
        action=RuleAction.CRISIS_OVERRIDE,
    ))

    # ===== 2. 情绪困扰规则 =====
    rules.append(SafetyRule(
        name="distress_keywords",
        category=RuleCategory.EMOTIONAL_DISTRESS,
        patterns=config["distress_keywords"],
        severity=RuleSeverity.EMOTIONAL_DISTRESS,
        action=RuleAction.ATTACH_PREFIX,
    ))

    # ===== 3. 医疗边界规则(关键词) =====
    rules.append(SafetyRule(
        name="medical_block_keywords",
        category=RuleCategory.MEDICAL_BOUNDARY,
        patterns=config["medical_block_keywords"],
        severity=RuleSeverity.BLOCK,
        action=RuleAction.BLOCK,
        response_template=(
            "我不是医生，无法给出专业的医疗建议。\n\n"
            "每个人的身体状况不同，用药和治疗方案需要医生根据具体情况来判断。"
            "建议您：\n"
            "1. 前往正规医院就诊\n"
            "2. 咨询专业医生获取诊断\n"
            "3. 不要自行用药\n\n"
            "如果您有其他养生、保健方面的问题，我很乐意帮您~"
        ),
    ))

    # ===== 4. 医疗边界规则(正则) =====
    rules.append(SafetyRule(
        name="medical_block_patterns",
        category=RuleCategory.MEDICAL_BOUNDARY,
        patterns=config["medical_block_patterns"],
        is_regex=True,
        severity=RuleSeverity.BLOCK,
        action=RuleAction.BLOCK,
        response_template=(
            "我不是医生，无法给出专业的医疗建议。\n\n"
            "体检报告和专业医疗问题需要由专业医生来解读。\n"
            "建议您前往正规医院就诊，听取专业医生的意见。\n\n"
            "如果您有其他养生、保健方面的问题，我很乐意帮您~"
        ),
    ))

    # ===== 5. 儿童保护规则 =====
    rules.append(SafetyRule(
        name="child_protection",
        category=RuleCategory.CHILD_PROTECTION,
        patterns=config["child_protection_keywords"],
        severity=RuleSeverity.SENSITIVE,
        action=RuleAction.ATTACH_PREFIX,
        response_template=(
            "我注意到您提到的内容涉及未成年人。\n"
            "如果您或身边的孩子需要帮助，请联系：\n"
            "- 全国心理援助热线：400-161-9995\n"
            "- 儿童保护热线：12349\n"
            "- 紧急情况请拨打：110\n\n"
            "保护孩子是每个人的责任，请及时寻求帮助。"
        ),
    ))

    # ===== 6. 依赖检测规则 =====
    rules.append(SafetyRule(
        name="dependency_detection",
        category=RuleCategory.DEPENDENCY_DETECTION,
        patterns=config["dependency_keywords"],
        severity=RuleSeverity.SENSITIVE,
        action=RuleAction.ATTACH_PREFIX,
    ))

    # ===== 7. 禁止内容(暴力/色情) =====
    rules.append(SafetyRule(
        name="forbidden_patterns",
        category=RuleCategory.FORBIDDEN,
        patterns=[
            r"怎么.*杀人", r"如何.*伤害.*人", r"武器",
            r"色情", r"淫秽",
        ],
        is_regex=True,
        severity=RuleSeverity.BLOCK,
        action=RuleAction.BLOCK,
        response_template="抱歉，我无法回答这个问题。如果您有养生或健康相关的问题，我很乐意帮您~",
    ))

    # ===== 8. 输出违规规则 =====
    rules.append(SafetyRule(
        name="output_violation",
        category=RuleCategory.OUTPUT_VIOLATION,
        patterns=config["output_violation_patterns"],
        is_regex=True,
        severity=RuleSeverity.SENSITIVE,
        action=RuleAction.WARN_AND_CONTINUE,
        response_template=(
            "\n\n⚠️ 温馨提示：我是一个养生健康陪伴助手，不是医生。"
            "以上内容仅供参考，具体的医疗问题请咨询专业医生。"
        ),
    ))

    return rules


# 全局规则缓存
_rules_cache: Optional[List[SafetyRule]] = None


def get_rules() -> List[SafetyRule]:
    """获取规则列表(带缓存)"""
    global _rules_cache
    if _rules_cache is None:
        _rules_cache = build_rules()
    return _rules_cache


def reload_rules():
    """热重载规则"""
    global _rules_cache
    _rules_cache = build_rules()
    logger.info("[SafetyRules] 规则已重新加载，共 %d 条", len(_rules_cache))
