"""
顺时 — 肺部养护 API (shunshi-lung-care)
中医护肺方案、润肺食疗、肺部功能锻炼
"""

from fastapi import APIRouter, Query
from typing import Optional

router = APIRouter(prefix="/api/v1/lung-care", tags=["lung-care"])

LUNG_TCM = {
    "functions": [
        "肺主气，司呼吸",
        "肺主宣发肃降",
        "肺主通调水道",
        "肺开窍于鼻",
        "肺在体合皮毛",
        "肺藏魄（情志与肺相关）"
    ],
    "season": "秋",
    "peak_time": "寅时（凌晨3-5点）",
    "element": "金",
    "emotion": "悲",
    "flavor": "辛"
}

LUNG_FOODS = [
    {"name": "梨", "benefit": "润肺清热，化痰止咳", "best_for": ["干咳", "燥咳", "肺热"]},
    {"name": "银耳", "benefit": "滋阴润肺，生津止渴", "best_for": ["肺阴虚", "干咳少痰"]},
    {"name": "百合", "benefit": "润肺止咳，清心安神", "best_for": ["久咳", "肺阴虚", "心烦失眠"]},
    {"name": "川贝", "benefit": "清热润肺，化痰止咳", "best_for": ["痰热咳嗽", "燥咳"]},
    {"name": "白萝卜", "benefit": "化痰止咳，降气消食", "best_for": ["痰多咳嗽", "气逆上咳"]},
    {"name": "白色食物", "benefit": "五行中金色（白色）对应肺", "best_for": ["日常肺部养护"]},
    {"name": "杏仁", "benefit": "润肺止咳，宣肺平喘", "best_for": ["各类咳嗽", "气喘"]},
]

BREATHING_EXERCISES = [
    {
        "id": "abdominal_breathing", "name": "腹式呼吸",
        "duration": "每次10分钟",
        "steps": ["仰卧或坐姿", "鼻子缓慢吸气，腹部隆起", "嘴巴缓慢呼气，腹部内收", "呼吸比约1:2（吸气4秒，呼气8秒）"],
        "benefit": "增加肺活量，改善氧合，平静神经系统"
    },
    {
        "id": "pursed_lip_breathing", "name": "缩唇呼吸",
        "duration": "每次5分钟",
        "steps": ["放松肩膀", "用鼻子吸气2秒", "噘起嘴唇，缓慢呼气4秒"],
        "benefit": "延缓气道塌陷，适合COPD患者"
    },
    {
        "id": "diaphragm_training", "name": "横膈膜呼吸训练",
        "duration": "每次5-10分钟",
        "steps": ["一手放胸部，一手放腹部", "鼻子吸气，腹部手随之上升", "嘴巴吐气，腹部手随之下降", "胸部手保持最小动作"],
        "benefit": "加强横膈膜肌力，提升肺功能"
    }
]

ACUPOINTS = [
    {"code": "LU1", "name": "中府穴", "location": "锁骨下外侧1寸", "function": "清肺化痰，止咳平喘"},
    {"code": "LU7", "name": "列缺穴", "location": "手腕上方1.5寸", "function": "宣肺解表，利咽止咳"},
    {"code": "KD27", "name": "俞府穴", "location": "胸骨旁开2寸", "function": "理气降逆，止咳平喘"},
    {"code": "ST40", "name": "丰隆穴", "location": "小腿外侧中点", "function": "化痰湿，清肺热"},
]


@router.get("/tcm-functions", summary="中医肺脏功能")
async def get_tcm_functions():
    return {"success": True, "data": LUNG_TCM}


@router.get("/foods", summary="润肺食物推荐")
async def get_lung_foods(condition: Optional[str] = Query(None)):
    foods = LUNG_FOODS
    if condition:
        foods = [f for f in foods if any(condition in b for b in f["best_for"])]
    return {"success": True, "data": {"foods": foods}}


@router.get("/breathing-exercises", summary="肺部呼吸功法")
async def get_breathing_exercises():
    return {"success": True, "data": {"exercises": BREATHING_EXERCISES}}


@router.get("/acupoints", summary="护肺穴位")
async def get_lung_acupoints():
    return {"success": True, "data": {"acupoints": ACUPOINTS}}


@router.get("/seasonal-care", summary="四季护肺方案")
async def get_seasonal_care():
    care = {
        "spring": "春季花粉多，过敏体质需防护，多吃清淡食物，减少油炸",
        "summer": "夏季暑热伤肺气，注意空调温度不过低，可饮绿豆百合汤",
        "autumn": "秋季燥邪最易伤肺，重点润燥，多食白色润肺食物",
        "winter": "冬季寒邪伤肺，保暖防寒，戴口罩防风寒，适当温补肺气"
    }
    return {"success": True, "data": {"seasonal_care": care}}


@router.get("/daily-plan", summary="每日护肺计划")
async def get_daily_plan():
    plan = {
        "morning": "起床后做腹式呼吸10分钟，喝温水或梨水",
        "midday": "午餐加入润肺食物，如百合莲子汤",
        "afternoon": "下午2-3点多喝水，按摩列缺穴3分钟",
        "evening": "傍晚散步，深呼吸吐故纳新",
        "bedtime": "睡前使用加湿器保持湿度在50-60%"
    }
    return {"success": True, "data": {"daily_plan": plan}}
