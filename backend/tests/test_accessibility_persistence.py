from fastapi.testclient import TestClient
from app.main import create_app
from app.security import verify_token
from app.simple_models import UserSetting


def test_preferences_survive_new_app_and_are_exported_and_erased(client, settings, auth_headers):
    user = verify_token(settings, auth_headers['Authorization'].removeprefix('Bearer '))
    path = f'/api/v1/accessibility/settings/{user}'
    assert client.get(path).status_code == 401
    result = client.post('/api/v1/accessibility/settings', headers=auth_headers,
                         json={'user_id': user, 'font_size': 'extra_large', 'high_contrast': True})
    assert result.status_code == 200
    with TestClient(create_app(settings)) as restarted:
        result = restarted.get(path, headers=auth_headers)
        assert result.status_code == 200
        assert result.json()['data']['font_scale'] == 1.5
        assert result.json()['data']['settings']['high_contrast'] is True
        exported = restarted.get('/api/v1/auth/data/export', headers=auth_headers).json()
        assert exported['settings']['settings:accessibility']['font_size'] == 'x-large'
        other = restarted.post('/api/v1/auth/guest-login', json={}).json()['access_token']
        outsider = {'Authorization': 'Bearer ' + other}
        assert restarted.get(path, headers=outsider).status_code == 403
        assert restarted.post(path + '/reset', headers=outsider).status_code == 403
        assert restarted.post('/api/v1/accessibility/settings', headers=outsider,
                              json={'user_id': user, 'font_size': 'small'}).status_code == 403
        assert restarted.get(path, headers=auth_headers).json()['data']['font_scale'] == 1.5
        assert restarted.post(path + '/reset', headers=auth_headers).status_code == 200
        assert restarted.get(path, headers=auth_headers).json()['data']['font_scale'] == 1.0
        assert restarted.delete('/api/v1/auth/account', headers=auth_headers).status_code == 200
        with restarted.app.state.session_factory() as session:
            assert session.get(UserSetting, {'user_id': user, 'key': 'settings:accessibility'}) is None
        assert restarted.get(path, headers=auth_headers).status_code == 401


def test_invalid_preferences_do_not_replace_saved_values(client, auth_headers):
    path = '/api/v1/accessibility/settings'
    assert client.post(path, headers=auth_headers, json={'font_size': 'large'}).status_code == 200
    for field, value in [('font_size', 'huge'), ('color_blind_mode', 'invalid'),
                         ('button_size', 'tiny'), ('line_spacing', 'negative')]:
        assert client.post(path, headers=auth_headers, json={field: value}).status_code == 422
