from types import SimpleNamespace
from threading import Event

import pytest
from fastapi import HTTPException
from fastapi.testclient import TestClient

from app.database.db import get_db, close_test_connection
from app.services import payment_recovery
from app.services.payment_activation import activate_verified_domestic_payment
from app.simple_models import Entitlement, User
from app.main import create_app
from .test_domestic_payment_recovery import order_for


def test_production_lifespan_starts_and_drains_recovery_worker(settings, monkeypatch):
    started, stopped = Event(), Event()
    async def worker(app, stop):
        started.set()
        await stop.wait()
        stopped.set()
    monkeypatch.setattr(payment_recovery, 'payment_recovery_loop', worker)
    production = settings.model_copy(update={
        'env': 'production', 'cors_origins': 'https://example.cn'})
    with TestClient(create_app(production)):
        assert started.wait(timeout=2)
        assert not stopped.is_set()
    assert stopped.is_set()


def test_worker_recovers_without_another_callback_and_retries_with_backoff(client, auth_headers, monkeypatch):
    order, args = order_for(client, auth_headers)
    factory = client.app.state.session_factory
    monkeypatch.setattr(client.app.state, 'session_factory', None)
    with pytest.raises(HTTPException):
        activate_verified_domestic_payment(SimpleNamespace(app=client.app), **args)
    first = payment_recovery.recover_pending_payments(client.app)
    assert first == {'restored': 0, 'retry': 1, 'blocked': 0, 'discarded': 0}
    assert payment_recovery.recover_pending_payments(client.app)['retry'] == 0
    db = get_db()
    try:
        job = db.execute('SELECT * FROM domestic_payment_recovery WHERE user_id=?',
            (order['user_id'],)).fetchone()
        assert job['status'] == 'pending' and job['attempts'] == 1
        monkeypatch.setattr(client.app.state, 'session_factory', factory)
        # Advancing the persisted due time models the next run after restart.
        db.execute('UPDATE domestic_payment_recovery SET next_attempt_at=0 WHERE user_id=?',
            (order['user_id'],))
        db.commit()
        assert payment_recovery.recover_pending_payments(client.app)['restored'] == 1
        with factory() as session:
            assert session.get(Entitlement, order['user_id']).original_transaction_id == args['transaction_id']
        assert db.execute('SELECT status FROM domestic_payment_recovery WHERE user_id=?',
            (order['user_id'],)).fetchone()[0] == 'done'
        assert payment_recovery.recover_pending_payments(client.app)['restored'] == 0
    finally:
        close_test_connection(db)


def test_payment_and_recovery_job_rollback_together(client, auth_headers, monkeypatch):
    order, args = order_for(client, auth_headers)
    original = payment_recovery.enqueue_recovery
    def interrupted(db, user_id):
        original(db, user_id)
        raise RuntimeError('injected before ledger commit')
    monkeypatch.setattr(payment_recovery, 'enqueue_recovery', interrupted)
    with pytest.raises(RuntimeError):
        activate_verified_domestic_payment(SimpleNamespace(app=client.app), **args)
    db = get_db()
    try:
        assert db.execute('SELECT status FROM payment_orders WHERE id=?',
            (order['id'],)).fetchone()[0] == 'pending'
        assert db.execute('SELECT count(*) FROM domestic_payment_recovery WHERE user_id=?',
            (order['user_id'],)).fetchone()[0] == 0
        assert db.execute('SELECT count(*) FROM subscriptions WHERE user_id=?',
            (order['user_id'],)).fetchone()[0] == 0
    finally:
        close_test_connection(db)


def test_missing_subscription_is_blocked_without_manufacturing_entitlement(client, auth_headers, monkeypatch):
    order, args = order_for(client, auth_headers)
    factory = client.app.state.session_factory
    monkeypatch.setattr(client.app.state, 'session_factory', None)
    with pytest.raises(HTTPException):
        activate_verified_domestic_payment(SimpleNamespace(app=client.app), **args)
    monkeypatch.setattr(client.app.state, 'session_factory', factory)
    db = get_db()
    try:
        db.execute('DELETE FROM subscriptions WHERE user_id=?', (order['user_id'],))
        db.commit()
        assert payment_recovery.recover_pending_payments(client.app)['blocked'] == 1
        with factory() as session:
            assert session.get(Entitlement, order['user_id']) is None
        assert db.execute('SELECT status FROM domestic_payment_recovery WHERE user_id=?',
            (order['user_id'],)).fetchone()[0] == 'blocked'
    finally:
        close_test_connection(db)


@pytest.mark.parametrize('delete_via_api', [False, True])
def test_worker_discards_deleted_account_job(client, auth_headers, monkeypatch, delete_via_api):
    order, args = order_for(client, auth_headers)
    factory = client.app.state.session_factory
    monkeypatch.setattr(client.app.state, 'session_factory', None)
    with pytest.raises(HTTPException):
        activate_verified_domestic_payment(SimpleNamespace(app=client.app), **args)
    monkeypatch.setattr(client.app.state, 'session_factory', factory)
    if delete_via_api:
        response = client.delete('/api/v1/auth/account', headers=auth_headers)
        assert response.status_code == 200, response.text
    else:
        with factory() as session:
            session.delete(session.get(User, order['user_id']))
            session.commit()
    assert payment_recovery.recover_pending_payments(client.app)['discarded'] == (0 if delete_via_api else 1)
    with factory() as session:
        assert session.get(Entitlement, order['user_id']) is None
    db = get_db()
    try:
        assert db.execute('SELECT count(*) FROM domestic_payment_recovery WHERE user_id=?',
            (order['user_id'],)).fetchone()[0] == 0
    finally:
        close_test_connection(db)
