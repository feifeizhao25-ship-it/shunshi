"""
TF-IDF 向量嵌入模块
中文用 jieba 分词，英文用 scikit-learn 默认 tokenizer
纯本地方案，无需 API key
"""
import logging
from typing import Optional

import jieba
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
import numpy as np

from .knowledge_base import KnowledgeBase, KnowledgeChunk

logger = logging.getLogger(__name__)


def _cn_tokenizer(text: str) -> list[str]:
    """中文分词器 - 使用 jieba"""
    words = jieba.lcut(text)
    # 过滤停用词和单字（保留有意义的词）
    stop_chars = set("的了是在有我你他她它们这那个一不也都很而会把被让给跟比等还会对才能")
    return [w for w in words if len(w) > 1 and w not in stop_chars]


class TFIDFEmbedder:
    """TF-IDF 向量嵌入器"""

    def __init__(self, knowledge_base: KnowledgeBase, lang: str):
        self.kb = knowledge_base
        self.lang = lang
        self.vectorizer: Optional[TfidfVectorizer] = None
        self.chunk_vectors: Optional[np.ndarray] = None
        self.fitted = False

    def fit(self):
        """训练 TF-IDF 模型"""
        if not self.kb.chunks:
            logger.warning(f"[Embedder] {self.lang} 知识库为空，跳过训练")
            return

        corpus = [chunk.content for chunk in self.kb.chunks]

        if self.lang == "cn":
            self.vectorizer = TfidfVectorizer(
                tokenizer=_cn_tokenizer,
                token_pattern=None,  # 禁用默认正则分词
                max_features=5000,
                ngram_range=(1, 2),
                min_df=1,
                max_df=0.95,
            )
        else:
            self.vectorizer = TfidfVectorizer(
                max_features=5000,
                ngram_range=(1, 2),
                min_df=1,
                max_df=0.95,
                stop_words="english",
            )

        self.chunk_vectors = self.vectorizer.fit_transform(corpus)
        self.fitted = True
        logger.info(f"[Embedder] {self.lang} TF-IDF 训练完成: vocabulary_size={len(self.vectorizer.vocabulary_)}")

    def query(self, query: str, top_k: int = 5) -> list[tuple[int, float]]:
        """
        查询相似 chunks

        Returns:
            list of (chunk_index, similarity_score) tuples, sorted by score desc
        """
        if not self.fitted or self.vectorizer is None:
            return []

        query_vector = self.vectorizer.transform([query])
        similarities = cosine_similarity(query_vector, self.chunk_vectors).flatten()

        # 获取 top_k 结果
        top_indices = np.argsort(similarities)[::-1][:top_k]

        results = []
        for idx in top_indices:
            score = float(similarities[idx])
            if score > 0.01:  # 过滤极低相关性
                results.append((int(idx), score))

        return results


# 全局 embedder 实例（延迟初始化）
_cn_embedder: Optional[TFIDFEmbedder] = None
_gl_embedder: Optional[TFIDFEmbedder] = None


def get_embedder(lang: str) -> TFIDFEmbedder:
    """获取对应语言的 embedder"""
    global _cn_embedder, _gl_embedder

    from .knowledge_base import cn_kb, gl_kb

    if lang == "cn":
        if _cn_embedder is None:
            _cn_embedder = TFIDFEmbedder(cn_kb, "cn")
        return _cn_embedder
    else:
        if _gl_embedder is None:
            _gl_embedder = TFIDFEmbedder(gl_kb, "gl")
        return _gl_embedder


def init_embedders():
    """初始化所有 embedder（启动时调用）"""
    global _cn_embedder, _gl_embedder
    from .knowledge_base import cn_kb, gl_kb

    if cn_kb.loaded:
        _cn_embedder = TFIDFEmbedder(cn_kb, "cn")
        _cn_embedder.fit()
    if gl_kb.loaded:
        _gl_embedder = TFIDFEmbedder(gl_kb, "gl")
        _gl_embedder.fit()
