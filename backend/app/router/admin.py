"""
顺时 Admin 后台聚合 API
提供仪表盘统计、配置管理等后台专属接口
"""
from fastapi import APIRouter, Depends, Query
from sqlalchemy.sql import text
from sqlalchemy import text, func
from sqlalchemy.orm import Session
from typing import Optional

from app.db.database import get_db

router = APIRouter(prefix="/api/v1/admin", tags=["Admin后台"])


@router.get("/dashboard", response_model=dict)
async def get_dashboard(
    db: Session = Depends(get_db),
):
    """仪表盘统计数据"""
    stats = {}

    # 总用户数
    try:
        result = db.execute(text("SELECT COUNT(*) as cnt FROM users"))
        stats["total_users"] = result.scalar() or 0
    except Exception:
        stats["total_users"] = 0

    # 今日新增用户
    try:
        result = db.execute(text(
            "SELECT COUNT(*) FROM users WHERE DATE(created_at) = DATE('now')"
        ))
        stats["new_users_today"] = result.scalar() or 0
    except Exception:
        stats["new_users_today"] = 0

    # 内容总数
    try:
        result = db.execute(text("SELECT COUNT(*) FROM contents"))
        stats["total_content"] = result.scalar() or 0
    except Exception:
        stats["total_content"] = 0

    # 今日发布内容
    try:
        result = db.execute(text(
            "SELECT COUNT(*) FROM contents WHERE DATE(created_at) = DATE('now')"
        ))
        stats["content_published_today"] = result.scalar() or 0
    except Exception:
        stats["content_published_today"] = 0

    # 安全事件数 (近7天)
    try:
        result = db.execute(text(
            "SELECT COUNT(*) FROM safety_audit_logs WHERE created_at >= datetime('now', '-7 days')"
        ))
        stats["safety_events"] = result.scalar() or 0
    except Exception:
        stats["safety_events"] = 0

    # 活跃告警
    try:
        result = db.execute(text(
            "SELECT COUNT(*) FROM alerts WHERE resolved = 0"
        ))
        stats["active_alerts"] = result.scalar() or 0
    except Exception:
        stats["active_alerts"] = 0

    # 活跃订阅
    try:
        result = db.execute(text(
            "SELECT COUNT(DISTINCT user_id) FROM subscriptions WHERE status = 'paid'"
        ))
        stats["active_subscriptions"] = result.scalar() or 0
    except Exception:
        stats["active_subscriptions"] = 0

    # AI 请求数 (今日)
    try:
        result = db.execute(text(
            "SELECT COUNT(*) FROM llm_audit_logs WHERE DATE(created_at) = DATE('now')"
        ))
        stats["ai_requests_today"] = result.scalar() or 0
    except Exception:
        stats["ai_requests_today"] = 0

    return {"success": True, "data": stats}


@router.get("/config/ai-models", response_model=dict)
async def get_ai_models_config(
    db: Session = Depends(get_db),
):
    """获取 AI 模型配置列表"""
    models = [
        {
            "id": "deepseek-chat",
            "name": "DeepSeek Chat",
            "provider": "deepseek",
            "max_tokens": 4096,
            "is_default": True,
            "status": "active",
        },
        {
            "id": "deepseek-reasoner",
            "name": "DeepSeek Reasoner",
            "provider": "deepseek",
            "max_tokens": 8192,
            "is_default": False,
            "status": "active",
        },
    ]

    # 尝试从数据库读取
    try:
        result = db.execute(text(
            "SELECT key, value FROM feature_flags WHERE key LIKE 'model_%'"
        ))
        for row in result:
            pass  # 可以根据 feature_flags 覆盖默认配置
    except Exception:
        pass

    return {"success": True, "data": models}


@router.get("/constitution/stats", response_model=dict)
async def get_constitution_stats(
    db: Session = Depends(get_db),
):
    """体质分布统计"""
    stats = {}
    try:
        result = db.execute(text(
            "SELECT constitution_type, COUNT(*) as cnt FROM users "
            "WHERE constitution_type IS NOT NULL AND constitution_type != '' "
            "GROUP BY constitution_type ORDER BY cnt DESC"
        ))
        for row in result:
            stats[row[0]] = row[1]
    except Exception:
        # 返回默认分布
        stats = {
            "平和质": 0, "气虚质": 0, "阳虚质": 0, "阴虚质": 0,
            "痰湿质": 0, "湿热质": 0, "血瘀质": 0, "气郁质": 0, "特禀质": 0,
        }

    return {"success": True, "data": stats}


@router.get("/subscription/stats", response_model=dict)
async def get_subscription_stats(
    db: Session = Depends(get_db),
):
    """订阅统计"""
    stats = {}
    try:
        # 各状态订单数
        result = db.execute(text(
            "SELECT status, COUNT(*) as cnt FROM subscriptions GROUP BY status"
        ))
        for row in result:
            stats[f"orders_{row[0]}"] = row[1]
    except Exception:
        pass

    # 总收入
    try:
        result = db.execute(text(
            "SELECT COALESCE(SUM(amount), 0) FROM subscriptions WHERE status = 'paid'"
        ))
        stats["total_revenue"] = float(result.scalar() or 0)
    except Exception:
        stats["total_revenue"] = 0

    return {"success": True, "data": stats}
