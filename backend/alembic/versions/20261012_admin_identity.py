"""Persist administrator credentials and revocable sessions.

Revision ID: 20261012_admin_identity
Revises: 120c73a3479b
"""
from alembic import op
import sqlalchemy as sa

metadata = sa.MetaData()
credentials = sa.Table(
    "admin_credentials", metadata,
    sa.Column("username", sa.String(100), primary_key=True),
    sa.Column("password_hash", sa.String(256), nullable=False),
    sa.Column("salt", sa.String(64)),
    sa.Column("version", sa.Integer, nullable=False),
)
sessions = sa.Table(
    "admin_sessions", metadata,
    sa.Column("token_digest", sa.String(64), primary_key=True),
    sa.Column("username", sa.String(100), nullable=False, index=True),
    sa.Column("credential_version", sa.Integer, nullable=False),
    sa.Column("expires_at", sa.Float, nullable=False, index=True),
)

revision = "20261012_admin_identity"
down_revision = "120c73a3479b"
branch_labels = None
depends_on = None


def upgrade():
    # Existing startup create_all deployments may already contain these tables.
    credentials.create(op.get_bind(), checkfirst=True)
    sessions.create(op.get_bind(), checkfirst=True)


def downgrade():
    sessions.drop(op.get_bind(), checkfirst=True)
    credentials.drop(op.get_bind(), checkfirst=True)
