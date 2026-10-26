import filecmp
from pathlib import Path

from app.growth.skills.catalog import SKILLS
from app.growth.skills.drafts import render_draft, title_variants
from app.growth.skills.evaluate import evaluate_skill
from app.growth.skills.library import PACKS_DIR, list_skills, load_skill
from app.growth.skills.materialize import write_packs


def _rouge_l(left: str, right: str) -> float:
    previous = [0] * (len(right) + 1)
    for char in left:
        current = [0]
        for index, other in enumerate(right, start=1):
            if char == other:
                current.append(previous[index - 1] + 1)
            else:
                current.append(max(previous[index], current[-1]))
        previous = current
    if not left or not right:
        return 0.0
    return previous[-1] / max(len(left), len(right))


def test_titles_stay_diverse():
    titles = title_variants("立春")
    assert len(titles) == 5
    for index, left in enumerate(titles):
        for right in titles[index + 1 :]:
            assert _rouge_l(left, right) < 0.6


def test_each_skill_has_version_changelog_and_fixed_evals():
    packs = list_skills()
    assert {pack.name for pack in packs} == {spec.name for spec in SKILLS}
    for pack in packs:
        assert pack.version == "0.1.0"
        assert f"## {pack.version}" in pack.changelog
        assert pack.rubric["hook_threshold"] == 0.35
        assert len(pack.golden) >= 50
        assert len(pack.redteam) >= 30
        assert pack.red_lines
        report = evaluate_skill(pack.name, baseline_mean=None)
        assert report.golden_mean == 1
        assert report.redteam_pass == 1
        assert report.regressions == 0
        assert report.promotable is False
        lifted = evaluate_skill(pack.name, baseline_mean=0.9)
        assert lifted.promotable is True


def test_referral_copy_does_not_promise_membership():
    text = render_draft("referral-copy", "立春", "早睡", "站内")
    assert "记到你的名下" in text
    assert "7天" not in text
    assert "会员体验" not in text


def test_committed_packs_match_the_generator(tmp_path):
    write_packs(tmp_path)
    committed = PACKS_DIR
    for spec in SKILLS:
        for relative in (
            Path("SKILL.md"),
            Path("CHANGELOG.md"),
            Path("rubric.yaml"),
            Path("evals") / "golden.jsonl",
            Path("evals") / "redteam.jsonl",
        ):
            assert filecmp.cmp(committed / spec.name / relative, tmp_path / spec.name / relative, shallow=False)
    assert load_skill("xhs-note").channels == ["小红书"]
