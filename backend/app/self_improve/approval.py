"""企业微信审批。

默认关闭、超时即不晋升（timeout = no promotion）。
审批人名单来自环境变量 ``POLICY_REVIEWERS``（逗号分隔的企业微信 userid）。
**名单为空 = 没有任何人能批准**：提案停在待审，直到超时作废。TODO(owner): 由负责人填写，
本代码与自动化流程都不得代填。专家签字（expert_signed）由真实人员在外部系统完成，这里永不设置。
密钥只通过环境变量名读取：WECOM_CORP_ID / WECOM_AGENT_ID / WECOM_APP_SECRET。
"""

from __future__ import annotations

import json
import os
from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import Callable, Mapping, Protocol

from .store import Candidate


def reviewers_from_env(env: Mapping[str, str] | None = None) -> frozenset:
    env = os.environ if env is None else env
    return frozenset(x.strip() for x in (env.get("POLICY_REVIEWERS") or "").split(",") if x.strip())


@dataclass(frozen=True)
class ApprovalPolicy:
    reviewers: frozenset = frozenset()
    timeout_hours: int = 72

    @classmethod
    def from_env(cls, env: Mapping[str, str] | None = None) -> "ApprovalPolicy":
        env = os.environ if env is None else env
        return cls(reviewers=reviewers_from_env(env), timeout_hours=int(env.get("SIL_APPROVAL_TIMEOUT_HOURS", "72")))

    def can_approve(self, reviewer: str) -> bool:
        return reviewer in self.reviewers  # 空名单 → 恒为 False


def build_card(c: Candidate, eval_summary: Mapping, base_url: str = "") -> dict:
    """企业微信 textcard 消息体（只构造，不发送）。"""
    gates = eval_summary.get("gates", {})
    desc = (
        f"<div class=\"gray\">对象：{c.target}（{c.kind}）</div>"
        f"<div class=\"normal\">{c.summary[:120]}</div>"
        f"<div class=\"highlight\">门禁：{'通过' if gates.get('passed') else '未通过'}"
        f"{' · 需真实专家签字' if c.needs_expert else ''}</div>"
        f"<div class=\"gray\">超时未批准将作废，不会上线。</div>"
    )
    return {
        "msgtype": "textcard",
        "textcard": {
            "title": f"[自改进] 待审批：{c.id}",
            "description": desc,
            "url": f"{base_url}/self-improve/{c.id}" if base_url else "about:blank",
            "btntxt": "查看详情",
        },
    }


class Gateway(Protocol):
    def send(self, card: dict, to_users: list[str]) -> str: ...


class NullGateway:
    """未配置企业微信时使用：只记录，不外发。"""

    def __init__(self):
        self.sent: list[tuple[dict, list[str]]] = []

    def send(self, card: dict, to_users: list[str]) -> str:
        self.sent.append((card, list(to_users)))
        return f"null-{len(self.sent)}"


class WeComGateway:
    """企业微信应用消息。http 由调用方注入（便于测试与复用产品内已有客户端）。

    http(method, url, json_body) -> dict。令牌读取来自环境变量名，不落盘。
    """

    API = "https://qyapi.weixin.qq.com/cgi-bin"

    def __init__(self, http: Callable[[str, str, dict | None], dict], env: Mapping[str, str] | None = None):
        self._http = http
        self._env = os.environ if env is None else env

    def configured(self) -> bool:
        return all(self._env.get(k) for k in ("WECOM_CORP_ID", "WECOM_AGENT_ID", "WECOM_APP_SECRET"))

    def send(self, card: dict, to_users: list[str]) -> str:
        if not self.configured():
            raise RuntimeError("wecom_not_configured")
        if not to_users:
            raise RuntimeError("no_reviewers_configured")
        tok = self._http(
            "GET",
            f"{self.API}/gettoken?corpid={self._env['WECOM_CORP_ID']}&corpsecret={self._env['WECOM_APP_SECRET']}",
            None,
        )
        body = {**card, "touser": "|".join(to_users), "agentid": int(self._env["WECOM_AGENT_ID"])}
        res = self._http("POST", f"{self.API}/message/send?access_token={tok['access_token']}", body)
        if res.get("errcode", 0) != 0:
            raise RuntimeError(f"wecom_send_failed:{res.get('errcode')}")
        return str(res.get("msgid", ""))


def is_timed_out(updated_at_iso: str, now: datetime, timeout_hours: int) -> bool:
    return now - datetime.fromisoformat(updated_at_iso) >= timedelta(hours=timeout_hours)
