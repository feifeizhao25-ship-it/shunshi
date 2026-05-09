"""
顺时 12 核心 Skills 产品化封装
Core Skills Product Wrapper

将 361 个细粒度技能封装为 12 个产品级核心 Skills，统一 Schema 输出。
每个核心 Skill 具备：
- 统一输入/输出 Schema（严格遵循 SKILLS_SYSTEM.md）
- 独立缓存策略（按 skill+params 分桶）
- 强制安全字段（safety_flag, presence_level, contraindications, when_to_seek_help）
- 版本管理（version 字段）

12 核心 Skills:
1. DailyRhythmPlan      - 今日节律
2. SleepWindDown        - 睡前仪式
3. OfficeMicroBreak     - 办公室3分钟放松
4. MoodFirstAid         - 情绪急救
5. SolarTermGuide       - 节气指南
6. BodyConstitutionLite - 体质轻推断
7. FoodTeaRecommender   - 食疗/茶饮生成
8. AcupressureRoutineLite - 穴位按揉流程
9. FollowUpGenerator    - 轻跟进生成
10. PresencePolicyDecider - 退让策略（新增）
11. CareStatusUpdater   - 照护状态机
12. FamilyCareDigest    - 家庭可感知摘要

作者: Claw 🦅
日期: 2026-04-29
"""

from __future__ import annotations
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, field
from enum import Enum
import hashlib
import json
import logging
import time
from datetime import datetime, timedelta

from .skill_registry import skill_registry
from .orchestrator import SkillOrchestrator, SkillExecutionResult, OrchestrationStatus
from .schema_validator import SchemaValidator, ValidationResult

logger = logging.getLogger(__name__)


# ==================== 枚举定义 ====================

class SafetyFlag(str, Enum):
    """安全标记"""
    NONE = "none"
    WATCH = "watch"
    ESCALATE = "escalate"


class PresenceLevel(str, Enum):
    """触达级别"""
    NORMAL = "normal"
    REDUCED = "reduced"
    SILENT = "silent"


class LifeStage(str, Enum):
    """人生阶段"""
    EXPLORATION = "exploration"
    STRESS = "stress"
    HEALTH = "health"
    COMPANIONSHIP = "companionship"


class Tone(str, Enum):
    """语气风格"""
    GENTLE = "gentle"
    WARM = "warm"
    ENCOURAGING = "encouraging"
    CALM = "calm"
    SERIOUS = "serious"


# ==================== 统一数据模型 ====================

@dataclass
class CoreSkillInput:
    """核心 Skill 统一输入"""
    user_id: str
    user_context: Dict[str, Any] = field(default_factory=dict)
    task_params: Dict[str, Any] = field(default_factory=dict)
    signals: Optional[Dict[str, Any]] = None
    locale: str = "zh-CN"


@dataclass
class Insight:
    """洞察卡片"""
    title: str
    content: str
    emoji: str = ""


@dataclass
class Action:
    """行动建议"""
    time_period: str  # morning | afternoon | evening
    items: List[str] = field(default_factory=list)


@dataclass
class ContentCard:
    """内容卡片"""
    type: str  # suggestion | diet | exercise | acupoint | tea | sleep
    title: str
    content: str
    emoji: str = ""
    steps: List[str] = field(default_factory=list)
    duration_min: Optional[int] = None
    contraindications: List[str] = field(default_factory=list)


@dataclass
class FollowUp:
    """跟进计划"""
    type: str
    message: str
    in_days: Optional[int] = None


@dataclass
class CoreSkillOutput:
    """核心 Skill 统一输出 Schema（严格遵循 SKILLS_SYSTEM.md）"""
    skill: str
    text: str  # 对用户说的话，50-150字
    
    # 强制安全字段
    safety_flag: SafetyFlag = SafetyFlag.NONE
    presence_level: PresenceLevel = PresenceLevel.NORMAL
    contraindications: List[str] = field(default_factory=list)
    when_to_seek_help: Optional[str] = None
    
    # 内容字段
    tone: Tone = Tone.GENTLE
    care_status: str = "stable"  # stable | tired | needs_attention | crisis
    insight: Optional[Insight] = None
    actions: List[Action] = field(default_factory=list)
    cards: List[ContentCard] = field(default_factory=list)
    follow_up: Optional[FollowUp] = None
    
    # 元数据
    version: str = "2.0.0"
    cached: bool = False
    generated_at: str = field(default_factory=lambda: datetime.utcnow().isoformat())
    model_used: str = ""
    tokens_used: int = 0
    latency_ms: int = 0

    def to_dict(self) -> Dict[str, Any]:
        """序列化为字典"""
        result = {
            "skill": self.skill,
            "version": self.version,
            "text": self.text,
            "safety_flag": self.safety_flag.value,
            "presence_level": self.presence_level.value,
            "contraindications": self.contraindications,
            "when_to_seek_help": self.when_to_seek_help,
            "tone": self.tone.value,
            "care_status": self.care_status,
            "insight": {
                "title": self.insight.title,
                "content": self.insight.content,
                "emoji": self.insight.emoji,
            } if self.insight else None,
            "actions": [
                {"time_period": a.time_period, "items": a.items}
                for a in self.actions
            ],
            "cards": [
                {
                    "type": c.type,
                    "title": c.title,
                    "content": c.content,
                    "emoji": c.emoji,
                    "steps": c.steps,
                    "duration_min": c.duration_min,
                    "contraindications": c.contraindications,
                }
                for c in self.cards
            ],
            "follow_up": {
                "type": self.follow_up.type,
                "message": self.follow_up.message,
                "in_days": self.follow_up.in_days,
            } if self.follow_up else None,
            "meta": {
                "cached": self.cached,
                "generated_at": self.generated_at,
                "model_used": self.model_used,
                "tokens_used": self.tokens_used,
                "latency_ms": self.latency_ms,
            }
        }
        return result


# ==================== Skill 缓存管理器 ====================

class SkillCache:
    """Skill 级别缓存（按 skill+params 分桶）"""
    
    # 缓存策略配置
    CACHE_CONFIG = {
        "DailyRhythmPlan": {"ttl_hours": 24, "bucket_key": "user_id+date"},
        "SleepWindDown": {"ttl_hours": 12, "bucket_key": "user_id+duration"},
        "OfficeMicroBreak": {"ttl_hours": 6, "bucket_key": "user_id+focus_area"},
        "MoodFirstAid": {"ttl_hours": 0, "bucket_key": "none"},  # 不缓存
        "SolarTermGuide": {"ttl_hours": 360, "bucket_key": "term+region"},  # 15天
        "BodyConstitutionLite": {"ttl_hours": 720, "bucket_key": "user_id"},  # 30天
        "FoodTeaRecommender": {"ttl_hours": 24, "bucket_key": "goal+constraints_hash"},
        "AcupressureRoutineLite": {"ttl_hours": 12, "bucket_key": "user_id+target"},
        "FollowUpGenerator": {"ttl_hours": 0, "bucket_key": "none"},  # 不缓存
        "PresencePolicyDecider": {"ttl_hours": 1, "bucket_key": "user_id"},
        "CareStatusUpdater": {"ttl_hours": 2, "bucket_key": "user_id"},
        "FamilyCareDigest": {"ttl_hours": 6, "bucket_key": "user_id+family_hash"},
    }
    
    def __init__(self):
        self._memory: Dict[str, Dict[str, Any]] = {}
    
    def _generate_key(self, skill_name: str, user_id: str, params: Dict[str, Any]) -> str:
        """生成缓存 Key"""
        config = self.CACHE_CONFIG.get(skill_name, {"ttl_hours": 1, "bucket_key": "user_id"})
        bucket_key = config["bucket_key"]
        
        components = [skill_name]
        
        if "user_id" in bucket_key:
            components.append(user_id)
        if "date" in bucket_key:
            components.append(datetime.now().strftime("%Y-%m-%d"))
        if "term" in bucket_key and params.get("solar_term"):
            components.append(params["solar_term"])
        if "region" in bucket_key and params.get("region"):
            components.append(params["region"])
        if "duration" in bucket_key and params.get("duration"):
            components.append(str(params["duration"]))
        if "focus_area" in bucket_key and params.get("focus_area"):
            components.append(params["focus_area"])
        if "goal" in bucket_key and params.get("goal"):
            components.append(params["goal"])
        if "target" in bucket_key and params.get("target"):
            components.append(params["target"])
        if "family_hash" in bucket_key and params.get("family_members"):
            # 简化 family hash
            family_ids = sorted([m.get("user_id", "") for m in params["family_members"]])
            components.append(hashlib.md5("".join(family_ids).encode()).hexdigest()[:8])
        
        key_string = "|".join(components)
        return f"core_skill:{hashlib.sha256(key_string.encode()).hexdigest()[:16]}"
    
    def get(self, skill_name: str, user_id: str, params: Dict[str, Any]) -> Optional[CoreSkillOutput]:
        """获取缓存"""
        config = self.CACHE_CONFIG.get(skill_name, {"ttl_hours": 0})
        if config["ttl_hours"] == 0:
            return None  # 不缓存的 Skill
        
        key = self._generate_key(skill_name, user_id, params)
        entry = self._memory.get(key)
        
        if entry and datetime.now() < entry["expires_at"]:
            logger.info(f"[SkillCache] 命中: {skill_name} for {user_id}")
            return entry["value"]
        
        if entry:
            del self._memory[key]
        
        return None
    
    def set(self, skill_name: str, user_id: str, params: Dict[str, Any], output: CoreSkillOutput):
        """设置缓存"""
        config = self.CACHE_CONFIG.get(skill_name, {"ttl_hours": 0})
        if config["ttl_hours"] == 0:
            return  # 不缓存的 Skill
        
        key = self._generate_key(skill_name, user_id, params)
        ttl_seconds = config["ttl_hours"] * 3600
        
        self._memory[key] = {
            "value": output,
            "expires_at": datetime.now() + timedelta(seconds=ttl_seconds),
        }
        logger.info(f"[SkillCache] 保存: {skill_name} for {user_id}, TTL={config['ttl_hours']}h")
    
    def invalidate_user(self, user_id: str):
        """清除某用户的所有缓存"""
        keys_to_delete = [k for k in self._memory.keys() if user_id in k]
        for k in keys_to_delete:
            del self._memory[k]
        logger.info(f"[SkillCache] 清除用户缓存: {user_id}, {len(keys_to_delete)} 条")


# ==================== 核心 Skill 执行器 ====================

class CoreSkillExecutor:
    """
    12 核心 Skill 执行器
    
    将 361 个细粒度技能映射到 12 个产品级核心 Skill，
    统一输出 Schema，管理缓存和安全边界。
    """
    
    SKILL_VERSION = "2.0.0"
    
    def __init__(self, orchestrator: Optional[SkillOrchestrator] = None):
        self.orchestrator = orchestrator or SkillOrchestrator()
        self.validator = SchemaValidator()
        self.cache = SkillCache()
    
    # ============ 公共执行接口 ============
    
    async def execute(
        self,
        skill_name: str,
        input_data: CoreSkillInput,
    ) -> CoreSkillOutput:
        """
        执行指定核心 Skill
        
        Args:
            skill_name: 12 核心 Skill 之一
            input_data: 统一输入
        
        Returns:
            CoreSkillOutput（统一 Schema）
        """
        start_time = time.time()
        
        # 1. 检查缓存
        cached = self.cache.get(skill_name, input_data.user_id, input_data.task_params)
        if cached:
            cached.cached = True
            return cached
        
        # 2. 路由到具体执行方法
        method_map = {
            "DailyRhythmPlan": self._execute_daily_rhythm,
            "SleepWindDown": self._execute_sleep_winddown,
            "OfficeMicroBreak": self._execute_office_micro,
            "MoodFirstAid": self._execute_mood_first_aid,
            "SolarTermGuide": self._execute_solar_term,
            "BodyConstitutionLite": self._execute_body_constitution,
            "FoodTeaRecommender": self._execute_food_tea,
            "AcupressureRoutineLite": self._execute_acupressure,
            "FollowUpGenerator": self._execute_follow_up,
            "PresencePolicyDecider": self._execute_presence_policy,
            "CareStatusUpdater": self._execute_care_status,
            "FamilyCareDigest": self._execute_family_care,
        }
        
        method = method_map.get(skill_name)
        if not method:
            return self._build_error_output(skill_name, f"Unknown core skill: {skill_name}")
        
        try:
            output = await method(input_data)
        except Exception as e:
            logger.error(f"[CoreSkill] {skill_name} 执行失败: {e}")
            output = self._build_fallback_output(skill_name, input_data)
        
        # 3. 补充元数据
        output.version = self.SKILL_VERSION
        output.latency_ms = int((time.time() - start_time) * 1000)
        
        # 4. 保存缓存
        self.cache.set(skill_name, input_data.user_id, input_data.task_params, output)
        
        return output
    
    # ============ 各 Skill 具体实现 ============
    
    # 预设今日节律模板（按星期几 + 季节）
    DAILY_RHYTHM_TEMPLATES = {
        0: {  # 周一
            "theme": "启新",
            "emoji": "🌅",
            "insight": "新周伊始，身体还在适应从周末到工作日的节奏转换。今天重点在于温和启动，不要给自己太大压力。",
            "morning": ["早起喝一杯温开水，唤醒肠胃", "做5分钟颈部和肩部拉伸", "吃一份温热早餐，避免空腹出门"],
            "afternoon": ["午间小憩10-15分钟，恢复精力", "起身活动5分钟，远眺窗外绿植", "喝一杯淡茶，提神不伤胃"],
            "evening": ["晚餐清淡，七分饱即可", "睡前温水泡脚15分钟", "写下今天的一件小确幸，放松心情"],
            "focus": "温和启动，调整节奏",
        },
        1: {  # 周二
            "theme": "深耕",
            "emoji": "🌱",
            "insight": "身体已适应工作节奏，今天是效率最高的一天。把握这个能量高峰，同时注意劳逸结合。",
            "morning": ["早起做3分钟腹式呼吸，稳定心神", "吃富含蛋白质的食物（鸡蛋/豆浆）", "花2分钟规划今天最重要的三件事"],
            "afternoon": ["工作1小时后起身走动", "做眼保健操或20-20-20护眼法则", "吃点坚果或水果补充能量"],
            "evening": ["晚餐后散步20分钟，助消化", "睡前做温和的瑜伽或拉伸", "23点前放下手机，准备入睡"],
            "focus": "高效工作，注意护眼",
        },
        2: {  # 周三
            "theme": "平衡",
            "emoji": "⚖️",
            "insight": "一周过半，精力可能开始下降。今天是调整平衡点的好时机，注意补充能量和情绪调节。",
            "morning": ["比平常多睡10分钟，补偿精力", "早餐加入五谷杂粮，补充B族维生素", "出门前晒5分钟太阳，提升血清素"],
            "afternoon": ["午间小憩20分钟，给大脑充电", "喝一碗绿豆汤或银耳汤，滋阴润燥", "做几个深呼吸，缓解工作压力"],
            "evening": ["晚餐加入深色蔬菜，补充抗氧化物", "泡一个热水澡或淋浴，放松肌肉", "听轻音乐或白噪音，帮助入眠"],
            "focus": "补充能量，调节情绪",
        },
        3: {  # 周四
            "theme": "蓄力",
            "emoji": "🔋",
            "insight": "周末在望，但今天的坚持很重要。适当降低强度，为周末储备能量，避免过度消耗。",
            "morning": ["起床后喝一杯蜂蜜水，润肠通便", "做5分钟八段锦或太极起势", "早餐搭配一份水果，补充维生素"],
            "afternoon": ["下午茶时间，喝一杯花茶舒缓心情", "做肩颈按摩或热敷，缓解久坐疲劳", "整理桌面，营造清爽工作环境"],
            "evening": ["晚餐少吃淀粉，多吃蔬菜和蛋白质", "和家人聊聊天，或给朋友打个电话", "睡前做5分钟冥想，清空思绪"],
            "focus": "适度蓄力，社交充电",
        },
        4: {  # 周五
            "theme": "释然",
            "emoji": "🌸",
            "insight": "一周辛劳即将结束，今天要让身心逐渐放松。但不要过度放纵，为周末的健康节奏做铺垫。",
            "morning": ["带着轻松的心情起床", "早餐可以稍微丰富一点，奖励自己", "规划一个愉快的周末活动"],
            "afternoon": ["完成本周收尾工作，不要拖到周末", "喝一杯菊花茶，清肝明目", "提前整理下周待办清单，放空大脑"],
            "evening": ["晚餐可以稍微丰盛，但仍避免油腻", "看一部轻松的电影或读几页书", "比平时稍晚入睡不要超过1小时"],
            "focus": "收尾放松，周末铺垫",
        },
        5: {  # 周六
            "theme": "舒展",
            "emoji": "🌿",
            "insight": "周末第一天，是身体修复和心灵舒展的最佳时机。放慢节奏，做一些工作日没时间做的事。",
            "morning": ["睡到自然醒，但不要超过9点", "吃一顿悠闲的早午餐", "安排户外活动：公园散步、爬山、骑行"],
            "afternoon": ["尝试一项兴趣爱好：烹饪、园艺、手工", "和朋友或家人共度时光", "午休20-30分钟，补充精力"],
            "evening": ["晚餐可以稍微放松，但仍避免暴饮暴食", "泡一杯温热的养生茶", "早点休息，为周日养精蓄锐"],
            "focus": "户外舒展，兴趣充电",
        },
        6: {  # 周日
            "theme": "归藏",
            "emoji": "🌙",
            "insight": "周末收尾，是为新一周做准备的日子。今天重在回归内心，整理身心，迎接新的开始。",
            "morning": ["早起做15分钟温和运动（太极/瑜伽）", "吃一顿营养均衡的早餐", "花10分钟整理房间，清理杂物"],
            "afternoon": ["准备下周的衣物和物品", "读一本养生或心灵成长的书籍", "做一顿健康晚餐，为自己 cooking"],
            "evening": ["洗澡后做全身拉伸", "写下下周的三个小目标", "22:30前上床，确保8小时睡眠"],
            "focus": "整理归藏，迎接新周",
        },
    }

    SEASON_ADJUSTMENTS = {
        "春": {"tip": "春季养肝，多吃绿色蔬菜，保持心情愉悦", "food": "韭菜、菠菜、荠菜", "activity": "户外踏青，舒展筋骨"},
        "夏": {"tip": "夏季养心，避免暴晒，注意补充水分", "food": "苦瓜、绿豆、西瓜", "activity": "游泳、早晚散步"},
        "秋": {"tip": "秋季养肺，多吃润燥食物，注意保暖", "food": "梨、百合、银耳", "activity": "登山、慢跑"},
        "冬": {"tip": "冬季养肾，早睡晚起，适当进补", "food": "羊肉、核桃、黑芝麻", "activity": "室内太极、八段锦"},
    }

    def _get_season(self) -> str:
        """根据当前月份判断季节"""
        month = datetime.now().month
        if month in (3, 4, 5):
            return "春"
        elif month in (6, 7, 8):
            return "夏"
        elif month in (9, 10, 11):
            return "秋"
        return "冬"

    async def _execute_daily_rhythm(self, inp: CoreSkillInput) -> CoreSkillOutput:
        """今日节律 - 洞察 + 3行动 + 1卡片（预设模板为主，有 signals 时才调用 LLM）"""
        weekday = datetime.now().weekday()
        season = self._get_season()
        template = self.DAILY_RHYTHM_TEMPLATES[weekday]
        season_adj = self.SEASON_ADJUSTMENTS[season]
        
        # 只有在 signals 包含异常/复杂数据时才调用 LLM 个性化
        # 简单的 sleep_quality="good", mood="calm" 等正常状态不走 LLM
        _simple_values = {"good", "calm", "normal", "ok", "fine", "fair", "average", "moderate"}
        has_complex_signals = False
        if inp.signals:
            for key, val in inp.signals.items():
                if isinstance(val, (int, float)) and val < 5:  # 数值型低分
                    has_complex_signals = True
                    break
                if isinstance(val, str) and val.lower() not in _simple_values:
                    has_complex_signals = True
                    break
                if isinstance(val, (list, dict)) and val:
                    has_complex_signals = True
                    break
        
        if has_complex_signals:
            messages = [
                f"请为我生成今日养生计划。",
                f"用户阶段: {inp.user_context.get('life_stage', 'adult')}",
                f"日期: {inp.task_params.get('date', datetime.now().strftime('%Y-%m-%d'))}",
                f"信号数据: {json.dumps(inp.signals, ensure_ascii=False)}",
            ]
            result = await self._call_orchestrator(" ".join(messages), inp.user_context)
            text = result.final_response or f"今天的养生建议已经为你准备好了。"
            model_used = result.skills_executed[0].model if result.skills_executed else "fallback"
            tokens_used = result.total_tokens
        else:
            # 使用预设模板
            text = f"""🌿 **今日节律 | {template['theme']}**

{template['insight']}

**🌅 早间** {template['morning'][0]}
• {template['morning'][1]}
• {template['morning'][2]}

**☀️ 午间** {template['afternoon'][0]}
• {template['afternoon'][1]}
• {template['afternoon'][2]}

**🌙 晚间** {template['evening'][0]}
• {template['evening'][1]}
• {template['evening'][2]}

**{season}季调养** 🍃
{season_adj['tip']}
推荐食材：{season_adj['food']}
推荐活动：{season_adj['activity']}
"""
            model_used = "preset"
            tokens_used = 0
        
        return CoreSkillOutput(
            skill="DailyRhythmPlan",
            text=text,
            insight=Insight(
                title=f"今日节律 | {template['theme']}",
                content=template["insight"],
                emoji=template["emoji"],
            ),
            actions=[
                Action(time_period="morning", items=template["morning"]),
                Action(time_period="afternoon", items=template["afternoon"]),
                Action(time_period="evening", items=template["evening"]),
            ],
            cards=[ContentCard(
                type="suggestion",
                title=f"{season}季重点",
                content=season_adj["tip"],
                emoji="💡",
            )],
            safety_flag=SafetyFlag.NONE,
            presence_level=PresenceLevel.NORMAL,
            contraindications=["孕妇请咨询医生", "慢性病患者遵医嘱"],
            when_to_seek_help=None,
            model_used=model_used,
            tokens_used=tokens_used,
        )
    
    async def _execute_sleep_winddown(self, inp: CoreSkillInput) -> CoreSkillOutput:
        """睡前仪式 - 步骤 + 提示 + 安全标记"""
        params = inp.task_params
        duration = params.get("duration", 20)
        scenario = params.get("scenario", "general")
        
        result = await self._call_orchestrator(
            f"我睡不着，请帮我准备一个{duration}分钟的睡前仪式。场景: {scenario}",
            inp.user_context,
        )
        
        return CoreSkillOutput(
            skill="SleepWindDown",
            text=result.final_response or "让我们一起为今晚的睡眠做准备吧。",
            cards=[ContentCard(
                type="sleep",
                title=f"{duration}分钟睡前仪式",
                content="1. 调暗灯光\n2. 放下手机\n3. 深呼吸放松\n4. 温和拉伸",
                emoji="🌙",
                steps=[
                    "调暗卧室灯光，营造睡眠氛围",
                    "将手机放在伸手不可及的地方",
                    "做3分钟腹式呼吸（吸气4秒-屏息4秒-呼气6秒）",
                    "简单拉伸肩颈和腿部",
                ],
                duration_min=duration,
                contraindications=["严重失眠请就医", "服用安眠药期间遵医嘱"],
            )],
            safety_flag=SafetyFlag.NONE,
            presence_level=PresenceLevel.REDUCED,  # 睡前减少打扰
            contraindications=["严重失眠请就医", "服用安眠药期间遵医嘱"],
            when_to_seek_help="如果连续两周失眠且影响白天工作，建议就医。",
            model_used=result.skills_executed[0].model if result.skills_executed else "fallback",
            tokens_used=result.total_tokens,
        )
    
    async def _execute_office_micro(self, inp: CoreSkillInput) -> CoreSkillOutput:
        """办公室3分钟放松"""
        params = inp.task_params
        focus = params.get("focus_area", "shoulder")
        duration = params.get("duration", 3)
        space = params.get("space", "desk")
        
        result = await self._call_orchestrator(
            f"我在办公室，{focus}不舒服，请给我{duration}分钟的放松建议。空间: {space}",
            inp.user_context,
        )
        
        exercise_map = {
            "shoulder": ["耸肩-沉肩 x5", "颈部缓慢左右转动", "双手背后交叉拉伸"],
            "eye": ["20-20-20法则远眺", "闭眼掌心热敷", "眼球上下左右转动"],
            "breath": ["腹式呼吸 x5", "4-7-8呼吸法", "叹息式深呼气"],
        }
        
        return CoreSkillOutput(
            skill="OfficeMicroBreak",
            text=result.final_response or f"工作辛苦了，让我们用{duration}分钟放松一下{focus}吧。",
            cards=[ContentCard(
                type="exercise",
                title=f"办公室{duration}分钟放松",
                content=f"针对{focus}的简易放松动作",
                emoji="💼",
                steps=exercise_map.get(focus, exercise_map["shoulder"]),
                duration_min=duration,
                contraindications=["急性疼痛请停止", "手术后恢复期遵医嘱"],
            )],
            safety_flag=SafetyFlag.NONE,
            presence_level=PresenceLevel.NORMAL,
            contraindications=["急性疼痛请停止", "手术后恢复期遵医嘱"],
            when_to_seek_help=None,
            model_used=result.skills_executed[0].model if result.skills_executed else "fallback",
            tokens_used=result.total_tokens,
        )
    
    async def _execute_mood_first_aid(self, inp: CoreSkillInput) -> CoreSkillOutput:
        """情绪急救 - 安全边界最严格"""
        params = inp.task_params
        intensity = params.get("intensity", "low")
        trigger = params.get("trigger", "")
        
        result = await self._call_orchestrator(
            f"我心情不好，{trigger}",
            inp.user_context,
        )
        
        # 检测危机情绪
        crisis_keywords = ["想死", "自杀", "不想活", "结束一切", "活着没意思"]
        user_message = trigger.lower()
        is_crisis = any(kw in user_message for kw in crisis_keywords)
        
        safety = SafetyFlag.ESCALATE if is_crisis else SafetyFlag.NONE
        presence = PresenceLevel.SILENT if is_crisis else PresenceLevel.REDUCED
        
        text = result.final_response or "我理解你现在的感受，这很难受。"
        if is_crisis:
            text = "我听到你说这些，我很担心你。你并不孤单，有人愿意倾听。请拨打心理援助热线：400-161-9995"
        
        return CoreSkillOutput(
            skill="MoodFirstAid",
            text=text,
            cards=[ContentCard(
                type="suggestion",
                title="情绪急救箱",
                content="1. 深呼吸3次\n2. 喝一口温水\n3. 写下此刻感受" if not is_crisis else "请联系专业心理援助",
                emoji="🆘" if is_crisis else "💚",
                steps=[
                    "停下来，深呼吸3次（吸气4秒-呼气6秒）",
                    "喝一杯温水，感受温度",
                    "如果愿意，写下此刻的感受",
                ] if not is_crisis else [
                    "拨打 24小时心理援助热线：400-161-9995",
                    "告诉身边的信任的人你的感受",
                    "前往最近医院急诊科",
                ],
            )],
            safety_flag=safety,
            presence_level=presence,
            contraindications=["不替代专业心理咨询", "不诊断、不贴标签"],
            when_to_seek_help="如果情绪持续低落超过两周，或影响日常生活，请寻求专业帮助。",
            model_used=result.skills_executed[0].model if result.skills_executed else "fallback",
            tokens_used=result.total_tokens,
        )
    
    # 预设节气数据（避免每次调用 LLM）
    SOLAR_TERM_DATA = {
        "立春": {"dates": "2月4日前后", "proverb": "立春一日，百草回芽", "focus": "养肝护阳，疏肝理气", "foods": ["韭菜", "香菜", "葱", "春笋", "豆芽"], "activities": ["踏青", "散步", "舒展筋骨"], "sleep": "早睡早起，最晚23点前入睡"},
        "雨水": {"dates": "2月19日前后", "proverb": "春雨贵如油", "focus": "健脾祛湿，养护脾胃", "foods": ["山药", "薏米", "红枣", "菠菜", "蜂蜜"], "activities": ["室内运动", "太极", "八段锦"], "sleep": "保证充足睡眠，避免湿重困脾"},
        "惊蛰": {"dates": "3月5日前后", "proverb": "惊蛰雷鸣，万物生长", "focus": "养肝明目，清肝火", "foods": ["梨", "菠菜", "芹菜", "枸杞", "菊花"], "activities": ["户外散步", "慢跑", "放风筝"], "sleep": "早睡早起，避免熬夜伤肝"},
        "春分": {"dates": "3月20日前后", "proverb": "春分秋分，昼夜平分", "focus": "阴阳平衡，调和肝脾", "foods": ["荠菜", "香椿", "韭菜", "草莓", "菠菜"], "activities": ["春游", "登山", "户外太极"], "sleep": "早睡早起，中午可小憩15分钟"},
        "清明": {"dates": "4月4日前后", "proverb": "清明前后，种瓜点豆", "focus": "清肝明目，疏解情绪", "foods": ["荠菜", "艾草", "春笋", "菠菜", "绿豆"], "activities": ["踏青", "放风筝", "散步"], "sleep": "早睡早起，注意情绪调节"},
        "谷雨": {"dates": "4月20日前后", "proverb": "谷雨断霜", "focus": "健脾祛湿，养胃护肝", "foods": ["香椿", "菠菜", "薏米", "赤小豆", "山药"], "activities": ["户外徒步", "瑜伽", "游泳"], "sleep": "早睡早起，避免湿邪困脾"},
        "立夏": {"dates": "5月5日前后", "proverb": "立夏栽茄子，立秋吃茄子", "focus": "养心护阳，清淡饮食", "foods": ["绿豆", "苦瓜", "莲子", "百合", "西瓜"], "activities": ["晨练", "游泳", "散步"], "sleep": "晚睡早起，中午小憩30分钟"},
        "小满": {"dates": "5月21日前后", "proverb": "小满不满，芒种不管", "focus": "清热利湿，养护心脾", "foods": ["薏米", "赤小豆", "苦瓜", "冬瓜", "丝瓜"], "activities": ["游泳", "太极拳", "早晚散步"], "sleep": "晚睡早起，避免午后暴晒"},
        "芒种": {"dates": "6月5日前后", "proverb": "芒种看今日，螳螂应节生", "focus": "清热解暑，养心安神", "foods": ["绿豆", "西瓜", "苦瓜", "莲子", "百合"], "activities": ["晨练", "游泳", "傍晚散步"], "sleep": "晚睡早起，保证7小时睡眠"},
        "夏至": {"dates": "6月21日前后", "proverb": "夏至一阴生", "focus": "养阴清热，养护心肾", "foods": ["西瓜", "绿豆", "苦瓜", "黄瓜", "荷叶"], "activities": ["游泳", "早晚散步", "室内瑜伽"], "sleep": "晚睡早起，中午必须午休"},
        "小暑": {"dates": "7月7日前后", "proverb": "小暑大暑，上蒸下煮", "focus": "清热解暑，健脾开胃", "foods": ["西瓜", "苦瓜", "冬瓜", "绿豆汤", "莲子"], "activities": ["游泳", "早晚散步", "室内运动"], "sleep": "晚睡早起，避免熬夜伤阴"},
        "大暑": {"dates": "7月22日前后", "proverb": "大暑热不透，大热在秋后", "focus": "清热祛湿，养护心脾", "foods": ["绿豆汤", "西瓜", "苦瓜", "薏米", "冬瓜"], "activities": ["游泳", "早晚散步", "静坐"], "sleep": "晚睡早起，中午午休30分钟"},
        "立秋": {"dates": "8月7日前后", "proverb": "立秋之日凉风至", "focus": "养肺润燥，滋阴清热", "foods": ["梨", "百合", "银耳", "芝麻", "蜂蜜"], "activities": ["登山", "慢跑", "太极拳"], "sleep": "早睡早起，收敛阳气"},
        "处暑": {"dates": "8月23日前后", "proverb": "处暑不出头，割了喂老牛", "focus": "养阴润燥，健脾祛湿", "foods": ["梨", "百合", "山药", "银耳", "莲子"], "activities": ["登山", "慢跑", "八段锦"], "sleep": "早睡早起，避免秋燥伤肺"},
        "白露": {"dates": "9月7日前后", "proverb": "白露身不露", "focus": "养肺润燥，滋阴养肾", "foods": ["梨", "百合", "山药", "芝麻", "核桃"], "activities": ["登山", "太极", "早晚散步"], "sleep": "早睡早起，注意保暖"},
        "秋分": {"dates": "9月23日前后", "proverb": "秋分只怕雷电闪", "focus": "阴阳平衡，养肺润燥", "foods": ["梨", "百合", "银耳", "山药", "蜂蜜"], "activities": ["登山", "慢跑", "户外瑜伽"], "sleep": "早睡早起，收敛神气"},
        "寒露": {"dates": "10月8日前后", "proverb": "寒露脚不露", "focus": "养肺润燥，温补脾肾", "foods": ["山药", "核桃", "板栗", "红枣", "芝麻"], "activities": ["登山", "太极", "八段锦"], "sleep": "早睡早起，注意足部保暖"},
        "霜降": {"dates": "10月23日前后", "proverb": "霜降无雨，暖到立冬", "focus": "温补脾胃，养肺润燥", "foods": ["山药", "板栗", "柿子", "核桃", "羊肉"], "activities": ["太极", "八段锦", "室内运动"], "sleep": "早睡晚起，避寒就温"},
        "立冬": {"dates": "11月7日前后", "proverb": "立冬补冬，补嘴空", "focus": "温补肾阳，藏精纳气", "foods": ["羊肉", "韭菜", "核桃", "黑芝麻", "栗子"], "activities": ["室内运动", "太极", "八段锦"], "sleep": "早睡晚起，保证充足睡眠"},
        "小雪": {"dates": "11月22日前后", "proverb": "小雪雪满天，来年必丰年", "focus": "温补肾阳，养心安神", "foods": ["羊肉", "牛肉", "核桃", "黑芝麻", "红枣"], "activities": ["室内运动", "太极", "瑜伽"], "sleep": "早睡晚起，注意防寒"},
        "大雪": {"dates": "12月7日前后", "proverb": "大雪冬至后，篮装水不漏", "focus": "温补元气，养肾藏精", "foods": ["羊肉", "狗肉", "核桃", "黑芝麻", "枸杞"], "activities": ["室内太极", "八段锦", "静坐"], "sleep": "早睡晚起，避免寒邪入侵"},
        "冬至": {"dates": "12月22日前后", "proverb": "冬至一阳生", "focus": "温补肾阳，养护心脾", "foods": ["羊肉", "饺子", "汤圆", "核桃", "黑芝麻"], "activities": ["室内运动", "泡脚", "静坐"], "sleep": "早睡晚起，养藏为主"},
        "小寒": {"dates": "1月5日前后", "proverb": "小寒大寒，冷成冰团", "focus": "温阳散寒，养护脾肾", "foods": ["羊肉", "生姜", "桂圆", "红枣", "核桃"], "activities": ["室内运动", "泡脚", "艾灸"], "sleep": "早睡晚起，注意保暖"},
        "大寒": {"dates": "1月20日前后", "proverb": "大寒到顶点，日后天渐暖", "focus": "温阳补气，养肾藏精", "foods": ["羊肉", "牛肉", "生姜", "桂圆", "红枣"], "activities": ["室内太极", "八段锦", "泡脚"], "sleep": "早睡晚起，养藏为主"},
    }

    def _get_current_solar_term(self) -> str:
        """根据当前日期推断节气"""
        from datetime import datetime
        month = datetime.now().month
        day = datetime.now().day
        
        term_dates = [
            (2, 4, "立春"), (2, 19, "雨水"), (3, 5, "惊蛰"), (3, 20, "春分"),
            (4, 4, "清明"), (4, 20, "谷雨"), (5, 5, "立夏"), (5, 21, "小满"),
            (6, 5, "芒种"), (6, 21, "夏至"), (7, 7, "小暑"), (7, 22, "大暑"),
            (8, 7, "立秋"), (8, 23, "处暑"), (9, 7, "白露"), (9, 23, "秋分"),
            (10, 8, "寒露"), (10, 23, "霜降"), (11, 7, "立冬"), (11, 22, "小雪"),
            (12, 7, "大雪"), (12, 22, "冬至"), (1, 5, "小寒"), (1, 20, "大寒"),
        ]
        
        current = "立春"
        for m, d, term in term_dates:
            if (month > m) or (month == m and day >= d):
                current = term
        return current

    async def _execute_solar_term(self, inp: CoreSkillInput) -> CoreSkillOutput:
        """节气指南 - 使用预设数据，避免每次调用 LLM"""
        params = inp.task_params
        term = params.get("solar_term", "")
        if not term:
            term = self._get_current_solar_term()
        
        data = self.SOLAR_TERM_DATA.get(term)
        if not data:
            # 回退到通用内容
            return CoreSkillOutput(
                skill="SolarTermGuide",
                text=f"{term}到了，顺应节气调养身体。建议：早睡早起，饮食清淡，适度运动。",
                cards=[
                    ContentCard(type="diet", title=f"{term}饮食", content="顺应节气选择当季食材", emoji="🥬"),
                    ContentCard(type="suggestion", title=f"{term}起居", content="早睡早起，适度运动", emoji="🏠"),
                ],
                safety_flag=SafetyFlag.NONE,
                presence_level=PresenceLevel.NORMAL,
                contraindications=["体质特殊者请咨询中医"],
                when_to_seek_help=None,
                model_used="preset",
                tokens_used=0,
            )
        
        # 构建高质量预设内容
        foods_str = "、".join(data["foods"])
        activities_str = "、".join(data["activities"])
        
        text = f"""🌿 **{term}** ({data['dates']})

*{data['proverb']}*

{term}已至，养生重点：**{data['focus']}**。

**饮食建议** 🥬
宜食：{foods_str}。顺应节气选择当季食材，少酸多甘，养护脾胃。

**起居调养** 🏠
{data['sleep']}。{activities_str}，顺应自然规律。

**今日宜做**
• 晨起喝一杯温开水，唤醒脾胃
• 适当户外活动，吸收自然之气
• 保持心情愉悦，肝喜条达
• 睡前温水泡脚，引火下行

**给你的小建议** 💡
节气交替之时，最易感受外邪。注意增减衣物，尤其护好颈背和腹部。如有任何身体不适，请及时咨询医生。
"""
        
        return CoreSkillOutput(
            skill="SolarTermGuide",
            text=text,
            cards=[
                ContentCard(type="diet", title=f"{term}饮食", content=f"宜食：{foods_str}", emoji="🥬"),
                ContentCard(type="suggestion", title=f"{term}起居", content=data["sleep"], emoji="🏠"),
                ContentCard(type="exercise", title=f"{term}运动", content=activities_str, emoji="🚶"),
            ],
            safety_flag=SafetyFlag.NONE,
            presence_level=PresenceLevel.NORMAL,
            contraindications=["体质特殊者请咨询中医", "孕妇及慢性病患者请遵医嘱"],
            when_to_seek_help=None,
            model_used="preset",
            tokens_used=0,
        )
    
    async def _execute_body_constitution(self, inp: CoreSkillInput) -> CoreSkillOutput:
        """体质轻推断 - 必须带免责声明"""
        params = inp.task_params
        answers = params.get("answers", [])
        symptoms = params.get("symptoms", "")
        
        result = await self._call_orchestrator(
            f"请帮我分析体质。症状描述: {symptoms}",
            inp.user_context,
        )
        
        return CoreSkillOutput(
            skill="BodyConstitutionLite",
            text=result.final_response or "根据你的描述，初步分析如下。",
            cards=[ContentCard(
                type="suggestion",
                title="体质调理建议",
                content="饮食、运动、作息综合调理",
                emoji="⚖️",
                steps=[
                    "记录一周的睡眠、饮食、情绪状态",
                    "根据体质类型调整饮食结构",
                    "选择适合的运动方式",
                ],
            )],
            safety_flag=SafetyFlag.NONE,
            presence_level=PresenceLevel.NORMAL,
            contraindications=["只说'倾向于'，不说'你是'", "不开药方"],
            when_to_seek_help="如有明显不适，建议到正规医院中医科就诊。",
            model_used=result.skills_executed[0].model if result.skills_executed else "fallback",
            tokens_used=result.total_tokens,
        )
    
    async def _execute_food_tea(self, inp: CoreSkillInput) -> CoreSkillOutput:
        """食疗/茶饮生成"""
        params = inp.task_params
        req_type = params.get("type", "diet")  # diet | tea | soup
        goal = params.get("goal", "")
        constraints = params.get("constraints", [])
        
        result = await self._call_orchestrator(
            f"请推荐{req_type}，目标: {goal}，禁忌: {', '.join(constraints)}",
            inp.user_context,
        )
        
        card_type = "tea" if req_type == "tea" else "diet"
        
        return CoreSkillOutput(
            skill="FoodTeaRecommender",
            text=result.final_response or f"为你推荐适合的{req_type}方案。",
            cards=[ContentCard(
                type=card_type,
                title=f"推荐{req_type}",
                content="具体配方和做法",
                emoji="🍵" if req_type == "tea" else "🥣",
                steps=[
                    "准备食材",
                    "按步骤烹饪",
                    "注意食用时间和量",
                ],
            )],
            safety_flag=SafetyFlag.NONE,
            presence_level=PresenceLevel.NORMAL,
            contraindications=constraints or ["过敏体质请谨慎", "孕妇遵医嘱"],
            when_to_seek_help=None,
            model_used=result.skills_executed[0].model if result.skills_executed else "fallback",
            tokens_used=result.total_tokens,
        )
    
    async def _execute_acupressure(self, inp: CoreSkillInput) -> CoreSkillOutput:
        """穴位按揉流程"""
        params = inp.task_params
        target = params.get("target", "relaxation")
        duration = params.get("duration", 10)
        
        result = await self._call_orchestrator(
            f"请推荐穴位按摩，目标: {target}，时长: {duration}分钟",
            inp.user_context,
        )
        
        return CoreSkillOutput(
            skill="AcupressureRoutineLite",
            text=result.final_response or "穴位按摩是简便有效的自我保健方法。",
            cards=[ContentCard(
                type="acupoint",
                title=f"{target}穴位按揉",
                content="推荐穴位及按摩方法",
                emoji="👆",
                steps=[
                    "找准穴位位置",
                    "用拇指指腹按压",
                    "每穴按压1-2分钟，力度适中",
                    "按摩后喝温水",
                ],
                duration_min=duration,
                contraindications=["皮肤破损处禁按", "孕妇部分穴位禁忌"],
            )],
            safety_flag=SafetyFlag.NONE,
            presence_level=PresenceLevel.NORMAL,
            contraindications=["皮肤破损处禁按", "孕妇部分穴位禁忌", "饭后一小时内不宜"],
            when_to_seek_help="如按压后疼痛加重或出现淤青，请停止并就医。",
            model_used=result.skills_executed[0].model if result.skills_executed else "fallback",
            tokens_used=result.total_tokens,
        )
    
    async def _execute_follow_up(self, inp: CoreSkillInput) -> CoreSkillOutput:
        """轻跟进生成"""
        params = inp.task_params
        check_type = params.get("type", "check_in")
        pending_topics = inp.signals.get("pending_topics", []) if inp.signals else []
        
        if not pending_topics:
            return CoreSkillOutput(
                skill="FollowUpGenerator",
                text="",
                safety_flag=SafetyFlag.NONE,
                presence_level=PresenceLevel.SILENT,
                follow_up=None,
            )
        
        topic = pending_topics[0]
        result = await self._call_orchestrator(
            f"跟进之前的话题: {topic}",
            inp.user_context,
        )
        
        return CoreSkillOutput(
            skill="FollowUpGenerator",
            text=result.final_response or f"上次聊到{topic}，最近怎么样？",
            follow_up=FollowUp(
                type=check_type,
                message=f"上次聊到{topic}，最近怎么样？",
                in_days=3,
            ),
            safety_flag=SafetyFlag.NONE,
            presence_level=PresenceLevel.NORMAL,
            contraindications=[],
            when_to_seek_help=None,
            model_used=result.skills_executed[0].model if result.skills_executed else "fallback",
            tokens_used=result.total_tokens,
        )
    
    async def _execute_presence_policy(self, inp: CoreSkillInput) -> CoreSkillOutput:
        """退让策略 - 知道何时不打扰用户（新增核心技能）"""
        params = inp.task_params
        signals = inp.signals or {}
        
        # 获取用户状态信号
        last_active = signals.get("last_active", datetime.now().isoformat())
        interaction_count = signals.get("interaction_count", 0)
        care_status = signals.get("care_status", "stable")
        quiet_hours = inp.user_context.get("quiet_hours", {"start": 22, "end": 7})
        
        now = datetime.now()
        current_hour = now.hour
        
        # 决策逻辑
        is_quiet = quiet_hours["start"] <= current_hour or current_hour < quiet_hours["end"]
        is_overwhelmed = interaction_count > 10 and care_status == "tired"
        
        if is_quiet:
            decision = {
                "should_reach": False,
                "reason": "用户在安静时段",
                "recommended_channels": [],
                "presence_level": PresenceLevel.SILENT,
            }
        elif is_overwhelmed:
            decision = {
                "should_reach": False,
                "reason": "用户今日互动过多，需要空间",
                "recommended_channels": [],
                "presence_level": PresenceLevel.REDUCED,
            }
        elif care_status == "crisis":
            decision = {
                "should_reach": True,
                "reason": "用户处于危机状态，需要关怀",
                "recommended_channels": ["push", "in_app"],
                "presence_level": PresenceLevel.NORMAL,
            }
        else:
            decision = {
                "should_reach": True,
                "reason": "正常触达",
                "recommended_channels": ["in_app"],
                "presence_level": PresenceLevel.NORMAL,
            }
        
        return CoreSkillOutput(
            skill="PresencePolicyDecider",
            text="" if not decision["should_reach"] else "根据你的状态，顺时选择适时陪伴。",
            safety_flag=SafetyFlag.NONE,
            presence_level=decision["presence_level"],
            contraindications=[],
            when_to_seek_help=None,
            model_used="rule_engine",
            tokens_used=0,
        )
    
    async def _execute_care_status(self, inp: CoreSkillInput) -> CoreSkillOutput:
        """照护状态机"""
        params = inp.task_params
        signals = inp.signals or {}
        
        recent_messages = signals.get("recent_messages", [])
        sleep_trend = signals.get("sleep_trend", "stable")
        interaction_freq = signals.get("interaction_frequency", "normal")
        
        # 简单状态评估
        if sleep_trend == "worsening" and interaction_freq == "low":
            overall = "needs_attention"
            emotion_trend = "declining"
            care_level = "enhanced"
        elif sleep_trend == "improving":
            overall = "stable"
            emotion_trend = "improving"
            care_level = "normal"
        else:
            overall = "stable"
            emotion_trend = "stable"
            care_level = "normal"
        
        return CoreSkillOutput(
            skill="CareStatusUpdater",
            text=f"你的照护状态已更新：{overall}。",
            insight=Insight(
                title="照护状态",
                content=f"整体状态: {overall}\n情绪趋势: {emotion_trend}\n建议照护级别: {care_level}",
                emoji="💚" if overall == "stable" else "💛",
            ),
            safety_flag=SafetyFlag.NONE,
            presence_level=PresenceLevel.NORMAL,
            contraindications=[],
            when_to_seek_help=None,
            model_used="rule_engine",
            tokens_used=0,
        )
    
    async def _execute_family_care(self, inp: CoreSkillInput) -> CoreSkillOutput:
        """家庭可感知摘要"""
        params = inp.task_params
        family_members = params.get("family_members", [])
        
        result = await self._call_orchestrator(
            f"生成家庭健康摘要。家庭成员: {len(family_members)}人",
            inp.user_context,
        )
        
        return CoreSkillOutput(
            skill="FamilyCareDigest",
            text=result.final_response or "家人的健康状态一览。",
            cards=[ContentCard(
                type="suggestion",
                title="家庭健康摘要",
                content="各成员健康状态及关怀建议",
                emoji="🏠",
                steps=[
                    "查看各成员近期健康趋势",
                    "关注异常提醒",
                    "适时发送关怀消息",
                ],
            )],
            safety_flag=SafetyFlag.NONE,
            presence_level=PresenceLevel.NORMAL,
            contraindications=["家庭共享需获得成员同意", "敏感信息注意隐私"],
            when_to_seek_help="如家庭成员出现紧急健康状况，请立即就医。",
            model_used=result.skills_executed[0].model if result.skills_executed else "fallback",
            tokens_used=result.total_tokens,
        )
    
    # ============ 辅助方法 ============
    
    async def _call_orchestrator(
        self,
        message: str,
        user_context: Dict[str, Any],
    ) -> SkillExecutionResult:
        """调用底层 Orchestrator"""
        try:
            return await self.orchestrator.execute(
                user_message=message,
                user_context=user_context,
            )
        except Exception as e:
            logger.warning(f"[CoreSkill] Orchestrator 调用失败: {e}")
            # 返回空结果
            from .orchestrator import SkillExecutionResult
            return SkillExecutionResult(
                status=OrchestrationStatus.FAILED,
                skills_executed=[],
                final_response="",
                total_tokens=0,
                total_latency_ms=0,
            )
    
    def _build_fallback_output(self, skill_name: str, inp: CoreSkillInput) -> CoreSkillOutput:
        """构建兜底输出"""
        from .executor import get_fallback_response
        
        fallback_text = get_fallback_response(skill_name.lower())
        
        return CoreSkillOutput(
            skill=skill_name,
            text=fallback_text,
            safety_flag=SafetyFlag.NONE,
            presence_level=PresenceLevel.NORMAL,
            contraindications=[],
            when_to_seek_help=None,
            model_used="fallback",
            tokens_used=0,
        )
    
    def _build_error_output(self, skill_name: str, error: str) -> CoreSkillOutput:
        """构建错误输出"""
        return CoreSkillOutput(
            skill=skill_name,
            text="抱歉，我现在有点困，让我休息一下再陪你聊天好吗？",
            safety_flag=SafetyFlag.NONE,
            presence_level=PresenceLevel.LOW if hasattr(PresenceLevel, "LOW") else PresenceLevel.REDUCED,
            contraindications=[],
            when_to_seek_help=None,
            model_used="error",
            tokens_used=0,
        )


# ==================== 全局实例 ====================

core_skill_executor = CoreSkillExecutor()


def init_core_skill_executor(orchestrator: SkillOrchestrator):
    """初始化核心 Skill 执行器"""
    global core_skill_executor
    core_skill_executor = CoreSkillExecutor(orchestrator=orchestrator)
    logger.info("[CoreSkill] 核心 Skill 执行器已初始化")
