"""知识库搜索：``GET /api/v1/knowledge/search``。

ios-cn 的「饮食推荐」「全局搜索」和 ios-global 的饮食推荐页一直在调这条路由，服务端却从来没挂过，
页面只会得到 404、永远是空列表。这里补上：在 ``contents`` 表里按标题、简介、标签、分类检索，
返回客户端已经在解析的形状（``data.results`` 与顶层 ``results``），不编造任何条目。

- ``q``：关键词。整句、空格分词、以及中文的相邻二字词都参与匹配（"补气健脾" 能命中含 "补气" 或 "健脾" 的条目）。
- ``content_type``：客户端的类型名（diet / tea / recipe / herb / exercise / meridian / acupoint），
  映射到库里的真实类型；库里没有的类型（如 herb）返回空列表，不拿别的类型充数。
- 语言由 ``X-App-Market`` / ``Accept-Language`` 决定（global 市场返回英文条目），也可用 ``locale`` 覆盖。
"""

from __future__ import annotations

import re
from typing import Optional

from fastapi import APIRouter, Depends, Query

from app.database.db import get_db
from app.locale_context import RequestLocale, request_locale
from app.router.contents import _content_row_to_dict

router = APIRouter(prefix="/api/v1/knowledge", tags=["知识库搜索"])

# 客户端类型 -> contents.type
_DB_TYPES: dict[str, tuple[str, ...]] = {
    "diet": ("food_therapy",),
    "tea": ("tea",),
    "recipe": ("recipe",),
    "herb": (),
    "exercise": ("exercise",),
    "meridian": ("acupressure",),
    "acupoint": ("acupoint", "acupressure"),
}
# contents.type -> 客户端类型
_CLIENT_TYPE = {
    "food_therapy": "diet",
    "acupressure": "meridian",
}

_CJK = re.compile(r"[\u3400-\u9fff]")


def _terms(q: str) -> list[str]:
    q = q.strip()
    out: list[str] = [q]
    for part in q.split():
        if part and part not in out and (len(part) >= 2 or _CJK.search(part)):
            out.append(part)
    for part in q.split():
        if _CJK.search(part) and len(part) >= 3:
            for i in range(len(part) - 1):
                gram = part[i : i + 2]
                if gram not in out:
                    out.append(gram)
    return out[:10]


@router.get("/search")
async def knowledge_search(
    q: str = Query(..., min_length=1, max_length=100, description="搜索关键词"),
    content_type: Optional[str] = Query(None, description="diet/tea/recipe/herb/exercise/meridian/acupoint"),
    top_k: int = Query(20, ge=1, le=100),
    locale: Optional[str] = Query(None, description="zh-CN / en-US，不传则按请求头判断"),
    req: RequestLocale = Depends(request_locale),
) -> dict:
    loc = locale if locale in ("zh-CN", "en-US") else ("en-US" if req.is_global else "zh-CN")
    terms = _terms(q)

    db_types: Optional[tuple[str, ...]] = None
    if content_type:
        db_types = _DB_TYPES.get(content_type, (content_type,))
        if not db_types:
            return _payload(q, [])

    clauses = " OR ".join(["title LIKE ? OR description LIKE ? OR tags LIKE ? OR category LIKE ?"] * len(terms))
    params: list = [loc]
    for t in terms:
        params.extend([f"%{t}%"] * 4)
    sql = f"SELECT * FROM contents WHERE locale = ? AND ({clauses})"
    if db_types:
        sql += " AND type IN (%s)" % ",".join("?" * len(db_types))
        params.extend(db_types)
    sql += " LIMIT 500"
    rows = get_db().execute(sql, params).fetchall()

    scored = []
    for row in rows:
        item = _content_row_to_dict(row)
        title = (item.get("title") or "").lower()
        desc = (item.get("description") or "").lower()
        side = f"{item.get('category') or ''} {' '.join(item.get('tags') or [])}".lower()
        score = 0
        for i, t in enumerate(terms):
            t = t.lower()
            weight = 2 if i == 0 else 1  # 整句命中更靠前
            if t in title:
                score += 3 * weight
            if t in side:
                score += 2 * weight
            if t in desc:
                score += weight
        scored.append((score, item))
    scored.sort(key=lambda s: (-s[0], str(s[1].get("title") or "")))

    results = []
    for _, item in scored[:top_k]:
        raw = item.get("type")
        item["content_type"] = raw
        item["type"] = _CLIENT_TYPE.get(raw, raw)
        item["content"] = item.get("description") or ""
        results.append(item)
    return _payload(q, results)


def _payload(q: str, results: list[dict]) -> dict:
    return {
        "success": True,
        "results": results,
        "data": {"query": q, "total": len(results), "results": results},
    }
