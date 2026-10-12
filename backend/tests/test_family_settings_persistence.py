import sqlite3

import pytest
from fastapi.testclient import TestClient
from app.main import create_app
from app.database.db import get_db, close_test_connection
from app.security import verify_token

URL = '/api/v1/family/settings'


def get(client, headers):
    response = client.get(URL, headers=headers)
    assert response.status_code == 200, response.text
    return response.json()


def test_partial_settings_persist_through_restart(client, auth_headers, settings):
    assert get(client, auth_headers)['data'] == dict(show_trend_only=True, reminder_enabled=True, reminder_frequency='daily')
    assert client.put(URL, headers=auth_headers, json={'reminder_enabled': False}).status_code == 200
    saved = client.put(URL, headers=auth_headers, json={'reminder_frequency': 'weekly'})
    assert saved.status_code == 200 and saved.json()['reminder_schedule_active'] is False
    with TestClient(create_app(settings)) as restarted:
        value = get(restarted, auth_headers)['data']
        assert value == dict(show_trend_only=True, reminder_enabled=False, reminder_frequency='weekly')
    assert client.put(URL, headers=auth_headers, json={}).json()['data'] == value


@pytest.mark.parametrize('value', [{'reminder_frequency': 'hourly'}, {'show_trend_only': False}])
def test_invalid_or_unsupported_setting_does_not_write(client, auth_headers, value):
    assert client.put(URL, headers=auth_headers, json=value).status_code == 422
    assert get(client, auth_headers)['data']['show_trend_only'] is True
    assert get(client, auth_headers)['data']['reminder_frequency'] == 'daily'


def test_disabled_reminder_creates_no_notification_then_enable_works(client, auth_headers, settings):
    actor = verify_token(settings, auth_headers['Authorization'].removeprefix('Bearer '))
    added = client.post('/api/v1/family/members', headers=auth_headers, json={'name': '家人', 'relation': 'parent', 'age': 60})
    assert added.status_code == 200
    body = {'target_member_id': added.json()['id'], 'type': 'care'}
    assert client.put(URL, headers=auth_headers, json={'reminder_enabled': False}).status_code == 200
    assert client.post('/api/v1/family/reminder', headers=auth_headers, json=body).status_code == 409
    db = get_db()
    try:
        assert db.execute('SELECT count(*) FROM notifications WHERE user_id = ?', (actor,)).fetchone()[0] == 0
    finally:
        close_test_connection(db)
    assert client.put(URL, headers=auth_headers, json={'reminder_enabled': True, 'reminder_frequency': 'manual'}).status_code == 200
    response = client.post('/api/v1/family/reminder', headers=auth_headers, json=body)
    assert response.status_code == 200, response.text
    assert response.json()['delivery'] == 'self_inbox'
    assert response.json()['message'] == '已保存到自己的通知列表'
    db = get_db()
    try:
        row = db.execute('SELECT user_id FROM notifications WHERE id = ?', (response.json()['notification_id'],)).fetchone()
        assert row['user_id'] == actor
    finally:
        close_test_connection(db)


def test_settings_isolated_exported_and_erased(client, auth_headers, settings):
    actor = verify_token(settings, auth_headers['Authorization'].removeprefix('Bearer '))
    assert client.put(URL, headers=auth_headers, json={'reminder_enabled': False}).status_code == 200
    other = client.post('/api/v1/auth/guest-login', json={}).json()['access_token']
    other_headers = {'Authorization': f'Bearer {other}'}
    assert get(client, other_headers)['data']['reminder_enabled'] is True
    assert client.put(URL, headers=other_headers, params={'user_id': actor}, json={'reminder_enabled': True}).status_code == 403
    exported = client.post('/api/v1/auth/data/export', headers=auth_headers)
    assert exported.status_code == 200
    assert exported.json()['record_store']['family_settings'][0]['reminder_enabled'] == 0
    deleted = client.delete('/api/v1/auth/account', headers=auth_headers)
    assert deleted.status_code == 200, deleted.text
    assert deleted.json()['deleted_record_rows']['family_settings'] == 1
    assert get(client, other_headers)['data']['reminder_enabled'] is True


def test_database_failure_does_not_return_fake_default_or_saved_success(client, auth_headers, monkeypatch):
    from app.router import family
    class BrokenDB:
        def execute(self, *args):
            raise sqlite3.OperationalError('injected read/write failure')
        def rollback(self):
            pass
    monkeypatch.setattr(family, 'get_db', lambda: BrokenDB())
    for method, kwargs in [(client.get, {}), (client.put, {'json': {'reminder_enabled': False}})]:
        with pytest.raises(sqlite3.OperationalError):
            method(URL, headers=auth_headers, **kwargs)


def test_settings_require_login(client):
    assert client.get(URL).status_code == 401
    assert client.put(URL, json={'reminder_enabled': False}).status_code == 401


def test_concurrent_partial_updates_keep_both_preferences(client, auth_headers, settings):
    from concurrent.futures import ThreadPoolExecutor
    from threading import Barrier
    barrier = Barrier(2)
    with TestClient(create_app(settings)) as second:
        def save(test_client, payload):
            barrier.wait(timeout=5)
            return test_client.put(URL, headers=auth_headers, json=payload)
        with ThreadPoolExecutor(max_workers=2) as pool:
            first = pool.submit(save, client, {'reminder_enabled': False})
            other = pool.submit(save, second, {'reminder_frequency': 'weekly'})
            assert first.result(timeout=10).status_code == 200
            assert other.result(timeout=10).status_code == 200
    assert get(client, auth_headers)['data'] == dict(show_trend_only=True, reminder_enabled=False, reminder_frequency='weekly')
