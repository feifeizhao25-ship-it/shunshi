"""Shared database-backed administrator authentication; no raw token storage."""
import hashlib
import hmac
import secrets
import time
from contextlib import contextmanager

from sqlalchemy import delete, select, text
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.dialects.sqlite import insert as sqlite_insert

from app.db.database import session_factory
from app.models.admin_identity import AdminCredential, AdminSession
from app.security import hash_password, check_password


def token_digest(token, secret):
    return hmac.new(secret.encode(), token.encode(), hashlib.sha256).hexdigest()


@contextmanager
def _credential_transaction(username, bootstrap_hash):
    with session_factory() as db:
        try:
            dialect = db.get_bind().dialect.name
            if dialect == "sqlite":
                db.execute(text("BEGIN IMMEDIATE"))
            insert = sqlite_insert if dialect == "sqlite" else pg_insert
            db.execute(insert(AdminCredential).values(
                username=username, password_hash=bootstrap_hash, salt=None, version=1,
            ).on_conflict_do_nothing(index_elements=["username"]))
            credential = db.execute(
                select(AdminCredential).where(AdminCredential.username == username).with_for_update()
            ).scalar_one()
            yield db, credential
            db.commit()
        except Exception:
            db.rollback()
            raise


def _password_matches(credential, password):
    if credential.salt:
        return check_password(password, credential.salt, credential.password_hash)
    return hmac.compare_digest(hashlib.sha256(password.encode()).hexdigest(), credential.password_hash)


def login(username, password, bootstrap_hash, secret, lifetime_hours):
    with _credential_transaction(username, bootstrap_hash) as (db, credential):
        if not _password_matches(credential, password):
            return None
        if credential.salt is None:
            credential.salt = secrets.token_hex(16)
            credential.password_hash = hash_password(password, credential.salt)
        token = secrets.token_urlsafe(32)
        expires = time.time() + lifetime_hours * 3600
        db.execute(delete(AdminSession).where(AdminSession.expires_at <= time.time()))
        db.add(AdminSession(
            token_digest=token_digest(token, secret), username=username,
            credential_version=credential.version, expires_at=expires,
        ))
    return token, expires


def verify(token, secret):
    if not token or len(token) > 512:
        return None
    with session_factory() as db:
        return db.execute(
            select(AdminSession.username).join(
                AdminCredential, AdminCredential.username == AdminSession.username,
            ).where(
                AdminSession.token_digest == token_digest(token, secret),
                AdminSession.expires_at > time.time(),
                AdminSession.credential_version == AdminCredential.version,
            )
        ).scalar_one_or_none()


def logout(token, secret):
    with session_factory.begin() as db:
        db.execute(delete(AdminSession).where(
            AdminSession.token_digest == token_digest(token, secret),
        ))


def change_password(username, token, old_password, new_password, bootstrap_hash, secret):
    with _credential_transaction(username, bootstrap_hash) as (db, credential):
        session = db.get(AdminSession, token_digest(token, secret))
        if (session is None or session.username != username
                or session.expires_at <= time.time()
                or session.credential_version != credential.version):
            return "unauthorized"
        if not _password_matches(credential, old_password):
            return "wrong_password"
        credential.salt = secrets.token_hex(16)
        credential.password_hash = hash_password(new_password, credential.salt)
        credential.version += 1
        db.execute(delete(AdminSession).where(AdminSession.username == username))
    return "changed"
