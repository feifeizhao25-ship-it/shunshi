"""
顺时 — 主题定制 API (shunshi-theme)
应用主题、节气主题、用户个性化外观设置
"""

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel, Field
from typing import Optional, List, Dict

router = APIRouter(prefix="/api/v1/theme", tags=["theme"])

_user_themes: Dict[str, dict] = {}

BUILT_IN_THEMES = {
    "spring_blossom": {
        "id": "spring_blossom", "name": "春花", "name_en": "Spring Blossom",
        "season": "spring",
        "colors": {
            "primary": "#E91E8C", "secondary": "#FFC1E3",
            "background": "#FFF0F5", "surface": "#FFFFFF",
            "text_primary": "#1A1A2E", "text_secondary": "#6B6B8A"
        },
        "solar_terms": ["lichun", "yushui", "jingzhe", "chunfen", "qingming", "guyu"],
        "preview_url": "https://cdn.shunshi.app/themes/spring_blossom.jpg",
        "is_premium": False
    },
    "summer_lotus": {
        "id": "summer_lotus", "name": "夏荷", "name_en": "Summer Lotus",
        "season": "summer",
        "colors": {
            "primary": "#1B7F79", "secondary": "#A8E6CF",
            "background": "#F0FFFC", "surface": "#FFFFFF",
            "text_primary": "#0D3B38", "text_secondary": "#4A7C79"
        },
        "solar_terms": ["lixia", "xiaoman", "mangzhong", "xiazhi", "xiaoshu", "dashu"],
        "preview_url": "https://cdn.shunshi.app/themes/summer_lotus.jpg",
        "is_premium": False
    },
    "autumn_maple": {
        "id": "autumn_maple", "name": "秋枫", "name_en": "Autumn Maple",
        "season": "autumn",
        "colors": {
            "primary": "#D84315", "secondary": "#FFCCBC",
            "background": "#FFF8F0", "surface": "#FFFFFF",
            "text_primary": "#1A0F0A", "text_secondary": "#6D4C41"
        },
        "solar_terms": ["liqiu", "chushu", "bailu", "qiufen", "hanlu", "shuangjiang"],
        "preview_url": "https://cdn.shunshi.app/themes/autumn_maple.jpg",
        "is_premium": False
    },
    "winter_snow": {
        "id": "winter_snow", "name": "冬雪", "name_en": "Winter Snow",
        "season": "winter",
        "colors": {
            "primary": "#1565C0", "secondary": "#BBDEFB",
            "background": "#F5F9FF", "surface": "#FFFFFF",
            "text_primary": "#0A1628", "text_secondary": "#455A8A"
        },
        "solar_terms": ["lidong", "xiaoxue", "daxue", "dongzhi", "xiaohan", "dahan"],
        "preview_url": "https://cdn.shunshi.app/themes/winter_snow.jpg",
        "is_premium": False
    },
    "ink_painting": {
        "id": "ink_painting", "name": "水墨", "name_en": "Ink Painting",
        "season": "all",
        "colors": {
            "primary": "#37474F", "secondary": "#B0BEC5",
            "background": "#FAFAFA", "surface": "#FFFFFF",
            "text_primary": "#212121", "text_secondary": "#757575"
        },
        "solar_terms": [],
        "preview_url": "https://cdn.shunshi.app/themes/ink_painting.jpg",
        "is_premium": True
    },
    "golden_autumn": {
        "id": "golden_autumn", "name": "金秋", "name_en": "Golden Autumn",
        "season": "autumn",
        "colors": {
            "primary": "#F57F17", "secondary": "#FFF9C4",
            "background": "#FFFDE7", "surface": "#FFFFFF",
            "text_primary": "#1A1400", "text_secondary": "#6D5800"
        },
        "solar_terms": ["liqiu", "chushu", "bailu", "qiufen"],
        "preview_url": "https://cdn.shunshi.app/themes/golden_autumn.jpg",
        "is_premium": True
    }
}

FONT_OPTIONS = [
    {"id": "default", "name": "系统默认", "preview": "顺时养生"},
    {"id": "round", "name": "圆润字体", "preview": "顺时养生"},
    {"id": "classic", "name": "经典宋体", "preview": "顺时養生"},
]

THEME_ALIASES = {
    "spring": "spring_blossom",
    "summer": "summer_lotus",
    "autumn": "autumn_maple",
    "winter": "winter_snow",
}


class ThemeSettingsRequest(BaseModel):
    user_id: str = Field(..., description="用户ID")
    theme_id: str = Field(..., description="主题ID")
    font_id: Optional[str] = Field(None, description="字体ID")
    dark_mode: Optional[bool] = Field(None, description="是否深色模式")
    auto_season: Optional[bool] = Field(True, description="是否自动跟随节气切换主题")


@router.get("/list", summary="主题列表")
async def list_themes(
    season: Optional[str] = Query(None, description="季节筛选"),
    is_premium: Optional[bool] = Query(None, description="是否付费主题")
):
    items = list(BUILT_IN_THEMES.values())
    if season:
        items = [t for t in items if t["season"] in (season, "all")]
    if is_premium is not None:
        items = [t for t in items if t["is_premium"] == is_premium]
    return {"success": True, "data": {"themes": items, "total": len(items)}}


@router.get("/{theme_id}", summary="主题详情")
async def get_theme(theme_id: str):
    theme_id = THEME_ALIASES.get(theme_id, theme_id)
    if theme_id not in BUILT_IN_THEMES:
        raise HTTPException(status_code=404, detail="主题不存在")
    return {"success": True, "data": BUILT_IN_THEMES[theme_id]}


@router.post("/settings", summary="设置用户主题")
async def set_theme(request: ThemeSettingsRequest):
    theme_id = THEME_ALIASES.get(request.theme_id, request.theme_id)
    if theme_id not in BUILT_IN_THEMES:
        raise HTTPException(status_code=404, detail="主题不存在")
    _user_themes[request.user_id] = {
        "theme_id": theme_id,
        "font_id": request.font_id or "default",
        "dark_mode": request.dark_mode or False,
        "auto_season": request.auto_season if request.auto_season is not None else True
    }
    return {"success": True, "data": {"message": "主题设置已保存", "settings": _user_themes[request.user_id]}}


@router.get("/settings/{user_id}", summary="获取用户主题设置")
async def get_user_theme(user_id: str):
    settings = _user_themes.get(user_id, {"theme_id": "spring_blossom", "font_id": "default", "dark_mode": False, "auto_season": True})
    theme = BUILT_IN_THEMES.get(settings["theme_id"], BUILT_IN_THEMES["spring_blossom"])
    return {"success": True, "data": {"settings": settings, "theme": theme}}


@router.get("/fonts/list", summary="字体选项")
async def list_fonts():
    return {"success": True, "data": {"fonts": FONT_OPTIONS}}


@router.get("/seasonal/current", summary="当前节气推荐主题")
async def get_seasonal_theme():
    from datetime import date
    month = date.today().month
    if 3 <= month <= 5:
        theme_id = "spring_blossom"
    elif 6 <= month <= 8:
        theme_id = "summer_lotus"
    elif 9 <= month <= 11:
        theme_id = "autumn_maple"
    else:
        theme_id = "winter_snow"
    return {"success": True, "data": {"recommended_theme": BUILT_IN_THEMES[theme_id]}}
