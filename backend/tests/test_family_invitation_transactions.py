import sqlite3
from concurrent.futures import ThreadPoolExecutor
from threading import Barrier

import pytest
from fastapi.testclient import TestClient
from app.main import create_app
from app.database.db import get_db, close_test_connection


def login(client):
    response = client.post('/api/v1/auth/guest-login', json={})
    assert response.status_code == 200
    return {'Authorization': 'Bearer ' + response.json()['access_token']}


def invite(client, headers, relation='parent'):
    response = client.post('/api/v1/family/invite', headers=headers, json={'relation': relation})
    assert response.status_code == 200, response.text
    return response.json()['code']


def join(client, headers, code):
    return client.post('/api/v1/family/join', headers=headers, params={'code': code})


def state(code):
    db = get_db()
    try:
        row = db.execute('SELECT * FROM family_invites WHERE code = ?', (code,)).fetchone()
        return dict(row) if row else None
    finally:
        close_test_connection(db)


def test_join_once_exit_and_rejoin_with_new_invitation(client, auth_headers):
    guest = login(client)
    code = invite(client, auth_headers)
    assert join(client, guest, code).status_code == 200
    assert state(code)['used'] == 1
    assert join(client, login(client), code).status_code == 400
    members = client.get('/api/v1/family/members', headers=guest).json()['data']['members']
    assert len(members) == 1
    # A joined member cannot fetch the inviter's unused invitation through /family.
    next_code = invite(client, auth_headers, 'child')
    assert client.get('/api/v1/family', headers=guest).json()['invite_code'] is None
    assert join(client, guest, next_code).status_code == 409
    assert state(next_code)['used'] == 0
    own_code = invite(client, guest)
    assert own_code != next_code
    assert client.post('/api/v1/family/leave', headers=guest).status_code == 200
    assert state(own_code) is None
    assert client.get('/api/v1/family/members', headers=guest).json()['data']['members'] == []
    assert join(client, guest, next_code).status_code == 200


def test_self_join_rejected_without_consuming_invite(client, auth_headers):
    code = invite(client, auth_headers)
    assert join(client, auth_headers, code).status_code == 400
    assert state(code)['used'] == 0


def test_relations_have_distinct_invites_and_same_relation_reuses(client, auth_headers):
    first = invite(client, auth_headers, 'parent')
    assert invite(client, auth_headers, 'parent') == first
    assert invite(client, auth_headers, 'child') != first


def test_full_family_blocks_join_without_consuming_invite(client, auth_headers):
    for i in range(4):
        response = client.post('/api/v1/family/members', headers=auth_headers,
            json={'name': f'成员{i}', 'relation': 'parent', 'age': 60})
        assert response.status_code == 200
    code = invite(client, auth_headers)
    assert join(client, login(client), code).status_code == 400
    assert state(code)['used'] == 0


def test_insert_failure_rolls_back_consumed_flag(client, auth_headers, monkeypatch):
    from app.router import family
    code = invite(client, auth_headers)
    guest = login(client)
    db = get_db()
    db.execute("CREATE TEMP TRIGGER fail_join BEFORE INSERT ON family_relations BEGIN SELECT RAISE(ABORT, 'injected join failure'); END")
    with monkeypatch.context() as patch:
        patch.setattr(family, 'get_db', lambda: db)
        with pytest.raises(sqlite3.IntegrityError):
            join(client, guest, code)
    assert state(code)['used'] == 0
    assert join(client, guest, code).status_code == 200


def test_code_collision_retries_without_returning_other_invite(client, auth_headers, monkeypatch):
    from app.router import family
    first = invite(client, auth_headers)
    values = iter([first, 'NEW001'])
    monkeypatch.setattr(family, 'generate_code', lambda: next(values))
    assert invite(client, login(client)) == 'NEW001'
    assert state(first)['used'] == 0


def test_deleted_inviter_cannot_be_joined(client, auth_headers):
    code = invite(client, auth_headers)
    assert client.delete('/api/v1/auth/account', headers=auth_headers).status_code == 200
    assert join(client, login(client), code).status_code in (404, 410)


def test_two_users_cannot_consume_one_code(client, auth_headers, settings):
    code = invite(client, auth_headers)
    guest1, guest2 = login(client), login(client)
    barrier = Barrier(2)
    with TestClient(create_app(settings)) as second:
        def attempt(test_client, headers):
            barrier.wait(timeout=5)
            return join(test_client, headers, code).status_code
        with ThreadPoolExecutor(max_workers=2) as pool:
            first = pool.submit(attempt, client, guest1)
            other = pool.submit(attempt, second, guest2)
            assert sorted([first.result(timeout=10), other.result(timeout=10)]) == [200, 400]
    db = get_db()
    try:
        assert db.execute('SELECT count(*) FROM family_relations WHERE family_id = ?', (state(code)['family_id'],)).fetchone()[0] == 1
    finally:
        close_test_connection(db)


def test_expired_invite_is_not_consumed(client, auth_headers):
    code = invite(client, auth_headers)
    db = get_db()
    try:
        db.execute("UPDATE family_invites SET expires_at = '2000-01-01T00:00:00' WHERE code = ?", (code,))
        db.commit()
    finally:
        close_test_connection(db)
    assert join(client, login(client), code).status_code == 400
    assert state(code)['used'] == 0


def test_add_and_join_compete_for_last_slot(client, auth_headers, settings):
    for i in range(3):
        assert client.post('/api/v1/family/members', headers=auth_headers,
            json={'name': f'成员{i}', 'relation': 'parent', 'age': 60}).status_code == 200
    code = invite(client, auth_headers)
    guest = login(client)
    barrier = Barrier(2)
    with TestClient(create_app(settings)) as second:
        def add():
            barrier.wait(timeout=5)
            return client.post('/api/v1/family/members', headers=auth_headers,
                json={'name': '最后名额', 'relation': 'parent', 'age': 60}).status_code
        def accept():
            barrier.wait(timeout=5)
            return join(second, guest, code).status_code
        with ThreadPoolExecutor(max_workers=2) as pool:
            first, other = pool.submit(add), pool.submit(accept)
            add_result, join_result = first.result(timeout=10), other.result(timeout=10)
            assert sorted([add_result, join_result]) == [200, 400]
    invitation = state(code)
    assert invitation['used'] == int(join_result == 200)
    db = get_db()
    try:
        assert db.execute('SELECT count(*) FROM family_relations WHERE family_id = ?', (invitation['family_id'],)).fetchone()[0] == 4
    finally:
        close_test_connection(db)
