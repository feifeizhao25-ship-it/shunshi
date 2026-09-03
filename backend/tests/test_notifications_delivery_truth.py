"""通知投递状态不能在推送服务缺失时伪报成功。"""

from importlib import import_module


notifications = import_module("app.router.notifications")


def test_push_fails_closed_when_firebase_is_unavailable(monkeypatch):
    monkeypatch.setattr(notifications, "_FCM_AVAILABLE", False)
    result = notifications.send_push_notification("device-token", "标题", "正文")
    assert result == {
        "success": False,
        "error": "推送服务未配置",
        "provider": "fcm",
    }


def test_push_to_user_reports_zero_successful_deliveries(monkeypatch):
    monkeypatch.setattr(notifications, "_FCM_AVAILABLE", False)
    monkeypatch.setitem(
        notifications.device_tokens,
        "delivery-test-user",
        [{"token": "device-token", "platform": "fcm"}],
    )
    result = notifications.send_push_to_user("delivery-test-user", "标题", "正文")
    assert result["success"] is False
    assert result["sent_count"] == 0
    assert result["total_devices"] == 1
    assert result["results"][0]["success"] is False
