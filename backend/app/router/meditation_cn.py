"""顺时国内版 — 原创中文冥想音频库。

- 目录来自 ``app/data/meditation_cn/tracks.json``（原创脚本 + 音频元数据），音频文件在
  ``app/static/audio/meditation/``，由 ``/static`` 对外提供；也可以用环境变量
  ``SHUNSHI_MEDITATION_AUDIO_BASE_URL`` 指向对象存储 / CDN，客户端包里不内置音频。
- 人声是 AI 合成语音，响应里带显式标识 ``ai_label``，并带 ``X-AI-Generated`` 响应头。
- 只返回磁盘上真有音频文件的条目；一个都没有时返回空列表，由客户端显示空状态，不编造条目。
- 内容仅用于放松与作息参考，不是医疗服务，不含诊断、疗效或用药表述。
"""

from __future__ import annotations

import json
import os
import re
from datetime import datetime, timedelta, timezone
from functools import lru_cache
from pathlib import Path
from typing import Optional

from fastapi import APIRouter, HTTPException, Query, Response

from ..aigc import AI_HEADERS
from ..safety.config import CRISIS_HOTLINE

router = APIRouter(prefix="/api/v1/meditation", tags=["meditation-cn"])

_APP_DIR = Path(__file__).resolve().parents[1]
CATALOG_PATH = _APP_DIR / "data" / "meditation_cn" / "tracks.json"
AUDIO_DIR = _APP_DIR / "static" / "audio" / "meditation"
AUDIO_URL_PREFIX = "/static/audio/meditation/"

AI_AUDIO_LABEL = "AI 合成语音"
DISCLAIMER = (
    "本音频由 AI 合成语音朗读，仅用于放松与作息参考，不是医疗服务，也不能替代专业诊疗。"
    f"练习中感到不适请立即停止；如长期睡不好或情绪持续低落，请咨询医生或拨打 {CRISIS_HOTLINE} 心理援助热线。"
)

CATEGORY_ORDER = ["breathing", "sleep", "solar_term", "quick"]
_PAUSE = re.compile(r"<#[\d.]+#>")


@lru_cache(maxsize=1)
def _catalog() -> dict:
    return json.loads(CATALOG_PATH.read_text(encoding="utf-8"))


def reload_catalog() -> None:
    """测试或热更新目录后调用。"""
    _catalog.cache_clear()


def _audio_url(track_id: str) -> str:
    base = os.environ.get("SHUNSHI_MEDITATION_AUDIO_BASE_URL", "").strip().rstrip("/")
    return f"{base}/{track_id}.mp3" if base else f"{AUDIO_URL_PREFIX}{track_id}.mp3"


def _current_season() -> str:
    month = datetime.now(timezone(timedelta(hours=8))).month
    return {3: "spring", 4: "spring", 5: "spring", 6: "summer", 7: "summer", 8: "summer",
            9: "autumn", 10: "autumn", 11: "autumn"}.get(month, "winter")


def _available(track: dict) -> bool:
    return (AUDIO_DIR / f"{track['id']}.mp3").is_file()


def _public(track: dict, *, detail: bool = False, season: str | None = None) -> dict:
    item = {
        "id": track["id"],
        "title": track["title"],
        "subtitle": track["subtitle"],
        "category": track["category"],
        "category_label": track["category_label"],
        "duration_seconds": track.get("duration_seconds"),
        "size_bytes": track.get("size_bytes"),
        "best_time": track["best_time"],
        "season": track.get("season"),
        "term": track.get("term"),
        "tags": track.get("tags", []),
        "is_premium": bool(track.get("is_premium", False)),
        "audio_url": _audio_url(track["id"]),
        "ai_generated": True,
        "ai_label": AI_AUDIO_LABEL,
        "review_status": _catalog().get("review_status", "待审核"),
        "recommended": bool(season and track.get("season") == season),
    }
    if detail:
        item["transcript"] = _PAUSE.sub("", "".join(track["text"]))
        item["disclaimer"] = DISCLAIMER
    return item


@router.get("/library")
async def meditation_library(
    response: Response,
    category: Optional[str] = Query(None, description="breathing / sleep / solar_term / quick"),
    season: Optional[str] = Query(None, description="spring / summer / autumn / winter；不传则按当前季节排序"),
    best_time: Optional[str] = Query(None, description="morning / afternoon / evening / night / any"),
):
    response.headers.update(AI_HEADERS)
    tracks = [t for t in _catalog()["tracks"] if _available(t)]
    if category:
        tracks = [t for t in tracks if t["category"] == category]
    if best_time:
        tracks = [t for t in tracks if t["best_time"] in (best_time, "any")]
    current = season or _current_season()
    if season:
        tracks = [t for t in tracks if t.get("season") in (None, season)]
    # 当前季节的节气冥想排前面，其余按分类顺序
    tracks.sort(key=lambda t: (t.get("season") != current,
                               CATEGORY_ORDER.index(t["category"]) if t["category"] in CATEGORY_ORDER else 99))
    items = [_public(t, season=current) for t in tracks]
    labels = {t["category"]: t["category_label"] for t in _catalog()["tracks"]}
    return {
        "data": {
            "items": items,
            "total": len(items),
            "season": current,
            "categories": [{"id": c, "label": labels.get(c, c)} for c in CATEGORY_ORDER],
            "ai_label": AI_AUDIO_LABEL,
            "disclaimer": DISCLAIMER,
            "review_status": _catalog().get("review_status", "待审核"),
        }
    }


@router.get("/library/{track_id}")
async def meditation_track(track_id: str, response: Response):
    response.headers.update(AI_HEADERS)
    for track in _catalog()["tracks"]:
        if track["id"] == track_id and _available(track):
            return {"data": _public(track, detail=True, season=_current_season())}
    raise HTTPException(status_code=404, detail="没有找到这条冥想音频")
