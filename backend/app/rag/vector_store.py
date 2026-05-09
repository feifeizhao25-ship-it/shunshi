"""
向量数据库抽象层
支持 ChromaDB（本地/内存）和 pgvector（PostgreSQL）

职责：
1. 统一的向量存储接口（add, search, delete, list）
2. 自动选择后端（优先 pgvector，回退 ChromaDB）
3. 集合（Collection）管理
4. 元数据过滤

作者: Claw 🦅
日期: 2026-04-29
"""

from __future__ import annotations
import os
import logging
from typing import List, Dict, Optional, Any, Tuple
from dataclasses import dataclass
from enum import Enum

logger = logging.getLogger(__name__)


@dataclass
class VectorDocument:
    """向量文档"""
    id: str
    content: str
    vector: List[float]
    metadata: Dict[str, Any]


@dataclass
class SearchResult:
    """搜索结果"""
    id: str
    content: str
    score: float  # 相似度分数
    metadata: Dict[str, Any]


class VectorStoreBackend(str, Enum):
    """向量存储后端"""
    CHROMADB = "chromadb"
    PGVECTOR = "pgvector"
    MEMORY = "memory"  # 纯内存（测试用）


class VectorStore:
    """
    向量数据库统一接口
    
    使用策略：
    1. 优先 pgvector（如果 PostgreSQL 可用且有 pgvector 扩展）
    2. 其次 ChromaDB（本地持久化）
    3. 最后内存（仅测试）
    """
    
    def __init__(
        self,
        collection_name: str = "shunshi_knowledge",
        backend: Optional[VectorStoreBackend] = None,
        embedding_dim: int = 1024,
        persist_dir: Optional[str] = None,
    ):
        self.collection_name = collection_name
        self.embedding_dim = embedding_dim
        self.persist_dir = persist_dir or os.path.join(
            os.path.dirname(os.path.dirname(os.path.dirname(__file__))),
            "data", "vector_db"
        )
        self._backend_impl = None
        
        # 自动选择后端
        if backend:
            self.backend = backend
        else:
            self.backend = self._auto_select_backend()
        
        logger.info(f"[VectorStore] 使用后端: {self.backend}, collection={collection_name}, dim={embedding_dim}")
    
    def _auto_select_backend(self) -> VectorStoreBackend:
        """自动选择最优后端"""
        # 1. 检查 pgvector
        if self._check_pgvector():
            logger.info("[VectorStore] 检测到 pgvector，使用 PostgreSQL 后端")
            return VectorStoreBackend.PGVECTOR
        
        # 2. 检查 ChromaDB
        if self._check_chromadb():
            logger.info("[VectorStore] 使用 ChromaDB 后端")
            return VectorStoreBackend.CHROMADB
        
        # 3. 回退到内存
        logger.warning("[VectorStore] 无外部向量数据库，回退到内存模式（仅测试）")
        return VectorStoreBackend.MEMORY
    
    def _check_pgvector(self) -> bool:
        """检查 pgvector 是否可用"""
        try:
            import psycopg2
            from psycopg2.extras import RealDictCursor
            
            db_url = os.getenv("DATABASE_URL", "")
            if not db_url or "postgresql" not in db_url.lower():
                return False
            
            conn = psycopg2.connect(db_url)
            cursor = conn.cursor()
            cursor.execute("SELECT 1 FROM pg_extension WHERE extname = 'vector'")
            has_vector = cursor.fetchone() is not None
            cursor.close()
            conn.close()
            
            return has_vector
        except Exception:
            return False
    
    def _check_chromadb(self) -> bool:
        """检查 ChromaDB 是否可用"""
        try:
            import chromadb
            return True
        except ImportError:
            return False
    
    def _get_impl(self):
        """获取后端实现（懒加载）"""
        if self._backend_impl is None:
            if self.backend == VectorStoreBackend.PGVECTOR:
                self._backend_impl = _PGVectorBackend(
                    collection_name=self.collection_name,
                    embedding_dim=self.embedding_dim,
                )
            elif self.backend == VectorStoreBackend.CHROMADB:
                self._backend_impl = _ChromaDBBackend(
                    collection_name=self.collection_name,
                    embedding_dim=self.embedding_dim,
                    persist_dir=self.persist_dir,
                )
            else:
                self._backend_impl = _MemoryBackend(
                    collection_name=self.collection_name,
                )
        return self._backend_impl
    
    # ============ 公共接口 ============
    
    def add(
        self,
        documents: List[VectorDocument],
    ) -> bool:
        """添加文档到向量库"""
        return self._get_impl().add(documents)
    
    def search(
        self,
        query_vector: List[float],
        top_k: int = 5,
        filters: Optional[Dict[str, Any]] = None,
    ) -> List[SearchResult]:
        """
        向量相似度搜索
        
        Args:
            query_vector: 查询向量
            top_k: 返回结果数量
            filters: 元数据过滤条件，如 {"category": "diet", "season": "spring"}
        
        Returns:
            按相似度排序的结果列表
        """
        return self._get_impl().search(query_vector, top_k, filters)
    
    def delete(self, ids: List[str]) -> bool:
        """删除文档"""
        return self._get_impl().delete(ids)
    
    def get(self, ids: List[str]) -> List[VectorDocument]:
        """根据 ID 获取文档"""
        return self._get_impl().get(ids)
    
    def count(self) -> int:
        """获取文档总数"""
        return self._get_impl().count()
    
    def clear(self) -> bool:
        """清空集合"""
        return self._get_impl().clear()
    
    def health_check(self) -> dict:
        """健康检查"""
        return {
            "backend": self.backend.value,
            "collection": self.collection_name,
            "embedding_dim": self.embedding_dim,
            "count": self.count(),
        }


# ==================== ChromaDB 后端 ====================

class _ChromaDBBackend:
    """ChromaDB 后端实现"""
    
    def __init__(self, collection_name: str, embedding_dim: int, persist_dir: str):
        import chromadb
        from chromadb.config import Settings
        
        self.client = chromadb.PersistentClient(
            path=persist_dir,
            settings=Settings(anonymized_telemetry=False),
        )
        self.collection = self.client.get_or_create_collection(
            name=collection_name,
            metadata={"hnsw:space": "cosine"},
        )
        logger.info(f"[ChromaDB] 集合初始化: {collection_name}")
    
    def add(self, documents: List[VectorDocument]) -> bool:
        if not documents:
            return True
        
        self.collection.add(
            ids=[d.id for d in documents],
            documents=[d.content for d in documents],
            embeddings=[d.vector for d in documents],
            metadatas=[d.metadata for d in documents],
        )
        return True
    
    def search(
        self,
        query_vector: List[float],
        top_k: int = 5,
        filters: Optional[Dict[str, Any]] = None,
    ) -> List[SearchResult]:
        results = self.collection.query(
            query_embeddings=[query_vector],
            n_results=top_k,
            where=filters,
            include=["documents", "metadatas", "distances"],
        )
        
        search_results = []
        for i in range(len(results["ids"][0])):
            # ChromaDB 返回的是距离（越小越相似），转换为相似度分数
            distance = results["distances"][0][i]
            score = 1.0 - distance  # 简单转换
            
            search_results.append(SearchResult(
                id=results["ids"][0][i],
                content=results["documents"][0][i],
                score=score,
                metadata=results["metadatas"][0][i],
            ))
        
        return search_results
    
    def delete(self, ids: List[str]) -> bool:
        self.collection.delete(ids=ids)
        return True
    
    def get(self, ids: List[str]) -> List[VectorDocument]:
        results = self.collection.get(
            ids=ids,
            include=["documents", "embeddings", "metadatas"],
        )
        
        docs = []
        for i in range(len(results["ids"])):
            docs.append(VectorDocument(
                id=results["ids"][i],
                content=results["documents"][i],
                vector=results["embeddings"][i],
                metadata=results["metadatas"][i],
            ))
        return docs
    
    def count(self) -> int:
        return self.collection.count()
    
    def clear(self) -> bool:
        self.client.delete_collection(self.collection.name)
        return True


# ==================== pgvector 后端 ====================

class _PGVectorBackend:
    """pgvector PostgreSQL 后端实现"""
    
    def __init__(self, collection_name: str, embedding_dim: int):
        import psycopg2
        
        self.collection_name = collection_name
        self.embedding_dim = embedding_dim
        self.table_name = f"vectors_{collection_name}"
        
        db_url = os.getenv("DATABASE_URL", "")
        self.conn = psycopg2.connect(db_url)
        self._init_table()
        
        logger.info(f"[PGVector] 表初始化: {self.table_name}")
    
    def _init_table(self):
        """初始化向量表"""
        cursor = self.conn.cursor()
        
        # 创建表
        cursor.execute(f"""
            CREATE TABLE IF NOT EXISTS {self.table_name} (
                id TEXT PRIMARY KEY,
                content TEXT NOT NULL,
                embedding vector({self.embedding_dim}),
                metadata JSONB DEFAULT '{{}}',
                created_at TIMESTAMP DEFAULT NOW()
            )
        """)
        
        # 创建向量索引（IVFFlat，适合中等规模数据）
        cursor.execute(f"""
            CREATE INDEX IF NOT EXISTS idx_{self.table_name}_embedding
            ON {self.table_name}
            USING ivfflat (embedding vector_cosine_ops)
            WITH (lists = 100)
        """)
        
        # 元数据索引
        cursor.execute(f"""
            CREATE INDEX IF NOT EXISTS idx_{self.table_name}_metadata
            ON {self.table_name} USING GIN (metadata)
        """)
        
        self.conn.commit()
        cursor.close()
    
    def add(self, documents: List[VectorDocument]) -> bool:
        if not documents:
            return True
        
        cursor = self.conn.cursor()
        
        for doc in documents:
            cursor.execute(f"""
                INSERT INTO {self.table_name} (id, content, embedding, metadata)
                VALUES (%s, %s, %s, %s)
                ON CONFLICT (id) DO UPDATE SET
                    content = EXCLUDED.content,
                    embedding = EXCLUDED.embedding,
                    metadata = EXCLUDED.metadata
            """, (doc.id, doc.content, doc.vector, json.dumps(doc.metadata)))
        
        self.conn.commit()
        cursor.close()
        return True
    
    def search(
        self,
        query_vector: List[float],
        top_k: int = 5,
        filters: Optional[Dict[str, Any]] = None,
    ) -> List[SearchResult]:
        cursor = self.conn.cursor()
        
        # 构建过滤条件
        where_clause = ""
        params = [query_vector, top_k]
        
        if filters:
            conditions = []
            for key, value in filters.items():
                conditions.append(f"metadata->>'{key}' = %s")
                params.insert(-1, value)  # 插入到 top_k 之前
            
            if conditions:
                where_clause = "WHERE " + " AND ".join(conditions)
        
        cursor.execute(f"""
            SELECT id, content, metadata,
                   1 - (embedding <=> %s::vector) as similarity
            FROM {self.table_name}
            {where_clause}
            ORDER BY embedding <=> %s::vector
            LIMIT %s
        """, (query_vector, query_vector, top_k))
        
        results = []
        for row in cursor.fetchall():
            results.append(SearchResult(
                id=row[0],
                content=row[1],
                score=row[3],
                metadata=row[2],
            ))
        
        cursor.close()
        return results
    
    def delete(self, ids: List[str]) -> bool:
        cursor = self.conn.cursor()
        cursor.execute(
            f"DELETE FROM {self.table_name} WHERE id = ANY(%s)",
            (ids,)
        )
        self.conn.commit()
        cursor.close()
        return True
    
    def get(self, ids: List[str]) -> List[VectorDocument]:
        cursor = self.conn.cursor()
        cursor.execute(
            f"SELECT id, content, embedding, metadata FROM {self.table_name} WHERE id = ANY(%s)",
            (ids,)
        )
        
        docs = []
        for row in cursor.fetchall():
            docs.append(VectorDocument(
                id=row[0],
                content=row[1],
                vector=row[2],
                metadata=row[3],
            ))
        
        cursor.close()
        return docs
    
    def count(self) -> int:
        cursor = self.conn.cursor()
        cursor.execute(f"SELECT COUNT(*) FROM {self.table_name}")
        count = cursor.fetchone()[0]
        cursor.close()
        return count
    
    def clear(self) -> bool:
        cursor = self.conn.cursor()
        cursor.execute(f"TRUNCATE TABLE {self.table_name}")
        self.conn.commit()
        cursor.close()
        return True


# ==================== 内存后端 ====================

class _MemoryBackend:
    """纯内存后端（仅测试用）"""
    
    def __init__(self, collection_name: str):
        self.collection_name = collection_name
        self._docs: Dict[str, VectorDocument] = {}
        logger.info(f"[MemoryVector] 集合初始化: {collection_name}")
    
    def add(self, documents: List[VectorDocument]) -> bool:
        for doc in documents:
            self._docs[doc.id] = doc
        return True
    
    def search(
        self,
        query_vector: List[float],
        top_k: int = 5,
        filters: Optional[Dict[str, Any]] = None,
    ) -> List[SearchResult]:
        import numpy as np
        
        query = np.array(query_vector)
        results = []
        
        for doc in self._docs.values():
            # 元数据过滤
            if filters:
                skip = False
                for key, value in filters.items():
                    if doc.metadata.get(key) != value:
                        skip = True
                        break
                if skip:
                    continue
            
            # 余弦相似度
            vec = np.array(doc.vector)
            similarity = np.dot(query, vec) / (np.linalg.norm(query) * np.linalg.norm(vec))
            
            results.append(SearchResult(
                id=doc.id,
                content=doc.content,
                score=float(similarity),
                metadata=doc.metadata,
            ))
        
        # 排序并截取 top_k
        results.sort(key=lambda x: x.score, reverse=True)
        return results[:top_k]
    
    def delete(self, ids: List[str]) -> bool:
        for id_ in ids:
            self._docs.pop(id_, None)
        return True
    
    def get(self, ids: List[str]) -> List[VectorDocument]:
        return [self._docs[id_] for id_ in ids if id_ in self._docs]
    
    def count(self) -> int:
        return len(self._docs)
    
    def clear(self) -> bool:
        self._docs.clear()
        return True


# ==================== 全局实例 ====================

import json  # for pgvector json dumps

vector_store: Optional[VectorStore] = None


def get_vector_store() -> VectorStore:
    """获取全局向量存储实例"""
    global vector_store
    if vector_store is None:
        vector_store = VectorStore()
    return vector_store


def init_vector_store(
    collection_name: str = "shunshi_knowledge",
    backend: Optional[str] = None,
    embedding_dim: int = 1024,
):
    """初始化向量存储"""
    global vector_store
    
    backend_enum = None
    if backend:
        backend_enum = VectorStoreBackend(backend)
    
    vector_store = VectorStore(
        collection_name=collection_name,
        backend=backend_enum,
        embedding_dim=embedding_dim,
    )
    logger.info(f"[VectorStore] 已初始化: {vector_store.backend.value}")
