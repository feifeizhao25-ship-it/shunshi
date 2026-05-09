"""
Embedding 模型客户端
支持多提供商：SiliconFlow / OpenAI / 本地模型

职责：
1. 将文本转换为向量（embedding）
2. 统一接口，支持多模型切换
3. 批量编码优化

作者: Claw 🦅
日期: 2026-04-29
"""

from __future__ import annotations
import os
import logging
from typing import List, Optional, Union
from dataclasses import dataclass

logger = logging.getLogger(__name__)


@dataclass
class EmbeddingResult:
    """Embedding 结果"""
    vectors: List[List[float]]  # 每个文本的向量
    model: str
    dimensions: int
    total_tokens: int = 0


class EmbeddingClient:
    """
    Embedding 客户端统一接口
    
    支持后端:
    - siliconflow: SiliconFlow Embedding API (BAAI/bge-large-zh-v1.5)
    - openai: OpenAI text-embedding-3-small
    - local: sentence-transformers (本地，无网络依赖)
    """
    
    SUPPORTED_PROVIDERS = ["siliconflow", "openai", "local"]
    
    # 默认模型映射
    DEFAULT_MODELS = {
        "siliconflow": "BAAI/bge-large-zh-v1.5",
        "openai": "text-embedding-3-small",
        "local": "BAAI/bge-small-zh-v1.5",
    }
    
    # 维度映射
    DIMENSIONS = {
        "BAAI/bge-large-zh-v1.5": 1024,
        "BAAI/bge-small-zh-v1.5": 512,
        "text-embedding-3-small": 1536,
        "text-embedding-3-large": 3072,
    }
    
    def __init__(
        self,
        provider: Optional[str] = None,
        model: Optional[str] = None,
        api_key: Optional[str] = None,
        base_url: Optional[str] = None,
    ):
        self.provider = provider or os.getenv("EMBEDDING_PROVIDER", "siliconflow")
        self.model = model or self.DEFAULT_MODELS.get(self.provider, "BAAI/bge-large-zh-v1.5")
        self.api_key = api_key or self._get_api_key()
        self.base_url = base_url or self._get_base_url()
        self.dimensions = self.DIMENSIONS.get(self.model, 1024)
        self._local_model = None
        
        if self.provider not in self.SUPPORTED_PROVIDERS:
            logger.warning(f"[Embedder] 未知 provider: {self.provider}, 回退到 siliconflow")
            self.provider = "siliconflow"
        
        logger.info(f"[Embedder] 初始化: provider={self.provider}, model={self.model}, dim={self.dimensions}")
    
    def _get_api_key(self) -> str:
        """获取 API Key"""
        if self.provider == "siliconflow":
            return os.getenv("SILICONFLOW_API_KEY", "")
        elif self.provider == "openai":
            return os.getenv("OPENAI_API_KEY", "")
        return ""
    
    def _get_base_url(self) -> str:
        """获取 Base URL"""
        if self.provider == "siliconflow":
            return os.getenv("SILICONFLOW_BASE_URL", "https://api.siliconflow.cn/v1")
        elif self.provider == "openai":
            return os.getenv("OPENAI_BASE_URL", "https://api.openai.com/v1")
        return ""
    
    async def embed(self, texts: Union[str, List[str]]) -> EmbeddingResult:
        """
        将文本转换为向量
        
        Args:
            texts: 单个文本或文本列表
        
        Returns:
            EmbeddingResult
        """
        if isinstance(texts, str):
            texts = [texts]
        
        if self.provider == "siliconflow":
            try:
                return await self._embed_siliconflow(texts)
            except Exception as e:
                logger.warning(f"[Embedder] SiliconFlow 失败，回退到本地模型: {e}")
                return await self._embed_local(texts)
        elif self.provider == "openai":
            try:
                return await self._embed_openai(texts)
            except Exception as e:
                logger.warning(f"[Embedder] OpenAI 失败，回退到本地模型: {e}")
                return await self._embed_local(texts)
        else:
            return await self._embed_local(texts)
    
    async def _embed_siliconflow(self, texts: List[str]) -> EmbeddingResult:
        """SiliconFlow Embedding API"""
        import aiohttp
        
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }
        
        payload = {
            "model": self.model,
            "input": texts,
            "encoding_format": "float",
        }
        
        async with aiohttp.ClientSession() as session:
            async with session.post(
                f"{self.base_url}/embeddings",
                headers=headers,
                json=payload,
                timeout=aiohttp.ClientTimeout(total=30),
            ) as response:
                if response.status != 200:
                    text = await response.text()
                    raise RuntimeError(f"SiliconFlow embedding failed: {response.status} - {text}")
                
                data = await response.json()
                vectors = [item["embedding"] for item in data["data"]]
                total_tokens = data.get("usage", {}).get("total_tokens", 0)
                
                return EmbeddingResult(
                    vectors=vectors,
                    model=self.model,
                    dimensions=self.dimensions,
                    total_tokens=total_tokens,
                )
    
    async def _embed_openai(self, texts: List[str]) -> EmbeddingResult:
        """OpenAI Embedding API"""
        import aiohttp
        
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }
        
        payload = {
            "model": self.model,
            "input": texts,
        }
        
        async with aiohttp.ClientSession() as session:
            async with session.post(
                f"{self.base_url}/embeddings",
                headers=headers,
                json=payload,
                timeout=aiohttp.ClientTimeout(total=30),
            ) as response:
                if response.status != 200:
                    text = await response.text()
                    raise RuntimeError(f"OpenAI embedding failed: {response.status} - {text}")
                
                data = await response.json()
                vectors = [item["embedding"] for item in data["data"]]
                total_tokens = data.get("usage", {}).get("total_tokens", 0)
                
                return EmbeddingResult(
                    vectors=vectors,
                    model=self.model,
                    dimensions=self.dimensions,
                    total_tokens=total_tokens,
                )
    
    async def _embed_local(self, texts: List[str]) -> EmbeddingResult:
        """
        本地 Embedding（sentence-transformers）
        
        首次调用时加载模型，后续复用。
        """
        if self._local_model is None:
            try:
                from sentence_transformers import SentenceTransformer
                self._local_model = SentenceTransformer(self.model)
                logger.info(f"[Embedder] 本地模型加载完成: {self.model}")
            except ImportError:
                logger.error("[Embedder] sentence-transformers 未安装，无法使用本地模型")
                raise RuntimeError(
                    "Local embedding requires: pip install sentence-transformers"
                )
        
        import numpy as np
        vectors = self._local_model.encode(texts, normalize_embeddings=True)
        vectors = vectors.tolist()
        
        return EmbeddingResult(
            vectors=vectors,
            model=self.model,
            dimensions=self.dimensions,
            total_tokens=sum(len(t) for t in texts),  # 粗略估计
        )
    
    def health_check(self) -> dict:
        """健康检查"""
        return {
            "provider": self.provider,
            "model": self.model,
            "dimensions": self.dimensions,
            "api_key_configured": bool(self.api_key),
            "base_url": self.base_url,
        }


# ==================== 全局实例 ====================

_embedder: Optional[EmbeddingClient] = None


def get_embedder() -> EmbeddingClient:
    """获取全局 Embedding 客户端"""
    global _embedder
    if _embedder is None:
        _embedder = EmbeddingClient()
    return _embedder


def init_embedder(
    provider: Optional[str] = None,
    model: Optional[str] = None,
    api_key: Optional[str] = None,
):
    """初始化 Embedding 客户端"""
    global _embedder
    _embedder = EmbeddingClient(provider=provider, model=model, api_key=api_key)
    logger.info(f"[Embedder] 已初始化: {_embedder.provider}/{_embedder.model}")
