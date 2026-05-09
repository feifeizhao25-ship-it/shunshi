"""
语义检索器 - 基于向量数据库 + Embedding 模型
替代原有的 TF-IDF 检索，提供语义级别的相似度搜索

作者: Claw 🦅
日期: 2026-04-29
"""

from __future__ import annotations
import logging
from typing import Optional, List, Dict, Any

from .embedder_api import get_embedder, EmbeddingClient
from .vector_store import get_vector_store, VectorStore, VectorDocument, SearchResult
from .knowledge_base import cn_kb, gl_kb, KnowledgeChunk

logger = logging.getLogger(__name__)


class SemanticRetriever:
    """
    语义检索器
    
    工作流程：
    1. 将查询文本转换为向量（Embedding）
    2. 在向量数据库中搜索相似向量
    3. 返回语义相似的结果（而非关键词匹配）
    
    优势：
    - 理解同义词、近义词
    - 支持跨语言检索
    - 可以处理语义相似但用词不同的情况
    """
    
    def __init__(
        self,
        embedder: Optional[EmbeddingClient] = None,
        vector_store: Optional[VectorStore] = None,
    ):
        self.embedder = embedder or get_embedder()
        self.vector_store = vector_store or get_vector_store()
    
    async def retrieve(
        self,
        query: str,
        lang: str = "cn",
        top_k: int = 5,
        filters: Optional[Dict[str, Any]] = None,
    ) -> List[Dict[str, Any]]:
        """
        语义检索
        
        Args:
            query: 查询文本
            lang: 语言（影响 embedding 模型选择）
            top_k: 返回条数
            filters: 元数据过滤条件
        
        Returns:
            检索结果列表，包含 content, score, metadata 等
        """
        try:
            # 1. 文本向量化
            embed_result = await self.embedder.embed(query)
            query_vector = embed_result.vectors[0]
            
            # 2. 向量搜索
            results = self.vector_store.search(
                query_vector=query_vector,
                top_k=top_k,
                filters=filters,
            )
            
            # 3. 格式化输出
            formatted = []
            for r in results:
                formatted.append({
                    "chunk_id": r.id,
                    "content": r.content,
                    "score": round(r.score, 4),
                    "metadata": r.metadata,
                    "retriever": "semantic",
                })
            
            logger.info(f"[SemanticRetriever] 查询: '{query[:30]}...' -> {len(formatted)} 条结果")
            return formatted
            
        except Exception as e:
            logger.error(f"[SemanticRetriever] 检索失败: {e}")
            # 降级到原有 TF-IDF 检索
            logger.warning("[SemanticRetriever] 降级到 TF-IDF 检索")
            from .retriever import retrieve as tfidf_retrieve
            return tfidf_retrieve(query=query, lang=lang, top_k=top_k, filters=filters)
    
    async def hybrid_retrieve(
        self,
        query: str,
        lang: str = "cn",
        top_k: int = 5,
        filters: Optional[Dict[str, Any]] = None,
        semantic_weight: float = 0.7,
    ) -> List[Dict[str, Any]]:
        """
        混合检索：语义检索 + TF-IDF 检索结果融合
        
        Args:
            semantic_weight: 语义检索的权重（0-1），剩余为 TF-IDF 权重
        """
        # 并行执行两种检索
        semantic_results = await self.retrieve(
            query=query, lang=lang, top_k=top_k * 2, filters=filters
        )
        
        from .retriever import retrieve as tfidf_retrieve
        tfidf_results = tfidf_retrieve(
            query=query, lang=lang, top_k=top_k * 2, filters=filters
        )
        
        # 融合结果（RRF - Reciprocal Rank Fusion）
        fused = self._reciprocal_rank_fusion(
            semantic_results, tfidf_results, semantic_weight
        )
        
        return fused[:top_k]
    
    def _reciprocal_rank_fusion(
        self,
        semantic_results: List[Dict[str, Any]],
        tfidf_results: List[Dict[str, Any]],
        semantic_weight: float,
        k: int = 60,
    ) -> List[Dict[str, Any]]:
        """
        Reciprocal Rank Fusion 结果融合
        
        score = sum(w_i / (k + rank_i))
        """
        scores = {}
        docs = {}
        
        # 语义检索结果
        for rank, doc in enumerate(semantic_results):
            doc_id = doc["chunk_id"]
            scores[doc_id] = scores.get(doc_id, 0) + semantic_weight / (k + rank)
            docs[doc_id] = doc
        
        # TF-IDF 结果
        for rank, doc in enumerate(tfidf_results):
            doc_id = doc["chunk_id"]
            scores[doc_id] = scores.get(doc_id, 0) + (1 - semantic_weight) / (k + rank)
            if doc_id not in docs:
                docs[doc_id] = doc
        
        # 排序
        sorted_ids = sorted(scores.keys(), key=lambda x: scores[x], reverse=True)
        
        result = []
        for doc_id in sorted_ids:
            doc = docs[doc_id].copy()
            doc["fusion_score"] = round(scores[doc_id], 4)
            result.append(doc)
        
        return result


# ==================== 知识库迁移工具 ====================

async def migrate_knowledge_base_to_vector_store(
    lang: str = "cn",
    batch_size: int = 50,
) -> int:
    """
    将现有知识库迁移到向量数据库
    
    Args:
        lang: "cn" 或 "gl"
        batch_size: 每批处理的文档数
    
    Returns:
        迁移的文档数量
    """
    embedder = get_embedder()
    store = get_vector_store()
    
    # 获取知识库
    kb = cn_kb if lang == "cn" else gl_kb
    if not kb.loaded or not kb.chunks:
        logger.warning(f"[Migrate] {lang} 知识库未加载")
        return 0
    
    total_migrated = 0
    
    # 分批处理
    for i in range(0, len(kb.chunks), batch_size):
        batch = kb.chunks[i:i + batch_size]
        
        # 生成 embedding
        texts = [chunk.content for chunk in batch]
        embed_result = await embedder.embed(texts)
        
        # 构建文档
        documents = []
        for j, chunk in enumerate(batch):
            doc = VectorDocument(
                id=chunk.chunk_id,
                content=chunk.content,
                vector=embed_result.vectors[j],
                metadata={
                    **chunk.metadata,
                    "heading_path": chunk.heading_path,
                    "lang": lang,
                },
            )
            documents.append(doc)
        
        # 存入向量库
        store.add(documents)
        total_migrated += len(documents)
        
        logger.info(f"[Migrate] 已迁移 {total_migrated}/{len(kb.chunks)} 条")
    
    logger.info(f"[Migrate] {lang} 知识库迁移完成: {total_migrated} 条")
    return total_migrated


# ==================== 全局实例 ====================

_semantic_retriever: Optional[SemanticRetriever] = None


def get_semantic_retriever() -> SemanticRetriever:
    """获取全局语义检索器"""
    global _semantic_retriever
    if _semantic_retriever is None:
        _semantic_retriever = SemanticRetriever()
    return _semantic_retriever


def init_semantic_retriever():
    """初始化语义检索器"""
    global _semantic_retriever
    _semantic_retriever = SemanticRetriever()
    logger.info("[SemanticRetriever] 已初始化")
