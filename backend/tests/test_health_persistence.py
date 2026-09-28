from datetime import datetime, timedelta, timezone
from zoneinfo import ZoneInfo

from fastapi.testclient import TestClient
from sqlalchemy import select

from app.main import create_app
from app.security import verify_token
from app.simple_models import HealthMeasurement


def _sync(client, headers, when, value=4000):
    return client.post('/api/v1/health-data/sync', headers=headers, json={
        'data_type': 'steps', 'value': value, 'unit': 'steps',
        'recorded_at': when, 'source': 'manual',
    })


def _actor(settings, headers):
    return verify_token(settings, headers['Authorization'].removeprefix('Bearer '))


def test_health_survives_new_application_and_database_session(client, auth_headers, settings):
    actor = _actor(settings, auth_headers)
    assert _sync(client, auth_headers, (datetime.now(timezone.utc)-timedelta(minutes=1)).isoformat()).status_code == 200
    with TestClient(create_app(settings)) as restarted:
        response = restarted.get(f'/api/v1/health-data/summary/{actor}', headers=auth_headers)
        assert response.status_code == 200
        assert response.json()['data']['latest_values']['steps']['value'] == 4000


def test_chronological_order_uses_instants_not_offset_strings(client, auth_headers, settings):
    now = datetime.now(timezone.utc)-timedelta(minutes=1)
    older = (now-timedelta(hours=1)).astimezone(ZoneInfo('Asia/Shanghai'))
    assert _sync(client, auth_headers, now.isoformat(), 6000).status_code == 200
    assert _sync(client, auth_headers, older.isoformat(), 3000).status_code == 200
    assert _sync(client, auth_headers, (now-timedelta(days=8)).isoformat(), 1000).status_code == 200
    actor = _actor(settings, auth_headers)
    data = client.get(f'/api/v1/health-data/summary/{actor}', headers=auth_headers).json()['data']
    assert data['data_count'] == 2
    assert data['latest_values']['steps']['value'] == 6000


def test_legacy_china_time_and_future_validation(client, auth_headers, settings):
    local = (datetime.now(ZoneInfo('Asia/Shanghai'))-timedelta(minutes=1)).replace(tzinfo=None)
    assert _sync(client, auth_headers, local.isoformat()).status_code == 200
    with client.app.state.session_factory() as session:
        row = session.scalar(select(HealthMeasurement))
        assert row.recorded_at == local.replace(tzinfo=ZoneInfo('Asia/Shanghai')).timestamp()
    assert _sync(client, auth_headers, (datetime.now(timezone.utc)+timedelta(days=1)).isoformat()).status_code == 422


def test_export_and_account_erasure_include_health_records(client, auth_headers, settings):
    assert _sync(client, auth_headers, (datetime.now(timezone.utc)-timedelta(minutes=1)).isoformat()).status_code == 200
    exported = client.get('/api/v1/auth/data/export', headers=auth_headers)
    assert exported.status_code == 200
    assert len(exported.json()['health_measurements']) == 1
    deleted = client.delete('/api/v1/auth/account', headers=auth_headers)
    assert deleted.status_code == 200, deleted.text
    assert deleted.json()['deleted_rows']['health_measurements'] == 1
    with client.app.state.session_factory() as session:
        assert session.scalar(select(HealthMeasurement)) is None


def test_health_delete_does_not_delete_other_accounts(client, auth_headers, settings):
    actor = _actor(settings, auth_headers)
    token = client.post('/api/v1/auth/guest-login', json={}).json()['access_token']
    other = {'Authorization': f'Bearer {token}'}
    other_actor = _actor(settings, other)
    when = (datetime.now(timezone.utc)-timedelta(minutes=1)).isoformat()
    assert _sync(client, auth_headers, when).status_code == 200
    assert _sync(client, other, when).status_code == 200
    assert client.delete(f'/api/v1/health-data/delete/{actor}', headers=auth_headers).status_code == 200
    with client.app.state.session_factory() as session:
        rows = session.scalars(select(HealthMeasurement)).all()
        assert len(rows) == 1 and rows[0].user_id == other_actor
