"""
顺时 — 中药服药提醒与禁忌管理 API
提供中成药数据库、服药提醒、药物相互作用检查。
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
        "constitution_suitable": ["yin_deficiency", "kidney_yin_deficiency"],
        "timing": "饭后",
        "food_taboos": ["萝卜", "浓茶", "咖啡"],
        "drug_interactions_warning": [
            {"drug": "麻黄", "warning": "不可同用，易致阴虚加重"},
            {"drug": "附子", "warning": "相反，不宜配伍"},
        ],
        "dosage_note": "每次 6-9g，一日 2-3 次，温开水送服",
        "duration_typical": "4-8 周见效，可长期服用",
        "tcm_function": "滋阴补肾，清热",
        "caution": "脾胃虚弱、腹泻者慎用；感冒发热期间停用",
    },
    "med_002": {
        "id": "med_002",
        "name": "金匮肾气丸",
        "category": "补阳",
        "constitution_suitable": ["yang_deficiency", "kidney_yang_deficiency"],
        "timing": "饭前",
        "food_taboos": ["冷饮", "浓茶", "萝卜"],
        "drug_interactions_warning": [
            {"drug": "凉茶", "warning": "不可同用，相反相克"},
        ],
        "dosage_note": "每次 6-9g，一日 2-3 次，温开水送服",
        "duration_typical": "4-8 周见效，可长期服用",
        "tcm_function": "温阳扶阳，利水通淋",
        "caution": "肾阴虚、口干者慎用；发热期间停用",
    },
    "med_003": {
        "id": "med_003",
        "name": "逍遥丸",
        "category": "疏肝理气",
        "constitution_suitable": ["liver_qi_stagnation", "liver_depression"],
        "timing": "饭前",
        "food_taboos": ["辛辣刺激", "油腻厚腻"],
        "drug_interactions_warning": [],
        "dosage_note": "每次 6-9g，一日 2-3 次，温开水送服",
        "duration_typical": "2-4 周见效，可长期服用",
        "tcm_function": "疏肝解郁，健脾益气",
        "caution": "肝血虚者配伍补血药更佳；月经过多者注意观察",
    },
    "med_004": {
        "id": "med_004",
        "name": "归脾丸",
        "category": "补气补血",
        "constitution_suitable": ["qi_blood_deficiency", "spleen_weakness"],
        "timing": "饭后",
        "food_taboos": ["萝卜", "浓茶"],
        "drug_interactions_warning": [
            {"drug": "寒凉药", "warning": "不宜同用，影响温阳效果"},
        ],
        "dosage_note": "每次 6-9g，一日 2-3 次，温开水送服",
        "duration_typical": "4-8 周见效，可长期服用",
        "tcm_function": "补气健脾，养血安神",
        "caution": "脾胃虚弱导致腹泻者谨慎；湿热体质者慎用",
    },
    "med_005": {
        "id": "med_005",
        "name": "补中益气丸",
        "category": "补气",
        "constitution_suitable": ["qi_deficiency", "spleen_weakness"],
        "timing": "饭后",
        "food_taboos": ["萝卜", "浓茶"],
        "drug_interactions_warning": [],
        "dosage_note": "每次 6-9g，一日 2-3 次，温开水送服",
        "duration_typical": "2-4 周见效",
        "tcm_function": "补中益气，健脾升阳",
        "caution": "高血压患者注意监测；湿热体质者慎用",
    },
    "med_006": {
        "id": "med_006",
        "name": "龙胆泻肝丸",
        "category": "清热",
        "constitution_suitable": ["damp_heat", "liver_heat"],
        "timing": "饭后",
        "food_taboos": ["油腻厚腻", "甘甜食物"],
        "drug_interactions_warning": [
            {"drug": "温阳药", "warning": "不宜同用，相反相克"},
        ],
        "dosage_note": "每次 6-9g，一日 2-3 次，温开水送服",
        "duration_typical": "2-4 周见效",
        "tcm_function": "清肝胆湿热，改善目赤肿痛",
        "caution": "脾阳虚弱者禁用；长期服用需监测肝功能",
    },
    "med_007": {
        "id": "med_007",
        "name": "血府逐瘀丸",
        "category": "活血",
        "constitution_suitable": ["blood_stasis", "qi_stagnation"],
        "timing": "饭后",
        "food_taboos": ["萝卜", "浓茶"],
        "drug_interactions_warning": [
            {"drug": "孕妇禁用药", "warning": "怀孕期间禁用"},
        ],
        "dosage_note": "每次 6-9g，一日 2-3 次，温开水送服",
        "duration_typical": "4-12 周见效",
        "tcm_function": "活血化瘀，行气止痛",
        "caution": "月经过多者慎用；孕妇禁用；有出血倾向者注意",
    },
    "med_008": {
        "id": "med_008",
        "name": "二陈丸",
        "category": "化痰",
        "constitution_suitable": ["phlegm_damp", "damp"],
        "timing": "饭后",
        "food_taboos": ["油腻厚腻", "甜腻食物"],
        "drug_interactions_warning": [],
        "dosage_note": "每次 6-9g，一日 2-3 次，温开水送服",
        "duration_typical": "2-4 周见效",
        "tcm_function": "化痰祛湿，健脾益气",
        "caution": "阴虚燥热者慎用；长期需配伍滋阴药",
    },
    "med_009": {
        "id": "med_009",
        "name": "香砂六君子丸",
        "category": "健脾",
        "constitution_suitable": ["spleen_weakness", "qi_deficiency"],
        "timing": "饭前",
        "food_taboos": ["萝卜", "浓茶"],
        "drug_interactions_warning": [],
        "dosage_note": "每次 6-9g，一日 2-3 次，温开水送服",
        "duration_typical": "2-4 周见效",
        "tcm_function": "健脾益气，消食和胃",
        "caution": "胃酸过多者慎用；需配伍调理脾胃药效果更佳",
    },
    "med_010": {
        "id": "med_010",
        "name": "参苓白术散",
        "category": "补气健脾",
        "constitution_suitable": ["qi_deficiency", "spleen_weakness", "damp"],
        "timing": "饭后",
        "food_taboos": ["萝卜", "浓茶"],
        "drug_interactions_warning": [],
        "dosage_note": "每次 6-9g，一日 2-3 次，温开水送服",
        "duration_typical": "2-4 周见效",
        "tcm_function": "补气健脾，祛湿益胃",
        "caution": "脾胃虚弱配伍食疗更佳；长期需定期评估",
    },
    "med_011": {
        "id": "med_011",
        "name": "玉屏风散",
        "category": "补气",
        "constitution_suitable": ["qi_deficiency", "wei_qi_deficiency"],
        "timing": "饭后",
        "food_taboos": ["萝卜", "浓茶"],
        "drug_interactions_warning": [],
        "dosage_note": "每次 6-9g，一日 2-3 次，温开水送服",
        "duration_typical": "2-4 周见效，可长期服用",
        "tcm_function": "补气固表，增强免疫",
        "caution": "容易感冒者适用；可预防性长期服用",
    },
    "med_012": {
        "id": "med_012",
        "name": "天王补心丹",
        "category": "补血安神",
        "constitution_suitable": ["heart_yin_deficiency", "heart_weakness"],
        "timing": "睡前",
        "food_taboos": ["浓茶", "咖啡", "刺激性饮料"],
        "drug_interactions_warning": [
            {"drug": "兴奋药", "warning": "不宜同用，影响睡眠"},
        ],
        "dosage_note": "每次 6-9g，一日 1-2 次，睡前温开水送服",
        "duration_typical": "1-2 周见效",
        "tcm_function": "滋阴补血，养心安神",
        "caution": "脾胃虚弱者配伍健脾药；长期需评估效果",
    },
    "med_013": {
        "id": "med_013",
        "name": "柏子养心丸",
        "category": "安神",
        "constitution_suitable": ["heart_weakness", "heart_yin_deficiency", "qi_stagnation"],
        "timing": "睡前",
        "food_taboos": ["浓茶", "咖啡"],
        "drug_interactions_warning": [],
        "dosage_note": "每次 6-9g，一日 1-2 次，睡前温开水送服",
        "duration_typical": "1-2 周见效",
        "tcm_function": "宁心安神，调理心脾",
        "caution": "脾阳虚弱者慎用；可与逍遥丸配伍",
    },
    "med_014": {
        "id": "med_014",
        "name": "川芎茶调丸",
        "category": "活血",
        "constitution_suitable": ["qi_stagnation", "blood_stasis"],
        "timing": "饭后",
        "food_taboos": ["萝卜", "浓茶"],
        "drug_interactions_warning": [
            {"drug": "孕妇禁用药", "warning": "怀孕期间禁用"},
        ],
        "dosage_note": "每次 6-9g，一日 2-3 次，温开水送服",
        "duration_typical": "2-4 周见效",
        "tcm_function": "活血行气，改善头痛",
        "caution": "月经过多者慎用；孕妇禁用；月经期间可停用",
    },
    "med_015": {
        "id": "med_015",
        "name": "板蓝根颗粒",
        "category": "清热",
        "constitution_suitable": ["heat", "damp_heat"],
        "timing": "饭后",
        "food_taboos": ["油腻厚腻", "甘甜食物"],
        "drug_interactions_warning": [
            {"drug": "温阳药", "warning": "不宜同用，相反相克"},
        ],
        "dosage_note": "每次 6-9g，一日 2-3 次，温开水送服",
        "duration_typical": "1-2 周见效",
        "tcm_function": "清热解毒，增强免疫",
        "caution": "脾阳虚弱者禁用；长期使用需医嘱指导",
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
                "warning": interaction["warning"],
            }

    # 检查 med2 中是否提到了 med1
    for interaction in med2.get("drug_interactions_warning", []):
        if med1["name"] in interaction["drug"] or "相反" in interaction["warning"]:
            return {
                "has_interaction": True,
                "medicine_1": med1["name"],
                "medicine_2": med2["name"],
                "warning": interaction["warning"],
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
                "warning": "两种药物相反相克，不宜同用",
            }

    return {
        "has_interaction": False,
        "medicine_1": med1["name"],
        "medicine_2": med2["name"],
        "warning": "无明显相互作用",
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
            "food_taboos": medicine.get("food_taboos", []),
            "drug_interactions_warning": medicine.get("drug_interactions_warning", []),
            "lifestyle_cautions": [
                "避免过度疲劳",
                "保证充足睡眠",
                "避免长时间对着电脑或手机",
                "适度运动",
                "避免过度压力和焦虑",
            ],
            "general_caution": medicine.get("caution", ""),
            "dosage_note": medicine.get("dosage_note", ""),
            "timing": medicine.get("timing", ""),
        },
    }
