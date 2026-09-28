import pytest
from app.security import verify_token


def test_personalized_recommendations_do_not_mutate_other_requests(client):
    before = client.get('/api/v1/smart-alarm/recommend').json()
    first = client.get('/api/v1/smart-alarm/recommend?constitution=yang_deficiency').json()
    second = client.get('/api/v1/smart-alarm/recommend?constitution=yang_deficiency').json()
    assert first == second
    assert next(a for a in first['data']['recommendations'] if a['type'] == 'sleep')['time'] == '22:00'
    assert client.get('/api/v1/smart-alarm/recommend').json() == before
    assert next(a for a in before['data']['recommendations'] if a['type'] == 'sleep')['time'] == '22:30'


@pytest.mark.parametrize('invalid', [{'time': '24:00'}, {'time': '12:60'}, {'time': '-1:00'}, {'days': ['tomorrow']}, {'sound': 'missing-sound'}])
def test_invalid_create_and_update_do_not_change_saved_alarm(client, auth_headers, settings, invalid):
    body = {'type': 'wake_up', 'time': '07:00', 'days': ['mon'], 'sound': 'morning_bell'}
    assert client.post('/api/v1/smart-alarm/', headers=auth_headers, json={**body, **invalid}).status_code == 422
    created = client.post('/api/v1/smart-alarm/', headers=auth_headers, json=body)
    assert created.status_code == 200
    actor = verify_token(settings, auth_headers['Authorization'].removeprefix('Bearer '))
    alarm_id = created.json()['data']['alarm_id']
    result = client.put(f'/api/v1/smart-alarm/user/{actor}/alarm/{alarm_id}', headers=auth_headers, json=invalid)
    assert result.status_code == 422
    saved = client.get(f'/api/v1/smart-alarm/user/{actor}', headers=auth_headers).json()['data']['alarms']
    assert len(saved) == 1 and saved[0]['time'] == '07:00' and saved[0]['days'] == ['mon']


def test_alarm_cannot_be_changed_by_another_account(client, auth_headers, settings):
    actor = verify_token(settings, auth_headers['Authorization'].removeprefix('Bearer '))
    body = {'type': 'wake_up', 'time': '07:00'}
    assert client.post('/api/v1/smart-alarm/', json=body).status_code == 401
    alarm_id = client.post('/api/v1/smart-alarm/', headers=auth_headers, json=body).json()['data']['alarm_id']
    token = client.post('/api/v1/auth/guest-login', json={}).json()['access_token']
    other_headers = {'Authorization': f'Bearer {token}'}
    for method in ['put', 'delete']:
        kwargs = {'json': {'time': '09:00'}} if method == 'put' else {}
        assert getattr(client, method)(f'/api/v1/smart-alarm/user/{actor}/alarm/{alarm_id}', headers=other_headers, **kwargs).status_code == 403
