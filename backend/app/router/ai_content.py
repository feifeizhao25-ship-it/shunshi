"""
顺时 — AI个性化内容生成引擎
基于模板和规则生成内容，不调用真实LLM，支持多场景和个性化
"""

from fastapi import APIRouter, HTTPException, Query
from typing import Optional, List, Dict, Any
from datetime import datetime
import hashlib
from pydantic import BaseModel

router = APIRouter(prefix="/api/v1/ai-content", tags=["ai_content_generator"])

# ─────────────────────────────────────────────────────────────────────────────
# 数据模型
# ─────────────────────────────────────────────────────────────────────────────

class Template(BaseModel):
    id: str
    scene: str
    template_cn: str
    template_en: str
    variables_required: List[str]
    variables_optional: List[str]
    tone: str  # warm/professional/playful


class GenerateRequest(BaseModel):
    template_id: str
    variables: Dict[str, Any]
    lang: str = "zh"  # zh or en
    user_id: Optional[str] = None


class BatchGenerateRequest(BaseModel):
    requests: List[Dict[str, Any]]  # Each: {template_id, variables, lang?}


class PreferencesMatrix:
    """体质×季节→内容风格映射"""
    def __init__(self):
        self.matrix = {
            ("qi_deficiency", "spring"): "warm",
            ("qi_deficiency", "summer"): "professional",
            ("qi_deficiency", "autumn"): "warm",
            ("qi_deficiency", "winter"): "warm",
            ("yin_deficiency", "spring"): "professional",
            ("yin_deficiency", "summer"): "professional",
            ("yin_deficiency", "autumn"): "warm",
            ("yin_deficiency", "winter"): "playful",
            ("yang_deficiency", "spring"): "warm",
            ("yang_deficiency", "summer"): "warm",
            ("yang_deficiency", "autumn"): "warm",
            ("yang_deficiency", "winter"): "warm",
            ("balanced", "spring"): "playful",
            ("balanced", "summer"): "playful",
            ("balanced", "autumn"): "professional",
            ("balanced", "winter"): "warm",
        }

    def get_tone(self, constitution: str, season: str) -> str:
        return self.matrix.get((constitution, season), "warm")


# ─────────────────────────────────────────────────────────────────────────────
# 内容模板库（12+个场景）
# ─────────────────────────────────────────────────────────────────────────────

TEMPLATES = [
    # 节气问候语
    {
        "id": "tpl_solar_1",
        "scene": "solar_term_greeting",
        "template_cn": "亲爱的{user_name}，{solar_term}时节，{constitution}体质的你应该{advice}。愿你康泰！",
        "template_en": "Dear {user_name}, during {solar_term}, as a {constitution} constitution person, you should {advice}. Stay healthy!",
        "variables_required": ["user_name", "solar_term", "constitution", "advice"],
        "variables_optional": [],
        "tone": "warm",
    },
    {
        "id": "tpl_solar_2",
        "scene": "solar_term_greeting",
        "template_cn": "{solar_term}到来，{constitution}体质宜{advice}，坚持调理身体最重要。——{user_name}",
        "template_en": "{solar_term} arrives, {constitution} constitution should {advice}. Keep adjusting your body. ——{user_name}",
        "variables_required": ["solar_term", "constitution", "advice", "user_name"],
        "variables_optional": [],
        "tone": "professional",
    },

    # 每日养生小贴士
    {
        "id": "tpl_daily_tip_1",
        "scene": "daily_tip",
        "template_cn": "今日提示：{season}季，{constitution}体质的你，{time_period}宜{tip}。坚持为妙！",
        "template_en": "Today's tip: In {season}, as a {constitution} person, {time_period} is ideal to {tip}.",
        "variables_required": ["season", "constitution", "time_period", "tip"],
        "variables_optional": [],
        "tone": "warm",
    },
    {
        "id": "tpl_daily_tip_2",
        "scene": "daily_tip",
        "template_cn": "{time_period}养生秘诀（{season}版）：{constitution}体质→{tip}。效果显著，试试看！",
        "template_en": "{time_period} wellness secret ({season} edition): {constitution} type → {tip}.",
        "variables_required": ["time_period", "season", "constitution", "tip"],
        "variables_optional": [],
        "tone": "playful",
    },

    # 体质报告开场白
    {
        "id": "tpl_report_intro",
        "scene": "constitution_report_intro",
        "template_cn": "你好{user_name}！根据数据分析，你是典型的{constitution}体质。这份个性化报告将为你揭示如何科学调理，激发身体的自愈力。",
        "template_en": "Hello {user_name}! Based on analysis, you are a typical {constitution} constitution. This report will guide you on scientific regulation.",
        "variables_required": ["user_name", "constitution"],
        "variables_optional": [],
        "tone": "professional",
    },

    # 食疗推荐理由
    {
        "id": "tpl_food_reason_1",
        "scene": "food_recommendation_reason",
        "template_cn": "为什么推荐{food}？{season}时节，{constitution}体质的你容易{issue}，而{food}能{benefit}，帮你调理体质。",
        "template_en": "Why {food}? In {season}, {constitution} types tend to {issue}, and {food} can {benefit}.",
        "variables_required": ["food", "season", "constitution", "issue", "benefit"],
        "variables_optional": [],
        "tone": "professional",
    },
    {
        "id": "tpl_food_reason_2",
        "scene": "food_recommendation_reason",
        "template_cn": "{food}：{season}养生必备！{constitution}体质的你吃它，就像给身体按下'恢复键'——{benefit}",
        "template_en": "{food}: Essential for {season} wellness! For {constitution} types, it's like hitting recovery — {benefit}",
        "variables_required": ["food", "season", "constitution", "benefit"],
        "variables_optional": [],
        "tone": "playful",
    },

    # 运动激励语
    {
        "id": "tpl_exercise_1",
        "scene": "exercise_motivation",
        "template_cn": "今日{exercise}已打卡！你正在一步步改善{constitution}体质，坚持就是胜利。再来{times}周，你会看到明显变化！",
        "template_en": "Today's {exercise} logged! You're gradually improving your {constitution} constitution. {times} more weeks for visible changes!",
        "variables_required": ["exercise", "constitution", "times"],
        "variables_optional": [],
        "tone": "warm",
    },
    {
        "id": "tpl_exercise_2",
        "scene": "exercise_motivation",
        "template_cn": "{exercise}小能手出现！你的{constitution}体质在默默变好，保持这份热情，身体会感谢你。",
        "template_en": "Great {exercise} streak! Your {constitution} constitution is quietly improving. Keep it up!",
        "variables_required": ["exercise", "constitution"],
        "variables_optional": [],
        "tone": "playful",
    },

    # 睡前提醒
    {
        "id": "tpl_sleep_reminder",
        "scene": "sleep_reminder",
        "template_cn": "{time_period}已到！{constitution}体质的你，这个时辰应该{action}，准备睡眠。早睡才能早养阳气哦~",
        "template_en": "{time_period} is here! {constitution} type, time to {action} and prepare for sleep.",
        "variables_required": ["time_period", "constitution", "action"],
        "variables_optional": [],
        "tone": "warm",
    },

    # 节日养生提醒
    {
        "id": "tpl_festival_wellness",
        "scene": "festival_wellness",
        "template_cn": "{festival}快乐！{constitution}体质的你在假期要注意：{warning}。放松身心的同时，别忘了照顾好身体哦~",
        "template_en": "Happy {festival}! {constitution} types should note: {warning}. Enjoy while caring for your body!",
        "variables_required": ["festival", "constitution", "warning"],
        "variables_optional": [],
        "tone": "warm",
    },

    # 打卡里程碑庆祝语
    {
        "id": "tpl_milestone",
        "scene": "progress_celebration",
        "template_cn": "太棒了！你已经连续打卡{days}天！这说明你正在{constitution}体质调理上做出真正的承诺。再坚持，改变就在眼前！",
        "template_en": "{days} days streak! You're truly committed to improving your {constitution} constitution. Keep it up!",
        "variables_required": ["days", "constitution"],
        "variables_optional": [],
        "tone": "warm",
    },
]

# 内存缓存（防止重复）
_duplicate_cache: Dict[str, List[str]] = {}  # user_id → [content_hash, ...]
_content_history: Dict[str, List[str]] = {}  # user_id → [generated_content, ...]


def _get_current_season() -> str:
    month = datetime.now().month
    if month in (3, 4, 5): return "spring"
    if month in (6, 7, 8): return "summer"
    if month in (9, 10, 11): return "autumn"
    return "winter"


def _render_template(template: dict, variables: dict, lang: str) -> str:
    """渲染模板，用变量替换占位符"""
    key = f"template_{lang}" if lang == "en" else "template_cn"
    text = template.get(key, "")

    try:
        return text.format(**variables)
    except KeyError as e:
        raise ValueError(f"Missing variable: {e.args[0]}")


def _is_duplicate(user_id: str, content: str) -> bool:
    """检查是否为该用户的重复内容"""
    if user_id not in _duplicate_cache:
        return False
    content_hash = hashlib.md5(content.encode()).hexdigest()
    return content_hash in _duplicate_cache[user_id]


def _record_content(user_id: str, content: str) -> None:
    """记录生成的内容（防重复）"""
    if user_id not in _duplicate_cache:
        _duplicate_cache[user_id] = []
        _content_history[user_id] = []

    content_hash = hashlib.md5(content.encode()).hexdigest()
    _duplicate_cache[user_id].append(content_hash)
    _content_history[user_id].append(content)

    # 只保留最近50条
    if len(_duplicate_cache[user_id]) > 50:
        _duplicate_cache[user_id].pop(0)
        _content_history[user_id].pop(0)


# ─────────────────────────────────────────────────────────────────────────────
# 端点
# ─────────────────────────────────────────────────────────────────────────────

@router.get("/templates", summary="所有内容模板")
async def list_templates(scene: Optional[str] = Query(None, description="场景过滤")):
    """返回所有模板，支持按场景过滤"""
    results = TEMPLATES.copy()
    if scene:
        results = [t for t in results if t["scene"] == scene]

    return {
        "success": True,
        "data": {
            "templates": results,
            "total": len(results),
            "scenes": list(set(t["scene"] for t in TEMPLATES)),
        },
    }


@router.get("/scenes", summary="所有场景列表")
async def list_scenes():
    """返回所有可用场景"""
    scenes = list(set(t["scene"] for t in TEMPLATES))
    scene_descriptions = {
        "solar_term_greeting": "节气问候语",
        "daily_tip": "每日养生小贴士",
        "constitution_report_intro": "体质报告开场白",
        "food_recommendation_reason": "食疗推荐理由",
        "exercise_motivation": "运动激励语",
        "sleep_reminder": "睡前提醒",
        "festival_wellness": "节日养生提醒",
        "progress_celebration": "打卡里程碑庆祝",
    }

    return {
        "success": True,
        "data": {
            "scenes": [
                {"id": s, "name": scene_descriptions.get(s, s)}
                for s in sorted(scenes)
            ]
        },
    }


@router.get("/preview/{template_id}", summary="模板预览")
async def preview_template(template_id: str):
    """用示例变量预览模板"""
    template = next((t for t in TEMPLATES if t["id"] == template_id), None)
    if not template:
        raise HTTPException(status_code=404, detail=f"Template {template_id} not found")

    # 示例变量
    examples = {
        "user_name": "张三",
        "solar_term": "春分",
        "constitution": "气虚",
        "advice": "食用红枣和山药",
        "season": "春",
        "time_period": "早晨",
        "tip": "晨间散步30分钟",
        "issue": "容易疲劳",
        "food": "黄芪粥",
        "benefit": "健脾益气",
        "exercise": "太极拳",
        "times": "2",
        "action": "停止刷手机",
        "festival": "端午节",
        "warning": "避免过量食用冷饮",
        "days": "21",
    }

    required_vars = {k: examples.get(k, f"[{k}]") for k in template["variables_required"]}
    preview_cn = _render_template(template, required_vars, "zh")
    preview_en = _render_template(template, required_vars, "en")

    return {
        "success": True,
        "data": {
            "template": template,
            "preview_cn": preview_cn,
            "preview_en": preview_en,
        },
    }


@router.post("/generate", summary="生成个性化内容")
async def generate_content(req: GenerateRequest):
    """生成个性化内容"""
    template = next((t for t in TEMPLATES if t["id"] == req.template_id), None)
    if not template:
        raise HTTPException(status_code=404, detail=f"Template {req.template_id} not found")

    # 验证必填变量
    missing = [v for v in template["variables_required"] if v not in req.variables]
    if missing:
        raise HTTPException(status_code=422, detail=f"Missing required variables: {missing}")

    # 渲染
    try:
        content = _render_template(template, req.variables, req.lang)
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))

    # 检查重复
    if req.user_id and _is_duplicate(req.user_id, content):
        # 重试机制：轻微调整内容
        content = content + "（更新版）" if req.lang == "zh" else content + " (updated)"

    if req.user_id:
        _record_content(req.user_id, content)

    return {
        "success": True,
        "data": {
            "content": content,
            "template_id": req.template_id,
            "lang": req.lang,
        },
    }


@router.post("/batch-generate", summary="批量生成内容")
async def batch_generate(req: BatchGenerateRequest):
    """批量生成内容（最多10个）"""
    if len(req.requests) > 10:
        raise HTTPException(status_code=400, detail="Maximum 10 requests per batch")

    results = []
    for item in req.requests:
        template_id = item.get("template_id")
        variables = item.get("variables", {})
        lang = item.get("lang", "zh")

        template = next((t for t in TEMPLATES if t["id"] == template_id), None)
        if not template:
            results.append({"success": False, "error": f"Template {template_id} not found"})
            continue

        missing = [v for v in template["variables_required"] if v not in variables]
        if missing:
            results.append({"success": False, "error": f"Missing variables: {missing}"})
            continue

        try:
            content = _render_template(template, variables, lang)
            results.append({
                "success": True,
                "template_id": template_id,
                "content": content,
            })
        except Exception as e:
            results.append({"success": False, "error": str(e)})

    return {
        "success": True,
        "data": {
            "results": results,
            "total": len(results),
            "success_count": sum(1 for r in results if r.get("success", False)),
        },
    }


@router.get("/daily-tip", summary="今日个性化养生贴士")
async def daily_tip(
    user_id: str = Query(...),
    constitution_type: str = Query(...),
    lang: str = Query("zh", regex="^(zh|en)$"),
):
    """返回当日不重复的个性化养生贴士"""
    season = _get_current_season()

    # 寻找matching的daily_tip模板
    daily_templates = [t for t in TEMPLATES if t["scene"] == "daily_tip"]
    if not daily_templates:
        raise HTTPException(status_code=500, detail="No daily_tip templates available")

    # 选择第一个可用的
    template = daily_templates[0]

    times_of_day = ["早晨", "上午", "正午", "午后", "傍晚", "晚上"]
    time_period = times_of_day[datetime.now().day % len(times_of_day)]

    tips_map = {
        "qi_deficiency": "适当运动，不过度疲劳",
        "yin_deficiency": "多喝温水，避免熬夜",
        "yang_deficiency": "温阳食物，早睡早起",
        "balanced": "保持日常养生习惯",
    }
    tip = tips_map.get(constitution_type, "科学调理身体")

    variables = {
        "season": season,
        "constitution": constitution_type,
        "time_period": time_period,
        "tip": tip,
    }

    content = _render_template(template, variables, lang)

    # 检查重复，如果重复则返回不同的tip
    if _is_duplicate(user_id, content):
        tip = tip + "（续）" if lang == "zh" else tip + " (continued)"
        variables["tip"] = tip
        content = _render_template(template, variables, lang)

    _record_content(user_id, content)

    return {
        "success": True,
        "data": {
            "content": content,
            "season": season,
            "date": datetime.now().strftime("%Y-%m-%d"),
            "time_period": time_period,
        },
    }
