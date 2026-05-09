"""
告警系统测试
"""

import json
import pytest
from unittest.mock import AsyncMock, patch, MagicMock
from datetime import datetime, timezone

from app.alerts.sender import AlertEvent, AlertSender
from app.alerts.rules import AlertRules
from app.alerts.store import AlertStore


# ==================== Fixtures ====================

def _make_event(**overrides) -> AlertEvent:
    defaults = {
        "level": "error",
        "category": "payment",
        "title": "test alert",
        "message": "test message",
        "context": {"key": "value"},
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "alert_id": "test_alert_001",
    }
    defaults.update(overrides)
    return AlertEvent(**defaults)


@pytest.fixture
def sender():
    """未配置渠道的 sender"""
    return AlertSender(webhook_url="", wechat_url="", enabled=True)


@pytest.fixture
def sender_with_webhook():
    """配置了 webhook 的 sender"""
    return AlertSender(webhook_url="https://hooks.example.com/test", wechat_url="", enabled=True)


@pytest.fixture
def store(tmp_path):
    """使用内存数据库的 AlertStore"""
    s = AlertStore()
    # init_tables 会调用 get_db，这里用 mock
    return s


# ==================== TestAlertSender ====================

class TestAlertSender:
    def test_should_alert_critical(self, sender):
        assert sender.should_alert("critical", "system") is True

    def test_should_alert_error(self, sender):
        assert sender.should_alert("error", "system") is True

    def test_should_alert_warning_payment(self, sender):
        assert sender.should_alert("warning", "payment") is True

    def test_should_alert_warning_safety(self, sender):
        assert sender.should_alert("warning", "safety") is True

    def test_should_not_alert_warning_system(self, sender):
        assert sender.should_alert("warning", "system") is False

    def test_should_not_alert_info(self, sender):
        assert sender.should_alert("info", "payment") is False

    def test_should_not_alert_info_any_category(self, sender):
        assert sender.should_alert("info", "safety") is False

    @pytest.mark.asyncio
    async def test_send_webhook_success(self, sender_with_webhook):
        """Webhook 发送成功"""
        event = _make_event()
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.raise_for_status = MagicMock()

        mock_client = AsyncMock()
        mock_client.post = AsyncMock(return_value=mock_response)
        mock_client.is_closed = False

        sender_with_webhook._client = mock_client
        result = await sender_with_webhook.send(event)
        assert result is True
        mock_client.post.assert_called_once()

    @pytest.mark.asyncio
    async def test_send_webhook_failure_logged(self, sender_with_webhook):
        """Webhook 发送失败不影响业务"""
        event = _make_event()
        mock_client = AsyncMock()
        mock_client.post = AsyncMock(side_effect=Exception("network error"))
        mock_client.is_closed = False

        sender_with_webhook._client = mock_client
        result = await sender_with_webhook.send(event)
        assert result is False

    @pytest.mark.asyncio
    async def test_send_disabled(self, sender):
        """禁用时不发送"""
        sender.enabled = False
        event = _make_event()
        result = await sender.send(event)
        assert result is False

    @pytest.mark.asyncio
    async def test_send_no_channels(self, sender):
        """没有配置渠道时返回 False"""
        event = _make_event()
        result = await sender.send(event)
        assert result is False

    @pytest.mark.asyncio
    async def test_send_level_not_met(self, sender_with_webhook):
        """info 级别不发送"""
        event = _make_event(level="info")
        result = await sender_with_webhook.send(event)
        assert result is False

    @pytest.mark.asyncio
    async def test_send_wechat_success(self):
        sender = AlertSender(webhook_url="", wechat_url="https://qyapi.weixin.qq.com/test", enabled=True)
        event = _make_event()
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.raise_for_status = MagicMock()

        mock_client = AsyncMock()
        mock_client.post = AsyncMock(return_value=mock_response)
        mock_client.is_closed = False

        sender._client = mock_client
        result = await sender.send(event)
        assert result is True


# ==================== TestAlertRules ====================

class TestAlertRules:
    def test_payment_failed_event(self):
        event = AlertRules.payment_failed("order_12345", "签名验证失败", 29.0)
        assert event.level == "error"
        assert event.category == "payment"
        assert event.title == "支付失败"
        assert "order_12345" in event.message
        assert "29.00" in event.context["amount"]
        assert event.alert_id.startswith("alert_")

    def test_safety_crisis_event(self):
        event = AlertRules.safety_crisis_triggered("user_abcdefg", "crisis")
        assert event.level == "critical"
        assert event.category == "safety"
        assert event.title == "安全危机检测"
        assert "user" in event.context["user_id"]

    def test_ai_model_down_event(self):
        event = AlertRules.ai_model_down("siliconflow", "deepseek-v3.2")
        assert event.level == "error"
        assert event.category == "system"
        assert "deepseek-v3.2" in event.message

    def test_payment_duplicate_event(self):
        event = AlertRules.payment_duplicate("txn_abcdef1234567890")
        assert event.level == "warning"
        assert event.category == "payment"

    def test_subscription_expired_event(self):
        event = AlertRules.subscription_expired_unexpected("user_123456", "yiyang")
        assert event.level == "warning"
        assert event.category == "payment"
        assert "yiyang" in event.message

    def test_high_value_payment_event(self):
        event = AlertRules.high_value_payment(999.0, "user_abcdefg")
        assert event.level == "warning"
        assert "999.00" in event.message

    def test_suspicious_login_event(self):
        event = AlertRules.suspicious_login("user_123456", "192.168.1.100", "iPhone 15")
        assert event.level == "warning"
        assert event.category == "safety"
        assert "iPhone 15" in event.context["device"]

    def test_ai_budget_exceeded_event(self):
        event = AlertRules.ai_budget_exceeded("user_abcdefg", "yangxin", 95.5)
        assert event.level == "warning"
        assert event.category == "ai"
        assert "95.5%" in event.message

    def test_user_id_masked_in_context(self):
        """验证 user_id 在 context 中被脱敏"""
        event = AlertRules.safety_crisis_triggered("user_abcdefghij", "crisis")
        # user_id 超过 4 字符时，to_dingtalk_markdown 应脱敏
        md = event.to_dingtalk_markdown()
        assert "****" in md

    def test_dingtalk_markdown_format(self):
        event = AlertRules.payment_failed("order_123", "reason", 59.0)
        md = event.to_dingtalk_markdown()
        assert "###" in md
        assert "error" in md.upper() or "ERROR" in md

    def test_json_payload(self):
        event = AlertRules.ai_model_down("openai", "gpt-4")
        payload = event.to_json_payload()
        assert payload["level"] == "error"
        assert payload["context"].get("provider") == "openai"


# ==================== TestAlertStore ====================

class TestAlertStore:
    @pytest.mark.asyncio
    async def test_record_alert(self):
        store = AlertStore()
        event = _make_event()

        mock_db = MagicMock()
        mock_db.execute = MagicMock(return_value=MagicMock())
        mock_db.commit = MagicMock()

        with patch("app.alerts.store.AlertStore._get_db", return_value=mock_db):
            with patch.object(store, "init_tables"):
                log_id = store.record(event, sent=True, channel="webhook", response="ok")
                assert log_id != ""
                mock_db.execute.assert_called_once()
                mock_db.commit.assert_called_once()

    @pytest.mark.asyncio
    async def test_list_alerts(self):
        store = AlertStore()

        mock_row = MagicMock()
        data = {
            "id": "alog_001",
            "alert_id": "alert_001",
            "level": "error",
            "category": "payment",
            "title": "test",
            "message": "msg",
            "context": "{}",
            "sent": 1,
            "channel": "webhook",
            "response": "ok",
            "created_at": "2026-01-01T00:00:00+00:00",
        }
        mock_row.__getitem__ = lambda self_key, key: data[key]

        mock_cursor = MagicMock()
        mock_cursor.fetchall.return_value = [mock_row]

        mock_db = MagicMock()
        mock_db.execute = MagicMock(return_value=mock_cursor)

        with patch("app.alerts.store.AlertStore._get_db", return_value=mock_db):
            with patch.object(store, "init_tables"):
                result = store.list_alerts(level="error", limit=10)
                assert len(result) == 1
                assert result[0]["level"] == "error"

    @pytest.mark.asyncio
    async def test_stats(self):
        store = AlertStore()
        mock_db = MagicMock()
        # get_stats does 5 queries
        mock_db.execute = MagicMock(side_effect=[
            MagicMock(**{"fetchone.return_value": {"c": 10}}),
            MagicMock(**{"fetchone.return_value": {"c": 8}}),
            MagicMock(**{"fetchall.return_value": [
                MagicMock(**{"__getitem__": lambda s, k: "error" if k == "level" else 5}),
            ]}),
            MagicMock(**{"fetchall.return_value": [
                MagicMock(**{"__getitem__": lambda s, k: "payment" if k == "category" else 5}),
            ]}),
            MagicMock(**{"fetchone.return_value": {"c": 2}}),
        ])

        with patch("app.alerts.store.AlertStore._get_db", return_value=mock_db):
            with patch.object(store, "init_tables"):
                stats = store.get_stats()
                assert stats["total"] == 10
                assert stats["sent"] == 8
                assert stats["failed"] == 2
                assert stats["last_24h"] == 2
