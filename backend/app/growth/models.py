"""增长域的表，挂在 simple_models.Base 上，随 app.db.init_db 的 create_all 出现。

和产品问答知识库不是同一套表。审计表只允许插入。
"""

from __future__ import annotations

from sqlalchemy import Boolean, Float, Integer, String, Text, event
from sqlalchemy.orm import Mapped, mapped_column

from app.simple_models import Base, new_id, now_ts


class GrowthShare(Base):
    __tablename__ = "growth_share"

    share_id: Mapped[str] = mapped_column(String(64), primary_key=True)
    user_id: Mapped[str] = mapped_column(String(64), index=True)
    content_type: Mapped[str] = mapped_column(String(64), default="")
    content_id: Mapped[str] = mapped_column(String(128), default="")
    platform: Mapped[str] = mapped_column(String(32), default="")
    title: Mapped[str] = mapped_column(String(200), default="")
    text: Mapped[str] = mapped_column(Text, default="")
    hashtags_json: Mapped[str] = mapped_column(Text, default="[]")
    share_url: Mapped[str] = mapped_column(String(300), default="")
    image_url: Mapped[str] = mapped_column(String(300), default="")
    clicks: Mapped[int] = mapped_column(Integer, default=0)
    created_at: Mapped[str] = mapped_column(String(40), default="")


class GrowthReferral(Base):
    __tablename__ = "growth_referral"

    invite_code: Mapped[str] = mapped_column(String(32), primary_key=True)
    inviter_user_id: Mapped[str] = mapped_column(String(64), index=True)
    channel: Mapped[str] = mapped_column(String(32), default="")
    utm_source: Mapped[str] = mapped_column(String(64), default="")
    utm_medium: Mapped[str] = mapped_column(String(64), default="")
    utm_campaign: Mapped[str] = mapped_column(String(64), default="")
    content_id: Mapped[str] = mapped_column(String(128), default="")
    created_at: Mapped[int] = mapped_column(Integer, default=now_ts)


class GrowthEvent(Base):
    __tablename__ = "growth_event"

    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=new_id)
    event_type: Mapped[str] = mapped_column(String(40), index=True)
    user_id: Mapped[str] = mapped_column(String(64), default="", index=True)
    anonymous_id: Mapped[str] = mapped_column(String(64), default="")
    invite_code: Mapped[str] = mapped_column(String(32), default="", index=True)
    inviter_user_id: Mapped[str] = mapped_column(String(64), default="")
    utm_source: Mapped[str] = mapped_column(String(64), default="")
    utm_medium: Mapped[str] = mapped_column(String(64), default="")
    utm_campaign: Mapped[str] = mapped_column(String(64), default="")
    content_id: Mapped[str] = mapped_column(String(128), default="")
    amount_yuan: Mapped[float] = mapped_column(Float, default=0)
    created_at: Mapped[int] = mapped_column(Integer, default=now_ts, index=True)


class GrowthKbChunk(Base):
    __tablename__ = "growth_kb_chunk"

    chunk_id: Mapped[str] = mapped_column(String(80), primary_key=True)
    source_id: Mapped[str] = mapped_column(String(64), index=True)
    text: Mapped[str] = mapped_column(Text, default="")
    embedding_json: Mapped[str] = mapped_column(Text, default="[]")
    license: Mapped[str] = mapped_column(String(64), default="")
    published_at: Mapped[str] = mapped_column(String(20), default="")
    fetched_at: Mapped[str] = mapped_column(String(20), default="")
    expires_at: Mapped[str] = mapped_column(String(20), default="")
    tier: Mapped[str] = mapped_column(String(32), default="")
    status: Mapped[str] = mapped_column(String(20), default="candidate", index=True)
    url: Mapped[str] = mapped_column(String(300), default="")


class GrowthAuditLog(Base):
    """只追加。更新和删除在 flush 时直接拒绝。"""

    __tablename__ = "growth_audit_log"

    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=new_id)
    created_at: Mapped[int] = mapped_column(Integer, default=now_ts, index=True)
    actor: Mapped[str] = mapped_column(String(64), default="system")
    action: Mapped[str] = mapped_column(String(64), default="")
    object_key: Mapped[str] = mapped_column(String(120), default="")
    version: Mapped[str] = mapped_column(String(32), default="")
    decision: Mapped[str] = mapped_column(String(32), default="no_change")
    detail_json: Mapped[str] = mapped_column(Text, default="{}")


class GrowthActive(Base):
    __tablename__ = "growth_active"

    object_key: Mapped[str] = mapped_column(String(120), primary_key=True)
    version: Mapped[str] = mapped_column(String(32), default="")
    previous_version: Mapped[str] = mapped_column(String(32), default="")
    updated_at: Mapped[int] = mapped_column(Integer, default=now_ts)


class GrowthProposal(Base):
    __tablename__ = "growth_proposal"

    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=new_id)
    kind: Mapped[str] = mapped_column(String(16), default="skill")
    skill_name: Mapped[str] = mapped_column(String(64), default="")
    object_key: Mapped[str] = mapped_column(String(120), default="", index=True)
    from_version: Mapped[str] = mapped_column(String(32), default="")
    to_version: Mapped[str] = mapped_column(String(32), default="")
    change_level: Mapped[str] = mapped_column(String(16), default="patch")
    channel: Mapped[str] = mapped_column(String(32), default="")
    status: Mapped[str] = mapped_column(String(32), default="proposed", index=True)
    detail_json: Mapped[str] = mapped_column(Text, default="{}")
    created_at: Mapped[int] = mapped_column(Integer, default=now_ts)


class GrowthApproval(Base):
    """运营中枢写下的已批准内容。发布时按 content_sha256 再核一次。"""

    __tablename__ = "growth_approval"

    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=new_id)
    channel: Mapped[str] = mapped_column(String(32), default="", index=True)
    title: Mapped[str] = mapped_column(String(200), default="")
    body: Mapped[str] = mapped_column(Text, default="")
    content_sha256: Mapped[str] = mapped_column(String(64), default="", index=True)
    status: Mapped[str] = mapped_column(String(32), default="approved", index=True)
    created_at: Mapped[int] = mapped_column(Integer, default=now_ts)


class GrowthInAppCard(Base):
    __tablename__ = "growth_in_app_card"

    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=new_id)
    user_id: Mapped[str] = mapped_column(String(64), index=True)
    title: Mapped[str] = mapped_column(String(200), default="")
    body: Mapped[str] = mapped_column(Text, default="")
    content_sha256: Mapped[str] = mapped_column(String(64), default="", index=True)
    created_at: Mapped[int] = mapped_column(Integer, default=now_ts)


class GrowthPushDelivery(Base):
    __tablename__ = "growth_push_delivery"

    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=new_id)
    user_id: Mapped[str] = mapped_column(String(64), index=True)
    title: Mapped[str] = mapped_column(String(200), default="")
    body: Mapped[str] = mapped_column(Text, default="")
    content_sha256: Mapped[str] = mapped_column(String(64), default="", index=True)
    status: Mapped[str] = mapped_column(String(32), default="recorded")
    created_at: Mapped[int] = mapped_column(Integer, default=now_ts)


class GrowthDraft(Base):
    __tablename__ = "growth_draft"

    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=new_id)
    platform: Mapped[str] = mapped_column(String(32), default="", index=True)
    title: Mapped[str] = mapped_column(String(200), default="")
    body: Mapped[str] = mapped_column(Text, default="")
    status: Mapped[str] = mapped_column(String(32), default="pending_human", index=True)
    aigc_labeled: Mapped[bool] = mapped_column(Boolean, default=False)
    external_posted: Mapped[bool] = mapped_column(Boolean, default=False)
    citations_json: Mapped[str] = mapped_column(Text, default="[]")
    created_at: Mapped[int] = mapped_column(Integer, default=now_ts)


@event.listens_for(GrowthAuditLog, "before_update")
def _refuse_audit_update(mapper, connection, target) -> None:  # noqa: ARG001
    raise RuntimeError("growth_audit_log is append-only")


@event.listens_for(GrowthAuditLog, "before_delete")
def _refuse_audit_delete(mapper, connection, target) -> None:  # noqa: ARG001
    raise RuntimeError("growth_audit_log is append-only")
