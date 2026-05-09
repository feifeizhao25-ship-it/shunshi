"""Add wellness tracking tables for 43 new routers

Revision ID: 002_wellness_tracking
Revises: 001
Create Date: 2024-01-01 00:00:00.000000

Tables added:
  - water_logs, water_goals
  - menstrual_cycles, menstrual_settings
  - habits, habit_checkins
  - meal_logs, calorie_goals
  - gratitude_entries
  - weight_logs, weight_goals
  - dream_logs
  - smart_alarms
  - community_posts, community_comments
  - expert_questions
  - user_feedback
  - coupons
  - gift_orders, gift_cards
  - live_class_bookings
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID, JSON

# revision identifiers
revision = "002_wellness_tracking"
down_revision = "001"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # ─── water_logs ───
    op.create_table(
        "water_logs",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id", sa.String(64), nullable=False),
        sa.Column("amount_ml", sa.Integer, nullable=False),
        sa.Column("type", sa.String(32), server_default="water"),
        sa.Column("logged_at", sa.TIMESTAMP, server_default=sa.text("NOW()")),
        sa.Column("date", sa.Date, nullable=False),
    )
    op.create_index("ix_water_logs_user_id", "water_logs", ["user_id"])
    op.create_index("ix_water_logs_date", "water_logs", ["date"])

    # ─── water_goals ───
    op.create_table(
        "water_goals",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id", sa.String(64), nullable=False, unique=True),
        sa.Column("goal_ml", sa.Integer, server_default="1700"),
        sa.Column("updated_at", sa.TIMESTAMP, server_default=sa.text("NOW()")),
    )
    op.create_index("ix_water_goals_user_id", "water_goals", ["user_id"])

    # ─── menstrual_cycles ───
    op.create_table(
        "menstrual_cycles",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id", sa.String(64), nullable=False),
        sa.Column("start_date", sa.Date, nullable=False),
        sa.Column("end_date", sa.Date),
        sa.Column("cycle_length", sa.Integer, server_default="28"),
        sa.Column("period_length", sa.Integer, server_default="5"),
        sa.Column("flow_level", sa.String(16), server_default="normal"),
        sa.Column("symptoms", JSON, server_default="[]"),
        sa.Column("notes", sa.Text),
        sa.Column("logged_at", sa.TIMESTAMP, server_default=sa.text("NOW()")),
    )
    op.create_index("ix_menstrual_cycles_user_id", "menstrual_cycles", ["user_id"])

    # ─── menstrual_settings ───
    op.create_table(
        "menstrual_settings",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id", sa.String(64), nullable=False, unique=True),
        sa.Column("avg_cycle_length", sa.Integer, server_default="28"),
        sa.Column("avg_period_length", sa.Integer, server_default="5"),
        sa.Column("reminder_enabled", sa.Boolean, server_default="true"),
        sa.Column("reminder_days_before", sa.Integer, server_default="2"),
        sa.Column("updated_at", sa.TIMESTAMP, server_default=sa.text("NOW()")),
    )

    # ─── habits ───
    op.create_table(
        "habits",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id", sa.String(64), nullable=False),
        sa.Column("name", sa.String(100), nullable=False),
        sa.Column("category", sa.String(32)),
        sa.Column("frequency", sa.String(16), server_default="daily"),
        sa.Column("target_days", sa.Integer, server_default="21"),
        sa.Column("current_streak", sa.Integer, server_default="0"),
        sa.Column("longest_streak", sa.Integer, server_default="0"),
        sa.Column("total_checkins", sa.Integer, server_default="0"),
        sa.Column("is_active", sa.Boolean, server_default="true"),
        sa.Column("created_at", sa.TIMESTAMP, server_default=sa.text("NOW()")),
        sa.Column("updated_at", sa.TIMESTAMP, server_default=sa.text("NOW()")),
    )
    op.create_index("ix_habits_user_id", "habits", ["user_id"])

    # ─── habit_checkins ───
    op.create_table(
        "habit_checkins",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("habit_id", UUID(as_uuid=True),
                  sa.ForeignKey("habits.id", ondelete="CASCADE"), nullable=False),
        sa.Column("user_id", sa.String(64), nullable=False),
        sa.Column("check_date", sa.Date, nullable=False),
        sa.Column("note", sa.Text),
        sa.Column("logged_at", sa.TIMESTAMP, server_default=sa.text("NOW()")),
    )
    op.create_index("ix_habit_checkins_user_id", "habit_checkins", ["user_id"])

    # ─── meal_logs ───
    op.create_table(
        "meal_logs",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id", sa.String(64), nullable=False),
        sa.Column("meal_type", sa.String(16), nullable=False),
        sa.Column("foods", JSON, server_default="[]"),
        sa.Column("total_calories", sa.Float, server_default="0"),
        sa.Column("total_protein_g", sa.Float, server_default="0"),
        sa.Column("total_carbs_g", sa.Float, server_default="0"),
        sa.Column("total_fat_g", sa.Float, server_default="0"),
        sa.Column("date", sa.Date, nullable=False),
        sa.Column("logged_at", sa.TIMESTAMP, server_default=sa.text("NOW()")),
    )
    op.create_index("ix_meal_logs_user_id", "meal_logs", ["user_id"])
    op.create_index("ix_meal_logs_date", "meal_logs", ["date"])

    # ─── calorie_goals ───
    op.create_table(
        "calorie_goals",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id", sa.String(64), nullable=False, unique=True),
        sa.Column("daily_calories", sa.Integer, server_default="2000"),
        sa.Column("updated_at", sa.TIMESTAMP, server_default=sa.text("NOW()")),
    )

    # ─── gratitude_entries ───
    op.create_table(
        "gratitude_entries",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id", sa.String(64), nullable=False),
        sa.Column("content", sa.Text, nullable=False),
        sa.Column("items", JSON, server_default="[]"),
        sa.Column("mood", sa.String(16), server_default="neutral"),
        sa.Column("date", sa.Date, nullable=False),
        sa.Column("logged_at", sa.TIMESTAMP, server_default=sa.text("NOW()")),
    )
    op.create_index("ix_gratitude_entries_user_id", "gratitude_entries", ["user_id"])

    # ─── weight_logs ───
    op.create_table(
        "weight_logs",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id", sa.String(64), nullable=False),
        sa.Column("weight_kg", sa.Float, nullable=False),
        sa.Column("bmi", sa.Float),
        sa.Column("date", sa.Date, nullable=False),
        sa.Column("note", sa.Text),
        sa.Column("logged_at", sa.TIMESTAMP, server_default=sa.text("NOW()")),
    )
    op.create_index("ix_weight_logs_user_id", "weight_logs", ["user_id"])

    # ─── weight_goals ───
    op.create_table(
        "weight_goals",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id", sa.String(64), nullable=False, unique=True),
        sa.Column("target_weight_kg", sa.Float),
        sa.Column("weeks", sa.Integer, server_default="12"),
        sa.Column("updated_at", sa.TIMESTAMP, server_default=sa.text("NOW()")),
    )

    # ─── dream_logs ───
    op.create_table(
        "dream_logs",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id", sa.String(64), nullable=False),
        sa.Column("description", sa.Text, nullable=False),
        sa.Column("dream_quality", sa.String(32), server_default="vivid_dreams"),
        sa.Column("emotions", JSON, server_default="[]"),
        sa.Column("sleep_time", sa.String(5)),
        sa.Column("wake_time", sa.String(5)),
        sa.Column("body_symptoms", JSON, server_default="[]"),
        sa.Column("tcm_analysis", JSON),
        sa.Column("date", sa.Date, nullable=False),
        sa.Column("logged_at", sa.TIMESTAMP, server_default=sa.text("NOW()")),
    )
    op.create_index("ix_dream_logs_user_id", "dream_logs", ["user_id"])

    # ─── smart_alarms ───
    op.create_table(
        "smart_alarms",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id", sa.String(64), nullable=False),
        sa.Column("alarm_type", sa.String(32), nullable=False),
        sa.Column("time", sa.String(5), nullable=False),
        sa.Column("days", JSON, server_default="[]"),
        sa.Column("sound", sa.String(64), server_default="morning_bell"),
        sa.Column("enabled", sa.Boolean, server_default="true"),
        sa.Column("shichen_aligned", sa.Boolean, server_default="false"),
        sa.Column("created_at", sa.TIMESTAMP, server_default=sa.text("NOW()")),
        sa.Column("updated_at", sa.TIMESTAMP, server_default=sa.text("NOW()")),
    )
    op.create_index("ix_smart_alarms_user_id", "smart_alarms", ["user_id"])

    # ─── community_posts ───
    op.create_table(
        "community_posts",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id", sa.String(64), nullable=False),
        sa.Column("content", sa.Text, nullable=False),
        sa.Column("category", sa.String(32), server_default="general"),
        sa.Column("tags", JSON, server_default="[]"),
        sa.Column("likes", sa.Integer, server_default="0"),
        sa.Column("comment_count", sa.Integer, server_default="0"),
        sa.Column("is_featured", sa.Boolean, server_default="false"),
        sa.Column("is_active", sa.Boolean, server_default="true"),
        sa.Column("created_at", sa.TIMESTAMP, server_default=sa.text("NOW()")),
        sa.Column("updated_at", sa.TIMESTAMP, server_default=sa.text("NOW()")),
    )
    op.create_index("ix_community_posts_user_id", "community_posts", ["user_id"])

    # ─── community_comments ───
    op.create_table(
        "community_comments",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("post_id", UUID(as_uuid=True),
                  sa.ForeignKey("community_posts.id", ondelete="CASCADE"), nullable=False),
        sa.Column("user_id", sa.String(64), nullable=False),
        sa.Column("content", sa.Text, nullable=False),
        sa.Column("likes", sa.Integer, server_default="0"),
        sa.Column("created_at", sa.TIMESTAMP, server_default=sa.text("NOW()")),
    )
    op.create_index("ix_community_comments_post_id", "community_comments", ["post_id"])

    # ─── expert_questions ───
    op.create_table(
        "expert_questions",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id", sa.String(64), nullable=False),
        sa.Column("question", sa.Text, nullable=False),
        sa.Column("category", sa.String(32), server_default="general"),
        sa.Column("expert_id", sa.String(64)),
        sa.Column("answer", sa.Text),
        sa.Column("answered_by", sa.String(64)),
        sa.Column("status", sa.String(16), server_default="pending"),
        sa.Column("created_at", sa.TIMESTAMP, server_default=sa.text("NOW()")),
        sa.Column("answered_at", sa.TIMESTAMP),
    )
    op.create_index("ix_expert_questions_user_id", "expert_questions", ["user_id"])

    # ─── user_feedback ───
    op.create_table(
        "user_feedback",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id", sa.String(64), nullable=False),
        sa.Column("feedback_type", sa.String(32), nullable=False),
        sa.Column("title", sa.String(200)),
        sa.Column("content", sa.Text, nullable=False),
        sa.Column("platform", sa.String(16)),
        sa.Column("app_version", sa.String(16)),
        sa.Column("status", sa.String(16), server_default="pending"),
        sa.Column("admin_note", sa.Text),
        sa.Column("created_at", sa.TIMESTAMP, server_default=sa.text("NOW()")),
        sa.Column("updated_at", sa.TIMESTAMP, server_default=sa.text("NOW()")),
    )
    op.create_index("ix_user_feedback_user_id", "user_feedback", ["user_id"])

    # ─── coupons ───
    op.create_table(
        "coupons",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("code", sa.String(16), nullable=False, unique=True),
        sa.Column("user_id", sa.String(64), nullable=False),
        sa.Column("coupon_type", sa.String(32), nullable=False),
        sa.Column("value", sa.Float),
        sa.Column("is_redeemed", sa.Boolean, server_default="false"),
        sa.Column("redeemed_at", sa.TIMESTAMP),
        sa.Column("expires_at", sa.TIMESTAMP),
        sa.Column("issued_at", sa.TIMESTAMP, server_default=sa.text("NOW()")),
    )
    op.create_index("ix_coupons_code", "coupons", ["code"])
    op.create_index("ix_coupons_user_id", "coupons", ["user_id"])

    # ─── gift_orders ───
    op.create_table(
        "gift_orders",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("buyer_id", sa.String(64), nullable=False),
        sa.Column("recipient_id", sa.String(64)),
        sa.Column("product_id", sa.String(64), nullable=False),
        sa.Column("message", sa.Text),
        sa.Column("status", sa.String(16), server_default="pending"),
        sa.Column("created_at", sa.TIMESTAMP, server_default=sa.text("NOW()")),
        sa.Column("updated_at", sa.TIMESTAMP, server_default=sa.text("NOW()")),
    )
    op.create_index("ix_gift_orders_buyer_id", "gift_orders", ["buyer_id"])

    # ─── gift_cards ───
    op.create_table(
        "gift_cards",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("code", sa.String(16), nullable=False, unique=True),
        sa.Column("buyer_id", sa.String(64), nullable=False),
        sa.Column("denomination", sa.Float, nullable=False),
        sa.Column("message", sa.Text),
        sa.Column("is_redeemed", sa.Boolean, server_default="false"),
        sa.Column("redeemed_by", sa.String(64)),
        sa.Column("redeemed_at", sa.TIMESTAMP),
        sa.Column("created_at", sa.TIMESTAMP, server_default=sa.text("NOW()")),
    )
    op.create_index("ix_gift_cards_code", "gift_cards", ["code"])

    # ─── live_class_bookings ───
    op.create_table(
        "live_class_bookings",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id", sa.String(64), nullable=False),
        sa.Column("class_id", sa.String(64), nullable=False),
        sa.Column("status", sa.String(16), server_default="booked"),
        sa.Column("booked_at", sa.TIMESTAMP, server_default=sa.text("NOW()")),
        sa.Column("attended_at", sa.TIMESTAMP),
    )
    op.create_index("ix_live_class_bookings_user_id", "live_class_bookings", ["user_id"])
    op.create_index("ix_live_class_bookings_class_id", "live_class_bookings", ["class_id"])


def downgrade() -> None:
    tables = [
        "live_class_bookings",
        "gift_cards",
        "gift_orders",
        "coupons",
        "user_feedback",
        "expert_questions",
        "community_comments",
        "community_posts",
        "smart_alarms",
        "dream_logs",
        "weight_goals",
        "weight_logs",
        "gratitude_entries",
        "calorie_goals",
        "meal_logs",
        "habit_checkins",
        "habits",
        "menstrual_settings",
        "menstrual_cycles",
        "water_goals",
        "water_logs",
    ]
    for table in tables:
        op.drop_table(table)
