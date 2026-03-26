"""
顺时 ShunShi - 初始迁移: SQLite → PostgreSQL
迁移所有现有表结构到 PostgreSQL，同时保留 SQLite 兼容

修订 ID: 001
创建时间: 2026-03-18

使用方法:
  开发环境: alembic upgrade head
  生产环境: alembic -x url=postgresql+asyncpg://user:pass@host:5432/shunshi upgrade head
"""
from typing import Sequence, Union

import sqlalchemy as sa
from sqlalchemy.dialects import postgresql
from alembic import op

# revision identifiers
revision: str = "001"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """创建所有表结构"""

    # ========== 用户相关 ==========
    op.create_table(
        "sa_users",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("phone", sa.String(20), unique=True, nullable=True),
        sa.Column("email", sa.String(255), unique=True, nullable=True),
        sa.Column("nickname", sa.String(100), nullable=False, server_default="用户"),
        sa.Column("avatar", sa.String(500), nullable=True),
        sa.Column("gender", sa.String(10), nullable=True),
        sa.Column("age", sa.Integer, nullable=True),
        sa.Column("life_stage", sa.String(20), nullable=False, server_default="exploring"),
        sa.Column("status", sa.String(20), nullable=False, server_default="active"),
        sa.Column("auth_provider", sa.String(20), nullable=True),
        sa.Column("auth_provider_id", sa.String(255), nullable=True),
        sa.Column("last_login_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("last_login_ip", sa.String(45), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("is_deleted", sa.Boolean, nullable=False, server_default=sa.text("false")),
    )

    op.create_table(
        "sa_user_preferences",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("sa_users.id", ondelete="CASCADE"), unique=True, nullable=False),
        sa.Column("sleep_time", sa.Time, nullable=False, server_default="23:00"),
        sa.Column("wake_time", sa.Time, nullable=False, server_default="07:00"),
        sa.Column("reminder_style", sa.String(20), nullable=False, server_default="gentle"),
        sa.Column("interaction_style", sa.String(20), nullable=False, server_default="warm"),
        sa.Column("memory_enabled", sa.Boolean, nullable=False, server_default=sa.text("true")),
        sa.Column("proactive_enabled", sa.Boolean, nullable=False, server_default=sa.text("true")),
        sa.Column("quiet_hours_start", sa.Time, nullable=False, server_default="23:00"),
        sa.Column("quiet_hours_end", sa.Time, nullable=False, server_default="07:00"),
        sa.Column("locale", sa.String(10), nullable=False, server_default="zh-CN"),
        sa.Column("dietary_restrictions", postgresql.JSON, nullable=True),
        sa.Column("interests", postgresql.JSON, nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("is_deleted", sa.Boolean, nullable=False, server_default=sa.text("false")),
    )

    op.create_table(
        "sa_user_devices",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("sa_users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("device_id", sa.String(255), unique=True, nullable=False),
        sa.Column("platform", sa.String(20), nullable=False),
        sa.Column("push_token", sa.String(500), nullable=True),
        sa.Column("app_version", sa.String(50), nullable=True),
        sa.Column("os_version", sa.String(50), nullable=True),
        sa.Column("last_active_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("is_active", sa.Boolean, nullable=False, server_default=sa.text("true")),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("is_deleted", sa.Boolean, nullable=False, server_default=sa.text("false")),
    )
    op.create_index("ix_sa_user_devices_user_id", "sa_user_devices", ["user_id"])

    op.create_table(
        "sa_user_memories",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("sa_users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("memory_type", sa.String(30), nullable=False),
        sa.Column("content", postgresql.JSON, nullable=True),
        sa.Column("source", sa.String(20), nullable=False, server_default="ai_inferred"),
        sa.Column("confidence", sa.Float, nullable=False, server_default="1.0"),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_by", sa.String(20), nullable=False, server_default="ai_system"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("is_deleted", sa.Boolean, nullable=False, server_default=sa.text("false")),
    )
    op.create_index("ix_sa_user_memories_user_id", "sa_user_memories", ["user_id"])

    # ========== 订阅相关 ==========
    op.create_table(
        "sa_subscription_products",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("product_id", sa.String(100), unique=True, nullable=False),
        sa.Column("name", sa.String(200), nullable=False),
        sa.Column("tier", sa.String(20), nullable=False),
        sa.Column("platform", sa.String(20), nullable=True),
        sa.Column("price", sa.Numeric(10, 2), nullable=False, server_default="0.00"),
        sa.Column("currency", sa.String(10), nullable=False, server_default="CNY"),
        sa.Column("duration_days", sa.Integer, nullable=False, server_default="30"),
        sa.Column("max_family_seats", sa.Integer, nullable=False, server_default="0"),
        sa.Column("features", postgresql.JSON, nullable=True),
        sa.Column("status", sa.String(20), nullable=False, server_default="active"),
        sa.Column("sort_order", sa.Integer, nullable=False, server_default="0"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("is_deleted", sa.Boolean, nullable=False, server_default=sa.text("false")),
    )

    op.create_table(
        "sa_subscription_orders",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("order_no", sa.String(100), unique=True, nullable=False),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("sa_users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("product_id", sa.ForeignKey("sa_subscription_products.id", ondelete="SET NULL"), nullable=True),
        sa.Column("platform", sa.String(20), nullable=True),
        sa.Column("amount", sa.Numeric(10, 2), nullable=False, server_default="0.00"),
        sa.Column("currency", sa.String(10), nullable=False, server_default="CNY"),
        sa.Column("status", sa.String(20), nullable=False, server_default="pending"),
        sa.Column("transaction_id", sa.String(255), nullable=True),
        sa.Column("paid_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("refund_reason", sa.String(500), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("is_deleted", sa.Boolean, nullable=False, server_default=sa.text("false")),
    )
    op.create_index("ix_sa_subscription_orders_user_id", "sa_subscription_orders", ["user_id"])

    op.create_table(
        "sa_user_subscriptions",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("sa_users.id", ondelete="CASCADE"), unique=True, nullable=False),
        sa.Column("tier", sa.String(20), nullable=False, server_default="free"),
        sa.Column("order_id", sa.ForeignKey("sa_subscription_orders.id", ondelete="SET NULL"), nullable=True),
        sa.Column("start_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("end_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("status", sa.String(20), nullable=False, server_default="active"),
        sa.Column("auto_renew", sa.Boolean, nullable=False, server_default=sa.text("true")),
        sa.Column("source", sa.String(20), nullable=False, server_default="purchase"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("is_deleted", sa.Boolean, nullable=False, server_default=sa.text("false")),
    )

    # ========== 对话相关 ==========
    op.create_table(
        "sa_conversations",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("sa_users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("title", sa.String(200), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("is_deleted", sa.Boolean, nullable=False, server_default=sa.text("false")),
    )
    op.create_index("ix_sa_conversations_user_id", "sa_conversations", ["user_id"])

    op.create_table(
        "sa_messages",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("conversation_id", sa.String(36), sa.ForeignKey("sa_conversations.id", ondelete="CASCADE"), nullable=False),
        sa.Column("role", sa.String(20), nullable=False),
        sa.Column("content", sa.Text, nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("is_deleted", sa.Boolean, nullable=False, server_default=sa.text("false")),
    )
    op.create_index("ix_sa_messages_conversation_id", "sa_messages", ["conversation_id"])

    # ========== 通知 ==========
    op.create_table(
        "sa_notifications",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("sa_users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("type", sa.String(30), nullable=False),
        sa.Column("title", sa.String(200), nullable=False),
        sa.Column("body", sa.String(1000), nullable=True),
        sa.Column("data", postgresql.JSON, nullable=True),
        sa.Column("sent_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("read_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("channel", sa.String(20), nullable=False, server_default="push"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("is_deleted", sa.Boolean, nullable=False, server_default=sa.text("false")),
    )
    op.create_index("ix_sa_notifications_user_id", "sa_notifications", ["user_id"])

    # ========== 内容 ==========
    op.create_table(
        "sa_content_items",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("title", sa.String(200), nullable=False),
        sa.Column("description", sa.Text, nullable=True),
        sa.Column("type", sa.String(50), nullable=False),
        sa.Column("category", sa.String(50), nullable=True),
        sa.Column("difficulty", sa.String(20), nullable=True),
        sa.Column("time", sa.String(20), nullable=True),
        sa.Column("duration", sa.String(20), nullable=True),
        sa.Column("ingredients", postgresql.JSON, nullable=True),
        sa.Column("steps", postgresql.JSON, nullable=True),
        sa.Column("location", sa.String(200), nullable=True),
        sa.Column("method", sa.String(500), nullable=True),
        sa.Column("effect", sa.String(500), nullable=True),
        sa.Column("benefits", postgresql.JSON, nullable=True),
        sa.Column("best_time", sa.String(50), nullable=True),
        sa.Column("season_tag", sa.String(20), nullable=True),
        sa.Column("locale", sa.String(10), nullable=False, server_default="zh-CN"),
        sa.Column("view_count", sa.Integer, nullable=False, server_default="0"),
        sa.Column("like_count", sa.Integer, nullable=False, server_default="0"),
        sa.Column("is_premium", sa.Boolean, nullable=False, server_default=sa.text("false")),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("is_deleted", sa.Boolean, nullable=False, server_default=sa.text("false")),
    )

    op.create_table(
        "sa_content_media",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("content_id", sa.ForeignKey("sa_content_items.id", ondelete="CASCADE"), nullable=False),
        sa.Column("url", sa.String(500), nullable=False),
        sa.Column("media_type", sa.String(20), nullable=False),
        sa.Column("sort_order", sa.Integer, nullable=False, server_default="0"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("is_deleted", sa.Boolean, nullable=False, server_default=sa.text("false")),
    )

    op.create_table(
        "sa_content_tags",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("name", sa.String(50), unique=True, nullable=False),
        sa.Column("locale", sa.String(10), nullable=False, server_default="zh-CN"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("is_deleted", sa.Boolean, nullable=False, server_default=sa.text("false")),
    )

    op.create_table(
        "sa_content_tag_relations",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("content_id", sa.ForeignKey("sa_content_items.id", ondelete="CASCADE"), nullable=False),
        sa.Column("tag_id", sa.ForeignKey("sa_content_tags.id", ondelete="CASCADE"), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("is_deleted", sa.Boolean, nullable=False, server_default=sa.text("false")),
    )

    # ========== 体质辨识 ==========
    op.create_table(
        "sa_constitutions",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("user_id", sa.ForeignKey("sa_users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("result_type", sa.String(50), nullable=False),
        sa.Column("score", sa.Float, nullable=False),
        sa.Column("answers", postgresql.JSON, nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("is_deleted", sa.Boolean, nullable=False, server_default=sa.text("false")),
    )

    op.create_table(
        "sa_constitution_questions",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("category", sa.String(50), nullable=False),
        sa.Column("question_text", sa.Text, nullable=False),
        sa.Column("options", postgresql.JSON, nullable=True),
        sa.Column("sort_order", sa.Integer, nullable=False, server_default="0"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("is_deleted", sa.Boolean, nullable=False, server_default=sa.text("false")),
    )

    op.create_table(
        "sa_constitution_results",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("user_id", sa.ForeignKey("sa_users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("constitution_type", sa.String(50), nullable=False),
        sa.Column("score", sa.Float, nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("is_deleted", sa.Boolean, nullable=False, server_default=sa.text("false")),
    )

    # ========== 节气 ==========
    op.create_table(
        "sa_solar_terms",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("name", sa.String(50), nullable=False),
        sa.Column("date", sa.Date, nullable=False),
        sa.Column("description", sa.Text, nullable=True),
        sa.Column("health_advice", postgresql.JSON, nullable=True),
        sa.Column("locale", sa.String(10), nullable=False, server_default="zh-CN"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("is_deleted", sa.Boolean, nullable=False, server_default=sa.text("false")),
    )

    op.create_table(
        "sa_solar_term_contents",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("solar_term_id", sa.ForeignKey("sa_solar_terms.id", ondelete="CASCADE"), nullable=False),
        sa.Column("content_id", sa.ForeignKey("sa_content_items.id", ondelete="CASCADE"), nullable=False),
        sa.Column("sort_order", sa.Integer, nullable=False, server_default="0"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("is_deleted", sa.Boolean, nullable=False, server_default=sa.text("false")),
    )

    # ========== 日记/报告 ==========
    op.create_table(
        "sa_diary_entries",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("user_id", sa.ForeignKey("sa_users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("date", sa.Date, nullable=False),
        sa.Column("mood", sa.String(20), nullable=True),
        sa.Column("content", sa.Text, nullable=True),
        sa.Column("tags", postgresql.JSON, nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("is_deleted", sa.Boolean, nullable=False, server_default=sa.text("false")),
    )

    op.create_table(
        "sa_weekly_reports",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("user_id", sa.ForeignKey("sa_users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("week_start", sa.Date, nullable=False),
        sa.Column("summary", sa.Text, nullable=True),
        sa.Column("metrics", postgresql.JSON, nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("is_deleted", sa.Boolean, nullable=False, server_default=sa.text("false")),
    )

    op.create_table(
        "sa_monthly_reports",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("user_id", sa.ForeignKey("sa_users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("month", sa.Date, nullable=False),
        sa.Column("summary", sa.Text, nullable=True),
        sa.Column("metrics", postgresql.JSON, nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("is_deleted", sa.Boolean, nullable=False, server_default=sa.text("false")),
    )

    # ========== 跟进 ==========
    op.create_table(
        "sa_follow_ups",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("user_id", sa.ForeignKey("sa_users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("conversation_id", sa.ForeignKey("sa_conversations.id", ondelete="SET NULL"), nullable=True),
        sa.Column("title", sa.String(200), nullable=False),
        sa.Column("description", sa.Text, nullable=True),
        sa.Column("type", sa.String(20), nullable=False, server_default="wellness"),
        sa.Column("status", sa.String(20), nullable=False, server_default="pending"),
        sa.Column("priority", sa.String(20), nullable=False, server_default="normal"),
        sa.Column("scheduled_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("is_deleted", sa.Boolean, nullable=False, server_default=sa.text("false")),
    )

    # ========== 家庭 ==========
    op.create_table(
        "sa_family_relations",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("user_id", sa.ForeignKey("sa_users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("family_id", sa.String(36), nullable=False),
        sa.Column("family_name", sa.String(100), nullable=False, server_default="我的家庭"),
        sa.Column("member_name", sa.String(100), nullable=False),
        sa.Column("relation", sa.String(50), nullable=False),
        sa.Column("age", sa.Integer, nullable=True),
        sa.Column("status", sa.String(20), nullable=False, server_default="normal"),
        sa.Column("last_active_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("user_id_member", sa.String(36), nullable=True),
        sa.Column("health_data", postgresql.JSON, nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("is_deleted", sa.Boolean, nullable=False, server_default=sa.text("false")),
    )

    # ========== 审计 ==========
    op.create_table(
        "sa_audit_logs",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("event_id", sa.String(100), nullable=True),
        sa.Column("user_id", sa.String(36), nullable=True),
        sa.Column("action", sa.String(50), nullable=False),
        sa.Column("request_data", postgresql.JSON, nullable=True),
        sa.Column("response_data", postgresql.JSON, nullable=True),
        sa.Column("model", sa.String(50), nullable=True),
        sa.Column("tokens_used", sa.Integer, nullable=True),
        sa.Column("latency_ms", sa.Integer, nullable=True),
        sa.Column("cost_usd", sa.Float, nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("is_deleted", sa.Boolean, nullable=False, server_default=sa.text("false")),
    )

    op.create_table(
        "sa_prompt_versions",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("name", sa.String(100), unique=True, nullable=False),
        sa.Column("content", sa.Text, nullable=False),
        sa.Column("version", sa.Integer, nullable=False, server_default="1"),
        sa.Column("is_active", sa.Boolean, nullable=False, server_default=sa.text("true")),
        sa.Column("created_at", sa.DateTime(timezone(True)), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("is_deleted", sa.Boolean, nullable=False, server_default=sa.text("false")),
    )

    op.create_table(
        "sa_feature_flags",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("key", sa.String(100), unique=True, nullable=False),
        sa.Column("value", postgresql.JSON, nullable=True),
        sa.Column("description", sa.String(500), nullable=True),
        sa.Column("enabled", sa.Boolean, nullable=False, server_default=sa.text("true")),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("is_deleted", sa.Boolean, nullable=False, server_default=sa.text("false")),
    )


def downgrade() -> None:
    """删除所有表"""
    # 按依赖关系逆序删除
    tables = [
        "sa_feature_flags",
        "sa_prompt_versions",
        "sa_audit_logs",
        "sa_family_relations",
        "sa_follow_ups",
        "sa_monthly_reports",
        "sa_weekly_reports",
        "sa_diary_entries",
        "sa_solar_term_contents",
        "sa_solar_terms",
        "sa_constitution_results",
        "sa_constitution_questions",
        "sa_constitutions",
        "sa_content_tag_relations",
        "sa_content_tags",
        "sa_content_media",
        "sa_content_items",
        "sa_notifications",
        "sa_messages",
        "sa_conversations",
        "sa_user_subscriptions",
        "sa_subscription_orders",
        "sa_subscription_products",
        "sa_user_memories",
        "sa_user_devices",
        "sa_user_preferences",
        "sa_users",
    ]
    for table in tables:
        op.drop_table(table)
