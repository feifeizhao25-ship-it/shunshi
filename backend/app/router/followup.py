"""
顺时 - Follow-up 调度 API 路由
"""

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel
from typing import Optional, Dict, Any, List

from app.services.followup_scheduler import (
    followup_scheduler,
    VALID_TYPES,
    TYPE_DESCRIPTIONS,
)
from app.database.db import get_db

router = APIRouter(prefix="/api/v1/followup", tags=["Follow-up调度"])


# ============ Models ============

class ScheduleFollowUpRequest(BaseModel):
    """创建调度请求"""
    user_id: str
    type: str  # daily_checkin / mood_followup / sleep_followup / care_reminder / subscription_expiring
    trigger_time: str  # ISO格式 或 "HH:MM"
    content: Optional[str] = None
    title: Optional[str] = None
    description: Optional[str] = None
    conversation_id: Optional[str] = None


class UpdateStatusRequest(BaseModel):
    """更新状态请求"""
    status: str  # scheduled / sent / cancelled / expired


# ============ API 端点 ============
# 注意：固定路径必须在动态路径 /{followup_id} 之前注册

@router.get("/types")
async def list_followup_types():
    """列出所有可用的 follow-up 类型"""
    return {
        "types": [
            {
                "value": t,
                **TYPE_DESCRIPTIONS.get(t, {}),
            }
            for t in VALID_TYPES
        ],
    }


@router.post("/schedule")
async def schedule_followup(request: ScheduleFollowUpRequest):
    """
    创建 follow-up 调度

    支持多种类型：签到提醒、情绪跟进、睡眠跟进、关怀提醒、订阅到期提醒
    """
    try:
        followup = followup_scheduler.schedule_followup(
            user_id=request.user_id,
            followup_type=request.type,
            trigger_time=request.trigger_time,
            content=request.content,
            title=request.title,
            description=request.description,
            conversation_id=request.conversation_id,
        )
        return {"success": True, "followup": followup}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/list")
async def list_followups(
    user_id: Optional[str] = Query(None, description="按用户过滤"),
    status: Optional[str] = Query(None, description="按状态过滤"),
    type: Optional[str] = Query(None, description="按类型过滤"),
    limit: int = Query(50, description="返回数量限制", le=200),
):
    """
    列出 follow-up 任务

    支持按用户、状态、类型过滤
    """
    followups = followup_scheduler.get_followup_list(
        user_id=user_id,
        status=status,
        followup_type=type,
        limit=limit,
    )
    return {
        "count": len(followups),
        "followups": followups,
    }


@router.get("/stats")
async def get_followup_stats(
    user_id: Optional[str] = Query(None, description="按用户过滤"),
):
    """获取 follow-up 统计"""
    stats = followup_scheduler.get_stats(user_id=user_id)
    return stats


@router.get("/due")
async def get_due_followups():
    """
    查看到期但尚未执行的 follow-up 任务

    仅查看，不执行
    """
    due = followup_scheduler.check_due_followups()
    return {
        "count": len(due),
        "due_followups": due,
    }


@router.get("/{followup_id}")
async def get_followup(followup_id: str):
    """获取单个 follow-up 详情"""
    followup = followup_scheduler._get_followup_by_id(followup_id)
    if not followup:
        raise HTTPException(status_code=404, detail="follow-up not found")
    return followup


@router.put("/{followup_id}")
async def update_followup_status(
    followup_id: str,
    request: UpdateStatusRequest,
):
    """
    更新 follow-up 状态

    可将状态更新为 scheduled / sent / cancelled / expired
    """
    try:
        followup = followup_scheduler.update_followup_status(
            followup_id, request.status
        )
        if not followup:
            raise HTTPException(status_code=404, detail="follow-up not found")
        return {"success": True, "followup": followup}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.delete("/{followup_id}")
async def cancel_followup(followup_id: str):
    """
    取消 follow-up

    仅能取消未发送的任务
    """
    success = followup_scheduler.cancel_followup(followup_id)
    if not success:
        raise HTTPException(
            status_code=400,
            detail="follow-up不存在或已发送，无法取消",
        )
    return {"success": True, "message": "follow-up已取消"}


@router.post("/check")
async def check_and_trigger():
    """
    检查并执行到期的 follow-up 任务

    扫描所有已到触发时间且状态为 scheduled 的任务，标记为已发送。
    可由定时任务（如cron）定期调用。
    """
    results = followup_scheduler.check_and_trigger_due()
    return {
        "checked_at": __import__("datetime").datetime.now().isoformat(),
        "triggered_count": len(results),
        "results": results,
    }


# ============ 智能调度 ============

# 递增间隔（天）
SMART_INTERVALS = [3, 7, 14, 30, 30, 60]

class SmartScheduleRequest(BaseModel):
    """智能调度请求"""
    user_id: str
    followup_type: str
    title: Optional[str] = None
    description: Optional[str] = None
    conversation_id: Optional[str] = None


@router.post("/schedule-smart")
async def smart_schedule(request: SmartScheduleRequest):
    """
    智能调度下一个 Follow-up
    
    完成一个 Follow-up 后，自动创建下一个（间隔递增：3天→7天→14天→30天）。
    根据用户活跃度调整频率（活跃用户→较少提醒，沉默用户→适当提醒）。
    """
    from datetime import datetime, timedelta
    db = get_db()
    now = datetime.now()
    
    # 查询用户已完成的同类型 follow-up 数量，决定间隔
    completed_count = 0
    try:
        row = db.execute("""
            SELECT COUNT(*) as cnt FROM follow_ups 
            WHERE user_id = ? AND type = ? AND status = 'completed'
        """, (request.user_id, request.followup_type)).fetchone()
        completed_count = row["cnt"] if row else 0
    except Exception:
        pass
    
    # 确定间隔（递增）
    interval_idx = min(completed_count, len(SMART_INTERVALS) - 1)
    base_interval = SMART_INTERVALS[interval_idx]
    
    # 根据用户活跃度调整
    # 查询用户最近7天的活跃记录
    days_ago = (now - timedelta(days=7)).isoformat()
    try:
        active_row = db.execute("""
            SELECT COUNT(*) as cnt FROM conversations 
            WHERE user_id = ? AND updated_at > ?
        """, (request.user_id, days_ago)).fetchone()
        active_count = active_row["cnt"] if active_row else 0
    except Exception:
        active_count = 0
    
    # 活跃用户 (>5次对话/周) → 间隔加长30%
    # 沉默用户 (0次对话/周) → 间隔缩短50%
    if active_count > 5:
        adjusted_interval = int(base_interval * 1.3)
    elif active_count == 0:
        adjusted_interval = max(int(base_interval * 0.5), 1)
    else:
        adjusted_interval = base_interval
    
    # 计算触发时间
    trigger_at = now + timedelta(days=adjusted_interval)
    trigger_time_str = trigger_at.strftime("%Y-%m-%dT%H:%M")
    
    # 创建 follow-up
    title = request.title or f"{request.followup_type} 提醒"
    description = request.description or f"距上次完成已 {adjusted_interval} 天，请关注您的{request.followup_type}。"
    
    try:
        followup = followup_scheduler.schedule_followup(
            user_id=request.user_id,
            followup_type=request.followup_type,
            trigger_time=trigger_time_str,
            content=description,
            title=title,
            description=description,
            conversation_id=request.conversation_id,
        )
        
        return {
            "success": True,
            "followup": followup,
            "schedule_info": {
                "completed_count": completed_count,
                "base_interval_days": base_interval,
                "adjusted_interval_days": adjusted_interval,
                "user_active_7d": active_count,
                "next_trigger_at": trigger_at.isoformat(),
            }
        }
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/check-due")
async def check_due_followups_user(
    user_id: str = Query(..., description="用户ID"),
):
    """
    检查指定用户到期的 Follow-up
    
    返回已到期但未完成的 follow-up 列表，可用于推送提醒。
    """
    from datetime import datetime
    now = datetime.now()
    now_str = now.isoformat()
    
    db = get_db()
    try:
        rows = db.execute("""
            SELECT * FROM follow_ups 
            WHERE user_id = ? AND status = 'pending' AND scheduled_at <= ?
            ORDER BY scheduled_at ASC
        """, (user_id, now_str)).fetchall()
        
        due_list = [dict(r) for r in rows]
        
        # 同时检查调度器中的到期任务
        scheduler_due = followup_scheduler.check_due_followups()
        scheduler_due_for_user = [f for f in scheduler_due if f.get("user_id") == user_id]
        
        # 合并去重
        seen = set(f.get("id") for f in due_list)
        for f in scheduler_due_for_user:
            if f.get("id") not in seen:
                due_list.append(f)
        
        return {
            "success": True,
            "count": len(due_list),
            "due_followups": due_list,
            "checked_at": now_str,
        }
    except Exception as e:
        return {
            "success": True,
            "count": 0,
            "due_followups": [],
            "error": str(e),
        }


# ============ 快捷创建端点 ============

@router.post("/quick/daily-checkin")
async def quick_daily_checkin(
    user_id: str = Query(..., description="用户ID"),
    time: str = Query("20:00", description="提醒时间 HH:MM"),
):
    """快捷创建每日签到提醒"""
    followup = followup_scheduler.create_daily_checkin(user_id=user_id, time=time)
    return {"success": True, "followup": followup}


@router.post("/quick/mood-followup")
async def quick_mood_followup(
    user_id: str = Query(..., description="用户ID"),
    hours: int = Query(24, description="几小时后触发"),
    conversation_id: Optional[str] = Query(None, description="关联对话ID"),
):
    """快捷创建情绪跟进"""
    followup = followup_scheduler.create_mood_followup(
        user_id=user_id,
        trigger_hours=hours,
        conversation_id=conversation_id,
    )
    return {"success": True, "followup": followup}


@router.post("/quick/sleep-followup")
async def quick_sleep_followup(
    user_id: str = Query(..., description="用户ID"),
    hours: int = Query(12, description="几小时后触发"),
    conversation_id: Optional[str] = Query(None, description="关联对话ID"),
):
    """快捷创建睡眠跟进"""
    followup = followup_scheduler.create_sleep_followup(
        user_id=user_id,
        trigger_hours=hours,
        conversation_id=conversation_id,
    )
    return {"success": True, "followup": followup}
