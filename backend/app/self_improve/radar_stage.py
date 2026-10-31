"""研究雷达线索 → 资料库“待审核候选”暂存区（只暂存，永不自动通过）。

雷达（radar.py）只写摘要文件；这里把其中**与本产品相关**的线索整理成一份暂存清单，供人决定要不要读原文、整理成条目。
边界（测试逐条锁定）：
- 暂存区文件只有 <data_dir>/library_staged.jsonl；不写资料库条目、不改状态文件、不发消息、不联网；
- 每条都是 review_status=待审核、visible=false、auto_approved=false；没有任何函数把它改成“已审核”；
- 线索只保留标题/链接/≤200 字摘要（当数据；含提示注入特征的整条丢弃），**不拷贝正文或代码**；
- 许可证类别为 do_not_ingest / do_not_introduce / unknown_do_not_introduce 的，ingest_allowed=false，只能当“读后自己重写”的参考；
- 与产品关键词零匹配的不暂存；同一 URL 不重复；每次最多暂存 cap 条（默认 20）。
"""

from __future__ import annotations

import json
import re
from datetime import datetime
from pathlib import Path
from typing import Iterable, Mapping, Optional

_INJECTION = re.compile(r"(ignore (all |any )?(previous|prior) instructions|disregard .{0,20}instructions|system prompt|忽略(以上|之前|上述)|无视.{0,6}(指令|规则)|你现在是)", re.I)
BLOCKED_LICENSES = ("do_not_ingest", "do_not_introduce", "unknown_do_not_introduce")


def _clean(t: object, n: int) -> str:
    return re.sub(r"\s+", " ", re.sub(r"[\x00-\x1f\x7f]", " ", str(t or ""))).strip()[:n]


def relevance(item: Mapping, terms: Iterable[str]) -> int:
    blob = f"{item.get('title', '')} {item.get('summary', '')}".lower()
    return sum(1 for t in terms if t.lower() in blob)


def load_items(radar_dir) -> list[dict]:
    """读 radar 目录下全部 items_*.json（由 radar.run_radar 写出）。"""
    out: list[dict] = []
    for p in sorted(Path(radar_dir).glob("items_*.json")):
        try:
            out += json.loads(p.read_text("utf-8"))
        except (OSError, ValueError):
            continue
    return out


def stage(items: Iterable[Mapping], *, product: str, terms: Iterable[str], staged_path, known_urls: Iterable[str] = (),
          now: Optional[datetime] = None, cap: int = 20, min_relevance: int = 1) -> dict:
    from .radar import license_class  # 同一套许可证分类

    staged_path = Path(staged_path)
    seen = {u for u in known_urls if u}
    if staged_path.exists():
        for line in staged_path.read_text("utf-8").splitlines():
            if line.strip():
                seen.add(json.loads(line).get("url"))
    now = now or datetime.now()
    terms = list(terms)
    rows, skipped = [], {"irrelevant": 0, "duplicate": 0, "injection": 0, "no_url": 0, "cap": 0}
    for it in items:
        url = str(it.get("url", ""))
        title, summary = _clean(it.get("title"), 160), _clean(it.get("summary"), 200)
        if not url.startswith("https://"):
            skipped["no_url"] += 1
        elif _INJECTION.search(f"{title} {summary}"):
            skipped["injection"] += 1
        elif url in seen:
            skipped["duplicate"] += 1
        elif relevance(it, terms) < min_relevance:
            skipped["irrelevant"] += 1
        elif len(rows) >= cap:
            skipped["cap"] += 1
        else:
            lc = license_class(it.get("license"))
            seen.add(url)
            rows.append({
                "id": "radar-" + re.sub(r"[^a-zA-Z0-9]+", "-", f"{it.get('source', 'x')}-{it.get('id', '')}")[:60].strip("-"),
                "product": product, "kind": "lead", "title": title, "url": url, "summary": summary, "date": it.get("date", ""),
                "source": it.get("source", ""), "license": it.get("license"), "license_class": lc,
                "ingest_allowed": lc not in BLOCKED_LICENSES, "relevance": relevance(it, terms),
                "review_status": "待审核", "visible": False, "auto_approved": False,
                "action": "人工读原文；要采用就自己改写成带出处的条目再走资料库审核，不要拷贝正文/代码",
                "staged_at": now.isoformat(timespec="seconds"),
            })
    if rows:
        staged_path.parent.mkdir(parents=True, exist_ok=True)
        with staged_path.open("a", encoding="utf-8") as f:
            for r in rows:
                f.write(json.dumps(r, ensure_ascii=False) + "\n")
    return {"staged": len(rows), "skipped": skipped, "path": str(staged_path)}


def load_staged(staged_path) -> list[dict]:
    p = Path(staged_path)
    return [json.loads(x) for x in p.read_text("utf-8").splitlines() if x.strip()] if p.exists() else []
