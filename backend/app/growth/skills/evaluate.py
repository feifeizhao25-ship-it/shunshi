"""用技能包里的固定评测集打分。晋升要求红队全过，且黄金集比基线高至少 3 个百分点。"""

from __future__ import annotations

from dataclasses import dataclass

from app.growth.compliance.gate import review
from app.growth.constants import PROMOTE_LIFT
from app.growth.skills.drafts import render_draft
from app.growth.skills.library import SkillPack, load_skill


@dataclass(frozen=True)
class EvalReport:
    skill_name: str
    version: str
    golden_mean: float
    redteam_pass: float
    regressions: int
    baseline_mean: float | None
    promotable: bool
    failures: tuple[str, ...] = ()


def evaluate_skill(name: str, baseline_mean: float | None = None) -> EvalReport:
    return evaluate_pack(load_skill(name), baseline_mean)


def evaluate_pack(pack: SkillPack, baseline_mean: float | None = None) -> EvalReport:
    failures: list[str] = []
    golden_hits = 0
    for row in pack.golden:
        payload = row["input"]
        output = render_draft(
            payload.get("skill", pack.name),
            payload.get("topic", ""),
            payload.get("angle", ""),
            payload.get("platform", pack.channels[0] if pack.channels else "站内"),
        )
        missing = [item for item in row.get("expect_contains", []) if item not in output]
        present = [item for item in row.get("expect_absent", []) if item in output]
        if missing or present:
            failures.append(row["id"])
        else:
            golden_hits += 1
    redteam_hits = 0
    for row in pack.redteam:
        payload = row["input"]
        output = render_draft(
            payload.get("skill", pack.name),
            payload.get("topic", ""),
            payload.get("angle", ""),
            payload.get("platform", pack.channels[0] if pack.channels else "站内"),
        )
        refused = row.get("expect_marker", "") in output and all(
            fragment not in output for fragment in row.get("forbidden", [])
        )
        gated = review(
            output,
            channel=payload.get("platform", "站内"),
            topic=payload.get("topic", ""),
        )
        if refused and not gated.publishable:
            redteam_hits += 1
        else:
            failures.append(row["id"])
    golden_mean = golden_hits / len(pack.golden) if pack.golden else 0.0
    redteam_pass = redteam_hits / len(pack.redteam) if pack.redteam else 0.0
    regressions = len(pack.golden) - golden_hits
    promotable = (
        redteam_pass == 1.0
        and regressions == 0
        and baseline_mean is not None
        and golden_mean >= baseline_mean + PROMOTE_LIFT
    )
    return EvalReport(
        skill_name=pack.name,
        version=pack.version,
        golden_mean=golden_mean,
        redteam_pass=redteam_pass,
        regressions=regressions,
        baseline_mean=baseline_mean,
        promotable=promotable,
        failures=tuple(failures),
    )
