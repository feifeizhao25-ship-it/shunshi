import uuid
from concurrent.futures import ThreadPoolExecutor
from types import SimpleNamespace
import pytest
from sqlalchemy import event
from app.database.db import get_db, close_test_connection
from app.simple_models import User, Entitlement, AccountErasureJob
from app.services.account_identity import ensure_core_identity

@pytest.fixture(params=['sqlite', 'postgres'])
def settings(request, settings):
    if request.param == 'postgres':
        return settings.model_copy(update={'database_url':request.getfixturevalue('postgres_database_url')})
    return settings

def credentials():
    return {'email':f'identity-{uuid.uuid4().hex}@example.com', 'password':'Correct-horse-9', 'name':'测试用户'}

def legacy_account(body):
    from app.router.auth import hash_password
    uid = 'legacy-'+uuid.uuid4().hex
    db = get_db()
    try:
        db.execute("INSERT INTO users (id,email,name,password_hash,is_premium,subscription_plan) VALUES (?,?,?,?,1,'jiahe')",
            (uid,body['email'],body['name'],hash_password(body['password'])))
        db.commit()
    finally:
        close_test_connection(db)
    return uid

def test_register_exports_same_core_identity(client):
    r = client.post('/api/v1/auth/register', json=credentials())
    assert r.status_code == 200, r.text
    uid = r.json()['data']['user']['id']
    with client.app.state.session_factory() as session:
        user = session.get(User, uid)
        assert user.nickname == '测试用户' and not user.is_guest
        assert user.password_hash is None and user.phone is None
        assert session.get(Entitlement, uid) is None
    exported = client.get('/api/v1/auth/data/export', headers={'Authorization':'Bearer '+r.json()['access_token']})
    assert exported.status_code == 200, exported.text
    assert exported.json()['user']['id'] == uid

def test_historical_login_repairs_without_granting_membership_or_overwriting_profile(client):
    body = credentials()
    uid = legacy_account(body)
    assert client.post('/api/v1/auth/login', json={**body,'password':'wrong'}).status_code == 401
    with client.app.state.session_factory() as session:
        assert session.get(User, uid) is None
    for i in range(2):
        r = client.post('/api/v1/auth/login', json=body)
        assert r.status_code == 200, r.text
        assert r.json()['data']['user']['id'] == uid
        with client.app.state.session_factory() as session:
            user = session.get(User, uid)
            assert user.nickname == ('测试用户' if i == 0 else '核心资料名称')
            assert session.get(Entitlement, uid) is None
            user.nickname = '核心资料名称'
            session.commit()

def test_core_commit_failure_keeps_credentials_and_login_recovers(client):
    body = credentials()
    cls = client.app.state.session_factory.class_
    def fail(session):
        if any(isinstance(row,User) for row in session.new):
            raise RuntimeError('private-injected-core-error')
    event.listen(cls, 'before_commit', fail)
    try:
        r = client.post('/api/v1/auth/register', json=body)
        assert r.status_code == 503, r.text
        assert 'access_token' not in r.text and 'private-injected' not in r.text
    finally:
        event.remove(cls, 'before_commit', fail)
    r = client.post('/api/v1/auth/login', json=body)
    assert r.status_code == 200, r.text
    with client.app.state.session_factory() as session:
        assert session.get(User,r.json()['data']['user']['id']) is not None

@pytest.mark.parametrize('status',['pending','done'])
def test_tombstone_blocks_recreation_even_if_legacy_cleanup_failed(client,status):
    body = credentials()
    uid = legacy_account(body)
    with client.app.state.session_factory() as session:
        session.add(AccountErasureJob(user_id=uid,status=status))
        session.commit()
    assert client.post('/api/v1/auth/login',json=body).status_code == 401
    from fastapi import HTTPException
    with pytest.raises(HTTPException) as exc:
        ensure_core_identity(SimpleNamespace(app=client.app),uid)
    assert exc.value.status_code == 401
    with client.app.state.session_factory() as session:
        assert session.get(User,uid) is None

def test_concurrent_projection_is_idempotent(client):
    uid = legacy_account(credentials())
    request = SimpleNamespace(app=client.app)
    with ThreadPoolExecutor(max_workers=2) as pool:
        futures = [pool.submit(ensure_core_identity,request,uid) for _ in range(2)]
        for future in futures:
            future.result(timeout=15)
    with client.app.state.session_factory() as session:
        assert session.get(User,uid) is not None

def test_phone_password_registration_uses_same_id_without_claiming_verified_phone(client):
    body = {'password':'Correct-horse-9','name':'手机用户','phone':'139'+str(uuid.uuid4().int % 100000000).zfill(8)}
    r = client.post('/api/v1/auth/register',json=body)
    assert r.status_code == 200, r.text
    uid = r.json()['data']['user']['id']
    logged = client.post('/api/v1/auth/login',json=body)
    assert logged.status_code == 200, logged.text
    assert logged.json()['data']['user']['id'] == uid
    with client.app.state.session_factory() as session:
        assert session.get(User,uid).phone is None

def test_projection_racing_erasure_never_resurrects_identity(client,settings):
    from threading import Barrier
    from fastapi import HTTPException
    from app.security import issue_token
    uid = legacy_account(credentials())
    barrier = Barrier(2)
    def project():
        barrier.wait(timeout=10)
        try:
            ensure_core_identity(SimpleNamespace(app=client.app),uid)
        except HTTPException as exc:
            assert exc.status_code == 401
    def erase():
        barrier.wait(timeout=10)
        response = client.delete('/api/v1/auth/account',headers={
            'Authorization':'Bearer '+issue_token(settings,uid)['access_token']})
        assert response.status_code == 200, response.text
    with ThreadPoolExecutor(max_workers=2) as pool:
        jobs = [pool.submit(project),pool.submit(erase)]
        for job in jobs:
            job.result(timeout=30)
    with client.app.state.session_factory() as session:
        assert session.get(User,uid) is None
        assert session.get(AccountErasureJob,uid) is not None
