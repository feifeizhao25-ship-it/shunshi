import pytest


def add_member(client, headers):
    response = client.post('/api/v1/family/members', headers=headers,
        json={'name': '测试家人', 'relation': 'parent', 'age': 60})
    assert response.status_code == 200, response.text
    return response.json()['id']


@pytest.mark.parametrize('status,attention', [('normal', False), ('attention', True), ('warning', True), ('inactive', False)])
def test_updated_status_survives_next_request(client, auth_headers, status, attention):
    member = add_member(client, auth_headers)
    response = client.patch(f'/api/v1/family/members/{member}/status', headers=auth_headers, params={'status': status})
    assert response.status_code == 200, response.text
    current = client.get('/api/v1/family/status', headers=auth_headers)
    assert current.status_code == 200, current.text
    found = next(m for m in current.json()['data']['members'] if m['id'] == member)
    assert found['needs_attention'] is attention
    assert found['trend'] == ('attention' if attention else 'inactive' if status == 'inactive' else 'good')
    assert client.get('/api/v1/family/members', headers=auth_headers).json()['data']['members'][0]['status'] == status


def test_invalid_status_cannot_silently_look_healthy(client, auth_headers):
    member = add_member(client, auth_headers)
    response = client.patch(f'/api/v1/family/members/{member}/status', headers=auth_headers, params={'status': 'anything'})
    assert response.status_code == 422
    assert client.get('/api/v1/family/members', headers=auth_headers).json()['data']['members'][0]['status'] == 'normal'


def test_another_account_cannot_update_or_delete_member(client, auth_headers, settings):
    from app.security import verify_token
    owner = verify_token(settings, auth_headers['Authorization'].removeprefix('Bearer '))
    member = add_member(client, auth_headers)
    other = client.post('/api/v1/auth/guest-login', json={}).json()['access_token']
    headers = {'Authorization': f'Bearer {other}'}
    assert client.patch(f'/api/v1/family/members/{member}/status', headers=headers, params={'status': 'warning'}).status_code == 404
    assert client.patch(f'/api/v1/family/members/{member}/status', headers=headers, params={'status': 'warning', 'user_id': owner}).status_code == 403
    assert client.delete(f'/api/v1/family/members/{member}', headers=headers).status_code == 404
    assert client.delete(f'/api/v1/family/members/{member}', headers=headers, params={'user_id': owner}).status_code == 403
    # A failed unauthorized mutation must not leave a database write lock behind.
    assert client.patch(f'/api/v1/family/members/{member}/status', headers=auth_headers, params={'status': 'attention'}).status_code == 200
    assert client.get('/api/v1/family/members', headers=auth_headers).json()['data']['members'][0]['status'] == 'attention'


def test_delete_reports_missing_and_persists_removal(client, auth_headers):
    member = add_member(client, auth_headers)
    assert client.delete(f'/api/v1/family/members/{member}', headers=auth_headers).status_code == 200
    assert client.delete(f'/api/v1/family/members/{member}', headers=auth_headers).status_code == 404
    assert client.get('/api/v1/family/members', headers=auth_headers).json()['data']['members'] == []
