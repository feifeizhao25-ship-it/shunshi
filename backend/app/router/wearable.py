"""
顺时 — 可穿戴设备集成 API (shunshi-wearable)
接入健康手环/手表数据，与TCM养生结合分析
"""

from fastapi import APIRouter, HTTPException, Query, Path, Depends
from pydantic import BaseModel, Field
from typing import Optional, List, Dict
from datetime import date as Date, datetime
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.models.wearable import WearableSync

router = APIRouter(prefix="/api/v1/wearable", tags=["wearable"])

SUPPORTED_DEVICES = [
    {"id": "apple_watch", "name": "Apple Watch", "platform": "ios", "data_types": ["heart_rate", "steps", "sleep", "calories", "spo2"]},
    {"id": "fitbit", "name": "Fitbit", "platform": "all", "data_types": ["heart_rate", "steps", "sleep", "calories"]},
    {"id": "xiaomi_band", "name": "小米手环", "platform": "all", "data_types": ["heart_rate", "steps", "sleep", "spo2"]},
    {"id": "huawei_watch", "name": "华为手表", "platform": "all", "data_types": ["heart_rate", "steps", "sleep", "spo2", "stress"]},
    {"id": "samsung_galaxy", "name": "Samsung Galaxy Watch", "platform": "android", "data_types": ["heart_rate", "steps", "sleep", "spo2", "stress"]},
]

TCM_HEART_RATE_ANALYSIS = {
    "resting_low": {"range": (0, 50), "tcm": "心率偏低，可能心阳不足，宜温补心阳"},
    "resting_normal": {"range": (50, 80), "tcm": "心率正常，气血运行顺畅"},
    "resting_high": {"range": (80, 100), "tcm": "心率偏快，可能心火偏旺，宜清心降火"},
    "resting_very_high": {"range": (100, 999), "tcm": "心率过快，建议就医排除心脏问题"},
}

TCM_SLEEP_ANALYSIS = {
    "excellent": {"hours": (7, 9), "tcm": "睡眠充足，气血得以充分修复"},
    "good": {"hours": (6, 7), "tcm": "睡眠基本充足，可适当早睡"},
    "insufficient": {"hours": (0, 6), "tcm": "睡眠不足，长期易气血两虚，宜调整作息"},
}


class WearableDataSync(BaseModel):
    user_id: str = Field(..., description="用户ID")
    device_id: str = Field(..., description="设备ID")
    date: Date = Field(..., description="数据日期 YYYY-MM-DD")
    heart_rate_avg: Optional[float] = Field(None, description="平均心率(bpm)")
    heart_rate_resting: Optional[float] = Field(None, description="静息心率(bpm)")
    steps: Optional[int] = Field(None, description="步数")
    sleep_hours: Optional[float] = Field(None, description="睡眠时长(小时)")
    sleep_deep_hours: Optional[float] = Field(None, description="深睡时长(小时)")
    calories_burned: Optional[float] = Field(None, description="消耗卡路里")
    spo2_avg: Optional[float] = Field(None, description="平均血氧饱和度(%)")
    stress_level: Optional[int] = Field(None, ge=0, le=100, description="压力指数(0-100)")


class DeviceConnectRequest(BaseModel):
    user_id: str = Field(..., description="用户ID")
    device_id: str = Field(..., description="设备ID")
    device_token: Optional[str] = Field(None, description="设备授权token")


# 已连接设备（内存缓存，用于快速查询设备连接状态）
_connected_devices: Dict[str, dict] = {}


def _analyze_heart_rate(hr: float) -> dict:
    for key, info in TCM_HEART_RATE_ANALYSIS.items():
        low, high = info["range"]
        if low <= hr < high:
            return {"status": key, "tcm_analysis": info["tcm"]}
    return {"status": "unknown", "tcm_analysis": "无法分析"}


def _analyze_sleep(hours: float) -> dict:
    for key, info in TCM_SLEEP_ANALYSIS.items():
        low, high = info["hours"]
        if low <= hours < high:
            return {"status": key, "tcm_analysis": info["tcm"]}
    return {"status": "unknown", "tcm_analysis": "无法分析"}


@router.get("/devices", summary="支持的设备列表")
async def list_devices():
    return {"success": True, "data": {"devices": SUPPORTED_DEVICES}}


@router.post("/connect", summary="连接设备")
async def connect_device(request: DeviceConnectRequest):
    device = next((d for d in SUPPORTED_DEVICES if d["id"] == request.device_id), None)
    if not device:
        raise HTTPException(status_code=404, detail="不支持该设备")
    _connected_devices[request.user_id] = {
        "device_id": request.device_id,
        "device_name": device["name"],
        "connected_at": datetime.now().isoformat(),
        "status": "connected"
    }
    return {"success": True, "data": {"message": f"{device['name']} 连接成功", "device": device}}


@router.get("/connected/{user_id}", summary="已连接设备")
async def get_connected_device(user_id: str):
    device = _connected_devices.get(user_id)
    return {"success": True, "data": {"device": device, "is_connected": device is not None}}


@router.post("/sync", summary="同步健康数据")
async def sync_data(request: WearableDataSync, db: Session = Depends(get_db)):
    # TCM分析
    tcm_insights = []
    if request.heart_rate_resting:
        hr_analysis = _analyze_heart_rate(request.heart_rate_resting)
        tcm_insights.append({"metric": "静息心率", "value": request.heart_rate_resting, **hr_analysis})
    if request.sleep_hours:
        sleep_analysis = _analyze_sleep(request.sleep_hours)
        tcm_insights.append({"metric": "睡眠时长", "value": request.sleep_hours, **sleep_analysis})
    if request.steps:
        step_advice = "步数适宜，运动量合理" if 6000 <= request.steps <= 15000 else \
            ("步数偏少，建议适当增加活动" if request.steps < 6000 else "步数过多，注意休息保存正气")
        tcm_insights.append({"metric": "步数", "value": request.steps, "tcm_analysis": step_advice})
    if request.spo2_avg and request.spo2_avg < 95:
        tcm_insights.append({"metric": "血氧", "value": request.spo2_avg, "tcm_analysis": "血氧偏低，可能肺气不足，建议练习腹式呼吸"})

    # 保存到数据库
    row = WearableSync(
        user_id=request.user_id,
        device_id=request.device_id,
        sync_date=request.date,
        heart_rate_avg=request.heart_rate_avg,
        heart_rate_resting=request.heart_rate_resting,
        steps=request.steps,
        sleep_hours=request.sleep_hours,
        sleep_deep_hours=request.sleep_deep_hours,
        calories_burned=request.calories_burned,
        spo2_avg=request.spo2_avg,
        stress_level=request.stress_level,
        tcm_insights=tcm_insights,
    )
    db.add(row)
    db.commit()

    entry = {
        "date": request.date.isoformat(),
        "device_id": request.device_id,
        "raw_data": request.model_dump(exclude={"user_id", "device_id", "date"}),
        "tcm_insights": tcm_insights,
        "synced_at": datetime.now().isoformat()
    }
    return {"success": True, "data": {"entry": entry, "tcm_insights": tcm_insights}}


@router.get("/history/{user_id}", summary="历史健康数据")
async def get_history(user_id: str, days: int = Query(7, ge=1, le=90), db: Session = Depends(get_db)):
    rows = (db.query(WearableSync)
            .filter(WearableSync.user_id == user_id)
            .order_by(WearableSync.sync_date.desc())
            .limit(days).all())
    data = [{
        "date": r.sync_date,
        "device_id": r.device_id,
        "raw_data": {
            "heart_rate_avg": r.heart_rate_avg,
            "heart_rate_resting": r.heart_rate_resting,
            "steps": r.steps,
            "sleep_hours": r.sleep_hours,
            "sleep_deep_hours": r.sleep_deep_hours,
            "calories_burned": r.calories_burned,
            "spo2_avg": r.spo2_avg,
            "stress_level": r.stress_level,
        },
        "tcm_insights": r.tcm_insights or [],
        "synced_at": r.created_at.isoformat() if r.created_at else None,
    } for r in rows]
    return {"success": True, "data": {"history": data, "total": len(data)}}


@router.get("/today-summary/{user_id}", summary="今日健康摘要")
async def get_today_summary(user_id: str, db: Session = Depends(get_db)):
    today = Date.today()
    row = (db.query(WearableSync)
           .filter(WearableSync.user_id == user_id, WearableSync.sync_date == today)
           .order_by(WearableSync.created_at.desc()).first())
    if not row:
        return {"success": True, "data": {"message": "今日暂无数据，请同步设备"}}
    return {
        "success": True,
        "data": {
            "today": {
                "date": row.sync_date,
                "device_id": row.device_id,
                "raw_data": {
                    "heart_rate_avg": row.heart_rate_avg,
                    "steps": row.steps,
                    "sleep_hours": row.sleep_hours,
                },
                "tcm_insights": row.tcm_insights or [],
            }
        }
    }
