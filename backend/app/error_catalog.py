"""用户能看到的错误文案。接口只从这里取句子，文档《错误码对照》与这里同一张表。

国内版用中文，国际版用英文。价格、备案和语音供应商不在这张表里。
"""
from __future__ import annotations

from typing import NamedTuple


class Entry(NamedTuple):
    status: int
    zh: str
    en: str


# 六种必须分开的情况：没配置、没登录、没权限、额度用完、合规拦住、服务故障。
# 登录已失效和没登录是两句，不能混用。
CATALOG: dict[str, Entry] = {
    "bad_request": Entry(400, "请求内容有误，请检查后重试", "The request looks wrong. Please check it and try again."),
    "not_signed_in": Entry(401, "请先登录", "Please sign in first."),
    "session_expired": Entry(401, "登录已失效，请重新登录", "Your session has expired. Please sign in again."),
    "forbidden": Entry(403, "没有权限进行此操作", "You don't have permission to do this."),
    "not_found": Entry(404, "没有找到相关内容", "We couldn't find what you were looking for."),
    "method_not_allowed": Entry(405, "不支持这种操作", "That action isn't supported."),
    "conflict": Entry(409, "当前状态下无法完成此操作，请刷新后重试", "This can't be done in the current state. Please refresh and try again."),
    "payload_too_large": Entry(413, "提交的内容太大", "The content you submitted is too large."),
    "invalid_input": Entry(422, "填写的内容不正确，请检查后重试", "Some of the information isn't valid. Please check it and try again."),
    "rate_limited": Entry(429, "操作太频繁，请稍后再试", "Too many requests. Please try again shortly."),
    "quota_exhausted": Entry(
        429,
        "今日对话次数已达上限，将于北京时间零点重置",
        "You have used today's chat messages. The limit resets once a day; Plan & usage shows when, in your own time zone.",
    ),
    "quota_unavailable": Entry(
        503,
        "对话额度服务暂不可用，请稍后重试",
        "The chat quota service is temporarily unavailable. Please try again shortly.",
    ),
    "quota_misconfigured": Entry(
        503,
        "对话额度配置异常，请稍后重试",
        "The chat quota is misconfigured. Please try again later.",
    ),
    "speech_unconfigured": Entry(503, "朗读服务尚未配置，暂时用不了", "Voice playback is not set up yet."),
    "sms_unconfigured": Entry(503, "短信服务尚未配置", "Text messaging is not set up yet."),
    "compliance_blocked": Entry(
        200,
        "这份回答未通过安全检查，请换个问题或咨询专业人员。",
        "This reply didn't pass the safety check. Please ask differently or talk to a professional.",
    ),
    "service_unavailable": Entry(503, "服务暂时不可用，请稍后再试", "The service is unavailable right now. Please try again later."),
    "busy": Entry(503, "服务繁忙，请稍后再试", "The service is busy. Please try again shortly."),
    "request_incomplete": Entry(400, "请求未能完成，请稍后再试", "The request couldn't be completed. Please try again later."),
}

# 状态码兜底用哪一条。401 的兜底是「请先登录」，过期令牌走 session_expired，不走这一条。
STATUS_CODE = {
    400: "bad_request",
    401: "not_signed_in",
    403: "forbidden",
    404: "not_found",
    405: "method_not_allowed",
    409: "conflict",
    413: "payload_too_large",
    422: "invalid_input",
    429: "rate_limited",
}


def text(code: str, lang: str = "zh") -> str:
    entry = CATALOG[code]
    return entry.en if lang == "en" else entry.zh


def code_for(message: str) -> str | None:
    for code, entry in CATALOG.items():
        if message == entry.zh or message == entry.en:
            return code
    return None
