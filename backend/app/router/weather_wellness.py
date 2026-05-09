"""
顺时 — 天气养生 API (shunshi-weather-wellness)
根据天气条件提供个性化养生建议
"""

from fastapi import APIRouter, Query
from pydantic import BaseModel, Field
from typing import Optional

router = APIRouter(prefix="/api/v1/weather-wellness", tags=["weather-wellness"])


class WeatherInput(BaseModel):
    temperature: float = Field(..., description="气温(°C)")
    humidity: float = Field(..., ge=0, le=100, description="湿度(%)")
    weather_type: str = Field(..., description="天气类型: sunny/cloudy/rainy/snowy/foggy/windy")
    aqi: Optional[int] = Field(None, description="空气质量指数")
    location: Optional[str] = Field(None, description="城市")


WEATHER_WELLNESS = {
    "sunny": {
        "risk_factors": ["紫外线强", "出汗多"],
        "constitution_advice": {
            "yin_deficiency": "阴虚体质容易上火，晴天需防日晒，多喝水",
            "yang_deficiency": "阳虚体质适合晒太阳补阳，但避免暴晒"
        },
        "general": {
            "diet": ["多喝水", "绿茶", "西瓜汁", "绿豆汤"],
            "exercise": ["早晨或傍晚运动", "避免正午户外"],
            "clothing": ["宽松透气衣物", "防晒帽", "防晒霜"],
            "tcm_tip": "晴天阳气旺，宜户外活动，吸收自然阳气"
        }
    },
    "cloudy": {
        "risk_factors": ["阳气不足", "情绪可能低落"],
        "constitution_advice": {
            "qi_deficiency": "阴云天气阳气弱，气虚者更需注意保暖",
            "qi_stagnation": "阴天情绪易郁闷，气郁体质需特别注意情绪调节"
        },
        "general": {
            "diet": ["温热食物", "生姜茶", "红枣"],
            "exercise": ["室内运动", "八段锦", "瑜伽"],
            "clothing": ["注意保暖层次"],
            "tcm_tip": "阴云天宜调节情志，避免郁郁寡欢"
        }
    },
    "rainy": {
        "risk_factors": ["湿气重", "关节不适", "情绪低落"],
        "constitution_advice": {
            "phlegm_dampness": "痰湿体质在雨天湿气加重，需特别注意祛湿",
            "blood_stasis": "雨天寒湿会加重血瘀，血瘀体质需保暖"
        },
        "general": {
            "diet": ["薏米粥", "茯苓茶", "姜汤", "红豆", "避免生冷"],
            "exercise": ["室内运动为主", "避免淋雨"],
            "clothing": ["防水外层", "注意保暖防寒"],
            "tcm_tip": "雨天湿气重，脾胃最易受损，宜健脾祛湿"
        }
    },
    "snowy": {
        "risk_factors": ["严寒伤阳", "跌倒风险", "心脑血管风险"],
        "constitution_advice": {
            "yang_deficiency": "阳虚体质在雪天严寒最难受，需大力温补保暖",
            "blood_stasis": "寒冷加重血瘀，血瘀体质需注意心脑血管保护"
        },
        "general": {
            "diet": ["羊肉汤", "核桃", "姜枣茶", "温热食物"],
            "exercise": ["室内为主", "避免清晨户外（最冷时段）"],
            "clothing": ["多层保暖", "尤其保护颈部和足部"],
            "tcm_tip": "雪天严寒，阳气封藏，宜早睡晚起，养精蓄锐"
        }
    },
    "foggy": {
        "risk_factors": ["空气质量差", "呼吸系统影响", "能见度低"],
        "constitution_advice": {
            "lung_weak": "肺气虚者在雾天最易受影响，需特别防护"
        },
        "general": {
            "diet": ["清肺食物", "梨水", "百合粥", "银耳汤"],
            "exercise": ["避免户外运动", "戴N95口罩外出"],
            "clothing": ["口罩必备"],
            "tcm_tip": "雾天肺经受损，宜润肺清肺"
        }
    },
    "windy": {
        "risk_factors": ["风邪侵袭", "感冒风险", "眼部干涩"],
        "constitution_advice": {
            "qi_deficiency": "气虚者卫气不固，风天最易感冒，需防风保暖"
        },
        "general": {
            "diet": ["葱姜汤", "益气补虚食物", "温热饮品"],
            "exercise": ["避免大风中运动", "减少户外时间"],
            "clothing": ["防风外套", "注意颈部保暖（风池穴）"],
            "tcm_tip": "风为百病之长，风天需防风散寒，固护卫气"
        }
    }
}


def _get_aqi_advice(aqi: Optional[int]) -> dict:
    if aqi is None:
        return {"level": "未知", "advice": "请关注当地空气质量"}
    if aqi <= 50:
        return {"level": "优", "advice": "空气质量良好，适合户外活动"}
    elif aqi <= 100:
        return {"level": "良", "advice": "空气质量可接受，敏感人群减少长时间户外"}
    elif aqi <= 150:
        return {"level": "轻度污染", "advice": "儿童、老人和心肺疾病患者减少长时间户外活动"}
    elif aqi <= 200:
        return {"level": "中度污染", "advice": "所有人应减少户外活动，外出戴口罩"}
    else:
        return {"level": "重度污染", "advice": "避免户外活动，紧闭门窗，使用空气净化器"}


def _get_temp_advice(temp: float) -> str:
    if temp < 0:
        return "极寒天气，注意防寒保暖，预防冻伤"
    elif temp < 10:
        return "寒冷天气，多穿衣物，注意保暖"
    elif temp < 20:
        return "凉爽天气，适合户外活动，注意随时增减衣物"
    elif temp < 30:
        return "温暖天气，适合各类户外活动"
    elif temp < 35:
        return "炎热天气，注意防暑降温，多补充水分"
    else:
        return "高温天气，减少户外活动，防止中暑"


@router.post("/advice", summary="根据天气获取养生建议")
async def get_weather_advice(weather: WeatherInput):
    base = WEATHER_WELLNESS.get(weather.weather_type, WEATHER_WELLNESS["cloudy"])
    aqi_advice = _get_aqi_advice(weather.aqi)
    temp_advice = _get_temp_advice(weather.temperature)

    humidity_tip = ""
    if weather.humidity > 80:
        humidity_tip = "湿度偏高，注意祛湿，避免生冷食物"
    elif weather.humidity < 30:
        humidity_tip = "湿度偏低，注意补充水分，润燥养肺"

    return {
        "success": True,
        "data": {
            "weather_type": weather.weather_type,
            "temperature": weather.temperature,
            "temperature_advice": temp_advice,
            "humidity_tip": humidity_tip,
            "aqi_advice": aqi_advice,
            "wellness_advice": base["general"],
            "risk_factors": base["risk_factors"],
            "tcm_tip": base["general"]["tcm_tip"]
        }
    }


@router.get("/types", summary="天气类型及养生要点")
async def list_weather_types():
    types = [
        {"type": k, "risk_factors": v["risk_factors"], "tcm_tip": v["general"]["tcm_tip"]}
        for k, v in WEATHER_WELLNESS.items()
    ]
    return {"success": True, "data": {"weather_types": types}}


@router.get("/aqi-guide", summary="空气质量养生指南")
async def get_aqi_guide():
    levels = [
        {"range": "0-50", "level": "优", "outdoor": "鼓励户外活动"},
        {"range": "51-100", "level": "良", "outdoor": "可正常户外活动"},
        {"range": "101-150", "level": "轻度污染", "outdoor": "敏感人群减少户外"},
        {"range": "151-200", "level": "中度污染", "outdoor": "减少户外，戴口罩"},
        {"range": ">200", "level": "重度污染", "outdoor": "避免户外，关窗"}
    ]
    return {"success": True, "data": {"aqi_levels": levels}}
