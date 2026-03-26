"""
顺时 Skills API 路由
提供 Skill 的查询、执行、分类、统计等接口

端点:
- GET  /api/v1/skills              - Skill 列表
- GET  /api/v1/skills/{skill_id}   - Skill 详情
- POST /api/v1/skills/execute       - 执行 Skill
- GET  /api/v1/skills/categories    - 分类树
- GET  /api/v1/skills/stats         - 使用统计
- POST /api/v1/skills/daily-plan    - 今日养生计划

作者: Claw 🦅
日期: 2026-03-17
"""

from typing import Optional, Dict, Any, List
from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel, Field

from ..skills.skill_registry import skill_registry
from ..skills.orchestrator import SkillOrchestrator, SkillExecutionResult

router = APIRouter()


# ==================== 请求/响应模型 ====================

class SkillSummary(BaseModel):
    """Skill 摘要"""
    skill_id: str
    category: str
    name: str
    description: str
    priority: str
    recommended_model: str
    is_premium: bool
    tags: List[str] = []


class SkillDetail(BaseModel):
    """Skill 详情"""
    skill_id: str
    category: str
    name: str
    description: str
    version: str
    priority: str
    required_context: List[str]
    tags: List[str]
    output_schema: Dict[str, Any]
    recommended_model: str
    max_tokens: int
    is_premium: bool
    cooldown_hours: int
    dependencies: List[str]


class CategoryInfo(BaseModel):
    """分类信息"""
    category: str
    skill_count: int
    p0_count: int
    premium_count: int
    sample_skills: List[str]


class ExecuteRequest(BaseModel):
    """Skill 执行请求"""
    user_id: str
    message: str
    context: Optional[Dict[str, Any]] = None
    skill_ids: Optional[List[str]] = None  # 可指定特定 Skill


class ExecuteResponse(BaseModel):
    """Skill 执行响应"""
    status: str
    final_response: str
    skills_executed: List[Dict[str, Any]]
    total_tokens: int
    total_latency_ms: int
    safety_flag: str = "none"
    follow_up: Optional[Dict[str, Any]] = None


class DailyPlanRequest(BaseModel):
    """今日计划请求"""
    user_id: str
    context: Optional[Dict[str, Any]] = None
    plan_type: str = "light"  # light / deep / emotion / sleep / constitution / season


class StatsResponse(BaseModel):
    """统计响应"""
    total_skills: int
    category_counts: Dict[str, int]
    priority_counts: Dict[str, int]
    premium_count: int
    free_count: int


# ==================== 全局 Orchestrator（懒加载） ====================

_orchestrator: Optional[SkillOrchestrator] = None


def get_orchestrator() -> SkillOrchestrator:
    """获取或创建 Orchestrator 实例"""
    global _orchestrator
    if _orchestrator is None:
        _orchestrator = SkillOrchestrator()
    return _orchestrator


# ==================== 端点 ====================

@router.get("", response_model=List[SkillSummary])
async def list_skills(
    category: Optional[str] = Query(None, description="按分类筛选"),
    tag: Optional[str] = Query(None, description="按标签筛选"),
    priority: Optional[str] = Query(None, description="按优先级筛选"),
    premium_only: bool = Query(False, description="仅会员 Skill"),
    limit: int = Query(50, ge=1, le=200, description="返回数量"),
    offset: int = Query(0, ge=0, description="偏移量"),
):
    """
    获取 Skill 列表

    支持按分类、标签、优先级筛选，支持分页。
    """
    # 筛选
    if category:
        skills = skill_registry.get_by_category(category)
    elif tag:
        skills = skill_registry.get_by_tags([tag])
    elif priority:
        skills = skill_registry.get_by_priority(priority)
    elif premium_only:
        skills = skill_registry.get_premium_skills()
    else:
        skills = skill_registry.all_skills()

    # 分页
    paginated = skills[offset:offset + limit]

    return [
        SkillSummary(
            skill_id=s.skill_id,
            category=s.category,
            name=s.name,
            description=s.description,
            priority=s.priority,
            recommended_model=s.recommended_model,
            is_premium=s.is_premium,
            tags=s.tags,
        )
        for s in paginated
    ]


@router.get("/categories", response_model=List[CategoryInfo])
async def list_categories():
    """
    获取分类树

    返回所有 Skill 分类及其统计信息。
    """
    categories = skill_registry.list_categories()
    return [
        CategoryInfo(
            category=cat["category"],
            skill_count=cat["skill_count"],
            p0_count=cat["p0_count"],
            premium_count=cat["premium_count"],
            sample_skills=cat["skill_ids"],
        )
        for cat in categories
    ]


@router.get("/stats", response_model=StatsResponse)
async def get_stats():
    """
    获取 Skill 使用统计

    返回总数、分类统计、优先级统计等。
    """
    all_skills = skill_registry.all_skills()
    category_counts = skill_registry.category_counts()

    priority_counts = {"P0": 0, "P1": 0, "P2": 0}
    for s in all_skills:
        if s.priority in priority_counts:
            priority_counts[s.priority] += 1

    return StatsResponse(
        total_skills=len(all_skills),
        category_counts=category_counts,
        priority_counts=priority_counts,
        premium_count=len([s for s in all_skills if s.is_premium]),
        free_count=len([s for s in all_skills if not s.is_premium]),
    )


@router.get("/search")
async def search_skills(
    q: str = Query(..., description="搜索关键词"),
    limit: int = Query(10, ge=1, le=50),
):
    """
    搜索 Skill

    按名称、描述、标签模糊搜索。
    """
    results = skill_registry.search(q)[:limit]
    return [
        SkillSummary(
            skill_id=s.skill_id,
            category=s.category,
            name=s.name,
            description=s.description,
            priority=s.priority,
            recommended_model=s.recommended_model,
            is_premium=s.is_premium,
            tags=s.tags,
        )
        for s in results
    ]


@router.get("/{skill_id}", response_model=SkillDetail)
async def get_skill(skill_id: str):
    """
    获取 Skill 详情

    根据 skill_id 获取完整的 Skill 定义。
    """
    skill = skill_registry.get(skill_id)
    if not skill:
        raise HTTPException(status_code=404, detail=f"Skill '{skill_id}' not found")
    return SkillDetail(
        skill_id=skill.skill_id,
        category=skill.category,
        name=skill.name,
        description=skill.description,
        version=skill.version,
        priority=skill.priority,
        required_context=skill.required_context,
        tags=skill.tags,
        output_schema=skill.output_schema,
        recommended_model=skill.recommended_model,
        max_tokens=skill.max_tokens,
        is_premium=skill.is_premium,
        cooldown_hours=skill.cooldown_hours,
        dependencies=skill.dependencies,
    )


@router.post("/execute", response_model=ExecuteResponse)
async def execute_skill(request: ExecuteRequest):
    """
    执行 Skill

    根据用户消息和上下文，自动识别意图并执行对应 Skill。
    也可通过 skill_ids 指定特定 Skill。
    """
    orchestrator = get_orchestrator()

    try:
        result: SkillExecutionResult = await orchestrator.execute(
            user_message=request.message,
            user_context=request.context,
        )
        return ExecuteResponse(
            status=result.status.value,
            final_response=result.final_response,
            skills_executed=[
                {
                    "skill_id": sr.skill_id,
                    "skill_name": sr.skill_name,
                    "category": sr.category,
                    "status": sr.status,
                    "model": sr.model,
                    "tokens_used": sr.tokens_used,
                    "latency_ms": sr.latency_ms,
                }
                for sr in result.skills_executed
            ],
            total_tokens=result.total_tokens,
            total_latency_ms=result.total_latency_ms,
            safety_flag=result.safety_flag,
            follow_up=result.follow_up,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Skill execution failed: {str(e)}")


@router.post("/daily-plan", response_model=ExecuteResponse)
async def generate_daily_plan(request: DailyPlanRequest):
    """
    生成今日养生计划

    plan_type:
    - light: 轻量版（3条核心建议）
    - deep: 深度版（详细全案）
    - emotion: 情绪关怀计划
    - sleep: 睡眠优化计划
    - constitution: 体质调理计划
    - season: 节气养生计划
    """
    # 映射 plan_type 到 skill_id
    plan_skill_map = {
        "light": "generate_daily_plan_light",
        "deep": "generate_daily_plan_deep",
        "emotion": "generate_daily_plan_emotion",
        "sleep": "generate_daily_plan_sleep",
        "constitution": "generate_daily_plan_constitution",
        "season": "generate_daily_plan_season",
    }

    skill_id = plan_skill_map.get(request.plan_type, "generate_daily_plan_light")
    skill = skill_registry.get(skill_id)
    if not skill:
        raise HTTPException(
            status_code=400,
            detail=f"Unknown plan_type: {request.plan_type}"
        )

    orchestrator = get_orchestrator()
    message = f"请为我生成{skill.name}"

    try:
        result: SkillExecutionResult = await orchestrator.execute(
            user_message=message,
            user_context=request.context or {},
        )
        return ExecuteResponse(
            status=result.status.value,
            final_response=result.final_response,
            skills_executed=[
                {
                    "skill_id": sr.skill_id,
                    "skill_name": sr.skill_name,
                    "category": sr.category,
                    "status": sr.status,
                    "model": sr.model,
                    "tokens_used": sr.tokens_used,
                    "latency_ms": sr.latency_ms,
                }
                for sr in result.skills_executed
            ],
            total_tokens=result.total_tokens,
            total_latency_ms=result.total_latency_ms,
            safety_flag=result.safety_flag,
            follow_up=result.follow_up,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Plan generation failed: {str(e)}")
