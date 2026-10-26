import json
import subprocess
import sys
from pathlib import Path

import pytest

from app.growth.config import GrowthConfig
from app.growth.cycle import ProposalInput, confirm_draft, review_canary, run_cycle, version_for
from app.growth.models import GrowthActive, GrowthAuditLog, GrowthDraft, GrowthKbChunk
from app.growth.publish import ExternalPublishBlocked, post_to_platform
from app.growth.skills.evaluate import EvalReport


def _promotable() -> EvalReport:
    return EvalReport(
        skill_name="xhs-note",
        version="0.1.1",
        golden_mean=1.0,
        redteam_pass=1.0,
        regressions=0,
        baseline_mean=0.9,
        promotable=True,
    )


def test_empty_cycle_makes_no_change_and_audit_is_append_only(growth_session):
    result = run_cycle(growth_session, GrowthConfig())
    assert result.decision == "no_change"
    row = growth_session.query(GrowthAuditLog).one()
    row.action = "tamper"
    with pytest.raises(RuntimeError, match="append-only"):
        growth_session.commit()
    growth_session.rollback()


def test_failed_gate_does_not_change_the_active_version(growth_session):
    growth_session.add(GrowthActive(object_key="skill:xhs-note", version="0.1.0", previous_version=""))
    growth_session.flush()
    result = run_cycle(
        growth_session,
        GrowthConfig(allow_publish=True),
        [ProposalInput(skill_name="xhs-note", channel="小程序", sample="这个方子可长期服用")],
        eval_override=_promotable(),
    )
    assert result.decision == "no_change"
    assert growth_session.get(GrowthActive, "skill:xhs-note").version == "0.1.0"
    assert growth_session.query(GrowthDraft).count() == 0


def test_human_channel_is_queued_and_confirm_never_posts(growth_session):
    result = run_cycle(
        growth_session,
        GrowthConfig(allow_publish=True),
        [ProposalInput(skill_name="xhs-note", channel="小红书", topic="立春", angle="早睡")],
    )
    assert result.decision == "queued"
    draft = growth_session.get(GrowthDraft, result.queued_draft_ids[0])
    assert draft.status == "pending_human"
    assert draft.aigc_labeled is True
    assert draft.external_posted is False
    confirm_draft(growth_session, draft.id)
    assert draft.status == "human_confirmed"
    assert draft.external_posted is False
    with pytest.raises(ExternalPublishBlocked):
        post_to_platform("小红书", draft.body)


def test_canary_keeps_fifteen_percent_then_promotes_or_rolls_back(growth_session):
    growth_session.add(GrowthActive(object_key="skill:xhs-note", version="0.1.0", previous_version=""))
    growth_session.flush()
    result = run_cycle(
        growth_session,
        GrowthConfig(),
        [
            ProposalInput(
                skill_name="xhs-note",
                channel="小程序",
                to_version="0.2.0",
                change_level="minor",
                topic="立春",
                angle="早睡",
            )
        ],
        eval_override=_promotable(),
    )
    assert result.decision == "canary"
    control = next(f"user-{i}" for i in range(500) if version_for(growth_session, "skill:xhs-note", f"user-{i}") == "0.1.0")
    treatment = next(f"user-{i}" for i in range(500) if version_for(growth_session, "skill:xhs-note", f"user-{i}") == "0.2.0")
    assert control != treatment
    assert review_canary(
        growth_session,
        "skill:xhs-note",
        control_success=10,
        control_total=200,
        treatment_success=80,
        treatment_total=200,
        eval_ok=True,
    ) == "promoted"
    assert version_for(growth_session, "skill:xhs-note", control) == "0.1.0"
    assert version_for(growth_session, "skill:xhs-note", treatment) == "0.2.0"
    assert review_canary(
        growth_session,
        "skill:xhs-note",
        control_success=80,
        control_total=200,
        treatment_success=10,
        treatment_total=200,
        eval_ok=False,
    ) == "rolled_back"
    assert version_for(growth_session, "skill:xhs-note", treatment) == "0.1.0"


def test_major_change_and_extra_proposals_do_not_promote(growth_session):
    growth_session.add(GrowthActive(object_key="skill:topic-selection", version="0.1.0"))
    growth_session.flush()
    proposals = [
        ProposalInput(skill_name="topic-selection", channel="小红书", topic="立春", change_level="major", to_version="1.0.0"),
        ProposalInput(skill_name="topic-selection", channel="公众号", topic="雨水"),
        ProposalInput(skill_name="topic-selection", channel="知乎", topic="惊蛰"),
        ProposalInput(skill_name="topic-selection", channel="视频号", topic="春分"),
    ]
    result = run_cycle(growth_session, GrowthConfig(), proposals, eval_override=_promotable())
    assert result.dropped == 1
    assert result.considered == 3
    assert growth_session.get(GrowthActive, "skill:topic-selection").version == "0.1.0"
    assert result.decision == "queued"


def test_new_rag_source_stays_candidate(growth_session):
    result = run_cycle(
        growth_session,
        GrowthConfig(),
        [
            ProposalInput(
                kind="rag",
                source_id="B11",
                source_text="补充一条作息备忘：晚上提前安静下来。",
                license="internal-summary",
                tier="papers",
                published_at="2026-02-01",
            )
        ],
    )
    assert result.decision == "no_change"
    row = growth_session.get(GrowthKbChunk, "B11#c1")
    assert row.status == "candidate"
    refused = run_cycle(
        growth_session,
        GrowthConfig(),
        [ProposalInput(kind="rag", source_id="B12", source_text="可长期服用", license="internal-summary")],
    )
    assert refused.decision == "no_change"
    assert growth_session.get(GrowthKbChunk, "B12#c1") is None
    reasons = [
        json.loads(row.detail_json).get("reason")
        for row in growth_session.query(GrowthAuditLog).filter(GrowthAuditLog.action == "rag_ingest")
    ]
    assert "refused" in reasons


def test_dry_run_does_not_open_a_database():
    backend = Path(__file__).resolve().parents[2]
    completed = subprocess.run(
        [sys.executable, "-m", "app.growth.cycle", "--dry-run"],
        cwd=backend,
        capture_output=True,
        text=True,
        check=False,
    )
    assert completed.returncode == 0, completed.stderr
    assert "40 7 * * * Asia/Shanghai" in completed.stdout
    assert "no external post" in completed.stdout
    assert "[DB]" not in completed.stdout


def test_paid_ads_stay_off(growth_session):
    result = run_cycle(
        growth_session,
        GrowthConfig(allow_paid_ads=False),
        [ProposalInput(skill_name="xhs-note", channel="付费投放", topic="立春")],
    )
    assert result.decision == "no_change"
