"""从已经构造好的 Settings 读增长配置。这里不调用 Settings()。"""

from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class GrowthConfig:
    arpu_yuan: float = 600
    embedding_provider: str = "local"
    reranker: str = "local"
    embedding_url: str = ""
    reranker_url: str = ""
    allow_publish: bool = False
    allow_paid_ads: bool = False

    @classmethod
    def from_settings(cls, settings) -> "GrowthConfig":
        return cls(
            arpu_yuan=float(settings.growth_arpu_yuan),
            embedding_provider=settings.growth_embedding_provider,
            reranker=settings.growth_reranker,
            embedding_url=settings.growth_embedding_url or "",
            reranker_url=settings.growth_reranker_url or "",
            allow_publish=bool(settings.growth_allow_publish),
            allow_paid_ads=bool(settings.growth_allow_paid_ads),
        )
