"""
顺时 — 经络养生 API (shunshi-meridian)
十四经络基础知识、经络养生方案、循经按摩指导
"""

from fastapi import APIRouter, HTTPException, Query
from typing import Optional, List

router = APIRouter(prefix="/api/v1/meridian", tags=["meridian"])

MERIDIANS = {
    "lung": {
        "code": "lung", "name_cn": "手太阴肺经", "name_en": "Lung Meridian",
        "element": "metal", "organ": "肺", "yin_yang": "yin",
        "peak_time": "03:00-05:00", "shichen": "寅时",
        "pathway": "起于中焦，下络大肠，还循胃口，上膈属肺",
        "key_acupoints": [
            {"code": "LU1", "name": "中府穴", "function": "清肺化痰，止咳平喘"},
            {"code": "LU7", "name": "列缺穴", "function": "宣肺解表，通经活络"},
            {"code": "LU9", "name": "太渊穴", "function": "补肺益气，止咳化痰"},
            {"code": "LU11", "name": "少商穴", "function": "清热利咽，开窍醒神"},
        ],
        "wellness": {
            "principle": "补肺益气，宣降肺气",
            "massage_tip": "沿手臂内侧从胸部向手腕方向推按，每次3-5分钟",
            "season": "秋",
            "foods": ["白色食物", "梨", "百合", "银耳", "莲藕"],
            "avoid": ["吸烟", "干燥环境", "悲伤情绪"]
        }
    },
    "large_intestine": {
        "code": "large_intestine", "name_cn": "手阳明大肠经", "name_en": "Large Intestine Meridian",
        "element": "metal", "organ": "大肠", "yin_yang": "yang",
        "peak_time": "05:00-07:00", "shichen": "卯时",
        "pathway": "起于食指末端，沿手背、臂外侧，经肩，上颈，至面颊，入下齿，旁绕上唇",
        "key_acupoints": [
            {"code": "LI4", "name": "合谷穴", "function": "镇静止痛，通经活络，清热解表"},
            {"code": "LI11", "name": "曲池穴", "function": "清热解表，散风止痒"},
        ],
        "wellness": {
            "principle": "清肠排毒，润肠通便",
            "massage_tip": "沿手臂外侧由手腕向肩膀方向按摩",
            "season": "秋",
            "foods": ["粗纤维食物", "蔬菜", "香蕉", "蜂蜜"],
            "avoid": ["高脂油腻", "久坐不动"]
        }
    },
    "stomach": {
        "code": "stomach", "name_cn": "足阳明胃经", "name_en": "Stomach Meridian",
        "element": "earth", "organ": "胃", "yin_yang": "yang",
        "peak_time": "07:00-09:00", "shichen": "辰时",
        "pathway": "起于鼻翼旁，上至鼻根，下循鼻外，入上齿，环绕嘴唇，沿喉咙下行至胸腹",
        "key_acupoints": [
            {"code": "ST36", "name": "足三里穴", "function": "调理脾胃，补中益气，扶正培元"},
            {"code": "ST25", "name": "天枢穴", "function": "疏调大肠，理气行滞"},
        ],
        "wellness": {
            "principle": "健脾和胃，益气养血",
            "massage_tip": "沿小腿外侧向下按摩，重点按压足三里穴",
            "season": "长夏",
            "foods": ["小米", "山药", "南瓜", "红枣", "莲子"],
            "avoid": ["冷饮", "暴饮暴食", "过度思虑"]
        }
    },
    "spleen": {
        "code": "spleen", "name_cn": "足太阴脾经", "name_en": "Spleen Meridian",
        "element": "earth", "organ": "脾", "yin_yang": "yin",
        "peak_time": "09:00-11:00", "shichen": "巳时",
        "pathway": "起于大趾末端，沿足内侧、小腿内侧、大腿内侧，进入腹部，属脾，络胃",
        "key_acupoints": [
            {"code": "SP6", "name": "三阴交穴", "function": "健脾和胃，调补肝肾，行气活血"},
            {"code": "SP9", "name": "阴陵泉穴", "function": "健脾化湿，通利三焦"},
        ],
        "wellness": {
            "principle": "健脾益气，化湿通络",
            "massage_tip": "沿小腿内侧向上按摩，重点按压三阴交穴",
            "season": "长夏",
            "foods": ["黄色食物", "玉米", "薏米", "茯苓"],
            "avoid": ["生冷食物", "湿重环境", "过度劳累"]
        }
    },
    "heart": {
        "code": "heart", "name_cn": "手少阴心经", "name_en": "Heart Meridian",
        "element": "fire", "organ": "心", "yin_yang": "yin",
        "peak_time": "11:00-13:00", "shichen": "午时",
        "pathway": "起于心中，出属心系，下膈，络小肠",
        "key_acupoints": [
            {"code": "HT7", "name": "神门穴", "function": "安神定志，清心泻热"},
            {"code": "HT3", "name": "少海穴", "function": "理气通络，益心安神"},
        ],
        "wellness": {
            "principle": "养心安神，调和气血",
            "massage_tip": "沿手臂内侧轻柔按摩，重点按压神门穴",
            "season": "夏",
            "foods": ["红色食物", "红枣", "龙眼", "莲子心"],
            "avoid": ["情绪激动", "暴喜暴悲", "过热食物"]
        }
    },
    "kidney": {
        "code": "kidney", "name_cn": "足少阴肾经", "name_en": "Kidney Meridian",
        "element": "water", "organ": "肾", "yin_yang": "yin",
        "peak_time": "17:00-19:00", "shichen": "酉时",
        "pathway": "起于小趾之下，斜走足心，循内踝，沿小腿内侧、大腿内侧，贯脊属肾",
        "key_acupoints": [
            {"code": "KD1", "name": "涌泉穴", "function": "醒神开窍，滋阴降火，引火归原"},
            {"code": "KD3", "name": "太溪穴", "function": "滋肾阴，补肾气，壮肾阳"},
        ],
        "wellness": {
            "principle": "补肾固精，滋阴壮阳",
            "massage_tip": "按压涌泉穴和太溪穴，每次按压3-5秒，重复10次",
            "season": "冬",
            "foods": ["黑色食物", "黑豆", "黑芝麻", "核桃", "枸杞"],
            "avoid": ["过度劳累", "房劳过度", "咸食过量"]
        }
    },
    "liver": {
        "code": "liver", "name_cn": "足厥阴肝经", "name_en": "Liver Meridian",
        "element": "wood", "organ": "肝", "yin_yang": "yin",
        "peak_time": "01:00-03:00", "shichen": "丑时",
        "pathway": "起于大趾，循足背、小腿内侧，上入阴毛中，环阴器，入少腹，属肝，络胆",
        "key_acupoints": [
            {"code": "LV3", "name": "太冲穴", "function": "清泻肝火，平肝息风，行气活血"},
            {"code": "LV14", "name": "期门穴", "function": "疏肝理气，健脾和胃"},
        ],
        "wellness": {
            "principle": "疏肝理气，养血柔肝",
            "massage_tip": "从脚背向上按摩至膝盖，重点按压太冲穴",
            "season": "春",
            "foods": ["绿色食物", "菠菜", "芹菜", "枸杞"],
            "avoid": ["暴怒", "酗酒", "熬夜"]
        }
    }
}


@router.get("/list", summary="经络列表")
async def list_meridians(element: Optional[str] = Query(None, description="五行筛选")):
    items = list(MERIDIANS.values())
    if element:
        items = [m for m in items if m["element"] == element]
    return {"success": True, "data": {"meridians": items, "total": len(items)}}


@router.get("/{code}", summary="经络详情")
async def get_meridian(code: str):
    if code not in MERIDIANS:
        raise HTTPException(status_code=404, detail=f"经络 '{code}' 不存在")
    return {"success": True, "data": MERIDIANS[code]}


@router.get("/{code}/acupoints", summary="经络主要穴位")
async def get_meridian_acupoints(code: str):
    if code not in MERIDIANS:
        raise HTTPException(status_code=404, detail=f"经络 '{code}' 不存在")
    m = MERIDIANS[code]
    return {
        "success": True,
        "data": {
            "meridian": m["name_cn"],
            "acupoints": m["key_acupoints"],
            "massage_tip": m["wellness"]["massage_tip"]
        }
    }


@router.get("/{code}/wellness", summary="经络养生方案")
async def get_meridian_wellness(code: str):
    if code not in MERIDIANS:
        raise HTTPException(status_code=404, detail=f"经络 '{code}' 不存在")
    m = MERIDIANS[code]
    return {"success": True, "data": {"meridian": m["name_cn"], "wellness": m["wellness"]}}


@router.get("/by-season/{season}", summary="按季节推荐经络养生")
async def get_meridian_by_season(season: str):
    season_map = {"spring": "春", "summer": "夏", "autumn": "秋", "winter": "冬", "long_summer": "长夏"}
    season_cn = season_map.get(season, season)
    items = [m for m in MERIDIANS.values() if m["wellness"]["season"] == season_cn]
    return {"success": True, "data": {"season": season_cn, "meridians": items}}
