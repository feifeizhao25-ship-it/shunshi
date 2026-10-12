import pytest


def test_missing_age_stays_null_and_zero_stays_zero(client, auth_headers):
    for age in [None, 0, 60]:
        response = client.post('/api/v1/family/members', headers=auth_headers,
            json={'name': ' 家人 ', 'relation': 'parent', 'age': age})
        assert response.status_code == 200, response.text
        assert response.json()['age'] == age and response.json()['name'] == '家人'
    for path in ['/api/v1/family', '/api/v1/family/members']:
        response = client.get(path, headers=auth_headers).json()
        members = response['members'] if 'members' in response else response['data']['members']
        assert [m['age'] for m in members] == [None, 0, 60]


@pytest.mark.parametrize('extra', [{'age': -1}, {'age': 121}, {'age': 1.5}, {'age': True}, {'name': '   '}, {'relation': ' '}])
def test_invalid_member_fields_rejected(client, auth_headers, extra):
    response = client.post('/api/v1/family/members', headers=auth_headers,
        json={'name': '家人', 'relation': 'parent', **extra})
    assert response.status_code == 422
    assert client.get('/api/v1/family', headers=auth_headers).json()['members'] == []
