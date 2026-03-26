"""
顺时 Skill 注册表 - LOS (Life Operating System) 核心
Skill Registry - 300+ 个养生技能定义

每个 Skill 包含：
- skill_id, category, name, description
- version, priority, required_context, tags
- output_schema, recommended_model, max_tokens
- is_premium, cooldown_hours, dependencies

15 个一级分类：
season, constitution, diet, tea, acupoint, exercise, sleep,
emotion, lifestyle, daily_plan, follow_up, family, safety,
meta, reflection

作者: Claw 🦅
日期: 2026-03-17
"""

from __future__ import annotations
from typing import Dict, List, Optional, Any, Set
from dataclasses import dataclass, field
from enum import Enum
import logging

logger = logging.getLogger(__name__)


# ==================== 枚举 & 常量 ====================

class SkillCategory(str, Enum):
    """Skill 一级分类"""
    SEASON = "season"                    # 节气
    CONSTITUTION = "constitution"        # 体质
    DIET = "diet"                        # 食疗
    TEA = "tea"                          # 茶饮
    ACUPOINT = "acupoint"                # 穴位
    EXERCISE = "exercise"                # 运动
    SLEEP = "sleep"                      # 睡眠
    EMOTION = "emotion"                  # 情绪
    LIFESTYLE = "lifestyle"              # 生活
    DAILY_PLAN = "daily_plan"            # 计划
    FOLLOW_UP = "follow_up"              # 跟进
    FAMILY = "family"                    # 家庭
    SAFETY = "safety"                    # 安全
    META = "meta"                        # 系统控制
    REFLECTION = "reflection"            # 复盘


class Priority(str, Enum):
    """优先级"""
    P0 = "P0"   # 核心高频
    P1 = "P1"   # 重要功能
    P2 = "P2"   # 辅助扩展


# 可用模型列表（与 config.py 中的 MODEL_CONFIG 保持一致）
AVAILABLE_MODELS = [
    "deepseek-v3.2",
    "glm-4.6",
    "qwen3-235b",
    "kimi-k2-thinking",
    "minimax-m2",
]

# 可用上下文字段
CONTEXT_KEYS = [
    "constitution",   # 体质
    "sleep",          # 睡眠
    "emotion",        # 情绪
    "season",         # 季节/节气
    "life_stage",     # 生命阶段
    "family",         # 家庭
    "diet",           # 饮食
    "exercise",       # 运动
    "membership",     # 会员等级
]

# 24 节气列表
SOLAR_TERMS = [
    "立春", "雨水", "惊蛰", "春分", "清明", "谷雨",
    "立夏", "小满", "芒种", "夏至", "小暑", "大暑",
    "立秋", "处暑", "白露", "秋分", "寒露", "霜降",
    "立冬", "小雪", "大雪", "冬至", "小寒", "大寒",
]

# 节气内容维度
SOLAR_TERM_DIMENSIONS = [
    "profile",        # 总览
    "diet",           # 饮食
    "exercise",       # 运动
    "sleep",          # 睡眠
    "emotion",        # 情志
    "tea",            # 茶饮
    "acupoint",       # 穴位
]


# ==================== Skill 数据类 ====================

@dataclass
class SkillDefinition:
    """
    Skill 完整定义

    Attributes:
        skill_id: 技能唯一标识 (snake_case)
        category: 一级分类
        name: 中文显示名
        description: 功能描述
        version: 版本号
        priority: 优先级 (P0/P1/P2)
        required_context: 需要的上下文字段列表
        tags: 标签列表
        output_schema: 输出 JSON 结构定义
        recommended_model: 推荐模型
        max_tokens: 建议 token 数
        is_premium: 是否会员专属
        cooldown_hours: 冷却时间（小时）
        dependencies: 依赖的其他 skill_id 列表
    """
    skill_id: str
    category: str
    name: str
    description: str
    version: str = "1.0.0"
    priority: str = "P1"
    required_context: List[str] = field(default_factory=list)
    tags: List[str] = field(default_factory=list)
    output_schema: Dict[str, Any] = field(default_factory=dict)
    recommended_model: str = "deepseek-v3.2"
    max_tokens: int = 2048
    is_premium: bool = False
    cooldown_hours: int = 0
    dependencies: List[str] = field(default_factory=list)

    def to_dict(self) -> Dict[str, Any]:
        """序列化为字典"""
        return {
            "skill_id": self.skill_id,
            "category": self.category,
            "name": self.name,
            "description": self.description,
            "version": self.version,
            "priority": self.priority,
            "required_context": self.required_context,
            "tags": self.tags,
            "output_schema": self.output_schema,
            "recommended_model": self.recommended_model,
            "max_tokens": self.max_tokens,
            "is_premium": self.is_premium,
            "cooldown_hours": self.cooldown_hours,
            "dependencies": self.dependencies,
        }


# ==================== 通用输出 Schema ====================

# 基础输出 Schema（所有 Skill 共用）
BASE_OUTPUT_SCHEMA = {
    "type": "object",
    "required": ["text", "tone", "care_status"],
    "properties": {
        "text": {"type": "string", "description": "回复文本"},
        "tone": {
            "type": "string",
            "enum": ["gentle", "warm", "encouraging"],
            "default": "gentle",
            "description": "语气风格",
        },
        "care_status": {
            "type": "string",
            "enum": ["stable", "tired", "needs_attention", "crisis"],
            "default": "stable",
            "description": "关怀状态",
        },
        "suggestions": {
            "type": "array",
            "items": {"type": "string"},
            "maxItems": 5,
            "description": "建议列表",
        },
        "content_cards": {
            "type": "array",
            "items": {
                "type": "object",
                "required": ["type", "title", "summary"],
                "properties": {
                    "type": {
                        "type": "string",
                        "enum": ["food", "tea", "exercise", "acupoint", "sleep"],
                    },
                    "title": {"type": "string"},
                    "summary": {"type": "string"},
                },
            },
            "description": "内容卡片列表",
        },
        "follow_up": {
            "type": "object",
            "properties": {
                "in_days": {"type": "integer", "minimum": 1, "maximum": 7},
                "intent": {"type": "string"},
                "soft": {"type": "boolean", "default": True},
            },
            "description": "跟进计划",
        },
        "presence_level": {
            "type": "string",
            "enum": ["present", "normal", "retreating"],
            "default": "normal",
        },
        "safety_flag": {
            "type": "string",
            "enum": ["none", "medical", "risk", "crisis"],
            "default": "none",
        },
        "offline_encouraged": {
            "type": "boolean",
            "default": True,
        },
    },
}

# 内容卡片 Schema
CONTENT_CARD_SCHEMA = {
    "type": "object",
    "required": ["type", "title", "summary"],
    "properties": {
        "type": {"type": "string", "enum": ["food", "tea", "exercise", "acupoint", "sleep"]},
        "title": {"type": "string"},
        "summary": {"type": "string"},
    },
}


# ==================== Skill 工厂函数 ====================

def _skill(
    skill_id: str,
    category: str,
    name: str,
    description: str,
    priority: str = "P1",
    context: Optional[List[str]] = None,
    tags: Optional[List[str]] = None,
    model: str = "deepseek-v3.2",
    max_tokens: int = 2048,
    is_premium: bool = False,
    cooldown: int = 0,
    deps: Optional[List[str]] = None,
) -> SkillDefinition:
    """快速创建 Skill 定义的工厂函数"""
    return SkillDefinition(
        skill_id=skill_id,
        category=category,
        name=name,
        description=description,
        version="1.0.0",
        priority=priority,
        required_context=context or [],
        tags=tags or [],
        output_schema=BASE_OUTPUT_SCHEMA,
        recommended_model=model,
        max_tokens=max_tokens,
        is_premium=is_premium,
        cooldown_hours=cooldown,
        dependencies=deps or [],
    )


# ==================== 1. Season 节气 Skills (30+) ====================

def _build_season_skills() -> Dict[str, SkillDefinition]:
    """构建节气分类的所有 Skill（含 24 节气动态生成）"""
    skills: Dict[str, SkillDefinition] = {}

    # --- 核心节气 Skill（20 个手动定义）---
    skills["detect_current_solar_term"] = _skill(
        "detect_current_solar_term", "season", "当前节气检测",
        "根据当前日期自动检测所属节气，返回节气名称、日期范围和养生要点",
        priority="P0", context=["season"], tags=["节气", "自动", "检测"],
        model="minimax-m2", max_tokens=512, cooldown=0,
    )
    skills["detect_next_solar_term"] = _skill(
        "detect_next_solar_term", "season", "下一节气预览",
        "检测即将到来的下一个节气，给出提前准备的养生建议",
        priority="P1", context=["season"], tags=["节气", "预告", "准备"],
        model="minimax-m2", max_tokens=512, cooldown=0,
    )
    skills["generate_solar_term_profile"] = _skill(
        "generate_solar_term_profile", "season", "节气总览",
        "生成当前节气的完整养生总览：气候特征、养生重点、饮食起居运动情志",
        priority="P0", context=["season", "constitution"], tags=["节气", "总览", "综合"],
        model="glm-4.6", max_tokens=2048,
    )
    skills["generate_solar_term_diet"] = _skill(
        "generate_solar_term_diet", "season", "节气饮食建议",
        "根据当前节气推荐应季食材和养生食谱",
        priority="P0", context=["season", "constitution", "diet"], tags=["节气", "饮食", "食疗"],
        model="glm-4.6", max_tokens=2048,
    )
    skills["generate_solar_term_exercise"] = _skill(
        "generate_solar_term_exercise", "season", "节气运动建议",
        "根据当前节气推荐适合的运动方式和注意事项",
        priority="P1", context=["season", "life_stage", "exercise"], tags=["节气", "运动"],
        model="glm-4.6", max_tokens=1024,
    )
    skills["generate_solar_term_sleep"] = _skill(
        "generate_solar_term_sleep", "season", "节气睡眠建议",
        "根据当前节气调整作息时间和睡眠习惯",
        priority="P1", context=["season", "sleep"], tags=["节气", "睡眠"],
        model="glm-4.6", max_tokens=1024,
    )
    skills["generate_solar_term_emotion"] = _skill(
        "generate_solar_term_emotion", "season", "节气情志调养",
        "根据当前节气提供情志调节和情绪管理建议",
        priority="P1", context=["season", "emotion"], tags=["节气", "情志", "情绪"],
        model="glm-4.6", max_tokens=1024,
    )
    skills["generate_solar_term_tea"] = _skill(
        "generate_solar_term_tea", "season", "节气茶饮推荐",
        "根据当前节气推荐养生茶饮和配方",
        priority="P1", context=["season", "constitution"], tags=["节气", "茶饮"],
        model="glm-4.6", max_tokens=1024,
    )
    skills["generate_solar_term_acupoint"] = _skill(
        "generate_solar_term_acupoint", "season", "节气穴位保健",
        "根据当前节气推荐适合按摩的穴位",
        priority="P1", context=["season"], tags=["节气", "穴位"],
        model="glm-4.6", max_tokens=1024,
    )
    skills["generate_solar_term_7_day_plan"] = _skill(
        "generate_solar_term_7_day_plan", "season", "节气7日养生计划",
        "围绕当前节气生成7天完整养生计划",
        priority="P1", context=["season", "constitution", "life_stage"],
        tags=["节气", "计划", "7天"], model="qwen3-235b", max_tokens=4096,
        is_premium=True, cooldown=168,
    )
    skills["generate_solar_term_avoid_list"] = _skill(
        "generate_solar_term_avoid_list", "season", "节气禁忌清单",
        "当前节气应避免的食物和行为",
        priority="P1", context=["season"], tags=["节气", "禁忌"],
        model="deepseek-v3.2", max_tokens=1024,
    )
    skills["generate_solar_term_daily_tip"] = _skill(
        "generate_solar_term_daily_tip", "season", "节气每日小贴士",
        "根据当前节气生成今日养生小贴士",
        priority="P0", context=["season"], tags=["节气", "每日", "小贴士"],
        model="minimax-m2", max_tokens=512, cooldown=24,
    )
    skills["generate_solar_term_morning_tip"] = _skill(
        "generate_solar_term_morning_tip", "season", "节气晨间养生",
        "当前节气早晨养生建议：起床、早餐、晨练",
        priority="P1", context=["season"], tags=["节气", "早晨"],
        model="deepseek-v3.2", max_tokens=512,
    )
    skills["generate_solar_term_evening_tip"] = _skill(
        "generate_solar_term_evening_tip", "season", "节气晚间养生",
        "当前节气晚间养生建议：晚餐、放松、入睡",
        priority="P1", context=["season", "sleep"], tags=["节气", "晚间"],
        model="deepseek-v3.2", max_tokens=512,
    )
    skills["generate_solar_term_transition_tip"] = _skill(
        "generate_solar_term_transition_tip", "season", "节气交替注意",
        "两个节气交替期间的养生过渡建议",
        priority="P1", context=["season"], tags=["节气", "交替"],
        model="glm-4.6", max_tokens=1024,
    )
    skills["generate_solar_term_weather_adjustment"] = _skill(
        "generate_solar_term_weather_adjustment", "season", "节气天气应对",
        "根据当前节气气候特征提供穿衣出行建议",
        priority="P2", context=["season"], tags=["节气", "天气"],
        model="deepseek-v3.2", max_tokens=512,
    )
    skills["generate_solar_term_body_adjustment"] = _skill(
        "generate_solar_term_body_adjustment", "season", "节气身体调适",
        "当前节气身体调适建议，结合体质类型",
        priority="P1", context=["season", "constitution"], tags=["节气", "身体"],
        model="glm-4.6", max_tokens=1024,
    )
    skills["generate_solar_term_office_adjustment"] = _skill(
        "generate_solar_term_office_adjustment", "season", "节气办公室养生",
        "办公室场景的节气养生建议",
        priority="P2", context=["season"], tags=["节气", "办公室"],
        model="deepseek-v3.2", max_tokens=512,
    )
    skills["generate_solar_term_travel_adjustment"] = _skill(
        "generate_solar_term_travel_adjustment", "season", "节气出行养生",
        "出行/旅游场景的节气养生建议",
        priority="P2", context=["season"], tags=["节气", "出行"],
        model="deepseek-v3.2", max_tokens=512,
    )
    skills["generate_solar_term_family_advice"] = _skill(
        "generate_solar_term_family_advice", "season", "节气家庭养生",
        "当前节气全家人适用的养生建议",
        priority="P1", context=["season", "family", "life_stage"], tags=["节气", "家庭"],
        model="glm-4.6", max_tokens=2048,
    )

    # --- 动态生成：24 节气 × 7 维度 ---
    # 使用 generate_solar_term_content(term, dimension) 统一入口
    # 注册一个动态分发 Skill
    skills["generate_solar_term_content"] = _skill(
        "generate_solar_term_content", "season", "节气内容生成（动态）",
        "根据指定的节气名称和维度（profile/diet/exercise/sleep/emotion/tea/acupoint）"
        "动态生成对应养生内容。24节气×7维度共168种组合通过此Skill统一处理。",
        priority="P0",
        context=["season", "constitution", "life_stage"],
        tags=["节气", "动态", "生成", "通用"],
        model="glm-4.6", max_tokens=2048,
    )

    # 为常用节气注册快捷 Skill（确保至少30个）
    popular_terms = ["立春", "清明", "谷雨", "立夏", "夏至", "大暑",
                     "立秋", "白露", "秋分", "立冬", "冬至", "大寒"]
    for term in popular_terms:
        sid = f"solar_term_{_term_to_pinyin(term)}"
        skills[sid] = _skill(
            sid, "season", f"{term}养生指南",
            f"{term}节气完整养生建议，包含饮食、运动、起居、情志",
            priority="P1", context=["season", "constitution", "life_stage"],
            tags=["节气", term, "指南"],
            model="glm-4.6", max_tokens=2048,
            deps=["generate_solar_term_content"],
        )

    return skills


def _term_to_pinyin(term: str) -> str:
    """节气名称转拼音标识（简化版，用于 skill_id）"""
    mapping = {
        "立春": "lichun", "雨水": "yushui", "惊蛰": "jingzhe", "春分": "chunfen",
        "清明": "qingming", "谷雨": "guyu", "立夏": "lixia", "小满": "xiaoman",
        "芒种": "mangzhong", "夏至": "xiazhi", "小暑": "xiaoshu", "大暑": "dashu",
        "立秋": "liqiu", "处暑": "chushu", "白露": "bailu", "秋分": "qiufen",
        "寒露": "hanlu", "霜降": "shuangjiang", "立冬": "lidong", "小雪": "xiaoxue",
        "大雪": "daxue", "冬至": "dongzhi", "小寒": "xiaohan", "大寒": "dahan",
    }
    return mapping.get(term, "unknown")


# ==================== 2. Constitution 体质 Skills (30) ====================

def _build_constitution_skills() -> Dict[str, SkillDefinition]:
    """构建体质分类的所有 Skill"""
    skills: Dict[str, SkillDefinition] = {}

    # 九种体质
    constitutions = [
        ("pinghe", "平和质", "阴阳气血调和，体态适中"),
        ("qixu", "气虚质", "元气不足，易疲乏"),
        ("yangxu", "阳虚质", "阳气不足，畏寒怕冷"),
        ("yinxu", "阴虚质", "阴液亏少，口燥咽干"),
        ("tanshi", "痰湿质", "痰湿凝聚，体形肥胖"),
        ("shire", "湿热质", "湿热内蕴，面垢油光"),
        ("xueyu", "血瘀质", "血行不畅，肤色晦暗"),
        ("qiyu", "气郁质", "气机郁滞，情志抑郁"),
        ("tebing", "特禀质", "先天特殊，易过敏"),
    ]

    for ctype, cname, cdesc in constitutions:
        sid = f"constitution_{ctype}_guide"
        skills[sid] = _skill(
            sid, "constitution", f"{cname}调养指南",
            f"{cname}的完整调养方案：{cdesc}。涵盖饮食、运动、起居、茶饮、穴位",
            priority="P1", context=["constitution", "season", "life_stage"],
            tags=["体质", cname, "调养"],
            model="glm-4.6", max_tokens=2048,
            deps=["analyze_constitution"],
        )

    # 核心体质 Skill
    skills["analyze_constitution"] = _skill(
        "analyze_constitution", "constitution", "体质分析",
        "根据用户描述的症状和生活习惯，分析中医体质类型（九种体质）",
        priority="P0", context=["constitution"],
        tags=["体质", "分析", "中医"], model="kimi-k2-thinking", max_tokens=2048,
    )
    skills["calculate_constitution_score"] = _skill(
        "calculate_constitution_score", "constitution", "体质评分",
        "计算用户各体质维度的得分，给出体质倾向排名",
        priority="P1", context=["constitution"],
        tags=["体质", "评分", "量化"], model="kimi-k2-thinking", max_tokens=2048,
        is_premium=True, cooldown=168,
    )
    skills["detect_constitution_shift"] = _skill(
        "detect_constitution_shift", "constitution", "体质变化检测",
        "对比历史体质数据，检测体质变化趋势",
        priority="P1", context=["constitution"],
        tags=["体质", "变化", "趋势"], model="glm-4.6", max_tokens=1024,
    )
    skills["generate_constitution_summary"] = _skill(
        "generate_constitution_summary", "constitution", "体质总览",
        "生成用户体质综合总览报告",
        priority="P0", context=["constitution", "season"],
        tags=["体质", "总览"], model="glm-4.6", max_tokens=2048,
    )
    skills["generate_constitution_diet"] = _skill(
        "generate_constitution_diet", "constitution", "体质食疗方案",
        "根据体质类型推荐适合和应避免的食物",
        priority="P0", context=["constitution", "season", "diet"],
        tags=["体质", "饮食", "食疗"], model="glm-4.6", max_tokens=2048,
    )
    skills["generate_constitution_tea"] = _skill(
        "generate_constitution_tea", "constitution", "体质茶饮推荐",
        "根据体质类型推荐养生茶饮",
        priority="P1", context=["constitution", "season"],
        tags=["体质", "茶饮"], model="glm-4.6", max_tokens=1024,
    )
    skills["generate_constitution_exercise"] = _skill(
        "generate_constitution_exercise", "constitution", "体质运动方案",
        "根据体质类型推荐适合的运动方式",
        priority="P1", context=["constitution", "life_stage", "exercise"],
        tags=["体质", "运动"], model="glm-4.6", max_tokens=1024,
    )
    skills["generate_constitution_sleep"] = _skill(
        "generate_constitution_sleep", "constitution", "体质睡眠建议",
        "根据体质类型调整睡眠习惯",
        priority="P1", context=["constitution", "sleep"],
        tags=["体质", "睡眠"], model="glm-4.6", max_tokens=1024,
    )
    skills["generate_constitution_emotion"] = _skill(
        "generate_constitution_emotion", "constitution", "体质情志调养",
        "根据体质类型提供情志调节建议",
        priority="P1", context=["constitution", "emotion"],
        tags=["体质", "情绪"], model="glm-4.6", max_tokens=1024,
    )
    skills["generate_constitution_avoid_list"] = _skill(
        "generate_constitution_avoid_list", "constitution", "体质禁忌清单",
        "根据体质类型列出应避免的食物、行为和环境",
        priority="P1", context=["constitution"],
        tags=["体质", "禁忌"], model="deepseek-v3.2", max_tokens=1024,
    )
    skills["generate_constitution_week_plan"] = _skill(
        "generate_constitution_week_plan", "constitution", "体质周调养计划",
        "根据体质生成7天调养计划",
        priority="P1", context=["constitution", "season", "life_stage"],
        tags=["体质", "计划", "7天"], model="qwen3-235b", max_tokens=4096,
        is_premium=True, cooldown=168,
    )
    skills["generate_constitution_daily_adjustment"] = _skill(
        "generate_constitution_daily_adjustment", "constitution", "体质日常调理",
        "根据体质提供每日调理小建议",
        priority="P1", context=["constitution", "season"],
        tags=["体质", "日常"], model="deepseek-v3.2", max_tokens=512,
        cooldown=24,
    )
    skills["generate_constitution_warning"] = _skill(
        "generate_constitution_warning", "constitution", "体质预警提示",
        "根据当前节气和体质，发出需要特别注意的健康预警",
        priority="P1", context=["constitution", "season"],
        tags=["体质", "预警"], model="glm-4.6", max_tokens=512,
    )
    skills["generate_constitution_morning_routine"] = _skill(
        "generate_constitution_morning_routine", "constitution", "体质晨间养生",
        "根据体质生成晨间养生流程",
        priority="P2", context=["constitution"],
        tags=["体质", "早晨"], model="deepseek-v3.2", max_tokens=512,
    )
    skills["generate_constitution_evening_routine"] = _skill(
        "generate_constitution_evening_routine", "constitution", "体质晚间养生",
        "根据体质生成晚间养生流程",
        priority="P2", context=["constitution", "sleep"],
        tags=["体质", "晚间"], model="deepseek-v3.2", max_tokens=512,
    )
    skills["generate_constitution_change_trend"] = _skill(
        "generate_constitution_change_trend", "constitution", "体质变化趋势分析",
        "分析用户体质随时间的变化趋势",
        priority="P2", context=["constitution"],
        tags=["体质", "趋势", "分析"], model="kimi-k2-thinking", max_tokens=2048,
        is_premium=True, cooldown=720,
    )
    skills["generate_constitution_cross_season_adjustment"] = _skill(
        "generate_constitution_cross_season_adjustment", "constitution", "跨季节体质调整",
        "季节交替时体质调养的过渡方案",
        priority="P2", context=["constitution", "season"],
        tags=["体质", "季节", "调整"], model="glm-4.6", max_tokens=1024,
    )

    # 额外的体质细分 Skill（凑满30）
    extra_constitution_skills = [
        ("constitution_seasonal_adjust", "体质四季调养", "根据四季变化调整体质养生方案", "P2", ["constitution", "season"], ["体质", "四季"]),
        ("constitution_acupoint_map", "体质穴位图鉴", "根据体质类型推荐穴位保健方案", "P1", ["constitution"], ["体质", "穴位"]),
        ("constitution_recipe_collection", "体质食谱集", "根据体质收集整理适合的养生食谱", "P1", ["constitution", "season", "diet"], ["体质", "食谱"]),
        ("constitution_medicine_food", "体质药食同源", "体质对应的药食同源食材推荐", "P2", ["constitution"], ["体质", "药食同源"]),
        ("constitution_office_adapt", "体质办公室调理", "办公室场景的体质调理方案", "P2", ["constitution"], ["体质", "办公室"]),
    ]
    for sid, name, desc, pri, ctx, tags in extra_constitution_skills:
        skills[sid] = _skill(sid, "constitution", name, desc, pri, ctx, tags)

    return skills


# ==================== 3. Diet 食疗 Skills (40) ====================

def _build_diet_skills() -> Dict[str, SkillDefinition]:
    """构建食疗分类的所有 Skill"""
    skills: Dict[str, SkillDefinition] = {}

    # 核心计划类
    skills["generate_meal_plan_daily"] = _skill(
        "generate_meal_plan_daily", "diet", "每日膳食计划",
        "生成今日三餐加餐的完整膳食计划",
        priority="P0", context=["constitution", "season", "diet", "life_stage"],
        tags=["食疗", "每日", "三餐"], model="glm-4.6", max_tokens=2048,
    )
    skills["generate_meal_plan_weekly"] = _skill(
        "generate_meal_plan_weekly", "diet", "周膳食计划",
        "生成7天膳食计划，含早中晚加餐",
        priority="P1", context=["constitution", "season", "diet"],
        tags=["食疗", "周计划", "7天"], model="qwen3-235b", max_tokens=4096,
        is_premium=True, cooldown=168,
    )
    skills["generate_meal_plan_constitution"] = _skill(
        "generate_meal_plan_constitution", "diet", "体质膳食计划",
        "根据体质类型定制膳食计划",
        priority="P0", context=["constitution", "season", "diet"],
        tags=["食疗", "体质", "定制"], model="glm-4.6", max_tokens=2048,
        deps=["analyze_constitution"],
    )
    skills["generate_meal_plan_season"] = _skill(
        "generate_meal_plan_season", "diet", "当季膳食计划",
        "根据当前季节和节气推荐应季膳食",
        priority="P1", context=["season", "constitution", "diet"],
        tags=["食疗", "当季", "节气"], model="glm-4.6", max_tokens=2048,
    )
    skills["generate_meal_plan_sleep_support"] = _skill(
        "generate_meal_plan_sleep_support", "diet", "助眠膳食计划",
        "针对睡眠问题推荐助眠食物和食谱",
        priority="P1", context=["sleep", "constitution", "diet"],
        tags=["食疗", "助眠", "睡眠"], model="glm-4.6", max_tokens=1024,
    )
    skills["generate_meal_plan_energy_boost"] = _skill(
        "generate_meal_plan_energy_boost", "diet", "补气膳食计划",
        "针对疲劳乏力推荐补气提神的膳食",
        priority="P1", context=["constitution", "diet"],
        tags=["食疗", "补气", "提神"], model="glm-4.6", max_tokens=1024,
    )

    # 食谱生成类
    skills["generate_recipe"] = _skill(
        "generate_recipe", "diet", "养生食谱生成",
        "根据食材和功效需求生成详细食谱",
        priority="P0", context=["constitution", "season", "diet"],
        tags=["食疗", "食谱", "生成"], model="glm-4.6", max_tokens=1024,
    )
    skills["generate_quick_recipe"] = _skill(
        "generate_quick_recipe", "diet", "快手养生食谱",
        "10分钟内可完成的简易养生食谱",
        priority="P1", context=["constitution", "diet"],
        tags=["食疗", "快手", "简单"], model="deepseek-v3.2", max_tokens=512,
    )
    skills["generate_family_recipe"] = _skill(
        "generate_family_recipe", "diet", "家庭养生食谱",
        "适合全家人的养生食谱",
        priority="P1", context=["family", "season", "diet"],
        tags=["食疗", "家庭"], model="glm-4.6", max_tokens=1024,
    )
    skills["generate_office_recipe"] = _skill(
        "generate_office_recipe", "diet", "办公室养生食谱",
        "适合办公室准备或外卖选择的养生食谱",
        priority="P2", context=["diet"], tags=["食疗", "办公室"],
        model="deepseek-v3.2", max_tokens=512,
    )

    # 食物分析类
    skills["suggest_food_combination"] = _skill(
        "suggest_food_combination", "diet", "食材搭配建议",
        "推荐合理的食材搭配方案",
        priority="P1", context=["constitution", "diet"],
        tags=["食疗", "搭配"], model="glm-4.6", max_tokens=1024,
    )
    skills["detect_food_conflict"] = _skill(
        "detect_food_conflict", "diet", "食物相克检测",
        "检测食材之间是否存在相克或不宜同食的情况",
        priority="P1", context=["diet"], tags=["食疗", "相克", "安全"],
        model="deepseek-v3.2", max_tokens=512,
    )
    skills["detect_food_suitability"] = _skill(
        "detect_food_suitability", "diet", "食物适宜性分析",
        "根据体质和季节分析某食材是否适合当前食用",
        priority="P1", context=["constitution", "season", "diet"],
        tags=["食疗", "适宜", "分析"], model="glm-4.6", max_tokens=512,
    )
    skills["generate_shopping_list"] = _skill(
        "generate_shopping_list", "diet", "养生食材采购清单",
        "根据膳食计划生成采购清单",
        priority="P2", context=["diet", "season"],
        tags=["食疗", "采购"], model="deepseek-v3.2", max_tokens=512,
    )

    # 特殊场景食谱
    scenario_skills = [
        ("generate_diet_light_version", "轻食养生方案", "低热量高营养的轻食方案", "P2", ["diet"]),
        ("generate_diet_strict_version", "严格调理方案", "严格忌口的调理膳食方案", "P2", ["constitution", "diet"]),
        ("generate_diet_festival_version", "节庆养生食谱", "传统节日养生食谱推荐", "P2", ["season", "diet"]),
        ("generate_diet_travel_version", "出行养生饮食", "旅行途中的养生饮食建议", "P2", ["diet"]),
        ("generate_diet_breakfast", "养生早餐推荐", "根据体质和季节推荐养生早餐", "P1", ["constitution", "season", "diet"]),
        ("generate_diet_lunch", "养生午餐推荐", "根据体质和场景推荐养生午餐", "P1", ["constitution", "diet"]),
        ("generate_diet_dinner", "养生晚餐推荐", "晚餐宜清淡，推荐养生晚餐方案", "P1", ["constitution", "diet"]),
        ("generate_diet_snack", "养生加餐推荐", "两餐之间的健康加餐推荐", "P2", ["constitution", "diet"]),
        ("generate_diet_soup", "养生汤品推荐", "根据体质和季节推荐养生汤品", "P1", ["constitution", "season", "diet"]),
        ("generate_diet_congee", "养生粥品推荐", "根据体质和季节推荐养生粥品", "P1", ["constitution", "season", "diet"]),
        ("generate_diet_seasonal_ingredients", "当季食材推荐", "当前季节应季食材推荐及营养价值", "P1", ["season", "diet"]),
        ("generate_diet_nutrition_balance", "营养均衡分析", "分析膳食计划的营养均衡程度", "P2", ["constitution", "diet"]),
        ("generate_diet_allergy_friendly", "过敏体质食谱", "适合过敏体质的安全食谱", "P2", ["constitution", "diet"]),
        ("generate_diet_warming", "温补膳食方案", "适合阳虚畏寒人群的温补方案", "P1", ["constitution", "season", "diet"]),
        ("generate_diet_cooling", "清热膳食方案", "适合阴虚内热人群的清热方案", "P1", ["constitution", "season", "diet"]),
        ("generate_diet_detox", "排毒清体方案", "帮助身体排毒的膳食方案", "P2", ["diet"]),
        ("generate_diet_immunity_boost", "免疫力提升食谱", "增强免疫力的膳食推荐", "P1", ["constitution", "diet"]),
        ("generate_diet_digestion_aid", "健脾胃食谱", "健脾养胃助消化的食谱推荐", "P1", ["constitution", "diet"]),
        ("generate_diet_follow_up", "食疗效果跟进", "跟踪食疗方案执行效果并调整", "P2", ["constitution", "diet"]),
    ]
    for sid, name, desc, pri, ctx in scenario_skills:
        skills[sid] = _skill(sid, "diet", name, desc, pri, ctx, ["食疗", name[-3:]])

    return skills


# ==================== 4. Tea 茶饮 Skills (25) ====================

def _build_tea_skills() -> Dict[str, SkillDefinition]:
    """构建茶饮分类的所有 Skill"""
    skills: Dict[str, SkillDefinition] = {}

    core_tea_skills = [
        ("generate_tea_recommendation", "茶饮智能推荐", "综合体质、季节、场景推荐茶饮", "P0", ["constitution", "season"], "茶饮", "推荐"),
        ("generate_tea_recipe", "茶饮配方生成", "根据功效需求生成茶饮配方", "P0", ["constitution", "season"], "茶饮", "配方"),
        ("generate_tea_constitution", "体质茶饮方案", "根据九种体质推荐茶饮", "P0", ["constitution", "season"], "茶饮", "体质"),
        ("generate_tea_season", "四季茶饮方案", "春夏秋冬各季推荐茶饮", "P1", ["season"], "茶饮", "四季"),
        ("generate_tea_sleep", "安神助眠茶饮", "帮助入眠的茶饮推荐", "P1", ["sleep", "constitution"], "茶饮", "助眠"),
        ("generate_tea_relax", "放松解压茶饮", "舒缓压力放松身心的茶饮", "P1", ["emotion"], "茶饮", "放松"),
        ("generate_tea_energy", "提神醒脑茶饮", "补充精力提升专注的茶饮", "P1", ["constitution"], "茶饮", "提神"),
        ("generate_tea_detox", "排毒清体茶饮", "清热排毒的茶饮推荐", "P2", ["constitution", "season"], "茶饮", "排毒"),
        ("generate_tea_morning", "晨间养生茶饮", "适合早晨饮用的茶饮", "P1", ["constitution", "season"], "茶饮", "早晨"),
        ("generate_tea_evening", "晚间养生茶饮", "适合晚间饮用的温和茶饮", "P1", ["constitution", "sleep"], "茶饮", "晚间"),
        ("generate_tea_office", "办公室养生茶饮", "适合办公场景的便捷茶饮", "P2", ["constitution"], "茶饮", "办公室"),
        ("generate_tea_family", "家庭养生茶饮", "适合全家的茶饮推荐", "P1", ["family", "season"], "茶饮", "家庭"),
        ("generate_tea_follow_up", "茶饮效果跟进", "跟踪茶饮养生效果并调整", "P2", ["constitution"], "茶饮", "跟进"),
        ("generate_tea_summer_cooling", "夏日消暑茶饮", "夏季清热消暑的茶饮", "P2", ["season"], "茶饮", "消暑"),
        ("generate_tea_winter_warming", "冬日暖身茶饮", "冬季温补暖身的茶饮", "P2", ["season"], "茶饮", "暖身"),
        ("generate_tea_eye_care", "护眼明目茶饮", "保护视力缓解眼疲劳的茶饮", "P2", [], "茶饮", "护眼"),
        ("generate_tea_beauty", "美容养颜茶饮", "滋养肌肤美容养颜的茶饮", "P2", ["constitution"], "茶饮", "美容"),
        ("generate_tea_weight", "瘦身纤体茶饮", "辅助体重管理的茶饮", "P2", ["constitution"], "茶饮", "瘦身"),
        ("generate_tea_anti_aging", "抗衰延年茶饮", "延缓衰老的茶饮推荐", "P2", ["life_stage"], "茶饮", "抗衰"),
        ("generate_tea_cold_remedy", "风寒感冒茶饮", "风寒感冒初期的茶饮调理", "P2", [], "茶饮", "感冒"),
        ("generate_tea_spring_liver", "春季养肝茶饮", "春季养肝护肝的茶饮推荐", "P1", ["season"], "茶饮", "养肝"),
        ("generate_tea_women_health", "女性养生茶饮", "调理女性气血的茶饮", "P2", ["constitution"], "茶饮", "女性"),
        ("generate_tea_elder_health", "老年养生茶饮", "适合老年人的温和茶饮", "P2", ["life_stage"], "茶饮", "老年"),
        ("generate_tea_child_safe", "儿童安全茶饮", "适合儿童的安全茶饮推荐", "P2", ["life_stage"], "茶饮", "儿童"),
        ("generate_tea_herbal_basic", "常见中药茶介绍", "介绍常见养生中药茶的泡法和功效", "P2", [], "茶饮", "中药"),
    ]
    for sid, name, desc, pri, ctx, *tags in core_tea_skills:
        skills[sid] = _skill(sid, "tea", name, desc, pri, ctx, tags[0])

    return skills


# ==================== 5. Acupoint 穴位 Skills (25) ====================

def _build_acupoint_skills() -> Dict[str, SkillDefinition]:
    """构建穴位分类的所有 Skill"""
    skills: Dict[str, SkillDefinition] = {}

    acupoint_skills = [
        ("recommend_acupoint", "穴位推荐", "根据身体问题推荐适合按摩的穴位", "P0", ["constitution"], "穴位", "推荐"),
        ("explain_acupoint", "穴位详解", "详细介绍穴位的定位、功效和按摩方法", "P0", [], "穴位", "详解"),
        ("generate_acupoint_plan", "穴位保健计划", "生成系统的穴位按摩计划", "P1", ["constitution", "life_stage"], "穴位", "计划"),
        ("generate_acupoint_daily", "每日穴位保健", "每日穴位按摩推荐", "P1", ["constitution", "season"], "穴位", "每日"),
        ("generate_acupoint_sleep", "助眠穴位推荐", "帮助改善睡眠的穴位按摩方案", "P1", ["sleep"], "穴位", "助眠"),
        ("generate_acupoint_stress", "减压穴位推荐", "缓解压力焦虑的穴位按摩方案", "P1", ["emotion"], "穴位", "减压"),
        ("generate_acupoint_energy", "补气穴位推荐", "补充元气缓解疲劳的穴位", "P1", ["constitution"], "穴位", "补气"),
        ("generate_acupoint_digest", "健脾助消化穴位", "调理脾胃促进消化的穴位", "P1", ["constitution"], "穴位", "脾胃"),
        ("generate_acupoint_constitution", "体质穴位方案", "根据体质推荐穴位保健方案", "P1", ["constitution"], "穴位", "体质"),
        ("generate_acupoint_family", "家庭穴位保健", "适合全家人的基础穴位保健", "P1", ["family", "life_stage"], "穴位", "家庭"),
        ("generate_acupoint_follow_up", "穴位保健跟进", "跟踪穴位按摩效果并调整方案", "P2", ["constitution"], "穴位", "跟进"),
        ("generate_acupoint_eye", "护眼穴位推荐", "缓解眼疲劳保护视力的穴位", "P2", [], "穴位", "护眼"),
        ("generate_acupoint_headache", "头痛缓解穴位", "缓解头痛的穴位按摩方案", "P2", [], "穴位", "头痛"),
        ("generate_acupoint_neck", "颈椎保健穴位", "保护颈椎缓解肩颈不适的穴位", "P2", [], "穴位", "颈椎"),
        ("generate_acupoint_back", "腰部保健穴位", "保护腰椎缓解腰痛的穴位", "P2", [], "穴位", "腰痛"),
        ("generate_acupoint_cold_prevention", "防感冒穴位", "增强免疫力预防感冒的穴位", "P2", ["season"], "穴位", "感冒"),
        ("generate_acupoint_menstrual", "经期调理穴位", "缓解经期不适的穴位按摩", "P2", [], "穴位", "经期"),
        ("generate_acupoint_seasonal", "季节穴位调整", "根据季节推荐适合的穴位按摩", "P2", ["season"], "穴位", "四季"),
        ("acupoint_zusanli", "足三里详解", "足三里穴的详细介绍和按摩方法", "P1", [], "穴位", "足三里"),
        ("acupoint_hegu", "合谷穴详解", "合谷穴的详细介绍和按摩方法", "P1", [], "穴位", "合谷"),
        ("acupoint_taicang", "太冲穴详解", "太冲穴的详细介绍和按摩方法", "P1", [], "穴位", "太冲"),
        ("acupoint_sanyinjiao", "三阴交详解", "三阴交穴的详细介绍和按摩方法", "P1", [], "穴位", "三阴交"),
        ("acupoint_neiguan", "内关穴详解", "内关穴的详细介绍和按摩方法", "P1", [], "穴位", "内关"),
        ("acupoint_yongquan", "涌泉穴详解", "涌泉穴的详细介绍和按摩方法", "P1", [], "穴位", "涌泉"),
        ("acupoint_fengchi", "风池穴详解", "风池穴的详细介绍和按摩方法", "P1", [], "穴位", "风池"),
    ]
    for sid, name, desc, pri, ctx, *tags in acupoint_skills:
        skills[sid] = _skill(sid, "acupoint", name, desc, pri, ctx, tags[0])

    return skills


# ==================== 6. Exercise 运动 Skills (30) ====================

def _build_exercise_skills() -> Dict[str, SkillDefinition]:
    """构建运动分类的所有 Skill"""
    skills: Dict[str, SkillDefinition] = {}

    exercise_skills = [
        ("generate_exercise_plan", "运动计划生成", "根据体质和目标生成运动计划", "P0", ["constitution", "life_stage", "exercise"]),
        ("generate_light_exercise", "轻度运动推荐", "适合日常的轻度养生运动", "P1", ["constitution", "life_stage"]),
        ("generate_office_exercise", "办公室微运动", "办公室可做的简短运动", "P0", []),
        ("generate_morning_exercise", "晨间运动方案", "适合早晨的运动方案", "P1", ["constitution", "season"]),
        ("generate_evening_exercise", "晚间运动方案", "适合晚间放松的运动方案", "P1", ["constitution", "sleep"]),
        ("generate_sleep_exercise", "助眠运动推荐", "帮助改善睡眠的睡前运动", "P1", ["sleep", "constitution"]),
        ("generate_constitution_exercise", "体质运动方案", "根据体质推荐运动方式", "P1", ["constitution", "life_stage"]),
        ("generate_season_exercise", "四季运动方案", "春夏秋冬各季适合的运动", "P1", ["season", "life_stage"]),
        ("generate_8_duan_jin", "八段锦教程", "八段锦完整动作讲解", "P0", ["life_stage"]),
        ("generate_stretching", "拉伸运动指导", "全身拉伸运动指导", "P1", []),
        ("generate_breathing", "呼吸练习指导", "养生呼吸练习方法", "P1", ["emotion"]),
        ("generate_exercise_follow_up", "运动效果跟进", "跟踪运动效果并调整方案", "P2", ["exercise"]),
        ("generate_exercise_micro_action", "微运动推荐", "1-3分钟可完成的小运动", "P0", []),
        ("generate_taiji_guide", "太极拳入门指导", "太极拳基本动作指导", "P1", ["life_stage"]),
        ("generate_baduanjin_session", "八段锦今日练习", "今日八段锦练习安排", "P1", ["life_stage"]),
        ("generate_yoga_gentle", "温和瑜伽推荐", "适合养生调理的温和瑜伽", "P1", ["constitution", "life_stage"]),
        ("generate_walking_plan", "散步养生方案", "科学散步的方法和时间安排", "P2", ["life_stage"]),
        ("generate_neck_exercise", "颈部运动方案", "缓解颈椎不适的运动方案", "P1", []),
        ("generate_eye_exercise", "眼保健操指导", "保护视力的眼保健操", "P1", []),
        ("generate_outdoor_exercise", "户外运动推荐", "适合当前季节的户外运动", "P2", ["season", "life_stage"]),
        ("generate_indoor_exercise", "室内运动推荐", "居家可做的养生运动", "P2", []),
        ("generate_exercise_warmup", "运动前热身指导", "运动前的热身动作指导", "P2", []),
        ("generate_exercise_cooldown", "运动后放松指导", "运动后的拉伸放松指导", "P2", []),
        ("generate_exercise_injury_prevention", "运动损伤预防", "常见运动损伤的预防方法", "P2", ["life_stage"]),
        ("generate_exercise_weather_adapt", "天气运动调整", "根据天气情况调整运动计划", "P2", ["season"]),
        ("generate_exercise_weight_manage", "体重管理运动", "辅助体重管理的运动方案", "P2", ["constitution"]),
        ("generate_exercise_elder_safe", "老年安全运动", "适合老年人的安全运动方案", "P1", ["life_stage"]),
        ("generate_exercise_child_fun", "儿童趣味运动", "适合儿童的健康运动游戏", "P2", ["life_stage"]),
        ("generate_exercise_stress_relief", "减压运动推荐", "释放压力的运动方案", "P1", ["emotion"]),
        ("generate_exercise_posture_correct", "体态矫正运动", "改善不良体态的运动方案", "P2", []),
    ]
    for sid, name, *rest in exercise_skills:
        desc = rest[0]
        pri = rest[1] if len(rest) > 1 else "P1"
        ctx = rest[2] if len(rest) > 2 else []
        skills[sid] = _skill(sid, "exercise", name, desc, pri, ctx, ["运动", name[-3:]])

    return skills


# ==================== 7. Sleep 睡眠 Skills (30) ====================

def _build_sleep_skills() -> Dict[str, SkillDefinition]:
    """构建睡眠分类的所有 Skill"""
    skills: Dict[str, SkillDefinition] = {}

    sleep_skills = [
        ("analyze_sleep_issue", "睡眠问题分析", "分析用户睡眠问题的原因和类型", "P0", ["sleep"]),
        ("generate_sleep_plan", "睡眠改善计划", "生成系统的睡眠改善计划", "P0", ["sleep", "constitution"]),
        ("generate_sleep_routine", "睡眠作息方案", "制定规律的睡眠作息时间表", "P1", ["sleep", "life_stage"]),
        ("generate_sleep_preparation", "睡前准备流程", "完整的睡前准备步骤建议", "P1", ["sleep"]),
        ("generate_sleep_environment", "睡眠环境优化", "优化睡眠环境的建议", "P1", ["sleep"]),
        ("generate_sleep_breathing", "助眠呼吸法", "帮助入眠的呼吸练习方法", "P1", ["sleep", "emotion"]),
        ("generate_sleep_audio_prompt", "睡眠音频引导", "生成助眠音频引导文案", "P2", ["sleep"]),
        ("generate_sleep_follow_up", "睡眠改善跟进", "跟踪睡眠改善效果", "P2", ["sleep"]),
        ("generate_sleep_quick_fix", "快速入睡技巧", "无法入睡时的快速解决方法", "P0", ["sleep"]),
        ("generate_sleep_long_term_plan", "长期睡眠调理", "30天长期睡眠调理方案", "P1", ["sleep", "constitution"], True, 720),
        ("generate_sleep_diet", "助眠饮食建议", "有助于睡眠的食物和饮品", "P1", ["sleep", "diet"]),
        ("generate_sleep_herbal", "助眠草本推荐", "有助于睡眠的草本植物", "P2", ["sleep"]),
        ("generate_sleep_meditation", "睡前冥想引导", "睡前冥想放松引导", "P1", ["sleep", "emotion"]),
        ("generate_sleep_acupoint", "助眠穴位按摩", "帮助入睡的穴位按摩方案", "P1", ["sleep"]),
        ("generate_sleep_posure", "睡眠姿势建议", "最佳的睡眠姿势建议", "P2", ["sleep", "life_stage"]),
        ("generate_sleep_nap_guide", "午休指导", "科学的午休方法和时间", "P2", ["sleep", "life_stage"]),
        ("generate_sleep_jetlag", "时差调整方案", "跨时区出行的睡眠调整", "P2", ["sleep"]),
        ("generate_sleep_season_adjust", "四季睡眠调整", "不同季节的睡眠时间调整", "P1", ["sleep", "season"]),
        ("generate_sleep_elder_care", "老年睡眠关怀", "老年人睡眠问题关怀方案", "P2", ["sleep", "life_stage"]),
        ("generate_sleep_child_care", "儿童睡眠指导", "儿童健康睡眠习惯培养", "P2", ["sleep", "life_stage"]),
        ("generate_sleep_tcm_understanding", "中医睡眠观", "中医对睡眠的理解和调理", "P1", ["sleep", "constitution"]),
        ("generate_sleep_stress_relation", "压力与睡眠", "分析压力对睡眠的影响和应对", "P1", ["sleep", "emotion"]),
        ("generate_sleep_morning_fresh", "晨起清爽方案", "提升早晨精神状态的方案", "P1", ["sleep"]),
        ("generate_sleep_late_night", "熬夜后恢复", "熬夜后的身体恢复方案", "P1", ["sleep"]),
        ("generate_sleep_dream_analysis", "睡眠梦境解读", "中医视角的常见梦境解读", "P2", ["sleep"]),
        ("generate_sleep_snoring_help", "打鼾缓解建议", "减轻打鼾的生活调理建议", "P2", ["sleep"]),
        ("generate_sleep_waking_up", "早醒调理方案", "改善早醒问题的调理方案", "P1", ["sleep"]),
        ("generate_sleep_midnight", "半夜醒来调理", "改善半夜醒来的调理方案", "P1", ["sleep"]),
        ("generate_sleep_tech_hygiene", "睡前数字卫生", "减少电子设备对睡眠的影响", "P2", ["sleep"]),
        ("generate_sleep_progressive_relax", "渐进式肌肉放松", "睡前渐进式肌肉放松练习", "P1", ["sleep", "emotion"]),
    ]
    for sid, name, *rest in sleep_skills:
        desc = rest[0]
        pri = rest[1] if len(rest) > 1 else "P1"
        ctx = rest[2] if len(rest) > 2 else []
        premium = rest[3] if len(rest) > 3 else False
        cooldown = rest[4] if len(rest) > 4 else 0
        skills[sid] = _skill(
            sid, "sleep", name, desc, pri, ctx, ["睡眠", name[-3:]],
            is_premium=premium, cooldown=cooldown,
        )

    return skills


# ==================== 8. Emotion 情绪 Skills (30) ====================

def _build_emotion_skills() -> Dict[str, SkillDefinition]:
    """构建情绪分类的所有 Skill"""
    skills: Dict[str, SkillDefinition] = {}

    emotion_skills = [
        ("detect_emotion", "情绪识别", "识别用户当前情绪状态", "P0", ["emotion"]),
        ("detect_emotion_intensity", "情绪强度评估", "评估用户情绪的强度等级", "P1", ["emotion"]),
        ("generate_empathy_response", "共情回应生成", "生成温暖共情的回应", "P0", ["emotion"]),
        ("generate_emotion_support", "情绪支持方案", "提供系统的情绪支持方案", "P0", ["emotion"]),
        ("generate_emotion_release", "情绪释放方法", "健康释放负面情绪的方法", "P1", ["emotion"]),
        ("generate_emotion_breathing", "情绪呼吸法", "调节情绪的呼吸练习", "P1", ["emotion"]),
        ("generate_emotion_reframe", "认知重构引导", "帮助换个角度看待问题", "P1", ["emotion"]),
        ("generate_emotion_follow_up", "情绪状态跟进", "跟踪用户情绪变化", "P2", ["emotion"]),
        ("generate_emotion_journal_prompt", "情绪日记引导", "引导用户写情绪日记", "P2", ["emotion"]),
        ("generate_emotion_grounding", "接地练习引导", "焦虑时的接地练习方法", "P1", ["emotion"]),
        ("generate_emotion_micro_action", "情绪微行动", "1分钟内可做的情绪调节小方法", "P0", ["emotion"]),
        ("generate_emotion_morning_intention", "晨间情绪设定", "早晨设定积极情绪意图", "P2", ["emotion"]),
        ("generate_emotion_evening_reflection", "晚间情绪回顾", "晚间回顾一天的情绪变化", "P2", ["emotion"]),
        ("generate_emotion_stress_manage", "压力管理方案", "系统的压力管理方法", "P1", ["emotion"]),
        ("generate_emotion_anxiety_relief", "焦虑缓解方案", "缓解焦虑情绪的方法", "P1", ["emotion"]),
        ("generate_emotion_sadness_support", "悲伤陪伴方案", "面对悲伤时的温暖陪伴", "P1", ["emotion"]),
        ("generate_emotion_anger_manage", "愤怒管理方案", "管理愤怒情绪的方法", "P1", ["emotion"]),
        ("generate_emotion_loneliness_comfort", "孤独感抚慰", "缓解孤独感的方法", "P1", ["emotion"]),
        ("generate_emotion_gratitude", "感恩练习引导", "培养感恩心态的练习", "P2", ["emotion"]),
        ("generate_emotion_self_compassion", "自我关怀引导", "培养自我关怀的练习", "P1", ["emotion"]),
        ("generate_emotion_seasonal_mood", "季节情绪调适", "季节变化引起的情绪调整", "P2", ["emotion", "season"]),
        ("generate_emotion_workplace", "职场情绪管理", "工作场景的情绪管理", "P2", ["emotion"]),
        ("generate_emotion_relationship", "关系情绪支持", "人际关系中的情绪支持", "P2", ["emotion"]),
        ("generate_emotion_body_scan", "身体扫描冥想", "通过身体扫描调节情绪", "P1", ["emotion"]),
        ("generate_emotion_positive_affirmation", "积极自我肯定", "生成积极自我肯定的语句", "P2", ["emotion"]),
        ("generate_emotion_worry_manage", "担忧管理方法", "管理过度担忧的思维方法", "P1", ["emotion"]),
        ("generate_emotion_crisis_resources", "危机资源提供", "提供心理健康危机资源", "P0", ["emotion"]),
        ("generate_emotion_daily_checkin", "每日情绪签到", "引导用户每日记录情绪", "P1", ["emotion"]),
        ("generate_emotion_resilience", "心理韧性培养", "提升心理韧性的方法", "P1", ["emotion"]),
        ("generate_emotion_mindful_pause", "正念暂停引导", "随时可用的正念暂停练习", "P1", ["emotion"]),
    ]
    for sid, name, *rest in emotion_skills:
        desc = rest[0]
        pri = rest[1] if len(rest) > 1 else "P1"
        ctx = rest[2] if len(rest) > 2 else []
        skills[sid] = _skill(sid, "emotion", name, desc, pri, ctx, ["情绪", name[-3:]])

    return skills


# ==================== 9. Lifestyle 生活 Skills (25) ====================

def _build_lifestyle_skills() -> Dict[str, SkillDefinition]:
    """构建生活分类的所有 Skill"""
    skills: Dict[str, SkillDefinition] = {}

    lifestyle_skills = [
        ("generate_daily_rhythm", "每日作息规划", "生成科学合理的每日作息时间表", "P0", ["life_stage", "sleep", "exercise"]),
        ("generate_lifestyle_plan", "生活方式改善计划", "综合生活方式改善计划", "P1", ["constitution", "life_stage"]),
        ("generate_habit_plan", "习惯养成计划", "帮助养成健康习惯的21天计划", "P1", ["constitution"]),
        ("generate_micro_habit", "微习惯推荐", "1-5分钟可完成的小习惯", "P0", []),
        ("generate_water_plan", "饮水计划", "科学的每日饮水时间和量", "P2", ["constitution", "season"]),
        ("generate_posture_fix", "体态矫正指导", "改善不良体态的指导", "P2", []),
        ("generate_office_health", "办公室健康指南", "办公室场景的全面健康建议", "P1", []),
        ("generate_lifestyle_follow_up", "生活方式跟进", "跟踪生活方式改善进度", "P2", ["constitution"]),
        ("generate_screen_time_plan", "屏幕时间管理", "合理管理电子设备使用时间", "P2", []),
        ("generate_bath_plan", "泡澡养生方案", "根据体质和季节的泡澡养生方案", "P2", ["constitution", "season"]),
        ("generate_foot_soak_recipe", "足浴配方推荐", "养生足浴的配方和方法", "P1", ["constitution", "season"]),
        ("generate_digital_detox", "数字断舍离指导", "减少数字产品依赖的方法", "P2", []),
        ("generate_morning_routine", "晨间养生流程", "完整的晨间养生流程", "P1", ["constitution", "season"]),
        ("generate_evening_routine", "晚间养生流程", "完整的晚间养生流程", "P1", ["constitution", "sleep"]),
        ("generate_weekend_plan", "周末养生计划", "周末的养生放松计划", "P2", ["life_stage"]),
        ("generate_clothing_advice", "穿衣养生建议", "根据节气和体质的穿衣建议", "P2", ["season", "constitution"]),
        ("generate_household_health", "居家环境健康", "家居环境的健康优化建议", "P2", []),
        ("generate_social_health", "社交健康建议", "健康社交和人际关系的建议", "P2", ["emotion"]),
        ("generate_reading_health", "养生阅读推荐", "推荐健康养生相关书籍", "P2", []),
        ("generate_music_therapy", "音乐养生推荐", "不同场景的养生音乐推荐", "P2", ["emotion"]),
        ("generate_aging_wellness", "抗衰养生方案", "延缓衰老的综合养生方案", "P2", ["life_stage", "constitution"]),
        ("generate_cold_prevention", "日常防感冒指南", "日常预防感冒的方法", "P1", ["season"]),
        ("generate_allergy_management", "过敏管理方案", "日常过敏管理方法", "P2", ["constitution", "season"]),
        ("generate_hydration_tip", "每日补水小贴士", "简单实用的补水小建议", "P2", ["season"]),
        ("generate_noise_management", "噪音管理建议", "减少噪音对健康的影响", "P2", []),
    ]
    for sid, name, *rest in lifestyle_skills:
        desc = rest[0]
        pri = rest[1] if len(rest) > 1 else "P1"
        ctx = rest[2] if len(rest) > 2 else []
        skills[sid] = _skill(sid, "lifestyle", name, desc, pri, ctx, ["生活", name[-3:]])

    return skills


# ==================== 10. Daily Plan 计划 Skills (20) ====================

def _build_daily_plan_skills() -> Dict[str, SkillDefinition]:
    """构建计划分类的所有 Skill"""
    skills: Dict[str, SkillDefinition] = {}

    plan_skills = [
        ("generate_daily_plan", "今日养生计划", "生成今日综合养生计划", "P0",
         ["constitution", "season", "sleep", "emotion", "life_stage", "exercise", "diet"]),
        ("generate_daily_plan_light", "轻量养生计划", "简短的今日3条核心建议", "P0",
         ["constitution", "season"]),
        ("generate_daily_plan_deep", "深度养生计划", "详细的今日养生全案", "P1",
         ["constitution", "season", "sleep", "emotion", "life_stage", "exercise", "diet"],
         True, 0, ["generate_daily_plan"]),
        ("generate_daily_plan_emotion", "情绪关怀计划", "侧重情绪关怀的今日计划", "P1", ["emotion", "season"]),
        ("generate_daily_plan_sleep", "睡眠优化计划", "侧重睡眠优化的今日计划", "P1", ["sleep", "constitution"]),
        ("generate_daily_plan_constitution", "体质调理计划", "侧重体质调理的今日计划", "P1", ["constitution", "season"]),
        ("generate_daily_plan_season", "节气养生计划", "侧重节气养生的今日计划", "P0", ["season", "constitution"]),
        ("generate_daily_plan_follow_up", "计划执行跟进", "跟踪昨日计划执行情况", "P2", ["constitution"]),
        ("generate_daily_plan_morning", "晨间启动计划", "今日晨间养生安排", "P1", ["constitution", "season"]),
        ("generate_daily_plan_noon", "午间休整计划", "今日午间养生安排", "P1", ["constitution"]),
        ("generate_daily_plan_evening", "晚间收心计划", "今日晚间养生安排", "P1", ["constitution", "sleep"]),
        ("generate_weekly_plan", "本周养生计划", "本周综合养生计划", "P1",
         ["constitution", "season", "life_stage"], True, 168),
        ("generate_monthly_plan", "本月养生计划", "本月综合养生计划", "P2",
         ["constitution", "season", "life_stage"], True, 720),
        ("generate_plan_adjustment", "计划动态调整", "根据执行情况调整养生计划", "P2", ["constitution"]),
        ("generate_plan_review", "计划执行复盘", "回顾养生计划执行效果", "P2", ["constitution"]),
        ("generate_travel_health_plan", "出行健康计划", "旅行途中的健康计划", "P2", ["constitution", "season"]),
        ("generate_workday_plan", "工作日养生计划", "工作日的养生安排", "P1", ["constitution"]),
        ("generate_restday_plan", "休息日养生计划", "休息日的养生放松安排", "P1", ["constitution", "life_stage"]),
        ("generate_plan_summary", "计划执行总结", "汇总计划执行情况", "P2", ["constitution"]),
        ("generate_next_day_preview", "明日养生预告", "提前预览明天的养生要点", "P2", ["season", "constitution"]),
    ]
    for sid, name, *rest in plan_skills:
        desc = rest[0]
        pri = rest[1] if len(rest) > 1 else "P1"
        ctx = rest[2] if len(rest) > 2 else []
        premium = rest[3] if len(rest) > 3 else False
        cooldown = rest[4] if len(rest) > 4 else 0
        deps = rest[5] if len(rest) > 5 else []
        skills[sid] = _skill(
            sid, "daily_plan", name, desc, pri, ctx, ["计划", name[-3:]],
            is_premium=premium, cooldown=cooldown, deps=deps,
        )

    return skills


# ==================== 11. Follow-up 跟进 Skills (20) ====================

def _build_follow_up_skills() -> Dict[str, SkillDefinition]:
    """构建跟进分类的所有 Skill"""
    skills: Dict[str, SkillDefinition] = {}

    followup_skills = [
        ("generate_follow_up", "通用跟进生成", "生成通用的养生跟进消息", "P0", []),
        ("generate_follow_up_soft", "软性跟进", "自然不突兀的关怀跟进", "P0", []),
        ("generate_follow_up_sleep", "睡眠跟进", "跟踪睡眠改善情况", "P1", ["sleep"]),
        ("generate_follow_up_emotion", "情绪跟进", "跟踪用户情绪状态", "P1", ["emotion"]),
        ("generate_follow_up_diet", "饮食跟进", "跟踪食疗执行情况", "P2", ["diet"]),
        ("generate_follow_up_exercise", "运动跟进", "跟踪运动计划执行", "P2", ["exercise"]),
        ("generate_follow_up_family", "家庭关怀跟进", "家庭健康关怀跟进", "P1", ["family"]),
        ("decay_follow_up_frequency", "跟进频率衰减", "根据用户参与度衰减跟进频率", "P2", []),
        ("cancel_follow_up", "取消跟进", "取消或暂停某项跟进计划", "P2", []),
        ("generate_follow_up_morning", "晨间关怀", "早晨的自然关怀消息", "P1", ["constitution", "season"]),
        ("generate_follow_up_evening", "晚间关怀", "晚间的温暖关怀消息", "P1", ["constitution"]),
        ("generate_follow_up_weekly", "周度跟进", "每周一次的养生总结跟进", "P1", ["constitution"]),
        ("generate_follow_up_monthly", "月度跟进", "每月一次的养生回顾", "P2", ["constitution"], True, 720),
        ("generate_follow_up_season_transition", "节气交替跟进", "节气变化时的特别跟进", "P1", ["season"]),
        ("generate_follow_up_reminder", "温馨提醒", "定时温馨养生提醒", "P1", []),
        ("generate_follow_up_habit", "习惯养成跟进", "跟踪习惯养成进度", "P2", []),
        ("generate_follow_up_constitution", "体质调理跟进", "跟踪体质调理进展", "P1", ["constitution"]),
        ("generate_follow_up_tea", "茶饮养生跟进", "跟踪茶饮养生效果", "P2", ["constitution"]),
        ("generate_follow_up_acupoint", "穴位保健跟进", "跟踪穴位按摩坚持情况", "P2", ["constitution"]),
        ("generate_follow_up_milestone", "里程碑祝贺", "达成养生目标时的祝贺跟进", "P2", []),
    ]
    for sid, name, *rest in followup_skills:
        desc = rest[0]
        pri = rest[1] if len(rest) > 1 else "P1"
        ctx = rest[2] if len(rest) > 2 else []
        premium = rest[3] if len(rest) > 3 else False
        cooldown = rest[4] if len(rest) > 4 else 0
        skills[sid] = _skill(
            sid, "follow_up", name, desc, pri, ctx, ["跟进", name[-3:]],
            is_premium=premium, cooldown=cooldown,
        )

    return skills


# ==================== 12. Family 家庭 Skills (15) ====================

def _build_family_skills() -> Dict[str, SkillDefinition]:
    """构建家庭分类的所有 Skill"""
    skills: Dict[str, SkillDefinition] = {}

    family_skills = [
        ("generate_family_status", "家庭健康总览", "全家人健康状态总览", "P1", ["family", "life_stage"]),
        ("generate_family_advice", "家庭养生建议", "适合全家的养生建议", "P1", ["family", "season"]),
        ("generate_parent_care", "父母关怀方案", "对父母的健康关怀方案", "P1", ["family", "life_stage"]),
        ("generate_family_follow_up", "家庭关怀跟进", "家庭健康关怀跟进", "P2", ["family"]),
        ("generate_family_alert_soft", "家庭关怀提醒", "温和的家庭关怀提醒", "P2", ["family"]),
        ("generate_family_meal_plan", "家庭膳食计划", "全家的膳食安排建议", "P1", ["family", "season", "diet"]),
        ("generate_family_exercise_plan", "家庭运动计划", "全家的运动安排建议", "P2", ["family", "life_stage"]),
        ("generate_child_health_advice", "儿童健康建议", "儿童健康养生的建议", "P1", ["family", "life_stage"]),
        ("generate_elder_care_guide", "老人关怀指南", "老人日常关怀的全面指南", "P1", ["family", "life_stage"]),
        ("generate_family_seasonal", "家庭季节养生", "全家的季节性养生建议", "P1", ["family", "season"]),
        ("generate_family_emergency_prep", "家庭急救准备", "家庭急救物品和方法准备", "P2", ["family"]),
        ("generate_family_health_record", "家庭健康档案", "维护家庭健康记录", "P2", ["family"], True),
        ("generate_family_sleep_advice", "家庭睡眠建议", "不同年龄段的睡眠建议", "P2", ["family", "life_stage"]),
        ("generate_family_emotion_support", "家庭情绪关怀", "家庭关系中的情绪关怀", "P2", ["family", "emotion"]),
        ("generate_family_holiday_plan", "家庭节日养生", "传统节日的家庭养生建议", "P2", ["family", "season"]),
    ]
    for sid, name, *rest in family_skills:
        desc = rest[0]
        pri = rest[1] if len(rest) > 1 else "P1"
        ctx = rest[2] if len(rest) > 2 else []
        premium = rest[3] if len(rest) > 3 else False
        skills[sid] = _skill(
            sid, "family", name, desc, pri, ctx, ["家庭", name[-3:]],
            is_premium=premium,
        )

    return skills


# ==================== 13. Safety 安全 Skills (15) ====================

def _build_safety_skills() -> Dict[str, SkillDefinition]:
    """构建安全分类的所有 Skill"""
    skills: Dict[str, SkillDefinition] = {}

    safety_skills = [
        ("detect_medical_intent", "医疗意图检测", "检测用户是否有医疗诊断意图", "P0", [], "安全", "医疗"),
        ("detect_risk_emotion", "危机情绪检测", "检测用户是否有危机情绪信号", "P0", ["emotion"], "安全", "危机"),
        ("generate_safe_response", "安全响应生成", "生成符合安全边界的响应", "P0", [], "安全", "响应"),
        ("generate_safe_mode_response", "安全模式响应", "安全模式下的标准响应", "P0", [], "安全", "模式"),
        ("block_illegal_advice", "违规建议拦截", "拦截并替换违规的医疗建议", "P0", [], "安全", "拦截"),
        ("generate_offline_suggestion", "线下就医建议", "引导用户线下就医的建议", "P0", [], "安全", "就医"),
        ("generate_medical_boundary_response", "医疗边界响应", "明确告知不做医疗诊断的回应", "P0", [], "安全", "边界"),
        ("detect_pregnancy_intent", "孕期意图检测", "检测与孕期相关的问题", "P0", [], "安全", "孕期"),
        ("generate_pregnancy_safe_response", "孕期安全响应", "孕期问题的安全回应", "P0", [], "安全", "孕期"),
        ("detect_child_medical", "儿童医疗检测", "检测儿童医疗相关问题", "P0", ["family"], "安全", "儿童"),
        ("generate_child_safe_response", "儿童安全响应", "儿童健康问题的安全回应", "P0", ["family"], "安全", "儿童"),
        ("generate_allergy_alert", "过敏风险提示", "食材或方法的过敏风险提示", "P1", ["constitution"], "安全", "过敏"),
        ("generate_exercise_safety_warning", "运动安全警告", "运动中的安全注意事项", "P1", ["life_stage"], "安全", "运动"),
        ("generate_acupoint_safety_warning", "穴位安全提醒", "穴位按摩的安全注意事项", "P1", [], "安全", "穴位"),
        ("generate_diet_safety_check", "食疗安全检查", "食疗方案的安全性检查", "P1", ["constitution"], "安全", "食疗"),
    ]
    for sid, name, *rest in safety_skills:
        desc = rest[0]
        pri = rest[1] if len(rest) > 1 else "P1"
        ctx = rest[2] if len(rest) > 2 else []
        tag_group = rest[3] if len(rest) > 3 else ["安全"]
        skills[sid] = _skill(sid, "safety", name, desc, pri, ctx, tag_group)

    return skills


# ==================== 14. Meta 系统控制 Skills (10) ====================

def _build_meta_skills() -> Dict[str, SkillDefinition]:
    """构建系统控制分类的所有 Skill"""
    skills: Dict[str, SkillDefinition] = {}

    skills["decide_skill_chain"] = _skill(
        "decide_skill_chain", "meta", "Skill链决策",
        "决定本次对话需要执行的Skill组合和顺序",
        priority="P0", context=["constitution", "season", "emotion", "sleep"],
        tags=["系统", "决策"], model="minimax-m2", max_tokens=256,
    )
    skills["decide_model"] = _skill(
        "decide_model", "meta", "模型选择决策",
        "根据任务复杂度和用户等级选择最适合的模型",
        priority="P0", context=["membership"],
        tags=["系统", "模型"], model="minimax-m2", max_tokens=128,
    )
    skills["decide_temperature"] = _skill(
        "decide_temperature", "meta", "温度参数决策",
        "根据任务类型决定LLM温度参数",
        priority="P0", context=[],
        tags=["系统", "参数"], model="minimax-m2", max_tokens=64,
    )
    skills["decide_token_budget"] = _skill(
        "decide_token_budget", "meta", "Token预算决策",
        "根据任务类型和用户等级分配token预算",
        priority="P0", context=["membership"],
        tags=["系统", "token"], model="minimax-m2", max_tokens=64,
    )
    skills["log_skill_usage"] = _skill(
        "log_skill_usage", "meta", "Skill使用记录",
        "记录Skill使用情况用于分析和优化",
        priority="P1", context=[],
        tags=["系统", "日志"], model="minimax-m2", max_tokens=128,
    )
    skills["detect_context_need"] = _skill(
        "detect_context_need", "meta", "上下文需求检测",
        "检测执行当前Skill需要哪些额外上下文",
        priority="P0", context=[],
        tags=["系统", "上下文"], model="minimax-m2", max_tokens=128,
    )
    skills["estimate_complexity"] = _skill(
        "estimate_complexity", "meta", "复杂度评估",
        "评估当前请求的复杂度等级",
        priority="P0", context=[],
        tags=["系统", "复杂度"], model="minimax-m2", max_tokens=64,
    )
    skills["plan_fallback_chain"] = _skill(
        "plan_fallback_chain", "meta", "降级链规划",
        "规划Skill执行失败时的降级方案",
        priority="P1", context=[],
        tags=["系统", "降级"], model="minimax-m2", max_tokens=128,
    )
    skills["validate_user_input"] = _skill(
        "validate_user_input", "meta", "输入验证",
        "验证用户输入的合法性和完整性",
        priority="P0", context=[],
        tags=["系统", "验证"], model="minimax-m2", max_tokens=64,
    )
    skills["generate_cost_estimate"] = _skill(
        "generate_cost_estimate", "meta", "成本预估",
        "预估本次请求的成本",
        priority="P1", context=["membership"],
        tags=["系统", "成本"], model="minimax-m2", max_tokens=64,
    )

    return skills


# ==================== 15. Reflection 复盘 Skills (20) ====================

def _build_reflection_skills() -> Dict[str, SkillDefinition]:
    """构建复盘分类的所有 Skill"""
    skills: Dict[str, SkillDefinition] = {}

    reflection_skills = [
        ("generate_daily_reflection", "每日养生复盘", "今日养生实践回顾与反思", "P1", ["constitution", "season"]),
        ("generate_weekly_reflection", "每周养生复盘", "本周养生实践回顾与反思", "P1", ["constitution"], True, 168),
        ("generate_monthly_reflection", "每月养生复盘", "本月养生实践回顾与反思", "P2", ["constitution"], True, 720),
        ("generate_seasonal_reflection", "节气养生复盘", "当前节气养生实践回顾", "P1", ["season", "constitution"]),
        ("analyze_mood_trend", "情绪趋势分析", "分析用户情绪的变化趋势", "P1", ["emotion"]),
        ("analyze_sleep_trend", "睡眠趋势分析", "分析用户睡眠的变化趋势", "P1", ["sleep"]),
        ("generate_reflection_prompt", "复盘引导提问", "生成引导用户自我反思的问题", "P2", ["constitution"]),
        ("generate_mood_journal", "心情日记生成", "帮助用户生成心情日记内容", "P2", ["emotion"]),
        ("analyze_diet_trend", "饮食趋势分析", "分析用户饮食习惯的变化趋势", "P2", ["diet"]),
        ("analyze_exercise_trend", "运动趋势分析", "分析用户运动习惯的变化趋势", "P2", ["exercise"]),
        ("generate_health_score", "健康评分", "综合评估用户健康状态得分", "P1", ["constitution", "sleep", "emotion"]),
        ("generate_progress_report", "进步报告", "展示养生实践的进步和成果", "P1", ["constitution"]),
        ("generate_goal_review", "目标回顾", "回顾养生目标完成情况", "P2", ["constitution"]),
        ("generate_season_summary", "季节养生总结", "整个季节的养生总结", "P2", ["season", "constitution"]),
        ("generate_constitution_change_report", "体质变化报告", "体质调理的变化和成效报告", "P2", ["constitution"], True, 720),
        ("generate_habit_strength_report", "习惯巩固报告", "已养成习惯的巩固度分析", "P2", []),
        ("generate_personal_insight", "个人养生洞察", "从用户数据中发现养生洞察", "P2", ["constitution", "emotion", "sleep"], True, 168),
        ("generate_yearly_summary", "年度养生总结", "全年养生实践的总结回顾", "P2", ["constitution"], True, 8760),
        ("generate_comparison_report", "对比分析报告", "不同时段的养生状态对比", "P2", ["constitution"], True, 720),
        ("generate_next_phase_plan", "下阶段计划", "基于复盘制定下阶段养生计划", "P2", ["constitution", "season"]),
    ]
    for sid, name, *rest in reflection_skills:
        desc = rest[0]
        pri = rest[1] if len(rest) > 1 else "P1"
        ctx = rest[2] if len(rest) > 2 else []
        premium = rest[3] if len(rest) > 3 else False
        cooldown = rest[4] if len(rest) > 4 else 0
        skills[sid] = _skill(
            sid, "reflection", name, desc, pri, ctx, ["复盘", name[-3:]],
            is_premium=premium, cooldown=cooldown,
        )

    return skills


# ==================== Skill Registry 注册表 ====================

class SkillRegistry:
    """
    顺时 Skill 注册表

    统一管理所有 300+ 个 Skill 的注册、查询和筛选。
    每个分类通过独立的构建函数生成 Skill 字典，
    注册表在初始化时加载所有 Skill。
    """

    def __init__(self):
        """初始化注册表，加载所有 Skill"""
        self._skills: Dict[str, SkillDefinition] = {}
        self._categories: Dict[str, List[str]] = {}
        self._load_all_skills()
        logger.info(f"[SkillRegistry] 已加载 {len(self._skills)} 个 Skill")

    def _load_all_skills(self) -> None:
        """加载所有分类的 Skill"""
        # 按分类构建
        builders = [
            (SkillCategory.SEASON.value, _build_season_skills),
            (SkillCategory.CONSTITUTION.value, _build_constitution_skills),
            (SkillCategory.DIET.value, _build_diet_skills),
            (SkillCategory.TEA.value, _build_tea_skills),
            (SkillCategory.ACUPOINT.value, _build_acupoint_skills),
            (SkillCategory.EXERCISE.value, _build_exercise_skills),
            (SkillCategory.SLEEP.value, _build_sleep_skills),
            (SkillCategory.EMOTION.value, _build_emotion_skills),
            (SkillCategory.LIFESTYLE.value, _build_lifestyle_skills),
            (SkillCategory.DAILY_PLAN.value, _build_daily_plan_skills),
            (SkillCategory.FOLLOW_UP.value, _build_follow_up_skills),
            (SkillCategory.FAMILY.value, _build_family_skills),
            (SkillCategory.SAFETY.value, _build_safety_skills),
            (SkillCategory.META.value, _build_meta_skills),
            (SkillCategory.REFLECTION.value, _build_reflection_skills),
        ]

        for category, builder_fn in builders:
            category_skills = builder_fn()
            self._categories[category] = list(category_skills.keys())
            for skill_id, skill_def in category_skills.items():
                # 确保分类字段正确
                skill_def.category = category
                self._skills[skill_id] = skill_def

    # ==================== 查询方法 ====================

    def get(self, skill_id: str) -> Optional[SkillDefinition]:
        """根据 skill_id 获取 Skill 定义"""
        return self._skills.get(skill_id)

    def get_by_category(self, category: str) -> List[SkillDefinition]:
        """获取某个分类下的所有 Skill"""
        skill_ids = self._categories.get(category, [])
        return [self._skills[sid] for sid in skill_ids if sid in self._skills]

    def get_by_tags(self, tags: List[str]) -> List[SkillDefinition]:
        """根据标签筛选 Skill"""
        tag_set = set(tags)
        return [
            s for s in self._skills.values()
            if tag_set.intersection(set(s.tags))
        ]

    def get_by_priority(self, priority: str) -> List[SkillDefinition]:
        """根据优先级筛选 Skill"""
        return [s for s in self._skills.values() if s.priority == priority]

    def get_by_model(self, model: str) -> List[SkillDefinition]:
        """根据推荐模型筛选 Skill"""
        return [s for s in self._skills.values() if s.recommended_model == model]

    def get_premium_skills(self) -> List[SkillDefinition]:
        """获取所有会员专属 Skill"""
        return [s for s in self._skills.values() if s.is_premium]

    def get_free_skills(self) -> List[SkillDefinition]:
        """获取所有免费 Skill"""
        return [s for s in self._skills.values() if not s.is_premium]

    def search(self, query: str) -> List[SkillDefinition]:
        """搜索 Skill（匹配 name, description, tags, skill_id）"""
        query_lower = query.lower()
        results = []
        for s in self._skills.values():
            if (query_lower in s.skill_id.lower() or
                query_lower in s.name or
                query_lower in s.description or
                any(query_lower in t for t in s.tags)):
                results.append(s)
        return results

    # ==================== 统计方法 ====================

    def total_count(self) -> int:
        """Skill 总数"""
        return len(self._skills)

    def category_counts(self) -> Dict[str, int]:
        """各分类 Skill 数量"""
        return {cat: len(sids) for cat, sids in self._categories.items()}

    def list_categories(self) -> List[Dict[str, Any]]:
        """列出所有分类信息"""
        result = []
        for cat, sids in self._categories.items():
            skills = [self._skills[sid] for sid in sids if sid in self._skills]
            p0_count = sum(1 for s in skills if s.priority == "P0")
            premium_count = sum(1 for s in skills if s.is_premium)
            result.append({
                "category": cat,
                "skill_count": len(skills),
                "p0_count": p0_count,
                "premium_count": premium_count,
                "skill_ids": sids[:5],  # 前5个示例
            })
        return result

    def get_solar_term_content_skill(
        self, term: str, dimension: str
    ) -> Optional[SkillDefinition]:
        """
        获取节气内容生成的 Skill

        Args:
            term: 节气名称（如"春分"）
            dimension: 内容维度（profile/diet/exercise/sleep/emotion/tea/acupoint）

        Returns:
            对应的 SkillDefinition，如果使用通用入口则返回通用Skill
        """
        # 先尝试特定节气 Skill
        pinyin = _term_to_pinyin(term)
        specific_id = f"solar_term_{pinyin}"
        if specific_id in self._skills:
            return self._skills[specific_id]
        # 否则返回通用动态入口
        return self._skills.get("generate_solar_term_content")

    def all_skill_ids(self) -> List[str]:
        """获取所有 Skill ID 列表"""
        return list(self._skills.keys())

    def all_skills(self) -> List[SkillDefinition]:
        """获取所有 Skill 列表"""
        return list(self._skills.values())

    def to_dict_list(self, skills: Optional[List[SkillDefinition]] = None) -> List[Dict]:
        """将 Skill 列表转换为字典列表"""
        if skills is None:
            skills = self.all_skills()
        return [s.to_dict() for s in skills]


# ==================== 全局实例 ====================

skill_registry = SkillRegistry()


# ==================== 使用示例 ====================

# ==================== DAG 依赖验证 ====================

def validate_skill_dag(skills: Dict[str, SkillDefinition]) -> List[str]:
    """
    验证 Skill 依赖关系是否有环。

    使用 Kahn 拓扑排序算法检测环。
    返回错误列表，空列表表示无环。

    Args:
        skills: {skill_id: SkillDefinition}

    Returns:
        错误消息列表，空列表表示 DAG 合法
    """
    errors: List[str] = []
    skill_ids = set(skills.keys())

    # 检查依赖引用是否都指向已注册的 skill
    dangling: List[str] = []
    for sid, skill in skills.items():
        for dep in skill.dependencies:
            if dep not in skill_ids:
                dangling.append(f"{sid} -> {dep} (未注册)")
    if dangling:
        errors.append(f"存在悬空依赖: {'; '.join(dangling[:5])}")

    # Kahn 算法：计算入度
    in_degree: Dict[str, int] = {sid: 0 for sid in skill_ids}
    adjacency: Dict[str, List[str]] = {sid: [] for sid in skill_ids}

    for sid, skill in skills.items():
        for dep in skill.dependencies:
            if dep in skill_ids:
                adjacency[dep].append(sid)
                in_degree[sid] += 1

    # 零入度节点入队
    from collections import deque
    queue: deque = deque()
    for sid, deg in in_degree.items():
        if deg == 0:
            queue.append(sid)

    visited_count = 0
    while queue:
        node = queue.popleft()
        visited_count += 1
        for neighbor in adjacency[node]:
            in_degree[neighbor] -= 1
            if in_degree[neighbor] == 0:
                queue.append(neighbor)

    if visited_count < len(skill_ids):
        # 找到环中的节点
        cycle_nodes = [
            sid for sid, deg in in_degree.items() if deg > 0
        ]
        errors.append(
            f"检测到循环依赖，涉及 {len(cycle_nodes)} 个 Skill: "
            f"{', '.join(cycle_nodes[:5])}"
            f"{'...' if len(cycle_nodes) > 5 else ''}"
        )

    return errors


def get_execution_order(
    skill_names: List[str],
    registry: Dict[str, SkillDefinition],
) -> List[str]:
    """
    根据依赖关系返回执行顺序（拓扑排序）。

    例如 diet depends on constitution → [constitution, diet]

    Args:
        skill_names: 需要执行的 skill_id 列表
        registry: 完整的 skill 注册表

    Returns:
        按依赖关系排序后的 skill_id 列表
    """
    # 仅考虑请求的 skill 及其请求内的依赖
    requested = set(skill_names)
    in_scope: Dict[str, SkillDefinition] = {}

    # 收集请求中引用的依赖（仅在请求范围内）
    for sid in skill_names:
        if sid in registry:
            in_scope[sid] = registry[sid]
        # 将请求范围内的依赖也纳入
        for dep in registry.get(sid, type('obj', (object,), {'dependencies': []})()).dependencies:
            if dep in requested:
                in_scope[dep] = registry.get(dep)

    # Kahn 拓扑排序
    in_degree: Dict[str, int] = {sid: 0 for sid in in_scope}
    adjacency: Dict[str, List[str]] = {sid: [] for sid in in_scope}

    for sid, skill in in_scope.items():
        for dep in skill.dependencies:
            if dep in in_scope:
                adjacency[dep].append(sid)
                in_degree[sid] += 1

    from collections import deque
    queue: deque = deque()
    for sid, deg in in_degree.items():
        if deg == 0:
            queue.append(sid)

    result: List[str] = []
    while queue:
        node = queue.popleft()
        result.append(node)
        for neighbor in adjacency[node]:
            in_degree[neighbor] -= 1
            if in_degree[neighbor] == 0:
                queue.append(neighbor)

    # 未排序的节点（有环或其他问题）追加到末尾
    remaining = [sid for sid in skill_names if sid not in set(result)]
    result.extend(remaining)

    return result


def demo_registry():
    """演示 Skill 注册表"""
    registry = SkillRegistry()

    print("=" * 60)
    print("顺时 Skill 注册表演示")
    print("=" * 60)

    # 基本统计
    print(f"\n[总览] 共 {registry.total_count()} 个 Skill")
    print(f"[分类统计] {registry.category_counts()}")

    # 各分类前3个
    print("\n[各分类预览]")
    for cat_info in registry.list_categories():
        print(f"  {cat_info['category']}: {cat_info['skill_count']}个 "
              f"(P0:{cat_info['p0_count']}, 会员:{cat_info['premium_count']})")

    # 搜索
    print("\n[搜索 '睡眠']")
    results = registry.search("睡眠")
    for s in results[:5]:
        print(f"  - {s.skill_id}: {s.name} ({s.category})")

    # 获取节气 Skill
    print("\n[节气动态] 春分 + 饮食")
    skill = registry.get_solar_term_content_skill("春分", "diet")
    if skill:
        print(f"  → {skill.skill_id}: {skill.name}")


if __name__ == "__main__":
    demo_registry()
