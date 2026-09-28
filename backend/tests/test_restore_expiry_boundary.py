from datetime import datetime, timezone
from unittest.mock import AsyncMock
import time

import pytest
from app.router import subscription
from app.security import verify_token


def actor(settings, headers):
    return verify_token(settings, headers['Authorization'].removeprefix('Bearer '))


def result(platform, expiry):
    return {'valid': True, 'product_id': 'com.shunshi.yiyang.yearly',
            'transaction_id': 'verified-ios', 'order_id': 'verified-android',
            ('expires_at_ms' if platform == 'ios' else 'expiry_time_ms'): expiry}


def restore(client, headers, monkeypatch, platform, verified):
    target = 'app.services.apple_receipt.verify_apple_receipt' if platform == 'ios' else 'app.services.google_purchase.verify_google_purchase'
    monkeypatch.setattr(target, AsyncMock(return_value=verified))
    return client.post('/api/v1/subscription/restore', headers=headers, json={
        'platform': platform, 'receipt': 'test-receipt', 'purchase_token': 'test-token',
        'transaction_id': 'untrusted-client-id', 'product_id': 'com.shunshi.yiyang.yearly',
    })


@pytest.mark.parametrize('platform', ['ios', 'android'])
@pytest.mark.parametrize('expiry', [None, 0, -1, 'not-a-time', 'NaN', 'Infinity', True, 1.5])
def test_bad_or_expired_platform_time_never_grants_membership(client, auth_headers, settings, monkeypatch, platform, expiry):
    user = actor(settings, auth_headers)
    response = restore(client, auth_headers, monkeypatch, platform, result(platform, expiry))
    assert response.status_code == 200
    assert response.json()['success'] is False
    assert user not in subscription.subscriptions
    assert user not in subscription.purchase_history


@pytest.mark.parametrize('platform', ['ios', 'android'])
def test_restore_uses_exact_platform_expiry_and_accepts_verified_renewal(client, auth_headers, settings, monkeypatch, platform):
    user = actor(settings, auth_headers)
    expiry = int((time.time()+86400)*1000)
    first = restore(client, auth_headers, monkeypatch, platform, result(platform, expiry)).json()
    assert first['success'] is True
    assert first['data']['expires_at'] == datetime.fromtimestamp(expiry/1000, timezone.utc).isoformat()
    assert subscription.subscriptions[user]['transaction_id'] == f'verified-{platform}'
    repeated = restore(client, auth_headers, monkeypatch, platform, result(platform, expiry)).json()
    assert repeated['code'] == 'already_restored'
    renewed = restore(client, auth_headers, monkeypatch, platform, result(platform, expiry+86400000)).json()
    assert renewed['code'] == 'restored'
    assert renewed['data']['expires_at'] == datetime.fromtimestamp((expiry+86400000)/1000, timezone.utc).isoformat()


def test_local_history_cannot_manufacture_new_membership(client, auth_headers, settings):
    user = actor(settings, auth_headers)
    subscription.purchase_history[user] = [{'platform': 'iap_ios', 'plan': 'yiyang'}]
    response = client.post('/api/v1/subscription/restore', headers=auth_headers, json={'platform': 'ios'})
    assert response.json()['code'] == 'verification_required'
    assert user not in subscription.subscriptions


def test_unknown_sku_cannot_fallback_to_history(client, auth_headers, settings, monkeypatch):
    user = actor(settings, auth_headers)
    subscription.purchase_history[user] = [{'platform': 'iap_ios', 'plan': 'jiahe'}]
    verified = result('ios', int((time.time()+86400)*1000))
    verified['product_id'] = 'counterfeit.jiahe.yearly'
    response = restore(client, auth_headers, monkeypatch, 'ios', verified)
    assert response.json()['code'] == 'unknown_product'
    assert user not in subscription.subscriptions


def test_missing_verified_transaction_cannot_use_client_id(client, auth_headers, settings, monkeypatch):
    verified = result('ios', int((time.time()+86400)*1000))
    verified.pop('transaction_id')
    response = restore(client, auth_headers, monkeypatch, 'ios', verified)
    assert response.json()['success'] is False
    assert actor(settings, auth_headers) not in subscription.subscriptions
