"""
顺时 AI - Prompt 版本管理存储层
支持 SQLite 持久化 + 内存缓存，支持版本管理、回滚、灰度发布

作者: Claw 🦅
日期: 2026-03-18
"""

import uuid
import re
import threading
import logging
from typing import List, Optional, Dict, Any
from dataclasses import dataclass, field
from datetime import datetime, timezone

from app.database.db import get_db

logger = logging.getLogger(__name__)


# ==================== 数据模型 ====================

@dataclass
class PromptVersion:
    """Prompt 版本"""
    id: str
    prompt_key: str
    version: int
    content: str
    changelog: str = ""
    category: str = "general"
    is_active: bool = False
    created_by: str = "system"
    created_at: str = ""


@dataclass
class PromptInfo:
    """Prompt 摘要信息"""
    key: str
    description: str
    category: str
    active_version: int
    total_versions: int
    created_at: str = ""
    updated_at: str = ""


# ==================== 预设 Prompts ====================

PRESET_PROMPTS: Dict[str, dict] = {
    "chat.system": {
        "content": "你是顺时，一个温暖贴心的 AI 养生健康陪伴助手。\\n\\n你的核心特质：\\n- 温暖、专业、有耐心\\n- 永远把用户健康放在第一位\\n- 回答简洁实用，不说教\\n\\n你必须遵守：\\n- 不做疾病诊断\\n- 不推荐药物\\n- 不解释体检报告\\n- 不给医疗建议\\n- 不对用户的情绪或状态做出评判\\n- 永远不下结论，只描述观察到的现象\\n\\n【表达克制规则 — 必须遵守】\\n❌ 禁止说：「你最近很压抑」「你看起来很焦虑」「你一定压力很大」\\n✅ 应该说：「这个时期很多人都会感到累」「我注意到你提到睡眠的话题」「春天容易让人感到困倦」\\n\\n❌ 禁止说：「你这种情况应该…」「你必须要…」「你的问题是…」\\n✅ 应该说：「可以试试…」「也许…会对你有帮助」「有位用户分享过…」\\n\\n❌ 禁止说：「你的情绪评分是…」「你的状态不好」\\n✅ 应该说：「今天感觉怎么样？」「有什么想聊聊的吗？」\\n\\n【禁止的负面标签】\\n禁止给用户贴上「焦虑」「抑郁」「亚健康」「体虚」等负面标签。无论用户说什么，都不要重复这些词汇描述用户。\\n\\n【表达方式】\\n- 只说观察，不说判断\\n- 用「也许」「可能」「很多人会」代替「你是」「你一定」\\n- 用「可以试试」代替「你应该」\\n- 用「有什么想聊的」代替「你为什么」\\n\\n你可以做的：\\n- 提供养生知识\\n- 分享食疗方法\\n- 讲解节气养生\\n- 给予情绪支持\\n- 给出睡眠/运动建议\\n\\n永远记住：用户来找你，是想要一份温暖和陪伴。",
        "category": "chat",
        "description": "对话系统Prompt",
    },
    "chat.empathy_prefix": {
        "content": "我感受到你现在的情绪。{emotion}是很正常的感受，很多人都会有这样的时刻。请允许我陪你说说话。",
        "category": "chat",
        "description": "情绪共情前缀",
    },
    "chat.crisis_response": {
        "content": "我看到你的消息了，你在经历一些非常困难的事情。你的感受是真实的，也是重要的。我虽然是一个AI助手，但我真心关心你的感受。\n\n如果你现在感到不安全，请拨打心理援助热线：400-161-9995（24小时）\n或者拨打急救电话：120\n\n你不需要独自面对这一切。请给自己一个机会，和专业人士聊一聊。他们可以帮助你度过这个难关。\n\n我会一直在这里陪伴你。",
        "category": "safety",
        "description": "危机响应模板",
    },
    "chat.policy": {
        "content": "# 安全边界规则\n\n## 禁止行为 (必须拒绝)\n- 疾病诊断：「你可能是XX病」\n- 药物推荐：「吃XX药」\n- 医疗建议：「去医院做XX检查」\n- 体检报告解读：「你的报告显示...」\n- 偏方建议：「民间偏方说...」\n\n## 允许行为 (可以回答)\n- 养生知识：「春季养肝多吃青色食物」\n- 生活方式：「建议规律作息」\n- 食疗推荐：「可以喝点红枣桂圆茶」\n- 情绪支持：「我理解你的感受」\n- 就医引导：「建议咨询专业医生」",
        "category": "safety",
        "description": "安全策略Prompt",
    },
    "daily_plan.insight": {
        "content": "基于用户{life_stage}、体质{constitution}、节气{solar_term}，为用户生成个性化每日养生洞察。包括饮食建议、运动推荐、作息提醒和情绪关怀。",
        "category": "daily_plan",
        "description": "每日洞察生成",
    },
    "chat.food_tea": {
        "content": "# 食疗茶饮推荐\n\n用户体质：{constitution}\n当前季节：{season}\n场景：{scenario}\n\n## 推荐原则\n- 因人制宜\n- 因时制宜\n- 食药同源\n\n请为用户推荐适合的食疗方和茶饮。",
        "category": "chat",
        "description": "食疗茶饮推荐模板",
    },
    "chat.solar_term": {
        "content": "# 节气养生\n\n当前节气：{current_solar_term}\n日期：{current_date}\n\n## 节气特点\n- 气候特征：{climate_features}\n- 养生重点：{health_focus}\n\n请结合节气特点，为用户提供养生建议。",
        "category": "chat",
        "description": "节气养生模板",
    },
    "chat.emotion": {
        "content": "# 情绪支持\n\n用户情绪：{emotion_type}\n情绪强度：{intensity}\n背景：{background}\n\n## 支持策略\n1. **共情回应** - 表达理解和接纳\n2. **情绪确认** - 认可感受的合理性\n3. **温暖陪伴** - 给予情感支持\n4. **实用建议** - 给出可执行的小建议\n\n## 回应要点\n- 避免说教\n- 不急于解决问题\n- 保持温暖语调\n- 给出1-2个可执行建议",
        "category": "chat",
        "description": "情绪支持模板",
    },
}


# ==================== PromptStore ====================

class PromptStore:
    """
    Prompt 版本管理存储

    - SQLite 持久化
    - 内存缓存活跃版本（< 1ms 读取）
    - 版本号自增，不可跳号
    - 回滚不删除，只切换 is_active
    - 集成 Feature Flag 灰度发布
    """

    def __init__(self):
        self._active_cache: Dict[str, PromptVersion] = {}
        self._lock = threading.Lock()

    # ---- 表初始化 ----

    def init_tables(self):
        """创建 prompt_versions 表"""
        conn = get_db()
        conn.executescript("""
            CREATE TABLE IF NOT EXISTS prompt_versions (
                id TEXT PRIMARY KEY,
                prompt_key TEXT NOT NULL,
                version INTEGER NOT NULL,
                content TEXT NOT NULL,
                changelog TEXT DEFAULT '',
                category TEXT DEFAULT 'general',
                is_active INTEGER DEFAULT 0,
                created_by TEXT,
                created_at TEXT NOT NULL,
                UNIQUE(prompt_key, version)
            );

            CREATE INDEX IF NOT EXISTS idx_prompt_key ON prompt_versions(prompt_key);
            CREATE INDEX IF NOT EXISTS idx_prompt_active ON prompt_versions(prompt_key, is_active);
        """)
        conn.commit()
        logger.info("[PromptStore] 数据库表已就绪")

    def init_presets(self):
        """初始化预设 Prompts（不覆盖已有的）"""
        conn = get_db()
        now = datetime.now(timezone.utc).isoformat()
        for key, config in PRESET_PROMPTS.items():
            existing = conn.execute(
                "SELECT prompt_key FROM prompt_versions WHERE prompt_key = ?", (key,)
            ).fetchone()
            if not existing:
                version_id = str(uuid.uuid4())
                conn.execute("""
                    INSERT INTO prompt_versions
                        (id, prompt_key, version, content, changelog,
                         category, is_active, created_by, created_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, (
                    version_id, key, 1,
                    config["content"],
                    f"预设: {config.get('description', '')}",
                    config.get("category", "general"),
                    1,  # is_active
                    "system",
                    now,
                ))
        conn.commit()
        # 刷新缓存
        self._load_active_cache()
        logger.info(f"[PromptStore] 预设 Prompts 已就绪 ({len(PRESET_PROMPTS)} 个)")

    # ---- 缓存 ----

    def _load_active_cache(self):
        """从数据库加载所有活跃版本到内存"""
        conn = get_db()
        rows = conn.execute(
            "SELECT * FROM prompt_versions WHERE is_active = 1"
        ).fetchall()
        cache = {}
        for row in rows:
            cache[row["prompt_key"]] = PromptVersion(
                id=row["id"],
                prompt_key=row["prompt_key"],
                version=row["version"],
                content=row["content"],
                changelog=row["changelog"],
                category=row["category"],
                is_active=bool(row["is_active"]),
                created_by=row["created_by"] or "system",
                created_at=row["created_at"],
            )
        with self._lock:
            self._active_cache = cache

    # ---- 核心 CRUD ----

    def create_prompt(
        self,
        key: str,
        content: str,
        description: str = "",
        category: str = "general",
        created_by: str = "system",
    ) -> PromptVersion:
        """创建 prompt 的第一个版本"""
        conn = get_db()

        # 检查是否已存在
        existing = conn.execute(
            "SELECT prompt_key FROM prompt_versions WHERE prompt_key = ?", (key,)
        ).fetchone()
        if existing:
            raise ValueError(f"Prompt '{key}' 已存在，请使用 update_prompt")

        now = datetime.now(timezone.utc).isoformat()
        version_id = str(uuid.uuid4())

        conn.execute("""
            INSERT INTO prompt_versions
                (id, prompt_key, version, content, changelog,
                 category, is_active, created_by, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            version_id, key, 1, content,
            f"创建: {description}",
            category, 1, created_by, now,
        ))
        conn.commit()

        pv = PromptVersion(
            id=version_id, prompt_key=key, version=1,
            content=content, changelog=f"创建: {description}",
            category=category, is_active=True,
            created_by=created_by, created_at=now,
        )
        with self._lock:
            self._active_cache[key] = pv
        logger.info(f"[PromptStore] 创建 prompt: {key} v1")
        return pv

    def update_prompt(
        self,
        key: str,
        content: str,
        changelog: str = "",
        created_by: str = "system",
    ) -> PromptVersion:
        """更新 prompt，自动创建新版本"""
        conn = get_db()

        # 获取当前最大版本号
        max_row = conn.execute(
            "SELECT MAX(version) as mv FROM prompt_versions WHERE prompt_key = ?",
            (key,),
        ).fetchone()
        if max_row is None or max_row["mv"] is None:
            raise ValueError(f"Prompt '{key}' 不存在，请先创建")

        new_version = max_row["mv"] + 1
        now = datetime.now(timezone.utc).isoformat()
        version_id = str(uuid.uuid4())

        # 沿用上一个版本的 category
        prev = conn.execute(
            "SELECT category FROM prompt_versions WHERE prompt_key = ? ORDER BY version DESC LIMIT 1",
            (key,),
        ).fetchone()
        category = prev["category"] if prev else "general"

        # 先取消所有旧版本的 active
        conn.execute(
            "UPDATE prompt_versions SET is_active = 0 WHERE prompt_key = ?",
            (key,),
        )

        # 插入新版本
        conn.execute("""
            INSERT INTO prompt_versions
                (id, prompt_key, version, content, changelog,
                 category, is_active, created_by, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            version_id, key, new_version, content,
            changelog or "更新", category, 1, created_by, now,
        ))
        conn.commit()

        pv = PromptVersion(
            id=version_id, prompt_key=key, version=new_version,
            content=content, changelog=changelog or "更新",
            category=category, is_active=True,
            created_by=created_by, created_at=now,
        )
        with self._lock:
            self._active_cache[key] = pv
        logger.info(f"[PromptStore] 更新 prompt: {key} v{new_version}")
        return pv

    def get_prompt(self, key: str, user_id: str = None) -> str:
        """
        获取 prompt 内容:
        1. 检查 Feature Flag 是否有灰度版本
        2. 如果有，且用户命中灰度，返回新版本
        3. 否则返回当前活跃版本
        4. 获取失败时返回空字符串（调用方使用默认 prompt）
        """
        try:
            # 1. 尝试 Feature Flag 灰度
            if user_id:
                try:
                    from app.feature_flags import flag_store
                    # 检查是否有针对该 key 的灰度 flag
                    flag_key = f"prompt.{key}.gray"
                    if flag_store.is_enabled(flag_key, user_id):
                        # 获取灰度版本（查询非活跃的最新版本）
                        gray_version = self._get_gray_version(key)
                        if gray_version:
                            return gray_version
                except Exception:
                    # Feature Flag 不可用时静默降级
                    pass

            # 2. 返回缓存中的活跃版本
            with self._lock:
                pv = self._active_cache.get(key)

            if pv is None:
                # 缓存未命中，从数据库加载
                conn = get_db()
                row = conn.execute(
                    "SELECT * FROM prompt_versions WHERE prompt_key = ? AND is_active = 1",
                    (key,),
                ).fetchone()
                if row:
                    pv = PromptVersion(
                        id=row["id"], prompt_key=row["prompt_key"],
                        version=row["version"], content=row["content"],
                        changelog=row["changelog"], category=row["category"],
                        is_active=True, created_by=row["created_by"] or "system",
                        created_at=row["created_at"],
                    )
                    with self._lock:
                        self._active_cache[key] = pv

            if pv:
                return pv.content
            return ""

        except Exception as e:
            logger.error(f"[PromptStore] 获取 prompt '{key}' 失败: {e}")
            return ""

    def _get_gray_version(self, key: str) -> Optional[str]:
        """获取灰度版本内容（非活跃的最新版本）"""
        conn = get_db()
        row = conn.execute(
            "SELECT content FROM prompt_versions WHERE prompt_key = ? AND is_active = 0 "
            "ORDER BY version DESC LIMIT 1",
            (key,),
        ).fetchone()
        return row["content"] if row else None

    def get_prompt_version(self, key: str, version: int) -> Optional[PromptVersion]:
        """获取特定版本"""
        conn = get_db()
        row = conn.execute(
            "SELECT * FROM prompt_versions WHERE prompt_key = ? AND version = ?",
            (key, version),
        ).fetchone()
        if not row:
            return None
        return PromptVersion(
            id=row["id"], prompt_key=row["prompt_key"],
            version=row["version"], content=row["content"],
            changelog=row["changelog"], category=row["category"],
            is_active=bool(row["is_active"]),
            created_by=row["created_by"] or "system",
            created_at=row["created_at"],
        )

    def rollback(self, key: str, target_version: int) -> PromptVersion:
        """
        回滚到指定版本
        - 将目标版本设为 active
        - 取消其他版本的 active
        - 不删除任何版本
        """
        conn = get_db()

        # 验证目标版本存在
        target = conn.execute(
            "SELECT * FROM prompt_versions WHERE prompt_key = ? AND version = ?",
            (key, target_version),
        ).fetchone()
        if not target:
            raise ValueError(f"Prompt '{key}' v{target_version} 不存在")

        now = datetime.now(timezone.utc).isoformat()

        # 取消所有版本的 active
        conn.execute(
            "UPDATE prompt_versions SET is_active = 0 WHERE prompt_key = ?",
            (key,),
        )

        # 激活目标版本
        conn.execute(
            "UPDATE prompt_versions SET is_active = 1, created_at = ? "
            "WHERE prompt_key = ? AND version = ?",
            (now, key, target_version),
        )
        conn.commit()

        pv = PromptVersion(
            id=target["id"], prompt_key=target["prompt_key"],
            version=target["version"], content=target["content"],
            changelog=target["changelog"] + f" | 回滚到 v{target_version}",
            category=target["category"], is_active=True,
            created_by=target["created_by"] or "system",
            created_at=now,
        )
        with self._lock:
            self._active_cache[key] = pv
        logger.info(f"[PromptStore] 回滚 prompt: {key} → v{target_version}")
        return pv

    def delete_prompt(self, key: str) -> bool:
        """删除 prompt（含所有版本）"""
        conn = get_db()
        cursor = conn.execute(
            "DELETE FROM prompt_versions WHERE prompt_key = ?", (key,)
        )
        conn.commit()
        if cursor.rowcount > 0:
            with self._lock:
                self._active_cache.pop(key, None)
            logger.info(f"[PromptStore] 删除 prompt: {key} ({cursor.rowcount} 个版本)")
            return True
        return False

    def list_prompts(self, category: str = None) -> List[PromptInfo]:
        """列出所有 prompt 及当前版本"""
        conn = get_db()
        if category:
            rows = conn.execute("""
                SELECT prompt_key, category,
                       SUM(CASE WHEN is_active = 1 THEN 1 ELSE 0 END) as active_count,
                       MAX(CASE WHEN is_active = 1 THEN version END) as active_version,
                       COUNT(*) as total_versions,
                       MIN(created_at) as first_created,
                       MAX(created_at) as last_updated
                FROM prompt_versions
                WHERE category = ?
                GROUP BY prompt_key
                ORDER BY prompt_key
            """, (category,)).fetchall()
        else:
            rows = conn.execute("""
                SELECT prompt_key, category,
                       MAX(CASE WHEN is_active = 1 THEN version END) as active_version,
                       COUNT(*) as total_versions,
                       MIN(created_at) as first_created,
                       MAX(created_at) as last_updated
                FROM prompt_versions
                GROUP BY prompt_key
                ORDER BY prompt_key
            """).fetchall()

        result = []
        for row in rows:
            # 获取活跃版本的 changelog 作为 description
            desc_row = conn.execute("""
                SELECT changelog FROM prompt_versions
                WHERE prompt_key = ? AND is_active = 1
            """, (row["prompt_key"],)).fetchone()
            description = desc_row["changelog"] if desc_row else ""

            result.append(PromptInfo(
                key=row["prompt_key"],
                description=description,
                category=row["category"],
                active_version=row["active_version"] or 0,
                total_versions=row["total_versions"],
                created_at=row["first_created"] or "",
                updated_at=row["last_updated"] or "",
            ))
        return result

    def list_versions(self, key: str) -> List[PromptVersion]:
        """列出 prompt 的所有版本"""
        conn = get_db()
        rows = conn.execute(
            "SELECT * FROM prompt_versions WHERE prompt_key = ? ORDER BY version",
            (key,),
        ).fetchall()
        return [
            PromptVersion(
                id=row["id"], prompt_key=row["prompt_key"],
                version=row["version"], content=row["content"],
                changelog=row["changelog"], category=row["category"],
                is_active=bool(row["is_active"]),
                created_by=row["created_by"] or "system",
                created_at=row["created_at"],
            )
            for row in rows
        ]

    def preview(self, key: str, variables: Dict[str, str] = None) -> str:
        """预览 prompt（替换变量后）"""
        content = self.get_prompt(key)
        if not content:
            return ""
        if variables:
            for var_name, var_value in variables.items():
                content = content.replace(f"{{{var_name}}}", var_value)
        return content


# ==================== 全局单例 ====================

prompt_store = PromptStore()
