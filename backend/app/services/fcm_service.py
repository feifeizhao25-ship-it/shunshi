"""
顺时 ShunShi - FCM 推送服务 (Android)
使用 firebase-admin-sdk
支持: 注册 Token / 发送通知 / 批量发送 / 主题订阅

3 类通知:
  - DailyRhythm: 每日节律提醒 (早安/晚安/运动)
  - Seasonal: 节气/季节变化提醒
  - Reflection: 反思/情绪关怀

Mock 模式: FCM_MODE=mock 或无有效凭据时自动降级
"""
import os
import json
import logging
from datetime import datetime
from typing import Optional

from pydantic import BaseModel

logger = logging.getLogger(__name__)

# ==================== 配置 ====================

FCM_MODE = os.getenv("FCM_MODE", "mock")  # mock / production

FCM_CREDENTIALS_PATH = os.getenv("FCM_CREDENTIALS_PATH", "")
FCM_CREDENTIALS_JSON = os.getenv("FCM_CREDENTIALS_JSON", "")  # JSON 字符串
FCM_PROJECT_ID = os.getenv("FCM_PROJECT_ID", "shunshi-push")

# ==================== 通知类型 ====================

NOTIFICATION_TYPES = {
    "daily_rhythm": {
        "topic": "daily_rhythm",
        "default_title": "顺时提醒",
        "sound": "gentle_chime.wav",
    },
    "seasonal": {
        "topic": "seasonal",
        "default_title": "节气提醒",
        "sound": "nature_bell.wav",
    },
    "reflection": {
        "topic": "reflection",
        "default_title": "反思时刻",
        "sound": "soft_tone.wav",
    },
}


# ==================== 数据模型 ====================

class PushMessage(BaseModel):
    """推送消息"""
    token: str
    title: str
    body: str
    data: dict = {}
    notification_type: str = "daily_rhythm"
    sound: str = "default"
    priority: str = "high"
    ttl: int = 86400  # 24h


class PushResult(BaseModel):
    """推送结果"""
    success: bool
    message_id: str = ""
    error: str = ""
    mode: str = "mock"


class TokenRegistration(BaseModel):
    """Token 注册"""
    user_id: str
    token: str
    platform: str = "android"
    app_version: str = ""


class TopicSubscription(BaseModel):
    """主题订阅"""
    token: str
    topic: str
    subscribe: bool = True


# ==================== 服务实现 ====================

class FCMService:
    """Firebase Cloud Messaging 推送服务"""

    def __init__(self) -> None:
        self.mode = FCM_MODE
        self._app = None

    def _get_app(self):
        """延迟初始化 Firebase App"""
        if self._app:
            return self._app
        if self.mode == "mock":
            return None

        try:
            import firebase_admin
            from firebase_admin import credentials

            if firebase_admin._apps:
                self._app = firebase_admin.get_app()
                return self._app

            cred_data: Optional[dict] = None
            if FCM_CREDENTIALS_JSON:
                cred_data = json.loads(FCM_CREDENTIALS_JSON)
            elif FCM_CREDENTIALS_PATH and os.path.exists(FCM_CREDENTIALS_PATH):
                with open(FCM_CREDENTIALS_PATH, "r") as f:
                    cred_data = json.load(f)

            if cred_data:
                cred = credentials.Certificate(cred_data)
                self._app = firebase_admin.initialize_app(cred)
                logger.info(f"[FCM] Firebase 初始化完成 (project={FCM_PROJECT_ID})")
                return self._app
            else:
                logger.warning("[FCM] 无有效凭据，降级到 mock 模式")
                self.mode = "mock"
                return None

        except ImportError:
            logger.warning("[FCM] firebase-admin 未安装，降级到 mock 模式")
            self.mode = "mock"
            return None

    async def register_token(self, registration: TokenRegistration) -> bool:
        """注册推送 Token"""
        # 保存到数据库
        try:
            from app.database.db import get_db
            db = get_db()
            now = datetime.now().isoformat()

            # 更新设备表
            db.execute(
                """INSERT OR REPLACE INTO user_settings (user_id, updated_at)
                   VALUES (?, ?)""",
                (registration.user_id, now),
            )
            db.commit()
        except Exception as e:
            logger.error(f"[FCM] Token 注册失败: {e}")

        logger.info(
            f"[FCM] Token 注册: user={registration.user_id}, "
            f"platform={registration.platform}, mode={self.mode}"
        )
        return True

    async def send(self, message: PushMessage) -> PushResult:
        """发送单条推送通知"""
        app = self._get_app()

        if app and self.mode != "mock":
            try:
                from firebase_admin import messaging

                notification = messaging.Notification(
                    title=message.title,
                    body=message.body,
                )
                android_config = messaging.AndroidConfig(
                    notification=messaging.AndroidNotification(
                        sound=message.sound,
                        priority=message.priority.upper(),
                        notification_count=1,
                    ),
                    ttl=message.ttl,
                )

                fcm_message = messaging.Message(
                    token=message.token,
                    notification=notification,
                    data={k: str(v) for k, v in message.data.items()},
                    android=android_config,
                )

                result = messaging.send(fcm_message)
                return PushResult(
                    success=True,
                    message_id=result,
                    mode=self.mode,
                )
            except Exception as e:
                logger.error(f"[FCM] 发送失败: {e}")
                return PushResult(success=False, error=str(e), mode=self.mode)
        else:
            # Mock 模式
            message_id = f"fcm_mock_{datetime.now().timestamp()}"
            logger.info(
                f"[FCM] Mock 发送: token={message.token[:20]}..., "
                f"title={message.title}"
            )
            return PushResult(
                success=True,
                message_id=message_id,
                mode="mock",
            )

    async def send_bulk(self, messages: list[PushMessage]) -> list[PushResult]:
        """批量发送推送通知"""
        results: list[PushResult] = []
        for msg in messages:
            result = await self.send(msg)
            results.append(result)
        return results

    async def subscribe_to_topic(self, subscription: TopicSubscription) -> bool:
        """订阅/退订主题"""
        app = self._get_app()

        if app and self.mode != "mock":
            try:
                from firebase_admin import messaging

                if subscription.subscribe:
                    response = messaging.subscribe_to_topic(
                        [subscription.token], subscription.topic
                    )
                else:
                    response = messaging.unsubscribe_from_topic(
                        [subscription.token], subscription.topic
                    )

                success = response.success_count > 0
                if not success:
                    for err in response.errors:
                        logger.error(f"[FCM] 主题订阅失败: {err.reason}")
                return success
            except Exception as e:
                logger.error(f"[FCM] 主题订阅异常: {e}")
                return False
        else:
            logger.info(
                f"[FCM] Mock 主题{'订阅' if subscription.subscribe else '退订'}: "
                f"topic={subscription.topic}"
            )
            return True

    async def send_to_topic(
        self,
        topic: str,
        title: str,
        body: str,
        data: Optional[dict] = None,
    ) -> PushResult:
        """向主题发送通知"""
        app = self._get_app()
        message_id = f"fcm_topic_{datetime.now().timestamp()}"

        if app and self.mode != "mock":
            try:
                from firebase_admin import messaging

                notification = messaging.Notification(title=title, body=body)
                message = messaging.Message(
                    topic=topic,
                    notification=notification,
                    data=data or {},
                )
                result = messaging.send(message)
                return PushResult(success=True, message_id=result, mode=self.mode)
            except Exception as e:
                logger.error(f"[FCM] 主题发送失败: {e}")
                return PushResult(success=False, error=str(e), mode=self.mode)
        else:
            logger.info(f"[FCM] Mock 主题发送: topic={topic}, title={title}")
            return PushResult(success=True, message_id=message_id, mode="mock")


# ==================== 单例 ====================

fcm_service = FCMService()
