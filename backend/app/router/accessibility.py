"""
顺时 — 无障碍功能 API (shunshi-accessibility)
无障碍设置、字体大小、色彩对比、辅助功能
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import Optional, Dict

router = APIRouter(prefix="/api/v1/accessibility", tags=["accessibility"])

_user_settings: Dict[str, dict] = {}

DEFAULT_SETTINGS = {
    "font_size": "medium",        # small / medium / large / x-large
    "high_contrast": False,
    "reduce_motion": False,
    "screen_reader": False,
    "bold_text": False,
    "color_blind_mode": "none",   # none / deuteranopia / protanopia / tritanopia
    "haptic_feedback": True,
    "auto_play_audio": False,
    "caption_enabled": True,
    "button_size": "normal",      # normal / large
    "line_spacing": "normal",     # compact / normal / relaxed
}

FONT_SIZE_SCALE = {
    "small": 0.85, "medium": 1.0, "large": 1.2, "x-large": 1.5
}

COLOR_BLIND_PALETTES = {
    "none": {"primary": "#1B7F79", "accent": "#E91E8C", "warning": "#FF9800", "error": "#F44336"},
    "normal": {"primary": "#1B7F79", "accent": "#E91E8C", "warning": "#FF9800", "error": "#F44336"},
    "deuteranopia": {"primary": "#0066CC", "accent": "#FF6600", "warning": "#FFCC00", "error": "#CC0000"},
    "protanopia": {"primary": "#0066CC", "accent": "#FF6600", "warning": "#FFCC00", "error": "#CC0000"},
    "tritanopia": {"primary": "#009999", "accent": "#FF6699", "warning": "#FF9933", "error": "#FF3300"},
}


class AccessibilitySettingsRequest(BaseModel):
    user_id: str = Field(..., description="用户ID")
    font_size: Optional[str] = Field(None, description="small/medium/large/x-large")
    high_contrast: Optional[bool] = None
    reduce_motion: Optional[bool] = None
    screen_reader: Optional[bool] = None
    bold_text: Optional[bool] = None
    color_blind_mode: Optional[str] = Field(None, description="none/deuteranopia/protanopia/tritanopia")
    haptic_feedback: Optional[bool] = None
    auto_play_audio: Optional[bool] = None
    caption_enabled: Optional[bool] = None
    button_size: Optional[str] = Field(None, description="normal/large")
    line_spacing: Optional[str] = Field(None, description="compact/normal/relaxed")


@router.get("/settings/{user_id}", summary="获取无障碍设置")
async def get_settings(user_id: str):
    settings = _user_settings.get(user_id, DEFAULT_SETTINGS.copy())
    palette = COLOR_BLIND_PALETTES.get(settings.get("color_blind_mode", "none"), COLOR_BLIND_PALETTES["none"])
    return {
        "success": True,
        "data": {
            "settings": settings,
            "font_scale": FONT_SIZE_SCALE.get(settings.get("font_size", "medium"), 1.0),
            "color_palette": palette
        }
    }


@router.post("/settings", summary="更新无障碍设置")
async def update_settings(request: AccessibilitySettingsRequest):
    current = _user_settings.get(request.user_id, DEFAULT_SETTINGS.copy())
    updates = request.dict(exclude_none=True, exclude={"user_id"})
    current.update(updates)
    _user_settings[request.user_id] = current
    return {"success": True, "data": {"settings": current, "message": "无障碍设置已更新"}}


@router.post("/settings/{user_id}/reset", summary="重置为默认设置")
async def reset_settings(user_id: str):
    _user_settings[user_id] = DEFAULT_SETTINGS.copy()
    return {"success": True, "data": {"settings": DEFAULT_SETTINGS, "message": "设置已重置"}}


@router.get("/options", summary="可用的无障碍选项")
async def get_options():
    return {
        "success": True,
        "data": {
            "font_sizes": list(FONT_SIZE_SCALE.keys()),
            "color_blind_modes": list(COLOR_BLIND_PALETTES.keys()),
            "button_sizes": ["normal", "large"],
            "line_spacings": ["compact", "normal", "relaxed"],
            "defaults": DEFAULT_SETTINGS
        }
    }


@router.get("/color-palette/{mode}", summary="获取色彩方案")
async def get_color_palette(mode: str):
    if mode not in COLOR_BLIND_PALETTES:
        raise HTTPException(status_code=404, detail=f"色彩方案 '{mode}' 不存在")
    return {"success": True, "data": {"mode": mode, "palette": COLOR_BLIND_PALETTES[mode]}}
