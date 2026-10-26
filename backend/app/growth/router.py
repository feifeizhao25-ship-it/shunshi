"""增长事件（落地页可匿名）和后台队列（只给管理员）。"""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.deps import current_user, get_session
from app.growth.config import GrowthConfig
from app.growth.cycle import ProposalInput, confirm_draft, rollback, run_cycle
from app.growth.audit import append_audit
from app.growth.events import record_event
from app.growth.kb.ingest import IngestRefused, activate_source
from app.growth.funnel import summarize
from app.growth.kb.sources import REGISTRY
from app.growth.models import GrowthAuditLog, GrowthDraft, GrowthInAppCard, GrowthKbChunk
from app.growth.ops import OpsRefused, publish, read_opt_in, record_approval, write_opt_in
from app.growth.skills.library import list_skills

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


class OptIn(BaseModel):
    in_app_cards: bool = False
    app_push: bool = False


class ApprovalIn(BaseModel):
    channel: str
    title: str = ""
    body: str = ""
    content_sha256: str


class PublishIn(BaseModel):
    channel: str
    title: str = ""
    body: str = ""
    content_sha256: str
    user_ids: list[str] = Field(default_factory=list)


def _config(request: Request) -> GrowthConfig:
    return GrowthConfig.from_settings(request.app.state.settings)


@events_router.get("/opt-in", summary="增长卡片和推送的订阅开关")
def get_opt_in(user_id: str = Depends(current_user), session: Session = Depends(get_session)):
    return {"success": True, "data": read_opt_in(session, user_id)}


@events_router.post("/opt-in", summary="打开或关闭增长卡片和推送")
def post_opt_in(
    body: OptIn,
    user_id: str = Depends(current_user),
    session: Session = Depends(get_session),
):
    saved = write_opt_in(
        session, user_id, in_app_cards=body.in_app_cards, app_push=body.app_push
    )
    return {"success": True, "data": saved}


@events_router.get("/cards", summary="已投放到本人的站内卡片")
def get_cards(user_id: str = Depends(current_user), session: Session = Depends(get_session)):
    rows = (
        session.query(GrowthInAppCard)
        .filter(GrowthInAppCard.user_id == user_id)
        .order_by(GrowthInAppCard.created_at.desc())
        .limit(50)
        .all()
    )
    return {
        "success": True,
        "data": [{"id": row.id, "title": row.title, "body": row.body} for row in rows],
    }


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


@admin_router.get("/skills", summary="流量技能和版本")
def get_skills():
    return {
        "success": True,
        "data": [
            {
                "name": pack.name,
                "version": pack.version,
                "description": pack.description,
                "channels": pack.channels,
                "golden_count": len(pack.golden),
                "redteam_count": len(pack.redteam),
            }
            for pack in list_skills()
        ],
    }


@admin_router.get("/sources", summary="增长知识库来源")
def get_sources(session: Session = Depends(get_session)):
    return {"success": True, "data": _source_rows(session)}


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


def _ops_call(action):
    try:
        return action()
    except OpsRefused as exc:
        raise HTTPException(status_code=exc.status_code, detail=exc.detail) from exc


@admin_router.post("/approvals", summary="记录运营中枢已经批准的内容")
def post_approval(body: ApprovalIn, session: Session = Depends(get_session)):
    row = _ops_call(
        lambda: record_approval(
            session,
            channel=body.channel,
            title=body.title,
            body=body.body,
            content_sha256_hex=body.content_sha256,
        )
    )
    return {"success": True, "data": {"id": row.id, "content_sha256": row.content_sha256}}


@admin_router.post("/publish", summary="按审批哈希投放站内卡片或推送")
def post_publish(body: PublishIn, request: Request, session: Session = Depends(get_session)):
    result = _ops_call(
        lambda: publish(
            session,
            _config(request),
            channel=body.channel,
            title=body.title,
            body=body.body,
            content_sha256_hex=body.content_sha256,
            user_ids=body.user_ids,
        )
    )
    return {"success": True, "data": result}


@admin_router.get("/metrics", summary="增长指标，给运营中枢只读")
def get_metrics(request: Request, session: Session = Depends(get_session)):
    config = _config(request)
    funnel = summarize(session, config.arpu_yuan)
    from app.growth.models import GrowthPushDelivery

    return {
        "success": True,
        "data": {
            "funnel": funnel,
            "in_app_cards": session.query(GrowthInAppCard).count(),
            "app_pushes": session.query(GrowthPushDelivery).count(),
            "switches": {
                "allow_publish": config.allow_publish,
                "allow_paid_ads": config.allow_paid_ads,
                "allow_in_app_cards": config.allow_in_app_cards,
                "allow_app_push": config.allow_app_push,
                "kill_switch": config.kill_switch,
            },
        },
    }


def _source_rows(session: Session) -> list[dict]:
    grouped: dict[str, set[str]] = {}
    for source_id, status in session.query(GrowthKbChunk.source_id, GrowthKbChunk.status):
        grouped.setdefault(source_id, set()).add(status)
    rows = []
    seen: set[str] = set()
    for record in REGISTRY:
        seen.add(record.source_id)
        rows.append(
            {
                "source_id": record.source_id,
                "title": record.title,
                "license": record.license,
                "tier": record.tier,
                "published_at": record.published_at,
                "status": _source_status(grouped.get(record.source_id, set())),
            }
        )
    for source_id in sorted(set(grouped) - seen):
        rows.append(
            {
                "source_id": source_id,
                "title": "",
                "license": "",
                "tier": "",
                "published_at": "",
                "status": _source_status(grouped[source_id]),
            }
        )
    return rows


def _source_status(statuses: set[str]) -> str:
    if not statuses:
        return "registered"
    if "active" in statuses:
        return "active"
    if "candidate" in statuses:
        return "candidate"
    if "archived" in statuses:
        return "archived"
    return sorted(statuses)[0]


def _proposal(item: dict) -> ProposalInput:
    allowed = set(ProposalInput.__dataclass_fields__)
    return ProposalInput(**{key: value for key, value in item.items() if key in allowed})
