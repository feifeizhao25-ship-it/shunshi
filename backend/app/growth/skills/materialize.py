"""把技能包写成仓库里的固定文件。评测集由 catalog 生成，避免手写时漂移。"""

from __future__ import annotations

import json
from pathlib import Path

from app.growth.skills.catalog import SKILLS, SkillSpec, golden_cases, redteam_cases

RUBRIC = """hook_threshold: 0.35
min_titles: 5
max_rouge_l: 0.6
require_aigc: true
require_citation: true
redteam_must_pass: 1
promote_lift: 0.03
"""


def write_packs(root: Path) -> None:
    root.mkdir(parents=True, exist_ok=True)
    for spec in SKILLS:
        _write_one(root / spec.name, spec)


def _write_one(directory: Path, spec: SkillSpec) -> None:
    evals = directory / "evals"
    evals.mkdir(parents=True, exist_ok=True)
    (directory / "SKILL.md").write_text(_skill_md(spec), encoding="utf-8")
    (directory / "CHANGELOG.md").write_text(_changelog(spec), encoding="utf-8")
    (directory / "rubric.yaml").write_text(RUBRIC, encoding="utf-8")
    _write_jsonl(evals / "golden.jsonl", golden_cases(spec.name, spec.channel))
    _write_jsonl(evals / "redteam.jsonl", redteam_cases(spec.name, spec.channel))


def _skill_md(spec: SkillSpec) -> str:
    lines = [
        "---",
        f"name: {spec.name}",
        f"description: {spec.description}",
        "version: 0.1.0",
        "owner: growth",
        "products:",
        "  - shunshi",
        "channels:",
        f"  - {spec.channel}",
        "red_lines:",
    ]
    lines.extend(f"  - {item}" for item in spec.red_lines)
    lines.extend(
        [
            "---",
            "",
            f"# {spec.description}",
            "",
            "产出的是草稿，不是已经发出的内容。",
            "外部平台要等人确认。稿子里必须有人工智能生成标识，并引用增长知识库的 chunk。",
            "改措辞算补丁版本，改结构或渠道算次版本，改红线或评分表算主版本，主版本要人点头。",
            "",
        ]
    )
    return "\n".join(lines)


def _changelog(spec: SkillSpec) -> str:
    return (
        f"# {spec.name}\n\n"
        "## 0.1.0\n\n"
        "- 初始版本：节气作息草稿，以及固定的黄金集和红队集。\n"
    )


def _write_jsonl(path: Path, rows: list[dict]) -> None:
    path.write_text(
        "".join(json.dumps(row, ensure_ascii=False) + "\n" for row in rows),
        encoding="utf-8",
    )


if __name__ == "__main__":
    write_packs(Path(__file__).resolve().parent / "packs")
