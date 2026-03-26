"""
告警规则 — 预定义的告警事件工厂

所有方法返回 AlertEvent，不直接发送。
user_id 等敏感字段会被截断脱敏。
"""

from __future__ import annotations

import time
import uuid
from datetime import datetime, timezone
from typing import Optional

from app.alerts.sender import AlertEvent


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def _alert_id() -> str:
    return f"alert_{uuid.uuid4().hex[:16]}"


def _mask_user_id(user_id: str) -> str:
    """脱敏: 保留前4位，其余用****替代"""
    if not user_id or len(user_id) <= 4:
        return user_id
    return user_id[:4] + "****"


class AlertRules:
    """预定义告警规则"""

    # ============ 支付告警 ============

    @staticmethod
    def payment_failed(order_id: str, reason: str, amount: float) -> AlertEvent:
        return AlertEvent(
            level="error",
            category="payment",
            title="支付失败",
            message=f"订单 {order_id[:12]} 支付失败: {reason}",
            context={
                "order_id": order_id[:16],
                "reason": reason,
                "amount": f"¥{amount:.2f}",
            },
            timestamp=_now_iso(),
            alert_id=_alert_id(),
        )

    @staticmethod
    def payment_duplicate(transaction_id: str) -> AlertEvent:
        return AlertEvent(
            level="warning",
            category="payment",
            title="重复支付检测",
            message=f"检测到重复交易: {transaction_id[:16]}",
            context={
                "transaction_id": transaction_id[:16],
            },
            timestamp=_now_iso(),
            alert_id=_alert_id(),
        )

    @staticmethod
    def subscription_expired_unexpected(user_id: str, tier: str) -> AlertEvent:
        return AlertEvent(
            level="warning",
            category="payment",
            title="订阅意外过期",
            message=f"用户 {_mask_user_id(user_id)} 的 {tier} 订阅已过期回退",
            context={
                "user_id": user_id,
                "tier": tier,
            },
            timestamp=_now_iso(),
            alert_id=_alert_id(),
            user_id=user_id,
        )

    @staticmethod
    def high_value_payment(amount: float, user_id: str) -> AlertEvent:
        """大额支付告警 (超过 500 元)"""
        return AlertEvent(
            level="warning",
            category="payment",
            title="大额支付",
            message=f"用户 {_mask_user_id(user_id)} 发起大额支付: ¥{amount:.2f}",
            context={
                "user_id": user_id,
                "amount": f"¥{amount:.2f}",
            },
            timestamp=_now_iso(),
            alert_id=_alert_id(),
            user_id=user_id,
        )

    # ============ 安全告警 ============

    @staticmethod
    def safety_crisis_triggered(user_id: str, level: str) -> AlertEvent:
        return AlertEvent(
            level="critical",
            category="safety",
            title="安全危机检测",
            message=f"用户 {_mask_user_id(user_id)} 触发危机级别安全警报",
            context={
                "user_id": user_id,
                "safety_level": level,
            },
            timestamp=_now_iso(),
            alert_id=_alert_id(),
            user_id=user_id,
        )

    @staticmethod
    def suspicious_login(user_id: str, ip: str, device: str) -> AlertEvent:
        return AlertEvent(
            level="warning",
            category="safety",
            title="可疑登录",
            message=f"用户 {_mask_user_id(user_id)} 从新设备/IP登录",
            context={
                "user_id": user_id,
                "ip": ip[:8] + "****" if len(ip) > 8 else ip,
                "device": device,
            },
            timestamp=_now_iso(),
            alert_id=_alert_id(),
            user_id=user_id,
        )

    # ============ 系统/AI 告警 ============

    @staticmethod
    def ai_model_down(provider: str, model: str) -> AlertEvent:
        return AlertEvent(
            level="error",
            category="system",
            title="AI 模型不可用",
            message=f"{provider} 的 {model} 模型调用失败/不可用",
            context={
                "provider": provider,
                "model": model,
            },
            timestamp=_now_iso(),
            alert_id=_alert_id(),
        )

    @staticmethod
    def ai_budget_exceeded(user_id: str, tier: str, usage: float) -> AlertEvent:
        return AlertEvent(
            level="warning",
            category="ai",
            title="AI 用量超额",
            message=f"用户 {_mask_user_id(user_id)} ({tier}) AI 用量已达 {usage:.1f}%",
            context={
                "user_id": user_id,
                "tier": tier,
                "usage_percent": f"{usage:.1f}%",
            },
            timestamp=_now_iso(),
            alert_id=_alert_id(),
            user_id=user_id,
        )
