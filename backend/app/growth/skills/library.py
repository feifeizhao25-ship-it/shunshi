"""读取已经落盘的技能包：版本、变更记录、评测集。不依赖 PyYAML。"""

from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path

PACKS_DIR = Path(__file__).resolve().parent / "packs"


@dataclass
class SkillPack:
    name: str
    description: str
    version: str
    owner: str
    channels: list[str]
    red_lines: list[str]
    body: str
    changelog: str
    rubric: dict
    golden: list[dict]
    redteam: list[dict]
    path: Path
    products: list[str] = field(default_factory=list)


def parse_frontmatter(text: str) -> tuple[dict, str]:
    if not text.startswith("---"):
        raise ValueError("skill file missing frontmatter")
    _, raw, body = text.split("---", 2)
    data: dict = {}
    current: str | None = None
    for line in raw.splitlines():
        if not line.strip():
            continue
        if line.startswith("  - ") or line.startswith("- "):
            if current is None:
                raise ValueError("list item without a key")
            data.setdefault(current, []).append(line.split("- ", 1)[1].strip())
            continue
        if ":" not in line:
            raise ValueError("frontmatter line has no key")
        key, value = line.split(":", 1)
        key = key.strip()
        value = value.strip()
        if value == "":
            current = key
            data[key] = []
        else:
            current = None
            data[key] = value
    return data, body.strip()


def parse_simple_yaml(text: str) -> dict:
    data: dict = {}
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        key, value = line.split(":", 1)
        value = value.strip()
        if value.lower() == "true":
            parsed: object = True
        elif value.lower() == "false":
            parsed = False
        else:
            try:
                parsed = float(value) if "." in value else int(value)
            except ValueError:
                parsed = value
        data[key.strip()] = parsed
    return data


def load_jsonl(path: Path) -> list[dict]:
    rows = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.strip():
            rows.append(json.loads(line))
    return rows


def load_skill(name: str, root: Path | None = None) -> SkillPack:
    pack_dir = (root or PACKS_DIR) / name
    meta, body = parse_frontmatter((pack_dir / "SKILL.md").read_text(encoding="utf-8"))
    channels = meta.get("channels") or []
    if isinstance(channels, str):
        channels = [channels]
    products = meta.get("products") or []
    if isinstance(products, str):
        products = [products]
    red_lines = meta.get("red_lines") or []
    return SkillPack(
        name=meta["name"],
        description=meta.get("description", ""),
        version=meta["version"],
        owner=meta.get("owner", ""),
        channels=list(channels),
        red_lines=list(red_lines),
        products=list(products),
        body=body,
        changelog=(pack_dir / "CHANGELOG.md").read_text(encoding="utf-8"),
        rubric=parse_simple_yaml((pack_dir / "rubric.yaml").read_text(encoding="utf-8")),
        golden=load_jsonl(pack_dir / "evals" / "golden.jsonl"),
        redteam=load_jsonl(pack_dir / "evals" / "redteam.jsonl"),
        path=pack_dir,
    )


def list_skills(root: Path | None = None) -> list[SkillPack]:
    base = root or PACKS_DIR
    return [load_skill(path.name, base) for path in sorted(base.iterdir()) if path.is_dir()]
