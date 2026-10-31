"""请求的语言 / 地区 / 市场：由客户端头决定，不由用户消息的文字决定。

国际版客户端发 ``Accept-Language``（设备语言，如 ``en-US``）、可选 ``X-Region``（ISO 国家码）、
可选 ``X-App-Market``（``global`` / ``cn``）。老的国内客户端什么都不发，按国内处理，行为不变。

规则（按顺序）：
1. ``X-App-Market`` 明确给了 ``global`` / ``cn`` 就用它；
2. 否则 ``Accept-Language`` 首选语言不是中文（``zh``）就当国际版；
3. 其余（没有头、或中文）当国内版。
国际版一律用英文回答、英文安全文案、本地危机资源；地区取 ``X-Region``，否则取语言标签里的国家
（``en-GB`` → GB），都没有就是 None，此时只给通用目录和「当地急救电话」，不猜号码。
"""

from __future__ import annotations

import re
from dataclasses import dataclass

from fastapi import Header

_REGION_RE = re.compile(r"^[A-Za-z]{2}$")


@dataclass(frozen=True)
class RequestLocale:
    market: str = "cn"          # "cn" | "global"
    lang: str = "zh"            # "zh" | "en"
    region: str | None = None   # ISO 3166-1 alpha-2, upper case
    tag: str | None = None      # 原始语言标签，如 en-US

    @property
    def is_global(self) -> bool:
        return self.market == "global"


def _first_tag(accept_language: str | None) -> str | None:
    if not accept_language:
        return None
    first = accept_language.split(",")[0].split(";")[0].strip()
    return first or None


def resolve_locale(
    accept_language: str | None = None,
    app_market: str | None = None,
    region: str | None = None,
) -> RequestLocale:
    tag = _first_tag(accept_language)
    primary = tag.split("-")[0].lower() if tag else None
    tag_region = None
    if tag and "-" in tag:
        for part in tag.split("-")[1:]:
            if _REGION_RE.match(part):
                tag_region = part.upper()
                break
    market_header = (app_market or "").strip().lower()
    if market_header in ("global", "cn"):
        market = market_header
    elif primary and primary != "zh":
        market = "global"
    else:
        market = "cn"
    chosen_region = None
    if region and _REGION_RE.match(region.strip()):
        chosen_region = region.strip().upper()
    elif tag_region:
        chosen_region = tag_region
    if market == "cn":
        return RequestLocale(market="cn", lang="zh", region=chosen_region or "CN", tag=tag)
    return RequestLocale(market="global", lang="en", region=chosen_region, tag=tag)


def request_locale(
    accept_language: str | None = Header(None, alias="Accept-Language"),
    app_market: str | None = Header(None, alias="X-App-Market"),
    region: str | None = Header(None, alias="X-Region"),
) -> RequestLocale:
    return resolve_locale(accept_language, app_market, region)
