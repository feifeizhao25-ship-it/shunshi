"""顺时节气表与膳食指南的年度候选钩子。

节奏写在 HARVEST_CADENCE：每年 1 月 2 日 02:00（Asia/Shanghai）由人执行，
核对新一年节气表；《中国居民膳食指南》修订发布后再执行同一命令。
不注册到 ``python -m app.self_improve.run serve``，也不读取新的云端密钥。
不读取、不打开 LIBRARY_FRESHNESS_ENABLED 或 SIL_ENABLED。

只写调用方给出的 candidates 目录（分栏 JSON + diff-report.md / diff-report.json）。
不改生产 RAG、节气表、资料库注册表、暂存包或 skills，也不调用 promote。

publish_candidates：reviewer_signature 为空则拒绝。
签名不是复核人姓名。即使签名非空，也只写 publish-receipt.json，
不把候选复制进线上库。具名复核人仍为空，审核状态仍是待审核。

默认不联网。目录里的摘录来自本产品已经引用的来源。调用方可以传入 fetcher
提供字节以计算内容哈希；抓取失败时保留目录摘录，不另编正文。
"""

from __future__ import annotations

import hashlib
import json
import os
import re
import sys
from datetime import date
from pathlib import Path
from typing import Callable, Optional
from urllib.parse import urlsplit

HARVEST_CADENCE = "yearly"
HARVEST_WINDOW = "JAN-02@02:00"
HARVEST_TIMEZONE = "Asia/Shanghai"
HARVEST_CADENCE_LABEL = f"{HARVEST_CADENCE}:{HARVEST_WINDOW}"
CATALOG_PATH = Path(__file__).resolve().parent / "yearly_sources.json"

CANDIDATE_FIELDS = (
    "url",
    "doi",
    "publisher",
    "excerpt",
    "published_at",
    "retrieved_at",
    "effective_at",
    "expires_at",
    "region",
    "content_hash",
    "license",
)

_ID_RE_TEXT = r"^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$"
_SECTION_RE_TEXT = r"^[a-z0-9][a-z0-9-]{0,63}$"
_SKIP_JSON = {"diff-report.json", "manifest.json", "publish-receipt.json"}
_ALMANAC_KEYS = ("宜", "忌", "吉", "凶", "yi", "ji", "jixiong")
_UNCONFIRMED_HOSTS = {
    "24jieqi.aboutchn.com",
    "snaped.fns.usda.gov",
    "eatforhealth.gov.au",
    "www.eatforhealth.gov.au",
    "huggingface.co",
}

Fetcher = Callable[[str], bytes]


def _app_dir() -> Path:
    return Path(__file__).resolve().parents[1]


def _repo_root() -> Path:
    return Path(__file__).resolve().parents[3]


def production_roots() -> list[Path]:
    """候选不得写进这些目录。目录不存在就不列入，避免为了拒绝而把目录创建出来。"""
    app = _app_dir()
    repo = _repo_root()
    roots = [
        app / "rag",
        app / "skills",
        app / "growth" / "skills",
        app / "library" / "data",
        app / "data",
        app / "self_improve" / "data",
        repo / "ios-cn" / "assets" / "library",
        repo / "android-cn" / "assets" / "library",
    ]
    return [path.resolve() for path in roots if path.exists()]


def default_production_paths() -> list[Path]:
    app = _app_dir()
    repo = _repo_root()
    paths = [
        app / "rag" / "source_manifest.json",
        app / "rag" / "verified_cn.md",
        app / "rag" / "verified_global.md",
        app / "rag" / "pending_cn.md",
        app / "rag" / "pending_global.md",
        app / "rag" / "sleep_light.py",
        app / "data" / "solar_terms.json",
        app / "self_improve" / "data" / "solar_terms_pmo_2026.json",
        app / "library" / "data" / "reference_entries_v1.json",
        app / "library" / "data" / "staged_entries_20261031b.json",
        app / "library" / "data" / "staged_entries_20261101c.json",
        app / "library" / "data" / "sources.json",
        app / "skills" / "core_skills.py",
        app / "skills" / "skill_registry.py",
        app / "growth" / "skills" / "catalog.py",
        repo / "ios-cn" / "assets" / "library" / "reference_entries_v1.json",
        repo / "android-cn" / "assets" / "library" / "reference_entries_v1.json",
        CATALOG_PATH,
    ]
    return [path.resolve() for path in paths if path.exists()]


def default_candidates_dir() -> Path:
    base = Path(os.environ.get("SHUNSHI_LIBRARY_DIR") or "var/library")
    return base / "yearly-candidates"


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _is_inside(child: Path, parent: Path) -> bool:
    try:
        child.resolve().relative_to(parent.resolve())
    except ValueError:
        return False
    return True


def refuse_production_dir(target: Path) -> Path:
    root = Path(target).resolve()
    for banned in production_roots():
        if root == banned or _is_inside(root, banned):
            raise PermissionError(
                "refusing to write candidates into production registry, RAG, or skills: %s" % root
            )
    return root


def _snapshot_bytes(paths: list[Path]) -> dict[str, Optional[bytes]]:
    out: dict[str, Optional[bytes]] = {}
    for path in paths:
        key = str(path.resolve()) if path.exists() else str(path)
        out[key] = path.read_bytes() if path.exists() else None
    return out


def _assert_unchanged(before: dict[str, Optional[bytes]]) -> None:
    for key, content in before.items():
        path = Path(key)
        current = path.read_bytes() if path.exists() else None
        if current != content:
            raise RuntimeError("production path changed during candidate harvest: %s" % key)


def load_catalog(path: Optional[Path] = None) -> dict:
    catalog_path = Path(path) if path else CATALOG_PATH
    return json.loads(catalog_path.read_text(encoding="utf-8"))


def _watched_paths(extra: Optional[list[Path]] = None) -> list[Path]:
    return [*(extra or []), *default_production_paths()]


def _host(url: str) -> str:
    try:
        return (urlsplit(url).hostname or "").lower()
    except ValueError:
        return ""


def _blocked_set(catalog: dict) -> set[str]:
    return {str(url).strip().rstrip("/") for url in catalog.get("blocked_urls", [])}


def _skip_status(url: str, blocked: set[str]) -> Optional[str]:
    bare = url.rstrip("/")
    if bare in blocked or url in blocked:
        return "blocked_unverified_url"
    host = _host(url)
    if host in _UNCONFIRMED_HOSTS or host.endswith(".huggingface.co"):
        return "unconfirmed_url"
    if not url.startswith(("https://", "http://")):
        return "unconfirmed_url"
    return None


def _safe_token(value: str, pattern: str, label: str) -> str:
    if not re.fullmatch(pattern, value):
        raise ValueError("unsafe %s" % label)
    return value


def _render_report(report: dict, written: list[dict], sections: list[dict]) -> str:
    by_section: dict[str, list[dict]] = {}
    for row in written:
        by_section.setdefault(row["section"], []).append(row)
    lines = [
        "# 顺时节气与膳食指南候选差异",
        "",
        "- 日期：%s" % report["generated_at"],
        "- 节奏：每年 1 月 2 日 02:00（Asia/Shanghai）由人执行，核对新一年节气表；膳食指南修订发布后再执行同一命令。",
        "- 调度：未注册定时任务，不需要新的云端密钥。LIBRARY_FRESHNESS 与 SIL 保持关闭。",
        "- 状态：未发布",
        "- 复核人：（空）",
        "- 审核状态：待审核",
        "",
        "这些记录只在候选目录里。生产 RAG、节气表、资料库注册表、暂存包和 skills 没有被改写，暂存包也没有被提升。",
        "",
    ]
    for section in sections:
        rows = by_section.get(section["id"], [])
        lines.append("## %s" % section.get("title", section["id"]))
        lines.append("")
        if section.get("note"):
            lines.append(section["note"])
            lines.append("")
        if not rows:
            lines.append("本栏没有候选。")
            lines.append("")
            continue
        for row in rows:
            if row["id"] in report["added"]:
                verb = "新增"
            elif row["id"] in report["changed"]:
                verb = "有变化"
            else:
                verb = "未变化"
            lines.append("- %s `%s` %s（%s）" % (verb, row["id"], row.get("title") or row["id"], row["publisher"]))
            lines.append("  %s" % row["url"])
        lines.append("")
    left = report.get("left_out") or []
    if left:
        lines.append("## 本轮不写入")
        lines.append("")
        for item in left:
            lines.append("- `%s`：%s" % (item.get("id", ""), item.get("reason", "")))
        lines.append("")
    skipped = "、".join("%s（%s）" % (item.get("id") or "（无编号）", item.get("status")) for item in report["skipped"])
    lines.extend(
        [
            "## 差异",
            "",
            "- 新增：%s" % ("、".join(report["added"]) or "无"),
            "- 有变化：%s" % ("、".join(report["changed"]) or "无"),
            "- 未变化：%s" % ("、".join(report["unchanged"]) or "无"),
            "- 本次不再列出：%s" % ("、".join(report["removed"]) or "无"),
            "- 未写入：%s" % (skipped or "无"),
            "",
            "发布候选时，复核人签名留空会被拒绝。签名本身不是复核人姓名；在具名复核人写入之前，不会把候选复制进线上库。",
            "",
        ]
    )
    return "\n".join(lines)


def harvest_yearly(
    *,
    candidates_dir: Path,
    today: Optional[date] = None,
    fetcher: Optional[Fetcher] = None,
    catalog_path: Optional[Path] = None,
    production_paths: Optional[list[Path]] = None,
) -> dict:
    """把节气表与膳食指南来源写入 ``candidates_dir``，并写出差异报告。

    复核人留空，审核状态为待审核。不更新生产 RAG 或 skills。
    """
    today = today or date.today()
    root = refuse_production_dir(candidates_dir)
    catalog = load_catalog(catalog_path)
    blocked = _blocked_set(catalog)
    before = _snapshot_bytes(_watched_paths(production_paths))
    manifest_path = root / "manifest.json"
    previous: dict[str, str] = {}
    if manifest_path.exists():
        prior = json.loads(manifest_path.read_text(encoding="utf-8"))
        previous = {row["id"]: row["content_hash"] for row in prior.get("candidates", [])}

    written: list[dict] = []
    skipped: list[dict] = []
    root.mkdir(parents=True, exist_ok=True)
    for source in catalog.get("sources", []):
        url = str(source.get("url", "")).strip()
        status = _skip_status(url, blocked)
        if any(key in source for key in _ALMANAC_KEYS):
            status = status or "almanac_unpublished"
        if status:
            skipped.append({"id": source.get("id"), "url": url, "status": status})
            continue
        source_id = _safe_token(str(source["id"]), _ID_RE_TEXT, "source id")
        section = _safe_token(str(source["section"]), _SECTION_RE_TEXT, "section id")
        body = None
        fetch_status = "not_fetched"
        fetch_error = None
        if fetcher is not None:
            try:
                body = fetcher(url)
                fetch_status = "fetched"
            except Exception as exc:  # 抓不到就保留目录摘录，不另编正文
                fetch_status = "fetch_failed"
                fetch_error = str(exc)[:300]
        raw = body if body is not None else str(source.get("excerpt", "")).encode("utf-8")
        record = {
            "id": source_id,
            "section": section,
            "product": source.get("product") or catalog.get("product") or "shunshi",
            "title": source.get("title") or source_id,
            "url": url,
            "doi": source.get("doi") or "",
            "publisher": source.get("publisher") or "",
            "excerpt": source.get("excerpt") or "",
            "published_at": source.get("published_at") or "",
            "retrieved_at": today.isoformat(),
            "effective_at": source.get("effective_at") or "",
            "expires_at": source.get("expires_at") or "",
            "region": source.get("region") or "",
            "content_hash": sha256_bytes(raw),
            "license": source.get("license") or "",
            "language": source.get("language") or "",
            "supersedes": source.get("supersedes") or "",
            "principle_only": bool(source.get("principle_only")),
            "almanac_published": False,
            "reviewer": "",
            "named_reviewer": None,
            "review_status": "待审核",
            "state": "unpublished",
            "fetch_status": fetch_status,
        }
        if fetch_error:
            record["fetch_error"] = fetch_error
        for field in CANDIDATE_FIELDS:
            if field not in record:
                raise RuntimeError("candidate missing %s" % field)
        folder = root / section
        folder.mkdir(parents=True, exist_ok=True)
        path = folder / ("%s.json" % source_id)
        if not _is_inside(path, root):
            raise ValueError("unsafe candidate path")
        path.write_text(json.dumps(record, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        written.append(record)

    ids = {row["id"] for row in written}
    for path in _walk_json(root):
        if path.name in _SKIP_JSON or path.stem in ids:
            continue
        path.unlink()
    added = [row["id"] for row in written if row["id"] not in previous]
    changed = [row["id"] for row in written if row["id"] in previous and previous[row["id"]] != row["content_hash"]]
    unchanged = [row["id"] for row in written if row["id"] in previous and previous[row["id"]] == row["content_hash"]]
    removed = [cid for cid in previous if cid not in ids]
    sections: dict[str, list[str]] = {}
    for row in written:
        sections.setdefault(row["section"], []).append(row["id"])
    window = catalog.get("cadence_window")
    if window:
        cadence_label = "%s:%s" % (catalog.get("cadence") or HARVEST_CADENCE, window)
    else:
        cadence_label = HARVEST_CADENCE_LABEL
    report = {
        "generated_at": today.isoformat(),
        "cadence": cadence_label,
        "timezone": catalog.get("timezone") or HARVEST_TIMEZONE,
        "scheduler_registered": False,
        "state": "unpublished",
        "reviewer": "",
        "named_reviewer": None,
        "review_status": "待审核",
        "added": added,
        "changed": changed,
        "unchanged": unchanged,
        "removed": removed,
        "skipped": skipped,
        "sections": sections,
        "left_out": catalog.get("not_in_this_catalog") or [],
        "production_written": False,
        "auto_promoted": False,
        "note": "候选未发布，未写入生产 RAG、节气表、资料库注册表、暂存包或 skills。复核人留空。未自动提升暂存包。",
    }
    (root / "diff-report.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    (root / "diff-report.md").write_text(
        _render_report(report, written, catalog.get("sections") or []),
        encoding="utf-8",
    )
    manifest = {
        "generated_at": today.isoformat(),
        "cadence": report["cadence"],
        "state": "unpublished",
        "candidates": [
            {"id": row["id"], "section": row["section"], "content_hash": row["content_hash"]} for row in written
        ],
    }
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    _assert_unchanged(before)
    return report


def _walk_json(directory: Path) -> list[Path]:
    if not directory.exists():
        return []
    found: list[Path] = []
    for path in sorted(directory.rglob("*.json")):
        if path.is_file():
            found.append(path)
    return found


def publish_candidates(
    reviewer_signature: str,
    *,
    candidates_dir: Path,
    production_paths: Optional[list[Path]] = None,
) -> dict:
    """收下非空签名，只写一张未发布回执。

    空签名直接拒绝，不写回执。签名不会写进候选的复核人栏，也不会把候选复制进生产库。
    """
    if reviewer_signature is None or not str(reviewer_signature).strip():
        raise ValueError("refusing publish: reviewer_signature is empty")
    root = refuse_production_dir(candidates_dir)
    before = _snapshot_bytes(_watched_paths(production_paths))
    for path in _walk_json(root):
        if path.name in _SKIP_JSON:
            continue
        row = json.loads(path.read_text(encoding="utf-8"))
        named = "" if row.get("named_reviewer") is None else str(row.get("named_reviewer"))
        if str(row.get("reviewer") or "").strip() or named.strip() or row.get("review_status") != "待审核" or row.get("state") != "unpublished":
            _assert_unchanged(before)
            raise RuntimeError("publish must leave candidates unpublished and reviewer empty")
        if row.get("almanac_published"):
            _assert_unchanged(before)
            raise RuntimeError("publish must leave almanac fields unpublished")
    receipt = {
        "state": "queued_unpublished",
        "production_written": False,
        "auto_promoted": False,
        "signature_accepted": True,
        "reviewer_on_candidates": "",
        "named_reviewer": None,
        "review_status": "待审核",
        "note": "签名只放行队列记录，不覆盖生产 RAG、节气表、资料库注册表或 skills，也不填写复核人姓名。在具名复核人写入之前，不会把候选复制进线上库。",
    }
    root.mkdir(parents=True, exist_ok=True)
    (root / "publish-receipt.json").write_text(json.dumps(receipt, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    _assert_unchanged(before)
    return receipt


def _flag(argv: list[str], name: str) -> str:
    key = "--%s" % name
    if key not in argv:
        return ""
    index = argv.index(key)
    if index + 1 >= len(argv) or argv[index + 1].startswith("--"):
        return ""
    return argv[index + 1]


def main(argv: Optional[list[str]] = None) -> int:
    argv = list(sys.argv[1:] if argv is None else argv)
    cmd = argv[0] if argv else ""
    if cmd not in ("harvest", "publish-candidates"):
        print(
            "用法：harvest [--out 目录] | publish-candidates --signature 签名 [--out 目录]",
            file=sys.stderr,
        )
        return 2
    out = Path(_flag(argv, "out") or default_candidates_dir())
    try:
        if cmd == "harvest":
            report = harvest_yearly(candidates_dir=out)
            print(
                "候选新增 %s 条，有变化 %s 条，未变化 %s 条。未写入生产库。报告：%s"
                % (len(report["added"]), len(report["changed"]), len(report["unchanged"]), out / "diff-report.md")
            )
            return 0
        publish_candidates(_flag(argv, "signature") or _flag(argv, "reviewer-signature"), candidates_dir=out)
        print("未写入生产库。签名已收下，复核人仍为空，候选保持未发布。")
        return 0
    except (ValueError, PermissionError, RuntimeError, OSError) as exc:
        print("失败：%s" % exc, file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
