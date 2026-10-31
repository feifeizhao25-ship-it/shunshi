"""每周自改进闭环（采集 → 清洗 → 隔离 → 提案 → 评测 → 合规 → 审批 → 晋升 → 回滚）。

所有外部能力（采集、提案、评测、应用）都由各产品通过 ``Hooks`` 注入；本模块不联网、不调用模型，
所以可以完整单测。默认关闭（SIL_ENABLED=0）；用户可见改动必须经企业微信批准，超时即作废。
"""

from __future__ import annotations

import json
from dataclasses import dataclass, field, asdict
from datetime import date, datetime
from pathlib import Path
from typing import Callable, Iterable, Mapping, Sequence

from . import compliance as comp
from .approval import ApprovalPolicy, Gateway, NullGateway, build_card, is_timed_out
from .config import SILConfig
from .freshness import retirement_scan
from .gates import GateResult, check_set_separation, edit_budget, evaluate_gates
from .sources import SourcePolicy, lint_source, scan_injection
from .store import Candidate, CandidateStore, IllegalTransition
from .utility import UtilityLedger


@dataclass
class EvalOutcome:
    baseline: Mapping[str, float]
    candidate: Mapping[str, float]
    no_skill: Mapping[str, float] | None = None
    standard_errors: Mapping[str, float] = field(default_factory=dict)


@dataclass
class Hooks:
    collect: Callable[[], Iterable[Mapping]]
    propose: Callable[[list[Mapping], int], list[Candidate]]
    evaluate: Callable[[Candidate], EvalOutcome]
    apply: Callable[[Candidate], dict]  # 晋升；返回回滚快照
    rollback: Callable[[Candidate], None]
    entries: Callable[[], Iterable[Mapping]] | None = None
    hits_90d: Callable[[], Mapping[str, int]] | None = None
    gate_sets: Callable[[], tuple[list, list, list]] | None = None  # (优化集, 门禁集, held-out)


@dataclass
class CycleReport:
    status: str = "ok"  # ok | disabled | aborted
    started_at: str = ""
    budget: int = 0
    sources_seen: int = 0
    sources_rejected: list = field(default_factory=list)
    proposed: list = field(default_factory=list)
    rejected: list = field(default_factory=list)  # [(id, reasons)]
    pending_approval: list = field(default_factory=list)
    promoted: list = field(default_factory=list)
    expired: list = field(default_factory=list)
    blocked: list = field(default_factory=list)  # [(id, reason)] 如缺专家签字
    warnings: list = field(default_factory=list)
    problems: list = field(default_factory=list)
    metrics: dict = field(default_factory=dict)  # 可观测：各类拒绝原因计数、账本规模等（不含任何用户数据）


def _parse(now) -> datetime:
    return now if isinstance(now, datetime) else datetime.fromisoformat(str(now))


class SelfImprovementLoop:
    def __init__(
        self,
        cfg: SILConfig,
        hooks: Hooks,
        *,
        source_policy: SourcePolicy | None = None,
        approval: ApprovalPolicy | None = None,
        gateway: Gateway | None = None,
        store: CandidateStore | None = None,
        extra_literals: Sequence[str] = (),
        extra_patterns: Mapping[str, Iterable[str]] | None = None,
    ):
        self.cfg, self.hooks = cfg, hooks
        self.source_policy = source_policy or SourcePolicy(allowed_domains=cfg.allowed_domains)
        self.approval = approval or ApprovalPolicy.from_env()
        self.gateway = gateway or NullGateway()
        self.store = store or CandidateStore(cfg.data_dir)
        self.extra_literals, self.extra_patterns = extra_literals, extra_patterns
        self._hist_path = Path(cfg.data_dir) / "weekly_history.json"
        self.utility = UtilityLedger(cfg.data_dir)

    # ---------- 工具 ----------
    def _history(self) -> list:
        return json.loads(self._hist_path.read_text("utf-8")) if self._hist_path.exists() else []

    def _save_history(self, h: list) -> None:
        self._hist_path.parent.mkdir(parents=True, exist_ok=True)
        self._hist_path.write_text(json.dumps(h[-26:], ensure_ascii=False), "utf-8")

    def _write_report(self, rep: CycleReport, now: datetime, kind: str) -> None:
        d = Path(self.cfg.data_dir) / "reports"
        d.mkdir(parents=True, exist_ok=True)
        (d / f"{kind}-{now.date().isoformat()}.json").write_text(json.dumps(asdict(rep), ensure_ascii=False, indent=2), "utf-8")

    def _compliance(self, c: Candidate) -> comp.ComplianceResult:
        text = " ".join(str(x) for x in (c.summary, c.payload.get("text", ""), c.payload.get("answer", "")))
        return comp.check(text, self.cfg.families, self.extra_literals, self.extra_patterns)

    # ---------- 每周 ----------
    def run_weekly(self, now) -> CycleReport:
        now = _parse(now)
        self.store.set_clock(lambda: now.isoformat(timespec="seconds"))
        rep = CycleReport(started_at=now.isoformat(timespec="seconds"))
        if not self.cfg.enabled:
            rep.status = "disabled"
            return rep
        if self.hooks.gate_sets:
            opt, gate, held = self.hooks.gate_sets()
            rep.problems = check_set_separation(opt, gate, held)
            if rep.problems:
                rep.status = "aborted"  # 评测集污染时不得继续「改进」
                self._write_report(rep, now, "weekly")
                return rep
        self._expire(now, rep)
        self._promote_approved(rep)

        hist = self._history()
        rep.budget = min(self.cfg.max_proposals_per_week, edit_budget(hist))
        clean: list[Mapping] = []
        for rec in self.hooks.collect():
            rep.sources_seen += 1
            lint = lint_source(rec, self.source_policy)
            if not lint.ok or lint.injection_flags:
                rep.sources_rejected.append({"id": rec.get("id"), "why": lint.violations + [f"injection:{len(lint.injection_flags)}"] if lint.injection_flags else lint.violations})
                self.store.ledger.append({"t": rep.started_at, "source_rejected": rec.get("id"), "why": lint.violations, "injection": len(lint.injection_flags)})
                continue
            clean.append(rec)

        for c in self.hooks.propose(clean, rep.budget)[: rep.budget]:
            c.origin = c.origin if c.origin in ("external", "internal") else "generated"
            c = self.store.add(c)
            if c.state != "quarantined":  # 已处理过的同 id 提案不重复处理
                continue
            rep.proposed.append(c.id)
            self._evaluate_one(c, rep)

        rep.metrics = self._metrics(rep)
        net = len(rep.promoted)  # 本周净收益；回滚会在 monitor 里扣减
        self._save_history(hist + [{"week": now.date().isoformat(), "net_gain": net}])
        self._write_report(rep, now, "weekly")
        return rep

    def _self_cited(self, c: Candidate) -> bool:
        own = str(Path(self.cfg.data_dir).as_posix()).rstrip("/")
        for ev in c.evidence or []:
            url = str((ev or {}).get("url", ""))
            if url.startswith("file://") or (own and own in url) or "var/self_improve" in url:
                return True
        return False

    def retire(self, name: str, reason: str, today=None) -> None:
        """把名字放进退役名单（调用方应已完成审批）。写入哈希链日志。"""
        day = _parse(today).date().isoformat() if today is not None else None
        self.utility.bury(name, reason, day)
        self.store.ledger.append({"t": day or "", "retired": name, "reason": reason})

    def unretire(self, name: str, reviewer: str) -> bool:
        """名单内的名字只有审批人名单内的人才能移出；名单为空时无人可移出。"""
        ok = self.utility.unbury(name, reviewer, self.approval.can_approve)
        if ok:
            self.store.ledger.append({"t": "", "unretired": name, "reviewer": reviewer})
        return ok

    def _metrics(self, rep: CycleReport) -> dict:
        by_reason: dict[str, int] = {}
        for _id, reasons in rep.rejected:
            for r in reasons:
                key = str(r).split(":")[0]
                by_reason[key] = by_reason.get(key, 0) + 1
        return {
            "sources_seen": rep.sources_seen,
            "sources_rejected": len(rep.sources_rejected),
            "proposed": len(rep.proposed),
            "rejected": len(rep.rejected),
            "rejected_by_reason": by_reason,
            "pending_approval": len(rep.pending_approval),
            "promoted": len(rep.promoted),
            "expired": len(rep.expired),
            "blocked": len(rep.blocked),
            "graveyard_size": len(self.utility.graveyard()),
        }

    def _evaluate_one(self, c: Candidate, rep: CycleReport) -> None:
        reasons: list[str] = []
        if c.origin == "generated":
            reasons.append("origin_generated_forbidden")
        res = self._compliance(c)
        if not res.ok:
            reasons += [f"compliance:{f}" for f in res.families]
        if scan_injection(" ".join([c.summary, str(c.payload.get("text", ""))])):
            reasons.append("injection_suspected")
        if self.utility.is_buried(c.target):
            reasons.append("graveyard")  # 名字级退役名单：不得同名复活，需有权限的审批人手动移出
        if self._self_cited(c):
            reasons.append("self_citation")  # 证据不能来自本系统自己的输出（防自我投毒）
        if reasons:
            self.store.transition(c.id, "rejected", reasons=reasons)
            rep.rejected.append((c.id, reasons))
            return
        out = self.hooks.evaluate(c)
        gate: GateResult = evaluate_gates(
            out.baseline, out.candidate, self.cfg.thresholds, standard_errors=out.standard_errors, no_skill=out.no_skill
        )
        self.store.transition(c.id, "evaluated", gates={"passed": gate.passed, "reasons": gate.reasons, "checked": gate.checked})
        if not gate.passed:
            self.store.transition(c.id, "rejected", reasons=gate.reasons)
            rep.rejected.append((c.id, gate.reasons))
            return
        needs_human = c.user_visible or c.needs_expert or not self.cfg.auto_promote_internal
        if needs_human:
            self.store.transition(c.id, "pending_approval")
            rep.pending_approval.append(c.id)
            to = sorted(self.approval.reviewers)
            if not to:
                rep.warnings.append(f"no_reviewers_configured:{c.id}")  # TODO(owner): 填写 POLICY_REVIEWERS
            else:
                try:
                    self.gateway.send(build_card(c, {"gates": {"passed": True}}), to)
                except Exception as e:  # 发不出去也不能晋升
                    rep.warnings.append(f"approval_send_failed:{c.id}:{type(e).__name__}")
        else:
            self.store.transition(c.id, "auto_ready")
            self._promote(c.id, rep)

    # ---------- 审批 ----------
    def record_decision(self, cid: str, reviewer: str, approve: bool, now=None) -> Candidate:
        """企业微信回调调用。非名单内审批人（含名单为空）一律拒绝。"""
        if not self.approval.can_approve(reviewer):
            raise PermissionError("reviewer_not_authorised")
        if now is not None:
            now = _parse(now)
            self.store.set_clock(lambda: now.isoformat(timespec="seconds"))
        c = self.store.get(cid)
        if c.state != "pending_approval":
            raise IllegalTransition(f"{c.state}->decision")
        return self.store.transition(cid, "approved" if approve else "rejected", reviewer=reviewer)

    def _expire(self, now: datetime, rep: CycleReport) -> None:
        for c in self.store.list("pending_approval"):
            if is_timed_out(c.updated_at, now, self.approval.timeout_hours):
                self.store.transition(c.id, "expired", reason="approval_timeout")
                rep.expired.append(c.id)

    def _promote_approved(self, rep: CycleReport) -> None:
        for c in self.store.list("approved"):
            if c.needs_expert and not c.payload.get("expert_attestation"):
                rep.blocked.append((c.id, "expert_signoff_required"))  # 永不代签
                continue
            self._promote(c.id, rep)

    def _promote(self, cid: str, rep: CycleReport) -> None:
        c = self.store.get(cid)
        snap = self.hooks.apply(c)
        self.store.transition(cid, "promoted", snapshot=snap)
        rep.promoted.append(cid)

    # ---------- 晋升后监控与回滚 ----------
    def monitor(self, cid: str, live: Mapping[str, float], baseline: Mapping[str, float], se: Mapping[str, float] | None = None) -> bool:
        """晋升后 7 天内用线上指标复核；跌破下限自动回滚。返回是否回滚。"""
        c = self.store.get(cid)
        if c.state != "promoted":
            return False
        res = evaluate_gates(baseline, live, self.cfg.thresholds, standard_errors=se, no_skill=live)
        regress = [r for r in res.reasons if r.startswith(("regression:", "redteam", "citation", "faithfulness"))]
        if regress:
            self.hooks.rollback(c)
            self.store.transition(cid, "rolled_back", reasons=regress)
            self.utility.record(c.target, 0.0)
            return True
        self.utility.record(c.target, 1.0)  # 7 天观察期内线上指标没有退步 → 记一次有用
        return False

    def rollback(self, cid: str, reason: str = "manual") -> Candidate:
        c = self.store.get(cid)
        self.hooks.rollback(c)
        return self.store.transition(cid, "rolled_back", reasons=[reason])

    # ---------- 每月 ----------
    def run_monthly(self, today: date) -> dict:
        """库清点：返回要降级的条目名单（不删除任何东西，由调用方执行并走审批）。"""
        if not self.cfg.enabled or not self.hooks.entries:
            return {"status": "disabled" if not self.cfg.enabled else "no_entries_hook"}
        rep = retirement_scan(self.hooks.entries(), today, hits_90d=self.hooks.hits_90d() if self.hooks.hits_90d else None)
        out = {"status": "ok", "retire": rep.retire_ids, "expiring_soon": rep.expiring_soon, "expired": rep.expired, "superseded": rep.superseded, "idle": rep.idle}
        d = Path(self.cfg.data_dir) / "reports"
        d.mkdir(parents=True, exist_ok=True)
        (d / f"monthly-{today.isoformat()}.json").write_text(json.dumps(out, ensure_ascii=False, indent=2), "utf-8")
        self.store.ledger.append({"t": today.isoformat(), "monthly_retirement": rep.retire_ids})
        return out
