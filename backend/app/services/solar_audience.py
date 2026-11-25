"""节气食材按体质和人群过滤。

通用节气知识仍然保留。只有调用方带来体质或人生阶段时，才改主建议。
阴虚、湿热不再把温补当作主建议；孕期、儿童、慢性病或正在用药的人看到禁忌提示。
内容是生活提示，不是诊断。候选资料待具名审核人核对后才能标成已审核。
"""
from __future__ import annotations

WARM_FOODS = ("羊肉", "牛肉", "桂圆", "龙眼", "生姜", "肉桂")
WARM_LEAD = ("温肾助阳", "温补肾阳", "温补肾精", "温阳散寒", "温肾健脾", "适当进补", "温补肾")
COOL_ALTERNATIVES = ("山药", "白萝卜", "银耳", "梨", "黑芝麻")
YIN_OR_DAMP = {"阴虚", "阴虚质", "yinxu", "湿热", "湿热质", "shire"}

_CONSTITUTION = {
    "阴虚": "阴虚", "阴虚质": "阴虚", "yinxu": "阴虚",
    "湿热": "湿热", "湿热质": "湿热", "shire": "湿热",
    "阳虚": "阳虚", "阳虚质": "阳虚", "yangxu": "阳虚",
    "气虚": "气虚", "气虚质": "气虚", "qixu": "气虚",
    "痰湿": "痰湿", "痰湿质": "痰湿", "tanshi": "痰湿",
    "血瘀": "血瘀", "血瘀质": "血瘀", "xueyu": "血瘀",
    "气郁": "气郁", "气郁质": "气郁", "qiyu": "气郁",
    "平和": "平和", "平和质": "平和", "pinghe": "平和",
    "特禀": "特禀", "特禀质": "特禀", "tebing": "特禀",
}


def normalize_constitution(value: str | None) -> str | None:
    if not value:
        return None
    return _CONSTITUTION.get(str(value).strip())


def _contains_any(text: str, words: tuple[str, ...]) -> bool:
    return any(word in text for word in words)


def filter_solar_term(term: dict, *, constitution: str | None = None, life_stage: str | None = None) -> dict:
    """返回新字典。没有体质和人生阶段时原样返回，并带上空的 audience_notes。"""
    out = dict(term)
    foods = [str(item) for item in (out.get("foods") or [])]
    suggestions = [str(item) for item in (out.get("suggestions") or [])]
    description = str(out.get("description") or "")
    notes: list[str] = []
    cons = normalize_constitution(constitution)
    if cons in ("阴虚", "湿热"):
        foods = [item for item in foods if not _contains_any(item, WARM_FOODS)]
        suggestions = [item for item in suggestions if not _contains_any(item, WARM_LEAD)]
        for extra in COOL_ALTERNATIVES:
            if extra not in foods:
                foods.append(extra)
        if _contains_any(description, WARM_LEAD):
            description = "这个节气天冷。饮食以清润、应季为主，少把温补当成主建议。"
        if not suggestions:
            suggestions = ["饮食清淡温润", "少吃燥热进补", "注意保暖", "作息规律"]
        label = "阴虚" if cons == "阴虚" else "湿热"
        notes.append(
            f"按你填写的{label}体质倾向，这次没有把温补当作主建议。"
            "阴虚或湿热少吃羊肉、桂圆这类偏温的食物。这是生活提示，不是诊断。"
        )
    stage = str(life_stage or "")
    if any(token in stage for token in ("孕", "pregnan", "pregnant")):
        foods = [item for item in foods if not _contains_any(item, ("桂圆", "龙眼", "羊肉"))]
        suggestions = [item for item in suggestions if not _contains_any(item, ("温肾助阳", "适当进补"))]
        notes.append("孕期把桂圆、羊肉等进补当作慎用，先问产科医生。这里不是诊断，也不代替产检。")
    if any(token in stage for token in ("儿童", "未成年", "child", "minor")):
        notes.append("儿童不按成人的方式进补。饮食保持清淡、规律即可，具体问题问儿科医生。")
    if any(token in stage for token in ("慢性", "服药", "用药")):
        notes.append("正在按医嘱用药或有长期健康问题时，进补前先问负责的医生。这里不提供用药建议。")
    out["foods"] = foods
    out["suggestions"] = suggestions
    out["description"] = description
    out["audience_notes"] = notes
    out["primary_suggestion"] = suggestions[0] if suggestions else ""
    return out


def filter_text_items(items: list, *, constitution: str | None = None, life_stage: str | None = None) -> list:
    """从食疗条目里拿掉和当前人群冲突的温补项。条目可以是字符串或带 title/description 的字典。"""
    cons = normalize_constitution(constitution)
    stage = str(life_stage or "")
    pregnant = any(token in stage for token in ("孕", "pregnan", "pregnant"))
    if cons not in ("阴虚", "湿热") and not pregnant:
        return list(items)

    def blob(item) -> str:
        if isinstance(item, str):
            return item
        if isinstance(item, dict):
            parts = [str(item.get(key) or "") for key in ("title", "description", "name")]
            ingredients = item.get("ingredients") or []
            if isinstance(ingredients, list):
                parts.extend(str(part) for part in ingredients)
            return " ".join(parts)
        return str(item)

    blocked = WARM_FOODS if cons in ("阴虚", "湿热") else ("桂圆", "龙眼", "羊肉")
    if pregnant:
        blocked = tuple(dict.fromkeys((*blocked, "桂圆", "龙眼", "羊肉")))
    return [item for item in items if not _contains_any(blob(item), blocked)]
