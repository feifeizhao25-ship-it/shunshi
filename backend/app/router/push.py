"""
个性化推送 API
Mock模式 — 只返回推送内容，不实际推送
"""
from __future__ import annotations
import logging
from fastapi import APIRouter, HTTPException, Query, Depends
from pydantic import BaseModel, Field
from typing import Optional, Literal
from sqlalchemy.orm import Session
from app.deps import get_session
from app.routers.settings import _read, _write

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/push", tags=["push"])


# ============ 推送偏好模型 ============

class PushPreferences(BaseModel):
    user_id: str
    quiet_hours_start: str = Field("22:00", pattern=r"^(?:[01][0-9]|2[0-3]):[0-5][0-9]$")
    quiet_hours_end: str = Field("07:00", pattern=r"^(?:[01][0-9]|2[0-3]):[0-5][0-9]$")
    push_frequency: Literal["normal", "minimal", "verbose"] = "normal"  # normal / minimal / verbose
    focus_areas: list[str] = []  # e.g. ["睡眠", "运动", "饮食"]
    language: str = "cn"


# ============ 持久化偏好存储 ============

SETTINGS_KEY = "settings:push"


# ============ API 端点 ============

@router.get("/morning")
async def get_morning_push(
    user_id: str = Query(..., description="用户ID"),
    lang: str = Query("cn", description="语言: cn / gl"),
):
    """早晨推送 (7:00) — 问候+今日饮食建议+晨练"""
    from app.services.push_scheduler import push_scheduler
    try:
        result = await push_scheduler.get_morning_push(user_id, "cn")
        return result
    except Exception as e:
        logger.error(f"[Push] morning push failed: {e}")
        raise HTTPException(status_code=500, detail="暂时无法生成提醒，请稍后重试")


@router.get("/noon")
async def get_noon_push(
    user_id: str = Query(..., description="用户ID"),
    lang: str = Query("cn", description="语言: cn / gl"),
):
    """午间推送 (12:00) — 午餐建议+午休提醒+茶饮"""
    from app.services.push_scheduler import push_scheduler
    try:
        result = await push_scheduler.get_noon_push(user_id, "cn")
        return result
    except Exception as e:
        logger.error(f"[Push] noon push failed: {e}")
        raise HTTPException(status_code=500, detail="暂时无法生成提醒，请稍后重试")


@router.get("/afternoon")
async def get_afternoon_push(
    user_id: str = Query(..., description="用户ID"),
    lang: str = Query("cn", description="语言: cn / gl"),
):
    """下午推送 (15:00) — 运动提醒+穴位按摩"""
    from app.services.push_scheduler import push_scheduler
    try:
        result = await push_scheduler.get_afternoon_push(user_id, "cn")
        return result
    except Exception as e:
        logger.error(f"[Push] afternoon push failed: {e}")
        raise HTTPException(status_code=500, detail="暂时无法生成提醒，请稍后重试")


@router.get("/evening")
async def get_evening_push(
    user_id: str = Query(..., description="用户ID"),
    lang: str = Query("cn", description="语言: cn / gl"),
):
    """晚间推送 (18:00) — 晚餐+泡脚建议"""
    from app.services.push_scheduler import push_scheduler
    try:
        result = await push_scheduler.get_evening_push(user_id, "cn")
        return result
    except Exception as e:
        logger.error(f"[Push] evening push failed: {e}")
        raise HTTPException(status_code=500, detail="暂时无法生成提醒，请稍后重试")


@router.get("/night")
async def get_night_push(
    user_id: str = Query(..., description="用户ID"),
    lang: str = Query("cn", description="语言: cn / gl"),
):
    """睡前推送 (21:30) — 睡眠建议+穴位+情绪"""
    from app.services.push_scheduler import push_scheduler
    try:
        result = await push_scheduler.get_night_push(user_id, "cn")
        return result
    except Exception as e:
        logger.error(f"[Push] night push failed: {e}")
        raise HTTPException(status_code=500, detail="暂时无法生成提醒，请稍后重试")


@router.get("/daily")
async def get_daily_push(
    user_id: str = Query(..., description="用户ID"),
    lang: str = Query("cn", description="语言: cn / gl"),
):
    """完整日推送方案"""
    from app.services.push_scheduler import push_scheduler
    try:
        result = await push_scheduler.get_daily_push(user_id, "cn")
        return result
    except Exception as e:
        logger.error(f"[Push] daily push failed: {e}")
        raise HTTPException(status_code=500, detail="暂时无法生成提醒，请稍后重试")


@router.post("/preferences")
async def set_push_preferences(prefs: PushPreferences, session: Session = Depends(get_session)):
    """设置推送偏好"""
    saved = {**prefs.model_dump(), "language": "cn"}
    _write(session, prefs.user_id, SETTINGS_KEY, saved)
    return {
        "success": True,
        "message": "提醒偏好已保存",
        "preferences": saved,
    }


@router.get("/preferences")
async def get_push_preferences(
    user_id: str = Query(..., description="用户ID"),
    session: Session = Depends(get_session),
):
    """获取推送偏好"""
    prefs = _read(session, user_id, SETTINGS_KEY, {})
    if not prefs:
        return {
            "user_id": user_id,
            "quiet_hours_start": "22:00",
            "quiet_hours_end": "07:00",
            "push_frequency": "normal",
            "focus_areas": [],
            "language": "cn",
        }
    return {**prefs, "language": "cn"}
