"""
app.alerts — 支付异常实时告警系统

支持钉钉/微信企业号/通用 Webhook 渠道。
"""

from app.alerts.sender import AlertEvent, AlertSender, alert_sender
from app.alerts.rules import AlertRules
from app.alerts.store import AlertStore, alert_store

__all__ = [
    "AlertEvent",
    "AlertSender",
    "alert_sender",
    "AlertRules",
    "AlertStore",
    "alert_store",
]
