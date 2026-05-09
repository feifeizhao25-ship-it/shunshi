"""
顺时 — 时辰养生 API (shunshi-shichen)
中国传统十二时辰与脏腑对应的养生指导
"""

from fastapi import APIRouter, HTTPException, Query
from typing import Optional, List
from datetime import datetime

router = APIRouter(prefix="/api/v1/shichen", tags=["shichen"])

# 十二时辰数据
SHICHEN_DATA = {
    "zi": {
        "code": "zi", "name_cn": "子时", "name_en": "Zi Hour",
        "hours": "23:00-01:00", "sequence": 1,
        "organ": "胆", "organ_en": "Gallbladder",
        "element": "water",
        "wellness": {
            "principle": "胆经当令，宜深睡眠",
            "activity": "deep_sleep",
            "advice": "此时胆经运行旺盛，应进入深度睡眠，有助于胆汁更新代谢，养护肝胆。",
            "avoid": ["熬夜", "久坐", "过度用脑"],
            "diet": ["温热牛奶", "百合粥"],
            "emotion": "平静入眠，避免焦虑"
        }
    },
    "chou": {
        "code": "chou", "name_cn": "丑时", "name_en": "Chou Hour",
        "hours": "01:00-03:00", "sequence": 2,
        "organ": "肝", "organ_en": "Liver",
        "element": "wood",
        "wellness": {
            "principle": "肝经当令，血归于肝",
            "activity": "deep_sleep",
            "advice": "肝经运行，血液在此时回流肝脏解毒。必须熟睡，不可在此时段饮酒。",
            "avoid": ["饮酒", "熬夜", "情绪激动"],
            "diet": [],
            "emotion": "平稳睡眠，肝气得养"
        }
    },
    "yin": {
        "code": "yin", "name_cn": "寅时", "name_en": "Yin Hour",
        "hours": "03:00-05:00", "sequence": 3,
        "organ": "肺", "organ_en": "Lung",
        "element": "metal",
        "wellness": {
            "principle": "肺经当令，肺朝百脉",
            "activity": "light_sleep",
            "advice": "肺经值班，体内气血重新分配。肺病患者此时症状多加重，需格外注意保暖。",
            "avoid": ["受寒", "剧烈运动", "吸烟"],
            "diet": ["梨汤", "百合"],
            "emotion": "安静休息"
        }
    },
    "mao": {
        "code": "mao", "name_cn": "卯时", "name_en": "Mao Hour",
        "hours": "05:00-07:00", "sequence": 4,
        "organ": "大肠", "organ_en": "Large Intestine",
        "element": "metal",
        "wellness": {
            "principle": "大肠经当令，宜排便",
            "activity": "wake_up_exercise",
            "advice": "大肠经运行，是最佳排便时间。起床后喝温水一杯，有助于肠道蠕动。",
            "avoid": ["憋便", "剧烈运动"],
            "diet": ["温水", "蜂蜜水"],
            "emotion": "轻松愉悦，迎接新一天"
        }
    },
    "chen": {
        "code": "chen", "name_cn": "辰时", "name_en": "Chen Hour",
        "hours": "07:00-09:00", "sequence": 5,
        "organ": "胃", "organ_en": "Stomach",
        "element": "earth",
        "wellness": {
            "principle": "胃经当令，宜吃早饭",
            "activity": "breakfast",
            "advice": "胃经当值，消化能力最强，早餐是一天中最重要的一餐，应吃热食。",
            "avoid": ["空腹", "冷食", "过辛辣"],
            "diet": ["小米粥", "燕麦", "鸡蛋", "温豆浆"],
            "emotion": "平和从容，细嚼慢咽"
        }
    },
    "si": {
        "code": "si", "name_cn": "巳时", "name_en": "Si Hour",
        "hours": "09:00-11:00", "sequence": 6,
        "organ": "脾", "organ_en": "Spleen",
        "element": "earth",
        "wellness": {
            "principle": "脾经当令，运化旺盛",
            "activity": "focused_work",
            "advice": "脾经运行，脾主运化，此时记忆力和思维能力最佳，适合学习工作。",
            "avoid": ["过度思虑", "久坐不动", "甜食过量"],
            "diet": ["山药茶", "红枣"],
            "emotion": "专注稳定，避免过度忧思"
        }
    },
    "wu": {
        "code": "wu", "name_cn": "午时", "name_en": "Wu Hour",
        "hours": "11:00-13:00", "sequence": 7,
        "organ": "心", "organ_en": "Heart",
        "element": "fire",
        "wellness": {
            "principle": "心经当令，宜小憩",
            "activity": "lunch_rest",
            "advice": "心经当值，午餐后小睡15-30分钟有利于养心，但不宜超过1小时。",
            "avoid": ["剧烈运动", "情绪激动", "久坐"],
            "diet": ["苦瓜", "莲子心茶", "清淡午餐"],
            "emotion": "平静喜悦，午休养神"
        }
    },
    "wei": {
        "code": "wei", "name_cn": "未时", "name_en": "Wei Hour",
        "hours": "13:00-15:00", "sequence": 8,
        "organ": "小肠", "organ_en": "Small Intestine",
        "element": "fire",
        "wellness": {
            "principle": "小肠经当令，消化吸收",
            "activity": "light_work",
            "advice": "小肠经运行，负责吸收营养精华。此时喝水有助于小肠消化，适合轻松工作。",
            "avoid": ["过度饮食", "高脂食物"],
            "diet": ["温水", "水果"],
            "emotion": "平和轻松"
        }
    },
    "shen": {
        "code": "shen", "name_cn": "申时", "name_en": "Shen Hour",
        "hours": "15:00-17:00", "sequence": 9,
        "organ": "膀胱", "organ_en": "Bladder",
        "element": "water",
        "wellness": {
            "principle": "膀胱经当令，宜学习运动",
            "activity": "exercise_study",
            "advice": "膀胱经运行，此时记忆力再次达到高峰，适合学习。也是下午运动的最佳时机。",
            "avoid": ["憋尿", "久坐不动"],
            "diet": ["温水", "绿茶"],
            "emotion": "活跃积极，充满活力"
        }
    },
    "you": {
        "code": "you", "name_cn": "酉时", "name_en": "You Hour",
        "hours": "17:00-19:00", "sequence": 10,
        "organ": "肾", "organ_en": "Kidney",
        "element": "water",
        "wellness": {
            "principle": "肾经当令，宜补肾养精",
            "activity": "gentle_exercise",
            "advice": "肾经运行，此时不宜剧烈运动，可做一些舒缓运动如散步、瑜伽。晚餐宜清淡。",
            "avoid": ["剧烈运动", "过量饮水", "房事"],
            "diet": ["黑豆", "核桃", "枸杞"],
            "emotion": "平静内敛，收心养性"
        }
    },
    "xu": {
        "code": "xu", "name_cn": "戌时", "name_en": "Xu Hour",
        "hours": "19:00-21:00", "sequence": 11,
        "organ": "心包", "organ_en": "Pericardium",
        "element": "fire",
        "wellness": {
            "principle": "心包经当令，宜娱乐放松",
            "activity": "relaxation",
            "advice": "心包经运行，心情舒畅有利于心脏保健。此时适合散步、家庭娱乐、读书等放松活动。",
            "avoid": ["激烈争吵", "重体力劳动", "过度兴奋"],
            "diet": ["玫瑰花茶", "红枣", "温牛奶"],
            "emotion": "欢乐祥和，家庭时光"
        }
    },
    "hai": {
        "code": "hai", "name_cn": "亥时", "name_en": "Hai Hour",
        "hours": "21:00-23:00", "sequence": 12,
        "organ": "三焦", "organ_en": "Triple Burner",
        "element": "fire",
        "wellness": {
            "principle": "三焦经当令，准备入睡",
            "activity": "prepare_sleep",
            "advice": "三焦经当值，百脉休养生息。此时应准备入睡，放下手机，热水泡脚有助于促进睡眠。",
            "avoid": ["手机蓝光", "剧烈运动", "大量进食"],
            "diet": ["温牛奶", "酸枣仁茶"],
            "emotion": "宁静平和，放松身心"
        }
    }
}

def _get_current_shichen() -> str:
    """根据当前时间返回时辰代码"""
    hour = datetime.now().hour
    mapping = [
        (23, 1, "zi"), (1, 3, "chou"), (3, 5, "yin"), (5, 7, "mao"),
        (7, 9, "chen"), (9, 11, "si"), (11, 13, "wu"), (13, 15, "wei"),
        (15, 17, "shen"), (17, 19, "you"), (19, 21, "xu"), (21, 23, "hai"),
    ]
    for start, end, code in mapping:
        if start == 23:
            if hour >= 23 or hour < 1:
                return code
        elif start <= hour < end:
            return code
    return "zi"


@router.get("/current", summary="当前时辰养生建议")
async def get_current_shichen():
    code = _get_current_shichen()
    data = SHICHEN_DATA[code]
    return {
        "success": True,
        "data": {
            **data,
            "current_time": datetime.now().strftime("%H:%M"),
            "message": f"现在是{data['name_cn']}，{data['wellness']['principle']}"
        }
    }


@router.get("/list", summary="十二时辰完整列表")
async def list_shichen():
    items = sorted(SHICHEN_DATA.values(), key=lambda x: x["sequence"])
    return {"success": True, "data": {"shichen_list": items, "total": 12}}


@router.get("/{code}", summary="指定时辰详情")
async def get_shichen_detail(code: str):
    if code not in SHICHEN_DATA:
        raise HTTPException(status_code=404, detail=f"时辰 '{code}' 不存在")
    return {"success": True, "data": SHICHEN_DATA[code]}


@router.get("/{code}/wellness", summary="指定时辰养生方案")
async def get_shichen_wellness(code: str):
    if code not in SHICHEN_DATA:
        raise HTTPException(status_code=404, detail=f"时辰 '{code}' 不存在")
    s = SHICHEN_DATA[code]
    return {
        "success": True,
        "data": {
            "shichen": s["name_cn"],
            "organ": s["organ"],
            "hours": s["hours"],
            "wellness": s["wellness"]
        }
    }
