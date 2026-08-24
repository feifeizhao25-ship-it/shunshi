"""
顺时 — 产后恢复 API (shunshi-postpartum)
产后调理方案、月子养护、哺乳期饮食
"""

from fastapi import APIRouter, Query
from typing import Optional

router = APIRouter(prefix="/api/v1/postpartum", tags=["postpartum"])

CLINICAL_NOTICE = "产后恢复因分娩方式、出血、伤口、哺乳和既往疾病而异，请以产科、助产或其他合格专业人员的个体化建议为准。"

POSTPARTUM_PHASES = {
    "week_1_2": {
        "phase": "产后第1-2周", "focus": "休息、营养、伤口与异常症状观察",
        "diet": {
            "principle": "饮食宜清淡、易消化，补而不腻",
            "recommended": ["按耐受选择完整均衡、富含蛋白质和纤维的饮食", "保持适量饮水"],
            "avoid": ["酒精", "未经医生确认的草药、补品或极端限制饮食"]
        },
        "care": [
            "保证休息并按医护建议逐步活动，降低血栓风险",
            "注意恶露颜色和量",
            "关注情绪变化并主动寻求支持；情绪问题不是个人过错"
        ],
        "tcm_herbs": ["不提供自行用药方案；益母草、生化汤等可能影响出血或与药物相互作用，须经医生评估"]
    },
    "week_3_4": {
        "phase": "产后第3-4周", "focus": "恢复活动、营养与喂养支持",
        "diet": {
            "principle": "保持食物多样和足够能量；乳量问题应先评估含接姿势、喂养频率和母婴健康",
            "recommended": ["完整均衡饮食", "按饥渴信号进食饮水"],
            "avoid": ["辛辣刺激", "酒精（影响哺乳）"]
        },
        "care": [
            "根据家庭选择和专业建议采用安全可持续的喂养方式",
            "适当室内轻活动",
            "注意乳房护理，预防乳腺炎"
        ],
        "tcm_herbs": ["不建议自行使用黄芪、当归、通草等催乳草药；先咨询医生或药师"]
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
        "tcm_herbs": ["不依据非医学标签自行服用中成药；用药需由医生结合哺乳和病史评估"]
    }
}

LACTATION_FOODS = [
    {"name": "均衡主食、蛋白质和蔬果", "benefit": "支持产妇总体营养，但没有单一食物能保证增加乳量"},
    {"name": "水和日常无酒精饮品", "benefit": "按口渴饮水即可；过量饮水不会直接提高乳量"},
    {"name": "花生等常见食物", "benefit": "可作为普通食物，但需考虑本人及婴儿过敏情况"},
    {"name": "通草、黄芪、王不留行等草药", "benefit": "不作为自行催乳食物推荐，安全性、剂量和相互作用需医生或药师评估"},
]

POSTPARTUM_EXERCISES = [
    {
        "name": "Kegel运动（凯格尔）",
        "timing": "经产科或盆底康复专业人员确认后开始",
        "method": "先确认能正确收缩和放松盆底肌，再按个体方案练习",
        "benefit": "可能帮助部分人的盆底功能；疼痛、坠胀或症状加重时停止并评估"
    },
    {
        "name": "腹式深呼吸",
        "timing": "身体稳定且医护人员允许后开始",
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
    "tcm_remedies": ["不提供自行用药或穴位治疗方案；哺乳期药物需由专业人员评估"],
    "when_to_seek_help": "无需等待满2周即可联系医生；如有自伤、伤害婴儿想法、幻觉、妄想、严重混乱或躁动，应立即联系急救和身边可信任的人，且不要独自照护婴儿。"
}


@router.get("/phases", summary="产后恢复阶段")
async def get_phases():
    return {"success": True, "data": {"phases": list(POSTPARTUM_PHASES.values())}}


@router.get("/phases/{phase_id}", summary="指定阶段调理方案")
async def get_phase(phase_id: str):
    phase_id = {"week1": "week_1_2", "week2": "week_1_2", "week3": "week_3_4", "week4": "week_3_4"}.get(phase_id, phase_id)
    if phase_id not in POSTPARTUM_PHASES:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="阶段不存在，可选: week_1_2/week_3_4/month_2_3")
    return {"success": True, "data": {**POSTPARTUM_PHASES[phase_id], "clinical_notice": CLINICAL_NOTICE}}


@router.get("/lactation-foods", summary="催乳食物推荐")
async def get_lactation_foods():
    return {"success": True, "data": {"foods": LACTATION_FOODS, "clinical_notice": CLINICAL_NOTICE}}


@router.get("/exercises", summary="产后康复运动")
async def get_exercises():
    return {"success": True, "data": {"exercises": POSTPARTUM_EXERCISES, "clinical_notice": CLINICAL_NOTICE}}


@router.get("/depression-support", summary="产后抑郁支持")
async def get_depression_support():
    return {"success": True, "data": {**POSTPARTUM_DEPRESSION_SUPPORT, "clinical_notice": CLINICAL_NOTICE}}


@router.get("/diet-guide", summary="月子饮食全指南")
async def get_diet_guide():
    return {
        "success": True,
        "data": {
            "principles": ["食物宜温热", "清淡易消化", "少量多餐", "补而不腻"],
            "key_nutrients": {
                "protein": "需求随体重、恢复和哺乳情况变化，优先从多样食物获取",
                "calcium": "按年龄、饮食和医嘱确定，不自行超量补充",
                "iron": "产后需求取决于失血、化验和是否哺乳，由医生判断是否补充",
                "DHA": "鱼类选择和补充剂需结合汞风险、饮食及医生建议"
            },
            "traditional_tips": [
                "产后1周以小米粥、蒸蛋为主",
                "第2周开始加入通乳食物",
                "第3-4周逐渐恢复正常饮食"
            ],
            "clinical_notice": CLINICAL_NOTICE,
        }
    }
