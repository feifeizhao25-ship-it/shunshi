"""
顺时 12 核心 Skills API 路由
Core Skills API - 统一 Schema 输出

端点:
- POST /api/v1/core-skills/run          - 执行指定核心 Skill
- POST /api/v1/core-skills/chat         - 智能路由（消息 → Skill）
- GET  /api/v1/core-skills/list         - 12 核心 Skill 列表
- POST /api/v1/core-skills/batch        - 批量执行多个 Skill

作者: Claw 🦅
日期: 2026-04-29
"""

from typing import Optional, Dict, Any, List
from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel, Field

from ..skills.core_skills import (
    core_skill_executor,
    CoreSkillInput,
    CoreSkillOutput,
    SafetyFlag,
    PresenceLevel,
)

from ..skill_access import SkillAccess, get_skill_access

router = APIRouter(prefix="/api/v1/core-skills", tags=["核心 Skills"])


# ==================== 请求/响应模型 ====================

class CoreSkillRunRequest(BaseModel):
    """核心 Skill 执行请求"""
    skill: str = Field(..., description="核心 Skill 名称: DailyRhythmPlan | SleepWindDown | OfficeMicroBreak | MoodFirstAid | SolarTermGuide | BodyConstitutionLite | FoodTeaRecommender | AcupressureRoutineLite | FollowUpGenerator | PresencePolicyDecider | CareStatusUpdater | FamilyCareDigest")
    user_id: str
    user_context: Dict[str, Any] = Field(default_factory=dict)
    task_params: Dict[str, Any] = Field(default_factory=dict)
    signals: Optional[Dict[str, Any]] = None
    locale: str = "zh-CN"


class CoreSkillChatRequest(BaseModel):
    """智能路由聊天请求（消息 → 自动匹配 Skill）"""
    user_id: str
    message: str
    user_context: Dict[str, Any] = Field(default_factory=dict)
    signals: Optional[Dict[str, Any]] = None
    locale: str = "zh-CN"


class CoreSkillResponse(BaseModel):
    """核心 Skill 统一响应"""
    success: bool = True
    data: Dict[str, Any]


class CoreSkillListItem(BaseModel):
    """核心 Skill 列表项"""
    skill: str
    name: str
    description: str
    category: str
    is_premium: bool
    cache_ttl_hours: int


class CoreSkillListResponse(BaseModel):
    """核心 Skill 列表响应"""
    skills: List[CoreSkillListItem]


# ==================== 意图 → Skill 路由规则 ====================

INTENT_SKILL_MAP = [
    # (关键词列表, Skill 名称, 置信度阈值)
    (["今天怎么样", "今日计划", "今天怎么安排", "今日节律"], "DailyRhythmPlan", 0.7),
    (["睡不着", "失眠", "睡前", "睡觉", "入睡"], "SleepWindDown", 0.8),
    (["肩膀酸", "眼睛累", "上班累", "办公室", "久坐", "脖子僵"], "OfficeMicroBreak", 0.7),
    (["心情不好", "烦", "压力大", "焦虑", "难过", "郁闷", "累"], "MoodFirstAid", 0.7),
    (["节气", "立春", "惊蛰", "春分", "清明", "谷雨", "立夏", "小满", "芒种", "夏至", "小暑", "大暑", "立秋", "处暑", "白露", "秋分", "寒露", "霜降", "立冬", "小雪", "大雪", "冬至", "小寒", "大寒"], "SolarTermGuide", 0.9),
    (["体质", "我是什么体质", "气虚", "阳虚", "阴虚", "痰湿", "湿热", "血瘀", "气郁", "特禀"], "BodyConstitutionLite", 0.8),
    (["吃什么", "食疗", "茶饮", "喝什么", "养生茶", "药膳"], "FoodTeaRecommender", 0.7),
    (["穴位", "按揉", "按摩", "按哪里", "酸痛", "不舒服"], "AcupressureRoutineLite", 0.7),
    (["最近怎么样", "上次", "跟进", "后来", "怎么样了"], "FollowUpGenerator", 0.6),
    (["家人", "父母", "爸妈", "老公", "老婆", "孩子", "家庭"], "FamilyCareDigest", 0.7),
]


def _classify_intent(message: str) -> tuple[str, float]:
    """
    简单意图分类（基于关键词匹配）
    
    Returns:
        (skill_name, confidence)
    """
    message_lower = message.lower()
    
    best_skill = "DailyRhythmPlan"
    best_confidence = 0.0
    
    for keywords, skill, threshold in INTENT_SKILL_MAP:
        match_count = sum(1 for kw in keywords if kw in message_lower)
        if match_count > 0:
            confidence = min(threshold + (match_count - 1) * 0.05, 1.0)
            if confidence >= threshold and confidence > best_confidence:
                best_skill = skill
                best_confidence = confidence
    
    return best_skill, best_confidence


PREMIUM_CORE_SKILLS = {"BodyConstitutionLite", "FoodTeaRecommender", "FamilyCareDigest"}
VALID_CORE_SKILLS = {
    "DailyRhythmPlan", "SleepWindDown", "OfficeMicroBreak", "MoodFirstAid",
    "SolarTermGuide", "BodyConstitutionLite", "FoodTeaRecommender",
    "AcupressureRoutineLite", "FollowUpGenerator", "PresencePolicyDecider",
    "CareStatusUpdater", "FamilyCareDigest",
}

def _authorize_core(access: SkillAccess, user_id: str, skill: str):
    if skill not in VALID_CORE_SKILLS:
        raise HTTPException(status_code=400, detail="请选择有效的能力")
    access.require(user_id, skill in PREMIUM_CORE_SKILLS)


# ==================== API 端点 ====================

@router.post("/run", response_model=CoreSkillResponse)
async def run_core_skill(request: CoreSkillRunRequest, access: SkillAccess = Depends(get_skill_access)):
    """
    执行指定核心 Skill
    
    根据 skill 名称执行对应的核心 Skill，返回统一 Schema 输出。
    """
    _authorize_core(access, request.user_id, request.skill)

    input_data = CoreSkillInput(
        user_id=request.user_id,
        user_context=request.user_context,
        task_params=request.task_params,
        signals=request.signals,
        locale="zh-CN",
    )
    
    try:
        output = await core_skill_executor.execute(request.skill, input_data)
        return CoreSkillResponse(
            success=True,
            data=output.to_dict(),
        )
    except Exception:
        raise HTTPException(status_code=503, detail="能力服务暂时不可用，请稍后重试") from None


@router.post("/chat", response_model=CoreSkillResponse)
async def chat_core_skill(request: CoreSkillChatRequest, access: SkillAccess = Depends(get_skill_access)):
    """
    智能路由聊天（消息 → 自动匹配 Skill）
    
    根据用户消息自动识别意图，路由到对应的核心 Skill 执行。
    """
    if not request.message.strip():
        raise HTTPException(status_code=400, detail="请输入问题")
    skill_name, confidence = _classify_intent(request.message)
    _authorize_core(access, request.user_id, skill_name)
    
    input_data = CoreSkillInput(
        user_id=request.user_id,
        user_context=request.user_context,
        task_params={"message": request.message, "confidence": confidence},
        signals=request.signals,
        locale="zh-CN",
    )
    
    try:
        output = await core_skill_executor.execute(skill_name, input_data)
        
        result = output.to_dict()
        result["_routing"] = {
            "skill": skill_name,
            "confidence": confidence,
            "method": "keyword_rules",
            "confidence_is_probability": False,
            "message": request.message,
        }
        
        return CoreSkillResponse(
            success=True,
            data=result,
        )
    except Exception:
        raise HTTPException(status_code=503, detail="对话服务暂时不可用，请稍后重试") from None


@router.get("/list", response_model=CoreSkillListResponse)
async def list_core_skills():
    """
    获取 12 核心 Skill 列表
    
    返回所有核心 Skill 的元信息。
    """
    skills = [
        CoreSkillListItem(
            skill="DailyRhythmPlan",
            name="今日节律",
            description="每日首页核心内容 - 洞察 + 3行动 + 1卡片",
            category="daily_plan",
            is_premium=False,
            cache_ttl_hours=24,
        ),
        CoreSkillListItem(
            skill="SleepWindDown",
            name="睡前仪式",
            description="睡前放松仪式 - 步骤 + 提示 + 安全标记",
            category="sleep",
            is_premium=False,
            cache_ttl_hours=12,
        ),
        CoreSkillListItem(
            skill="OfficeMicroBreak",
            name="办公室微放松",
            description="办公室3分钟放松 - 部位针对性",
            category="exercise",
            is_premium=False,
            cache_ttl_hours=6,
        ),
        CoreSkillListItem(
            skill="MoodFirstAid",
            name="情绪急救",
            description="情绪急救 - 严格安全边界",
            category="emotion",
            is_premium=False,
            cache_ttl_hours=0,
        ),
        CoreSkillListItem(
            skill="SolarTermGuide",
            name="节气指南",
            description="节气养生指南 - 谚语 + 重点 + 饮食 + 生活",
            category="season",
            is_premium=False,
            cache_ttl_hours=360,
        ),
        CoreSkillListItem(
            skill="BodyConstitutionLite",
            name="体质轻推断",
            description="体质轻推断 - 免责声明 + 倾向性",
            category="constitution",
            is_premium=True,
            cache_ttl_hours=720,
        ),
        CoreSkillListItem(
            skill="FoodTeaRecommender",
            name="食疗茶饮推荐",
            description="食疗/茶饮生成 - 配方 + 功效 + 禁忌",
            category="diet",
            is_premium=True,
            cache_ttl_hours=24,
        ),
        CoreSkillListItem(
            skill="AcupressureRoutineLite",
            name="穴位按揉流程",
            description="穴位按揉流程 - 位置 + 方法 + 时长",
            category="acupoint",
            is_premium=False,
            cache_ttl_hours=12,
        ),
        CoreSkillListItem(
            skill="FollowUpGenerator",
            name="轻跟进生成",
            description="轻跟进生成 - 话题延续",
            category="follow_up",
            is_premium=False,
            cache_ttl_hours=0,
        ),
        CoreSkillListItem(
            skill="PresencePolicyDecider",
            name="退让策略",
            description="知道何时不打扰用户 - 智能触达决策",
            category="meta",
            is_premium=False,
            cache_ttl_hours=1,
        ),
        CoreSkillListItem(
            skill="CareStatusUpdater",
            name="照护状态机",
            description="照护状态更新 - 多维度评估",
            category="follow_up",
            is_premium=False,
            cache_ttl_hours=2,
        ),
        CoreSkillListItem(
            skill="FamilyCareDigest",
            name="家庭可感知摘要",
            description="家庭健康摘要 - 成员状态 + 关怀建议",
            category="family",
            is_premium=True,
            cache_ttl_hours=6,
        ),
    ]
    
    return CoreSkillListResponse(skills=skills)


@router.post("/batch", response_model=CoreSkillResponse)
async def batch_core_skills(requests: List[CoreSkillRunRequest], access: SkillAccess = Depends(get_skill_access)):
    """
    批量执行多个核心 Skill
    
    用于需要同时获取多个 Skill 结果的场景（如首页加载）。
    """
    if not requests or len(requests) > 12 or len({req.skill for req in requests}) != len(requests):
        raise HTTPException(status_code=400, detail="每次请选择 1 至 12 项不同的能力")
    for req in requests:
        _authorize_core(access, req.user_id, req.skill)
    results = {}
    
    for req in requests:
        input_data = CoreSkillInput(
            user_id=req.user_id,
            user_context=req.user_context,
            task_params=req.task_params,
            signals=req.signals,
            locale="zh-CN",
        )
        
        try:
            output = await core_skill_executor.execute(req.skill, input_data)
            results[req.skill] = output.to_dict()
        except Exception:
            results[req.skill] = {
                "skill": req.skill,
                "error": "能力服务暂时不可用，请稍后重试",
                "success": False,
            }
    
    return CoreSkillResponse(
        success=all(item.get("success", True) for item in results.values()),
        data={"results": results, "count": len(results)},
    )
