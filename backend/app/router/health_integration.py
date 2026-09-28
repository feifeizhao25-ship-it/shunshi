"""
顺时 — 健康数据集成与 TCM 分析
记录健康指标；不从可穿戴单项数值推导未经验证的诊断或体质评分。
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field, model_validator
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
    value: float = Field(..., ge=0, allow_inf_nan=False, description="数值")
    unit: str = Field(..., description="单位: steps/hours/bpm/ms/kg等")
    recorded_at: str = Field(..., description="ISO 8601 日期时间")
    source: SourceEnum

    @model_validator(mode="after")
    def validate_measurement(self):
        expected = {"steps": "steps", "sleep": "hours", "heart_rate": "bpm", "hrv": "ms", "weight": "kg"}
        if self.unit != expected[self.data_type.value]:
            raise ValueError("数值单位与指标不匹配")
        if self.data_type in {DataTypeEnum.HEART_RATE, DataTypeEnum.HRV, DataTypeEnum.WEIGHT} and self.value <= 0:
            raise ValueError("该指标数值必须大于零")
        if self.data_type == DataTypeEnum.STEPS and not self.value.is_integer():
            raise ValueError("步数必须为整数")
        datetime.fromisoformat(self.recorded_at.replace("Z", "+00:00"))
        return self


class TCMAnalysisRequest(BaseModel):
    steps: int = Field(default=0, ge=0, allow_inf_nan=False)
    sleep_hours: float = Field(default=0, ge=0, allow_inf_nan=False)
    resting_hr: int = Field(default=0, ge=0, allow_inf_nan=False)
    hrv: int = Field(default=0, ge=0, allow_inf_nan=False)


# ─────────────────────────────────────────────────────────────────────────────
# 内存存储
# ─────────────────────────────────────────────────────────────────────────────

_health_data: Dict[str, List[Dict[str, Any]]] = {}


# ─────────────────────────────────────────────────────────────────────────────
# TCM 数据类型映射规则
# ─────────────────────────────────────────────────────────────────────────────

def _observation(label: str, value: float, unit: str) -> Dict[str, Any]:
    """A wearable reading is an observation, not a validated constitution test."""
    return {
        "constitution": "无法仅凭该数据判定体质",
        "score": None,
        "diagnostic": False,
        "evidence_status": "insufficient_for_diagnosis",
        "insight": f"本次记录：{label} {value:g} {unit}。单项数值不能代表整体健康状况。",
        "recommendation": "可记录测量时间与当时感受，供后续核对；如有不适，请向医疗专业人员咨询。",
    }


def _analyze_steps(steps: int) -> Dict[str, Any]:
    return _observation("步数", steps, "步")


def _analyze_sleep(sleep_hours: float) -> Dict[str, Any]:
    return _observation("睡眠时长", sleep_hours, "小时")


def _analyze_hrv(hrv: int) -> Dict[str, Any]:
    return _observation("心率变异度", hrv, "毫秒")


def _analyze_resting_hr(resting_hr: int) -> Dict[str, Any]:
    return _observation("静息心率", resting_hr, "次/分钟")


def _analyze_weight(weight: float, user_id: str) -> Dict[str, Any]:
    return _observation("体重", weight, "千克")


@router.post("/sync", summary="同步健康数据")
async def sync_health_data(request: HealthDataSyncRequest):
    """
    接收来自 Apple Health / Google Fit 的健康数据同步，
    返回非诊断性记录说明。
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
    整理当前指标，明确其不足以形成体质诊断。
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
            "overall_score": None,
            "diagnostic": False,
            "evidence_status": "insufficient_for_diagnosis",
            "health_status": "无法仅凭这些记录判断健康状况",
        },
    }


@router.get("/tcm-metrics/{user_id}", summary="TCM 体质评分")
async def get_tcm_metrics(user_id: str):
    """
    兼容旧评分字段，但没有验证依据时返回空值而非虚构分数。
    """
    return {
        "success": True,
        "data": {
            "user_id": user_id,
            "qi_deficiency_score": None,
            "yin_deficiency_score": None,
            "liver_stagnation_score": None,
            "damp_heat_score": None,
            "heart_yin_deficiency_score": None,
            "diagnostic": False,
            "evidence_status": "insufficient_for_diagnosis",
            "message": "这些记录不能用于计算中医体质评分，未提供诊断结果。",
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

    labels = {"steps": "步数", "sleep": "睡眠", "hrv": "心率变异度", "heart_rate": "心率", "weight": "体重"}
    for data_type in dict.fromkeys(record["data_type"] for record in records[-5:]):
        label = labels.get(data_type, "健康记录")
        recommendations.append({
            "category": label,
            "priority": "普通",
            "suggestion": f"已记录{label}，可补充测量时间与当时感受。此记录不提供体质诊断或用药建议。",
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
        raise HTTPException(status_code=404, detail="该用户暂无健康记录")

    del _health_data[user_id]

    return {
        "success": True,
        "data": {
            "user_id": user_id,
            "deleted": True,
            "message": "本功能保存的健康记录已删除",
            "timestamp": datetime.now().isoformat(),
        },
    }
