"""
告警管理 API

GET    /api/v1/alerts          — 告警列表
GET    /api/v1/alerts/stats    — 告警统计
POST   /api/v1/alerts/test     — 发送测试告警
GET    /api/v1/alerts/channels — 查看渠道状态
"""

from __future__ import annotations

import logging
from typing import Optional

from fastapi import APIRouter, Query, HTTPException
from pydantic import BaseModel, Field

from app.alerts.sender import alert_sender, AlertEvent, AlertSender
from app.alerts.rules import AlertRules
from app.alerts.store import alert_store, AlertStore

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/alerts", tags=["告警管理"])


# ==================== Models ====================

class TestAlertRequest(BaseModel):
    """测试告警请求"""
    level: str = Field("info", description="告警级别: info/warning/error/critical")
    channel: Optional[str] = Field(None, description="指定渠道: webhook/wechat")


# ==================== Endpoints ====================

@router.get("")
async def list_alerts(
    level: Optional[str] = Query(None, description="按级别过滤"),
    category: Optional[str] = Query(None, description="按类别过滤"),
    limit: int = Query(50, ge=1, le=200, description="返回数量"),
):
    """查询告警历史"""
    alerts = alert_store.list_alerts(level=level, category=category, limit=limit)
    return {"success": True, "data": alerts}


@router.get("/stats")
async def get_stats():
    """告警统计"""
    stats = alert_store.get_stats()
    return {"success": True, "data": stats}


@router.post("/test")
async def send_test_alert(request: TestAlertRequest):
    """发送测试告警"""
    event = AlertEvent(
        level=request.level,
        category="system",
        title="告警测试",
        message="这是一条测试告警，用于验证告警渠道配置",
        context={"type": "test"},
        timestamp=__import__("datetime").datetime.now(
            __import__("datetime").timezone.utc
        ).isoformat(),
        alert_id=f"test_{__import__('uuid').uuid4().hex[:12]}",
    )

    sent = False
    response = ""

    if request.channel == "wechat":
        if not alert_sender.wechat_url:
            raise HTTPException(status_code=400, detail="微信渠道未配置 (ALERT_WECHAT_WEBHOOK_URL)")
        sent = await alert_sender._send_wechat(event)
    elif request.channel == "webhook":
        if not alert_sender.webhook_url:
            raise HTTPException(status_code=400, detail="Webhook渠道未配置 (ALERT_WEBHOOK_URL)")
        sent = await alert_sender._send_webhook(event)
    else:
        sent = await alert_sender.send(event)

    # 记录日志
    alert_store.record(
        event=event,
        sent=sent,
        channel=request.channel or "all",
        response="ok" if sent else "failed",
    )

    return {
        "success": sent,
        "data": {
            "alert_id": event.alert_id,
            "sent": sent,
            "channel": request.channel or "all",
        },
    }


@router.get("/channels")
async def get_channels():
    """查看告警渠道配置状态"""
    return {
        "success": True,
        "data": {
            "enabled": alert_sender.enabled,
            "webhook": {
                "configured": bool(alert_sender.webhook_url),
                "url_masked": (
                    alert_sender.webhook_url[:30] + "****"
                    if alert_sender.webhook_url else ""
                ),
            },
            "wechat": {
                "configured": bool(alert_sender.wechat_url),
                "url_masked": (
                    alert_sender.wechat_url[:30] + "****"
                    if alert_sender.wechat_url else ""
                ),
            },
        },
    }
