"""
RAG API 路由
知识库查询、统计、个性化养生方案、体质分析
支持语义检索（Embedding + 向量数据库）和混合检索
"""
import logging
from typing import Optional

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from .knowledge_base import cn_kb, gl_kb
from .retriever import retrieve
from .personalizer import generate_personalized_plan, generate_daily_plan
from .constitution_analyzer import analyze_constitution
from .semantic_retriever import get_semantic_retriever, migrate_knowledge_base_to_vector_store
from .vector_store import get_vector_store
from .embedder_api import get_embedder

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/rag", tags=["RAG 知识库"])


# ==================== Request/Response Models ====================

class RAGQueryRequest(BaseModel):
    query: str = Field(..., description="查询文本", min_length=1, max_length=500)
    lang: str = Field(default="cn", description="语言: cn | gl")
    top_k: int = Field(default=5, ge=1, le=20, description="返回条数")
    filters: Optional[dict] = Field(default=None, description="过滤条件")


class SemanticQueryRequest(BaseModel):
    query: str = Field(..., description="查询文本", min_length=1, max_length=500)
    lang: str = Field(default="cn", description="语言: cn | gl")
    top_k: int = Field(default=5, ge=1, le=20, description="返回条数")
    filters: Optional[dict] = Field(default=None, description="过滤条件")


class HybridQueryRequest(BaseModel):
    query: str = Field(..., description="查询文本", min_length=1, max_length=500)
    lang: str = Field(default="cn", description="语言: cn | gl")
    top_k: int = Field(default=5, ge=1, le=20, description="返回条数")
    filters: Optional[dict] = Field(default=None, description="过滤条件")
    semantic_weight: float = Field(default=0.7, ge=0.0, le=1.0, description="语义检索权重")


class RAGQueryResponse(BaseModel):
    success: bool = True
    data: dict


class PersonalizedPlanRequest(BaseModel):
    user_id: str = Field(..., description="用户ID")
    lang: str = Field(default="cn", description="语言: cn | gl")


class ConstitutionAnalyzeRequest(BaseModel):
    answers: list[int] = Field(..., description="体质测试答案列表")
    lang: str = Field(default="cn", description="语言: cn | gl")


class MigrateRequest(BaseModel):
    lang: str = Field(default="cn", description="语言: cn | gl")


# ==================== Endpoints ====================

@router.post("/query")
async def rag_query(req: RAGQueryRequest):
    """
    知识库检索（TF-IDF 传统检索）

    根据查询文本检索相关知识库 chunks（关键词匹配）
    """
    if req.lang not in ("cn", "gl"):
        raise HTTPException(status_code=400, detail="lang must be 'cn' or 'gl'")

    chunks = retrieve(
        query=req.query,
        lang=req.lang,
        top_k=req.top_k,
        filters=req.filters,
    )

    return {
        "success": True,
        "data": {
            "query": req.query,
            "lang": req.lang,
            "retriever": "tfidf",
            "total": len(chunks),
            "chunks": [
                {
                    "chunk_id": c["chunk_id"],
                    "content": c["content"],
                    "heading_path": c.get("heading_path", ""),
                    "metadata": c["metadata"],
                    "score": c["score"],
                }
                for c in chunks
            ],
        },
    }


@router.post("/query/semantic")
async def rag_query_semantic(req: SemanticQueryRequest):
    """
    语义检索（Embedding + 向量数据库）

    基于语义相似度检索，理解同义词和近义词。
    需要先将知识库迁移到向量数据库（/migrate 端点）。
    """
    if req.lang not in ("cn", "gl"):
        raise HTTPException(status_code=400, detail="lang must be 'cn' or 'gl'")

    retriever = get_semantic_retriever()
    results = await retriever.retrieve(
        query=req.query,
        lang=req.lang,
        top_k=req.top_k,
        filters=req.filters,
    )

    return {
        "success": True,
        "data": {
            "query": req.query,
            "lang": req.lang,
            "retriever": "semantic",
            "total": len(results),
            "chunks": results,
        },
    }


@router.post("/query/hybrid")
async def rag_query_hybrid(req: HybridQueryRequest):
    """
    混合检索（语义 + TF-IDF 融合）

    结合语义检索和关键词检索的优势，使用 RRF 融合排序。
    """
    if req.lang not in ("cn", "gl"):
        raise HTTPException(status_code=400, detail="lang must be 'cn' or 'gl'")

    retriever = get_semantic_retriever()
    results = await retriever.hybrid_retrieve(
        query=req.query,
        lang=req.lang,
        top_k=req.top_k,
        filters=req.filters,
        semantic_weight=req.semantic_weight,
    )

    return {
        "success": True,
        "data": {
            "query": req.query,
            "lang": req.lang,
            "retriever": "hybrid",
            "semantic_weight": req.semantic_weight,
            "total": len(results),
            "chunks": results,
        },
    }


@router.post("/migrate")
async def rag_migrate(req: MigrateRequest):
    """
    迁移知识库到向量数据库

    将现有 Markdown 知识库转换为向量并存储到向量数据库中。
    只需执行一次，后续新增内容可增量添加。
    """
    if req.lang not in ("cn", "gl"):
        raise HTTPException(status_code=400, detail="lang must be 'cn' or 'gl'")

    try:
        count = await migrate_knowledge_base_to_vector_store(lang=req.lang)
        return {
            "success": True,
            "data": {
                "lang": req.lang,
                "migrated_count": count,
                "message": f"成功迁移 {count} 条知识库文档到向量数据库",
            },
        }
    except Exception as e:
        logger.error(f"[RAG] 知识库迁移失败: {e}")
        raise HTTPException(status_code=500, detail=f"Migration failed: {e}")


@router.get("/health")
async def rag_health():
    """
    RAG 系统健康检查

    检查向量数据库、Embedding 服务、知识库状态。
    """
    try:
        vector_store = get_vector_store()
        embedder = get_embedder()
        
        return {
            "success": True,
            "data": {
                "vector_store": vector_store.health_check(),
                "embedder": embedder.health_check(),
                "knowledge_base": {
                    "cn": {"loaded": cn_kb.loaded, "chunks": len(cn_kb.chunks)},
                    "gl": {"loaded": gl_kb.loaded, "chunks": len(gl_kb.chunks)},
                },
            },
        }
    except Exception as e:
        logger.error(f"[RAG] 健康检查失败: {e}")
        raise HTTPException(status_code=500, detail=f"Health check failed: {e}")


@router.get("/categories")
async def rag_categories():
    """获取知识库所有分类"""
    cn_cats = cn_kb.get_categories()
    gl_cats = gl_kb.get_categories()

    return {
        "success": True,
        "data": {
            "cn": {"categories": cn_cats, "chunk_count": len(cn_kb.chunks)},
            "gl": {"categories": gl_cats, "chunk_count": len(gl_kb.chunks)},
        },
    }


@router.get("/stats")
async def rag_stats():
    """获取知识库统计信息"""
    return {
        "success": True,
        "data": {
            "cn": cn_kb.get_stats(),
            "gl": gl_kb.get_stats(),
        },
    }


@router.post("/personalized-plan")
async def personalized_plan(req: PersonalizedPlanRequest):
    """
    生成个性化养生方案

    基于用户画像、当前时空上下文和知识库检索
    """
    if req.lang not in ("cn", "gl"):
        raise HTTPException(status_code=400, detail="lang must be 'cn' or 'gl'")

    try:
        plan = await generate_personalized_plan(req.user_id, lang=req.lang)
        return {
            "success": True,
            "data": plan,
        }
    except Exception as e:
        logger.error(f"[RAG] 生成个性化方案失败: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to generate plan: {e}")


@router.post("/personalized-plan/daily")
async def daily_plan(req: PersonalizedPlanRequest):
    """
    生成今日养生建议（简化版）
    """
    if req.lang not in ("cn", "gl"):
        raise HTTPException(status_code=400, detail="lang must be 'cn' or 'gl'")

    try:
        plan = await generate_daily_plan(req.user_id, lang=req.lang)
        return {
            "success": True,
            "data": plan,
        }
    except Exception as e:
        logger.error(f"[RAG] 生成今日方案失败: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to generate daily plan: {e}")


@router.post("/constitution-analyze")
async def constitution_analyze(req: ConstitutionAnalyzeRequest):
    """
    体质分析

    根据问卷答案分析体质类型，结合知识库给出个性化建议
    """
    if req.lang not in ("cn", "gl"):
        raise HTTPException(status_code=400, detail="lang must be 'cn' or 'gl'")

    if len(req.answers) < 5:
        raise HTTPException(status_code=400, detail="At least 5 answers required")

    try:
        result = analyze_constitution(req.answers, lang=req.lang)
        return {
            "success": True,
            "data": result,
        }
    except Exception as e:
        logger.error(f"[RAG] 体质分析失败: {e}")
        raise HTTPException(status_code=500, detail=f"Constitution analysis failed: {e}")
