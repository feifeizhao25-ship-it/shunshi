"""Mounted routes must keep journal entries isolated between authenticated users."""
from app.security import verify_token


def test_other_user_cannot_delete_journal(client, auth_headers, settings):
    owner = verify_token(settings, auth_headers['Authorization'].removeprefix('Bearer '))
    created = client.post('/api/v1/journal/entry', headers=auth_headers,
                          json={'user_id': owner, 'mood': 3, 'energy': 3, 'sleep_quality': 3})
    assert created.status_code == 200
    entry_id = created.json()['data']['entry_id']
    other = client.post('/api/v1/auth/guest-login', json={}).json()['access_token']
    outsider = {'Authorization': 'Bearer ' + other}
    assert client.delete(f'/api/v1/journal/entry/{entry_id}').status_code == 401
    assert client.delete(f'/api/v1/journal/entry/{entry_id}', headers=outsider).status_code == 404
    assert client.get(f'/api/v1/journal/entries/{owner}', headers=outsider).status_code == 403
    history = client.get(f'/api/v1/journal/entries/{owner}', headers=auth_headers).json()['data']['entries']
    assert entry_id in {entry['entry_id'] for entry in history}
    assert client.delete(f'/api/v1/journal/entry/{entry_id}', headers=auth_headers).status_code == 200
    assert client.delete(f'/api/v1/journal/entry/{entry_id}', headers=auth_headers).status_code == 404
