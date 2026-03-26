"""
顺时 AI 安全过滤器
Safety Filter - 关键词过滤与安全分级

安全级别：
- Normal             正常，直接回复
- EmotionalDistress  情绪困扰，添加共情前缀
- Crisis             危机情况，阻断并返回安全资源

作者: Claw 🦅
日期: 2026-03-17
"""

import re
from dataclasses import dataclass
from enum import Enum
from typing import Optional
import logging

logger = logging.getLogger(__name__)


class SafetyLevel(str, Enum):
    """安全级别"""
    NORMAL = "Normal"
    EMOTIONAL_DISTRESS = "EmotionalDistress"
    CRISIS = "Crisis"


@dataclass
class SafetyResult:
    """安全过滤结果"""
    level: SafetyLevel
    original_text: str
    filtered_text: Optional[str]
    prefix: Optional[str]  # 预设给 LLM 的共情前缀
    override_response: Optional[str]  # Crisis 模式下直接返回的响应
    matched_keywords: list

    def to_dict(self) -> dict:
        return {
            "level": self.level.value,
            "filtered_text": self.filtered_text,
            "prefix": self.prefix,
            "override_response": self.override_response,
            "matched_keywords": self.matched_keywords,
        }


# Crisis 安全资源信息
CRISIS_RESPONSE = (
    "我感受到你现在非常痛苦，你的感受很重要。💙\n\n"
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

# EmotionalDistress 共情前缀
EMPATHY_PREFIX = (
    "[系统指令：用户当前情绪状态不佳，请务必：\n"
    "1. 先表达共情和理解，不要急于给建议\n"
    "2. 用温暖、不评判的语气回应\n"
    "3. 不要说「你应该」「你不应该」\n"
    "4. 如果用户情绪很重，建议寻求专业帮助\n"
    "5. 回复中不要有任何可能加重用户负面情绪的内容]\n\n"
)


class SafetyFilter:
    """
    安全过滤器
    
    基于关键词匹配，对用户输入进行安全分级
    """

    def __init__(self):
        self.crisis_keywords = self._init_crisis_keywords()
        self.distress_keywords = self._init_distress_keywords()
        self.forbidden_patterns = self._init_forbidden_patterns()

    def _init_crisis_keywords(self) -> list:
        """Crisis 级别关键词 - 自残/轻生"""
        return [
            "想死", "不想活", "活着没意思", "想自杀", "自杀",
            "跳楼", "割腕", "吃药自杀", "结束生命",
            "从楼上跳", "不想醒来", "消失算了",
            "死了算了", "不如死", "去死", "寻死",
            "想伤害自己", "伤害自己", "自残", "自尽",
            "撑不下去", "活不下去", "没有活下去的意义",
            "想离开这个世界", "再也不想醒来",
            "让我死", "杀死自己",
        ]

    def _init_distress_keywords(self) -> list:
        """EmotionalDistress 级别关键词"""
        return [
            "崩溃", "绝望", "痛苦", "折磨", "窒息",
            "受不了", "扛不住", "撑不住", "太累了",
            "快疯了", "要疯了", "抑郁", "重度抑郁",
            "每天都很痛苦", "不想出门", "害怕出门",
            "没人理解", "没有人关心", "孤独",
            "被抛弃", "被伤害", "被欺负", "被羞辱",
            "无能为力", "无力感", "空虚", "麻木",
            "每天都哭", "控制不住哭", "哭不出来",
            "严重焦虑", "恐慌", "惊恐",
        ]

    def _init_forbidden_patterns(self) -> list:
        """禁止内容的正则模式（暴力/色情等）"""
        return [
            # 暴力
            r"怎么.*杀人", r"如何.*伤害.*人", r"武器",
            # 色情（基础过滤）
            r"色情", r"淫秽",
        ]

    def check(self, text: str) -> SafetyResult:
        """
        检查文本安全级别

        Args:
            text: 用户输入文本

        Returns:
            SafetyResult
        """
        matched = []

        # 1. 检查 Crisis 级别
        for kw in self.crisis_keywords:
            if kw in text:
                matched.append(("crisis", kw))

        if matched:
            logger.warning(f"[SafetyFilter] Crisis 检测到: {[m[1] for m in matched]}")
            return SafetyResult(
                level=SafetyLevel.CRISIS,
                original_text=text,
                filtered_text=None,
                prefix=None,
                override_response=CRISIS_RESPONSE,
                matched_keywords=[m[1] for m in matched],
            )

        # 2. 检查 EmotionalDistress 级别
        for kw in self.distress_keywords:
            if kw in text:
                matched.append(("distress", kw))

        if matched:
            logger.info(f"[SafetyFilter] EmotionalDistress 检测到: {[m[1] for m in matched]}")
            return SafetyResult(
                level=SafetyLevel.EMOTIONAL_DISTRESS,
                original_text=text,
                filtered_text=text,
                prefix=EMPATHY_PREFIX,
                override_response=None,
                matched_keywords=[m[1] for m in matched],
            )

        # 3. 检查禁止内容
        for pattern in self.forbidden_patterns:
            if re.search(pattern, text):
                matched.append(("forbidden", pattern))

        # 4. 正常
        return SafetyResult(
            level=SafetyLevel.NORMAL,
            original_text=text,
            filtered_text=text,
            prefix=None,
            override_response=None,
            matched_keywords=[],
        )


# 全局实例
safety_filter = SafetyFilter()
