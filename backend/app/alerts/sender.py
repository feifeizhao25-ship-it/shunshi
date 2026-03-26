"""
告警发送器 — 支持钉钉 Webhook / 微信企业号 / 通用 Webhook

环境变量:
  ALERT_WEBHOOK_URL          — 钉钉/通用 Webhook URL
  ALERT_WECHAT_WEBHOOK_URL   — 微信企业号 Webhook URL
  ALERT_ENABLED              — 是否启用 (default: true)
"""

from __future__ import annotations

import logging
import os
import time
import uuid
from dataclasses import dataclass, field, asdict
from typing import Optional

import httpx

logger = logging.getLogger(__name__)


@dataclass
class AlertEvent:
    """告警事件"""

    level: str            # info | warning | error | critical
    category: str         # payment | safety | system | ai
    title: str
    message: str
    context: dict         # 额外上下文（脱敏后的）
    timestamp: str        # ISO 8601
    alert_id: str         # 唯一 ID

    # ---- 可选字段 ----
    user_id: str = ""

    def to_dingtalk_markdown(self) -> str:
        """钉钉 Markdown 格式"""
        level_emoji = {
            "critical": "🔴",
            "error": "🟠",
            "warning": "🟡",
            "info": "🔵",
        }
        emoji = level_emoji.get(self.level, "⚪")
        ctx_lines = ""
        for k, v in self.context.items():
            if k == "user_id":
                ctx_lines += f"- **{k}**: `{str(v)[:4]}****`  \n"
            else:
                ctx_lines += f"- **{k}**: {v}  \n"
        return (
            f"### {emoji} [{self.level.upper()}] {self.title}\n\n"
            f"> {self.message}\n\n"
            f"{ctx_lines}"
            f"**时间**: {self.timestamp}  \n"
            f"**ID**: `{self.alert_id}`"
        )

    def to_wechat_markdown(self) -> str:
        """微信企业号 Markdown 格式"""
        level_tag = {
            "critical": "🔴严重",
            "error": "🟠错误",
            "warning": "🟡警告",
            "info": "🔵信息",
        }
        tag = level_tag.get(self.level, "⚪未知")
        ctx_lines = ""
        for k, v in self.context.items():
            if k == "user_id":
                ctx_lines += f"> {k}: `{str(v)[:4]}****`\n"
            else:
                ctx_lines += f"> {k}: {v}\n"
        return (
            f"## {tag} {self.title}\n"
            f"> {self.message}\n"
            f"{ctx_lines}"
            f"> 时间: {self.timestamp}\n"
            f"> ID: {self.alert_id}"
        )

    def to_json_payload(self) -> dict:
        """通用 JSON 格式"""
        return {
            "alert_id": self.alert_id,
            "level": self.level,
            "category": self.category,
            "title": self.title,
            "message": self.message,
            "context": self.context,
            "timestamp": self.timestamp,
        }


class AlertSender:
    """
    告警发送器，支持多种渠道。

    - 钉钉 Webhook (markdown)
    - 微信企业号 Webhook (markdown)
    - 通用 JSON Webhook
    """

    def __init__(
        self,
        webhook_url: Optional[str] = None,
        wechat_url: Optional[str] = None,
        enabled: Optional[bool] = None,
    ):
        self.webhook_url = webhook_url or os.getenv("ALERT_WEBHOOK_URL", "")
        self.wechat_url = wechat_url or os.getenv("ALERT_WECHAT_WEBHOOK_URL", "")
        if enabled is not None:
            self.enabled = enabled
        else:
            self.enabled = os.getenv("ALERT_ENABLED", "true").lower() == "true"
        self._client: Optional[httpx.AsyncClient] = None

    async def _get_client(self) -> httpx.AsyncClient:
        if self._client is None or self._client.is_closed:
            self._client = httpx.AsyncClient(timeout=10.0)
        return self._client

    async def close(self):
        if self._client and not self._client.is_closed:
            await self._client.aclose()
            self._client = None

    # ------------------------------------------------------------------
    # Public
    # ------------------------------------------------------------------

    async def send(self, event: AlertEvent) -> bool:
        """
        发送告警到所有已配置渠道。
        返回 True 表示至少一个渠道发送成功。
        """
        if not self.enabled:
            logger.debug("[Alert] 告警已禁用，跳过: %s", event.alert_id)
            return False

        if not self.should_alert(event.level, event.category):
            logger.debug("[Alert] 级别不满足告警条件: %s", event.alert_id)
            return False

        results = []
        if self.webhook_url:
            ok = await self._send_webhook(event)
            results.append(("webhook", ok))
        if self.wechat_url:
            ok = await self._send_wechat(event)
            results.append(("wechat", ok))

        if not results:
            logger.warning("[Alert] 未配置任何告警渠道: %s", event.alert_id)
            return False

        any_ok = any(ok for _, ok in results)
        if not any_ok:
            logger.error("[Alert] 所有渠道发送失败: %s", event.alert_id)
        return any_ok

    def should_alert(self, level: str, category: str = "") -> bool:
        """根据级别和类别决定是否告警"""
        if level == "critical":
            return True
        if level == "error":
            return True
        if level == "warning":
            # warning 级别仅支付和安全类别告警
            return category in ("payment", "safety")
        # info: 不告警
        return False

    # ------------------------------------------------------------------
    # Private: 渠道发送
    # ------------------------------------------------------------------

    async def _send_webhook(self, event: AlertEvent) -> bool:
        """发送到钉钉格式 Webhook"""
        try:
            client = await self._get_client()
            # 钉钉格式
            payload = {
                "msgtype": "markdown",
                "markdown": {
                    "title": f"[{event.level.upper()}] {event.title}",
                    "text": event.to_dingtalk_markdown(),
                },
            }
            resp = await client.post(
                self.webhook_url,
                json=payload,
                timeout=10.0,
            )
            resp.raise_for_status()
            logger.info("[Alert] Webhook 发送成功: %s", event.alert_id)
            return True
        except Exception as e:
            logger.error("[Alert] Webhook 发送失败: %s, error: %s", event.alert_id, e)
            return False

    async def _send_wechat(self, event: AlertEvent) -> bool:
        """发送到微信企业号 Webhook"""
        try:
            client = await self._get_client()
            payload = {
                "msgtype": "markdown",
                "markdown": {
                    "content": event.to_wechat_markdown(),
                },
            }
            resp = await client.post(
                self.wechat_url,
                json=payload,
                timeout=10.0,
            )
            resp.raise_for_status()
            logger.info("[Alert] 微信发送成功: %s", event.alert_id)
            return True
        except Exception as e:
            logger.error("[Alert] 微信发送失败: %s, error: %s", event.alert_id, e)
            return False


# ==================== 全局单例 ====================

alert_sender = AlertSender()
