"""Durable administrator credentials and revocable session digests."""
from sqlalchemy import Column, Float, Integer, String
from app.db.database import Base


class AdminCredential(Base):
    __tablename__ = "admin_credentials"
    username = Column(String(100), primary_key=True)
    password_hash = Column(String(256), nullable=False)
    salt = Column(String(64), nullable=True)
    version = Column(Integer, nullable=False, default=1)


class AdminSession(Base):
    __tablename__ = "admin_sessions"
    token_digest = Column(String(64), primary_key=True)
    username = Column(String(100), nullable=False, index=True)
    credential_version = Column(Integer, nullable=False)
    expires_at = Column(Float, nullable=False, index=True)
