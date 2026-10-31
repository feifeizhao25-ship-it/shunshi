"""读取资料库条目 + 来源核对状态，套上展示规则。数据目录：环境变量 SHUNSHI_LIBRARY_DIR（默认 var/library）。

条目文件：目录里的 reference_entries.json（审核人用 library_review 写回）；没有就用包内的 data/reference_entries_v1.json。
"""

from __future__ import annotations

import json
import os
from datetime import date
from pathlib import Path
from typing import Optional

from ..library_live import decide

HERE = Path(__file__).parent
BUNDLED = HERE / "data" / "reference_entries_v1.json"
TTL_DEFAULT = 90
TTL_BY_CATEGORY = {"消费提醒": 45}


def data_dir() -> Path:
    return Path(os.environ.get("SHUNSHI_LIBRARY_DIR") or "var/library")


def entries_path() -> Path:
    p = data_dir() / "reference_entries.json"
    return p if p.exists() else BUNDLED


def load_document() -> dict:
    return json.loads(entries_path().read_text("utf-8"))


def load_state() -> dict:
    p = data_dir() / "library_state.json"
    return json.loads(p.read_text("utf-8")) if p.exists() else {"entries": {}, "candidates": []}


def show_pending() -> bool:
    return os.environ.get("SHUNSHI_LIBRARY_SHOW_PENDING", "0").lower() in ("1", "true", "yes", "on")


def annotated(today: date, lang: str = "zh", *, document: Optional[dict] = None, state: Optional[dict] = None, preview: Optional[bool] = None,
              include_hidden: bool = False) -> list[dict]:
    """每条 = 条目内容 + display（展示规则的结论）。默认只返回对用户可见的。"""
    doc = document if document is not None else load_document()
    st = state if state is not None else load_state()
    preview = show_pending() if preview is None else preview
    out = []
    for e in doc["entries"]:
        d = decide(e, st.get("entries", {}).get(e["id"]), today, lang, ttl_default=TTL_DEFAULT, ttl_by_category=TTL_BY_CATEGORY, preview=preview)
        if d.visible or include_hidden:
            out.append({**e, "display": d.to_dict()})
    return out


def find(entry_id: str, today: date, lang: str = "zh", **kw) -> Optional[dict]:
    """详情页：已废止 / 核对中的条目只有直接打开才看得到（带横幅）；待审核的只在预览开关打开时可见。"""
    preview = kw.get("preview")
    preview = show_pending() if preview is None else preview
    for e in annotated(today, lang, include_hidden=True, **{**kw, "preview": preview}):
        if e["id"] == entry_id:
            if e["display"]["state"] == "pending" and not preview:
                return None
            return e
    return None
