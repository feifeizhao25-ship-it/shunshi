"""
顺时 — 产后恢复 API (shunshi-postpartum)
产后调理方案、月子养护、哺乳期饮食
"""

from fastapi import APIRouter, Query
from typing import Optional

router = APIRouter(prefix="/api/v1/postpartum", tags=["postpartum"])

POSTPARTUM_PHASES = {
    "week_1_2": {
        "phase": "产后第1-2周", "focus": "排恶露、促宫缩、补充气血",
        "diet": {
            "principle": "饮食宜清淡、易消化，补而不腻",
            "recommended": ["小米粥", "蛋花汤", "红糖水", "鸡蛋羹"],
            "avoid": ["生冷食物", "大补燥热食物", "过咸食物"]
        },
        "care": [
            "注意保暖，避免受风",
            "适当休息，减少下床活动",
            "注意恶露颜色和量",
            "预防产后抑郁，保持良好情绪"
        ],
        "tcm_herbs": ["益母草（排恶露）", "生化汤（活血化瘀）"]
    },
    "week_3_4": {
        "phase": "产后第3-4周", "focus": "补气血、促乳汁分泌",
        "diet": {
            "principle": "以补气养血、通乳为主",
            "recommended": ["猪蹄通草汤", "黄芪鸡汤", "红枣糯米粥"],
            "avoid": ["辛辣刺激", "酒精（影响哺乳）"]
        },
        "care": [
            "坚持母乳喂养",
            "适当室内轻活动",
            "注意乳房护理，预防乳腺炎"
        ],
        "tcm_herbs": ["黄芪", "当归", "通草（催乳）"]
    },
    "month_2_3": {
        "phase": "产后第2-3个月", "focus": "全面调理，恢复体力",
        "diet": {
            "principle": "均衡营养，逐步恢复正常饮食",
            "recommended": ["鱼汤", "排骨汤", "蔬菜水果", "全谷物"],
            "avoid": ["高糖高脂食物"]
        },
        "care": [
            "开始产后修复运动",
            "关注情绪状态",
            "坚持哺乳，补充钙质"
        ],
        "tcm_herbs": ["六味地黄丸（肾虚者）", "归脾丸（气血两虚者）"]
    }
}

LACTATION_FOODS = [
    {"name": "猪蹄", "benefit": "通乳下奶，补气血"},
    {"name": "通草", "benefit": "通经下乳，利水消肿"},
    {"name": "花生", "benefit": "通乳补血，润肺和胃"},
    {"name": "黄芪", "benefit": "补气升阳，益气固表，有助泌乳"},
    {"name": "王不留行", "benefit": "活血通经，下乳消肿（需医嘱）"},
    {"name": "鲫鱼", "benefit": "益气健脾，通乳下奶"},
]

POSTPARTUM_EXERCISES = [
    {
        "name": "Kegel运动（凯格尔）",
        "timing": "产后24小时即可开始",
        "method": "收缩盆底肌3秒，放松3秒，重复15-20次",
        "benefit": "预防和改善产后尿失禁，增强盆底肌力"
    },
    {
        "name": "腹式深呼吸",
        "timing": "产后第1天开始",
        "method": "仰卧，鼻吸腹胀，口吐腹收，10次为1组",
        "benefit": "帮助子宫复旧，促进腹肌恢复"
    },
    {
        "name": "产后瑜伽",
        "timing": "顺产6周后、剖腹产8周后",
        "method": "在专业教练指导下进行",
        "benefit": "全面恢复身体功能，改善情绪"
    }
]

POSTPARTUM_DEPRESSION_SUPPORT = {
    "signs": ["持续情绪低落", "对宝宝缺乏兴趣", "睡眠障碍", "焦虑担忧", "感觉无力或绝望"],
    "tcm_view": "中医认为产后抑郁多因气血不足、心神失养，或肝气郁结所致",
    "self_help": ["与家人朋友沟通", "适当休息", "参加支持小组", "户外散步接触阳光"],
    "tcm_remedies": ["逍遥丸（肝郁型）", "归脾汤（气血亏虚型）", "按摩神门穴、内关穴"],
    "when_to_seek_help": "如症状持续2周以上，建议及时寻求心理医生或精神科帮助"
}


@router.get("/phases", summary="产后恢复阶段")
async def get_phases():
    return {"success": True, "data": {"phases": list(POSTPARTUM_PHASES.values())}}


@router.get("/phases/{phase_id}", summary="指定阶段调理方案")
async def get_phase(phase_id: str):
    if phase_id not in POSTPARTUM_PHASES:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="阶段不存在，可选: week_1_2/week_3_4/month_2_3")
    return {"success": True, "data": POSTPARTUM_PHASES[phase_id]}


@router.get("/lactation-foods", summary="催乳食物推荐")
async def get_lactation_foods():
    return {"success": True, "data": {"foods": LACTATION_FOODS}}


@router.get("/exercises", summary="产后康复运动")
async def get_exercises():
    return {"success": True, "data": {"exercises": POSTPARTUM_EXERCISES}}


@router.get("/depression-support", summary="产后抑郁支持")
async def get_depression_support():
    return {"success": True, "data": POSTPARTUM_DEPRESSION_SUPPORT}


@router.get("/diet-guide", summary="月子饮食全指南")
async def get_diet_guide():
    return {
        "success": True,
        "data": {
            "principles": ["食物宜温热", "清淡易消化", "少量多餐", "补而不腻"],
            "key_nutrients": {
                "protein": "每日80-100g，促进伤口愈合和乳汁分泌",
                "calcium": "每日1000-1200mg，防止骨质流失",
                "iron": "每日27mg，补充分娩失血",
                "DHA": "哺乳期每日200mg，促进宝宝大脑发育"
            },
            "traditional_tips": [
                "产后1周以小米粥、蒸蛋为主",
                "第2周开始加入通乳食物",
                "第3-4周逐渐恢复正常饮食"
            ]
        }
    }
