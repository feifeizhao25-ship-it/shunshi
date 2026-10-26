"""阿里云内容安全文本审核（北京）。

文档 12 把「护栏用于非百炼模型的接入方式」标为待核实：服务名、端点都可以改，
缺省用官方 TextModeration（2022-03-02）和 green-cip.cn-beijing.aliyuncs.com。
没配 SHUNSHI_GUARDRAIL_AK_ID / SHUNSHI_GUARDRAIL_AK_SECRET 时不发请求，交给本地规则。
密钥只放在签名里，不进日志。
"""

from __future__ import annotations

import base64
import hashlib
import hmac
import json
import os
import uuid
from dataclasses import dataclass
from datetime import datetime, timezone
from urllib.parse import quote

import httpx

from app.llm.domestic_gateway import host_allowed, llm_timeout

DEFAULT_ENDPOINT = "https://green-cip.cn-beijing.aliyuncs.com"
DEFAULT_SERVICE = "chat_detection"


@dataclass(frozen=True)
class ModerationResult:
    checked: bool
    hit: bool
    labels: str = ""


def _source(env: dict | None) -> dict:
    return os.environ if env is None else env


def configured(env: dict | None = None) -> bool:
    source = _source(env)
    return bool((source.get("SHUNSHI_GUARDRAIL_AK_ID") or "").strip()) and bool(
        (source.get("SHUNSHI_GUARDRAIL_AK_SECRET") or "").strip()
    )


def _percent(value: str) -> str:
    encoded = quote(str(value), safe="")
    return encoded.replace("+", "%20").replace("*", "%2A").replace("%7E", "~")


def sign(params: dict[str, str], secret: str) -> str:
    canonical = "&".join(f"{_percent(key)}={_percent(params[key])}" for key in sorted(params))
    string_to_sign = f"POST&{_percent('/')}&{_percent(canonical)}"
    digest = hmac.new(f"{secret}&".encode(), string_to_sign.encode(), hashlib.sha1).digest()
    return base64.b64encode(digest).decode()


def _endpoint(env: dict) -> str | None:
    raw = (env.get("SHUNSHI_GUARDRAIL_ENDPOINT") or DEFAULT_ENDPOINT).strip()
    host = httpx.URL(raw).host
    if not host_allowed(host):
        return None
    return raw.rstrip("/")


def _hit(payload: dict) -> ModerationResult:
    data = payload.get("Data") or payload.get("data") or {}
    if isinstance(data, str):
        try:
            data = json.loads(data)
        except ValueError:
            data = {}
    if not isinstance(data, dict):
        return ModerationResult(checked=True, hit=True, labels="unreadable")
    labels = str(data.get("Labels") or data.get("labels") or "")
    reason_raw = data.get("Reason") or data.get("reason") or ""
    risk = ""
    if isinstance(reason_raw, str) and reason_raw:
        try:
            risk = str(json.loads(reason_raw).get("riskLevel") or "")
        except ValueError:
            risk = ""
    elif isinstance(reason_raw, dict):
        risk = str(reason_raw.get("riskLevel") or "")
    # 官方说明：低风险按未命中处理；高、中风险处置。
    if not labels.strip():
        return ModerationResult(checked=True, hit=False)
    if risk.lower() == "low":
        return ModerationResult(checked=True, hit=False, labels=labels)
    return ModerationResult(checked=True, hit=True, labels=labels)


async def moderate_text(
    text: str,
    *,
    client: httpx.AsyncClient | None = None,
    env: dict | None = None,
) -> ModerationResult:
    source = _source(env)
    if not configured(source) or not (text or "").strip():
        return ModerationResult(checked=False, hit=False)
    endpoint = _endpoint(source)
    if endpoint is None:
        return ModerationResult(checked=False, hit=False)
    secret = source["SHUNSHI_GUARDRAIL_AK_SECRET"].strip()
    service = (source.get("SHUNSHI_GUARDRAIL_SERVICE") or DEFAULT_SERVICE).strip() or DEFAULT_SERVICE
    chunk = text.strip()[:600]
    params = {
        "Action": "TextModeration",
        "Version": "2022-03-02",
        "Format": "JSON",
        "AccessKeyId": source["SHUNSHI_GUARDRAIL_AK_ID"].strip(),
        "SignatureMethod": "HMAC-SHA1",
        "SignatureVersion": "1.0",
        "SignatureNonce": uuid.uuid4().hex,
        "Timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "RegionId": "cn-beijing",
        "Service": service,
        "ServiceParameters": json.dumps({"content": chunk}, ensure_ascii=False),
    }
    params["Signature"] = sign({key: value for key, value in params.items() if key != "Signature"}, secret)
    owns = client is None
    client = client or httpx.AsyncClient(timeout=llm_timeout(source))
    try:
        response = await client.post(endpoint, params=params, timeout=llm_timeout(source))
    except httpx.HTTPError:
        return ModerationResult(checked=True, hit=True, labels="transport")
    finally:
        if owns:
            await client.aclose()
    if response.status_code != 200:
        return ModerationResult(checked=True, hit=True, labels=f"http-{response.status_code}")
    try:
        body = response.json()
    except ValueError:
        return ModerationResult(checked=True, hit=True, labels="json")
    code = body.get("Code", body.get("code"))
    if code not in (200, "200", None):
        return ModerationResult(checked=True, hit=True, labels=f"code-{code}")
    return _hit(body)
