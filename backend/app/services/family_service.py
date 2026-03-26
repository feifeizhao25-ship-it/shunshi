"""
顺时 ShunShi - 家庭账户增强服务
家庭成员管理 + 健康概览 + 共享内容包

作者: Claw 🦅
日期: 2026-03-18
"""

import json
import logging
from datetime import datetime, timedelta
from typing import Optional, Dict, Any, List

from app.database.db import get_db

logger = logging.getLogger(__name__)


class FamilyService:
    """家庭账户增强服务"""

    def __init__(self):
        pass

    def get_family_overview(self, user_id: str, locale: str = "zh-CN") -> Dict[str, Any]:
        """
        获取家庭健康概览

        Args:
            user_id: 用户 ID
            locale: 语言

        Returns:
            家庭概览数据
        """
        conn = get_db()

        # 获取用户家庭
        family = self._get_user_family(conn, user_id)
        if not family:
            return {
                "success": True,
                "data": {
                    "family_name": "我的家庭" if locale != "en-US" else "My Family",
                    "member_count": 0,
                    "members": [],
                    "shared_contents": [],
                    "health_overview": {},
                }
            }

        family_id = family["family_id"]
        family_name = family["family_name"]

        # 获取家庭成员
        members = self._get_members(conn, family_id, user_id, locale)

        # 家庭健康概览
        health_overview = self._get_health_overview(conn, members, locale)

        # 共享内容包
        shared_contents = self._get_shared_contents(conn, family_id, locale)

        return {
            "success": True,
            "data": {
                "family_id": family_id,
                "family_name": family_name,
                "member_count": len(members),
                "members": members,
                "health_overview": health_overview,
                "shared_contents": shared_contents,
            }
        }

    def get_member_health_detail(
        self, user_id: str, member_id: str, locale: str = "zh-CN"
    ) -> Dict[str, Any]:
        """获取家庭成员健康详情"""
        conn = get_db()

        family = self._get_user_family(conn, user_id)
        if not family:
            return {"success": False, "error": "家庭不存在" if locale != "en-US" else "Family not found"}

        member = conn.execute(
            "SELECT * FROM family_relations WHERE id = ? AND family_id = ?",
            (member_id, family["family_id"]),
        ).fetchone()

        if not member:
            return {"success": False, "error": "成员不存在" if locale != "en-US" else "Member not found"}

        d = dict(member)
        
        # 获取成员体质建议
        constitution_advice = self._get_constitution_advice(conn, d.get("health_data", "{}"), locale)

        # 获取成员最近活动
        recent_activity = self._get_member_activity(conn, member_id)

        return {
            "success": True,
            "data": {
                "id": d["id"],
                "name": d.get("member_name", ""),
                "relation": d.get("relation", ""),
                "age": d.get("age", 0),
                "status": d.get("status", "normal"),
                "constitution_advice": constitution_advice,
                "recent_activity": recent_activity,
                "trend": self._get_member_trend(d.get("status", "normal")),
            }
        }

    def get_shared_content_pack(
        self, user_id: str, pack_type: str = "wellness", locale: str = "zh-CN"
    ) -> Dict[str, Any]:
        """获取家庭共享内容包"""
        conn = get_db()

        family = self._get_user_family(conn, user_id)
        if not family:
            return {"success": True, "data": {"items": []}}

        type_mapping = {
            "wellness": ("food_therapy", "exercise", "tea", "sleep_tip"),
            "exercise": ("exercise",),
            "diet": ("food_therapy", "tea"),
        }

        types = type_mapping.get(pack_type, type_mapping["wellness"])

        placeholders = ",".join(["?"] * len(types))
        rows = conn.execute(
            f"""SELECT * FROM contents 
                WHERE type IN ({placeholders}) AND locale = ?
                ORDER BY RANDOM() LIMIT 10""",
            (*types, locale),
        ).fetchall()

        def parse_json(val):
            if not val:
                return []
            try:
                return json.loads(val) if isinstance(val, str) else val
            except (json.JSONDecodeError, TypeError):
                return [val] if val else []

        items = []
        for r in rows:
            d = dict(r)
            items.append({
                "id": d["id"],
                "title": d["title"],
                "description": d.get("description", ""),
                "type": d["type"],
                "category": d.get("category", ""),
                "tags": parse_json(d.get("tags")),
                "difficulty": d.get("difficulty", ""),
                "duration": d.get("duration", ""),
                "is_premium": bool(d.get("is_premium", 0)),
            })

        return {
            "success": True,
            "data": {
                "pack_type": pack_type,
                "items": items,
                "total": len(items),
            }
        }

    def _get_user_family(self, conn, user_id: str) -> Optional[Dict[str, Any]]:
        """获取用户家庭"""
        row = conn.execute(
            "SELECT DISTINCT family_id, family_name FROM family_relations WHERE user_id = ?",
            (user_id,),
        ).fetchone()
        if row:
            return dict(row)
        return None

    def _get_members(self, conn, family_id: str, user_id: str, locale: str) -> List[Dict[str, Any]]:
        """获取家庭成员列表"""
        rows = conn.execute(
            "SELECT * FROM family_relations WHERE family_id = ? AND user_id = ?",
            (family_id, user_id),
        ).fetchall()

        members = []
        for r in rows:
            d = dict(r)
            health_data = {}
            try:
                health_data = json.loads(d.get("health_data", "{}")) if isinstance(d.get("health_data"), str) else (d.get("health_data") or {})
            except (json.JSONDecodeError, TypeError):
                pass

            members.append({
                "id": d["id"],
                "name": d.get("member_name", ""),
                "relation": d.get("relation", ""),
                "age": d.get("age", 0),
                "status": d.get("status", "normal"),
                "trend": self._get_member_trend(d.get("status", "normal")),
                "last_active_at": d.get("last_active_at"),
                "constitution": health_data.get("constitution", ""),
                "health_summary": health_data.get("summary", ""),
            })

        return members

    def _get_health_overview(self, conn, members: List[Dict], locale: str) -> Dict[str, Any]:
        """获取家庭健康概览"""
        if not members:
            return {}

        total = len(members)
        needs_attention = sum(1 for m in members if m["status"] in ("attention", "warning"))
        active_today = sum(1 for m in members if m.get("last_active_at") and
                          m["last_active_at"].startswith(datetime.now().strftime("%Y-%m-%d")))

        # 按关系统计
        by_relation = {}
        for m in members:
            rel = m.get("relation", "unknown")
            by_relation[rel] = by_relation.get(rel, 0) + 1

        if locale == "en-US":
            return {
                "total_members": total,
                "members_active_today": active_today,
                "members_needing_attention": needs_attention,
                "health_score": max(0, 100 - needs_attention * 20),
                "by_relation": by_relation,
            }

        return {
            "total_members": total,
            "members_active_today": active_today,
            "members_needing_attention": needs_attention,
            "health_score": max(0, 100 - needs_attention * 20),
            "by_relation": by_relation,
        }

    def _get_shared_contents(self, conn, family_id: str, locale: str) -> List[Dict[str, Any]]:
        """获取共享内容"""
        try:
            rows = conn.execute(
                """SELECT c.* FROM contents c
                   JOIN family_shared_contents fsc ON c.id = fsc.content_id
                   WHERE fsc.family_id = ? AND c.locale = ?
                   ORDER BY fsc.created_at DESC LIMIT 10""",
                (family_id, locale),
            ).fetchall()
            return [{"id": dict(r)["id"], "title": dict(r)["title"]} for r in rows]
        except Exception:
            return []

    def _get_constitution_advice(self, conn, health_data_raw: str, locale: str) -> Dict[str, Any]:
        """获取体质建议"""
        health_data = {}
        try:
            health_data = json.loads(health_data_raw) if isinstance(health_data_raw, str) else (health_data_raw or {})
        except (json.JSONDecodeError, TypeError):
            pass

        constitution = health_data.get("constitution", "")
        if not constitution:
            return {}

        # 从数据库获取体质信息
        try:
            row = conn.execute(
                "SELECT * FROM constitutions WHERE name = ?",
                (constitution,),
            ).fetchone()
            if row:
                d = dict(row)
                return {
                    "name": d["name"],
                    "description": d.get("description", ""),
                    "diet_advice": d.get("diet_advice", {}),
                    "exercise_advice": d.get("exercise_advice", {}),
                }
        except Exception:
            pass

        return {"name": constitution}

    def _get_member_activity(self, conn, member_id: str) -> List[Dict[str, Any]]:
        """获取成员最近活动"""
        try:
            rows = conn.execute(
                "SELECT * FROM care_status WHERE user_id = ? ORDER BY created_at DESC LIMIT 5",
                (member_id,),
            ).fetchall()
            return [
                {"date": dict(r)["date"], "mood": dict(r).get("mood"), "sleep_hours": dict(r).get("sleep_hours")}
                for r in rows
            ]
        except Exception:
            return []

    def _get_member_trend(self, status: str) -> str:
        """获取成员趋势"""
        return {
            "normal": "good",
            "attention": "attention",
            "warning": "attention",
            "inactive": "inactive",
        }.get(status, "good")


# 全局实例
family_service = FamilyService()
