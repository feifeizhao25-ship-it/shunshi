import pytest


def scheduled(client, headers):
    response = client.post('/api/v1/followup/schedule', headers=headers, json={
        'type': 'care_reminder', 'trigger_time': '2026-01-01T00:00:00', 'content': '私密提醒'})
    assert response.status_code == 200
    return response.json()['followup']['id']


@pytest.mark.parametrize('method', ['get', 'put', 'delete'])
def test_other_users_cannot_read_or_mutate_tasks(client, auth_headers, method):
    task = scheduled(client, auth_headers)
    path = f'/api/v1/followup/{task}'
    args = {'json': {'status': 'sent'}} if method == 'put' else {}
    assert getattr(client, method)(path, **args).status_code == 401
    other = client.post('/api/v1/auth/guest-login', json={}).json()['access_token']
    outsider = {'Authorization': 'Bearer ' + other}
    assert getattr(client, method)(path, headers=outsider, **args).status_code == 404
    response = client.get(path, headers=auth_headers)
    assert response.status_code == 200
    assert response.json()['status'] == 'scheduled'
    assert getattr(client, method)(path, headers=auth_headers, **args).status_code == 200


def test_normal_user_cannot_trigger_global_scheduler(client, auth_headers, monkeypatch):
    from app.router.followup import followup_scheduler
    monkeypatch.setattr(followup_scheduler, 'check_and_trigger_due', lambda: pytest.fail('must not run'))
    assert client.post('/api/v1/followup/check').status_code == 401
    assert client.post('/api/v1/followup/check', headers=auth_headers).status_code == 403


def test_check_due_is_routable_and_scoped(client, auth_headers):
    task = scheduled(client, auth_headers)
    response = client.get('/api/v1/followup/check-due', headers=auth_headers)
    assert response.status_code == 200
    assert task in {item['id'] for item in response.json()['due_followups']}
    other = client.post('/api/v1/auth/guest-login', json={}).json()['access_token']
    response = client.get('/api/v1/followup/check-due', headers={'Authorization': 'Bearer ' + other})
    assert response.status_code == 200
    assert response.json()['due_followups'] == []


def test_due_read_failure_is_not_reported_as_empty_success(client, auth_headers, monkeypatch):
    from app.router import followup
    def unavailable():
        raise RuntimeError('private database connection detail')
    monkeypatch.setattr(followup, 'get_db', unavailable)
    response = client.get('/api/v1/followup/check-due', headers=auth_headers)
    assert response.status_code == 503
    assert 'private database' not in response.text


def test_deleted_account_token_cannot_read_task(client, auth_headers):
    task = scheduled(client, auth_headers)
    assert client.delete('/api/v1/auth/account', headers=auth_headers).status_code == 200
    assert client.get(f'/api/v1/followup/{task}', headers=auth_headers).status_code == 401


def test_operator_can_run_scheduler_with_no_real_delivery(client, monkeypatch):
    from app.router import admin_auth, followup
    import uuid
    token = 'test-operator-' + uuid.uuid4().hex
    calls = []
    monkeypatch.setitem(admin_auth._active_tokens, token, {'username': 'ops', 'expires_at': None})
    def run():
        calls.append(True)
        return []
    monkeypatch.setattr(followup.followup_scheduler, 'check_and_trigger_due', run)
    response = client.post('/api/v1/followup/check', headers={'X-Admin-Token': token})
    assert response.status_code == 200
    assert response.json()['triggered_count'] == 0
    assert calls == [True]
