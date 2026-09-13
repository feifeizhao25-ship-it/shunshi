from types import SimpleNamespace

from app.database.db import get_db, close_test_connection
from app.services.payment_activation import activate_verified_domestic_payment
from .test_domestic_payment_recovery import order_for
from .test_domestic_refund_requests import paid  # noqa: F401


def test_export_contains_only_owners_domestic_orders_and_refund_request(client, auth_headers, paid):
    refund = client.post('/api/v1/payments/alipay/refund', headers=auth_headers,
        json={'order_no': paid['order_no'], 'refund_amount': '1.00', 'refund_reason': '用户填写的原因'})
    assert refund.status_code == 202
    other_token = client.post('/api/v1/auth/guest-login', json={}).json()['access_token']
    other_headers = {'Authorization': 'Bearer ' + other_token}
    other, args = order_for(client, other_headers)
    activate_verified_domestic_payment(SimpleNamespace(app=client.app), **args)
    assert client.post('/api/v1/payments/alipay/refund', headers=other_headers,
        json={'order_no': other['order_no'], 'refund_amount': '1.00'}).status_code == 202
    for method in (client.get, client.post):
        response = method('/api/v1/auth/data/export', headers=auth_headers)
        assert response.status_code == 200
        data = response.json()['domestic_billing']
        assert [row['order_no'] for row in data['payment_orders']] == [paid['order_no']]
        assert [row['refund_no'] for row in data['refund_requests']] == [refund.json()['data']['refund_no']]
        assert data['refund_requests'][0]['reason'] == '用户填写的原因'
        assert data['refund_requests'][0]['status'] == 'pending_review'
        assert 'transaction_id' not in data['payment_orders'][0]


def test_empty_billing_export_is_truthful(client, auth_headers):
    data = client.get('/api/v1/auth/data/export', headers=auth_headers).json()
    assert data['domestic_billing'] == {'payment_orders': [], 'refund_requests': []}


def test_deleted_account_token_cannot_access_retained_billing_records(client, auth_headers, paid):
    payload = {'order_no': paid['order_no'], 'refund_amount': '1.00'}
    assert client.post('/api/v1/payments/alipay/refund', headers=auth_headers, json=payload).status_code == 202
    deleted = client.delete('/api/v1/auth/account', headers=auth_headers)
    assert deleted.status_code == 200
    assert deleted.json()['retained_billing_records'] == {
        'payment_orders': 1, 'domestic_refund_requests': 1}
    assert '不表示退款已完成' in deleted.json()['billing_notice']
    for path in ('/api/v1/payments/alipay/refund', '/api/v1/payments/alipay/query-order'):
        assert client.get(path, headers=auth_headers,
            params={'order_no': paid['order_no']}).status_code == 401
    assert client.post('/api/v1/payments/alipay/refund', headers=auth_headers, json=payload).status_code == 401
    assert client.get('/api/v1/auth/data/export', headers=auth_headers).status_code == 401
    db = get_db()
    try:
        assert db.execute('SELECT count(*) FROM domestic_refund_requests WHERE user_id=?',
            (paid['user_id'],)).fetchone()[0] == 1
    finally:
        close_test_connection(db)
