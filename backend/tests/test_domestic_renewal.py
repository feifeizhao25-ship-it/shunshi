from datetime import datetime, timedelta, timezone
from types import SimpleNamespace

import pytest
from fastapi import HTTPException

from app.database.db import get_db, close_test_connection
from app.router import subscription as sub
from app.services import payment_activation
from app.simple_models import Entitlement


@pytest.mark.parametrize("remaining_days,previous_platform", [
    (10, "alipay"), (0, "alipay"), (-10, "alipay"),
    (10, "wechat"), (10, "stripe"),
])
def test_same_plan_renewal_preserves_remaining_time_and_replay_is_idempotent(
    client, auth_headers, monkeypatch, remaining_days, previous_platform,
):
    now = datetime(2026, 9, 10, tzinfo=timezone.utc)

    class Clock(datetime):
        @classmethod
        def now(cls, tz=None):
            return now

    monkeypatch.setattr(payment_activation, "datetime", Clock)
    request = SimpleNamespace(app=client.app)

    def buy():
        response = client.post('/api/v1/subscription/create-order',
            headers=auth_headers, json={"product_id": "yangxin_monthly", "platform": "alipay"})
        assert response.status_code == 200
        order = sub.payment_orders[response.json()['data']['order_id']]
        args = dict(order_no=order['order_no'], transaction_id='trade-' + order['id'],
                    amount_cents=2900, provider='alipay')
        payment_activation.activate_verified_domestic_payment(request, **args)
        return order, args

    first, _ = buy()
    expiry = now + timedelta(days=remaining_days)
    db = get_db()
    try:
        db.execute('UPDATE subscriptions SET expires_at=?,platform=? WHERE user_id=?',
                   (expiry.isoformat(), previous_platform, first['user_id']))
        db.commit()
        with client.app.state.session_factory() as session:
            session.get(Entitlement, first['user_id']).expires_at = int(expiry.timestamp())
            session.commit()
        second, args = buy()
        base = max(now, expiry) if previous_platform in ('alipay', 'wechat') else now
        expected = base + timedelta(days=30)
        for _ in range(2):
            payment_activation.activate_verified_domestic_payment(request, **args)
            with client.app.state.session_factory() as session:
                assert session.get(Entitlement, first['user_id']).expires_at == int(expected.timestamp())
            record = db.execute('SELECT expires_at FROM subscriptions WHERE id=?',
                ('sub_alipay_' + second['order_no'],)).fetchone()
            assert datetime.fromisoformat(record['expires_at']) == expected
        # Historical records overlap; a third purchase adds exactly one term.
        third, _ = buy()
        with client.app.state.session_factory() as session:
            assert session.get(Entitlement, first['user_id']).expires_at == int(
                (expected + timedelta(days=30)).timestamp())
        record = db.execute('SELECT expires_at FROM subscriptions WHERE id=?',
            ('sub_alipay_' + third['order_no'],)).fetchone()
        assert datetime.fromisoformat(record['expires_at']) == expected + timedelta(days=30)
    finally:
        close_test_connection(db)


def test_invalid_existing_expiry_rolls_back_payment_claim(client, auth_headers):
    response = client.post('/api/v1/subscription/create-order', headers=auth_headers,
        json={"product_id": "yangxin_monthly", "platform": "alipay"})
    assert response.status_code == 200
    order = sub.payment_orders[response.json()['data']['order_id']]
    db = get_db()
    try:
        db.execute("INSERT OR IGNORE INTO users (id,name) VALUES (?,?)",
            (order['user_id'], '测试用户'))
        db.execute("""INSERT INTO subscriptions
            (id,user_id,plan,status,started_at,expires_at,auto_renew,platform,subscribed_at)
            VALUES (?,?,'yangxin','active','2026-09-01','broken',0,'alipay','2026-09-01')""",
            ('legacy-' + order['id'], order['user_id']))
        db.commit()
        with pytest.raises(HTTPException) as error:
            payment_activation.activate_verified_domestic_payment(
                SimpleNamespace(app=client.app), order_no=order['order_no'],
                transaction_id='trade-' + order['id'], amount_cents=2900, provider='alipay')
        assert error.value.status_code == 409
        row = db.execute('SELECT status,transaction_id FROM payment_orders WHERE id=?',
            (order['id'],)).fetchone()
        assert row['status'] == 'pending'
        assert row['transaction_id'] is None
        assert db.execute('SELECT count(*) FROM subscriptions WHERE user_id=?',
            (order['user_id'],)).fetchone()[0] == 1
        with client.app.state.session_factory() as session:
            assert session.get(Entitlement, order['user_id']) is None
    finally:
        close_test_connection(db)
