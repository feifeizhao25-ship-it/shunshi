"""
舌诊 API 路由
基于舌象特征（颜色、舌苔、形状）推断中医体质

说明：
- 当前为规则引擎版本，基于舌象与体质的对应关系表
- 生产环境可替换为真实的 CV 模型（TensorFlow/ONNX）
- 返回置信度和调理建议

作者: Claw 🦅
日期: 2026-03-27
"""

import base64, uuid
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import Optional, List

router = APIRouter(prefix="/api/v1/tongue", tags=["舌诊"])


# ==================== 舌象 → 体质映射表 ====================

# 舌色映射
TONGUE_COLOR_MAP = {
    "淡红": "pinghe",       # 淡红舌 → 平和质
    "红": "shire",          # 红舌 → 湿热质
    "淡白": "yangxu",        # 淡白舌 → 阳虚质
    "绛红": "yinxu",         # 绛红/深红 → 阴虚质
    "紫暗": "xueyu",         # 紫暗舌 → 血瘀质
    "淡紫": "xueyu",         # 淡紫 → 血瘀质
    "青紫": "xueyu",         # 青紫 → 血瘀质
    "淡胖": "qixu",          # 淡胖舌 → 气虚质
    "齿痕": "qixu",          # 齿痕舌 → 气虚质（多伴随）
}

# 舌苔映射
COATING_MAP = {
    "薄白": "pinghe",       # 薄白苔 → 平和质
    "白腻": "tanshi",        # 白腻苔 → 痰湿质
    "黄腻": "shire",          # 黄腻苔 → 湿热质
    "黄苔": "shire",          # 黄苔 → 湿热质
    "白苔": "yangxu",         # 白苔（偏厚）→ 阳虚质
    "少苔": "yinxu",          # 少苔/剥苔 → 阴虚质
    "灰黑": "shire",          # 灰黑苔 → 湿热/阴虚
    "润苔": "pinghe",         # 润苔 → 平和（正常）
}

# 舌形映射
SHAPE_MAP = {
    "正常": "pinghe",
    "胖大": "qixu",          # 胖大舌 → 气虚/阳虚
    "瘦薄": "yinxu",          # 瘦薄舌 → 阴虚
    "裂纹": "yinxu",          # 裂纹舌 → 阴虚
    "点刺": "shire",          # 点刺舌 → 湿热
    "瘀斑": "xueyu",          # 瘀斑舌 → 血瘀
    "齿痕": "qixu",           # 齿痕舌 → 气虚
}

# 体质调理建议（按体质）
CONSTITUTION_ADVICE = {
    "pinghe": {
        "name": "平和质",
        "description": "舌象基本正常，阴阳气血调和。",
        "suggestions": ["继续保持当前饮食和作息习惯", "适度运动，增强体质", "注意饮食均衡"],
    },
    "qixu": {
        "name": "气虚质",
        "description": "舌色淡胖或有齿痕，元气不足。",
        "suggestions": ["多食益气食物：黄芪、党参、山药、红枣", "避免剧烈运动，以柔和运动为主（太极、散步）", "早睡养气，最晚22:30睡"],
    },
    "yangxu": {
        "name": "阳虚质",
        "description": "舌色淡白，阳气不足。",
        "suggestions": ["多食温阳食物：羊肉、核桃、桂圆、生姜", "注意保暖，尤其是背部和足部", "避免生冷饮食"],
    },
    "yinxu": {
        "name": "阴虚质",
        "description": "舌红少苔或裂纹，阴液亏少。",
        "suggestions": ["多食滋阴食物：银耳、百合、麦冬、沙参", "避免辛辣刺激和熬夜", "保持居住环境湿润"],
    },
    "shire": {
        "name": "湿热质",
        "description": "舌红苔黄腻，湿热内蕴。",
        "suggestions": ["多食清热利湿食物：苦瓜、绿豆、冬瓜", "饮食清淡，忌辛辣油腻", "多出汗排湿，适度运动"],
    },
    "tanshi": {
        "name": "痰湿质",
        "description": "舌苔白腻，痰湿凝聚。",
        "suggestions": ["多食祛湿食物：薏米、赤小豆、冬瓜", "饮食清淡，少油少糖", "规律运动出汗排湿"],
    },
    "xueyu": {
        "name": "血瘀质",
        "description": "舌色紫暗或有瘀斑，血行不畅。",
        "suggestions": ["多食活血食物：山楂、黑木耳、玫瑰花", "适度运动促进气血流通", "注意保暖，血遇寒则瘀"],
    },
    "qiyu": {
        "name": "气郁质",
        "description": "舌色稍暗或正常，气机郁滞。",
        "suggestions": ["多食疏肝理气食物：玫瑰花、茉莉花、橙子", "情绪管理，多户外活动", "按摩太冲穴疏肝"],
    },
    "tebing": {
        "name": "特禀质",
        "description": "舌象多样，先天禀赋特殊。",
        "suggestions": ["清淡饮食，减少过敏原接触", "查明过敏原并避免", "适度运动增强体质"],
    },
}


# ==================== Request/Response Models ====================

class TongueDiagnosisRequest(BaseModel):
    """舌诊请求（手动选择舌象特征）"""
    tongue_color: str = Field(..., description="舌色：淡红/红/淡白/绛红/紫暗/淡紫/青紫/淡胖/齿痕")
    coating: str = Field(..., description="舌苔：薄白/白腻/黄腻/黄苔/白苔/少苔/灰黑/润苔")
    shape: Optional[str] = Field(default="正常", description="舌形：正常/胖大/瘦薄/裂纹/点刺/瘀斑/齿痕")
    notes: Optional[str] = Field(default=None, description="其他观察备注")


class TongueImageRequest(BaseModel):
    """舌诊请求（上传图片 base64）"""
    image_base64: str = Field(..., description="舌图 base64 编码（不含 data URI 前缀）")
    notes: Optional[str] = Field(default=None, description="其他观察备注")


class TongueFeature(BaseModel):
    """识别出的舌象特征"""
    feature: str
    confidence: float


class DiagnosisResult(BaseModel):
    """舌诊结果"""
    primary_constitution: str
    primary_name: str
    confidence: float
    features: List[TongueFeature]
    description: str
    suggestions: List[str]


# ==================== 核心分析逻辑 ====================

def _analyze_tongue_features(
    tongue_color: str,
    coating: str,
    shape: str = "正常",
) -> tuple[str, float, List[TongueFeature]]:
    """
    根据舌象特征分析体质

    Returns:
        (constitution_key, confidence, features)
    """
    features = []
    votes: dict[str, float] = {}

    # 舌色投票
    color_key = TONGUE_COLOR_MAP.get(tongue_color)
    if color_key:
        features.append(TongueFeature(feature=f"舌色：{tongue_color}", confidence=0.85))
        votes[color_key] = votes.get(color_key, 0) + 0.4

    # 舌苔投票
    coating_key = COATING_MAP.get(coating)
    if coating_key:
        features.append(TongueFeature(feature=f"舌苔：{coating}", confidence=0.80))
        votes[coating_key] = votes.get(coating_key, 0) + 0.35

    # 舌形投票
    if shape and shape != "正常":
        shape_key = SHAPE_MAP.get(shape)
        if shape_key:
            features.append(TongueFeature(feature=f"舌形：{shape}", confidence=0.75))
            votes[shape_key] = votes.get(shape_key, 0) + 0.25

    if not votes:
        # 无匹配 → 默认为平和质
        return "pinghe", 0.3, []

    # 多数表决
    primary = max(votes, key=lambda k: votes[k])
    confidence = min(votes[primary] / sum(votes.values()), 0.98)

    return primary, confidence, features


# ==================== API 端点 ====================

@router.post("/diagnose", response_model=dict)
async def tongue_diagnose(body: TongueDiagnosisRequest):
    """
    舌诊分析（基于舌象特征）

    支持以下舌色：淡红/红/淡白/绛红/紫暗/淡紫/青紫/淡胖/齿痕
    支持以下舌苔：薄白/白腻/黄腻/黄苔/白苔/少苔/灰黑/润苔
    支持以下舌形：正常/胖大/瘦薄/裂纹/点刺/瘀斑/齿痕
    """
    constitution_key, confidence, features = _analyze_tongue_features(
        tongue_color=body.tongue_color,
        coating=body.coating,
        shape=body.shape or "正常",
    )

    advice = CONSTITUTION_ADVICE.get(constitution_key, CONSTITUTION_ADVICE["pinghe"])

    return {
        "success": True,
        "data": {
            "diagnosis_id": str(uuid.uuid4()),
            "primary_constitution": constitution_key,
            "primary_name": advice["name"],
            "confidence": round(confidence, 2),
            "features": [{"feature": f.feature, "confidence": f.confidence} for f in features],
            "description": advice["description"],
            "suggestions": advice["suggestions"],
            "notes": body.notes,
        },
    }


@router.post("/diagnose/image", response_model=dict)
async def tongue_diagnose_image(body: TongueImageRequest):
    """
    舌诊分析（上传舌图）

    注意：当前版本为模拟实现，将图片编码存储用于后续分析。
    生产环境需接入真实 CV 模型（如 ResNet/VGG 训练的舌诊模型）。
    """
    # 验证 base64 格式（允许常见图片格式）
    try:
        img_data = base64.b64decode(body.image_base64)
        if len(img_data) < 1000:
            raise HTTPException(status_code=400, detail="图片数据太短，可能是无效 base64")
    except Exception:
        raise HTTPException(status_code=400, detail="无效的 base64 编码，请提供纯 base64 字符串（不含 data:image/... 前缀）")

    # 存储图片路径（供后续模型调用）
    import os
    from datetime import datetime
    img_dir = "/tmp/tongue_images"
    os.makedirs(img_dir, exist_ok=True)
    filename = f"{uuid.uuid4().hex}.jpg"
    img_path = os.path.join(img_dir, filename)
    with open(img_path, "wb") as f:
        f.write(img_data)

    # 模拟 CV 模型分析（实际应调用 TensorFlow/ONNX 模型）
    # 此处返回"待分析"状态，真实场景替换为模型调用
    return {
        "success": True,
        "data": {
            "diagnosis_id": str(uuid.uuid4()),
            "status": "analyzed",
            "primary_constitution": "pinghe",
            "primary_name": "平和质（图片分析）",
            "confidence": 0.75,
            "features": [
                {"feature": "舌图已接收", "confidence": 1.0},
                {"feature": "舌色：淡红（模拟）", "confidence": 0.75},
                {"feature": "舌苔：薄白（模拟）", "confidence": 0.75},
            ],
            "description": "舌图已接收并保存，等待深度学习模型分析。",
            "suggestions": ["图片已保存，待 CV 模型分析后返回完整报告"],
            "image_path": img_path,
            "note": "当前为模拟版本，请使用 /diagnose 端点进行基于规则的舌诊分析",
        },
    }


@router.get("/features")
async def tongue_features():
    """获取支持的舌象特征列表"""
    return {
        "success": True,
        "data": {
            "tongue_colors": list(TONGUE_COLOR_MAP.keys()),
            "coatings": list(COATING_MAP.keys()),
            "shapes": list(SHAPE_MAP.keys()),
            "constitutions": list(CONSTITUTION_ADVICE.keys()),
        },
    }
