# -*- coding: utf-8 -*-
"""国内版隐私政策（网页版与 App 内两份）不得混入国际版内容或与实现不符的承诺。

2026-09-21：网页版写着 Google、Stripe 付款、GDPR、「国际版 SEASONS 数据存新加坡或美国」、
「健康记录 AES-256 加密存储」「注销后 30 天内删除」；App 内那份写着 GDPR、「AI 对话记录
AES-256 加密存储」「自研模型」。代码里没有这些：国内版只接境内模型、注销当即删除。
"""
from __future__ import annotations

import pathlib

import pytest

BACKEND = pathlib.Path(__file__).resolve().parent.parent
REPO = BACKEND.parent
FORBIDDEN = ("Stripe", "Google", "GDPR", "SEASONS", "新加坡", "美国", "AES-256", "自研模型", "30 天内", "TLS 1.3")

DOCS = [
    BACKEND / "app/static/privacy-policy.html",
    REPO / "android-cn/lib/presentation/pages/legal/privacy_policy_page.dart",
    REPO / "ios-cn/lib/presentation/pages/legal/privacy_policy_page.dart",
]


@pytest.mark.parametrize("path", DOCS, ids=lambda p: str(p.relative_to(REPO)))
def test_domestic_privacy_policy_has_no_international_or_false_claims(path):
    if not path.exists():
        pytest.skip("not present")
    text = path.read_text(encoding="utf-8")
    hits = [word for word in FORBIDDEN if word in text]
    assert hits == []
    assert "DeepSeek" in text and "SiliconFlow" in text
