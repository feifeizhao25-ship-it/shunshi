from datetime import datetime, timedelta, timezone
from unittest.mock import AsyncMock
import time

from fastapi.testclient import TestClient
from sqlalchemy import select, func

from app.main import create_app
from app.router import subscription
from app.simple_models import Entitlement, StorePurchase, StorePurchaseOwner
from app.security import verify_token


def setup_verifier(monkeypatch, tx='transaction-1', chain='chain-1', expiry=None):
    result = {'valid': True, 'product_id': 'com.shunshi.yiyang.yearly',
              'transaction_id': tx, 'original_transaction_id': chain,
              'expires_at_ms': expiry or int((time.time()+86400)*1000)}
    monkeypatch.setattr('app.services.apple_receipt.verify_apple_receipt', AsyncMock(return_value=result))
    return result


def restore(client, headers, path='/restore'):
    return client.post('/api/v1/subscription'+path, headers=headers, json={'platform': 'ios', 'receipt': 'private-receipt'})


def other_account(client):
    token = client.post('/api/v1/auth/guest-login', json={}).json()['access_token']
    return {'Authorization': f'Bearer {token}'}


def test_restart_keeps_entitlements_and_history(client, auth_headers, settings, monkeypatch):
    setup_verifier(monkeypatch)
    assert restore(client, auth_headers).status_code == 200
    subscription.subscriptions.clear()
    subscription.purchase_history.clear()
    with TestClient(create_app(settings)) as restarted:
        current = restarted.get('/api/v1/subscription/status', headers=auth_headers).json()
        assert current['active'] is True and current['tier'] == 'pro'
        legacy = restarted.get('/api/v1/subscription', headers=auth_headers).json()
        assert legacy['data']['plan'] == 'yiyang'
        history = restarted.get('/api/v1/subscription/history', headers=auth_headers).json()['data']
        assert len(history) == 1 and 'private-receipt' not in str(history)
        assert restore(restarted, auth_headers).json()['code'] == 'already_restored'
    with client.app.state.session_factory() as session:
        assert session.scalar(select(func.count()).select_from(StorePurchase)) == 1


def test_receipt_chain_cannot_move_to_another_account(client, auth_headers, monkeypatch):
    setup_verifier(monkeypatch)
    assert restore(client, auth_headers).status_code == 200
    other = other_account(client)
    setup_verifier(monkeypatch, tx='renewal-2')
    assert restore(client, other).status_code == 409
    with client.app.state.session_factory() as session:
        assert session.scalar(select(func.count()).select_from(StorePurchase)) == 1
        assert session.scalar(select(func.count()).select_from(Entitlement)) == 1


def test_same_transaction_cannot_be_reassigned_under_another_chain(client, auth_headers, monkeypatch):
    setup_verifier(monkeypatch)
    assert restore(client, auth_headers).status_code == 200
    setup_verifier(monkeypatch, chain='forged-chain')
    assert restore(client, other_account(client)).status_code == 409
    with client.app.state.session_factory() as session:
        assert session.scalar(select(func.count()).select_from(StorePurchaseOwner)) == 1


def test_old_receipt_does_not_shorten_membership(client, auth_headers, monkeypatch):
    expiry = int((time.time()+10*86400)*1000)
    setup_verifier(monkeypatch, expiry=expiry)
    assert restore(client, auth_headers).status_code == 200
    setup_verifier(monkeypatch, tx='older-tx', expiry=expiry-86400000)
    assert restore(client, auth_headers).status_code == 409
    with client.app.state.session_factory() as session:
        assert session.scalar(select(Entitlement)).expires_at == expiry // 1000
        assert session.scalar(select(func.count()).select_from(StorePurchase)) == 1


def test_existing_domestic_entitlement_is_not_overwritten(client, auth_headers, settings, monkeypatch):
    actor = verify_token(settings, auth_headers['Authorization'].removeprefix('Bearer '))
    with client.app.state.session_factory() as session:
        session.add(Entitlement(user_id=actor, product_id='yiyang_yearly', store='alipay', expires_at=int(time.time()+86400), original_transaction_id='alipay-verified'))
        session.commit()
    setup_verifier(monkeypatch)
    assert restore(client, auth_headers).status_code == 409
    with client.app.state.session_factory() as session:
        assert session.get(Entitlement, actor).store == 'alipay'
        assert session.scalar(select(func.count()).select_from(StorePurchase)) == 0


def test_account_deletion_retains_ownership_and_reports_it(client, auth_headers, monkeypatch):
    setup_verifier(monkeypatch)
    assert restore(client, auth_headers).status_code == 200
    exported = client.get('/api/v1/auth/data/export', headers=auth_headers)
    assert len(exported.json()['store_purchases']) == 1
    deleted = client.delete('/api/v1/auth/account', headers=auth_headers)
    assert deleted.status_code == 200
    assert deleted.json()['retained_billing_records']['store_purchase_owners'] == 1
    assert restore(client, other_account(client)).status_code == 409


def test_restore_alias_uses_same_persistent_transaction(client, auth_headers, monkeypatch):
    setup_verifier(monkeypatch)
    assert restore(client, auth_headers, '/restore-purchase').json()['code'] == 'restored'
    response = client.post('/api/v1/subscription/verify-receipt-v2', headers=auth_headers, json={'platform': 'ios', 'receipt_data': 'private-receipt'})
    assert response.status_code == 200, response.text
    assert response.json()['code'] == 'already_restored'


def test_failed_commit_leaves_no_ownership_or_entitlement(client, auth_headers, settings, monkeypatch):
    from app.services.store_restore import persist_restore
    actor = verify_token(settings, auth_headers['Authorization'].removeprefix('Bearer '))
    with client.app.state.session_factory() as session:
        def fail():
            session.flush()
            raise RuntimeError('injected commit failure')
        monkeypatch.setattr(session, 'commit', fail)
        import pytest
        with pytest.raises(RuntimeError):
            persist_restore(session, user_id=actor, store='ios', transaction_id='fail-tx', chain_id='fail-chain', product_id='com.shunshi.yiyang.yearly', plan='yiyang', expires_at=datetime.now(timezone.utc)+timedelta(days=1), auto_renew=False, receipt_hash=None)
    with client.app.state.session_factory() as session:
        for model in (StorePurchase, StorePurchaseOwner, Entitlement):
            assert session.scalar(select(func.count()).select_from(model)) == 0
