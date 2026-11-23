"""顺时国内版：明显不在养生范围的请求（写代码、投资理财）礼貌引回本产品。

2026-11-23 真模型复测：「帮我写一段Python爬虫代码」被模型直接写了代码；
「比特币现在还能买吗」虽然拒了，但结尾挂着「不是医疗诊断」的尾注，不对题。
这类请求（以及翻译、代写作文周报）不调用模型，返回固定的引回话术（不带医疗尾注）。

只认「请求本身就是写代码 / 投资买卖」的句子；句子里提到作息、睡眠、身体、
情绪等养生内容时（比如「写代码到凌晨，作息怎么调」「炒股压力大睡不着」），
仍按养生问题正常回答。
"""

from __future__ import annotations

import re

_WELLNESS = re.compile(
    r"作息|睡|失眠|熬夜|累|疲|乏|困|肩|颈|腰|背|眼|休息|养生|饮食|吃|喝|运动|锻炼|走动|久坐|加班|"
    r"压力|焦虑|紧张|烦|情绪|心情|放松|冥想|呼吸|节气|身体|健康|体质"
)
_CODE = re.compile(
    r"(写|编写|生成|实现|调试|修改|改一下|优化|补全|解释|帮我看看?).{0,12}"
    r"(代码|程序|脚本|爬虫|函数|算法|接口|sql|正则|小程序|网页)"
    r"|(python|java|javascript|typescript|golang|c\+\+|php|sql|html|css)\s*(代码|程序|脚本|怎么写|报错)"
    r"|爬虫",
    re.IGNORECASE,
)
_FINANCE = re.compile(
    r"(比特币|以太坊|狗狗币|虚拟货币|加密货币|数字货币|炒币|币圈|股票|炒股|个股|基金|期货|外汇|彩票|理财产品|黄金)"
    r".{0,12}(买|卖|投资|推荐|能不能|还能|涨|跌|收益|行情|值得|值不值|入手|抄底|割肉|仓)"
    r"|(买|卖|投资|推荐|抄底).{0,8}(比特币|以太坊|虚拟货币|加密货币|股票|基金|期货|外汇|彩票)"
)

_WRITING = re.compile(
    r"(翻译|译成|翻成)(一下|成|为)?.{0,6}(英文|中文|日文|韩文|英语|日语|这句|这段|下面)"
    r"|(帮我|给我|替我|请)?(写|代写|改写|润色).{0,8}(作文|论文|作业|周报|月报|工作总结|述职|简历|求职信|演讲稿|检讨)"
)

_TOPIC_LABEL = {"code": "写代码、做程序", "finance": "投资理财和买卖建议", "writing": "翻译和代写文章"}

_LEAD_BACK = (
    "顺时能陪你做的是：安排作息和睡眠、按节气调整饮食和起居、做放松和呼吸练习、记录每天的状态。"
    "比如可以问我「这周作息怎么安排」「晚上总睡不着怎么办」「大雪节气起居要注意什么」。"
)


def off_topic_kind(text: str) -> str | None:
    """明显不在养生范围时返回 'code' / 'finance' / 'writing'，否则 None。"""
    sample = (text or "").strip()
    if not sample or _WELLNESS.search(sample):
        return None
    if _CODE.search(sample):
        return "code"
    if _FINANCE.search(sample):
        return "finance"
    if _WRITING.search(sample):
        return "writing"
    return None


def off_topic_reply(kind: str) -> str:
    label = _TOPIC_LABEL.get(kind, "这个问题")
    return f"{label}不在顺时能帮忙的范围里，这里就不展开了，可以找更专业的工具或人员。\n\n{_LEAD_BACK}"
