"""
顺时 — 中成药文化科普与用药提醒 API
仅提供中成药名称的一般性文化科普与用户自设提醒；不提供剂量、频次、疗程、配伍或疗效建议，具体用药遵医嘱。
"""
from __future__ import annotations

from fastapi import APIRouter, HTTPException, Query
from typing import Optional, List
from datetime import datetime
from pydantic import BaseModel

router = APIRouter(prefix="/api/v1/medication", tags=["tcm_medication"])

# ─────────────────────────────────────────────────────────────────────────────
# 中成药数据库（15 种常见中成药）
# ─────────────────────────────────────────────────────────────────────────────
MEDICINES = {
    "med_001": {
        "id": "med_001",
        "name": "六味地黄丸",
        "category": "补阴",
        "general_info": "传统典籍收载的中成药名称，仅作传统文化科普，不构成诊断、用药或疗效建议。",
        "caution": "是否适合使用、如何使用，请遵医嘱或药品说明书，并咨询医师或药师；孕期、哺乳期、儿童、慢病及正在用药者应先咨询专业人员。",
    },
    "med_002": {
        "id": "med_002",
        "name": "金匮肾气丸",
        "category": "补阳",
        "general_info": "传统典籍收载的中成药名称，仅作传统文化科普，不构成诊断、用药或疗效建议。",
        "caution": "是否适合使用、如何使用，请遵医嘱或药品说明书，并咨询医师或药师；孕期、哺乳期、儿童、慢病及正在用药者应先咨询专业人员。",
    },
    "med_003": {
        "id": "med_003",
        "name": "逍遥丸",
        "category": "疏肝理气",
        "general_info": "传统典籍收载的中成药名称，仅作传统文化科普，不构成诊断、用药或疗效建议。",
        "caution": "是否适合使用、如何使用，请遵医嘱或药品说明书，并咨询医师或药师；孕期、哺乳期、儿童、慢病及正在用药者应先咨询专业人员。",
    },
    "med_005": {
        "id": "med_005",
        "name": "补中益气丸",
        "category": "补气",
        "general_info": "传统典籍收载的中成药名称，仅作传统文化科普，不构成诊断、用药或疗效建议。",
        "caution": "是否适合使用、如何使用，请遵医嘱或药品说明书，并咨询医师或药师；孕期、哺乳期、儿童、慢病及正在用药者应先咨询专业人员。",
    },
    "med_007": {
        "id": "med_007",
        "name": "血府逐瘀丸",
        "category": "活血",
        "general_info": "传统典籍收载的中成药名称，仅作传统文化科普，不构成诊断、用药或疗效建议。",
        "caution": "是否适合使用、如何使用，请遵医嘱或药品说明书，并咨询医师或药师；孕期、哺乳期、儿童、慢病及正在用药者应先咨询专业人员。",
    },
    "med_008": {
        "id": "med_008",
        "name": "二陈丸",
        "category": "化痰",
        "general_info": "传统典籍收载的中成药名称，仅作传统文化科普，不构成诊断、用药或疗效建议。",
        "caution": "是否适合使用、如何使用，请遵医嘱或药品说明书，并咨询医师或药师；孕期、哺乳期、儿童、慢病及正在用药者应先咨询专业人员。",
    },
    "med_013": {
        "id": "med_013",
        "name": "柏子养心丸",
        "category": "安神",
        "general_info": "传统典籍收载的中成药名称，仅作传统文化科普，不构成诊断、用药或疗效建议。",
        "caution": "是否适合使用、如何使用，请遵医嘱或药品说明书，并咨询医师或药师；孕期、哺乳期、儿童、慢病及正在用药者应先咨询专业人员。",
    },
    "med_015": {
        "id": "med_015",
        "name": "板蓝根颗粒",
        "category": "清热",
        "general_info": "传统典籍收载的中成药名称，仅作传统文化科普，不构成诊断、用药或疗效建议。",
        "caution": "是否适合使用、如何使用，请遵医嘱或药品说明书，并咨询医师或药师；孕期、哺乳期、儿童、慢病及正在用药者应先咨询专业人员。",
    },
}

# ─────────────────────────────────────────────────────────────────────────────
# 用药提醒数据（内存存储）
# ─────────────────────────────────────────────────────────────────────────────
_reminders: dict[str, list] = {}

# ─────────────────────────────────────────────────────────────────────────────
# 数据模型
# ─────────────────────────────────────────────────────────────────────────────


class ReminderCreate(BaseModel):
    """创建用药提醒的请求模型"""
    user_id: str
    medicine_id: str
    times_per_day: int
    start_date: str
    notes: Optional[str] = None


class ReminderResponse(BaseModel):
    """用药提醒响应模型"""
    reminder_id: str
    user_id: str
    medicine_id: str
    medicine_name: str
    times_per_day: int
    start_date: str
    notes: Optional[str] = None
    created_at: str


# ─────────────────────────────────────────────────────────────────────────────
# 辅助函数
# ─────────────────────────────────────────────────────────────────────────────

def _generate_reminder_id() -> str:
    """生成提醒 ID"""
    import uuid
    return f"reminder_{uuid.uuid4().hex[:8]}"


def _check_drug_interaction(med1_id: str, med2_id: str) -> dict:
    """检查两种药物是否有相互作用"""
    med1 = MEDICINES.get(med1_id)
    med2 = MEDICINES.get(med2_id)

    if not med1 or not med2:
        return None

    # 检查 med1 中是否提到了 med2
    for interaction in med1.get("drug_interactions_warning", []):
        if med2["name"] in interaction["drug"] or "相反" in interaction["warning"]:
            return {
                "has_interaction": True,
                "medicine_1": med1["name"],
                "medicine_2": med2["name"],
                "warning": "是否可同时使用请咨询医师或药师，本服务不提供配伍结论。",
            }

    # 检查 med2 中是否提到了 med1
    for interaction in med2.get("drug_interactions_warning", []):
        if med1["name"] in interaction["drug"] or "相反" in interaction["warning"]:
            return {
                "has_interaction": True,
                "medicine_1": med1["name"],
                "medicine_2": med2["name"],
                "warning": "是否可同时使用请咨询医师或药师，本服务不提供配伍结论。",
            }

    # 检查配伍禁忌的常见组合
    incompatible_pairs = [
        ("六味地黄丸", "麻黄"),
        ("金匮肾气丸", "凉茶"),
        ("龙胆泻肝丸", "温阳药"),
        ("板蓝根颗粒", "温阳药"),
    ]

    for med1_name, med2_name in incompatible_pairs:
        if (med1["name"] == med1_name and med2_name in med2["name"]) or \
           (med2["name"] == med1_name and med2_name in med1["name"]):
            return {
                "has_interaction": True,
                "medicine_1": med1["name"],
                "medicine_2": med2["name"],
                "warning": "是否可同时使用请咨询医师或药师，本服务不提供配伍结论。",
            }

    return {
        "has_interaction": False,
        "medicine_1": med1["name"],
        "medicine_2": med2["name"],
        "warning": "本服务不提供配伍结论，是否可同时使用请咨询医师或药师。",
    }


# ─────────────────────────────────────────────────────────────────────────────
# 端点
# ─────────────────────────────────────────────────────────────────────────────

@router.get("/medicines", summary="获取药品列表")
async def list_medicines(
    category: Optional[str] = Query(None, description="药品分类过滤"),
    constitution: Optional[str] = Query(None, description="体质过滤"),
):
    """返回中成药列表，支持按分类和体质过滤。"""
    medicines = list(MEDICINES.values())

    if category:
        medicines = [m for m in medicines if m["category"] == category]

    if constitution:
        medicines = [m for m in medicines if constitution in m["constitution_suitable"]]

    return {
        "success": True,
        "data": {
            "medicines": medicines,
            "total": len(medicines),
            "category_filter": category,
            "constitution_filter": constitution,
        },
    }


@router.get("/medicines/{med_id}", summary="获取药品详情")
async def get_medicine(med_id: str):
    """获取指定药品的完整信息（含完整禁忌）。"""
    medicine = MEDICINES.get(med_id)
    if not medicine:
        raise HTTPException(status_code=404, detail=f"Medicine '{med_id}' not found")

    return {"success": True, "data": medicine}


@router.post("/reminder", summary="创建用药提醒")
async def create_reminder(reminder_data: ReminderCreate):
    """创建用药提醒记录。"""
    # 验证药品存在
    if reminder_data.medicine_id not in MEDICINES:
        raise HTTPException(status_code=404, detail=f"Medicine '{reminder_data.medicine_id}' not found")

    # 生成提醒
    reminder_id = _generate_reminder_id()
    medicine = MEDICINES[reminder_data.medicine_id]

    reminder_record = {
        "reminder_id": reminder_id,
        "user_id": reminder_data.user_id,
        "medicine_id": reminder_data.medicine_id,
        "medicine_name": medicine["name"],
        "times_per_day": reminder_data.times_per_day,
        "start_date": reminder_data.start_date,
        "notes": reminder_data.notes,
        "created_at": datetime.now().isoformat(),
    }

    # 存储到内存
    if reminder_data.user_id not in _reminders:
        _reminders[reminder_data.user_id] = []
    _reminders[reminder_data.user_id].append(reminder_record)

    return {
        "success": True,
        "data": reminder_record,
    }


@router.get("/reminder/{user_id}", summary="获取用户的提醒列表")
async def get_user_reminders(user_id: str):
    """获取指定用户的所有用药提醒记录。"""
    user_reminders = _reminders.get(user_id, [])

    return {
        "success": True,
        "data": {
            "user_id": user_id,
            "reminders": user_reminders,
            "total": len(user_reminders),
        },
    }


@router.get("/check-interaction", summary="检查药物配伍禁忌")
async def check_drug_interaction(
    med1: str = Query(..., description="第一种药物 ID"),
    med2: str = Query(..., description="第二种药物 ID"),
):
    """检查两种药物是否存在相互作用或配伍禁忌。"""
    if med1 not in MEDICINES:
        raise HTTPException(status_code=404, detail=f"Medicine '{med1}' not found")
    if med2 not in MEDICINES:
        raise HTTPException(status_code=404, detail=f"Medicine '{med2}' not found")

    interaction = _check_drug_interaction(med1, med2)

    return {
        "success": True,
        "data": interaction,
    }


@router.get("/taboos/{med_id}", summary="获取药物完整禁忌")
async def get_medicine_taboos(med_id: str):
    """获取指定药物的完整禁忌信息（食物、药物、生活方式）。"""
    medicine = MEDICINES.get(med_id)
    if not medicine:
        raise HTTPException(status_code=404, detail=f"Medicine '{med_id}' not found")

    return {
        "success": True,
        "data": {
            "medicine_id": med_id,
            "medicine_name": medicine["name"],
            "general_caution": medicine.get("caution", ""),
        },
    }
