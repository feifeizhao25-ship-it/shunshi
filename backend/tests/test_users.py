"""Legacy account paths must act on authenticated owners and real data."""
import pytest
from sqlalchemy import select, func
from app.security import verify_token
from app.simple_models import User, UserSetting
from app.database.db import get_db, close_test_connection

@pytest.fixture()
def actor(auth_headers, settings):
    return verify_token(settings, auth_headers['Authorization'].removeprefix('Bearer '))

@pytest.mark.parametrize('method,suffix', [('get','/export'), ('delete','?confirm=true')])
def test_anonymous_and_cross_account_denied(client, auth_headers, actor, method, suffix):
    request = getattr(client, method)
    assert request(f'/api/v1/users/{actor}{suffix}').status_code == 401
    other = client.post('/api/v1/auth/guest-login', json={}).json()['access_token']
    assert request(f'/api/v1/users/{actor}{suffix}', headers={'Authorization':f'Bearer {other}'}).status_code == 403
    with client.app.state.session_factory() as session:
        assert session.get(User, actor) is not None

@pytest.mark.parametrize('query,status', [('',400), ('?confirm=false',400), ('?confirm=invalid',422)])
def test_confirmation_required_without_deleting(client, auth_headers, actor, query, status):
    assert client.delete(f'/api/v1/users/{actor}{query}', headers=auth_headers).status_code == status
    with client.app.state.session_factory() as session:
        assert session.get(User, actor) is not None

def test_export_includes_core_data_and_isolates_owners(client, auth_headers, actor, settings):
    other_token = client.post('/api/v1/auth/guest-login', json={}).json()['access_token']
    other_id = verify_token(settings, other_token)
    with client.app.state.session_factory() as session:
        session.add(UserSetting(user_id=actor, key='private_note', value='"本人记录"'))
        session.add(UserSetting(user_id=other_id, key='private_note', value='"其他人的秘密"'))
        session.commit()
    response = client.get(f'/api/v1/users/{actor}/export', headers=auth_headers)
    assert response.status_code == 200, response.text
    data = response.json()
    assert data['user_id'] == data['user']['id'] == actor
    from datetime import datetime
    assert datetime.fromisoformat(data['exported_at']).tzinfo is not None
    assert data['settings']['private_note'] == '本人记录'
    assert '其他人的秘密' not in response.text
    assert all(key in data for key in ('health_measurements','family_seats','store_purchases','domestic_billing'))
    assert all(isinstance(data[key], list) for key in ('profile','subscriptions','memories','conversations'))
    assert '全部产品' in data['export_scope']
    other_export = client.get(f'/api/v1/users/{other_id}/export', headers={'Authorization':f'Bearer {other_token}'})
    assert other_export.status_code == 200
    assert other_export.json()['settings']['private_note'] == '其他人的秘密'
    assert '本人记录' not in other_export.text

def test_export_then_delete_removes_core_and_record_data(client, auth_headers, actor):
    with client.app.state.session_factory() as session:
        session.add(UserSetting(user_id=actor, key='note', value='"remove-me"'))
        session.commit()
    assert client.post('/api/v1/family/members', headers=auth_headers,
        json={'name':'外婆','relation':'grandma','age':78}).status_code == 200
    assert client.get(f'/api/v1/users/{actor}/export', headers=auth_headers).status_code == 200
    response = client.delete(f'/api/v1/users/{actor}?confirm=true', headers=auth_headers)
    assert response.status_code == 200, response.text
    data = response.json()
    assert data['success'] is True and data['deleted'] is True
    assert data['deleted_records']['core.users'] == 1
    assert data['deleted_records']['core.user_settings'] >= 1
    assert data['total_records_deleted'] == sum(data['deleted_records'].values())
    assert 'retained_billing_records' in data and data['deleted_at']
    with client.app.state.session_factory() as session:
        assert session.get(User, actor) is None
        assert session.scalar(select(func.count()).select_from(UserSetting).where(UserSetting.user_id==actor)) == 0
    db = get_db()
    try:
        assert db.execute('SELECT count(*) FROM family_relations WHERE user_id=?',(actor,)).fetchone()[0] == 0
    finally:
        close_test_connection(db)
    assert client.get('/api/v1/auth/data/export', headers=auth_headers).status_code == 401
    assert client.get(f'/api/v1/users/{actor}/export', headers=auth_headers).status_code == 401

def test_incomplete_erasure_is_not_reported_as_complete(client, auth_headers, actor, monkeypatch):
    from app.services import account_erasure
    monkeypatch.setattr(account_erasure, 'erase_product_store', lambda _: ({}, {}, ['unhandled_table']))
    response = client.delete(f'/api/v1/users/{actor}?confirm=true', headers=auth_headers)
    assert response.status_code == 200
    assert response.json()['success'] is False
    assert response.json()['erasure_incomplete_tables'] == ['unhandled_table']
    assert '尚未完成' in response.json()['message']

def test_deletion_failure_is_not_reported_as_success(client, auth_headers, actor, monkeypatch):
    from fastapi import HTTPException
    from app.router import users
    def fail(**kwargs):
        raise HTTPException(503, '注销存储暂不可用')
    monkeypatch.setattr(users, 'delete_account', fail)
    response = client.delete(f'/api/v1/users/{actor}?confirm=true', headers=auth_headers)
    assert response.status_code == 503
    with client.app.state.session_factory() as session:
        assert session.get(User, actor) is not None
