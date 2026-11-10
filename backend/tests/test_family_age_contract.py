import pytest


def _guest(client):
    created = client.post('/api/v1/auth/guest-login', json={})
    assert created.status_code == 200, created.text
    body = created.json()
    token = body.get('access_token') or body['data']['token']
    return {'Authorization': f'Bearer {token}'}


def test_missing_age_stays_null_and_zero_stays_zero(client):
    # 一个家庭只能绑定 2 位家人，所以三种年龄各用一个新账号。
    for age in [None, 0, 60]:
        headers = _guest(client)
        response = client.post('/api/v1/family/members', headers=headers,
            json={'name': ' 家人 ', 'relation': 'parent', 'age': age})
        assert response.status_code == 200, response.text
        assert response.json()['age'] == age and response.json()['name'] == '家人'
        for path in ['/api/v1/family', '/api/v1/family/members']:
            loaded = client.get(path, headers=headers).json()
            members = loaded['members'] if 'members' in loaded else loaded['data']['members']
            assert [m['age'] for m in members] == [age]


@pytest.mark.parametrize('extra', [{'age': -1}, {'age': 121}, {'age': 1.5}, {'age': True}, {'name': '   '}, {'relation': ' '}])
def test_invalid_member_fields_rejected(client, auth_headers, extra):
    response = client.post('/api/v1/family/members', headers=auth_headers,
        json={'name': '家人', 'relation': 'parent', **extra})
    assert response.status_code == 422
    assert client.get('/api/v1/family', headers=auth_headers).json()['members'] == []
