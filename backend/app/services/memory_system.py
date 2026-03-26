"""
顺时 - 记忆系统
存储和检索用户偏好、习惯、情绪趋势、反思主题，
为AI对话提供个性化上下文。

记忆类型：
- preference: 偏好（饮食偏好、运动偏好等）
- habit: 习惯（作息规律、运动频率等）
- emotional_trend: 情绪趋势（近期情绪变化）
- reflection_theme: 反思主题（用户关注的话题）

作者: Claw 🦅
日期: 2026-03-17
"""

import sqlite3
import json
import time
import enum
import logging
from datetime import datetime
from typing import Optional, Dict, Any, List

from app.database.db import get_db

logger = logging.getLogger(__name__)


class MemoryType(enum.Enum):
    """记忆类型枚举"""
    PREFERENCE = "preference"
    HABIT = "habit"
    EMOTIONAL_TREND = "emotional_trend"
    REFLECTION_THEME = "reflection_theme"


class MemoryItem:
    """记忆项"""
    def __init__(
        self,
        id: str,
        user_id: str,
        memory_type: str,
        content: str,
        confidence: float = 1.0,
        source: str = "conversation",
        created_at: str = "",
        updated_at: str = "",
        metadata: Optional[Dict[str, Any]] = None,
    ):
        self.id = id
        self.user_id = user_id
        self.memory_type = memory_type
        self.content = content
        self.confidence = confidence
        self.source = source
        self.created_at = created_at
        self.updated_at = updated_at
        self.metadata = metadata or {}

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "user_id": self.user_id,
            "type": self.memory_type,
            "content": self.content,
            "confidence": self.confidence,
            "source": self.source,
            "created_at": self.created_at,
            "updated_at": self.updated_at,
            "metadata": self.metadata,
        }


# ==================== 记忆提取规则 ====================

# 简单的基于关键词的记忆提取规则
EXTRACTION_RULES = {
    MemoryType.PREFERENCE: {
        "keywords": [
            "喜欢", "不爱", "偏好", "不喜欢", "爱吃", "不吃",
            "习惯吃", "经常喝", "喜欢喝", "不爱喝",
            "爱运动", "不爱运动", "喜欢运动",
        ],
        "description": "饮食和运动偏好",
    },
    MemoryType.HABIT: {
        "keywords": [
            "每天", "经常", "通常", "总是", "从不", "很少",
            "作息", "几点睡", "几点起", "习惯", "规律",
            "每周", "每个月", "定期",
        ],
        "description": "生活习惯和规律",
    },
    MemoryType.EMOTIONAL_TREND: {
        "keywords": [
            "最近", "最近感觉", "心情", "焦虑", "压力大",
            "失眠", "睡不着", "开心", "低落", "烦躁",
            "疲惫", "精神不好", "情绪",
        ],
        "description": "情绪状态和趋势",
    },
    MemoryType.REFLECTION_THEME: {
        "keywords": [
            "思考", "关注", "担心", "在意", "重视",
            "健康", "养生", "长寿", "品质", "退休",
            "未来", "计划", "目标", "希望",
        ],
        "description": "关注的话题和反思",
    },
}


class MemorySystem:
    """用户记忆系统"""

    def _ensure_table(self):
        """确保记忆表存在（使用已有的user_memory表）"""
        conn = get_db()
        # user_memory表已在db.py中定义，这里确认索引
        try:
            conn.execute(
                "CREATE INDEX IF NOT EXISTS idx_user_memory_type ON user_memory(user_id, type)"
            )
            conn.commit()
        except Exception as e:
            logger.warning(f"创建索引失败（可能已存在）: {e}")

    def extract_preferences(self, conversation_text: str) -> List[Dict[str, Any]]:
        """
        从对话文本中提取潜在的记忆项

        Args:
            conversation_text: 对话文本

        Returns:
            提取到的候选记忆列表
        """
        candidates = []

        for memory_type, rule in EXTRACTION_RULES.items():
            for keyword in rule["keywords"]:
                if keyword in conversation_text:
                    # 简单提取：找到包含关键词的句子
                    candidates.append({
                        "type": memory_type.value,
                        "keyword": keyword,
                        "source": "auto_extract",
                        "description": rule["description"],
                    })
                    break  # 每种类型只匹配一次

        return candidates

    def update_user_memory(
        self,
        user_id: str,
        memory_type: str,
        content: str,
        confidence: float = 1.0,
        source: str = "conversation",
        metadata: Optional[Dict[str, Any]] = None,
    ) -> MemoryItem:
        """
        更新用户记忆

        如果相同类型和内容的记忆已存在，则更新confidence和时间戳；
        否则创建新记忆。

        Args:
            user_id: 用户ID
            memory_type: 记忆类型
            content: 记忆内容
            confidence: 置信度 (0-1)
            source: 来源
            metadata: 附加元数据

        Returns:
            MemoryItem
        """
        self._ensure_table()
        conn = get_db()

        # 检查是否已存在相似记忆
        existing = conn.execute(
            "SELECT id, confidence FROM user_memory WHERE user_id = ? AND type = ? AND content = ?",
            (user_id, memory_type, content),
        ).fetchone()

        if existing:
            # 更新已有记忆
            memory_id = existing["id"]
            old_confidence = existing["confidence"]
            # 置信度取加权平均
            new_confidence = min(1.0, (old_confidence + confidence) / 2)
            conn.execute(
                """UPDATE user_memory
                   SET confidence = ?, updated_at = datetime('now'), metadata = ?
                   WHERE id = ?""",
                (new_confidence, json.dumps(metadata or {}), memory_id),
            )
            conn.commit()
            return self._get_memory_by_id(memory_id)
        else:
            # 创建新记忆
            import uuid
            memory_id = str(uuid.uuid4())
            now = datetime.now().isoformat()
            conn.execute(
                """INSERT INTO user_memory (id, user_id, type, content, metadata)
                   VALUES (?, ?, ?, ?, ?)""",
                (memory_id, user_id, memory_type, content, json.dumps(metadata or {})),
            )
            conn.commit()
            return MemoryItem(
                id=memory_id,
                user_id=user_id,
                memory_type=memory_type,
                content=content,
                confidence=confidence,
                source=source,
                created_at=now,
                updated_at=now,
                metadata=metadata,
            )

    def _get_memory_by_id(self, memory_id: str) -> Optional[MemoryItem]:
        """根据ID获取记忆"""
        conn = get_db()
        row = conn.execute(
            "SELECT * FROM user_memory WHERE id = ?", (memory_id,)
        ).fetchone()
        if not row:
            return None
        row_dict = dict(row)
        metadata = {}
        if row_dict.get("metadata"):
            try:
                metadata = json.loads(row_dict["metadata"])
            except (json.JSONDecodeError, TypeError):
                pass
        return MemoryItem(
            id=row_dict["id"],
            user_id=row_dict["user_id"],
            memory_type=row_dict["type"],
            content=row_dict["content"],
            confidence=1.0,  # 原表没有confidence字段
            source="stored",
            created_at=row_dict["created_at"],
            updated_at=row_dict.get("updated_at", row_dict["created_at"]),
            metadata=metadata,
        )

    def get_user_context(self, user_id: str) -> Dict[str, Any]:
        """
        获取用户上下文（给AI对话使用）

        构建用户画像，包括偏好、习惯、情绪趋势、反思主题

        Args:
            user_id: 用户ID

        Returns:
            用户上下文字典
        """
        self._ensure_table()
        conn = get_db()

        memories = conn.execute(
            "SELECT * FROM user_memory WHERE user_id = ? ORDER BY created_at DESC",
            (user_id,),
        ).fetchall()

        if not memories:
            return {
                "user_id": user_id,
                "has_context": False,
                "preferences": [],
                "habits": [],
                "emotional_trends": [],
                "reflection_themes": [],
                "summary": "暂无用户记忆数据",
            }

        preferences = []
        habits = []
        emotional_trends = []
        reflection_themes = []

        for row in memories:
            row_dict = dict(row)
            metadata = {}
            if row_dict.get("metadata"):
                try:
                    metadata = json.loads(row_dict["metadata"])
                except (json.JSONDecodeError, TypeError):
                    pass

            item = {
                "id": row_dict["id"],
                "content": row_dict["content"],
                "type": row_dict["type"],
                "created_at": row_dict["created_at"],
                "metadata": metadata,
            }

            memory_type = row_dict["type"]
            if memory_type == MemoryType.PREFERENCE.value:
                preferences.append(item)
            elif memory_type == MemoryType.HABIT.value:
                habits.append(item)
            elif memory_type == MemoryType.EMOTIONAL_TREND.value:
                emotional_trends.append(item)
            elif memory_type == MemoryType.REFLECTION_THEME.value:
                reflection_themes.append(item)

        # 构建摘要
        summary_parts = []
        if preferences:
            pref_contents = [p["content"] for p in preferences[:5]]
            summary_parts.append(f"偏好: {'; '.join(pref_contents)}")
        if habits:
            habit_contents = [h["content"] for h in habits[:5]]
            summary_parts.append(f"习惯: {'; '.join(habit_contents)}")
        if emotional_trends:
            emotion_contents = [e["content"] for e in emotional_trends[:3]]
            summary_parts.append(f"情绪: {'; '.join(emotion_contents)}")
        if reflection_themes:
            theme_contents = [t["content"] for t in reflection_themes[:3]]
            summary_parts.append(f"关注: {'; '.join(theme_contents)}")

        return {
            "user_id": user_id,
            "has_context": True,
            "preferences": preferences,
            "habits": habits,
            "emotional_trends": emotional_trends,
            "reflection_themes": reflection_themes,
            "memory_count": len(memories),
            "summary": " | ".join(summary_parts) if summary_parts else "暂无明确记忆",
        }

    def get_recent_memories(
        self, user_id: str, limit: int = 20, memory_type: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """
        获取最近的记忆列表

        Args:
            user_id: 用户ID
            limit: 返回数量限制
            memory_type: 记忆类型过滤（可选）

        Returns:
            记忆字典列表
        """
        self._ensure_table()
        conn = get_db()

        if memory_type:
            rows = conn.execute(
                """SELECT * FROM user_memory
                   WHERE user_id = ? AND type = ?
                   ORDER BY created_at DESC LIMIT ?""",
                (user_id, memory_type, limit),
            ).fetchall()
        else:
            rows = conn.execute(
                """SELECT * FROM user_memory
                   WHERE user_id = ?
                   ORDER BY created_at DESC LIMIT ?""",
                (user_id, limit),
            ).fetchall()

        result = []
        for row in rows:
            row_dict = dict(row)
            metadata = {}
            if row_dict.get("metadata"):
                try:
                    metadata = json.loads(row_dict["metadata"])
                except (json.JSONDecodeError, TypeError):
                    pass
            result.append({
                "id": row_dict["id"],
                "user_id": row_dict["user_id"],
                "type": row_dict["type"],
                "content": row_dict["content"],
                "created_at": row_dict["created_at"],
                "metadata": metadata,
            })

        return result

    def delete_memory(self, memory_id: str, user_id: str) -> bool:
        """
        删除单条记忆（GDPR合规）

        Args:
            memory_id: 记忆ID
            user_id: 用户ID（权限校验）

        Returns:
            是否删除成功
        """
        conn = get_db()
        cursor = conn.execute(
            "DELETE FROM user_memory WHERE id = ? AND user_id = ?",
            (memory_id, user_id),
        )
        conn.commit()
        return cursor.rowcount > 0

    def delete_all_memories(self, user_id: str) -> int:
        """
        删除用户所有记忆（GDPR合规）

        Args:
            user_id: 用户ID

        Returns:
            删除的记忆数量
        """
        conn = get_db()
        cursor = conn.execute(
            "DELETE FROM user_memory WHERE user_id = ?", (user_id,)
        )
        conn.commit()
        return cursor.rowcount

    def get_memory_stats(self, user_id: str) -> Dict[str, Any]:
        """获取用户记忆统计"""
        conn = get_db()

        total = conn.execute(
            "SELECT COUNT(*) FROM user_memory WHERE user_id = ?",
            (user_id,),
        ).fetchone()[0]

        by_type = {}
        for mt in MemoryType:
            count = conn.execute(
                "SELECT COUNT(*) FROM user_memory WHERE user_id = ? AND type = ?",
                (user_id, mt.value),
            ).fetchone()[0]
            by_type[mt.value] = count

        return {
            "user_id": user_id,
            "total": total,
            "by_type": by_type,
        }


# 全局实例
memory_system = MemorySystem()
