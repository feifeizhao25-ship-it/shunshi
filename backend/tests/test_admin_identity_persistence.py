import hashlib
import time
from concurrent.futures import ThreadPoolExecutor

import pytest
from sqlalchemy import create_engine, select
from sqlalchemy.orm import sessionmaker

from app.models.admin_identity import AdminCredential, AdminSession
from app.services import admin_identity as store
from app.router import admin_auth

PASSWORD = "original-test-password-123"
NEW = "changed-test-password-456"
SECRET = "shared-test-secret"


@pytest.fixture(params=["sqlite", "postgres"])
def identity_db(tmp_path, monkeypatch, request):
    url = ("sqlite:///" + str(tmp_path / "admin.db") if request.param == "sqlite"
           else request.getfixturevalue("postgres_database_url"))
    engine = create_engine(url, **({"connect_args": {"check_same_thread": False}} if request.param == "sqlite" else {}))
    AdminCredential.__table__.create(engine)
    AdminSession.__table__.create(engine)
    factory = sessionmaker(bind=engine)
    monkeypatch.setattr(store, "session_factory", factory)
    monkeypatch.setattr(admin_auth, "ADMIN_PASSWORD_HASH", hashlib.sha256(PASSWORD.encode()).hexdigest())
    yield factory
    engine.dispose()


def login(client, password=PASSWORD, username="admin"):
    return client.post("/api/v1/admin/auth/login", json={"username": username, "password": password})


def test_login_persists_digest_and_salted_password(client, identity_db, monkeypatch):
    response = login(client)
    assert response.status_code == 200
    token = response.json()["token"]
    with identity_db() as db:
        session = db.execute(select(AdminSession)).scalar_one()
        credential = db.get(AdminCredential, "admin")
        assert session.token_digest != token
        assert credential.salt
        assert credential.password_hash != hashlib.sha256(PASSWORD.encode()).hexdigest()
    monkeypatch.setattr(store, "session_factory", sessionmaker(bind=identity_db.kw["bind"]))
    assert client.get("/api/v1/admin/auth/verify", headers={"Authorization": "Bearer " + token}).json() == {"valid": True, "username": "admin"}
    assert client.get("/api/v1/admin/families", headers={"X-Admin-Token": token}).status_code == 200


def test_logout_bearer_revokes_persistently(client, identity_db):
    token = login(client).json()["token"]
    headers = {"Authorization": "Bearer " + token}
    assert client.post("/api/v1/admin/auth/logout", headers=headers).status_code == 200
    assert client.get("/api/v1/admin/auth/verify", headers=headers).json()["valid"] is False
    assert client.get("/api/v1/admin/families", headers=headers).status_code in (401, 403)


def test_password_change_persists_and_revokes_all(client, identity_db):
    first, second = login(client).json()["token"], login(client).json()["token"]
    changed = client.post("/api/v1/admin/auth/change-password",
        headers={"Authorization": "Bearer " + first},
        json={"old_password": PASSWORD, "new_password": NEW})
    assert changed.status_code == 200
    for token in (first, second):
        assert client.get("/api/v1/admin/auth/verify", headers={"X-Admin-Token": token}).json()["valid"] is False
    assert login(client).status_code == 401
    assert login(client, NEW).status_code == 200
    assert login(client, NEW, "someone-else").status_code == 401


def test_invalid_change_keeps_session(client, identity_db):
    token = login(client).json()["token"]
    headers = {"X-Admin-Token": token}
    assert client.post("/api/v1/admin/auth/change-password", headers=headers,
        json={"old_password": "wrong", "new_password": NEW}).status_code == 401
    assert client.post("/api/v1/admin/auth/change-password", headers=headers,
        json={"old_password": PASSWORD, "new_password": "short"}).status_code == 422
    assert client.get("/api/v1/admin/auth/verify", headers=headers).json()["valid"] is True


def test_expired_and_conflicting_headers_rejected(client, identity_db):
    token = login(client).json()["token"]
    conflict = {"X-Admin-Token": token, "Authorization": "Bearer other"}
    assert client.get("/api/v1/admin/auth/verify", headers=conflict).status_code == 401
    assert client.get("/api/v1/admin/families", headers=conflict).status_code == 401
    with identity_db.begin() as db:
        session = db.execute(select(AdminSession)).scalar_one()
        session.expires_at = time.time() - 1
    assert client.get("/api/v1/admin/auth/verify", headers={"X-Admin-Token": token}).json()["valid"] is False


def test_simultaneous_password_changes_only_one_wins(identity_db):
    bootstrap = hashlib.sha256(PASSWORD.encode()).hexdigest()
    token, _ = store.login("admin", PASSWORD, bootstrap, SECRET, 24)
    def change(new):
        return store.change_password("admin", token, PASSWORD, new, bootstrap, SECRET)
    with ThreadPoolExecutor(max_workers=2) as pool:
        results = list(pool.map(change, [NEW, NEW + "-other"]))
    assert sorted(results) == ["changed", "unauthorized"]
    assert store.verify(token, SECRET) is None


def test_failed_commit_does_not_change_password(identity_db, monkeypatch):
    bootstrap = hashlib.sha256(PASSWORD.encode()).hexdigest()
    token, _ = store.login("admin", PASSWORD, bootstrap, SECRET, 24)
    from sqlalchemy.orm import Session
    def fail(self):
        raise RuntimeError("commit unavailable")
    with monkeypatch.context() as patch:
        patch.setattr(Session, "commit", fail)
        with pytest.raises(RuntimeError, match="commit unavailable"):
            store.change_password("admin", token, PASSWORD, NEW, bootstrap, SECRET)
    assert store.verify(token, SECRET) == "admin"
    assert store.login("admin", PASSWORD, bootstrap, SECRET, 24)


def test_session_verified_by_separate_process(identity_db):
    import json
    import subprocess
    import sys
    from pathlib import Path
    bootstrap = hashlib.sha256(PASSWORD.encode()).hexdigest()
    token, _ = store.login("admin", PASSWORD, bootstrap, SECRET, 24)
    script = """
import json, sys
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.services import admin_identity as store
config = json.load(sys.stdin)
engine = create_engine(config["url"])
store.session_factory = sessionmaker(bind=engine)
assert store.verify(config["token"], config["secret"]) == "admin"
engine.dispose()
print("independent process verified")
"""
    result = subprocess.run([sys.executable, "-c", script],
        input=json.dumps({"url": identity_db.kw["bind"].url.render_as_string(hide_password=False),
                         "token": token, "secret": SECRET}),
        text=True, capture_output=True, timeout=30, cwd=Path(__file__).resolve().parents[1])
    assert result.returncode == 0, result.stderr
    assert result.stdout.strip() == "independent process verified"


def test_simultaneous_first_logins_share_one_credential(identity_db):
    bootstrap = hashlib.sha256(PASSWORD.encode()).hexdigest()
    def enter(_):
        return store.login("admin", PASSWORD, bootstrap, SECRET, 24)[0]
    with ThreadPoolExecutor(max_workers=2) as pool:
        tokens = list(pool.map(enter, range(2)))
    assert tokens[0] != tokens[1]
    assert all(store.verify(token, SECRET) == "admin" for token in tokens)
    with identity_db() as db:
        assert len(db.execute(select(AdminCredential)).scalars().all()) == 1


def test_admin_migration_is_repeatable_and_preserves_sessions(identity_db):
    import importlib.util
    from pathlib import Path
    from alembic.migration import MigrationContext
    from alembic.operations import Operations
    path = Path(__file__).resolve().parents[1] / "alembic/versions/20261012_admin_identity.py"
    spec = importlib.util.spec_from_file_location("admin_migration", path)
    migration = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(migration)
    bootstrap = hashlib.sha256(PASSWORD.encode()).hexdigest()
    token, _ = store.login("admin", PASSWORD, bootstrap, SECRET, 24)
    engine = identity_db.kw["bind"]
    with engine.begin() as connection:
        migration.op = Operations(MigrationContext.configure(connection))
        migration.upgrade()
        migration.upgrade()
    assert store.verify(token, SECRET) == "admin"
    with engine.begin() as connection:
        migration.op = Operations(MigrationContext.configure(connection))
        migration.downgrade()
        migration.upgrade()
    assert store.verify(token, SECRET) is None
    assert store.login("admin", PASSWORD, bootstrap, SECRET, 24)
