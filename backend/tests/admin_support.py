"""Database-backed administrator fixtures, no production bypass."""
import secrets
import time
from app.db.database import session_factory
from app.models.admin_identity import AdminCredential, AdminSession
from app.router.admin_auth import ADMIN_JWT_SECRET
from app.services.admin_identity import token_digest, logout


def create_admin_session():
    token = secrets.token_urlsafe(32)
    with session_factory.begin() as db:
        credential = db.get(AdminCredential, "fixture-operator")
        if credential is None:
            credential = AdminCredential(username="fixture-operator", password_hash="no-login", version=1)
            db.add(credential)
            db.flush()
        db.add(AdminSession(token_digest=token_digest(token, ADMIN_JWT_SECRET),
            username=credential.username, credential_version=credential.version,
            expires_at=time.time() + 3600))
    return token


def remove_admin_session(token):
    logout(token, ADMIN_JWT_SECRET)
