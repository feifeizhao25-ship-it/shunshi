#!/usr/bin/env python3
"""Fail closed on non-portable production sources and false-green CI."""

import json
import os
from pathlib import Path
import subprocess


ROOT = Path(__file__).resolve().parents[1]
errors: list[str] = []

for relative in (
    "android-global/i18n_doit.py",
    "android-global/i18n_process.py",
    "backend/fix_text_wrapping.py",
    "backend/scripts/import_knowledge_base.py",
):
    source = (ROOT / relative).read_text(encoding="utf-8")
    if "/Users/" in source or "C:\\Users\\" in source:
        errors.append(f"{relative}: production helper contains a developer-machine path")

for knowledge_file in ("顺时知识库_中文版.md", "顺时知识库_补充篇_中文版.md"):
    if not (ROOT / "参考文档，知识库" / knowledge_file).is_file():
        errors.append(f"参考文档，知识库/{knowledge_file}: required RAG source is missing")

admin_manifest = json.loads((ROOT / "admin/package.json").read_text(encoding="utf-8"))
if not admin_manifest.get("scripts", {}).get("test"):
    errors.append("admin/package.json: fail-closed test command is required")
admin_api = (ROOT / "admin/src/lib/api.ts").read_text(encoding="utf-8")
if "process.env.NEXT_PUBLIC_ADMIN_TOKEN" in admin_api:
    errors.append("admin/src/lib/api.ts: public bundles must never contain an admin token")

ci_source = (ROOT / ".github/workflows/ci.yml").read_text(encoding="utf-8")
for forbidden in ("--passWithNoTests", "continue-on-error: true", "|| true"):
    if forbidden in ci_source:
        errors.append(f".github/workflows/ci.yml: forbidden false-green option {forbidden}")

entries = subprocess.run(
    ["git", "ls-files", "-s", "-z"], cwd=ROOT, check=True, capture_output=True, text=True
).stdout.split("\0")
for entry in entries:
    if not entry or not entry.startswith("120000 "):
        continue
    relative = entry.split("\t", 1)[1]
    link = ROOT / relative
    target = os.readlink(link)
    if os.path.isabs(target):
        errors.append(f"{relative}: tracked symlink must be relative")
    elif not link.exists():
        errors.append(f"{relative}: tracked symlink target is missing ({target})")

if errors:
    raise SystemExit("Repository integrity gate failed:\n- " + "\n- ".join(errors))

print("Repository integrity gate passed")
