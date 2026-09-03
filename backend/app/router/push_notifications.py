"""
顺时 ShunShi - 推送通知 API
统一通知网关路由: /api/v1/notifications/send
"""
import logging
from typing import Optional

from fastapi import APIRouter, HTTPException, Request
from pydantic import BaseModel

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/notifications", tags=["Notifications"])


# ==================== 请求模型 ====================

class SendRequest(BaseModel):
    user_id: Optional[str] = None
    token: Optional[str] = None
    platform: Optional[str] = None
    title: str
    body: str
    data: dict = {}
    notification_type: str = "daily_rhythm"
    high_priority: bool = False


class TokenRegisterRequest(BaseModel):
    user_id: str
    token: str
    platform: str  # ios / android


class TopicSubscribeRequest(BaseModel):
    token: str
    topic: str
    subscribe: bool = True


class BroadcastRequest(BaseModel):
    title: str
    body: str
    notification_type: str = "daily_rhythm"
    data: dict = {}
    topic: Optional[str] = None


# ==================== API 端点 ====================

@router.post("/send")
async def send_notification(request: Request, body: SendRequest):
    """发送推送通知"""
    from app.services.notification_gateway import (
        notification_gateway,
        SendNotificationRequest,
    )

    req = SendNotificationRequest(
        user_id=body.user_id,
        token=body.token,
        platform=body.platform,
        title=body.title,
        body=body.body,
        data=body.data,
        notification_type=body.notification_type,
        high_priority=body.high_priority,
    )
    result = await notification_gateway.send(req)
    return {"success": result.success, "data": result.model_dump()}


@router.post("/send-to-user")
async def send_to_user(request: Request, body: SendRequest):
    """发送通知给指定用户"""
    from app.services.notification_gateway import notification_gateway

    if not body.user_id:
        raise HTTPException(status_code=400, detail="user_id is required")

    result = await notification_gateway.send_to_user(
        user_id=body.user_id,
        title=body.title,
        body=body.body,
        notification_type=body.notification_type,
        data=body.data,
        high_priority=body.high_priority,
    )
    return {"success": result.success, "data": result.model_dump()}


@router.post("/register-token")
async def register_token(request: Request, body: TokenRegisterRequest):
    """注册推送 Token"""
    if body.platform == "ios":
        from app.services.apns_service import apns_service
        success = await apns_service.register_token(
            user_id=body.user_id,
            token=body.token,
        )
    else:
        from app.services.fcm_service import fcm_service, TokenRegistration
        success = await fcm_service.register_token(
            TokenRegistration(
                user_id=body.user_id,
                token=body.token,
                platform=body.platform,
            )
        )
    return {"success": success}


@router.post("/subscribe-topic")
async def subscribe_topic(request: Request, body: TopicSubscribeRequest):
    """订阅/退订 FCM 主题"""
    from app.services.fcm_service import fcm_service, TopicSubscription

    success = await fcm_service.subscribe_to_topic(
        TopicSubscription(
            token=body.token,
            topic=body.topic,
            subscribe=body.subscribe,
        )
    )
    return {"success": success}


@router.post("/broadcast")
async def broadcast_notification(request: Request, body: BroadcastRequest):
    """广播通知"""
    from app.services.notification_gateway import notification_gateway

    result = await notification_gateway.broadcast(
        title=body.title,
        body=body.body,
        notification_type=body.notification_type,
        data=body.data,
        topic=body.topic,
    )
    return {"success": result.get("success", False), "data": result}


# ==================== 设备管理扩展 ====================

class UnregisterDeviceRequest(BaseModel):
    user_id: str
    token: Optional[str] = None


@router.delete("/devices/unregister")
async def unregister_device(body: UnregisterDeviceRequest):
    """注销设备推送 Token"""
    try:
        from app.database.db import get_db
        db = get_db()
        
        # 从数据库中删除设备 Token 记录
        if body.token:
            db.execute(
                "DELETE FROM push_tokens WHERE user_id = ? AND token = ?",
                (body.user_id, body.token)
            )
        else:
            db.execute(
                "DELETE FROM push_tokens WHERE user_id = ?",
                (body.user_id,)
            )
        db.commit()
        return {"success": True, "message": "设备已注销"}
    except Exception as e:
        logger.error(f"[Push] 注销设备失败: {e}")
        raise HTTPException(status_code=500, detail="设备注销失败") from e


# ==================== 通知已读管理 ====================

@router.get("/unread-count")
async def get_unread_count(user_id: str = None):
    """获取用户未读通知数量"""
    try:
        from app.database.db import get_db
        db = get_db()
        
        # 确保通知表存在
        try:
            db.execute("SELECT 1 FROM notifications LIMIT 1")
        except Exception:
            db.execute("""
                CREATE TABLE IF NOT EXISTS notifications (
                    id TEXT PRIMARY KEY,
                    user_id TEXT NOT NULL,
                    type TEXT NOT NULL,
                    title TEXT NOT NULL,
                    body TEXT,
                    data TEXT DEFAULT '{}',
                    is_read INTEGER DEFAULT 0,
                    sent_at TEXT DEFAULT (datetime('now')),
                    read_at TEXT
                )
            """)
            db.commit()
        
        row = db.execute(
            "SELECT COUNT(*) as count FROM notifications WHERE user_id = ? AND is_read = 0",
            (user_id or "user-001",)
        ).fetchone()
        
        return {"success": True, "data": {"count": row["count"] if row else 0}}
    except Exception as e:
        logger.warning(f"[Push] 获取未读数失败: {e}")
        return {"success": True, "data": {"count": 0}}


@router.post("/{notification_id}/read")
async def mark_notification_read(notification_id: str):
    """标记通知为已读"""
    try:
        from app.database.db import get_db
        from datetime import datetime, timezone
        db = get_db()
        
        db.execute(
            "UPDATE notifications SET is_read = 1, read_at = ? WHERE id = ?",
            (datetime.now(timezone.utc).isoformat(), notification_id)
        )
        db.commit()
        return {"success": True, "message": "已标记为已读"}
    except Exception as e:
        logger.warning(f"[Push] 标记已读失败: {e}")
        return {"success": True, "message": "已标记为已读"}
