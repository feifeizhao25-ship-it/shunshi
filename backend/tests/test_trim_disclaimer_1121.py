"""2026-11-21 真实调用：SEASONS 英文长回答被 600 token 截断后，结尾的健康免责声明一起被截掉了。
截断时在截断说明后面补回对应语言的免责声明。假 HTTP，不调模型。"""
import asyncio

import httpx
import pytest

from app.llm import domestic_gateway as gw
from app.routers.chat import SYSTEM_PROMPT, system_prompt_en
from app.locale_context import RequestLocale


def _run(system, content, finish):
    messages = [{'role': 'system', 'content': system}, {'role': 'user', 'content': 'plan'}]
    def handler(req):
        return httpx.Response(200, json={'choices': [{'message': {'content': content}, 'finish_reason': finish}]})
    async def run():
        async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as client:
            return await gw.complete(messages, client=client, env={'SHUNSHI_DEEPSEEK_API_KEY': 'test'})
    return asyncio.run(run())


EN = system_prompt_en(RequestLocale(market='global', lang='en', region='AE', tag='en-AE'))


def test_disclaimers_match_the_system_prompts():
    assert gw.DISCLAIMER_EN in EN
    assert gw.DISCLAIMER_ZH in SYSTEM_PROMPT


def test_seasons_trimmed_reply_ends_with_note_then_english_disclaimer():
    out = _run(EN, 'Eat warm soups in the evening. Keep a light layer on. Open a window for fresh', 'length')
    assert out.endswith(gw.TRUNCATED_NOTE_EN + '\n\n' + gw.DISCLAIMER_EN)
    assert 'fresh' not in out
    assert out.count('not medical diagnosis') == 1
    assert '仅供' not in out


def test_domestic_trimmed_reply_keeps_its_chinese_disclaimer():
    out = _run(SYSTEM_PROMPT, '仅供作息安排参考，不是医疗诊断或治疗建议。\n\n早上喝温水。晚上十一点前睡。周三吃', 'length')
    assert out.endswith(gw.TRUNCATED_NOTE_ZH + '\n\n' + gw.DISCLAIMER_ZH)
    assert '周三吃' not in out
    assert 'medical' not in out


@pytest.mark.parametrize('english', [True, False])
def test_disclaimer_is_not_doubled_when_the_trimmed_text_already_ends_with_it(english):
    system, disclaimer = (EN, gw.DISCLAIMER_EN) if english else (SYSTEM_PROMPT, gw.DISCLAIMER_ZH)
    tail = ' Then more' if english else '然后还有'
    out = _run(system, ('Rest well. ' if english else '早点睡。') + disclaimer + tail, 'length')
    assert out.count(disclaimer) == 1


@pytest.mark.parametrize('english', [True, False])
def test_finished_replies_are_unchanged(english):
    system = EN if english else SYSTEM_PROMPT
    text = 'A complete answer.' if english else '完整的回答。'
    assert _run(system, text, 'stop') == text
