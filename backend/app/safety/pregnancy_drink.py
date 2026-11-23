"""孕期 / 哺乳期问花草茶、饮品：不再一律返回「不能回答症状、用药或剂量问题」。

2026-11-23 真模型复测：「我怀孕22周了，孕期能喝菊花茶、玫瑰花茶吗？」命中健康边界规则，
回的是「我不是医生，不能回答症状、用药或剂量问题」，和问题对不上，也没有可做的事。

顺时已核验知识库（verified_cn.md、approved/）里没有孕期 / 哺乳期茶饮的审核内容，
所以这里**不下「能喝 / 不能喝」的结论、不调模型**，只把拒答换成可执行的谨慎建议：
日常补水以白开水为主（已核验饮水条目的一般原则），具体茶饮带配料表问医生，
不自己加药材，写明需要就医的信号。问题里点到产品现有孕期 / 哺乳期忌口清单
（contraindications 名单与 maternity.FORBIDDEN_HERBS_DATA，只读、不改）里的名字时，
照清单提醒先别自己喝。

用药、剂量、症状、儿童 / 胎儿、疗效等硬性拒答词仍按原规则拒答，不走这里。
"""

from __future__ import annotations

import re

from app.safety.config import DIET_STILL_REFUSE_PATTERNS

_PREGNANT = re.compile(r"怀孕|孕妇|孕期|孕早期|孕中期|孕晚期|孕\d+周|怀孕\d+周")
_BREASTFEEDING = re.compile(r"哺乳|母乳|喂奶")
_DRINK = re.compile(r"茶|喝|饮品|饮料")
_ASK = re.compile(r"能不能|可不可以|可以|能|适合|适不适合|行不行|安全|吗|嘛|呢|？|\?")
# 中药材那一组在这里不当硬性拒答：点到药材时照样给谨慎建议（并明确不要自己泡药材），
# 其余组（用药剂量、疗效诊断、急症症状、儿童胎儿）仍拒答。
_STILL_REFUSE = [re.compile(p, re.IGNORECASE) for p in DIET_STILL_REFUSE_PATTERNS if "中药" not in p]

DISCLAIMER = "仅供日常参考，不是医疗诊断或治疗建议。"


def _stage(text: str) -> str | None:
    if _PREGNANT.search(text):
        return "pregnancy"
    if _BREASTFEEDING.search(text):
        return "breastfeeding"
    return None


def is_pregnancy_drink_question(text: str) -> bool:
    sample = (text or "").strip()
    if not sample or _stage(sample) is None:
        return False
    if not (_DRINK.search(sample) and _ASK.search(sample)):
        return False
    return not any(p.search(sample) for p in _STILL_REFUSE)


def _listed_names(text: str, stage: str) -> list[str]:
    from app.safety.contraindications import names_for

    names = list(names_for(frozenset({stage})))
    if stage == "pregnancy":
        try:
            from app.router.maternity import FORBIDDEN_HERBS_DATA
        except Exception:  # noqa: BLE001 — 路由包导入失败（如未配 JWT_SECRET 的脚本环境）时只用 contraindications 名单
            FORBIDDEN_HERBS_DATA = []
        names.extend(str(row["name"]) for row in FORBIDDEN_HERBS_DATA if row.get("name"))
    found: list[str] = []
    rest = text
    for name in sorted(set(names), key=len, reverse=True):  # 藏红花 先于 红花
        if name and name in rest:
            found.append(name)
            rest = rest.replace(name, "")
    return found


def pregnancy_drink_reply(text: str) -> str:
    stage = _stage(text or "") or "pregnancy"
    label = "孕期" if stage == "pregnancy" else "哺乳期"
    purpose = "调理或安胎" if stage == "pregnancy" else "调理或催奶"
    doctor = "下次产检时问问医生" if stage == "pregnancy" else "问问给你看诊的医生"
    warning = (
        "如果出现腹痛、阴道出血或流液、胎动明显减少等情况，请及时就医；紧急情况拨打 120。"
        if stage == "pregnancy"
        else "你或宝宝出现不适时请及时就医；紧急情况拨打 120。"
    )
    lines = [
        f"{label}想喝点茶，这个顾虑很常见。顺时目前没有经过审核的{label}茶饮资料，"
        "没法替你判断某一种茶适不适合你，所以这里不给「能喝」或「不能喝」的结论。",
        "",
        "可以先这样安排：",
        "1. 日常补水以白开水、温水为主，少量多次。",
        f"2. 想喝的茶，把名字和包装上的配料表拍下来，{doctor}，确认后再喝。",
        f"3. 不要自己往茶里加中药材，也不要把花草茶当作{purpose}的方法。",
    ]
    listed = _listed_names(text or "", stage)
    if listed:
        lines.append(f"4. 「{'、'.join(listed)}」在顺时现有的{label}忌口清单里，先不要自己喝。")
    lines += ["", warning, "", DISCLAIMER]
    return "\n".join(lines)


# ── 2026-11-23 主人定（待定57）：孕期 / 哺乳期的用量、症状类问题拦下并建议就医 ──
# 「孕期菊花茶一天喝几杯」「孕期喝菊花茶肚子疼怎么办」原先被分到 bulk 路由、不经拒答直接进模型。
# 用量类必须同时出现入口相关的词（喝、吃、茶、水…），避免把「孕期每天睡几个小时」这类作息问题拦掉。
_DOSE = re.compile(
    r"几杯|多少杯|几碗|多少碗|几次|多少次|几克|多少克|几毫升|多少毫升|几包|多少包|几勺|多少勺|喝多少|吃多少|"
    r"用量|剂量|(一天|每天|每日|一次|每次).{0,6}(几|多少)"
)
_INTAKE = re.compile(r"喝|吃|茶|饮|咖啡|水|汤|奶|补充|服")
_SYMPTOM = re.compile(
    r"疼|痛|恶心|想吐|呕吐|吐了|出血|见红|流血|流液|拉肚子|腹泻|头晕|心慌|心悸|胸闷|过敏|起疹|皮疹|"
    r"宫缩|肚子发紧|胎动|发烧|发热|不舒服|难受|抽筋|水肿|浮肿|晕倒|呼吸困难"
)


def pregnancy_dose_or_symptom_kind(text: str) -> str | None:
    """孕期 / 哺乳期问用量（且和吃喝有关）返回 "dose"，提到身体不适返回 "symptom"（优先），否则 None。"""
    sample = (text or "").strip()
    if not sample or _stage(sample) is None:
        return None
    if _SYMPTOM.search(sample):
        return "symptom"
    if _DOSE.search(sample) and _INTAKE.search(sample):
        return "dose"
    return None


def pregnancy_dose_symptom_reply(text: str) -> str:
    stage = _stage(text or "") or "pregnancy"
    kind = pregnancy_dose_or_symptom_kind(text) or "dose"
    label = "孕期" if stage == "pregnancy" else "哺乳期"
    doctor = "产检医生" if stage == "pregnancy" else "给你看诊的医生或妇幼保健机构"
    factors = "孕周、体重、身体情况" if stage == "pregnancy" else "宝宝月龄和你的身体情况"
    if kind == "symptom":
        urgent = (
            "如果腹痛加重、阴道出血或流液、胎动明显减少，或者头晕、呼吸困难，请立即就医或拨打 120。"
            if stage == "pregnancy"
            else "如果你或宝宝症状加重，比如持续腹泻、呕吐、起疹或呼吸困难，请立即就医或拨打 120。"
        )
        lines = [
            f"{label}出现身体不适，顺时不能判断原因，也不能给处理办法。",
            "",
            "1. 先停下刚才吃或喝的东西，不要再自己尝试别的茶饮、食物或药材。",
            f"2. 请尽快联系{doctor}或去医院，说清楚吃了 / 喝了什么、多少、什么时候开始不舒服。",
            "",
            urgent,
        ]
    else:
        lines = [
            f"{label}一天能喝多少、吃多少，和{factors}都有关，顺时不能给你具体的量。",
            "",
            f"1. 请把想喝 / 想吃的东西和包装配料表拍下来，问问{doctor}，按医生说的量来。",
            "2. 问清楚之前，日常补水以白开水、温水为主，少量多次。",
            "3. 喝了或吃了之后有任何不舒服，请及时就医；紧急情况拨打 120。",
        ]
    lines += ["", DISCLAIMER]
    return "\n".join(lines)
