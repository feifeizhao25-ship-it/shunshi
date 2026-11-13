"""检索前按来源有效期过滤。

过了 valid_until 的片段不再进入现行引用。膳食指南 2022 版在 2026-12-31 之后仍可附在回答里，
但必须带版本说明，并且不能当作现行的唯一依据。这里不调用模型，也不读取 LIBRARY_FRESHNESS 开关。
"""

from __future__ import annotations

from datetime import date

REVISION_NOTICE = "新版修订中，以下为 2022 版"
EDITION_2022 = "2022"
# 与 evidence.MIN_RELEVANCE 相同：低于它的片段不当作来源。
MIN_RELEVANCE = 0.06


def edition_of(content: str, meta: dict | None = None) -> str:
    """从已有文稿里读出版本。没有写明年号时不编一个。"""
    meta = meta or {}
    recorded = str(meta.get("edition") or "")
    if recorded:
        return recorded
    text = content or ""
    if "膳食指南" in text and "2022" in text:
        return EDITION_2022
    return ""


def select_verified(query: str, *, today: date, top_k: int = 3, lang: str = "cn") -> dict:
    """在全部得分里挑已核验片段，先按 valid_until 丢掉过期来源，再决定要不要附上 2022 版说明。"""
    from .embedder import get_embedder
    from .knowledge_base import cn_kb, gl_kb, load_knowledge_bases
    from .retriever import is_expired

    load_knowledge_bases()
    kb = cn_kb if lang == "cn" else gl_kb
    if not kb.loaded or not kb.chunks:
        raise RuntimeError("国内知识库未加载" if lang == "cn" else "International knowledge base not loaded")
    ranked = get_embedder(lang).query(query, top_k=len(kb.chunks))
    window: list[tuple[object, float, bool]] = []
    for idx, score in ranked:
        if score < MIN_RELEVANCE:
            break
        chunk = kb.chunks[idx]
        meta = chunk.metadata
        if meta.get("evidence_status") != "verified_official":
            continue
        window.append((chunk, float(score), is_expired(meta, today)))
        if len(window) >= top_k:
            break
    current = [(chunk, score) for chunk, score, expired in window if not expired]
    expired_2022 = [
        (chunk, score)
        for chunk, score, expired in window
        if expired and edition_of(chunk.content, chunk.metadata) == EDITION_2022
    ]
    edition = ""
    if expired_2022 or any(edition_of(chunk.content, chunk.metadata) == EDITION_2022 for chunk, _ in current):
        edition = EDITION_2022
    notice = REVISION_NOTICE if expired_2022 else ""
    parts: list[str] = []
    if expired_2022:
        excerpt = "\n\n".join(chunk.content[:700] for chunk, _ in expired_2022)
        parts.append(notice + "\n" + excerpt)
    if current:
        parts.append("\n\n".join(chunk.content[:900] for chunk, _ in current))
    return {
        "text": "\n\n".join(parts),
        "edition": edition,
        "notice": notice,
        "sole_basis": not bool(expired_2022),
        "revision_in_progress": bool(expired_2022),
        "current": current,
        "expired_2022": expired_2022,
    }
