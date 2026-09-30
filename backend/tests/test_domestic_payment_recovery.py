"""Real local ledger/entitlement commits with failures at the storage boundary."""
from contextlib import contextmanager
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime
from threading import Barrier
from types import SimpleNamespace

import pytest
from fastapi import HTTPException

from app.database.db import get_db, close_test_connection
from app.router import subscription as sub
from app.services.payment_activation import activate_verified_domestic_payment
from app.simple_models import Entitlement


def order_for(client, headers, product="yangxin_monthly"):
    response = client.post('/api/v1/subscription/create-order', headers=headers,
        json={"product_id": product, "platform": "alipay"})
    assert response.status_code == 200, response.text
    order = sub.payment_orders[response.json()['data']['order_id']]
    return order, dict(order_no=order['order_no'], transaction_id='trade-' + order['id'],
        amount_cents=order['amount_cents'], provider='alipay')


@pytest.mark.parametrize("failure", ["missing_factory", "before_commit", "after_commit"])
def test_paid_ledger_survives_projection_failure_and_retry_does_not_add_days(
    client, auth_headers, monkeypatch, failure,
):
    order, args = order_for(client, auth_headers)
    factory = client.app.state.session_factory

    @contextmanager
    def broken_factory():
        with factory() as session:
            original_commit = session.commit
            def fail_commit():
                if failure == "after_commit":
                    original_commit()
                raise RuntimeError("injected storage acknowledgement failure")
            session.commit = fail_commit
            yield session

    monkeypatch.setattr(client.app.state, 'session_factory',
        None if failure == 'missing_factory' else broken_factory)
    request = SimpleNamespace(app=client.app)
    with pytest.raises(HTTPException) as error:
        activate_verified_domestic_payment(request, **args)
    assert error.value.status_code == 503
    db = get_db()
    try:
        paid = db.execute('SELECT * FROM payment_orders WHERE id=?', (order['id'],)).fetchone()
        assert paid['status'] == 'paid'
        assert paid['transaction_id'] == args['transaction_id']
        expiry = db.execute('SELECT expires_at FROM subscriptions WHERE user_id=?',
            (order['user_id'],)).fetchone()[0]
        # Drop process caches to exercise durable recovery after restart.
        sub.payment_orders.clear()
        sub.subscriptions.clear()
        monkeypatch.setattr(client.app.state, 'session_factory', factory)
        for _ in range(2):
            activate_verified_domestic_payment(request, **args)
            with factory() as session:
                assert session.get(Entitlement, order['user_id']).expires_at == int(
                    datetime.fromisoformat(expiry).timestamp())
        assert db.execute('SELECT count(*) FROM subscriptions WHERE user_id=?',
            (order['user_id'],)).fetchone()[0] == 1
        assert sub.subscriptions[order['user_id']]['expires_at'] == expiry
        assert len([h for h in sub.purchase_history[order['user_id']]
                    if h['order_id'] == order['id']]) == 1
    finally:
        close_test_connection(db)


def test_old_callback_recovers_latest_renewal_without_resetting_family_members(client, auth_headers):
    request = SimpleNamespace(app=client.app)
    first, first_args = order_for(client, auth_headers, 'jiahe_monthly')
    activate_verified_domestic_payment(request, **first_args)
    user_id = first['user_id']
    sub.bind_family_member(user_id, '家人')
    second, second_args = order_for(client, auth_headers, 'jiahe_monthly')
    activate_verified_domestic_payment(request, **second_args)
    with client.app.state.session_factory() as session:
        entitlement = session.get(Entitlement, user_id)
        expiry = entitlement.expires_at
        session.delete(entitlement)
        session.commit()
    sub.subscriptions.clear()
    barrier = Barrier(2)
    def replay(args):
        barrier.wait(timeout=5)
        return activate_verified_domestic_payment(request, **args)
    # Independent SQLite connections attempt to repair the same missing row.
    with ThreadPoolExecutor(max_workers=2) as pool:
        results = list(pool.map(replay, [first_args, second_args]))
    assert all(result['status'] == 'paid' for result in results)
    with client.app.state.session_factory() as session:
        entitlement = session.get(Entitlement, user_id)
        assert entitlement.expires_at == expiry
        assert entitlement.original_transaction_id == second_args['transaction_id']
    assert sub.subscriptions[user_id]['order_id'] == second['id']
    assert sub.get_family_seats_info(user_id)['used_seats'] == 1
    assert sub.family_seats[user_id]['order_id'] == second['id']


def test_old_domestic_replay_does_not_overwrite_other_store(client, auth_headers):
    order, args = order_for(client, auth_headers)
    request = SimpleNamespace(app=client.app)
    activate_verified_domestic_payment(request, **args)
    with client.app.state.session_factory() as session:
        entitlement = session.get(Entitlement, order['user_id'])
        entitlement.store = 'apple'
        entitlement.original_transaction_id = 'apple-' + order['id']
        session.commit()
    with pytest.raises(HTTPException) as error:
        activate_verified_domestic_payment(request, **args)
    assert error.value.status_code == 409
    with client.app.state.session_factory() as session:
        assert session.get(Entitlement, order['user_id']).store == 'apple'


@pytest.mark.parametrize('existing_entitlement', [False, True])
def test_domestic_projection_serializes_with_store_restore(client, auth_headers, existing_entitlement):
    """Exercise independent DB sessions, including a missing entitlement row."""
    import time
    from datetime import timedelta, timezone
    from threading import Event, local
    from sqlalchemy import event, select, func
    from app.services.store_restore import persist_restore
    from app.simple_models import StorePurchase, StorePurchaseOwner

    order, args = order_for(client, auth_headers)
    factory = client.app.state.session_factory
    with factory() as session:
        engine = session.get_bind()
        if existing_entitlement:
            session.add(Entitlement(user_id=order['user_id'], product_id='yangxin_monthly',
                store='alipay', expires_at=int(time.time()) - 60,
                original_transaction_id='expired-domestic'))
            session.commit()
    projection_read = Event()
    release_projection = Event()
    restore_attempt = Event()
    restore_done = Event()
    role = local()

    def before_execute(conn, cursor, statement, parameters, context, executemany):
        sql = statement.lower()
        if getattr(role, 'name', '') == 'domestic' and sql.startswith('select') and 'from entitlements' in sql:
            projection_read.set()
            assert release_projection.wait(5), 'test did not release domestic projection'
        if getattr(role, 'name', '') == 'store' and sql.startswith('update users'):
            restore_attempt.set()

    def domestic():
        role.name = 'domestic'
        return activate_verified_domestic_payment(SimpleNamespace(app=client.app), **args)

    def store():
        role.name = 'store'
        try:
            with factory() as session:
                persist_restore(session, user_id=order['user_id'], store='ios',
                    transaction_id='concurrent-store', chain_id='concurrent-chain',
                    product_id='com.shunshi.yiyang.yearly', plan='yiyang',
                    expires_at=datetime.now(timezone.utc) + timedelta(days=365),
                    auto_renew=False, receipt_hash='fixture-hash')
            return 200
        except HTTPException as exc:
            return exc.status_code
        finally:
            restore_done.set()

    event.listen(engine, 'before_cursor_execute', before_execute)
    try:
        with ThreadPoolExecutor(max_workers=2) as pool:
            payment = pool.submit(domestic)
            try:
                assert projection_read.wait(5)
                restoration = pool.submit(store)
                assert restore_attempt.wait(5)
                assert not restore_done.wait(0.3), 'store bypassed domestic account lock'
            finally:
                release_projection.set()
            assert payment.result(timeout=5)['status'] == 'paid'
            assert restoration.result(timeout=5) == 409
    finally:
        event.remove(engine, 'before_cursor_execute', before_execute)
    with factory() as session:
        assert session.get(Entitlement, order['user_id']).store == 'alipay'
        assert session.scalar(select(func.count()).select_from(StorePurchase)) == 0
        assert session.scalar(select(func.count()).select_from(StorePurchaseOwner)) == 0
