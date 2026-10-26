"""增长系统里不许随配置改掉的常量。

人工发布的平台、15% 永久对照、人工智能生成标识，都写死在这里。
对照比例不是 Settings 字段，避免被环境变量调成 0。
"""

from __future__ import annotations

import re

AIGC_LABEL = "本内容由人工智能生成。"
DISCLAIMER = "仅供作息安排参考，不是医疗诊断或治疗建议。"
REFUSAL = "这个问题不能写成发布稿。想安排作息的话，直接说一个节气就行。"

# 2026 年这些平台不允许未确认的自动发布。抖音同样只进人工队列。
HUMAN_CHANNELS = frozenset({"小红书", "公众号", "视频号", "抖音", "知乎"})
OWN_CHANNELS = frozenset({"小程序", "站内", "官网", "推送"})

# 永久对照：sha256 桶 10000 格里的前 1500 格，即 15%。
CONTROL_SLOTS = 1500
BUCKET_SLOTS = 10000

HOOK_THRESHOLD = 0.35
HOOK_WEIGHTS = (0.30, 0.25, 0.25, 0.20)  # 话题、长度、互动、标识
MIN_VERBATIM = 12
MAX_PROPOSALS = 3
PROMOTE_LIFT = 0.03

FUNNEL_EVENTS = (
    "landing_view",
    "signup",
    "first_rhythm_logged",
    "subscription_paid",
)
AUTHENTICATED_EVENTS = frozenset({"signup", "first_rhythm_logged", "subscription_paid"})

CITATION_RE = re.compile(r"\[([A-Za-z0-9_-]+)#([A-Za-z0-9_-]+)\]")
SOURCE_ID_RE = re.compile(r"^[A-Za-z0-9_-]+$")

CRON_DAILY = "40 7 * * *"
CRON_WEEKLY = "20 9 * * 0"
CRON_TIMEZONE = "Asia/Shanghai"

SOLAR_TERMS = (
    "立春", "雨水", "惊蛰", "春分", "清明", "谷雨",
    "立夏", "小满", "芒种", "夏至", "小暑", "大暑",
    "立秋", "处暑", "白露", "秋分", "寒露", "霜降",
    "立冬", "小雪", "大雪", "冬至", "小寒", "大寒",
)
DRAFT_ANGLES = ("早睡", "起床", "午间")
