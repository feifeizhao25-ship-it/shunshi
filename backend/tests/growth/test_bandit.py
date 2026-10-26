from app.config import Settings
from app.growth.constants import BUCKET_SLOTS, CONTROL_SLOTS
from app.growth.experiments.bandit import assign_bucket, judge_outcome, thompson_sample
from app.growth.experiments.wilson import wilson_lower


def test_control_bucket_is_permanent_fifteen_percent():
    assert "growth_control_rate" not in Settings.model_fields
    assert CONTROL_SLOTS / BUCKET_SLOTS == 0.15
    labels = [assign_bucket(f"user-{index}", "skill:xhs-note") for index in range(4000)]
    rate = labels.count("control") / len(labels)
    assert abs(rate - 0.15) < 0.02
    assert assign_bucket("user-7", "skill:xhs-note") == assign_bucket("user-7", "skill:xhs-note")


def test_wilson_and_promotion_rules():
    assert wilson_lower(0, 0) == 0
    assert wilson_lower(80, 100) > wilson_lower(40, 100)
    assert judge_outcome(80, 200, 10, 200, eval_ok=True) == "rollback"
    assert judge_outcome(10, 200, 80, 200, eval_ok=True) == "promote"
    assert judge_outcome(50, 100, 50, 100, eval_ok=True) == "no_change"
    assert judge_outcome(10, 200, 80, 200, eval_ok=False) == "rollback"
    assert judge_outcome(0, 0, 1, 1, eval_ok=True) == "no_change"
    sample = thompson_sample(2, 5)
    assert 0 <= sample <= 1
