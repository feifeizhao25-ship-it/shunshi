"""国际版（英文）的医疗边界：不诊断、不给用药 / 剂量、不劝停药。

国内规则（config.HEALTH_REFUSE_PATTERNS）是中文正则，对英文提问无效；英文用户问
「能不能停降压药」「给我剂量」时原来直接交给模型。这里是英文对应规则，命中就不调用模型，
返回固定的英文说明。关键词筛查，不是医疗判断。
"""

from __future__ import annotations

import re

from .crisis_resources import emergency_phrase_en

_FLAGS = re.IGNORECASE

_MED = r"(medication|medicine|meds?|pills?|prescription|insulin|statins?|antibiotics?|antidepressants?|blood pressure (?:pills?|medication|meds?)|metformin|ibuprofen|aspirin|paracetamol|acetaminophen)"

PATTERNS = [
    # stop / skip / replace medication
    rf"\b(stop|quit|skip|come off|go off|reduce|lower|cut|replace|substitute|swap|instead of)\b.{{0,30}}\b{_MED}\b",
    rf"\b{_MED}\b.{{0,30}}\b(replace|instead|substitute|stop|safe to skip)\b",
    # dosage
    r"\b(what|which|how much|how many)\b.{0,20}\b(dose|dosage|mg|milligrams?|tablets?|pills?|capsules?|grams? of)\b",
    r"\b(dose|dosage)\b.{0,20}\b(should i|do i|for me|to take)\b",
    # diagnosis / treatment / cure
    r"\b(diagnos(e|is)|do i have (a |an )?(disease|condition|cancer|diabetes|infection|disorder)|am i (sick|ill|having|suffering)|is it (cancer|a tumou?r|diabetes|a heart attack))\b",
    r"\b(can|will|does|could)\b.{0,40}\b(cure|treat|heal|reverse|fix)\b.{0,30}\b(my|the|disease|condition|diabetes|cancer|hypertension|anemia|anaemia|depression|infection)\b",
    r"\b(prescribe|prescription for|treatment plan for)\b",
    # symptoms needing a clinician
    r"\b(chest pain|shortness of breath|blood in (my )?(stool|urine|vomit)|coughing (up )?blood|fainting|passed out|severe (headache|abdominal pain))\b",
]
_COMPILED = [re.compile(p, _FLAGS) for p in PATTERNS]


def needs_clinician_en(message: str) -> bool:
    return any(p.search(message) for p in _COMPILED)


def boundary_reply_en(region: str | None) -> str:
    return (
        "I'm an AI wellness companion, not a doctor, so I can't diagnose, advise on medication or doses, "
        "or say whether a food or herb can treat, cure or replace a medicine. Please don't stop or change "
        "any prescribed medication without talking to your doctor or pharmacist.\n\n"
        "I'm happy to help with everyday routines such as sleep habits, seasonal eating, movement and stress.\n\n"
        f"If you have severe or sudden symptoms, call {emergency_phrase_en(region)} or seek urgent medical care.\n\n"
        "For wellness routine guidance only; not medical diagnosis or treatment."
    )
