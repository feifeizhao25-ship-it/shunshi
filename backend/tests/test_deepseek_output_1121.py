"""2026-11-21 真实 UI 测试回归：推理吃掉 600-token 正文额度。假 HTTP，不调模型。"""
import asyncio
import json

import httpx
import pytest

from app.llm import domestic_gateway as gw


@pytest.mark.parametrize('english', [False, True])
def test_deepseek_thinking_is_explicitly_disabled(english):
    messages = [{'role': 'system', 'content': 'Always answer in clear, plain English' if english else '只用中文'}]
    seen = []
    def handler(req):
        seen.append(json.loads(req.content))
        return httpx.Response(200, json={'choices': [{'message': {'content': 'A complete answer.'}, 'finish_reason': 'stop'}]})
    async def run():
        async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as client:
            return await gw.complete(messages, client=client, env={'SHUNSHI_DEEPSEEK_API_KEY': 'test'})
    assert asyncio.run(run()) == 'A complete answer.'
    assert seen[0]['thinking'] == {'type': 'disabled'}


@pytest.mark.parametrize('english,text,kept,dropped', [
    (False, '先按时睡觉。3. 如果明天', '先按时睡觉。', '3. 如果明天'),
    (True, 'Try a regular bedtime. If tomorrow you', 'Try a regular bedtime.', 'If tomorrow you'),
])
def test_length_finish_is_trimmed_and_explained(english, text, kept, dropped):
    messages = [{'role': 'system', 'content': 'Always answer in clear, plain English' if english else '只用中文'}]
    def handler(req):
        return httpx.Response(200, json={'choices': [{'message': {'content': text}, 'finish_reason': 'length'}]})
    async def run():
        async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as client:
            return await gw.complete(messages, client=client, env={'SHUNSHI_DEEPSEEK_API_KEY': 'test'})
    out = asyncio.run(run())
    assert kept in out and dropped not in out
    assert ('stopped here' if english else '回答较长') in out


@pytest.mark.parametrize('english', [False, True])
@pytest.mark.parametrize('reason', ['length', 'stop'])
def test_200_but_empty_is_readable_not_502(english, reason):
    messages = [{'role': 'system', 'content': 'Always answer in clear, plain English' if english else '只用中文'}]
    def handler(req):
        return httpx.Response(200, json={'choices': [{'message': {'content': '', 'reasoning_content': 'not for users'}, 'finish_reason': reason}]})
    async def run():
        async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as client:
            return await gw.complete(messages, client=client, env={'SHUNSHI_DEEPSEEK_API_KEY': 'test'})
    out = asyncio.run(run())
    assert ('Please try' if english else '请换个说法') in out
    assert 'not for users' not in out
