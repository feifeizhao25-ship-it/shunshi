"""
顺时 ShunShi - 统一通知网关
根据平台自动选择 FCM (Android) 或 APNs (iOS)
提供统一 API: /api/v1/notifications/send

使用方法:
  from app.services.notification_gateway import notification_gateway

  # 发送给单个用户
  await notification_gateway.send_to_user(
      user_id="xxx",
      title="早安",
      body="新的一天，从一杯温水开始",
      notification_type="daily_rhythm",
  )

  # 广播
  await notification_gateway.broadcast(
      title="节气提醒",
      body="明日谷雨，宜食香椿",
      notification_type="seasonal",
  )
"""
import os
import logging
from datetime import datetime
from typing import Optional

from pydantic import BaseModel

logger = logging.getLogger(__name__)

# ==================== 配置 ====================

NOTIFICATION_MODE = os.getenv("NOTIFICATION_MODE", "mock")  # mock / production

# ==================== 数据模型 ====================

class SendNotificationRequest(BaseModel):
    """发送通知请求"""
    user_id: Optional[str] = None
    token: Optional[str] = None
    platform: Optional[str] = None  # ios / android / auto
    title: str
    body: str
    data: dict = {}
    notification_type: str = "daily_rhythm"  # daily_rhythm / seasonal / reflection
    sound: str = "default"
    high_priority: bool = False
    skip_quiet_hours: bool = False


class SendNotificationResponse(BaseModel):
    """发送通知响应"""
    success: bool
    message_id: str = ""
    platform: str = ""
    error: str = ""
    quiet_hours_skipped: bool = False


class BroadcastRequest(BaseModel):
    """广播请求"""
    title: str
    body: str
    notification_type: str = "daily_rhythm"
    data: dict = {}
    topic: Optional[str] = None  # FCM topic


# ==================== 服务实现 ====================

class NotificationGateway:
    """统一通知网关 - 根据平台路由到 FCM 或 APNs"""

    def __init__(self) -> None:
        self.mode = NOTIFICATION_MODE
        self._fcm = None
        self._apns = None

    def _get_fcm(self):
        """延迟导入 FCM 服务"""
        if self._fcm is None:
            from app.services.fcm_service import fcm_service
            self._fcm = fcm_service
        return self._fcm

    def _get_apns(self):
        """延迟导入 APNs 服务"""
        if self._apns is None:
            from app.services.apns_service import apns_service
            self._apns = apns_service
        return self._apns

    async def send(self, request: SendNotificationRequest) -> SendNotificationResponse:
        """发送单条通知"""
        if self.mode == "mock":
            message_id = f"notif_mock_{datetime.now().timestamp()}"
            logger.info(
                f"[Gateway] Mock 通知: user={request.user_id}, "
                f"title={request.title}, type={request.notification_type}"
            )
            return SendNotificationResponse(
                success=True,
                message_id=message_id,
                platform="mock",
            )

        # 确定平台
        platform = request.platform or "auto"
        if platform == "auto":
            # 尝试从数据库查询用户设备平台
            platform = self._detect_platform(request.user_id)

        if platform == "ios":
            return await self._send_via_apns(request)
        elif platform == "android":
            return await self._send_via_fcm(request)
        else:
            # 尝试两个平台
            result = await self._send_via_fcm(request)
            if not result.success:
                result = await self._send_via_apns(request)
            return result

    async def send_to_user(
        self,
        user_id: str,
        title: str,
        body: str,
        notification_type: str = "daily_rhythm",
        data: Optional[dict] = None,
        high_priority: bool = False,
        skip_quiet_hours: bool = False,
    ) -> SendNotificationResponse:
        """发送通知给指定用户 (自动查询设备 Token)"""
        # 查询用户设备
        token, platform = self._get_user_device(user_id)

        if not token:
            return SendNotificationResponse(
                success=False,
                error="no_device_token",
            )

        request = SendNotificationRequest(
            user_id=user_id,
            token=token,
            platform=platform,
            title=title,
            body=body,
            data=data or {},
            notification_type=notification_type,
            high_priority=high_priority,
            skip_quiet_hours=skip_quiet_hours,
        )
        return await self.send(request)

    async def broadcast(
        self,
        title: str,
        body: str,
        notification_type: str = "daily_rhythm",
        data: Optional[dict] = None,
        topic: Optional[str] = None,
    ) -> dict:
        """广播通知"""
        if self.mode == "mock":
            logger.info(f"[Gateway] Mock 广播: title={title}, type={notification_type}")
            return {"success": True, "mode": "mock"}

        fcm = self._get_fcm()
        result = await fcm.send_to_topic(
            topic=topic or NOTIFICATION_TYPES.get(notification_type, {}).get("topic", "general"),
            title=title,
            body=body,
            data=data or {},
        )
        return {"success": result.success, "message_id": result.message_id}

    async def _send_via_fcm(self, request: SendNotificationRequest) -> SendNotificationResponse:
        """通过 FCM 发送"""
        from app.services.fcm_service import PushMessage
        fcm = self._get_fcm()

        message = PushMessage(
            token=request.token,
            title=request.title,
            body=request.body,
            data=request.data,
            notification_type=request.notification_type,
            sound=request.sound,
            priority="high" if request.high_priority else "normal",
        )

        result = await fcm.send(message)
        return SendNotificationResponse(
            success=result.success,
            message_id=result.message_id,
            platform="android",
            error=result.error,
        )

    async def _send_via_apns(self, request: SendNotificationRequest) -> SendNotificationResponse:
        """通过 APNs 发送"""
        from app.services.apns_service import APNSMessage
        apns = self._get_apns()

        message = APNSMessage(
            token=request.token,
            title=request.title,
            body=request.body,
            data=request.data,
            sound=request.sound,
            priority=10 if request.high_priority else 5,
        )

        result = await apns.send(message)

        quiet_hours_skipped = (result.error == "quiet_hours")

        return SendNotificationResponse(
            success=result.success,
            message_id=result.message_id,
            platform="ios",
            error=result.error,
            quiet_hours_skipped=quiet_hours_skipped,
        )

    def _detect_platform(self, user_id: Optional[str]) -> str:
        """从数据库检测用户设备平台"""
        if not user_id:
            return "android"

        try:
            from app.database.db import get_db
            db = get_db()
            row = db.execute(
                "SELECT platform FROM users WHERE id = ? LIMIT 1",
                (user_id,),
            ).fetchone()
            if row and row["platform"]:
                return str(row["platform"])
        except Exception as e:
            logger.debug(f"[Gateway] 平台检测失败: {e}")

        return "android"  # 默认

    def _get_user_device(self, user_id: str) -> tuple[Optional[str], Optional[str]]:
        """获取用户的推送 Token 和平台"""
        try:
            from app.database.db import get_db
            db = get_db()

            # 先查新表
            row = db.execute(
                """SELECT device_id, platform, push_token, is_active
                   FROM user_devices WHERE user_id = ? AND is_active = 1
                   ORDER BY last_active_at DESC LIMIT 1""",
                (user_id,),
            ).fetchone()

            if row:
                return row["push_token"], row["platform"]

            return None, None
        except Exception as e:
            logger.debug(f"[Gateway] 设备查询失败: {e}")
            return None, None


# 通知类型配置 (导入复用)
NOTIFICATION_TYPES = {
    "daily_rhythm": {"topic": "daily_rhythm", "default_title": "顺时提醒"},
    "seasonal": {"topic": "seasonal", "default_title": "节气提醒"},
    "reflection": {"topic": "reflection", "default_title": "反思时刻"},
}


# ==================== 单例 ====================

notification_gateway = NotificationGateway()
