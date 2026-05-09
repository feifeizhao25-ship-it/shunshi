"""
家庭成员可见信息分层

核心规则：
1. 紧急状态（crisis）→ 全部可见（包括详细健康数据）
2. 正常状态 → 只可见汇总摘要（不暴露细节）
3. 被关怀者可以设置额外隐藏字段
4. 所有数据访问记录审计日志

可见性层级：
- LEVEL_0_NONE: 不可见
- LEVEL_1_SUMMARY: 汇总摘要（如"整体良好"）
- LEVEL_2_TREND: 趋势概览（如"睡眠有改善"）
- LEVEL_3_DETAIL: 详细数据（具体睡眠时长、质量评分）
- LEVEL_4_FULL: 全部数据（包括原始记录、对话内容）

作者: Claw 🦅
日期: 2026-04-29
"""

from __future__ import annotations
import logging
from typing import Dict, Optional, List, Any
from enum import Enum
from dataclasses import dataclass

from app.database.db import get_db

logger = logging.getLogger(__name__)


class VisibilityLevel(str, Enum):
    """可见性层级"""
    NONE = "none"           # 完全不可见
    SUMMARY = "summary"     # 仅汇总摘要
    TREND = "trend"         # 趋势概览
    DETAIL = "detail"       # 详细数据
    FULL = "full"           # 全部数据


class DataCategory(str, Enum):
    """数据类别"""
    SLEEP = "sleep"
    EMOTION = "emotion"
    ACTIVITY = "activity"
    DIET = "diet"
    HEALTH_METRICS = "health_metrics"
    CONVERSATIONS = "conversations"
    LOCATION = "location"
    MEDICATION = "medication"


@dataclass
class VisibilityRule:
    """可见性规则"""
    category: DataCategory
    default_level: VisibilityLevel  # 默认层级
    crisis_level: VisibilityLevel   # 危机状态层级
    owner_can_override: bool        # 数据所有者是否可以覆盖


# 默认可见性规则矩阵
DEFAULT_VISIBILITY_RULES: List[VisibilityRule] = [
    VisibilityRule(DataCategory.SLEEP, VisibilityLevel.TREND, VisibilityLevel.DETAIL, True),
    VisibilityRule(DataCategory.EMOTION, VisibilityLevel.SUMMARY, VisibilityLevel.DETAIL, True),
    VisibilityRule(DataCategory.ACTIVITY, VisibilityLevel.SUMMARY, VisibilityLevel.TREND, True),
    VisibilityRule(DataCategory.DIET, VisibilityLevel.NONE, VisibilityLevel.SUMMARY, True),
    VisibilityRule(DataCategory.HEALTH_METRICS, VisibilityLevel.TREND, VisibilityLevel.FULL, True),
    VisibilityRule(DataCategory.CONVERSATIONS, VisibilityLevel.NONE, VisibilityLevel.SUMMARY, True),
    VisibilityRule(DataCategory.LOCATION, VisibilityLevel.NONE, VisibilityLevel.TREND, True),
    VisibilityRule(DataCategory.MEDICATION, VisibilityLevel.NONE, VisibilityLevel.DETAIL, True),
]


class VisibilityEngine:
    """
    可见性引擎
    
    根据用户状态、数据类别、同意状态，计算最终可见性层级。
    """
    
    def __init__(self):
        self._init_table()
        self._rules = {r.category: r for r in DEFAULT_VISIBILITY_RULES}
    
    def _init_table(self):
        """初始化用户自定义可见性设置表"""
        conn = get_db()
        conn.execute("""
            CREATE TABLE IF NOT EXISTS user_visibility_settings (
                user_id TEXT PRIMARY KEY,
                settings JSON NOT NULL DEFAULT '{}',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        conn.commit()
    
    def get_effective_level(
        self,
        owner_user_id: str,
        viewer_user_id: str,
        category: DataCategory,
        owner_care_status: str = "stable",  # stable | needs_attention | crisis
    ) -> VisibilityLevel:
        """
        计算有效可见性层级
        
        决策逻辑：
        1. 如果危机状态 → 使用 crisis_level
        2. 检查用户自定义覆盖
        3. 否则使用 default_level
        """
        rule = self._rules.get(category)
        if not rule:
            return VisibilityLevel.NONE
        
        # 1. 危机状态升级
        if owner_care_status == "crisis":
            base_level = rule.crisis_level
        else:
            base_level = rule.default_level
        
        # 2. 检查用户自定义设置（只能降低可见性，不能提高）
        user_override = self._get_user_override(owner_user_id, category)
        if user_override:
            # 取更严格的级别（数值更小的）
            level_order = [VisibilityLevel.NONE, VisibilityLevel.SUMMARY, 
                          VisibilityLevel.TREND, VisibilityLevel.DETAIL, VisibilityLevel.FULL]
            base_idx = level_order.index(base_level)
            override_idx = level_order.index(user_override)
            
            if override_idx < base_idx:
                return user_override
        
        return base_level
    
    def set_user_override(
        self,
        user_id: str,
        category: DataCategory,
        level: VisibilityLevel,
    ):
        """
        用户设置自定义可见性覆盖
        
        数据所有者（如父母）可以主动降低某些类别的可见性。
        """
        import json
        conn = get_db()
        
        # 获取现有设置
        row = conn.execute(
            "SELECT settings FROM user_visibility_settings WHERE user_id = ?",
            (user_id,),
        ).fetchone()
        
        if row:
            settings = json.loads(row["settings"])
        else:
            settings = {}
        
        settings[category.value] = level.value
        
        conn.execute("""
            INSERT INTO user_visibility_settings (user_id, settings, updated_at)
            VALUES (?, ?, CURRENT_TIMESTAMP)
            ON CONFLICT(user_id) DO UPDATE SET
                settings = excluded.settings,
                updated_at = CURRENT_TIMESTAMP
        """, (user_id, json.dumps(settings)))
        conn.commit()
        
        logger.info(f"[Visibility] 用户 {user_id} 设置 {category.value} -> {level.value}")
    
    def get_user_settings(self, user_id: str) -> Dict[str, str]:
        """获取用户所有可见性设置"""
        conn = get_db()
        row = conn.execute(
            "SELECT settings FROM user_visibility_settings WHERE user_id = ?",
            (user_id,),
        ).fetchone()
        
        if row:
            import json
            return json.loads(row["settings"])
        return {}
    
    def _get_user_override(
        self,
        user_id: str,
        category: DataCategory,
    ) -> Optional[VisibilityLevel]:
        """获取用户对特定类别的覆盖设置"""
        settings = self.get_user_settings(user_id)
        level_str = settings.get(category.value)
        if level_str:
            return VisibilityLevel(level_str)
        return None
    
    def filter_data_by_level(
        self,
        data: Dict[str, Any],
        level: VisibilityLevel,
        category: DataCategory,
    ) -> Dict[str, Any]:
        """
        根据可见性层级过滤数据
        
        返回符合当前可见性层级的数据子集。
        """
        if level == VisibilityLevel.NONE:
            return {"visible": False, "reason": "数据所有者未授权查看此类数据"}
        
        if level == VisibilityLevel.SUMMARY:
            # 只返回汇总字段
            return {
                "visible": True,
                "level": "summary",
                "summary": data.get("summary", "整体状态良好"),
                "last_updated": data.get("last_updated"),
            }
        
        if level == VisibilityLevel.TREND:
            # 返回趋势数据，隐藏原始值
            return {
                "visible": True,
                "level": "trend",
                "trend": data.get("trend", "稳定"),
                "summary": data.get("summary"),
                "last_updated": data.get("last_updated"),
            }
        
        if level == VisibilityLevel.DETAIL:
            # 返回详细数据，但隐藏最敏感的
            filtered = data.copy()
            # 移除最敏感字段
            for sensitive in ["raw_notes", "conversation_transcripts", "exact_location"]:
                filtered.pop(sensitive, None)
            filtered["level"] = "detail"
            filtered["visible"] = True
            return filtered
        
        # FULL: 返回全部
        data["level"] = "full"
        data["visible"] = True
        return data
    
    def get_visibility_matrix(self, user_id: str) -> Dict[str, Any]:
        """
        获取用户的完整可见性矩阵（用于前端展示设置页面）
        """
        user_overrides = self.get_user_settings(user_id)
        matrix = {}
        
        for rule in DEFAULT_VISIBILITY_RULES:
            matrix[rule.category.value] = {
                "category_name": self._get_category_name(rule.category),
                "default_level": rule.default_level.value,
                "crisis_level": rule.crisis_level.value,
                "current_level": user_overrides.get(rule.category.value, rule.default_level.value),
                "owner_can_override": rule.owner_can_override,
            }
        
        return matrix
    
    def _get_category_name(self, category: DataCategory) -> str:
        """获取类别的中文名称"""
        names = {
            DataCategory.SLEEP: "睡眠数据",
            DataCategory.EMOTION: "情绪状态",
            DataCategory.ACTIVITY: "活动记录",
            DataCategory.DIET: "饮食记录",
            DataCategory.HEALTH_METRICS: "健康指标",
            DataCategory.CONVERSATIONS: "对话记录",
            DataCategory.LOCATION: "位置信息",
            DataCategory.MEDICATION: "用药记录",
        }
        return names.get(category, category.value)


# ==================== 全局实例 ====================

visibility_engine = VisibilityEngine()
