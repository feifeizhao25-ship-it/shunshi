"""
顺时 AI 意图识别器
Intent Detector - 基于关键词 + 正则的轻量级意图识别

意图类型：
- health_consultation  健康咨询
- solar_term          节气养生
- food_recommendation  食疗推荐
- exercise            运动健身
- mood_support        情绪支持
- sleep               睡眠问题
- family              家庭健康
- subscription        会员订阅
- general_chat        一般聊天

作者: Claw 🦅
日期: 2026-03-17
"""

import re
from dataclasses import dataclass
from typing import Optional
import logging

logger = logging.getLogger(__name__)


class IntentType:
    """意图类型常量"""
    HEALTH_CONSULTATION = "health_consultation"
    SOLAR_TERM = "solar_term"
    FOOD_RECOMMENDATION = "food_recommendation"
    EXERCISE = "exercise"
    MOOD_SUPPORT = "mood_support"
    SLEEP = "sleep"
    FAMILY = "family"
    SUBSCRIPTION = "subscription"
    GENERAL_CHAT = "general_chat"


@dataclass
class IntentResult:
    """意图识别结果"""
    intent: str
    confidence: float
    keywords_matched: list

    def to_dict(self) -> dict:
        return {
            "intent": self.intent,
            "confidence": self.confidence,
            "keywords_matched": self.keywords_matched,
        }


class IntentDetector:
    """
    轻量级意图识别器
    
    基于关键词匹配 + 正则表达式，无需 LLM
    """

    def __init__(self):
        self.rules = self._init_rules()

    def _init_rules(self) -> dict:
        """初始化意图规则"""
        return {
            IntentType.SLEEP: {
                "keywords": [
                    "失眠", "睡不着", "入睡", "早醒", "多梦", "睡眠", "睡觉",
                    "失眠", "熬夜", "作息", "午休", "打呼", "睡眠质量",
                    "睡不着觉", "晚上醒", "起夜", "噩梦", "睡不着了",
                ],
                "patterns": [
                    r"睡[不没好差]", r"几点[睡起]", r"失眠", r"作息",
                    r"晚上.*醒", r"躺.*睡", r"入睡",
                ],
                "weight": 1.0,
            },
            IntentType.MOOD_SUPPORT: {
                "keywords": [
                    "焦虑", "抑郁", "压力", "烦", "难过", "伤心", "不开心",
                    "崩溃", "烦躁", "情绪", "心情", "孤独", "迷茫", "害怕",
                    "痛苦", "委屈", "无聊", "累", "想哭", "崩溃了",
                    "压力大", "心情不好", "情绪低", "负能量", "丧",
                    "不想活", "撑不下去", "受不了", "绝望", "自残",
                    "想死", "伤害自己", "不想活了", "活着没意思",
                ],
                "patterns": [
                    r"好[烦难累]", r"不开心", r"心情", r"情绪",
                    r"压力", r"焦虑", r"抑郁", r"崩溃",
                    r"不想活", r"想死", r"伤害自己",
                ],
                "weight": 1.0,
            },
            IntentType.SOLAR_TERM: {
                "keywords": [
                    "节气", "春分", "清明", "谷雨", "立夏", "小满",
                    "芒种", "夏至", "小暑", "大暑", "立秋", "处暑",
                    "白露", "秋分", "寒露", "霜降", "立冬", "小雪",
                    "大雪", "冬至", "小寒", "大寒", "雨水", "惊蛰",
                    "时令", "当季", "应季", "季节养生",
                ],
                "patterns": [
                    r"[春夏秋冬]天.*养", r"节气",
                    r"(春分|清明|谷雨|立夏|小满|芒种|夏至|小暑|大暑"
                    r"|立秋|处暑|白露|秋分|寒露|霜降|立冬|小雪|大雪"
                    r"|冬至|小寒|大寒|雨水|惊蛰)",
                ],
                "weight": 0.9,
            },
            IntentType.FOOD_RECOMMENDATION: {
                "keywords": [
                    "吃什么", "食疗", "养生餐", "食谱", "食材", "药膳",
                    "煲汤", "养生汤", "粥", "茶饮", "喝茶", "花茶",
                    "枸杞", "红枣", "桂圆", "山药", "薏米", "养生茶",
                    "早餐", "午餐", "晚餐", "加餐", "零食", "水果",
                    "补充营养", "吃什么好", "推荐吃",
                ],
                "patterns": [
                    r"吃[什么好]", r"推荐.*[吃食]", r"[食药]疗",
                    r"养生.*[茶汤粥]", r"[茶汤粥].*推荐",
                ],
                "weight": 0.9,
            },
            IntentType.EXERCISE: {
                "keywords": [
                    "运动", "健身", "锻炼", "跑步", "散步", "瑜伽",
                    "太极", "拉伸", "久坐", "办公室", "颈椎", "肩颈",
                    "腰酸", "背痛", "眼睛", "护眼", "微运动", "拉伸",
                    "活动一下", "筋骨", "健身操",
                ],
                "patterns": [
                    r"[运动锻炼健身]", r"跑步|散步|瑜伽|太极",
                    r"久坐|颈椎|肩颈", r"拉伸|微运动",
                ],
                "weight": 0.85,
            },
            IntentType.HEALTH_CONSULTATION: {
                "keywords": [
                    "养生", "体质", "中医", "气血", "脾胃", "肾虚",
                    "上火", "湿气", "寒性", "阳虚", "阴虚", "湿热",
                    "免疫力", "亚健康", "体质测试", "健康",
                    "怕冷", "怕热", "容易出汗", "手脚冰凉",
                    "舌苔", "脉象", "气血不足",
                ],
                "patterns": [
                    r"养生", r"体质", r"气血", r"脾胃",
                    r"上火|湿气|虚",
                ],
                "weight": 0.85,
            },
            IntentType.FAMILY: {
                "keywords": [
                    "孩子", "宝宝", "妈妈", "爸爸", "老人", "父母",
                    "家庭", "全家", "家人", "小孩", "儿童", "婴儿",
                    "长辈", "爸妈", "爷爷奶奶",
                ],
                "patterns": [
                    r"[子老父母人].*养",
                    r"家庭",
                ],
                "weight": 0.8,
            },
            IntentType.SUBSCRIPTION: {
                "keywords": [
                    "会员", "订阅", "VIP", "付费", "充值", "购买",
                    "价格", "套餐", "免费", "收费", "到期",
                ],
                "patterns": [
                    r"[会员VIP]", r"订阅|充值|购买",
                    r"套餐|付费|收费",
                ],
                "weight": 0.95,
            },
        }

    def detect(self, text: str) -> IntentResult:
        """
        识别用户意图

        Args:
            text: 用户输入文本

        Returns:
            IntentResult
        """
        text_lower = text.lower()
        scores = {}

        for intent, rule in self.rules.items():
            score = 0.0
            matched = []

            # 关键词匹配
            for kw in rule["keywords"]:
                if kw in text_lower:
                    # 短关键词权重较低
                    weight = 1.0 if len(kw) >= 3 else 0.6
                    score += weight
                    matched.append(kw)

            # 正则匹配
            for pattern in rule["patterns"]:
                if re.search(pattern, text_lower):
                    score += 0.8
                    matched.append(f"regex:{pattern[:10]}")

            if matched:
                # 归一化：除以匹配数，乘以规则权重
                normalized = min(score / max(len(matched), 1) * rule["weight"], 1.0)
                scores[intent] = {
                    "score": normalized,
                    "matched": matched,
                }

        if not scores:
            return IntentResult(
                intent=IntentType.GENERAL_CHAT,
                confidence=0.5,
                keywords_matched=[],
            )

        # 返回最高分意图
        best_intent = max(scores, key=lambda k: scores[k]["score"])
        best_data = scores[best_intent]

        return IntentResult(
            intent=best_intent,
            confidence=round(best_data["score"], 2),
            keywords_matched=best_data["matched"],
        )


# 意图 → 系统 prompt 映射
INTENT_SYSTEM_PROMPTS = {
    IntentType.SLEEP: (
        "你是顺时，一个温暖贴心的 AI 养生健康陪伴助手。\n"
        "用户正在询问睡眠相关的问题。请提供温暖实用的睡眠改善建议，\n"
        "包括睡前习惯、环境建议、放松方法等。语气温柔、不说教。"
    ),
    IntentType.MOOD_SUPPORT: (
        "你是顺时，一个温暖贴心的 AI 养生健康陪伴助手。\n"
        "用户正在表达情绪困扰。请先共情，表达理解，不要急于解决问题。\n"
        "保持温暖陪伴的语气，可以给1-2个简单可执行的小建议。\n"
        "如果用户表达自残或轻生念头，必须表达关心并建议寻求专业帮助。"
    ),
    IntentType.SOLAR_TERM: (
        "你是顺时，一个温暖贴心的 AI 养生健康陪伴助手。\n"
        "用户正在询问节气养生相关的问题。请结合当前节气，\n"
        "提供饮食、起居、运动、情志方面的养生建议。\n"
        "内容要专业但易懂，语气温暖亲切。"
    ),
    IntentType.FOOD_RECOMMENDATION: (
        "你是顺时，一个温暖贴心的 AI 养生健康陪伴助手。\n"
        "用户正在询问食疗或茶饮相关的问题。请根据体质和季节，\n"
        "推荐合适的食疗方案或养生茶饮，包含食材、做法和注意事项。\n"
        "注意：不做疾病诊断，不推荐药物。"
    ),
    IntentType.EXERCISE: (
        "你是顺时，一个温暖贴心的 AI 养生健康陪伴助手。\n"
        "用户正在询问运动健身相关的问题。请提供适合的养生运动建议，\n"
        "考虑用户的身体条件和场景（如办公室），给出简单可执行的动作。\n"
        "提醒注意安全和循序渐进。"
    ),
    IntentType.HEALTH_CONSULTATION: (
        "你是顺时，一个温暖贴心的 AI 养生健康陪伴助手。\n"
        "用户正在进行健康咨询。请提供专业的中医养生知识，\n"
        "帮助用户了解体质、气血、脾胃等方面的调养方法。\n"
        "注意：不做疾病诊断，不推荐药物，建议严重问题就医。"
    ),
    IntentType.FAMILY: (
        "你是顺时，一个温暖贴心的 AI 养生健康陪伴助手。\n"
        "用户正在询问家庭健康相关的问题。请根据家庭成员的情况，\n"
        "提供适合不同年龄段的养生建议，语气温暖贴心。"
    ),
    IntentType.SUBSCRIPTION: (
        "你是顺时，一个温暖贴心的 AI 养生健康陪伴助手。\n"
        "用户正在询问会员订阅相关的问题。请耐心解答会员权益、\n"
        "套餐价格等问题，语气友好专业。"
    ),
    IntentType.GENERAL_CHAT: (
        "你是顺时，一个温暖贴心的 AI 养生健康陪伴助手。\n"
        "你的核心特质：温暖、专业、有耐心，永远把用户健康放在第一位。\n"
        "你可以提供养生知识、分享食疗方法、讲解节气养生、\n"
        "给予情绪支持、给出睡眠/运动建议。\n"
        "不做疾病诊断，不推荐药物，不解释体检报告，不给医疗建议。"
    ),
}


# 全局实例
intent_detector = IntentDetector()
