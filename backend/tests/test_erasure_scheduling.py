"""Stale scans must not bypass retry scheduling or manufacture completions."""
import time
import pytest
from app.simple_models import AccountErasureJob
from app.services import account_erasure, erasure_recovery


@pytest.fixture(params=['sqlite', 'postgres'])
def settings(request, settings):
    if request.param == 'postgres':
        return settings.model_copy(update={'database_url':request.getfixturevalue('postgres_database_url')})
    return settings


def seed(client, **values):
    with client.app.state.session_factory() as session:
        session.add(AccountErasureJob(user_id='deleted-fixture', **values))
        session.commit()


def test_direct_stale_claim_does_not_repeat_partial_cleanup(client, monkeypatch):
    seed(client)
    calls = []
    def incomplete(user_id):
        calls.append(user_id)
        return {}, {}, ['blocked_table']
    monkeypatch.setattr(account_erasure, 'erase_product_store', incomplete)
    first = erasure_recovery.cleanup_account(client.app, 'deleted-fixture')
    assert first['attempted'] is True
    assert first['erasure_incomplete_tables'] == ['blocked_table']
    second = erasure_recovery.cleanup_account(client.app, 'deleted-fixture')
    assert second['attempted'] is False
    assert second['erasure_incomplete_tables'] == ['cleanup_pending']
    assert calls == ['deleted-fixture']
    with client.app.state.session_factory() as session:
        job = session.get(AccountErasureJob, 'deleted-fixture')
        assert job.attempts == 1 and job.last_error == 'incomplete_tables'
        assert job.next_attempt_at > time.time()


def test_worker_stale_scan_does_not_report_completion(client, monkeypatch):
    seed(client)
    original = erasure_recovery.cleanup_account
    def another_worker_already_scheduled_retry(app, user_id):
        with app.state.session_factory() as session:
            job = session.get(AccountErasureJob, user_id)
            job.attempts = 5
            job.next_attempt_at = int(time.time()) + 3600
            job.last_error = 'incomplete_tables'
            session.commit()
        return original(app, user_id)
    monkeypatch.setattr(erasure_recovery, 'cleanup_account', another_worker_already_scheduled_retry)
    assert erasure_recovery.recover_pending_erasures(client.app) == {'completed':0,'retry':0}
    with client.app.state.session_factory() as session:
        job = session.get(AccountErasureJob, 'deleted-fixture')
        assert job.status == 'pending' and job.attempts == 5
        assert job.last_error == 'incomplete_tables'


def test_missing_job_is_not_reported_as_success(client):
    result = erasure_recovery.cleanup_account(client.app, 'missing-fixture')
    assert result['attempted'] is False
    assert result['erasure_incomplete_tables'] == ['cleanup_job_missing']


def test_exception_retry_respects_backoff(client, monkeypatch):
    seed(client, attempts=5)
    calls = []
    def unavailable(*args):
        calls.append(True)
        raise RuntimeError('fixture outage')
    monkeypatch.setattr(account_erasure, 'erase_record_store', unavailable)
    before = int(time.time())
    assert erasure_recovery.cleanup_account(client.app, 'deleted-fixture')['attempted'] is True
    assert erasure_recovery.cleanup_account(client.app, 'deleted-fixture')['attempted'] is False
    assert calls == [True]
    with client.app.state.session_factory() as session:
        job = session.get(AccountErasureJob, 'deleted-fixture')
        assert job.attempts == 6
        assert job.next_attempt_at >= before + 1920
        assert job.last_error == 'cleanup_failed'
