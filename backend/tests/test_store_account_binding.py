import time
from unittest.mock import AsyncMock
from uuid import UUID

import pytest
from sqlalchemy import func, select
from app.simple_models import Entitlement, StorePurchase, StorePurchaseOwner


def account_token(client, headers):
    response = client.get('/api/v1/subscription/store-account', headers=headers)
    assert response.status_code == 200
    return response.json()['data']['app_account_token']


def other_account(client):
    token = client.post('/api/v1/auth/guest-login', json={}).json()['access_token']
    return {'Authorization': f'Bearer {token}'}


def verified(monkeypatch, account):
    result = dict(valid=True, product_id='com.shunshi.yiyang.yearly',
                  transaction_id='transaction', original_transaction_id='chain',
                  expires_at_ms=int((time.time()+86400)*1000))
    if account is not None:
        result['app_account_token'] = account
    monkeypatch.setattr('app.services.apple_receipt.verify_apple_receipt', AsyncMock(return_value=result))


def restore(client, headers, path='/restore', **extra):
    data = {'platform': 'ios', 'receipt': 'fixture-receipt', **extra}
    if path == '/verify-receipt-v2':
        data['receipt_data'] = data.pop('receipt')
    return client.post('/api/v1/subscription'+path, headers=headers, json=data)


def assert_empty(client):
    with client.app.state.session_factory() as session:
        for model in (Entitlement, StorePurchase, StorePurchaseOwner):
            assert session.scalar(select(func.count()).select_from(model)) == 0


def test_token_is_stable_scoped_and_requires_auth(client, auth_headers):
    first = account_token(client, auth_headers)
    assert str(UUID(first)) == first
    assert account_token(client, auth_headers) == first
    assert account_token(client, other_account(client)) != first
    assert client.get('/api/v1/subscription/store-account').status_code in (401, 403)


@pytest.mark.parametrize('path', ['/restore', '/restore-purchase', '/verify-receipt-v2'])
def test_first_receipt_cannot_be_claimed_by_another_account(client, auth_headers, monkeypatch, path):
    original = account_token(client, auth_headers)
    other = other_account(client)
    verified(monkeypatch, original)
    response = restore(client, other, path, app_account_token=account_token(client, other))
    assert response.status_code == 409
    assert_empty(client)
    response = restore(client, auth_headers, path)
    assert response.status_code == 200 and response.json()['success'] is True


@pytest.mark.parametrize('value', [None, '', 'malformed', 123, [], {}])
def test_missing_or_malformed_account_cannot_create_first_owner(client, auth_headers, monkeypatch, value):
    verified(monkeypatch, value)
    assert restore(client, auth_headers).status_code == 409
    assert_empty(client)


def test_legacy_receipt_only_restores_existing_owner(client, auth_headers, monkeypatch):
    token = account_token(client, auth_headers)
    verified(monkeypatch, token.upper())
    assert restore(client, auth_headers).json()['success'] is True
    verified(monkeypatch, None)
    assert restore(client, auth_headers).json()['code'] == 'already_restored'
    assert restore(client, other_account(client)).status_code == 409


def test_existing_owner_still_rejects_conflicting_platform_account(client, auth_headers, monkeypatch):
    verified(monkeypatch, account_token(client, auth_headers))
    assert restore(client, auth_headers).json()['success'] is True
    verified(monkeypatch, account_token(client, other_account(client)))
    assert restore(client, auth_headers).status_code == 409


def test_verify_alias_passes_transaction_selector_to_apple(client, auth_headers, monkeypatch):
    from app.services import apple_receipt
    verified(monkeypatch, account_token(client, auth_headers))
    response = restore(client, auth_headers, '/verify-receipt-v2', transaction_id='selected-transaction')
    assert response.status_code == 200
    assert apple_receipt.verify_apple_receipt.await_args.kwargs['transaction_id'] == 'selected-transaction'



def test_account_endpoint_cannot_select_another_user_or_use_deleted_account(client, auth_headers):
    original = account_token(client, auth_headers)
    assert client.get('/api/v1/subscription/store-account?user_id=someone-else', headers=auth_headers).json()['data']['app_account_token'] == original
    assert client.delete('/api/v1/auth/account', headers=auth_headers).status_code == 200
    assert client.get('/api/v1/subscription/store-account', headers=auth_headers).status_code in (401, 403, 410)


def test_account_endpoint_requires_auth_even_in_testing(client, monkeypatch):
    monkeypatch.setenv('APP_ENV', 'testing')
    assert client.get('/api/v1/subscription/store-account?user_id=someone-else').status_code == 401
