"""增长事件（落地页可匿名）和后台队列（只给管理员）。"""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.deps import get_session
from app.growth.config import GrowthConfig
from app.growth.cycle import ProposalInput, confirm_draft, rollback, run_cycle
from app.growth.audit import append_audit
from app.growth.events import record_event
from app.growth.kb.ingest import IngestRefused, activate_source
from app.growth.funnel import summarize
from app.growth.models import GrowthAuditLog, GrowthDraft

events_router = APIRouter(prefix="/api/v1/growth", tags=["growth"])
admin_router = APIRouter(prefix="/api/v1/admin/growth", tags=["growth-admin"])


class EventIn(BaseModel):
    event_type: str
    anonymous_id: str = ""
    user_id: str = ""
    invite_code: str = ""
    utm_source: str = ""
    utm_medium: str = ""
    utm_campaign: str = ""
    content_id: str = ""
    amount_yuan: float = 0


class CycleIn(BaseModel):
    proposals: list[dict] = Field(default_factory=list)


class RollbackIn(BaseModel):
    object_key: str


def _config(request: Request) -> GrowthConfig:
    return GrowthConfig.from_settings(request.app.state.settings)


@events_router.post("/events", summary="记录流量漏斗事件")
def post_event(
    body: EventIn,
    request: Request,
    session: Session = Depends(get_session),
):
    row = record_event(session, request, body.model_dump())
    return {
        "success": True,
        "data": {"id": row.id, "event_type": row.event_type, "inviter_user_id": row.inviter_user_id},
    }


@admin_router.get("/funnel", summary="流量到付费的漏斗")
def get_funnel(request: Request, session: Session = Depends(get_session)):
    config = _config(request)
    return {"success": True, "data": summarize(session, config.arpu_yuan)}


@admin_router.get("/queue", summary="待人工确认的草稿")
def get_queue(session: Session = Depends(get_session)):
    rows = (
        session.query(GrowthDraft)
        .order_by(GrowthDraft.created_at.desc())
        .limit(100)
        .all()
    )
    return {
        "success": True,
        "data": [
            {
                "id": row.id,
                "platform": row.platform,
                "title": row.title,
                "status": row.status,
                "aigc_labeled": row.aigc_labeled,
                "external_posted": row.external_posted,
            }
            for row in rows
        ],
    }


@admin_router.post("/queue/{draft_id}/confirm", summary="人工确认草稿")
def post_confirm(draft_id: str, session: Session = Depends(get_session)):
    try:
        row = confirm_draft(session, draft_id)
    except KeyError:
        raise HTTPException(status_code=404, detail="草稿不存在") from None
    return {
        "success": True,
        "data": {
            "id": row.id,
            "status": row.status,
            "external_posted": row.external_posted,
            "published": False,
        },
    }


@admin_router.post("/cycle", summary="跑一轮自改进")
def post_cycle(
    body: CycleIn,
    request: Request,
    session: Session = Depends(get_session),
):
    proposals = [_proposal(item) for item in body.proposals]
    result = run_cycle(session, _config(request), proposals)
    return {
        "success": True,
        "data": {
            "decision": result.decision,
            "considered": result.considered,
            "dropped": result.dropped,
            "queued_draft_ids": result.queued_draft_ids,
        },
    }


@admin_router.post("/sources/{source_id}/activate", summary="人审通过一条候选来源")
def post_activate(source_id: str, session: Session = Depends(get_session)):
    try:
        count = activate_source(session, source_id)
    except IngestRefused as exc:
        raise HTTPException(status_code=404, detail="没有可启用的来源") from exc
    append_audit(
        session,
        action="activate_source",
        decision="no_change",
        object_key=source_id,
        detail={"chunks": count},
    )
    return {"success": True, "data": {"source_id": source_id, "chunks": count}}


@admin_router.post("/rollback", summary="把线上版本退回上一版")
def post_rollback(body: RollbackIn, session: Session = Depends(get_session)):
    decision = rollback(session, body.object_key)
    return {"success": True, "data": {"decision": decision}}


@admin_router.get("/audit", summary="增长审计，只读")
def get_audit(session: Session = Depends(get_session)):
    rows = session.query(GrowthAuditLog).order_by(GrowthAuditLog.created_at.asc()).limit(200).all()
    return {
        "success": True,
        "data": [
            {
                "id": row.id,
                "action": row.action,
                "decision": row.decision,
                "object_key": row.object_key,
                "version": row.version,
            }
            for row in rows
        ],
    }


def _proposal(item: dict) -> ProposalInput:
    allowed = set(ProposalInput.__dataclass_fields__)
    return ProposalInput(**{key: value for key, value in item.items() if key in allowed})
