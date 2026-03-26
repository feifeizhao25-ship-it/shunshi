"""
检索器模块
基于 TF-IDF 相似度检索知识库 chunks，支持过滤
"""
import logging
from typing import Optional

from .knowledge_base import cn_kb, gl_kb, KnowledgeChunk
from .embedder import get_embedder

logger = logging.getLogger(__name__)


def retrieve(
    query: str,
    lang: str = "cn",
    top_k: int = 5,
    filters: Optional[dict] = None,
) -> list[dict]:
    """
    检索知识库

    Args:
        query: 查询文本
        lang: 语言 "cn" | "gl"
        top_k: 返回条数
        filters: 过滤条件，支持:
            - season: 季节 (春/夏/秋/冬 或 spring/summer/autumn/winter)
            - category: 分类 (节气/体质/食疗/运动/穴位/茶饮/情绪 等)
            - constitution: 体质 (气虚/阳虚/阴虚/痰湿/湿热/血瘀/气郁/特禀/平和)

    Returns:
        list of {chunk_id, content, heading_path, metadata, score}
    """
    if filters is None:
        filters = {}

    # 获取知识库
    kb = cn_kb if lang == "cn" else gl_kb
    if not kb.loaded or not kb.chunks:
        logger.warning(f"[Retriever] {lang} 知识库未加载")
        return []

    # TF-IDF 检索
    embedder = get_embedder(lang)
    raw_results = embedder.query(query, top_k=top_k * 3)  # 多取一些，过滤后再截取

    # 应用过滤
    filtered = []
    for idx, score in raw_results:
        chunk = kb.chunks[idx]
        meta = chunk.metadata

        # 季节过滤
        if "season" in filters:
            filter_season = filters["season"]
            chunk_season = meta.get("season", "")
            if chunk_season and filter_season != chunk_season:
                # 如果没有匹配，降低权重但不完全排除
                score *= 0.3

        # 分类过滤
        if "category" in filters:
            filter_cat = filters["category"]
            chunk_cat = meta.get("category", "")
            if chunk_cat and filter_cat != chunk_cat:
                score *= 0.3

        # 体质过滤
        if "constitution" in filters:
            filter_const = filters["constitution"]
            chunk_const = meta.get("constitution", "")
            # 同时检查内容中是否包含该体质
            content_has = filter_const in chunk.content
            if not content_has and chunk_const != filter_const:
                score *= 0.3

        filtered.append((idx, score))

    # 按调整后的分数排序并截取 top_k
    filtered.sort(key=lambda x: x[1], reverse=True)
    results = filtered[:top_k]

    return [
        {
            "chunk_id": kb.chunks[idx].chunk_id,
            "content": kb.chunks[idx].content,
            "heading_path": kb.chunks[idx].heading_path,
            "metadata": kb.chunks[idx].metadata,
            "score": round(score, 4),
        }
        for idx, score in results
        if score > 0.01
    ]
