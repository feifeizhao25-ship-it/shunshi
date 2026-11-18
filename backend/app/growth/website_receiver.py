"""自有网站发布接收口：运营中枢调 ``POST /api/v1/growth/publish/website``。

请求格式照运营中枢 ``ops/airui_ops/publish.py`` 的 ``Publisher._deliver``（contentflow 仓库）：

    POST {api_base}/growth/publish/website
    Authorization: Bearer <令牌>
    X-Airui-Contract: live
    {"content": {"product", "channel", "title", "body", "url"}, "stub": false, "note": "",
     "approval": {"id", "status", "content_sha256", "channel", "detail_checked"}}   # approval 见下

四件事同时满足才接收，任何一件不满足就拒绝并给出原因代码：

1. 批准单：``approval.status == "approved"``，且 ``approval.content_sha256`` 等于对 ``content`` 重新计算的哈希
   （算法和运营中枢 ``airui_ops.content.content_sha256`` 一致：``json.dumps(sort_keys=True,
   ensure_ascii=False, separators=(",", ":"))`` 后取 SHA-256）。企业微信审批（channel=oa）还要
   ``detail_checked``，和运营中枢的规则一致。
   **注意**：运营中枢目前的请求体里没有 ``approval``，所以现在每一次调用都会被拒（approval_missing），
   要等运营中枢把批准单一起带过来。
2. 时间：按服务器时钟、上海时间 08:00–21:30（含两端整分，和运营中枢 ``in_window`` 一致）。
3. 人工智能生成标识：正文里有 “本内容由人工智能生成。” 和 “仅供作息安排参考，不是医疗诊断或治疗建议。”
   （运营中枢 ``AIGC_TEXT['shunshi']`` 和 ``SHUNSHI_DISCLAIMER``）。
4. 审计：在同一个事务里写一条只追加的审计（``growth_audit_log``）；写不进去就整笔回滚，不接收。

另外：开关 ``growth_publish_receiver_enabled`` 默认关；全局急停打开时拒绝；内容要过已有的合规门。
接收以后只存进 ``growth_website_submission``，不上线、不转发到任何外部平台。
"""

from __future__ import annotations

import hashlib
import hmac
import json
import os
from dataclasses import dataclass, field
from datetime import datetime
from zoneinfo import ZoneInfo

from sqlalchemy.orm import Session

from app.growth.audit import append_audit
from app.growth.compliance.gate import violation_codes
from app.growth.models import GrowthWebsiteSubmission

RECEIVER_PATH = "/api/v1/growth/publish/website"
TOKEN_ENV = "OPENCLAW_SHUNSHI_PUBLISH_TOKEN"
# 这些变量的值不能拿来当接收口令牌：配置成相同的值时，接收口按“未配置”处理。
FORBIDDEN_REUSE_ENVS = (
    "OPENCLAW_SHUNSHI_ADMIN_TOKEN",
    "SHUNSHI_FUNNEL_READONLY_TOKEN",
    "SHUNSHI_JWT_SECRET",
    "ADMIN_JWT_SECRET",
    "ADMIN_PASSWORD_HASH",
    "SHUNSHI_ADMIN_TOKEN",
)
SHANGHAI = ZoneInfo("Asia/Shanghai")
WINDOW = ((8, 0), (21, 30))
AIGC_LABEL = "本内容由人工智能生成。"
DISCLAIMER = "仅供作息安排参考，不是医疗诊断或治疗建议。"
CHANNEL = "website_seo"
PRODUCT = "shunshi"

# 原因代码 → (HTTP 状态, 中文说明)
REASONS: dict[str, tuple[int, str]] = {
    "disabled": (503, "接收口未开启（SHUNSHI_GROWTH_PUBLISH_RECEIVER_ENABLED 默认关）"),
    "token_not_configured": (503, "接收口令牌未配置，或与其他口令相同"),
    "unauthorized": (401, "令牌缺失或不对"),
    "bad_request": (422, "请求体格式不对"),
    "kill_switch": (423, "全局急停已打开"),
    "outside_window": (403, "不在上海时间 08:00–21:30 之间"),
    "aigc_missing": (422, "正文缺少人工智能生成标识或顺时免责声明"),
    "approval_missing": (409, "没有批准单"),
    "approval_not_approved": (409, "批准单状态不是 approved"),
    "approval_detail_not_checked": (409, "企业微信审批未确认看过详情"),
    "sha_mismatch": (409, "批准单哈希与内容不一致"),
    "compliance_failed": (422, "内容未过合规门"),
    "audit_unavailable": (503, "审计记录写不进去，不接收"),
}


def content_sha256(payload) -> str:
    """和运营中枢 airui_ops.content.content_sha256 完全一致。"""
    raw = json.dumps(payload, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()


def in_window(now: datetime) -> bool:
    local = now.astimezone(SHANGHAI)
    minutes = local.hour * 60 + local.minute
    (sh, sm), (eh, em) = WINDOW
    return sh * 60 + sm <= minutes <= eh * 60 + em


def now_utc() -> datetime:
    """单独一个函数，测试里替换它来固定时间。"""
    from datetime import timezone

    return datetime.now(timezone.utc)


def configured_token(env=os.environ) -> str:
    token = (env.get(TOKEN_ENV) or "").strip()
    if not token:
        return ""
    for name in FORBIDDEN_REUSE_ENVS:
        other = (env.get(name) or "").strip()
        if other and hmac.compare_digest(other.encode(), token.encode()):
            return ""
    return token


def token_ok(supplied: str, expected: str) -> bool:
    if not supplied or not expected:
        return False
    return hmac.compare_digest(hashlib.sha256(supplied.encode()).digest(), hashlib.sha256(expected.encode()).digest())


def bearer(header: str | None) -> str:
    scheme, _, token = (header or "").partition(" ")
    return token.strip() if scheme.lower() == "bearer" else ""


@dataclass
class Verdict:
    accepted: bool
    reason: str
    failed: list[str] = field(default_factory=list)
    data: dict = field(default_factory=dict)

    @property
    def status_code(self) -> int:
        return 201 if self.accepted and not self.data.get("duplicate") else 200 if self.accepted else REASONS[self.reason][0]

    def body(self) -> dict:
        if self.accepted:
            return {"success": True, "accepted": True, **self.data}
        return {
            "success": False,
            "accepted": False,
            "reason": self.reason,
            "message": REASONS[self.reason][1],
            "failed": self.failed,
            **self.data,
        }


def check_content(payload: dict, now: datetime) -> tuple[list[str], dict, str]:
    """返回（不满足的原因列表、content、哈希）。只做判断，不碰数据库。"""
    content = payload.get("content")
    if not isinstance(content, dict) or not isinstance(content.get("body"), str) or not isinstance(content.get("title"), str):
        return ["bad_request"], {}, ""
    if content.get("product", PRODUCT) != PRODUCT or content.get("channel", CHANNEL) != CHANNEL or payload.get("stub"):
        return ["bad_request"], {}, ""
    digest = content_sha256(content)
    failed: list[str] = []
    if not in_window(now):
        failed.append("outside_window")
    body = content["body"]
    if AIGC_LABEL not in body or DISCLAIMER not in body:
        failed.append("aigc_missing")
    approval = payload.get("approval")
    if not isinstance(approval, dict) or not approval:
        failed.append("approval_missing")
    elif approval.get("status") != "approved":
        failed.append("approval_not_approved")
    elif str(approval.get("content_sha256") or "").lower() != digest:
        failed.append("sha_mismatch")
    elif approval.get("channel") == "oa" and not approval.get("detail_checked"):
        failed.append("approval_detail_not_checked")
    if violation_codes(f"{content['title']}\n{body}"):
        failed.append("compliance_failed")
    return failed, content, digest


def _audit(session: Session, *, decision: str, reason: str, digest: str, object_key: str = "", extra: dict | None = None):
    return append_audit(
        session,
        action="website_receive",
        decision=decision,
        object_key=object_key,
        actor="ops_hub",
        detail={"reason": reason, "content_sha256": digest, "path": RECEIVER_PATH, **(extra or {})},
    )


def receive(session: Session, payload: dict, *, now: datetime, kill_switch: bool) -> Verdict:
    """令牌和开关已经在路由里核过。这里做四项核对、存内容、写审计。"""
    if kill_switch:
        verdict = Verdict(False, "kill_switch", ["kill_switch"])
        _safe_reject_audit(session, verdict, "")
        return verdict
    failed, content, digest = check_content(payload if isinstance(payload, dict) else {}, now)
    if failed:
        verdict = Verdict(False, failed[0], failed, {"content_sha256": digest} if digest else {})
        _safe_reject_audit(session, verdict, digest)
        return verdict

    existing = session.query(GrowthWebsiteSubmission).filter_by(content_sha256=digest).one_or_none()
    approval_id = str((payload.get("approval") or {}).get("id") or "")
    try:
        with session.begin_nested():
            if existing is not None:
                row = existing
                _audit(session, decision="duplicate", reason="approved", digest=digest, object_key=row.id)
                duplicate = True
            else:
                row = GrowthWebsiteSubmission(
                    content_sha256=digest,
                    approval_id=approval_id[:120],
                    title=content["title"][:200],
                    body=content["body"],
                    url=str(content.get("url") or "")[:500],
                    content_json=json.dumps(content, ensure_ascii=False, sort_keys=True),
                )
                session.add(row)
                session.flush()
                _audit(session, decision="accept", reason="approved", digest=digest, object_key=row.id,
                       extra={"approval_id": approval_id[:120]})
                duplicate = False
    except Exception:
        # 审计或存储失败：嵌套事务已回滚，内容不留下。外层再试着记一条拒绝（也可能写不进去）。
        verdict = Verdict(False, "audit_unavailable", ["audit_unavailable"], {"content_sha256": digest})
        _safe_reject_audit(session, verdict, digest)
        return verdict
    return Verdict(True, "approved", [], {
        "id": row.id,
        "url": None,
        "content_sha256": digest,
        "stored": True,
        "published": False,
        "duplicate": duplicate,
        "note": "已存进顺时后台，未上线、未转发到任何外部平台",
    })


def _safe_reject_audit(session: Session, verdict: Verdict, digest: str) -> None:
    try:
        with session.begin_nested():
            _audit(session, decision="reject", reason=verdict.reason, digest=digest, extra={"failed": verdict.failed})
    except Exception:
        pass
