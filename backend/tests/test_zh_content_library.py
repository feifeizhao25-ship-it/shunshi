"""国内版内容库（文库 / 食疗 / 茶饮 / 运动 / 穴位 / 助眠 / 节气）完整且全中文。

只检查种子数据本身（不起数据库）：中文内容不得缺失、不得夹带英文。
英文条目（locale='en-US'）仅供国际版，国内接口默认 locale=zh-CN，不会返回。
"""
import json
import re

from app.database import db as dbmod

ALLOWED_LATIN = {"PM", "AM", "pH", "mmHg", "kcal", "ml", "mg", "kg", "cm", "min", "AI"}
# season_tag 是内部键（spring/summer/…），界面经 ZhLabels 转成「春季…」后才显示
INTERNAL_KEYS = {"season_tag"}
COLS = ["id", "title", "description", "type", "category", "tags", "difficulty", "time", "duration",
        "ingredients", "steps", "location", "method", "effect", "benefits", "best_time", "season_tag", "locale"]


def _zh_rows():
    rows = []
    for t in dbmod.SEED_CONTENTS:
        d = dict(zip(COLS, t))
        if d.get("locale", "zh-CN") == "zh-CN":
            rows.append(d)
    for t in dbmod.SEED_SOLAR_TERMS:
        rows.append(dict(zip(COLS[:6], t)))
    return rows


def test_zh_library_is_populated():
    rows = _zh_rows()
    by_type = {}
    for r in rows:
        by_type[r["type"]] = by_type.get(r["type"], 0) + 1
    assert len(rows) >= 200, by_type
    for t in ("food_therapy", "tea", "exercise", "acupressure", "sleep_tip"):
        assert by_type.get(t, 0) >= 20, (t, by_type)


def test_zh_library_rows_are_chinese_only():
    bad = []
    for r in _zh_rows():
        assert r["title"] and r["description"], r["id"]
        for k, v in r.items():
            if k in INTERNAL_KEYS or k in ("id", "type", "locale") or not v:
                continue
            words = [w for w in re.findall(r"[A-Za-z]{2,}", str(v)) if w not in ALLOWED_LATIN]
            if words:
                bad.append((r["id"], k, words[:3]))
    assert not bad, bad[:10]
    assert all(re.search(r"[\u4e00-\u9fff]", r["title"]) for r in _zh_rows())


def test_zh_rows_are_not_lorem_or_placeholder():
    text = json.dumps(_zh_rows(), ensure_ascii=False).lower()
    for w in ("lorem", "ipsum", "todo", "占位", "示例内容", "待补充"):
        assert w not in text, w
