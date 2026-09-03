"""统一通知网关不得把模拟投递计为成功。"""

import pytest

from app.services.notification_gateway import (
    NotificationGateway,
    SendNotificationRequest,
)


@pytest.mark.asyncio
async def test_unconfigured_single_delivery_fails_closed():
    gateway = NotificationGateway()
    gateway.mode = "mock"
    result = await gateway.send(
        SendNotificationRequest(token="token", platform="android", title="标题", body="正文")
    )
    assert result.success is False
    assert result.message_id == ""
    assert result.error == "notification_service_not_configured"


@pytest.mark.asyncio
async def test_unconfigured_broadcast_fails_closed():
    gateway = NotificationGateway()
    gateway.mode = "mock"
    result = await gateway.broadcast("标题", "正文")
    assert result == {"success": False, "error": "notification_service_not_configured"}
