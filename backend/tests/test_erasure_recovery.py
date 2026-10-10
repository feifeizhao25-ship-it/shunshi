"""Fault injection at both external stores and the core commit boundary."""
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import event
from app.main import create_app
from app.security import issue_token, verify_token
from app.simple_models import AccountErasureJob, User
from app.services import account_erasure
from app.services.erasure_recovery import recover_pending_erasures
from .test_account_erasure import _count_product_store, _count_record_store


@pytest.mark.parametrize('store', ['record', 'product'])
def test_failed_cleanup_survives_restart_and_blocks_other_device(client, auth_headers, settings, monkeypatch, store):
    user_id = verify_token(settings, auth_headers['Authorization'][7:])
    second_device = {'Authorization':'Bearer ' + issue_token(settings, user_id)['access_token']}
    assert client.post('/api/v1/family/members', headers=auth_headers,
        json={'name':'家人','relation':'grandma','age':70}).status_code == 200
    assert client.post('/api/v1/water-tracker/log', headers=auth_headers, json={'amount_ml':250}).status_code == 200
    name = f'erase_{store}_store'
    original = getattr(account_erasure, name)
    def fail(*args):
        raise RuntimeError('injected private detail must not be persisted')
    monkeypatch.setattr(account_erasure, name, fail)
    response = client.delete('/api/v1/auth/account', headers=auth_headers)
    assert response.status_code == 200, response.text
    assert response.json()['erasure_status'] == 'pending'
    with client.app.state.session_factory() as session:
        assert session.get(User, user_id) is None
        job = session.get(AccountErasureJob, user_id)
        assert job.status == 'pending' and job.attempts == 1
        assert job.last_error == 'cleanup_failed'
        assert job.next_attempt_at > 0
    assert client.post('/api/v1/water-tracker/log', headers=second_device, json={'amount_ml':999}).status_code == 401
    assert client.get('/api/v1/auth/data/export', headers=second_device).status_code == 401
    assert recover_pending_erasures(client.app) == {'completed':0,'retry':0}
    monkeypatch.setattr(account_erasure, name, original)
    with TestClient(create_app(settings)) as restarted:
        assert restarted.get('/api/v1/auth/data/export', headers=second_device).status_code == 401
        with restarted.app.state.session_factory() as session:
            session.get(AccountErasureJob, user_id).next_attempt_at = 0
            session.commit()
        assert recover_pending_erasures(restarted.app) == {'completed':1,'retry':0}
        assert recover_pending_erasures(restarted.app) == {'completed':0,'retry':0}
        with restarted.app.state.session_factory() as session:
            job = session.get(AccountErasureJob, user_id)
            assert job.status == 'done' and job.completed_at
            assert job.last_error is None
        assert restarted.post('/api/v1/water-tracker/log', headers=second_device, json={'amount_ml':999}).status_code == 401
    assert _count_record_store('family_relations', 'user_id', user_id) == 0
    assert _count_product_store('sa_water_logs', user_id) == 0


def test_core_rollback_keeps_account_and_does_not_schedule_cleanup(client, auth_headers, settings):
    user_id = verify_token(settings, auth_headers['Authorization'][7:])
    cls = client.app.state.session_factory.class_
    def fail(session, context, instances):
        if any(isinstance(obj, AccountErasureJob) for obj in session.new):
            raise RuntimeError('injected before core commit')
    event.listen(cls, 'before_flush', fail)
    try:
        with pytest.raises(RuntimeError, match='before core commit'):
            client.delete('/api/v1/auth/account', headers=auth_headers)
    finally:
        event.remove(cls, 'before_flush', fail)
    with client.app.state.session_factory() as session:
        assert session.get(User, user_id) is not None
        assert session.get(AccountErasureJob, user_id) is None
    assert client.get('/api/v1/auth/data/export', headers=auth_headers).status_code == 200


def test_partial_cleanup_remains_pending(client, auth_headers, settings, monkeypatch):
    user_id = verify_token(settings, auth_headers['Authorization'][7:])
    monkeypatch.setattr(account_erasure, 'erase_product_store', lambda _: ({},{},['blocked_child']))
    response = client.delete('/api/v1/auth/account', headers=auth_headers)
    assert response.status_code == 200
    assert response.json()['erasure_incomplete_tables'] == ['blocked_child']
    with client.app.state.session_factory() as session:
        job = session.get(AccountErasureJob, user_id)
        assert job.status == 'pending' and job.last_error == 'incomplete_tables'
        assert job.completed_at is None


def test_production_starts_and_stops_erasure_worker(settings, postgres_database_url, monkeypatch):
    from threading import Event
    from app.services import erasure_recovery
    started, stopped = Event(), Event()
    async def worker(app, stop):
        started.set()
        await stop.wait()
        stopped.set()
    monkeypatch.setattr(erasure_recovery, 'erasure_recovery_loop', worker)
    production = settings.model_copy(update={'env':'production', 'cors_origins':'https://example.cn',
                                             'database_url':postgres_database_url})
    with TestClient(create_app(production)):
        assert started.wait(2) and not stopped.is_set()
    assert stopped.is_set()


def test_uncertain_core_commit_keeps_recoverable_intent(client, auth_headers, settings, monkeypatch):
    user_id = verify_token(settings, auth_headers['Authorization'][7:])
    factory = client.app.state.session_factory
    def uncertain_factory():
        session = factory()
        commit = session.commit
        def uncertain_commit():
            erasing = any(isinstance(obj, AccountErasureJob) for obj in session.new)
            commit()
            if erasing:
                raise RuntimeError('injected lost commit acknowledgement')
        session.commit = uncertain_commit
        return session
    monkeypatch.setattr(client.app.state, 'session_factory', uncertain_factory)
    with pytest.raises(RuntimeError, match='lost commit acknowledgement'):
        client.delete('/api/v1/auth/account', headers=auth_headers)
    monkeypatch.setattr(client.app.state, 'session_factory', factory)
    with factory() as session:
        assert session.get(User, user_id) is None
        assert session.get(AccountErasureJob, user_id).status == 'pending'
    assert recover_pending_erasures(client.app) == {'completed':1,'retry':0}


def test_two_postgres_workers_do_not_repeat_completed_cleanup(settings, postgres_database_url, monkeypatch):
    from concurrent.futures import ThreadPoolExecutor
    from threading import Barrier
    from app.services.erasure_recovery import cleanup_account
    settings = settings.model_copy(update={'database_url':postgres_database_url})
    with TestClient(create_app(settings)) as client:
        with client.app.state.session_factory() as session:
            session.add(AccountErasureJob(user_id='already-deleted-fixture'))
            session.commit()
        calls = []
        original = account_erasure.erase_product_store
        def observed(user_id):
            calls.append(user_id)
            return original(user_id)
        monkeypatch.setattr(account_erasure, 'erase_product_store', observed)
        barrier = Barrier(2)
        def run():
            barrier.wait(5)
            return cleanup_account(client.app, 'already-deleted-fixture')
        with ThreadPoolExecutor(2) as pool:
            futures = [pool.submit(run) for _ in range(2)]
            assert all(f.result(timeout=10)['erasure_incomplete_tables'] == [] for f in futures)
        assert calls == ['already-deleted-fixture']
        with client.app.state.session_factory() as session:
            job = session.get(AccountErasureJob, 'already-deleted-fixture')
            assert job.status == 'done' and job.attempts == 1


def test_legacy_only_account_cleanup_is_durable(client, settings, monkeypatch):
    from .test_login_and_user_data_identity import _login_token
    token, user_id = _login_token(client)
    with client.app.state.session_factory() as session:
        # Simulate an account created before core identity projection existed.
        session.delete(session.get(User, user_id))
        session.commit()
    monkeypatch.setattr(account_erasure, 'erase_product_store', lambda _: ({},{},['retry_table']))
    response = client.delete('/api/v1/auth/account', headers={'Authorization':'Bearer '+token})
    assert response.status_code == 200, response.text
    assert response.json()['erasure_status'] == 'pending'
    with client.app.state.session_factory() as session:
        assert session.get(AccountErasureJob, user_id).status == 'pending'
    assert _count_record_store('users', 'id', user_id) == 0


def test_token_for_nonexistent_account_cannot_schedule_cleanup(client, settings):
    headers = {'Authorization':'Bearer '+issue_token(settings, 'missing-user')['access_token']}
    assert client.delete('/api/v1/auth/account', headers=headers).status_code == 401
    with client.app.state.session_factory() as session:
        assert session.get(AccountErasureJob, 'missing-user') is None


def test_failed_record_cleanup_blocks_legacy_auth_paths(client, settings, monkeypatch):
    import uuid
    from app.database.db import get_db, close_test_connection
    body = {'email':f'erasure-{uuid.uuid4().hex}@example.com','password':'Fixture-pass-938','name':'测试用户'}
    registered = client.post('/api/v1/auth/register', json=body)
    assert registered.status_code == 200
    data = registered.json()['data']
    user_id = data['user']['id']
    refresh = data['refresh_token']
    second = {'Authorization':'Bearer '+issue_token(settings,user_id)['access_token']}
    db = get_db()
    try:
        legacy = db.execute('SELECT token FROM auth_tokens WHERE user_id=?',(user_id,)).fetchone()[0]
    finally:
        close_test_connection(db)
    def fail(*args):
        raise RuntimeError('record store unavailable')
    monkeypatch.setattr(account_erasure, 'erase_record_store', fail)
    response = client.delete('/api/v1/auth/account', headers={'Authorization':'Bearer '+data['token']})
    assert response.status_code == 200 and response.json()['erasure_status'] == 'pending'
    assert _count_record_store('users', 'id', user_id) == 1
    assert client.get('/api/v1/auth/me', headers=second).status_code == 401
    assert client.post('/api/v1/auth/login', json=body).status_code == 401
    assert client.post('/api/v1/auth/refresh', json={'refresh_token':refresh}).status_code == 401
    for token in (second['Authorization'], 'Bearer '+legacy):
        assert client.post('/api/v1/user-data/export', headers={'Authorization':token},
                           json={'categories':['profile']}).status_code == 401
