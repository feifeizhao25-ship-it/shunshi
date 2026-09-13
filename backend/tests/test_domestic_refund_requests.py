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


@pytest.mark.parametrize('amount', ['0', '-1', 'NaN', 'Infinity', '1e1', '1.001', '30.00'])
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


def test_simultaneous_requests_share_one_persistent_refund_number(paid):
    barrier = Barrier(2)
    def submit(_):
        barrier.wait(timeout=5)
        return submit_refund_request(paid['order_no'], paid['user_id'], '1.00', '用户申请退款')
    with ThreadPoolExecutor(max_workers=2) as pool:
        results = list(pool.map(submit, range(2)))
    assert results[0] == results[1]
