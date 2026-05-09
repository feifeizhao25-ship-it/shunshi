"""
家庭共享同意管理器

管理家庭成员之间的数据共享同意状态：
- 被关怀者（父母）必须明确同意才能被子女查看数据
- 同意可以随时撤销
- 同意有有效期（默认1年）
- 每次重大数据共享操作前需确认同意状态

作者: Claw 🦅
日期: 2026-04-29
"""

from __future__ import annotations
import uuid
import logging
from typing import Dict, Optional, List
from dataclasses import dataclass
from datetime import datetime, timedelta
from enum import Enum

from app.database.db import get_db

logger = logging.getLogger(__name__)


class ConsentStatus(str, Enum):
    """同意状态"""
    PENDING = "pending"       # 待确认（已发送邀请，等待同意）
    ACTIVE = "active"         # 已同意
    PAUSED = "paused"         # 暂停（临时关闭共享）
    REVOKED = "revoked"       # 已撤销（永久关闭）
    EXPIRED = "expired"       # 已过期


@dataclass
class ConsentRecord:
    """同意记录"""
    id: str
    owner_user_id: str       # 数据所有者（被关怀者，如父母）
    viewer_user_id: str      # 数据查看者（关怀者，如子女）
    family_relation_id: str  # 关联的家庭关系ID
    status: ConsentStatus
    created_at: datetime
    updated_at: datetime
    expires_at: Optional[datetime]  # 过期时间
    consent_method: str      # 同意方式: in_app | sms | email | verbal
    notes: Optional[str] = None


class ConsentManager:
    """
    同意管理器
    
    核心规则：
    1. 任何数据共享前必须检查同意状态
    2. 被关怀者（数据所有者）有完全控制权
    3. 同意可撤销、可暂停、有过期时间
    4. 默认状态为 PENDING（未同意则不共享）
    """
    
    DEFAULT_EXPIRY_DAYS = 365  # 默认同意有效期1年
    
    def __init__(self):
        self._init_table()
    
    def _init_table(self):
        """初始化同意记录表"""
        conn = get_db()
        conn.execute("""
            CREATE TABLE IF NOT EXISTS family_privacy_consents (
                id TEXT PRIMARY KEY,
                owner_user_id TEXT NOT NULL,
                viewer_user_id TEXT NOT NULL,
                family_relation_id TEXT NOT NULL,
                status TEXT NOT NULL DEFAULT 'pending',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                expires_at TIMESTAMP,
                consent_method TEXT DEFAULT 'in_app',
                notes TEXT,
                UNIQUE(owner_user_id, viewer_user_id)
            )
        """)
        conn.execute("""
            CREATE INDEX IF NOT EXISTS idx_consents_owner 
            ON family_privacy_consents(owner_user_id)
        """)
        conn.execute("""
            CREATE INDEX IF NOT EXISTS idx_consents_viewer 
            ON family_privacy_consents(viewer_user_id)
        """)
        conn.commit()
    
    def create_consent_request(
        self,
        owner_user_id: str,
        viewer_user_id: str,
        family_relation_id: str,
        consent_method: str = "in_app",
    ) -> ConsentRecord:
        """
        创建同意请求
        
        当子女尝试绑定父母时，先创建同意请求，等待父母确认。
        """
        conn = get_db()
        
        # 检查是否已存在
        existing = conn.execute(
            "SELECT id FROM family_privacy_consents WHERE owner_user_id = ? AND viewer_user_id = ?",
            (owner_user_id, viewer_user_id),
        ).fetchone()
        
        if existing:
            raise ValueError("同意请求已存在")
        
        record_id = str(uuid.uuid4())
        now = datetime.now()
        expires = now + timedelta(days=self.DEFAULT_EXPIRY_DAYS)
        
        conn.execute("""
            INSERT INTO family_privacy_consents 
            (id, owner_user_id, viewer_user_id, family_relation_id, status, 
             created_at, updated_at, expires_at, consent_method)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (record_id, owner_user_id, viewer_user_id, family_relation_id,
              ConsentStatus.PENDING.value, now, now, expires, consent_method))
        conn.commit()
        
        logger.info(f"[Consent] 创建同意请求: {owner_user_id} -> {viewer_user_id}")
        
        return ConsentRecord(
            id=record_id,
            owner_user_id=owner_user_id,
            viewer_user_id=viewer_user_id,
            family_relation_id=family_relation_id,
            status=ConsentStatus.PENDING,
            created_at=now,
            updated_at=now,
            expires_at=expires,
            consent_method=consent_method,
        )
    
    def grant_consent(
        self,
        owner_user_id: str,
        viewer_user_id: str,
        notes: Optional[str] = None,
    ) -> ConsentRecord:
        """
        授予同意（由数据所有者操作，如父母确认同意）
        """
        conn = get_db()
        now = datetime.now()
        expires = now + timedelta(days=self.DEFAULT_EXPIRY_DAYS)
        
        conn.execute("""
            UPDATE family_privacy_consents
            SET status = ?, updated_at = ?, expires_at = ?, notes = ?
            WHERE owner_user_id = ? AND viewer_user_id = ?
        """, (ConsentStatus.ACTIVE.value, now, expires, notes,
              owner_user_id, viewer_user_id))
        conn.commit()
        
        logger.info(f"[Consent] 同意已授予: {owner_user_id} -> {viewer_user_id}")
        
        return self._get_record(owner_user_id, viewer_user_id)
    
    def revoke_consent(
        self,
        owner_user_id: str,
        viewer_user_id: str,
        reason: Optional[str] = None,
    ) -> ConsentRecord:
        """
        撤销同意（由数据所有者操作，永久关闭共享）
        """
        conn = get_db()
        now = datetime.now()
        
        conn.execute("""
            UPDATE family_privacy_consents
            SET status = ?, updated_at = ?, notes = ?
            WHERE owner_user_id = ? AND viewer_user_id = ?
        """, (ConsentStatus.REVOKED.value, now, reason,
              owner_user_id, viewer_user_id))
        conn.commit()
        
        logger.info(f"[Consent] 同意已撤销: {owner_user_id} -> {viewer_user_id}")
        
        return self._get_record(owner_user_id, viewer_user_id)
    
    def pause_consent(
        self,
        owner_user_id: str,
        viewer_user_id: str,
        reason: Optional[str] = None,
    ) -> ConsentRecord:
        """
        暂停共享（临时关闭，可随时恢复）
        """
        conn = get_db()
        now = datetime.now()
        
        conn.execute("""
            UPDATE family_privacy_consents
            SET status = ?, updated_at = ?, notes = ?
            WHERE owner_user_id = ? AND viewer_user_id = ?
        """, (ConsentStatus.PAUSED.value, now, reason,
              owner_user_id, viewer_user_id))
        conn.commit()
        
        logger.info(f"[Consent] 共享已暂停: {owner_user_id} -> {viewer_user_id}")
        
        return self._get_record(owner_user_id, viewer_user_id)
    
    def resume_consent(
        self,
        owner_user_id: str,
        viewer_user_id: str,
    ) -> ConsentRecord:
        """恢复共享（从暂停状态恢复）"""
        return self.grant_consent(owner_user_id, viewer_user_id, notes="从暂停恢复")
    
    def check_consent(
        self,
        owner_user_id: str,
        viewer_user_id: str,
    ) -> ConsentStatus:
        """
        检查同意状态
        
        返回当前同意状态，如果过期则自动更新为 EXPIRED。
        """
        record = self._get_record(owner_user_id, viewer_user_id)
        
        if not record:
            return ConsentStatus.REVOKED  # 无记录 = 未同意
        
        # 检查是否过期
        if record.status == ConsentStatus.ACTIVE and record.expires_at:
            if datetime.now() > record.expires_at:
                self._set_expired(record.id)
                return ConsentStatus.EXPIRED
        
        return record.status
    
    def can_access(
        self,
        owner_user_id: str,
        viewer_user_id: str,
    ) -> bool:
        """
        检查是否可以访问数据
        
        只有 ACTIVE 状态才允许访问。
        """
        status = self.check_consent(owner_user_id, viewer_user_id)
        return status == ConsentStatus.ACTIVE
    
    def list_consents_by_owner(
        self,
        owner_user_id: str,
    ) -> List[ConsentRecord]:
        """列出数据所有者所有的同意记录"""
        conn = get_db()
        rows = conn.execute(
            "SELECT * FROM family_privacy_consents WHERE owner_user_id = ? ORDER BY updated_at DESC",
            (owner_user_id,),
        ).fetchall()
        
        return [self._row_to_record(dict(row)) for row in rows]
    
    def list_consents_by_viewer(
        self,
        viewer_user_id: str,
    ) -> List[ConsentRecord]:
        """列出查看者所有的同意记录"""
        conn = get_db()
        rows = conn.execute(
            "SELECT * FROM family_privacy_consents WHERE viewer_user_id = ? ORDER BY updated_at DESC",
            (viewer_user_id,),
        ).fetchall()
        
        return [self._row_to_record(dict(row)) for row in rows]
    
    def _get_record(
        self,
        owner_user_id: str,
        viewer_user_id: str,
    ) -> Optional[ConsentRecord]:
        """获取单条记录"""
        conn = get_db()
        row = conn.execute(
            "SELECT * FROM family_privacy_consents WHERE owner_user_id = ? AND viewer_user_id = ?",
            (owner_user_id, viewer_user_id),
        ).fetchone()
        
        if row:
            return self._row_to_record(dict(row))
        return None
    
    def _set_expired(self, record_id: str):
        """将记录标记为过期"""
        conn = get_db()
        conn.execute(
            "UPDATE family_privacy_consents SET status = ?, updated_at = ? WHERE id = ?",
            (ConsentStatus.EXPIRED.value, datetime.now(), record_id),
        )
        conn.commit()
    
    def _row_to_record(self, row: Dict) -> ConsentRecord:
        """将数据库行转换为 ConsentRecord"""
        return ConsentRecord(
            id=row["id"],
            owner_user_id=row["owner_user_id"],
            viewer_user_id=row["viewer_user_id"],
            family_relation_id=row["family_relation_id"],
            status=ConsentStatus(row["status"]),
            created_at=datetime.fromisoformat(row["created_at"]),
            updated_at=datetime.fromisoformat(row["updated_at"]),
            expires_at=datetime.fromisoformat(row["expires_at"]) if row["expires_at"] else None,
            consent_method=row.get("consent_method", "in_app"),
            notes=row.get("notes"),
        )


# ==================== 全局实例 ====================

consent_manager = ConsentManager()
