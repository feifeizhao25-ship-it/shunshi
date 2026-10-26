"""增长知识库的来源登记。许可证和保鲜级别写在代码里，新增来源要经过人的评审。

这些摘要是内部备忘，不是法规原文。用药数据不在这里。
"""

from __future__ import annotations

from dataclasses import dataclass

from app.growth.kb.freshness import FRESHNESS_DAYS


@dataclass(frozen=True)
class SourceRecord:
    source_id: str
    title: str
    license: str
    tier: str
    url: str
    published_at: str
    summary: str


# published_at 是这条备忘写入登记册的日期，用来算保鲜，不是法规的公布日。
REGISTRY: tuple[SourceRecord, ...] = (
    SourceRecord(
        source_id="A01",
        title="生成合成内容需要显式标识",
        license="internal-summary",
        tier="laws",
        url="https://www.gov.cn/",
        published_at="2026-10-01",
        summary=(
            "面向公众发布的生成合成内容要能让人看出来是人工智能做的。"
            "增长草稿因此固定带上「本内容由人工智能生成。」这是内部备忘，不是条文摘抄。"
        ),
    ),
    SourceRecord(
        source_id="A02",
        title="外部平台发布要人确认",
        license="internal-summary",
        tier="platform_rules",
        url="https://www.gov.cn/",
        published_at="2026-10-01",
        summary=(
            "小红书、公众号、视频号和知乎的发布由人确认后才发出。"
            "系统只准备草稿和队列，不代替人点击发布。"
        ),
    ),
    SourceRecord(
        source_id="A03",
        title="节气作息只谈睡觉和起床",
        license="internal-summary",
        tier="papers",
        url="",
        published_at="2026-10-01",
        summary=(
            "选题围绕二十四节气的作息：早一点睡、固定起床、午间留白。"
            "不写服用方法，只帮助安排一天的节奏。"
        ),
    ),
    SourceRecord(
        source_id="A04",
        title="渠道效果只保留近四个周",
        license="internal-summary",
        tier="performance",
        url="",
        published_at="2026-10-01",
        summary="站内和推送的点击、注册、付费按周汇总。超过保鲜期的效果数据降权，再老就归档。",
    ),
)

REGISTRY_IDS = frozenset(record.source_id for record in REGISTRY)


def require_known_tier(tier: str) -> None:
    if tier not in FRESHNESS_DAYS:
        raise ValueError(f"unknown freshness tier: {tier}")
