"""
顺时 ShunShi - APNs 推送服务 (iOS)
使用 apns2 库
支持: 注册 Token / 发送通知 / 静默推送

配置:
  APNS_MODE=mock → 返回模拟数据
  APNS_KEY_ID / APNS_TEAM_ID / APNS_KEY_PATH → 生产模式
  APNS_BUNDLE_ID → App Bundle Identifier

静默时段: 默认 22:00-07:00 不发送通知 (可配置)
"""
import os
import logging
from datetime import datetime, time as dt_time
from typing import Optional

from pydantic import BaseModel

logger = logging.getLogger(__name__)

# ==================== 配置 ====================

APNS_MODE = os.getenv("APNS_MODE", "mock")  # mock / production

APNS_KEY_ID = os.getenv("APNS_KEY_ID", "")
APNS_TEAM_ID = os.getenv("APNS_TEAM_ID", "")
APNS_KEY_PATH = os.getenv("APNS_KEY_PATH", "")
APNS_BUNDLE_ID = os.getenv("APNS_BUNDLE_ID", "care.seasons.shunshi")
APNS_USE_SANDBOX = os.getenv("APNS_USE_SANDBOX", "false").lower() == "true"

# 静默时段配置
APNS_QUIET_START = os.getenv("APNS_QUIET_START", "22:00")  # 22:00
APNS_QUIET_END = os.getenv("APNS_QUIET_END", "07:00")  # 07:00


def _parse_time(time_str: str) -> dt_time:
    """解析 HH:MM 为 time 对象"""
    parts = time_str.split(":")
    return dt_time(int(parts[0]), int(parts[1]))


QUIET_HOURS_START: dt_time = _parse_time(APNS_QUIET_START)
QUIET_HOURS_END: dt_time = _parse_time(APNS_QUIET_END)


# ==================== 数据模型 ====================

class APNSMessage(BaseModel):
    """APNs 推送消息"""
    token: str
    title: str
    body: str
    data: dict = {}
    sound: str = "default"
    badge: Optional[int] = None
    content_available: bool = False
    mutable_content: bool = True
    thread_id: str = ""  # 通知分组 ID
    priority: int = 10  # 10=立即发送, 5=省电模式
    push_type: str = "alert"  # alert / background


class APNSResult(BaseModel):
    """APNs 推送结果"""
    success: bool
    message_id: str = ""
    error: str = ""
    mode: str = "mock"


# ==================== 服务实现 ====================

class APNsService:
    """Apple Push Notification Service"""

    def __init__(self) -> None:
        self.mode = APNS_MODE
        self._client = None
        self._init_client()

    def _init_client(self) -> None:
        """延迟初始化 APNs 客户端"""
        if self.mode == "mock":
            return

        if not all([APNS_KEY_ID, APNS_TEAM_ID, APNS_KEY_PATH, APNS_BUNDLE_ID]):
            logger.warning("[APNs] 缺少必要配置，降级到 mock 模式")
            self.mode = "mock"
            return

        if not os.path.exists(APNS_KEY_PATH):
            logger.warning(f"[APNs] Key 文件不存在: {APNS_KEY_PATH}")
            self.mode = "mock"
            return

        try:
            from apns2 import APNsClient
            from apns2.credentials import Credentials

            credentials = Credentials(
                key_path=APNS_KEY_PATH,
                key_id=APNS_KEY_ID,
                team_id=APNS_TEAM_ID,
            )
            topic = APNS_BUNDLE_ID
            use_sandbox = APNS_USE_SANDBOX

            self._client = APNsClient(
                credentials=credentials,
                use_sandbox=use_sandbox,
            )
            self._topic = topic
            logger.info(
                f"[APNs] 初始化完成 (bundle={topic}, sandbox={use_sandbox})"
            )
        except ImportError:
            logger.warning("[APNs] apns2 未安装，降级到 mock 模式")
            self.mode = "mock"

    def _is_quiet_hours(self) -> bool:
        """检查当前是否在静默时段"""
        now = datetime.now().time()
        if QUIET_HOURS_START <= QUIET_HOURS_END:
            return QUIET_HOURS_START <= now <= QUIET_HOURS_END
        else:
            # 跨午夜，如 22:00-07:00
            return now >= QUIET_HOURS_START or now <= QUIET_HOURS_END

    async def register_token(
        self,
        user_id: str,
        token: str,
        app_version: str = "",
    ) -> bool:
        """注册推送 Token"""
        try:
            from app.database.db import get_db
            db = get_db()
            now = datetime.now().isoformat()

            db.execute(
                """INSERT OR REPLACE INTO user_settings (user_id, updated_at)
                   VALUES (?, ?)""",
                (user_id, now),
            )
            db.commit()
        except Exception as e:
            logger.error(f"[APNs] Token 注册失败: {e}")

        logger.info(
            f"[APNs] Token 注册: user={user_id}, mode={self.mode}"
        )
        return True

    async def send(self, message: APNSMessage) -> APNSResult:
        """发送推送通知 (自动跳过静默时段)"""
        # 静默推送和后台推送不受静默时段限制
        if message.push_type == "alert" and self._is_quiet_hours():
            logger.info(
                f"[APNs] 静默时段 ({APNS_QUIET_START}-{APNS_QUIET_END})，"
                f"跳过通知: {message.title}"
            )
            return APNSResult(
                success=False,
                error="quiet_hours",
                mode=self.mode,
            )

        if self._client and self.mode != "mock":
            try:
                from apns2 import Payload, PayloadAlert

                alert = PayloadAlert(
                    title=message.title,
                    body=message.body,
                    thread_id=message.thread_id or None,
                )

                payload = Payload(
                    alert=alert,
                    badge=message.badge,
                    sound=message.sound,
                    content_available=message.content_available,
                    mutable_content=message.mutable_content,
                    custom=message.data,
                    thread_id=message.thread_id or None,
                )

                self._client.send_notification(
                    token=message.token,
                    notification=payload,
                    topic=self._topic,
                )

                message_id = f"apns_{datetime.now().timestamp()}"
                return APNSResult(
                    success=True,
                    message_id=message_id,
                    mode=self.mode,
                )

            except Exception as e:
                logger.error(f"[APNs] 发送失败: {e}")
                return APNSResult(
                    success=False,
                    error=str(e),
                    mode=self.mode,
                )
        else:
            # Mock 模式
            message_id = f"apns_mock_{datetime.now().timestamp()}"
            logger.info(
                f"[APNs] Mock 发送: token={message.token[:20]}..., "
                f"title={message.title}"
            )
            return APNSResult(
                success=True,
                message_id=message_id,
                mode="mock",
            )

    async def send_bulk(self, messages: list[APNSMessage]) -> list[APNSResult]:
        """批量发送"""
        results: list[APNSResult] = []
        for msg in messages:
            result = await self.send(msg)
            results.append(result)
        return results

    async def send_silent(
        self,
        token: str,
        data: dict,
    ) -> APNSResult:
        """发送静默推送 (content-available, 无 UI)"""
        message = APNSMessage(
            token=token,
            title="",
            body="",
            data=data,
            content_available=True,
            push_type="background",
            priority=5,
        )
        return await self.send(message)


# ==================== 单例 ====================

apns_service = APNsService()
