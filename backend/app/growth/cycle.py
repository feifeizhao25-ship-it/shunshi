"""自改进循环。门没过、评测没抬升、或是站外渠道时，默认不改线上版本。

给 OpenClaw 的 cron 用，本模块不安装定时任务，也不向平台发稿：

- 每天 07:40（Asia/Shanghai）：``python -m app.growth.cycle``
- 每周日 09:20（Asia/Shanghai）：``python -m app.growth.cycle --weekly``
"""

from __future__ import annotations

import argparse
import json
from dataclasses import dataclass, field

from sqlalchemy.orm import Session

from app.growth.audit import append_audit
from app.growth.compliance.gate import review, violation_codes
from app.growth.config import GrowthConfig
from app.growth.constants import (
    CRON_DAILY,
    CRON_TIMEZONE,
    CRON_WEEKLY,
    HUMAN_CHANNELS,
    MAX_PROPOSALS,
    OWN_CHANNELS,
)
from app.growth.experiments.bandit import assign_bucket, judge_outcome
from app.growth.kb.ingest import IngestRefused, ingest_text
from app.growth.models import GrowthActive, GrowthDraft, GrowthProposal
from app.growth.skills.drafts import render_draft, title_variants
from app.growth.skills.evaluate import EvalReport, evaluate_skill
from app.simple_models import now_ts


@dataclass
class ProposalInput:
    kind: str = "skill"
    skill_name: str = ""
    to_version: str = ""
    change_level: str = "patch"
    channel: str = "站内"
    topic: str = "立春"
    angle: str = "早睡"
    sample: str = ""
    source_id: str = ""
    source_text: str = ""
    license: str = ""
    tier: str = "papers"
    published_at: str = "2026-01-01"


@dataclass
class CycleResult:
    decision: str
    queued_draft_ids: list[str] = field(default_factory=list)
    audit_ids: list[str] = field(default_factory=list)
    considered: int = 0
    dropped: int = 0


def run_cycle(
    session: Session,
    config: GrowthConfig,
    proposals: list[ProposalInput] | None = None,
    *,
    eval_override: EvalReport | None = None,
) -> CycleResult:
    """读入已有漏斗事件，再逐条处理提案。没有任何提案时决策是 no_change。"""
    from app.growth.funnel import summarize

    metrics = summarize(session, config.arpu_yuan)
    metrics_audit = append_audit(
        session,
        action="ingest_metrics",
        decision="no_change",
        detail={
            "counts": metrics["counts"],
            "control_slots": 1500,
            "allow_publish": config.allow_publish,
            "external_post": "disabled",
        },
    )
    result = CycleResult(decision="no_change", audit_ids=[metrics_audit.id])
    incoming = list(proposals or [])
    result.dropped = max(0, len(incoming) - MAX_PROPOSALS)
    if result.dropped:
        dropped = append_audit(
            session,
            action="drop_proposal",
            decision="no_change",
            detail={"dropped": result.dropped, "kept": MAX_PROPOSALS},
        )
        result.audit_ids.append(dropped.id)
    for proposal in incoming[:MAX_PROPOSALS]:
        result.considered += 1
        decision, draft_id, audit_id = _one(session, config, proposal, eval_override)
        if audit_id:
            result.audit_ids.append(audit_id)
        if draft_id:
            result.queued_draft_ids.append(draft_id)
        if decision == "canary":
            result.decision = "canary"
        elif decision == "queued" and result.decision == "no_change":
            result.decision = "queued"
    return result


def _one(
    session: Session,
    config: GrowthConfig,
    proposal: ProposalInput,
    eval_override: EvalReport | None,
) -> tuple[str, str, str]:
    if proposal.kind == "rag":
        return _rag(session, proposal)
    if proposal.channel == "付费投放" and not config.allow_paid_ads:
        row = append_audit(
            session,
            action="reject_paid_ads",
            decision="no_change",
            object_key=proposal.skill_name,
            detail={"reason": "paid_ads_disabled"},
        )
        return "no_change", "", row.id
    sample = proposal.sample or render_draft(
        proposal.skill_name, proposal.topic, proposal.angle, proposal.channel
    )
    gated = review(sample, channel=proposal.channel, topic=proposal.topic)
    object_key = f"skill:{proposal.skill_name}"
    if not gated.publishable:
        row = append_audit(
            session,
            action="gate",
            decision="no_change",
            object_key=object_key,
            detail={"reasons": gated.reasons},
        )
        return "no_change", "", row.id
    if proposal.change_level == "major":
        row = append_audit(
            session,
            action="hold_major",
            decision="no_change",
            object_key=object_key,
            version=proposal.to_version,
            detail={"reason": "major_needs_human"},
        )
        return "no_change", "", row.id
    if proposal.channel in HUMAN_CHANNELS:
        draft = _queue(session, proposal, sample)
        row = append_audit(
            session,
            action="queue_draft",
            decision="queued",
            object_key=object_key,
            version=proposal.to_version,
            detail={"draft_id": draft.id, "external_posted": False},
        )
        return "queued", draft.id, row.id
    if proposal.channel not in OWN_CHANNELS:
        row = append_audit(
            session,
            action="gate",
            decision="no_change",
            object_key=object_key,
            detail={"reasons": ["unknown_channel"]},
        )
        return "no_change", "", row.id
    report = eval_override or evaluate_skill(proposal.skill_name, baseline_mean=None)
    if not report.promotable:
        row = append_audit(
            session,
            action="evaluate",
            decision="no_change",
            object_key=object_key,
            version=proposal.to_version,
            detail={
                "reason": "eval_not_promotable",
                "golden_mean": report.golden_mean,
                "redteam_pass": report.redteam_pass,
            },
        )
        return "no_change", "", row.id
    active = session.get(GrowthActive, object_key)
    if active is None or not proposal.to_version:
        row = append_audit(
            session,
            action="evaluate",
            decision="no_change",
            object_key=object_key,
            detail={"reason": "no_baseline"},
        )
        return "no_change", "", row.id
    previous = active.version
    active.previous_version = previous
    active.version = proposal.to_version
    active.updated_at = now_ts()
    stored = GrowthProposal(
        kind="skill",
        skill_name=proposal.skill_name,
        object_key=object_key,
        from_version=previous,
        to_version=proposal.to_version,
        change_level=proposal.change_level,
        channel=proposal.channel,
        status="canary",
        detail_json=json.dumps({"auto_post": False}, ensure_ascii=False),
    )
    session.add(stored)
    session.flush()
    row = append_audit(
        session,
        action="start_canary",
        decision="canary",
        object_key=object_key,
        version=proposal.to_version,
        detail={"previous": previous, "control_rate": 0.15, "allow_publish": config.allow_publish},
    )
    return "canary", "", row.id


def _queue(session: Session, proposal: ProposalInput, sample: str) -> GrowthDraft:
    title = title_variants(proposal.topic)[0] if proposal.topic else proposal.skill_name
    if violation_codes(title):
        title = proposal.skill_name or "草稿"
    draft = GrowthDraft(
        platform=proposal.channel,
        title=title,
        body=sample,
        status="pending_human",
        aigc_labeled="本内容由人工智能生成。" in sample,
        external_posted=False,
        citations_json=json.dumps(["A01#c1"], ensure_ascii=False),
    )
    session.add(draft)
    session.flush()
    return draft


def _rag(session: Session, proposal: ProposalInput) -> tuple[str, str, str]:
    try:
        ingest_text(
            session,
            source_id=proposal.source_id or "candidate",
            text=proposal.source_text,
            license=proposal.license or "unknown",
            tier=proposal.tier,
            url="",
            published_at=proposal.published_at,
            status="candidate",
        )
    except (IngestRefused, ValueError):
        row = append_audit(
            session,
            action="rag_ingest",
            decision="no_change",
            object_key=proposal.source_id,
            detail={"reason": "refused"},
        )
        return "no_change", "", row.id
    row = append_audit(
        session,
        action="rag_ingest",
        decision="no_change",
        object_key=proposal.source_id,
        detail={"reason": "candidate_until_human_review"},
    )
    return "no_change", "", row.id


def version_for(session: Session, object_key: str, unit_id: str, default: str = "0.1.0") -> str:
    row = session.get(GrowthActive, object_key)
    if row is None:
        return default
    if row.previous_version and assign_bucket(unit_id, object_key) == "control":
        return row.previous_version
    return row.version


def review_canary(
    session: Session,
    object_key: str,
    *,
    control_success: int,
    control_total: int,
    treatment_success: int,
    treatment_total: int,
    eval_ok: bool,
) -> str:
    decision = judge_outcome(
        control_success,
        control_total,
        treatment_success,
        treatment_total,
        eval_ok=eval_ok,
    )
    proposal = (
        session.query(GrowthProposal)
        .filter(GrowthProposal.object_key == object_key, GrowthProposal.status == "canary")
        .order_by(GrowthProposal.created_at.desc())
        .first()
    )
    if decision == "promote":
        if proposal is not None:
            proposal.status = "promoted"
        append_audit(
            session,
            action="promote",
            decision="promoted",
            object_key=object_key,
            version=proposal.to_version if proposal else "",
            detail={"control_rate": 0.15},
        )
        return "promoted"
    if decision == "rollback":
        outcome = rollback(session, object_key)
        if proposal is not None and outcome == "rolled_back":
            proposal.status = "rolled_back"
        return outcome
    append_audit(
        session,
        action="review_canary",
        decision="no_change",
        object_key=object_key,
        detail={"reason": "inconclusive"},
    )
    return "no_change"


def rollback(session: Session, object_key: str) -> str:
    row = session.get(GrowthActive, object_key)
    if row is None or not row.previous_version:
        append_audit(session, action="rollback", decision="no_change", object_key=object_key)
        return "no_change"
    restored = row.previous_version
    abandoned = row.version
    row.version = restored
    row.previous_version = ""
    row.updated_at = now_ts()
    append_audit(
        session,
        action="rollback",
        decision="rolled_back",
        object_key=object_key,
        version=restored,
        detail={"abandoned": abandoned},
    )
    return "rolled_back"


def confirm_draft(session: Session, draft_id: str) -> GrowthDraft:
    """人工确认只改队列状态。不调用 post_to_platform，external_posted 保持 False。"""
    row = session.get(GrowthDraft, draft_id)
    if row is None:
        raise KeyError(draft_id)
    row.status = "human_confirmed"
    row.external_posted = False
    append_audit(
        session,
        action="human_confirm",
        decision="queued",
        object_key=draft_id,
        detail={"external_posted": False},
    )
    return row


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="顺时增长循环")
    parser.add_argument("--weekly", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args(argv)
    schedule = CRON_WEEKLY if args.weekly else CRON_DAILY
    if args.dry_run:
        print(f"{schedule} {CRON_TIMEZONE}")
        print("no external post")
        return 0
    from app.config import Settings
    from app.db import init_db, make_engine, make_session_factory

    settings = Settings()
    config = GrowthConfig.from_settings(settings)
    engine = make_engine(settings.database_url)
    init_db(engine)
    session = make_session_factory(engine)()
    try:
        result = run_cycle(session, config, [])
        session.commit()
    except Exception:
        session.rollback()
        raise
    finally:
        session.close()
        engine.dispose()
    print(result.decision)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
