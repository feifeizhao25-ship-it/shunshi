"""只向生成模型提供已核验、未过期的国内官方知识片段。"""

from datetime import date

from .knowledge_base import cn_kb
from .retriever import retrieve


def verified_cn_context(query: str, top_k: int = 3) -> tuple[str, list[str], list[dict]]:
    if not cn_kb.loaded or not cn_kb.chunks:
        raise RuntimeError("国内知识库未加载")
    candidates = retrieve(query, lang="cn", top_k=12)
    verified = [
        chunk
        for chunk in candidates
        if chunk["metadata"].get("evidence_status") == "verified_official"
        and date.fromisoformat(chunk["metadata"]["valid_until"]) >= date.today()
    ][:top_k]
    context = "\n\n".join(chunk["content"][:900] for chunk in verified)
    details = [
        {
            "chunk_id": chunk["chunk_id"],
            "title": chunk["heading_path"][-1] if chunk["heading_path"] else "官方健康资料",
            "source_file": chunk["metadata"]["source_file"],
            "evidence_status": chunk["metadata"]["evidence_status"],
            "reviewed_at": chunk["metadata"]["reviewed_at"],
            "valid_until": chunk["metadata"]["valid_until"],
        }
        for chunk in verified
    ]
    labels = [
        f"{item['title']}｜官方资料已核验｜复核日期 {item['reviewed_at']}"
        for item in details
    ]
    return context, labels, details
