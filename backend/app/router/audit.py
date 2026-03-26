"""
顺时 AI - LLM 审计日志管理 API
Admin endpoints for viewing token usage, model stats, and budget checks.

作者: Claw 🦅
日期: 2026-03-18
"""

from fastapi import APIRouter, HTTPException, Query
from typing import Optional, Dict, Any

from app.llm.audit import get_llm_audit_logger

router = APIRouter(prefix="/api/v1/admin/audit", tags=["LLM审计"])


@router.get("/usage")
async def get_usage(
    user_id: str = Query(..., description="用户 ID"),
    date: Optional[str] = Query(None, description="日期 (YYYY-MM-DD)，默认今天"),
):
    """
    用户使用量查询

    返回指定用户在指定日期的 token 使用量、调用次数和成本。
    """
    audit = get_llm_audit_logger()
    usage = audit.get_user_daily_usage(user_id, date)
    return usage


@router.get("/model-stats")
async def get_model_stats(
    days: int = Query(7, ge=1, le=90, description="统计天数"),
):
    """
    模型使用统计

    按天、按模型分组返回调用量、token 消耗和成本。
    """
    audit = get_llm_audit_logger()
    stats = audit.get_model_usage_stats(days=days)
    return {"days": days, "stats": stats}


@router.get("/recent")
async def get_recent_calls(
    limit: int = Query(50, ge=1, le=200, description="返回条数"),
    user_id: Optional[str] = Query(None, description="按用户过滤"),
):
    """
    最近调用记录

    返回最近的 LLM 调用记录列表，可按用户过滤。
    注意: 不返回原始 prompt，只返回 prompt_hash。
    """
    audit = get_llm_audit_logger()
    calls = audit.get_recent_calls(limit=limit, user_id=user_id)
    return {"limit": limit, "calls": calls}


@router.get("/budget/{user_id}")
async def check_user_budget(
    user_id: str,
    tier: str = Query("free", description="用户等级: free/yangxin/yiyang/jiahe"),
):
    """
    用户预算检查

    检查用户当日 token 预算使用情况，判断是否需要降级。
    """
    audit = get_llm_audit_logger()
    budget = audit.check_budget(user_id, tier)
    return budget
