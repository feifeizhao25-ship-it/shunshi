"""顺时每月官方清单核对（中国营养学会 / 卫健委 / 市场监管总局）。

节奏写在 OFFICIAL_LIST_CADENCE：每月 15 日 03:00（Asia/Shanghai）由人执行。
只定义周期，不注册到 ``python -m app.self_improve.run serve``，也不读取新的云端密钥。
不读取、不打开 LIBRARY_FRESHNESS 或 SIL。

只写调用方给出的 candidates 目录（分栏 JSON + diff-report.md / diff-report.json）。
不改生产 RAG、节气表、资料库、禁推名单、价格、配额或法律文本，也不填写复核人姓名。

publish：reviewer_signature 为空则拒绝，与年度收获相同。
签名不是复核人姓名。即使签名非空，也只写 publish-receipt.json，不把候选复制进线上库。

默认不联网。目录里的摘录来自已标明可用的公开来源。调用方可以传入 fetcher
提供字节以计算内容哈希；不传 fetcher 时不会发出任何请求。
"""

from __future__ import annotations

import json
import re
import sys
from datetime import date
from pathlib import Path
from typing import Callable, Optional
from urllib.parse import urlsplit

from ..rag.yearly_harvest import (
    CANDIDATE_FIELDS,
    default_production_paths,
    refuse_production_dir,
    sha256_bytes,
)

OFFICIAL_LIST_CADENCE = "monthly"
OFFICIAL_LIST_WINDOW = "15@03:00"
OFFICIAL_LIST_TIMEZONE = "Asia/Shanghai"
OFFICIAL_LIST_CADENCE_LABEL = f"{OFFICIAL_LIST_CADENCE}:{OFFICIAL_LIST_WINDOW}"
SCHEDULER_REGISTERED = False
CATALOG_PATH = Path(__file__).resolve().parent / "data" / "monthly_official_sources.json"

_ID_RE_TEXT = r"^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$"
_SECTION_RE_TEXT = r"^[a-z0-9][a-z0-9-]{0,63}$"
_SKIP_JSON = {"diff-report.json", "manifest.json", "publish-receipt.json"}
_ALMANAC_KEYS = ("宜", "忌", "吉", "凶", "yi", "ji", "jixiong")
_REJECT_LICENSE = re.compile(
    r"non-?commercial|\bnc\b|cc-by-nc|share-?alike|\bgpl\b|\bagpl\b|未声明|noassertion|unknown|爬虫",
    re.IGNORECASE,
)
_ALLOW_LICENSE = ("政府", "学会公开", "公有", "mit", "apache", "bsd", "cc-by", "cc by", "public domain")

Fetcher = Callable[[str], bytes]


def load_catalog(path: Optional[Path] = None) -> dict:
    catalog_path = Path(path) if path else CATALOG_PATH
    return json.loads(catalog_path.read_text(encoding="utf-8"))


def license_allowed(text: str) -> bool:
    """政府公开引用、学会公开、MIT/Apache/BSD/CC-BY/公有领域可以通过。NC/GPL/未声明拒绝。"""
    raw = (text or "").strip()
    if not raw or _REJECT_LICENSE.search(raw):
        return False
    lowered = raw.lower()
    return any(marker in raw or marker in lowered for marker in _ALLOW_LICENSE)


def _host(url: str) -> str:
    try:
        return (urlsplit(url).hostname or "").lower()
    except ValueError:
        return ""


def _skip_status(source: dict) -> Optional[str]:
    if any(key in source for key in _ALMANAC_KEYS):
        return "almanac_unpublished"
    url = str(source.get("url", "")).strip()
    if not url.startswith(("https://", "http://")) or not _host(url):
        return "unconfirmed_url"
    if not license_allowed(str(source.get("license", ""))):
        return "license_rejected"
    return None


def _safe_token(value: str, pattern: str, label: str) -> str:
    if not re.fullmatch(pattern, value):
        raise ValueError("unsafe %s" % label)
    return value


def _is_inside(child: Path, parent: Path) -> bool:
    try:
        child.resolve().relative_to(parent.resolve())
    except ValueError:
        return False
    return True


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
            raise RuntimeError("production path changed during official-list check: %s" % key)


def _watched_paths(extra: Optional[list[Path]] = None) -> list[Path]:
    paths = [CATALOG_PATH, *(extra or []), *default_production_paths()]
    seen = set()
    out = []
    for path in paths:
        key = str(path)
        if key in seen:
            continue
        seen.add(key)
        out.append(path)
    return out


def _render_report(report: dict, written: list[dict], sections: list[dict]) -> str:
    by_section: dict[str, list[dict]] = {}
    for row in written:
        by_section.setdefault(row["section"], []).append(row)
    lines = [
        "# 顺时每月官方清单候选差异",
        "",
        "- 日期：%s" % report["generated_at"],
        "- 节奏：每月 15 日 03:00（Asia/Shanghai）由人执行，核对中国营养学会、国家卫生健康委、市场监管总局的公开清单。",
        "- 调度：只定义周期，未注册定时任务。LIBRARY_FRESHNESS 与 SIL 保持关闭。",
        "- 状态：未发布",
        "- 复核人：（空）",
        "- 审核状态：待审核",
        "",
        "这些记录只在候选目录里。生产库没有被改写。新版膳食指南未发布前，不把修订中的报道写成现行条文。",
        "",
    ]
    for section in sections:
        rows = by_section.get(section["id"], [])
        lines.append("## %s" % section.get("title", section["id"]))
        lines.append("")
        if section.get("listing_url"):
            lines.append("清单页：%s" % section["listing_url"])
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
            lines.append("  许可：%s" % row["license"])
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


def _walk_json(directory: Path) -> list[Path]:
    if not directory.exists():
        return []
    return [path for path in sorted(directory.rglob("*.json")) if path.is_file()]


def harvest_official_list(
    *,
    candidates_dir: Path,
    today: Optional[date] = None,
    fetcher: Optional[Fetcher] = None,
    catalog_path: Optional[Path] = None,
    production_paths: Optional[list[Path]] = None,
) -> dict:
    """把官方清单来源写入 ``candidates_dir``，并写出差异报告。默认不调用 fetcher。"""
    today = today or date.today()
    root = refuse_production_dir(candidates_dir)
    catalog = load_catalog(catalog_path)
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
        status = _skip_status(source)
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
            "region": source.get("region") or "CN",
            "content_hash": sha256_bytes(raw),
            "license": source.get("license") or "",
            "language": source.get("language") or "zh",
            "principle_only": bool(source.get("principle_only")),
            "edition_status": source.get("edition_status") or "",
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
    window = catalog.get("cadence_window") or OFFICIAL_LIST_WINDOW
    report = {
        "generated_at": today.isoformat(),
        "cadence": "%s:%s" % (catalog.get("cadence") or OFFICIAL_LIST_CADENCE, window),
        "timezone": catalog.get("timezone") or OFFICIAL_LIST_TIMEZONE,
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
        "production_written": False,
        "auto_promoted": False,
        "note": "候选未发布。复核人留空。未写入生产库。",
    }
    (root / "diff-report.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    (root / "diff-report.md").write_text(_render_report(report, written, catalog.get("sections") or []), encoding="utf-8")
    manifest = {
        "generated_at": today.isoformat(),
        "cadence": report["cadence"],
        "state": "unpublished",
        "candidates": [{"id": row["id"], "section": row["section"], "content_hash": row["content_hash"]} for row in written],
    }
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    _assert_unchanged(before)
    return report


def publish_official_list(
    reviewer_signature: str,
    *,
    candidates_dir: Path,
    production_paths: Optional[list[Path]] = None,
) -> dict:
    """收下非空签名，只写一张未发布回执。空签名直接拒绝，不写回执。"""
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
    receipt = {
        "state": "queued_unpublished",
        "production_written": False,
        "auto_promoted": False,
        "signature_accepted": True,
        "reviewer_on_candidates": "",
        "named_reviewer": None,
        "review_status": "待审核",
        "note": "签名只放行队列记录，不覆盖生产库，也不填写复核人姓名。",
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
    if cmd not in ("official-list", "publish-official-list"):
        print("用法：official-list [--out 目录] | publish-official-list --signature 签名 [--out 目录]", file=sys.stderr)
        return 2
    out = Path(_flag(argv, "out") or "var/library/monthly-official-candidates")
    try:
        if cmd == "official-list":
            report = harvest_official_list(candidates_dir=out)
            print(
                "官方清单候选新增 %s 条，有变化 %s 条，未变化 %s 条。未写入生产库。报告：%s"
                % (len(report["added"]), len(report["changed"]), len(report["unchanged"]), out / "diff-report.md")
            )
            return 0
        publish_official_list(_flag(argv, "signature") or _flag(argv, "reviewer-signature"), candidates_dir=out)
        print("未写入生产库。签名已收下，复核人仍为空，候选保持未发布。")
        return 0
    except (ValueError, PermissionError, RuntimeError, OSError) as exc:
        print("失败：%s" % exc, file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
