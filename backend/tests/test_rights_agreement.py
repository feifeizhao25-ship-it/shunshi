"""同一位用户的档位、每日对话额度和到期日，各接口必须逐项相同。

国际版以前有两份状态：权益表（/auth/me、/subscription/status、/subscription/plan-usage）
和内存里的 seasons 订阅。内存缺记录时付费用户被读成免费版。
seasons 路由只在国际版进程挂载，国内版测试进程不挂它，所以这里直接调用同一个函数。
"""
import asyncio
import time
import uuid
from datetime import datetime

from app.entitlements import daily_chat_limit_for_plan
from app.router import seasons_subscription as seasons_api
from app.seasons_plans import PLANS, message_line_for_plan
from app.simple_models import Entitlement


def _register(client):
    body = {"email": f"rights-{uuid.uuid4().hex}@example.com", "password": "Fixture-pass-938", "name": "权益对照"}
    response = client.post("/api/v1/auth/register", json=body)
    assert response.status_code == 200, response.text
    payload = response.json()
    return payload["data"]["user"]["id"], {"Authorization": "Bearer " + payload["access_token"]}


def _seed(client, user_id, sku, expires_at):
    with client.app.state.session_factory() as session:
        row = session.get(Entitlement, user_id)
        if row is None:
            row = Entitlement(user_id=user_id, original_transaction_id=uuid.uuid4().hex)
            session.add(row)
        row.product_id = sku
        row.expires_at = expires_at
        row.store = "app_store"
        session.commit()


def _views(client, user_id, headers):
    me = client.get("/api/v1/auth/me", headers=headers)
    status = client.get("/api/v1/subscription/status", headers=headers)
    usage = client.get("/api/v1/subscription/plan-usage", headers=headers)
    assert me.status_code == status.status_code == usage.status_code == 200, (me.status_code, status.status_code, usage.status_code, usage.text)
    with client.app.state.session_factory() as session:
        seasons = asyncio.run(seasons_api.get_subscription_status(user_id=user_id, session=session))
    return me.json()["data"], status.json(), usage.json(), seasons


def test_paid_user_plan_quota_and_expiry_match_across_endpoints(client):
    user_id, headers = _register(client)
    expires_at = int(time.time()) + 10 * 86400
    _seed(client, user_id, "shunshi_yiyang_yearly", expires_at)
    me, status, usage, seasons = _views(client, user_id, headers)

    assert me["subscription_plan"] == status["plan"] == status["data"]["plan"] == usage["plan"] == seasons["plan"] == "yiyang"
    assert me["is_premium"] is True
    assert status["active"] is True and seasons["active"] is True and usage["active"] is True
    assert seasons["tier"] == "premium"
    limit = daily_chat_limit_for_plan("yiyang")
    chat = next(item for item in usage["items"] if item["key"] == "chat_messages")
    assert status["data"]["features"]["daily_chat_limit"] == seasons["daily_chat_limit"] == chat["limit"] == limit == 200
    me_expiry = datetime.fromisoformat(me["subscription_expires_at"]).timestamp()
    assert me_expiry == status["expires_at"] == usage["expires_at"] == seasons["expires_at_unix"] == expires_at


def test_free_user_is_free_on_every_endpoint(client):
    user_id, headers = _register(client)
    me, status, usage, seasons = _views(client, user_id, headers)
    assert me["subscription_plan"] == status["plan"] == usage["plan"] == seasons["plan"] == "free"
    assert me["is_premium"] is False and status["active"] is False and seasons["active"] is False
    assert seasons["tier"] == "free"
    limit = daily_chat_limit_for_plan("free")
    chat = next(item for item in usage["items"] if item["key"] == "chat_messages")
    assert status["data"]["features"]["daily_chat_limit"] == seasons["daily_chat_limit"] == chat["limit"] == limit
    assert me["subscription_expires_at"] is None
    assert status["expires_at"] is None and usage["expires_at"] is None and seasons["expires_at_unix"] is None


def test_seasons_catalogue_message_counts_come_from_the_registry():
    assert PLANS["free"]["features"][0] == message_line_for_plan("free") == "20 AI messages a day"
    assert PLANS["premium"]["features"][0] == message_line_for_plan("premium") == "200 AI messages a day"
    assert "Unlimited" not in PLANS["premium"]["features"][0]
    assert PLANS["premium"]["yearly_price"] == 79.99
    assert PLANS["family"]["yearly_price"] == 159.99
