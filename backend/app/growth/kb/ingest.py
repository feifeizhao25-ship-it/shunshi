"""把允许的来源写进增长知识库。

拒绝名单在打开文件之前就生效，因此用药模块、提示词和密钥文件不会被读进来。
"""

from __future__ import annotations

import json
from datetime import date
from pathlib import Path

from sqlalchemy.orm import Session

from app.growth.compliance.gate import violation_codes
from app.growth.constants import SOURCE_ID_RE
from app.growth.kb.embeddings import Embedder, LocalHashEmbedder
from app.growth.kb.freshness import expires_on
from app.growth.kb.sources import REGISTRY, REGISTRY_IDS, SourceRecord, require_known_tier
from app.growth.models import GrowthKbChunk

# 路径里出现这些片段就直接拒绝，不打开文件。
BLOCKED_PATH_MARKERS = (
    "tcm_medication",
    "kimi_prompt",
    ".env",
    "keystore",
    "id_rsa",
)


class IngestRefused(ValueError):
    """来源或正文不能进入增长知识库。消息里不回显正文。"""


def assert_source_allowed(path: str | None, text: str) -> None:
    if path:
        normalized = path.replace("\\", "/").lower()
        if any(marker in normalized for marker in BLOCKED_PATH_MARKERS):
            raise IngestRefused("refused source")
    if text and violation_codes(text):
        raise IngestRefused("refused content")


def ingest_path(session: Session, path: str, embedder: Embedder | None = None) -> list[str]:
    assert_source_allowed(path, "")
    file_path = Path(path)
    text = file_path.read_text(encoding="utf-8")
    return ingest_text(
        session,
        source_id="upload",
        text=text,
        license="unknown",
        tier="papers",
        url="",
        published_at=date.today().isoformat(),
        embedder=embedder,
    )


def ingest_text(
    session: Session,
    *,
    source_id: str,
    text: str,
    license: str,
    tier: str,
    url: str,
    published_at: str,
    embedder: Embedder | None = None,
    status: str | None = None,
) -> list[str]:
    if not SOURCE_ID_RE.fullmatch(source_id):
        raise IngestRefused("refused source")
    if not license.strip():
        raise IngestRefused("missing license")
    require_known_tier(tier)
    assert_source_allowed(None, text)
    cleaned = text.strip()
    if not cleaned:
        raise IngestRefused("empty source")

    embedder = embedder or LocalHashEmbedder()
    pieces = _chunks(cleaned)
    vectors = embedder.embed(pieces)
    today = date.today().isoformat()
    expiry = expires_on(published_at, tier)
    resolved_status = status or ("active" if source_id in REGISTRY_IDS else "candidate")
    if resolved_status not in {"active", "candidate", "archived"}:
        raise IngestRefused("refused source")

    chunk_ids: list[str] = []
    for index, (piece, vector) in enumerate(zip(pieces, vectors), start=1):
        chunk_id = f"{source_id}#c{index}"
        status_for_row = resolved_status
        existing = session.get(GrowthKbChunk, chunk_id)
        if existing is not None and existing.status == "active" and status_for_row == "candidate":
            status_for_row = "active"
        session.merge(
            GrowthKbChunk(
                chunk_id=chunk_id,
                source_id=source_id,
                text=piece,
                embedding_json=json.dumps(vector),
                license=license,
                published_at=published_at[:10],
                fetched_at=today,
                expires_at=expiry,
                tier=tier,
                status=status_for_row,
                url=url,
            )
        )
        chunk_ids.append(chunk_id)
    session.flush()
    return chunk_ids


def activate_source(session: Session, source_id: str) -> int:
    """人审通过后，候选块才变成可检索。正文再过一次红线。"""
    rows = (
        session.query(GrowthKbChunk)
        .filter(GrowthKbChunk.source_id == source_id, GrowthKbChunk.status == "candidate")
        .all()
    )
    if not rows:
        raise IngestRefused("nothing to activate")
    for row in rows:
        assert_source_allowed(None, row.text)
    for row in rows:
        row.status = "active"
    session.flush()
    return len(rows)


def seed_registry(session: Session, embedder: Embedder | None = None) -> list[str]:
    """把登记册里的内部摘要写入知识库。登记册本身已经过这版代码的评审。"""
    ids: list[str] = []
    for record in REGISTRY:
        ids.extend(_ingest_record(session, record, embedder))
    return ids


def _ingest_record(session: Session, record: SourceRecord, embedder: Embedder | None) -> list[str]:
    return ingest_text(
        session,
        source_id=record.source_id,
        text=record.summary,
        license=record.license,
        tier=record.tier,
        url=record.url,
        published_at=record.published_at,
        embedder=embedder,
        status="active",
    )


def _chunks(text: str, limit: int = 160) -> list[str]:
    if len(text) <= limit:
        return [text]
    pieces: list[str] = []
    start = 0
    while start < len(text):
        pieces.append(text[start : start + limit])
        start += limit
    return pieces
