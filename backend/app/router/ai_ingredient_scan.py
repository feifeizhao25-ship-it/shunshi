"""
顺时 — AI食材扫描 API (shunshi-ai-ingredient-scan)
扫描食材识别、营养分析、中医属性查询
"""

import json
import logging
import os
import re

import httpx
from fastapi import APIRouter, HTTPException, Query, Request
from pydantic import BaseModel, Field
from typing import Optional, List, Dict

from ..aigc import ai_disclosure
from ..llm import cost_cap
from ..llm.domestic_gateway import host_allowed, llm_timeout
from ..llm.guardrail import moderate_image, moderate_text

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/ingredient-scan", tags=["ai-ingredient-scan"])

INGREDIENT_DATABASE = {
    "goji_berry": {
        "name_cn": "枸杞", "name_en": "Goji Berry",
        "calories_per_100g": 349, "protein": 14.4, "carbs": 64.1, "fat": 0.4,
        "tcm": {"nature": "平", "flavor": "甘", "meridians": ["肝经", "肾经"], "functions": ["滋补肝肾", "益精明目"]},
        "season_best": ["autumn", "winter"],
        "constitution_suit": ["yin_deficiency", "qi_deficiency"],
        "constitution_avoid": ["damp_heat"],
        "cooking_tips": "泡茶、煮粥、炖汤均可，不宜煎炸"
    },
    "jujube": {
        "name_cn": "红枣", "name_en": "Jujube/Red Date",
        "calories_per_100g": 264, "protein": 3.7, "carbs": 67.8, "fat": 0.5,
        "tcm": {"nature": "温", "flavor": "甘", "meridians": ["脾经", "胃经"], "functions": ["补中益气", "养血安神"]},
        "season_best": ["all"],
        "constitution_suit": ["qi_deficiency", "blood_deficiency"],
        "constitution_avoid": ["damp_heat", "phlegm_dampness"],
        "cooking_tips": "去核后泡茶、煮粥；痰湿体质少食"
    },
    "lotus_root": {
        "name_cn": "莲藕", "name_en": "Lotus Root",
        "calories_per_100g": 74, "protein": 1.9, "carbs": 17.1, "fat": 0.1,
        "tcm": {"nature": "生用寒，熟用温", "flavor": "甘", "meridians": ["心经", "脾经", "胃经"],
                "functions": ["清热凉血（生用）", "健脾开胃（熟用）"]},
        "season_best": ["autumn"],
        "constitution_suit": ["yin_deficiency", "damp_heat"],
        "constitution_avoid": ["yang_deficiency"],
        "cooking_tips": "生食清热，煮熟温补；秋季食用最宜"
    },
    "yam": {
        "name_cn": "山药", "name_en": "Chinese Yam",
        "calories_per_100g": 63, "protein": 1.9, "carbs": 14.4, "fat": 0.2,
        "tcm": {"nature": "平", "flavor": "甘", "meridians": ["脾经", "肺经", "肾经"],
                "functions": ["补脾养胃", "生津益肺", "补肾涩精"]},
        "season_best": ["all"],
        "constitution_suit": ["qi_deficiency", "yin_deficiency", "phlegm_dampness"],
        "constitution_avoid": [],
        "cooking_tips": "清炒、蒸、煮汤均可；脾胃虚弱者最宜"
    },
    "hawthorn": {
        "name_cn": "山楂", "name_en": "Hawthorn",
        "calories_per_100g": 102, "protein": 0.7, "carbs": 25.1, "fat": 0.6,
        "tcm": {"nature": "微温", "flavor": "酸、甘", "meridians": ["脾经", "胃经", "肝经"],
                "functions": ["消食健胃", "行气散瘀", "降脂"]},
        "season_best": ["autumn"],
        "constitution_suit": ["qi_stagnation", "blood_stasis", "phlegm_dampness"],
        "constitution_avoid": ["spleen_stomach_weak"],
        "cooking_tips": "山楂茶、山楂糕；孕妇及胃酸多者慎用"
    }
}


class ScanResultRequest(BaseModel):
    image_url: Optional[str] = Field(None, description="食材图片URL")
    ingredient_name: Optional[str] = Field(None, description="直接输入食材名称")
    user_constitution: Optional[str] = Field(None, description="用户体质（用于个性化建议）")
    current_season: Optional[str] = Field(None, description="当前季节")


class MultiIngredientAnalysisRequest(BaseModel):
    ingredients: List[str] = Field(..., min_length=2, max_length=10, description="食材名称列表")
    user_constitution: Optional[str] = Field(None)


def _find_ingredient(name: str) -> Optional[dict]:
    """按名称查找食材（模糊匹配）"""
    for key, ing in INGREDIENT_DATABASE.items():
        if name in ing["name_cn"] or name.lower() in ing["name_en"].lower():
            return {"id": key, **ing}
    return None


# 国内视觉模型：MiniMax 开放平台（境内）OpenAI 兼容 Chat Completions，图片用 image_url 内容块。
# 官方文档：https://platform.minimaxi.com/docs/api-reference/text-openai-api （多模态输入）
#           https://platform.minimaxi.com/docs/api-reference/text-chat-openai （POST /v1/chat/completions）
# 文档只在 MiniMax-M3 / MiniMax-M3.1-Flash 上列出图片输入；MiniMax-VL-01 不在官方模型列表里，所以缺省用 MiniMax-M3。
# 模型名可用 SHUNSHI_VISION_MODEL 覆盖。密钥只读环境变量，不写进代码、不进日志。
VISION_ENDPOINT = "https://api.minimax.cn/v1/chat/completions"
DEFAULT_VISION_MODEL = "MiniMax-M3"
VISION_KEY_VARS = ("SHUNSHI_MINIMAX_API_KEY", "MINIMAX_API_KEY")
VISION_PROMPT = (
    "识别图片中最主要的可食用食材。只返回JSON："
    "{\"ingredient_name_cn\":\"名称或未知\",\"confidence\":0到1}。"
    "不确定时必须返回未知，禁止猜测。"
)

MSG_UNCONFIGURED = "图片识别服务暂未配置，请改为输入食材名称"
MSG_OVER_CAP = "今日图片识别次数已达上限，请明天再试，或直接输入食材名称"
MSG_REJECTED = "图片未通过内容安全审核，请换一张食材图片，或直接输入食材名称"
MSG_MODERATION_DOWN = "图片内容安全审核暂时不可用，请稍后再试，或直接输入食材名称"

# 视觉调用的费用估算（元）：输入 token 取单张低清图加提示词的保守值，输出取 max token。
_EST_TOKENS_IN = 800
_EST_TOKENS_OUT = 120
_TRANSPORT_LABELS = ("transport", "json", "unreadable")


def _vision_model(env: dict | None = None) -> str:
    source = os.environ if env is None else env
    return (source.get("SHUNSHI_VISION_MODEL") or "").strip() or DEFAULT_VISION_MODEL


def _vision_api_key(source: dict) -> str:
    for name in VISION_KEY_VARS:
        value = (source.get(name) or "").strip()
        if value:
            return value
    return ""


def _vision_caps(user_id: str, env: dict) -> list[tuple[str, float]]:
    uid = user_id or "anonymous"
    return [
        (f"vision:user:{uid}", cost_cap.vision_user_daily_cap_cny(env)),
        ("vision:product", cost_cap.vision_product_daily_cap_cny(env)),
        (f"user:{uid}", cost_cap.user_daily_cap_cny(env)),
        ("product", cost_cap.product_daily_cap_cny(env)),
    ]


def _vision_over_cap(user_id: str, model: str, env: dict) -> bool:
    amount = cost_cap.estimate_cost_cny(model, _EST_TOKENS_IN, _EST_TOKENS_OUT, env)
    amount += cost_cap.guardrail_cost_cny(2, env)  # 图片审核一次 + 结果文字审核一次
    return any(cost_cap.would_exceed(scope, amount, cap) for scope, cap in _vision_caps(user_id, env))


def _vision_charge(user_id: str, amount: float, env: dict) -> None:
    for scope, _cap in _vision_caps(user_id, env):
        cost_cap.record(scope, amount)


def _text_moderation_unavailable(verdict) -> bool:
    """文字审核没真正跑成（没配、网络错、返回异常）一律按不可用处理，不放行。"""
    if not verdict.checked:
        return True
    return verdict.hit and (verdict.labels in _TRANSPORT_LABELS or verdict.labels.startswith(("http-", "code-")))


def _vision_detail(source: dict) -> str:
    value = (source.get("SHUNSHI_VISION_IMAGE_DETAIL") or "low").strip().lower()
    return value if value in {"low", "default", "high"} else "low"


async def _recognize_ingredient_image(
    image_url: str,
    *,
    user_id: str = "anonymous",
    client: httpx.AsyncClient | None = None,
    env: dict | None = None,
) -> tuple[str, float, str]:
    """用境内视觉模型识别食材图片。没配密钥或模型无把握时不编造结果。

    顺序：密钥 → 日费用上限（429）→ 图片内容安全审核（不过 422，审核不可用 503，都不调用模型）
    → 视觉模型 → 记费用 → 识别结果文字审核。任何一步不确定都按拒绝处理。
    """
    if not image_url.startswith("https://"):
        raise HTTPException(status_code=400, detail="食材图片必须使用可公开访问的 HTTPS 地址")
    source = os.environ if env is None else env
    api_key = _vision_api_key(source)
    if not api_key:
        raise HTTPException(status_code=503, detail=MSG_UNCONFIGURED)
    if not host_allowed(httpx.URL(VISION_ENDPOINT).host):
        raise HTTPException(status_code=503, detail=MSG_UNCONFIGURED)
    model = _vision_model(source)

    if _vision_over_cap(user_id, model, source):
        logger.info("vision cost cap: user=%s model=%s", user_id or "anonymous", model)
        raise HTTPException(status_code=429, detail=MSG_OVER_CAP)

    owns_client = client is None
    client = client or httpx.AsyncClient()
    try:
        moderation = await moderate_image(image_url, client=client, env=source)
        if moderation.requested:
            _vision_charge(user_id, cost_cap.guardrail_cost_cny(1, source), source)
        if moderation.status == "unavailable":
            raise HTTPException(status_code=503, detail=MSG_MODERATION_DOWN)
        if moderation.status == "reject":
            logger.info("vision image rejected by moderation: user=%s labels=%s", user_id or "anonymous", moderation.labels)
            raise HTTPException(status_code=422, detail=MSG_REJECTED)

        image_part: dict = {"url": image_url, "detail": _vision_detail(source)}
        payload: dict = {
            "model": model,
            "max_completion_tokens": _EST_TOKENS_OUT,
            "messages": [{
                "role": "user",
                "content": [
                    {"type": "text", "text": VISION_PROMPT},
                    {"type": "image_url", "image_url": image_part},
                ],
            }],
        }
        if "flash" in model.lower():
            # M3.1-Flash 的思考无法关闭，思考 token 也计入上限，给足额度并用最低档。
            payload["reasoning_effort"] = "low"
            payload["max_completion_tokens"] = 1024
        else:
            payload["thinking"] = {"type": "disabled"}
        try:
            response = await client.post(
                VISION_ENDPOINT,
                json=payload,
                headers={"Authorization": f"Bearer {api_key}"},
                timeout=llm_timeout(source),
            )
        except httpx.HTTPError as exc:
            raise HTTPException(status_code=502, detail="图片识别服务连接失败") from exc
        if response.status_code != 200:
            raise HTTPException(status_code=502, detail="图片识别服务暂时不可用")

        try:
            body = response.json()
        except ValueError as exc:
            raise HTTPException(status_code=502, detail="图片识别服务返回格式无效") from exc
        usage = body.get("usage") if isinstance(body, dict) else None
        tokens_in, tokens_out = _EST_TOKENS_IN, _EST_TOKENS_OUT
        if isinstance(usage, dict):
            if isinstance(usage.get("prompt_tokens"), int):
                tokens_in = usage["prompt_tokens"]
            if isinstance(usage.get("completion_tokens"), int):
                tokens_out = usage["completion_tokens"]
        _vision_charge(user_id, cost_cap.estimate_cost_cny(model, tokens_in, tokens_out, source), source)

        try:
            content = body["choices"][0]["message"]["content"]
            content = re.sub(r"<think>.*?</think>", "", content, flags=re.DOTALL)
            content = re.sub(r"^```(?:json)?\s*|\s*```$", "", content.strip())
            parsed = json.loads(content)
            name = str(parsed["ingredient_name_cn"]).strip()
            confidence = max(0.0, min(1.0, float(parsed["confidence"])))
        except (KeyError, IndexError, TypeError, ValueError, json.JSONDecodeError) as exc:
            raise HTTPException(status_code=502, detail="图片识别服务返回格式无效") from exc
        # 低把握一律按「未知」处理，由调用方提示用户核对或手动输入。
        if not name or name == "未知" or confidence < 0.6:
            return "未知", confidence, model

        verdict = await moderate_text(name, client=client, env=source)
        if verdict.checked:
            _vision_charge(user_id, cost_cap.guardrail_cost_cny(1, source), source)
        if _text_moderation_unavailable(verdict):
            raise HTTPException(status_code=503, detail=MSG_MODERATION_DOWN)
        if verdict.hit:
            logger.info("vision output rejected by moderation: user=%s labels=%s", user_id or "anonymous", verdict.labels)
            raise HTTPException(status_code=422, detail=MSG_REJECTED)
        return name, confidence, model
    finally:
        if owns_client:
            await client.aclose()


@router.post("/scan", summary="扫描/识别食材")
async def scan_ingredient(request: ScanResultRequest, http_request: Request):
    if not request.ingredient_name and not request.image_url:
        raise HTTPException(status_code=400, detail="请提供食材图片或名称")

    if request.image_url and not request.ingredient_name:
        recognized_name, confidence, recognition_model = await _recognize_ingredient_image(
            request.image_url,
            user_id=getattr(http_request.state, "user_id", "") or "anonymous",
        )
    else:
        recognized_name = request.ingredient_name
        confidence = 1.0
        recognition_model = None

    ingredient = _find_ingredient(recognized_name)
    if not ingredient:
        return {
            "success": True,
            "data": {
                "recognized": recognized_name,
                "confidence": confidence,
                "found_in_database": False,
                "recognition_model": recognition_model,
                "message": "未能可靠匹配食材资料，请核对识别结果或直接输入名称"
            },
            # 图片识别结果来自模型：显式标识
            **(ai_disclosure() if recognition_model else {}),
        }

    # 个性化建议
    personalized_advice = {}
    if request.user_constitution:
        if request.user_constitution in ingredient["constitution_suit"]:
            personalized_advice["suitability"] = "非常适合您的体质"
        elif request.user_constitution in ingredient["constitution_avoid"]:
            personalized_advice["suitability"] = "不太适合您的体质，建议少食"
        else:
            personalized_advice["suitability"] = "对您的体质基本适合"

    # 季节建议
    season_advice = ""
    if request.current_season:
        if "all" in ingredient["season_best"] or request.current_season in ingredient["season_best"]:
            season_advice = "当季食用，效果最佳"
        else:
            season_advice = "非最佳食用季节，可适量食用"

    return {
        "success": True,
        "data": {
            "recognized": recognized_name,
            "confidence": confidence,
            "recognition_model": recognition_model,
            "found_in_database": True,
            "ingredient": ingredient,
            "personalized_advice": personalized_advice,
            "season_advice": season_advice,
            "disclaimer": "营养及中医属性仅作一般信息参考，不能替代医生或营养师建议"
        },
        **(ai_disclosure() if recognition_model else {}),
    }


@router.get("/search", summary="搜索食材")
async def search_ingredient(q: str = Query(..., description="食材名称")):
    results = []
    for key, ing in INGREDIENT_DATABASE.items():
        if q in ing["name_cn"] or q.lower() in ing["name_en"].lower():
            results.append({"id": key, **ing})
    return {"success": True, "data": {"results": results, "total": len(results)}}


@router.get("/{ingredient_id}", summary="食材详情")
async def get_ingredient(ingredient_id: str):
    if ingredient_id not in INGREDIENT_DATABASE:
        raise HTTPException(status_code=404, detail="食材不存在")
    return {"success": True, "data": {"id": ingredient_id, **INGREDIENT_DATABASE[ingredient_id]}}


@router.post("/analyze-combination", summary="分析食材搭配")
async def analyze_combination(request: MultiIngredientAnalysisRequest):
    found = []
    not_found = []
    for name in request.ingredients:
        ing = _find_ingredient(name)
        if ing:
            found.append(ing)
        else:
            not_found.append(name)

    # 分析性质冲突
    natures = [f["tcm"]["nature"] for f in found]
    has_cold = any("寒" in n or "凉" in n for n in natures)
    has_hot = any("热" in n or "温" in n for n in natures)

    analysis = {
        "ingredients_found": found,
        "ingredients_not_found": not_found,
        "total_calories": sum(f.get("calories_per_100g", 0) * 0.1 for f in found),
        "nature_balance": {
            "has_cold_ingredients": has_cold,
            "has_hot_ingredients": has_hot,
            "is_balanced": not (has_cold and has_hot)
        },
        "advice": "食材性质平衡，搭配合理" if not (has_cold and has_hot) else "食材中有寒热混搭，体质偏寒者注意"
    }
    return {"success": True, "data": {"analysis": analysis}}


@router.get("/by-constitution/{constitution}", summary="按体质推荐食材")
async def get_by_constitution(constitution: str, season: Optional[str] = Query(None)):
    ingredients = [
        {"id": k, **v} for k, v in INGREDIENT_DATABASE.items()
        if constitution in v["constitution_suit"]
        and (not season or "all" in v["season_best"] or season in v["season_best"])
    ]
    return {"success": True, "data": {"constitution": constitution, "ingredients": ingredients}}
