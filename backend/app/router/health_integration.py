"""
顺时 — 健康数据集成与 TCM 分析
集成 Apple Health / Google Fit 数据，提供中医体质分析和个性化养护建议。
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime, timedelta
from enum import Enum

router = APIRouter(prefix="/api/v1/health-data", tags=["health_integration"])


# ─────────────────────────────────────────────────────────────────────────────
# 请求/响应模型
# ─────────────────────────────────────────────────────────────────────────────

class DataTypeEnum(str, Enum):
    STEPS = "steps"
    SLEEP = "sleep"
    HEART_RATE = "heart_rate"
    HRV = "hrv"
    WEIGHT = "weight"


class SourceEnum(str, Enum):
    APPLE_HEALTH = "apple_health"
    GOOGLE_FIT = "google_fit"
    MANUAL = "manual"


class HealthDataSyncRequest(BaseModel):
    user_id: str
    data_type: DataTypeEnum
    value: float = Field(..., gt=0, description="数值")
    unit: str = Field(..., description="单位: steps/hours/bpm/ms/kg等")
    recorded_at: str = Field(..., description="ISO 8601 日期时间")
    source: SourceEnum


class TCMAnalysisRequest(BaseModel):
    steps: int = Field(default=0)
    sleep_hours: float = Field(default=0)
    resting_hr: int = Field(default=0)
    hrv: int = Field(default=0)


# ─────────────────────────────────────────────────────────────────────────────
# 内存存储
# ─────────────────────────────────────────────────────────────────────────────

_health_data: Dict[str, List[Dict[str, Any]]] = {}


# ─────────────────────────────────────────────────────────────────────────────
# TCM 数据类型映射规则
# ─────────────────────────────────────────────────────────────────────────────

def _analyze_steps(steps: int) -> Dict[str, Any]:
    """步数分析 → TCM 体质倾向"""
    if steps < 3000:
        return {
            "constitution": "重度气虚",
            "score": 90,
            "insight": "步数严重不足，脾气虚弱，四肢乏力",
            "recommendation": "需要循序渐进的运动计划，建议从每天3000步开始，逐步增加",
        }
    elif steps < 5000:
        return {
            "constitution": "轻度气虚",
            "score": 65,
            "insight": "活动不足，气虚倾向明显",
            "recommendation": "补气运动：八段锦、太极拳、散步，建议每日5000步以上",
        }
    elif steps < 8000:
        return {
            "constitution": "气虚倾向",
            "score": 35,
            "insight": "运动量中等偏少，宜逐步增加",
            "recommendation": "维持当前运动量并逐步提升至8000步，可加入有氧运动",
        }
    elif steps < 12000:
        return {
            "constitution": "气血均衡",
            "score": 10,
            "insight": "运动量适中，脾胃气血充足",
            "recommendation": "保持现有运动习惯，可进行抗阻训练增强肌力",
        }
    else:
        return {
            "constitution": "气血充足",
            "score": 5,
            "insight": "运动量充分，精力充沛",
            "recommendation": "保持运动习惯，注意休息恢复，避免过度消耗",
        }


def _analyze_sleep(sleep_hours: float) -> Dict[str, Any]:
    """睡眠分析 → TCM 心神调理"""
    if sleep_hours < 5:
        return {
            "constitution": "重度心神失养",
            "score": 95,
            "insight": "严重睡眠不足，心神极度疲惫，血虚明显",
            "recommendation": "需要医学干预：调整作息、避免刺激性物质、考虑中医调理",
        }
    elif sleep_hours < 6:
        return {
            "constitution": "轻度心神失养",
            "score": 60,
            "insight": "睡眠略不足，心神疲倦，气血生成不足",
            "recommendation": "养心神食疗：红枣、莲子、百合、桂圆，晚上11点前入睡",
        }
    elif sleep_hours < 7:
        return {
            "constitution": "心神调理需加强",
            "score": 30,
            "insight": "睡眠接近充足，但仍有不足",
            "recommendation": "优化睡眠环境，建立规律作息，可用酸枣仁茶辅助",
        }
    elif sleep_hours <= 8:
        return {
            "constitution": "心神得养",
            "score": 5,
            "insight": "睡眠充足，心神宁谧，血气自生",
            "recommendation": "保持现有睡眠习惯，周末可适度延长以深度恢复",
        }
    else:
        return {
            "constitution": "睡眠过度",
            "score": 15,
            "insight": "睡眠过长可能反映脾阳虚弱或湿气过重",
            "recommendation": "增加白天活动，控制睡眠时长至8小时，避免久卧伤气",
        }


def _analyze_hrv(hrv: int) -> Dict[str, Any]:
    """心率变异度分析 → TCM 肝气调理"""
    if hrv < 20:
        return {
            "constitution": "重度肝气郁结",
            "score": 85,
            "insight": "HRV极低，自律神经失衡，肝气郁滞，易怒焦虑",
            "recommendation": "急需疏肝解郁：合谷+太冲穴、玫瑰花茶、柴胡疏肝散调理",
        }
    elif hrv < 40:
        return {
            "constitution": "轻度肝气郁结",
            "score": 55,
            "insight": "HRV偏低，自律神经张力不足，压力应激能力弱",
            "recommendation": "疏肝活动：深呼吸、户外散步、穴位按摩、香气疗法",
        }
    elif hrv < 60:
        return {
            "constitution": "肝气调理中等",
            "score": 25,
            "insight": "HRV适中，自律神经功能基本正常",
            "recommendation": "继续培养深呼吸习惯，进行冥想或瑜伽加强肝气和谐",
        }
    elif hrv <= 100:
        return {
            "constitution": "肝气疏泄正常",
            "score": 8,
            "insight": "HRV良好，自律神经平衡，肝气调达",
            "recommendation": "保持现状，继续养护肝血，保证充足睡眠和适度压力管理",
        }
    else:
        return {
            "constitution": "肝气过度活跃",
            "score": 20,
            "insight": "HRV过高可能反映过度紧张或过度训练",
            "recommendation": "增加放松恢复时间，避免过度运动，学习放松技巧",
        }


def _analyze_resting_hr(resting_hr: int) -> Dict[str, Any]:
    """静息心率分析 → TCM 虚热判断"""
    if resting_hr < 50:
        return {
            "constitution": "阴虚体质",
            "score": 70,
            "insight": "静息心率过低，可能反映过度训练或心脏功能异常",
            "recommendation": "咨询医生排除病理，增加恢复期，补阴养血食疗",
        }
    elif resting_hr < 60:
        return {
            "constitution": "气阴充足",
            "score": 8,
            "insight": "静息心率理想，心脏功能良好",
            "recommendation": "保持现有训练和恢复平衡，继续养心血",
        }
    elif resting_hr < 70:
        return {
            "constitution": "阳气基本充足",
            "score": 12,
            "insight": "心率正常，心脏耐受力良好",
            "recommendation": "保持健康生活方式，定期运动维持心肺功能",
        }
    elif resting_hr < 80:
        return {
            "constitution": "轻度虚热倾向",
            "score": 40,
            "insight": "心率偏快，可能反映压力或睡眠不足导致的阴虚",
            "recommendation": "滋阴清热：麦冬、银耳、绿豆，增加睡眠时长，减少压力",
        }
    else:
        return {
            "constitution": "明显虚热倾向",
            "score": 75,
            "insight": "静息心率过快，阴虚火旺，交感神经过度活跃",
            "recommendation": "紧急调理：滋阴降火、玄麦甘桔茶、冥想放松、医学评估",
        }


def _analyze_weight(weight: float, user_id: str) -> Dict[str, Any]:
    """体重变化分析 → TCM 脾胃功能"""
    # 这里简化处理，实际应对比往期数据
    if weight < 45 or weight > 120:
        return {
            "constitution": "脾胃虚弱",
            "score": 50,
            "insight": "体重异常，脾胃消化吸收功能可能受损",
            "recommendation": "健脾益气：薏米、红豆、山楂，定期复查体重趋势",
        }
    else:
        return {
            "constitution": "脾胃功能正常",
            "score": 15,
            "insight": "体重在合理范围，脾胃运化功能基本正常",
            "recommendation": "维持均衡饮食，避免暴食暴饮，保持规律运动",
        }


# ─────────────────────────────────────────────────────────────────────────────
# 端点
# ─────────────────────────────────────────────────────────────────────────────

@router.post("/sync", summary="同步健康数据")
async def sync_health_data(request: HealthDataSyncRequest):
    """
    接收来自 Apple Health / Google Fit 的健康数据同步，
    返回实时 TCM 分析结果。
    """
    user_id = request.user_id

    if user_id not in _health_data:
        _health_data[user_id] = []

    record = {
        "data_type": request.data_type.value,
        "value": request.value,
        "unit": request.unit,
        "recorded_at": request.recorded_at,
        "source": request.source.value,
        "synced_at": datetime.now().isoformat(),
    }

    _health_data[user_id].append(record)

    # 根据数据类型进行对应 TCM 分析
    tcm_result = None
    if request.data_type == DataTypeEnum.STEPS:
        tcm_result = _analyze_steps(int(request.value))
    elif request.data_type == DataTypeEnum.SLEEP:
        tcm_result = _analyze_sleep(request.value)
    elif request.data_type == DataTypeEnum.HRV:
        tcm_result = _analyze_hrv(int(request.value))
    elif request.data_type == DataTypeEnum.HEART_RATE:
        tcm_result = _analyze_resting_hr(int(request.value))
    elif request.data_type == DataTypeEnum.WEIGHT:
        tcm_result = _analyze_weight(request.value, user_id)

    return {
        "success": True,
        "data": {
            "synced": True,
            "data_type": request.data_type.value,
            "value": request.value,
            "unit": request.unit,
            "source": request.source.value,
            "timestamp": datetime.now().isoformat(),
            "tcm_analysis": tcm_result,
        },
    }


@router.get("/summary/{user_id}", summary="7天健康数据摘要")
async def get_health_summary(user_id: str):
    """
    返回用户最近7天的健康数据摘要，包括各指标最新值和趋势。
    """
    if user_id not in _health_data or not _health_data[user_id]:
        return {
            "success": True,
            "data": {
                "user_id": user_id,
                "summary": "暂无数据",
                "latest_values": {},
                "trend": "无趋势",
            },
        }

    records = _health_data[user_id]
    seven_days_ago = (datetime.now() - timedelta(days=7)).isoformat()
    recent_records = [r for r in records if r["recorded_at"] >= seven_days_ago]

    latest_by_type = {}
    for r in recent_records:
        dt = r["data_type"]
        if dt not in latest_by_type:
            latest_by_type[dt] = r
        else:
            if r["recorded_at"] > latest_by_type[dt]["recorded_at"]:
                latest_by_type[dt] = r

    summary = {
        "user_id": user_id,
        "period": "最近7天",
        "data_count": len(recent_records),
        "latest_values": {
            k: {
                "value": v["value"],
                "unit": v["unit"],
                "recorded_at": v["recorded_at"],
                "source": v["source"],
            }
            for k, v in latest_by_type.items()
        },
        "trend": "数据收集中" if len(recent_records) < 3 else "趋势分析中",
    }

    return {
        "success": True,
        "data": summary,
    }


@router.post("/analyze", summary="TCM 健康分析")
async def analyze_health(request: TCMAnalysisRequest):
    """
    根据当前健康指标进行综合 TCM 分析，判断体质倾向和养护建议。
    """
    analyses = []

    if request.steps > 0:
        analyses.append(_analyze_steps(request.steps))
    if request.sleep_hours > 0:
        analyses.append(_analyze_sleep(request.sleep_hours))
    if request.hrv > 0:
        analyses.append(_analyze_hrv(request.hrv))
    if request.resting_hr > 0:
        analyses.append(_analyze_resting_hr(request.resting_hr))

    # 综合评分
    avg_score = sum(a["score"] for a in analyses) / len(analyses) if analyses else 50

    return {
        "success": True,
        "data": {
            "input": {
                "steps": request.steps,
                "sleep_hours": request.sleep_hours,
                "resting_hr": request.resting_hr,
                "hrv": request.hrv,
            },
            "analyses": analyses,
            "overall_score": round(avg_score, 1),
            "health_status": "需要调理" if avg_score > 60 else "良好",
        },
    }


@router.get("/tcm-metrics/{user_id}", summary="TCM 体质评分")
async def get_tcm_metrics(user_id: str):
    """
    基于历史健康数据推导的 TCM 体质指标评分（0-100）。
    """
    if user_id not in _health_data or not _health_data[user_id]:
        return {
            "success": True,
            "data": {
                "user_id": user_id,
                "qi_deficiency_score": 50,
                "yin_deficiency_score": 50,
                "liver_stagnation_score": 50,
                "damp_heat_score": 50,
                "heart_yin_deficiency_score": 50,
                "message": "数据不足，请先同步健康数据",
            },
        }

    records = _health_data[user_id]

    # 简化计算：按最近数据估算
    qi_score = 50
    yin_score = 50
    liver_score = 50
    damp_heat_score = 50
    heart_yin_score = 50

    for r in records[-10:]:
        if r["data_type"] == "steps" and r["value"] < 5000:
            qi_score += 10
        if r["data_type"] == "sleep" and r["value"] < 7:
            heart_yin_score += 10
        if r["data_type"] == "hrv" and r["value"] < 40:
            liver_score += 15
        if r["data_type"] == "heart_rate" and r["value"] > 80:
            yin_score += 10

    return {
        "success": True,
        "data": {
            "user_id": user_id,
            "qi_deficiency_score": min(qi_score, 100),
            "yin_deficiency_score": min(yin_score, 100),
            "liver_stagnation_score": min(liver_score, 100),
            "damp_heat_score": min(damp_heat_score, 100),
            "heart_yin_deficiency_score": min(heart_yin_score, 100),
            "last_updated": datetime.now().isoformat(),
        },
    }


@router.get("/recommendations/{user_id}", summary="个性化养护建议")
async def get_recommendations(user_id: str):
    """
    基于用户的健康数据历史生成个性化的 TCM 养护建议。
    """
    if user_id not in _health_data or not _health_data[user_id]:
        return {
            "success": True,
            "data": {
                "user_id": user_id,
                "recommendations": [
                    "请先同步您的健康数据以获得个性化建议",
                    "可以从 Apple Health 或 Google Fit 导入步数、睡眠等数据",
                ],
            },
        }

    records = _health_data[user_id]
    recommendations = []

    # 根据最近数据生成建议
    if any(r["data_type"] == "steps" and r["value"] < 5000 for r in records[-5:]):
        recommendations.append({
            "category": "运动",
            "priority": "高",
            "suggestion": "每日步数不足，建议每日增加至 8000-10000 步，可进行太极拳、八段锦等中医功法",
        })

    if any(r["data_type"] == "sleep" and r["value"] < 7 for r in records[-5:]):
        recommendations.append({
            "category": "睡眠",
            "priority": "高",
            "suggestion": "睡眠不足，建议晚上 11 点前入睡，可用酸枣仁、龙眼肉泡茶助眠",
        })

    if any(r["data_type"] == "hrv" and r["value"] < 40 for r in records[-5:]):
        recommendations.append({
            "category": "心理",
            "priority": "中",
            "suggestion": "心率变异度低，提示肝气郁结，建议进行深呼吸、冥想、按摩合谷穴和太冲穴",
        })

    if any(r["data_type"] == "heart_rate" and r["value"] > 80 for r in records[-5:]):
        recommendations.append({
            "category": "滋阴",
            "priority": "中",
            "suggestion": "静息心率过高，提示阴虚火旺，建议食用麦冬、银耳、绿豆等滋阴食物",
        })

    if not recommendations:
        recommendations.append({
            "category": "保健",
            "priority": "低",
            "suggestion": "您的健康指标良好，建议保持现有生活习惯，定期检查",
        })

    return {
        "success": True,
        "data": {
            "user_id": user_id,
            "total_recommendations": len(recommendations),
            "recommendations": recommendations,
            "last_updated": datetime.now().isoformat(),
        },
    }


@router.delete("/delete/{user_id}", summary="删除用户健康数据")
async def delete_user_data(user_id: str):
    """
    根据 GDPR 等隐私法规，删除用户的所有健康数据。
    """
    if user_id not in _health_data:
        raise HTTPException(status_code=404, detail=f"User {user_id} has no data")

    del _health_data[user_id]

    return {
        "success": True,
        "data": {
            "user_id": user_id,
            "deleted": True,
            "message": "用户所有健康数据已删除（GDPR 合规）",
            "timestamp": datetime.now().isoformat(),
        },
    }
