"""Create sa_favorites (the favorites router used it, but no migration or model ever created it).

Revision ID: 20261101_favorites
Revises: 20261012_admin_identity
"""
from alembic import op
import sqlalchemy as sa

revision = "20261101_favorites"
down_revision = "20261012_admin_identity"
branch_labels = None
depends_on = None


def upgrade():
    bind = op.get_bind()
    if "sa_favorites" in sa.inspect(bind).get_table_names():
        return  # create_all 部署可能已经建过
    op.create_table(
        "sa_favorites",
        sa.Column("id", sa.CHAR(36), primary_key=True),
        sa.Column("user_id", sa.String(64), nullable=False),
        sa.Column("content_id", sa.String(128), nullable=False),
        sa.Column("content_type", sa.String(50)),
        sa.Column("created_at", sa.TIMESTAMP, nullable=False),
        sa.UniqueConstraint("user_id", "content_id", name="uq_sa_favorites_user_content"),
    )
    op.create_index("ix_sa_favorites_user_id", "sa_favorites", ["user_id"])


def downgrade():
    op.drop_index("ix_sa_favorites_user_id", table_name="sa_favorites")
    op.drop_table("sa_favorites")
