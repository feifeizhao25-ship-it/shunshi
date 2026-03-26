"""
顺时 Intent Classifier - 规则引擎意图分类器
基于关键词匹配 + 上下文推断的轻量级意图识别

11 类意图分类：
- season_wellness   节气养生
- constitution      体质
- diet              食疗
- tea               茶饮
- acupoint          穴位
- sleep             睡眠
- emotion           情绪
- exercise          运动
- lifestyle         生活
- follow_up         跟进
- safety_medical    医疗边界/危机

设计原则：
- 纯规则引擎，不调用 LLM，零额外 token 消耗
- 关键词权重 + 上下文增强
- safety_medical 最高优先级，一旦命中立即返回
- 支持多意图识别（最多返回3个意图）

作者: Claw 🦅
日期: 2026-03-17
"""

import re
import logging
from dataclasses import dataclass, field
from typing import List, Optional, Tuple, Dict, Any

logger = logging.getLogger(__name__)


# ==================== 意图常量 ====================

class Intent:
    """意图类型常量"""
    SEASON_WELLNESS = "season_wellness"   # 节气养生
    CONSTITUTION = "constitution"          # 体质
    DIET = "diet"                          # 食疗
    TEA = "tea"                            # 茶饮
    ACUPOINT = "acupoint"                  # 穴位
    SLEEP = "sleep"                        # 睡眠
    EMOTION = "emotion"                    # 情绪
    EXERCISE = "exercise"                  # 运动
    LIFESTYLE = "lifestyle"                # 生活
    FOLLOW_UP = "follow_up"                # 跟进
    SAFETY_MEDICAL = "safety_medical"      # 医疗边界/危机


# 意图 → Skill 分类映射
INTENT_TO_CATEGORY = {
    Intent.SEASON_WELLNESS: "season",
    Intent.CONSTITUTION: "constitution",
    Intent.DIET: "diet",
    Intent.TEA: "tea",
    Intent.ACUPOINT: "acupoint",
    Intent.SLEEP: "sleep",
    Intent.EMOTION: "emotion",
    Intent.EXERCISE: "exercise",
    Intent.LIFESTYLE: "lifestyle",
    Intent.FOLLOW_UP: "follow_up",
    Intent.SAFETY_MEDICAL: "safety",
}


# 24 节气关键词
SOLAR_TERM_KEYWORDS = [
    "节气", "春分", "清明", "谷雨", "立夏", "小满",
    "芒种", "夏至", "小暑", "大暑", "立秋", "处暑",
    "白露", "秋分", "寒露", "霜降", "立冬", "小雪",
    "大雪", "冬至", "小寒", "大寒", "雨水", "惊蛰",
]

# 9 种体质关键词
CONSTITUTION_KEYWORDS = [
    "平和质", "气虚质", "阳虚质", "阴虚质", "痰湿质",
    "湿热质", "血瘀质", "气郁质", "特禀质",
    "体质", "体虚", "气虚", "阳虚", "阴虚", "血虚",
    "上火", "湿气", "湿热", "寒性", "热性",
    "气血不足", "脾胃虚", "肾虚", "肝火",
]


@dataclass
class IntentResult:
    """
    意图识别结果

    Attributes:
        primary_intent: 主意图（置信度最高）
        confidence: 主意图置信度 (0-1)
        all_intents: 所有识别到的意图及置信度（按置信度降序）
        keywords_matched: 匹配到的关键词列表
        context_hints: 上下文推断线索
        is_crisis: 是否为危机场景
        is_medical: 是否涉及医疗边界
    """
    primary_intent: str
    confidence: float
    all_intents: List[Tuple[str, float]] = field(default_factory=list)
    keywords_matched: List[str] = field(default_factory=list)
    context_hints: List[str] = field(default_factory=list)
    is_crisis: bool = False
    is_medical: bool = False

    def to_dict(self) -> Dict[str, Any]:
        return {
            "primary_intent": self.primary_intent,
            "confidence": self.confidence,
            "all_intents": self.all_intents,
            "keywords_matched": self.keywords_matched,
            "context_hints": self.context_hints,
            "is_crisis": self.is_crisis,
            "is_medical": self.is_medical,
        }


class IntentClassifier:
    """
    规则引擎意图分类器

    使用关键词匹配 + 正则 + 上下文推断进行意图识别。
    不调用 LLM，零额外 token 消耗。

    处理流程：
    1. 安全检测（最高优先级）
    2. 关键词匹配
    3. 正则模式匹配
    4. 上下文增强
    5. 多意图排序
    """

    def __init__(self):
        """初始化意图规则"""
        self.rules = self._init_rules()
        self.safety_keywords = self._init_safety_keywords()
        self.medical_keywords = self._init_medical_keywords()

    def _init_rules(self) -> Dict[str, Dict]:
        """初始化意图规则"""
        return {
            Intent.SEASON_WELLNESS: {
                "keywords": SOLAR_TERM_KEYWORDS + [
                    "时令", "当季", "应季", "季节养生", "春夏秋冬",
                    "入秋", "入夏", "入冬", "入春",
                    "初春", "暮春", "盛夏", "深秋", "隆冬",
                    "数九", "三伏", "梅雨",
                ],
                "patterns": [
                    r"[春夏秋冬]天.*养",
                    r"(春分|清明|谷雨|立夏|小满|芒种|夏至|小暑|大暑"
                    r"|立秋|处暑|白露|秋分|寒露|霜降|立冬|小雪|大雪"
                    r"|冬至|小寒|大寒|雨水|惊蛰)",
                    r"节气",
                    r"时令",
                    r"季节.*调理",
                ],
                "weight": 0.9,
                "boost_context": ["season"],
            },
            Intent.CONSTITUTION: {
                "keywords": CONSTITUTION_KEYWORDS + [
                    "体质测试", "体质分析", "是什么体质", "哪种体质",
                    "中医体质", "体质调理", "体寒", "体热",
                    "偏寒", "偏热", "上热下寒", "阴阳平衡",
                    "湿气重", "痰多", "怕冷", "怕热",
                    "容易出汗", "手脚冰凉", "面色", "舌苔",
                    "脉象", "气短", "乏力",
                ],
                "patterns": [
                    r"体质",
                    r"气血",
                    r"脾胃",
                    r"湿气",
                    r"[阴阳][虚盛]",
                    r"上[火热]",
                ],
                "weight": 0.9,
                "boost_context": ["constitution"],
            },
            Intent.DIET: {
                "keywords": [
                    "吃什么", "食疗", "养生餐", "食谱", "食材",
                    "药膳", "煲汤", "养生汤", "粥", "养生粥",
                    "早餐", "午餐", "晚餐", "加餐", "零食",
                    "水果", "蔬菜", "肉类", "海鲜",
                    "补充营养", "吃什么好", "推荐吃",
                    "膳食", "营养", "卡路里", "热量",
                    "忌口", "食物", "菜谱", "做菜",
                    "补钙", "补铁", "补维生素",
                    "红枣", "枸杞", "桂圆", "山药", "薏米",
                    "当归", "黄芪", "党参",
                ],
                "patterns": [
                    r"吃[什么好]",
                    r"推荐.*[吃食]",
                    r"[食药]疗",
                    r"养生.*[茶汤粥]",
                    r"[茶汤粥].*推荐",
                    r"[早中晚]餐",
                    r"[红绿]豆",
                    r"煲汤",
                ],
                "weight": 0.85,
                "boost_context": ["diet"],
            },
            Intent.TEA: {
                "keywords": [
                    "茶", "茶饮", "花茶", "养生茶", "泡茶",
                    "喝茶", "饮茶", "茶方", "茶水",
                    "枸杞茶", "菊花茶", "玫瑰花茶", "金银花茶",
                    "普洱", "绿茶", "红茶", "白茶", "乌龙茶",
                    "陈皮", "柠檬水", "蜂蜜水", "姜茶",
                    "茶包", "袋泡茶", "养生饮品",
                ],
                "patterns": [
                    r"茶",
                    r"泡.*饮",
                    r"养生.*[茶饮]",
                ],
                "weight": 0.85,
                "boost_context": [],
            },
            Intent.ACUPOINT: {
                "keywords": [
                    "穴位", "按摩", "按压", "推拿", "指压",
                    "针灸", "艾灸", "刮痧", "拔罐",
                    "足三里", "合谷", "太冲", "三阴交",
                    "内关", "涌泉", "百会", "风池",
                    "太溪", "肾俞", "命门", "关元",
                    "中脘", "曲池", "血海", "阳陵泉",
                    "经络", "经穴", "点穴",
                ],
                "patterns": [
                    r"穴位",
                    r"[按推]拿",
                    r"艾灸",
                    r"刮痧",
                    r"拔罐",
                    r"足三里|合谷|太冲|三阴交",
                ],
                "weight": 0.9,
                "boost_context": [],
            },
            Intent.SLEEP: {
                "keywords": [
                    "失眠", "睡不着", "入睡", "早醒", "多梦",
                    "睡眠", "睡觉", "熬夜", "作息", "午休",
                    "打呼", "睡眠质量", "睡不着觉", "晚上醒",
                    "起夜", "噩梦", "睡不着了", "失眠了",
                    "安神", "助眠", "好困", "犯困",
                    "睡眠不好", "睡不好", "睡不着",
                    "生物钟", "倒时差", "午睡", "打盹",
                    "睡眠障碍", "入睡困难", "睡眠浅",
                ],
                "patterns": [
                    r"睡[不没好差]",
                    r"几点[睡起]",
                    r"失眠",
                    r"作息",
                    r"晚上.*醒",
                    r"躺.*睡",
                    r"入睡",
                    r"熬夜",
                ],
                "weight": 0.9,
                "boost_context": ["sleep"],
            },
            Intent.EMOTION: {
                "keywords": [
                    "焦虑", "抑郁", "压力", "烦", "难过", "伤心",
                    "不开心", "崩溃", "烦躁", "情绪", "心情",
                    "孤独", "迷茫", "害怕", "痛苦", "委屈",
                    "无聊", "累", "想哭", "崩溃了",
                    "压力大", "心情不好", "情绪低", "负能量", "丧",
                    "焦虑症", "抑郁情绪", "紧张", "恐慌",
                    "担心", "忧虑", "消极", "低落",
                    "情绪管理", "情绪调节", "心情差",
                ],
                "patterns": [
                    r"好[烦难累]",
                    r"不开心",
                    r"心情",
                    r"情绪",
                    r"压力",
                    r"焦虑",
                    r"抑郁",
                    r"崩溃",
                ],
                "weight": 0.9,
                "boost_context": ["emotion"],
            },
            Intent.EXERCISE: {
                "keywords": [
                    "运动", "健身", "锻炼", "跑步", "散步", "瑜伽",
                    "太极", "拉伸", "久坐", "办公室", "颈椎", "肩颈",
                    "腰酸", "背痛", "眼睛", "护眼", "微运动",
                    "活动一下", "筋骨", "健身操", "八段锦",
                    "跳绳", "游泳", "骑车", "快走", "慢跑",
                    "深蹲", "俯卧撑", "仰卧起坐", "平板支撑",
                    "走路", "登山", "打球", "跳操",
                ],
                "patterns": [
                    r"[运动锻炼健身]",
                    r"跑步|散步|瑜伽|太极",
                    r"久坐|颈椎|肩颈",
                    r"拉伸|微运动",
                    r"八段锦",
                    r"筋骨",
                ],
                "weight": 0.85,
                "boost_context": ["exercise"],
            },
            Intent.LIFESTYLE: {
                "keywords": [
                    "作息", "习惯", "喝水", "泡脚", "泡澡",
                    "养生", "养生方法", "养生小技巧", "日常",
                    "穿衣", "保暖", "降温", "室内",
                    "环境", "温度", "湿度",
                    "喝水", "补水", "饮水",
                    "体态", "坐姿", "站姿",
                    "周末", "假期", "休息",
                    "养生小贴士", "健康小知识",
                    "生活方式", "生活习惯",
                ],
                "patterns": [
                    r"养生",
                    r"习惯",
                    r"泡脚",
                    r"体态",
                    r"生活方式",
                ],
                "weight": 0.75,
                "boost_context": [],
            },
            Intent.FOLLOW_UP: {
                "keywords": [
                    "跟进", "提醒", "记得", "别忘了",
                    "昨天", "上次", "之前说的",
                    "执行了没", "做了没", "坚持了没",
                    "反馈", "效果", "进展", "情况怎么样",
                    "打卡", "记录", "跟踪",
                ],
                "patterns": [
                    r"昨天.*[了吗]?",
                    r"上次.*[了吗]?",
                    r"坚持",
                    r"跟进",
                    r"提醒",
                ],
                "weight": 0.8,
                "boost_context": [],
            },
        }

    def _init_safety_keywords(self) -> List[str]:
        """初始化危机关键词（自残/轻生）"""
        return [
            "想死", "不想活", "活着没意思", "想自杀", "自杀",
            "跳楼", "割腕", "吃药自杀", "结束生命",
            "从楼上跳", "不想醒来", "消失算了",
            "死了算了", "不如死", "去死", "寻死",
            "想伤害自己", "伤害自己", "自残", "自尽",
            "撑不下去", "活不下去", "没有活下去的意义",
            "想离开这个世界", "再也不想醒来",
            "让我死", "杀死自己", "想不开",
        ]

    def _init_medical_keywords(self) -> List[str]:
        """初始化医疗边界关键词"""
        return [
            "诊断", "确诊", "看病", "药方", "处方",
            "手术", "住院", "输液", "打针",
            "检查报告", "体检报告", "化验单",
            "血常规", "尿常规", "CT", "核磁",
            "血压高", "血糖高", "尿酸高", "胆固醇",
            "肿瘤", "癌症", "良性", "恶性",
            "怀孕", "孕期", "哺乳期",
            "疫苗", "接种",
            "什么病", "得了什么", "是不是XX病",
            "用药", "吃药", "剂量", "副作用",
        ]

    def classify(
        self,
        text: str,
        context: Optional[Dict[str, Any]] = None,
    ) -> IntentResult:
        """
        分类用户意图

        Args:
            text: 用户输入文本
            context: 用户上下文（体质/睡眠/情绪/节气等）

        Returns:
            IntentResult
        """
        if not text:
            return IntentResult(
                primary_intent=Intent.LIFESTYLE,
                confidence=0.3,
                all_intents=[],
                keywords_matched=[],
                context_hints=["空输入"],
            )

        text_lower = text.lower()

        # ==================== Step 1: 安全检测（最高优先级） ====================
        crisis_matched = []
        for kw in self.safety_keywords:
            if kw in text_lower:
                crisis_matched.append(kw)

        if crisis_matched:
            logger.warning(f"[IntentClassifier] 危机检测命中: {crisis_matched}")
            return IntentResult(
                primary_intent=Intent.SAFETY_MEDICAL,
                confidence=1.0,
                all_intents=[(Intent.SAFETY_MEDICAL, 1.0)],
                keywords_matched=crisis_matched,
                context_hints=["crisis_detected"],
                is_crisis=True,
            )

        # ==================== Step 2: 医疗边界检测 ====================
        medical_matched = []
        for kw in self.medical_keywords:
            if kw in text_lower:
                medical_matched.append(kw)

        # ==================== Step 3: 正常意图匹配 ====================
        scores: Dict[str, float] = {}
        all_matched: Dict[str, List[str]] = {}

        for intent, rule in self.rules.items():
            score = 0.0
            matched = []

            # 关键词匹配
            for kw in rule["keywords"]:
                if kw in text_lower:
                    weight = 1.0 if len(kw) >= 2 else 0.6
                    score += weight
                    matched.append(kw)

            # 正则匹配
            for pattern in rule["patterns"]:
                if re.search(pattern, text_lower):
                    score += 0.8
                    matched.append(f"regex:{pattern[:10]}")

            if matched:
                # 归一化并乘以权重
                normalized = min(score / max(len(matched), 1) * rule["weight"], 1.0)

                # 上下文增强
                if context:
                    boost_ctx = rule.get("boost_context", [])
                    for ctx_key in boost_ctx:
                        if context.get(ctx_key):
                            normalized = min(normalized + 0.15, 1.0)
                            matched.append(f"context:{ctx_key}")

                scores[intent] = normalized
                all_matched[intent] = matched

        # ==================== Step 4: 医医疗边界 + 普通意图 ====================
        # 如果匹配到医疗关键词但不属于危机，添加 medical 信号
        if medical_matched and not crisis_matched:
            # 医疗边界作为辅助信息附加到主意图上
            if scores:
                best_intent = max(scores, key=scores.get)
                all_matched.get(best_intent, []).extend(medical_matched)

        # ==================== Step 5: 排序并返回 ====================
        if not scores:
            return IntentResult(
                primary_intent=Intent.LIFESTYLE,
                confidence=0.4,
                all_intents=[(Intent.LIFESTYLE, 0.4)],
                keywords_matched=[],
                context_hints=["no_match"],
                is_medical=bool(medical_matched),
            )

        # 按置信度排序
        sorted_intents = sorted(scores.items(), key=lambda x: x[1], reverse=True)

        # 取前3个意图（置信度 > 0.2）
        top_intents = [
            (intent, round(conf, 2))
            for intent, conf in sorted_intents[:3]
            if conf > 0.2
        ]

        primary_intent = top_intents[0][0] if top_intents else Intent.LIFESTYLE
        primary_confidence = top_intents[0][1] if top_intents else 0.4
        primary_matched = all_matched.get(primary_intent, [])

        # 收集所有匹配关键词
        all_keywords = []
        for intent_keywords in all_matched.values():
            all_keywords.extend(intent_keywords)

        # 上下文推断线索
        context_hints = []
        if context:
            if context.get("constitution"):
                context_hints.append("用户有体质数据")
            if context.get("sleep") and context["sleep"].get("quality") == "poor":
                context_hints.append("用户睡眠不佳")
            if context.get("emotion") and context["emotion"].get("level") in ["anxious", "depressed"]:
                context_hints.append("用户情绪低落")

        return IntentResult(
            primary_intent=primary_intent,
            confidence=primary_confidence,
            all_intents=top_intents,
            keywords_matched=primary_matched,
            context_hints=context_hints,
            is_crisis=False,
            is_medical=bool(medical_matched),
        )

    def classify_quick(self, text: str) -> str:
        """
        快速分类（只返回主意图字符串）

        用于性能敏感场景。
        """
        result = self.classify(text)
        return result.primary_intent


# ==================== 全局实例 ====================

intent_classifier = IntentClassifier()


# ==================== 使用示例 ====================

def demo_classifier():
    """演示意图分类器"""
    classifier = IntentClassifier()

    test_cases = [
        "今天春分了，吃什么好？",
        "我最近总失眠，睡不着",
        "工作压力太大了，很焦虑",
        "推荐一个养生茶饮",
        "足三里穴怎么按？",
        "办公室久坐了，想活动一下",
        "我好像气虚体质",
        "昨天说的泡脚做了吗？",
        "血压高应该吃什么？",
        "想死，活不下去",
        "夏天养生要注意什么？",
        "帮我制定一个作息计划",
        "心情不好，需要安慰",
    ]

    print("=" * 60)
    print("顺时 Intent Classifier 演示")
    print("=" * 60)

    for text in test_cases:
        result = classifier.classify(text)
        crisis_flag = " [CRISIS]" if result.is_crisis else ""
        medical_flag = " [MEDICAL]" if result.is_medical else ""
        print(f"\n  输入: {text}")
        print(f"  意图: {result.primary_intent} ({result.confidence}){crisis_flag}{medical_flag}")
        if result.all_intents:
            others = ", ".join([f"{i}({c})" for i, c in result.all_intents[1:]])
            if others:
                print(f"  其他: {others}")


if __name__ == "__main__":
    demo_classifier()
