"""持续自改进（Self-Improvement Loop, SIL）公共内核。

仅依赖标准库、全部使用相对导入，可以原样放进任意后端包里。默认关闭。
设计见 proj_research/PLAN.md §A。
"""

from .approval import ApprovalPolicy, NullGateway, WeComGateway, build_card, reviewers_from_env
from .cohort import arm, in_canary, in_control
from .compliance import check as compliance_check, normalize
from .config import SILConfig
from .freshness import fact_allowed, retirement_scan, retrievable, validate_entry
from .gates import GateThresholds, debiased_pairwise, edit_budget, evaluate_gates, rotate_gate_set, check_set_separation
from .loop import CycleReport, EvalOutcome, Hooks, SelfImprovementLoop
from .models import ModelPolicy, assert_domestic
from .sources import SourcePolicy, as_data, lint_source
from .stats import wilson_interval, wilson_lower, wilson_superior
from .store import Candidate, CandidateStore, Ledger


from .fetch import FetchRefused, fetch_page  # noqa: E402
from .scheduler import SCHEDULE_DEFAULTS, next_run, run_forever  # noqa: E402

__all__ = [n for n in dir() if not n.startswith("_")]
