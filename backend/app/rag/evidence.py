"""只向生成模型提供已核验、未过期的官方知识片段（国内：中文官方资料；国际：英文官方资料）。

Only verified, unexpired official snippets are given to the model. The international
edition uses verified_global.md (CDC / WHO / NHS); it never cites the Chinese documents.

检索说明：原来只在「前 12 个候选」里挑已核验片段，而已核验片段只有寥寥几条，
几乎总是挤不进前 12，所以 17 次回答 sources 全为空。现在直接在全部片段的得分里挑
已核验的，并要求最低相关度，避免为了凑数附上无关来源。
"""

from datetime import date

from .embedder import get_embedder
from .knowledge_base import cn_kb, gl_kb

MIN_RELEVANCE = 0.06  # TF-IDF 余弦相似度下限：低于它的片段不当作来源


def _verified_chunks(lang: str, query: str, top_k: int) -> list[tuple[object, float]]:
    kb = cn_kb if lang == "cn" else gl_kb
    if not kb.loaded or not kb.chunks:
        raise RuntimeError("国内知识库未加载" if lang == "cn" else "International knowledge base not loaded")
    embedder = get_embedder(lang)
    ranked = embedder.query(query, top_k=len(kb.chunks))
    today = date.today()
    picked: list[tuple[object, float]] = []
    for idx, score in ranked:
        if score < MIN_RELEVANCE:
            break
        chunk = kb.chunks[idx]
        meta = chunk.metadata
        if meta.get("evidence_status") != "verified_official":
            continue
        if date.fromisoformat(meta["valid_until"]) < today:
            continue
        picked.append((chunk, float(score)))
        if len(picked) >= top_k:
            break
    return picked


REVIEW_DUE_DAYS = 30  # shown as "review due" once the source expires within this many days


def freshness(valid_until: str, today: date | None = None) -> tuple[str, int]:
    """("current" | "review_due" | "expired", days left). Expired sources are never picked; this keeps the label honest."""
    days = (date.fromisoformat(valid_until) - (today or date.today())).days
    if days < 0:
        return "expired", days
    return ("review_due" if days <= REVIEW_DUE_DAYS else "current"), days


def _details(picked, default_title: str, today: date | None = None) -> list[dict]:
    out = []
    for chunk, score in picked:
        meta = chunk.metadata
        state, days_left = freshness(meta["valid_until"], today)
        out.append(
            {
                "chunk_id": chunk.chunk_id,
                "title": chunk.heading_path[-1] if chunk.heading_path else default_title,
                "source_file": meta["source_file"],
                "evidence_status": meta["evidence_status"],
                "reviewed_at": meta["reviewed_at"],
                "valid_until": meta["valid_until"],
                "last_verified_at": meta["reviewed_at"],
                "freshness": state,
                "days_until_expiry": days_left,
                "relevance": round(score, 4),
                "url": _first_link(chunk.content),
            }
        )
    return out


def _first_link(content: str) -> str | None:
    for line in content.splitlines():
        for marker in ("链接：", "Link:"):
            if line.startswith(marker):
                return line[len(marker):].strip() or None
    return None


def _label_cn(item: dict) -> str:
    text = f"{item['title']}｜官方资料已核验｜复核日期 {item['reviewed_at']}"
    if item["freshness"] == "review_due":
        text += f"｜即将到期，需重新复核（有效期至 {item['valid_until']}）"
    return text


def _label_en(item: dict) -> str:
    text = f"{item['title']} | Official source, verified | Reviewed {item['reviewed_at']}"
    if item["freshness"] == "review_due":
        text += f" | Review due soon (valid until {item['valid_until']})"
    return text


def verified_cn_context(query: str, top_k: int = 3) -> tuple[str, list[str], list[dict]]:
    picked = _verified_chunks("cn", query, top_k)
    context = "\n\n".join(chunk.content[:900] for chunk, _ in picked)
    details = _details(picked, "官方健康资料")
    labels = [_label_cn(item) for item in details]
    return context, labels, details


def verified_global_context(query: str, top_k: int = 3) -> tuple[str, list[str], list[dict]]:
    picked = _verified_chunks("gl", query, top_k)
    context = "\n\n".join(chunk.content[:900] for chunk, _ in picked)
    details = _details(picked, "Official health information")
    labels = [_label_en(item) for item in details]
    return context, labels, details
