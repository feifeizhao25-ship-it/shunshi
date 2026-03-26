"""
顺时 ShunShi - 内容相关模型
包含 4 张表: ContentItem, ContentMedia, ContentTag, ContentTagRelation
"""
import enum
from typing import Optional

from sqlalchemy import String, Integer, Boolean, Text, ForeignKey, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .base import Base, IDMixin


# ==================== 枚举定义 ====================

class ContentType(str, enum.Enum):
    """内容类型"""
    food = "food"
    tea = "tea"
    acupoint = "acupoint"
    exercise = "exercise"
    sleep = "sleep"
    emotion = "emotion"
    solar_term = "solar_term"
    constitution = "constitution"


class ContentSeason(str, enum.Enum):
    """适用季节"""
    spring = "spring"
    summer = "summer"
    autumn = "autumn"
    winter = "winter"
    all = "all"


class ContentStatus(str, enum.Enum):
    """内容状态"""
    draft = "draft"
    published = "published"
    archived = "archived"


class MediaType(str, enum.Enum):
    """媒体类型"""
    image = "image"
    video = "video"
    audio = "audio"


# ==================== 模型定义 ====================

class ContentItem(IDMixin, Base):
    """内容条目表（食疗、茶饮、穴位、运动等）"""
    __tablename__ = "sa_content_items"

    title: Mapped[str] = mapped_column(
        String(200), nullable=False, comment="标题"
    )
    subtitle: Mapped[Optional[str]] = mapped_column(
        String(300), nullable=True, comment="副标题"
    )
    content_type: Mapped[str] = mapped_column(
        String(30), nullable=False, comment="内容类型: food/tea/acupoint/exercise/sleep/emotion/solar_term/constitution"
    )
    description: Mapped[Optional[str]] = mapped_column(
        Text, nullable=True, comment="详细描述"
    )
    steps: Mapped[Optional[dict]] = mapped_column(
        JSON, nullable=True, comment="步骤列表（JSON 数组）"
    )
    duration_minutes: Mapped[Optional[int]] = mapped_column(
        Integer, nullable=True, comment="时长（分钟）"
    )
    tags: Mapped[Optional[dict]] = mapped_column(
        JSON, nullable=True, comment="标签（JSON 数组）"
    )
    season: Mapped[Optional[str]] = mapped_column(
        String(20), nullable=True, comment="适用季节: spring/summer/autumn/winter/all"
    )
    constitution: Mapped[Optional[str]] = mapped_column(
        String(200), nullable=True, comment="适用体质（多个逗号分隔）"
    )
    best_time: Mapped[Optional[str]] = mapped_column(
        String(100), nullable=True, comment="最佳使用时间"
    )
    caution: Mapped[Optional[str]] = mapped_column(
        Text, nullable=True, comment="注意事项"
    )
    is_premium: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=False, comment="是否为付费内容"
    )
    status: Mapped[str] = mapped_column(
        String(20), nullable=False, default=ContentStatus.draft.value,
        comment="内容状态: draft/published/archived"
    )
    sort_order: Mapped[int] = mapped_column(
        Integer, nullable=False, default=0, comment="排序权重"
    )
    view_count: Mapped[int] = mapped_column(
        Integer, nullable=False, default=0, comment="浏览次数"
    )
    like_count: Mapped[int] = mapped_column(
        Integer, nullable=False, default=0, comment="点赞次数"
    )

    # ---- 关系 ----
    media: Mapped[list["ContentMedia"]] = relationship(
        "ContentMedia", back_populates="content", cascade="all, delete-orphan"
    )
    tag_relations: Mapped[list["ContentTagRelation"]] = relationship(
        "ContentTagRelation", back_populates="content", cascade="all, delete-orphan"
    )

    def __repr__(self) -> str:
        return f"<ContentItem id={self.id!r} title={self.title!r}>"


class ContentMedia(IDMixin, Base):
    """内容媒体表（图片、视频、音频）"""
    __tablename__ = "sa_content_media"

    content_id: Mapped[str] = mapped_column(
        ForeignKey("sa_content_items.id", ondelete="CASCADE"),
        nullable=False, index=True, comment="关联内容 ID"
    )
    media_type: Mapped[str] = mapped_column(
        String(20), nullable=False, comment="媒体类型: image/video/audio"
    )
    url: Mapped[str] = mapped_column(
        String(500), nullable=False, comment="媒体 URL（OSS）"
    )
    thumbnail_url: Mapped[Optional[str]] = mapped_column(
        String(500), nullable=True, comment="缩略图 URL"
    )
    duration_seconds: Mapped[Optional[int]] = mapped_column(
        Integer, nullable=True, comment="时长（秒，视频/音频）"
    )
    sort_order: Mapped[int] = mapped_column(
        Integer, nullable=False, default=0, comment="排序权重"
    )

    # ---- 关系 ----
    content: Mapped["ContentItem"] = relationship("ContentItem", back_populates="media")

    def __repr__(self) -> str:
        return f"<ContentMedia content_id={self.content_id!r} type={self.media_type!r}>"


class ContentTag(IDMixin, Base):
    """内容标签表"""
    __tablename__ = "sa_content_tags"

    name: Mapped[str] = mapped_column(
        String(100), unique=True, nullable=False, comment="标签名称（唯一）"
    )
    category: Mapped[Optional[str]] = mapped_column(
        String(50), nullable=True, comment="标签分类"
    )
    usage_count: Mapped[int] = mapped_column(
        Integer, nullable=False, default=0, comment="使用次数"
    )

    # ---- 关系 ----
    tag_relations: Mapped[list["ContentTagRelation"]] = relationship(
        "ContentTagRelation", back_populates="tag", cascade="all, delete-orphan"
    )

    def __repr__(self) -> str:
        return f"<ContentTag name={self.name!r}>"


class ContentTagRelation(IDMixin, Base):
    """内容-标签 多对多关联表"""
    __tablename__ = "sa_content_tag_relations"

    content_id: Mapped[str] = mapped_column(
        ForeignKey("sa_content_items.id", ondelete="CASCADE"),
        nullable=False, index=True, comment="关联内容 ID"
    )
    tag_id: Mapped[str] = mapped_column(
        ForeignKey("sa_content_tags.id", ondelete="CASCADE"),
        nullable=False, index=True, comment="关联标签 ID"
    )

    # ---- 关系 ----
    content: Mapped["ContentItem"] = relationship("ContentItem", back_populates="tag_relations")
    tag: Mapped["ContentTag"] = relationship("ContentTag", back_populates="tag_relations")

    def __repr__(self) -> str:
        return f"<ContentTagRelation content_id={self.content_id!r} tag_id={self.tag_id!r}>"
