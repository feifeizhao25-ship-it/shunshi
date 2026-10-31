"""国际版危机求助资源（按地区）。国内版仍只用 app/safety/config.py 里的国内热线。

只收录核验过的官方 / 运营机构自己公布的号码；没有核验的地区一律走通用目录
（findahelpline.com，ThroughLine 运营，覆盖 170+ 个国家）+「拨打当地急救电话」，
不猜号码。每条都带来源链接与核验日期，改号码必须同时改来源。

Verified 2026-10-31 against the operators' own pages (links below).
"""

from __future__ import annotations

from dataclasses import dataclass

VERIFIED_AT = "2026-10-31"
DIRECTORY_URL = "https://findahelpline.com"
DIRECTORY_NAME = "Find A Helpline (findahelpline.com)"


@dataclass(frozen=True)
class CrisisResource:
    region: str
    name: str
    contact: str          # 对用户显示的联系方式
    emergency: str        # 当地急救电话（紧急危险时）
    source_url: str
    detail: str = ""


RESOURCES: dict[str, CrisisResource] = {
    "US": CrisisResource(
        "US", "988 Suicide & Crisis Lifeline", "call or text 988, or chat at 988lifeline.org", "911",
        "https://988lifeline.org/get-help/", "Free, confidential, 24/7."),
    "CA": CrisisResource(
        "CA", "9-8-8 Suicide Crisis Helpline", "call or text 9-8-8", "911",
        "https://988.ca/", "Free, confidential, 24/7, in English or French."),
    "GB": CrisisResource(
        "GB", "Samaritans", "call 116 123 (free from any phone)", "999",
        "https://www.samaritans.org/how-we-can-help/contact-samaritan/talk-us-phone/",
        "Open 24 hours a day, 365 days a year."),
    "IE": CrisisResource(
        "IE", "Samaritans Ireland", "call 116 123 (free)", "112 or 999",
        "https://www.samaritans.org/samaritans-ireland/", "Open 24 hours a day, 365 days a year."),
    "AU": CrisisResource(
        "AU", "Lifeline Australia", "call 13 11 14, or text 0477 13 11 14", "000",
        "https://www.lifeline.org.au/131114", "24/7 crisis support by phone, text and chat."),
    "NZ": CrisisResource(
        "NZ", "1737, Need to talk?", "call or text 1737 (free)", "111",
        "https://www.1737.org.nz/how-1737-works", "24/7 support from trained counsellors."),
}

GENERIC_EMERGENCY = "your local emergency number"


def resource_for(region: str | None) -> CrisisResource | None:
    return RESOURCES.get((region or "").upper())


def crisis_reply_en(region: str | None) -> str:
    """危机回复（英文）。已知地区给本地资源；未知地区给通用目录，不给任何国家的号码。"""
    res = resource_for(region)
    head = (
        "I'm really sorry you're feeling this way, and I'm glad you told me. "
        "You matter, and you don't have to go through this alone.\n\n"
    )
    if res:
        body = (
            f"**Talk to someone now**\n- {res.name}: {res.contact}. {res.detail}\n\n"
            f"**If you are in immediate danger**, call {res.emergency} or go to your nearest emergency department.\n\n"
        )
    else:
        body = (
            "**Talk to someone now**\n"
            f"- {DIRECTORY_NAME} lists free, confidential helplines by country: {DIRECTORY_URL}\n\n"
            f"**If you are in immediate danger**, call {GENERIC_EMERGENCY} or go to your nearest emergency department.\n\n"
        )
    tail = (
        "If you can, tell someone you trust how you feel, and stay with them or let them stay with you. "
        "I'm an AI companion, not a counsellor or a doctor, so please reach out to the people above."
    )
    return head + body + tail


def distress_suffix_en(region: str | None) -> str:
    res = resource_for(region)
    if res:
        return f"\n\nIf these feelings don't ease, you can reach {res.name}: {res.contact}. Talking to someone you trust can also help."
    return (
        f"\n\nIf these feelings don't ease, {DIRECTORY_NAME} lists free helplines by country: {DIRECTORY_URL}. "
        "Talking to someone you trust can also help."
    )


def emergency_phrase_en(region: str | None) -> str:
    res = resource_for(region)
    return res.emergency if res else GENERIC_EMERGENCY
