"""用户能看见的文案不得承诺增强免疫、排毒、利尿、消肿。"""
import re

_REPLACEMENTS: tuple[tuple[re.Pattern[str], str], ...] = (
    (re.compile(r"(增强|提高|提升).{0,4}免疫(力|功能|应答)?"), "日常调养"),
    (re.compile(r"利尿消肿"), "多喝温水"),
    (re.compile(r"排毒利水"), "多喝温水"),
    (re.compile(r"利水消肿"), "清淡饮食"),
    (re.compile(r"排毒"), "休息"),
    (re.compile(r"利尿"), "多喝水"),
    (re.compile(r"消肿"), "放松"),
)


def redact_efficacy_claims(text: str) -> str:
    """把功效承诺换成日常说法。辟谣页不走这里，以免改掉要解释的原词。"""
    if not text:
        return text
    for pattern, replacement in _REPLACEMENTS:
        text = pattern.sub(replacement, text)
    return text
