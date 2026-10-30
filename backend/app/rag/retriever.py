"""
检索器模块
基于 TF-IDF 相似度检索知识库 chunks，支持过滤
"""
import logging
import re
from typing import Optional

from app.safety.efficacy import redact_efficacy_claims

from .knowledge_base import cn_kb, gl_kb, KnowledgeChunk
from .embedder import get_embedder

logger = logging.getLogger(__name__)

# 标题精确命中加权：用户问「立春…」时，标题就是「立春」的片段应排在最前。
# 自改进评测（app/self_improve/evals.py）显示纯 TF-IDF 的 top1 有据率只有 0.72。
_NUM = re.compile(r"^\s*(?:第[一二三四五六七八九十]+章[:：]\s*|[一二三四五六七八九十]+、\s*|\d+\.\s*)")
_PAREN = re.compile(r"[（(].*?[）)]")
_GENERIC_HEADINGS = frozenset({"说明", "简介", "概述", "注意事项", "总结", "前言", "备注"})
HEADING_BOOST = 0.5
STALE_PENALTY = 0.5


def _heading_topic(heading_path: list[str]) -> str:
    if not heading_path:
        return ""
    return _PAREN.sub("", _NUM.sub("", heading_path[-1])).strip()


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

        if meta.get("stale"):
            score *= STALE_PENALTY  # 来源已过期：降权，不删除，避免集体过期时问答变空白

        topic = _heading_topic(chunk.heading_path)
        if len(topic) >= 2 and topic not in _GENERIC_HEADINGS and topic in query:
            score += HEADING_BOOST

        filtered.append((idx, score))

    # 按调整后的分数排序并截取 top_k
    filtered.sort(key=lambda x: x[1], reverse=True)
    results = filtered[:top_k]

    return [
        {
            "chunk_id": kb.chunks[idx].chunk_id,
            "content": redact_efficacy_claims(kb.chunks[idx].content),
            "heading_path": kb.chunks[idx].heading_path,
            "metadata": kb.chunks[idx].metadata,
            "score": round(score, 4),
        }
        for idx, score in results
        if score > 0.01
    ]
