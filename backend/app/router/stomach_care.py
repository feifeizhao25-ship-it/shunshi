"""
顺时 — 胃部养护 API (shunshi-stomach-care)
中医护胃方案、胃病调理、饮食建议
"""

from fastapi import APIRouter, Query
from typing import Optional

router = APIRouter(prefix="/api/v1/stomach-care", tags=["stomach-care"])

STOMACH_CONDITIONS = {
    "gastritis": {
        "id": "gastritis", "name": "胃炎", "tcm_name": "胃脘痛",
        "tcm_types": [
            {
                "type": "寒邪犯胃", "signs": ["胃痛喜温", "得热痛减", "口淡不渴"],
                "treatment": "温胃散寒",
                "herbs": ["高良姜", "干姜", "吴茱萸"],
                "diet": ["生姜红糖水", "热粥", "葱白汤"]
            },
            {
                "type": "饮食伤胃", "signs": ["胃脘胀满", "嗳腐吞酸", "大便酸臭"],
                "treatment": "消食导滞",
                "herbs": ["山楂", "麦芽", "神曲", "莱菔子"],
                "diet": ["山楂茶", "萝卜汤", "清淡易消化食物"]
            },
            {
                "type": "肝气犯胃", "signs": ["胃脘胀痛", "嗳气频繁", "情志不舒则加重"],
                "treatment": "疏肝理气和胃",
                "herbs": ["柴胡", "白芍", "香附", "陈皮"],
                "diet": ["玫瑰花茶", "陈皮茶", "避免过度紧张"]
            }
        ],
        "acupoints": ["中脘穴", "足三里穴", "内关穴"],
        "dietary_advice": "三餐定时定量，细嚼慢咽，避免暴饮暴食"
    },
    "acid_reflux": {
        "id": "acid_reflux", "name": "胃酸反流", "tcm_name": "吞酸",
        "tcm_types": [
            {
                "type": "肝胃不和", "signs": ["反酸烧心", "胸骨后灼痛", "情绪差时加重"],
                "treatment": "疏肝和胃降逆",
                "herbs": ["旋覆花", "代赭石", "半夏"],
                "diet": ["陈皮茶", "避免酸辣食物"]
            }
        ],
        "acupoints": ["内关穴", "中脘穴", "天突穴"],
        "dietary_advice": "饭后不宜立即平卧，睡前3小时不进食"
    }
}

STOMACH_PROTECTION_TIPS = [
    {"category": "饮食规律", "tips": ["三餐定时定量", "早餐7-9点（辰时）消化最佳", "晚餐宜少宜早"]},
    {"category": "饮食方式", "tips": ["细嚼慢咽（每口咀嚼20-30次）", "进食时保持愉悦心情", "专心吃饭不看手机"]},
    {"category": "温度管理", "tips": ["食物温度适中，不宜过热过凉", "冬季注意胃部保暖", "避免空腹饮冷饮"]},
    {"category": "生活习惯", "tips": ["餐后散步15-30分钟", "避免饭后立即运动或平躺", "戒烟限酒"]},
    {"category": "情绪管理", "tips": ["保持愉悦心情进食", "学会减压，避免焦虑影响消化", "中医认为'忧思伤脾'"]},
]

STOMACH_SEASON_CARE = {
    "spring": "春季肝气旺，易克脾胃，宜疏肝健脾，多食山药、红枣",
    "summer": "夏季贪凉易损胃气，注意不要过食冷饮，多喝温水",
    "autumn": "秋季宜润燥养胃，多食银耳、百合、山药等",
    "winter": "冬季胃寒多见，宜温补，可适量食用羊肉、生姜汤"
}


@router.get("/conditions", summary="常见胃部问题")
async def list_conditions():
    items = [{"id": v["id"], "name": v["name"], "tcm_name": v["tcm_name"]} for v in STOMACH_CONDITIONS.values()]
    return {"success": True, "data": {"conditions": items}}


@router.get("/conditions/{condition_id}", summary="胃部问题详细调理方案")
async def get_condition(condition_id: str):
    if condition_id not in STOMACH_CONDITIONS:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="胃部问题类型不存在")
    return {"success": True, "data": STOMACH_CONDITIONS[condition_id]}


@router.get("/protection-tips", summary="日常护胃建议")
async def get_protection_tips():
    return {"success": True, "data": {"tips": STOMACH_PROTECTION_TIPS}}


@router.get("/seasonal-care", summary="四季护胃方案")
async def get_seasonal_care(season: Optional[str] = Query(None)):
    if season:
        care = STOMACH_SEASON_CARE.get(season)
        return {"success": True, "data": {"season": season, "advice": care}}
    return {"success": True, "data": {"seasonal_care": STOMACH_SEASON_CARE}}


@router.get("/acupoints", summary="护胃穴位")
async def get_stomach_acupoints():
    acupoints = [
        {"code": "ST36", "name": "足三里穴", "location": "小腿外侧，外膝眼下3寸", "function": "调理脾胃，补中益气", "method": "按压或艾灸，每次5-10分钟"},
        {"code": "CV12", "name": "中脘穴", "location": "前正中线，脐上4寸", "function": "健脾和胃，消食导滞", "method": "按揉或热敷，每次10-15分钟"},
        {"code": "PC6", "name": "内关穴", "location": "前臂正中，腕横纹上2寸", "function": "和胃降逆，宽胸解郁", "method": "按压，每次3-5分钟"},
        {"code": "SP4", "name": "公孙穴", "location": "足内侧，第一跖骨基底前下方", "function": "健脾和胃，理气止痛", "method": "按揉，每次3分钟"},
    ]
    return {"success": True, "data": {"acupoints": acupoints}}


@router.get("/diet-guide", summary="护胃饮食指南")
async def get_diet_guide():
    return {
        "success": True,
        "data": {
            "recommended_foods": ["小米粥", "山药", "南瓜", "胡萝卜", "豆腐", "鸡蛋羹"],
            "foods_to_avoid": ["辛辣刺激", "过凉食物", "酒精", "咖啡", "高酸食物"],
            "cooking_methods": ["蒸", "煮", "炖", "少油少盐"],
            "principles": ["食物宜温热", "少量多餐", "细嚼慢咽", "清淡为主"]
        }
    }
