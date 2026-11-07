from concurrent.futures import ThreadPoolExecutor
from threading import Barrier
from types import SimpleNamespace

import pytest

from app.database.db import get_db, close_test_connection
from app.services.alipay_service import alipay_service
from app.services.payment_activation import activate_verified_domestic_payment
from app.services.refund_requests import submit_refund_request
from app.simple_models import Entitlement
from .test_domestic_payment_recovery import order_for

URL = '/api/v1/payments/alipay/refund'


@pytest.fixture
def paid(client, auth_headers, monkeypatch):
    def forbidden(**kwargs):
        pytest.fail('A refund request must not execute merchant refunds')
    monkeypatch.setattr(alipay_service, 'refund', forbidden)
    order, args = order_for(client, auth_headers)
    activate_verified_domestic_payment(SimpleNamespace(app=client.app), **args)
    return order


@pytest.mark.parametrize('amount', ['0', '-1', 'NaN', 'Infinity', '1e1', '1.001', '400.00'])
def test_invalid_or_excessive_amount_never_creates_request(client, auth_headers, paid, amount):
    response = client.post(URL, headers=auth_headers,
        json={'order_no': paid['order_no'], 'refund_amount': amount})
    assert response.status_code == 400
    assert client.get(URL, headers=auth_headers,
        params={'order_no': paid['order_no']}).status_code == 404


def test_request_is_persistent_idempotent_and_does_not_revoke_entitlements(client, auth_headers, paid):
    with client.app.state.session_factory() as session:
        expiry = session.get(Entitlement, paid['user_id']).expires_at
    args = {'order_no': paid['order_no'], 'refund_amount': '29.00'}
    first = client.post(URL, headers=auth_headers, json=args)
    assert first.status_code == 202
    assert first.json()['data']['refund_completed'] is False
    assert first.json()['data']['status_label'] == '待处理'
    second = client.post(URL, headers=auth_headers, json={**args, 'refund_amount': '29'})
    assert second.json()['data'] == first.json()['data']
    queried = client.get(URL, headers=auth_headers, params={'order_no': paid['order_no']})
    assert queried.json()['data'] == first.json()['data']
    changed = client.post(URL, headers=auth_headers, json={**args, 'refund_amount': '1.00'})
    assert changed.status_code == 409
    with client.app.state.session_factory() as session:
        assert session.get(Entitlement, paid['user_id']).expires_at == expiry
    db = get_db()
    try:
        assert db.execute('SELECT status FROM payment_orders WHERE order_no=?',
            (paid['order_no'],)).fetchone()[0] == 'paid'
        assert db.execute('SELECT count(*) FROM domestic_refund_requests WHERE order_no=?',
            (paid['order_no'],)).fetchone()[0] == 1
    finally:
        close_test_connection(db)


def test_other_user_cannot_submit_or_read_refund(client, auth_headers, paid):
    token = client.post('/api/v1/auth/guest-login', json={}).json()['access_token']
    other = {'Authorization': 'Bearer ' + token}
    assert client.post(URL, headers=other, json={'order_no': paid['order_no'],
        'refund_amount': '1.00'}).status_code == 404
    assert client.get(URL, headers=other, params={'order_no': paid['order_no']}).status_code == 404


@pytest.mark.parametrize('field,value,expected', [
    ('status', 'pending', 409), ('status', 'refunded', 409),
    ('platform', 'wechat', 400), ('currency', 'USD', 400),
])
def test_only_confirmed_domestic_alipay_order_is_accepted(client, auth_headers, paid, field, value, expected):
    db = get_db()
    try:
        # Column names are fixed by this test's parameter list.
        db.execute(f'UPDATE payment_orders SET {field}=? WHERE order_no=?', (value, paid['order_no']))
        db.commit()
    finally:
        close_test_connection(db)
    assert client.post(URL, headers=auth_headers, json={'order_no': paid['order_no'],
        'refund_amount': '1.00'}).status_code == expected


def _yuan(cents):
    return f"{cents // 100}.{cents % 100:02d}"


def _row(order_no):
    db = get_db()
    try:
        return dict(db.execute('SELECT * FROM payment_orders WHERE order_no=?', (order_no,)).fetchone())
    finally:
        close_test_connection(db)


def _expiry(app, user_id):
    with app.state.session_factory() as session:
        row = session.get(Entitlement, user_id)
        return None if row is None else row.expires_at


def _notice(order, **changes):
    from app.services.alipay_service import AlipayNotifyData
    payload = dict(
        out_trade_no=order['order_no'], trade_no=order['transaction_id'],
        trade_status='TRADE_CLOSED', total_amount=_yuan(order['amount_cents']),
        buyer_id='buyer', refund_fee=_yuan(order['amount_cents']),
        gmt_refund='2026-11-07 18:00:00', out_biz_no='RF-SETTLE-1',
    )
    payload.update(changes)
    return AlipayNotifyData(**payload)


def _post_notice(client, monkeypatch, notice):
    from app.services import alipay_service as module
    monkeypatch.setattr(module.alipay_service, 'verify_notify', lambda _params: notice)
    monkeypatch.setattr(module.alipay_service, 'refund', lambda *args, **kwargs: pytest.fail('merchant refund'))
    return client.post('/api/v1/payments/alipay/notify', data={'sign': 'verifier-stub'})


def test_verified_full_refund_settles_only_that_order_and_is_idempotent(client, auth_headers, paid, monkeypatch):
    first_order = _row(paid['order_no'])
    first_expiry = _expiry(client.app, first_order['user_id'])
    _, second_args = order_for(client, auth_headers)
    activate_verified_domestic_payment(SimpleNamespace(app=client.app), **second_args)
    second = _row(second_args['order_no'])
    extended = _expiry(client.app, first_order['user_id'])
    assert extended > first_expiry
    response = _post_notice(client, monkeypatch, _notice(second))
    assert response.status_code == 200
    assert response.text == 'success'
    assert _row(second['order_no'])['status'] == 'refunded'
    assert _row(first_order['order_no'])['status'] == 'paid'
    assert _expiry(client.app, first_order['user_id']) == first_expiry
    again = _post_notice(client, monkeypatch, _notice(second))
    assert again.status_code == 200
    assert _expiry(client.app, first_order['user_id']) == first_expiry
    replay = _notice(second, refund_fee='', gmt_refund='', trade_status='TRADE_SUCCESS', out_biz_no='')
    assert _post_notice(client, monkeypatch, replay).status_code == 409
    assert _expiry(client.app, first_order['user_id']) == first_expiry


def test_pending_request_stays_unsettled_until_full_verified_notice(client, auth_headers, paid, monkeypatch):
    order = _row(paid['order_no'])
    expiry = _expiry(client.app, order['user_id'])
    requested = client.post(URL, headers=auth_headers, json={
        'order_no': order['order_no'], 'refund_amount': _yuan(order['amount_cents'])})
    assert requested.status_code == 202
    assert requested.json()['data']['refund_completed'] is False
    assert requested.json()['data']['status_label'] == '待处理'
    assert _row(order['order_no'])['status'] == 'paid'
    partial = _notice(order, refund_fee='1.00', out_biz_no='RF-PART')
    assert _post_notice(client, monkeypatch, partial).status_code == 200
    assert _expiry(client.app, order['user_id']) == expiry
    assert client.get(URL, headers=auth_headers, params={'order_no': order['order_no']}).json()['data']['status_label'] == '待处理'
    closed = _notice(order, refund_fee='', gmt_refund='', out_biz_no='')
    assert _post_notice(client, monkeypatch, closed).status_code == 200
    assert _row(order['order_no'])['status'] == 'paid'
    assert _post_notice(client, monkeypatch, _notice(order, trade_no='other-trade', out_biz_no='RF-BAD')).status_code == 409
    assert _expiry(client.app, order['user_id']) == expiry
    done = _post_notice(client, monkeypatch, _notice(order))
    assert done.status_code == 200
    body = client.get(URL, headers=auth_headers, params={'order_no': order['order_no']}).json()['data']
    assert body['refund_completed'] is True
    assert body['status_label'] == '已退款'
    settled_expiry = _expiry(client.app, order['user_id'])
    assert settled_expiry < expiry
    from app.services.payment_recovery import recover_pending_payments
    db = get_db()
    try:
        db.execute("""UPDATE domestic_payment_recovery SET status='pending', attempts=0,
            next_attempt_at=0 WHERE user_id=?""", (order['user_id'],))
        db.commit()
    finally:
        close_test_connection(db)
    assert recover_pending_payments(client.app)['restored'] >= 0
    assert _expiry(client.app, order['user_id']) == settled_expiry


def test_refund_notice_does_not_touch_another_user(client, auth_headers, paid, monkeypatch):
    order = _row(paid['order_no'])
    other_token = client.post('/api/v1/auth/guest-login', json={}).json()['access_token']
    other_headers = {'Authorization': 'Bearer ' + other_token}
    _, other_args = order_for(client, other_headers)
    activate_verified_domestic_payment(SimpleNamespace(app=client.app), **other_args)
    other = _row(other_args['order_no'])
    other_expiry = _expiry(client.app, other['user_id'])
    assert _post_notice(client, monkeypatch, _notice(order, out_biz_no='RF-OWNER')).status_code == 200
    assert _expiry(client.app, other['user_id']) == other_expiry
    assert _row(other['order_no'])['status'] == 'paid'


def test_unverified_or_unconfigured_notice_does_not_settle(client, auth_headers, paid, monkeypatch):
    from app.services import alipay_service as module
    order = _row(paid['order_no'])
    expiry = _expiry(client.app, order['user_id'])
    monkeypatch.setattr(module.alipay_service, 'verify_notify', lambda _params: (_ for _ in ()).throw(RuntimeError('unconfigured')))
    assert client.post('/api/v1/payments/alipay/notify', data={'sign': 'x'}).status_code == 503
    def forged(_params):
        raise ValueError('bad signature')
    monkeypatch.setattr(module.alipay_service, 'verify_notify', forged)
    assert client.post('/api/v1/payments/alipay/notify', data={'sign': 'x'}).status_code == 400
    assert _row(order['order_no'])['status'] == 'paid'
    assert _expiry(client.app, order['user_id']) == expiry


def test_refund_before_payment_does_not_settle(client, auth_headers, monkeypatch):
    created, _args = order_for(client, auth_headers)
    order = _row(created['order_no'])
    order['transaction_id'] = 'trade-early'
    notice = _notice(order, out_biz_no='RF-EARLY')
    # The stored order is still pending and has no transaction id.
    from app.services.alipay_service import AlipayNotifyData
    pending = AlipayNotifyData(
        out_trade_no=order['order_no'], trade_no='trade-early', trade_status='TRADE_CLOSED',
        total_amount=_yuan(order['amount_cents']), buyer_id='buyer', refund_fee=_yuan(order['amount_cents']),
        gmt_refund='2026-11-07 18:00:00', out_biz_no='RF-EARLY')
    assert _post_notice(client, monkeypatch, pending).status_code == 409
    assert _row(order['order_no'])['status'] == 'pending'
    assert _expiry(client.app, order['user_id']) is None


def test_simultaneous_requests_share_one_persistent_refund_number(paid):
    barrier = Barrier(2)
    def submit(_):
        barrier.wait(timeout=5)
        return submit_refund_request(paid['order_no'], paid['user_id'], '1.00', '用户申请退款')
    with ThreadPoolExecutor(max_workers=2) as pool:
        results = list(pool.map(submit, range(2)))
    assert results[0] == results[1]
