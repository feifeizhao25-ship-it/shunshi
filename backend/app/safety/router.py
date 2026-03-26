"""
安全 API 路由
Safety API Routes

POST /api/v1/safety/check        — 手动检查文本
GET  /api/v1/safety/audit-logs    — 查看审计日志(管理员)
GET  /api/v1/safety/stats         — 安全统计
POST /api/v1/safety/rules/reload  — 热重载规则(管理员)
"""

import logging
from typing import Optional
from fastapi import APIRouter, Query, HTTPException
from pydantic import BaseModel, Field

from app.safety.guard import safety_guard, SafetyLevel
from app.safety.audit import SafetyAuditLog

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/safety", tags=["安全"])


# ==================== Models ====================

class SafetyCheckRequest(BaseModel):
    """文本安全检查请求"""
    text: str = Field(..., min_length=1, max_length=5000, description="待检查文本")
    check_type: str = Field("input", description="检查类型: input 或 output")
    user_id: str = Field("anonymous", description="用户ID")
    lang: str = Field("cn", description="语言: cn 或 en")


class SafetyCheckResponse(BaseModel):
    """文本安全检查响应"""
    level: str
    flag: str
    should_block: bool
    redirect_to_resource: bool
    log_reason: str
    detection_rules: list
    override_response: Optional[str] = None
    prefix: Optional[str] = None


# ==================== Endpoints ====================

@router.post("/check", response_model=SafetyCheckResponse)
async def check_text(request: SafetyCheckRequest):
    """
    手动检查文本安全性

    用于管理后台或调试，检查一段文本的安全级别。
    """
    if request.check_type == "output":
        result = safety_guard.check_output(
            request.text,
            {"user_id": request.user_id},
        )
    else:
        result = safety_guard.check_input(
            request.text,
            {"user_id": request.user_id, "lang": request.lang},
        )

    # 危机级别触发告警
    if result.level.value == "CRISIS":
        try:
            from app.alerts import alert_sender, AlertRules
            from app.alerts.store import alert_store as _a_store
            event = AlertRules.safety_crisis_triggered(request.user_id, "crisis")
            sent = await alert_sender.send(event)
            _a_store.record(event, sent, "webhook")
        except Exception as alert_err:
            logger.warning(f"[Alert] 安全危机告警发送异常: {alert_err}")

    return SafetyCheckResponse(
        level=result.level.value,
        flag=result.flag,
        should_block=result.should_block,
        redirect_to_resource=result.redirect_to_resource,
        log_reason=result.log_reason,
        detection_rules=result.detection_rules,
        override_response=result.override_response,
        prefix=result.prefix,
    )


@router.get("/audit-logs")
async def get_audit_logs(
    user_id: Optional[str] = Query(None, description="按用户ID过滤"),
    event_type: Optional[str] = Query(None, description="按事件类型过滤"),
    level: Optional[str] = Query(None, description="按级别过滤"),
    limit: int = Query(50, ge=1, le=200, description="返回数量"),
    offset: int = Query(0, ge=0, description="偏移量"),
):
    """
    查看安全审计日志(管理员)

    返回安全检查的历史记录，用于运营监控和问题排查。
    """
    audit = SafetyAuditLog()
    logs = audit.get_logs(
        user_id=user_id,
        event_type=event_type,
        level=level,
        limit=limit,
        offset=offset,
    )
    return {
        "success": True,
        "data": {
            "items": logs,
            "total": len(logs),
        },
    }


@router.get("/stats")
async def get_safety_stats(days: int = Query(7, ge=1, le=90, description="统计天数")):
    """
    安全统计信息

    返回安全检查的汇总统计，包括各级别事件数、危机事件数等。
    """
    audit = SafetyAuditLog()
    stats = audit.get_stats(days=days)
    return {
        "success": True,
        "data": stats,
    }


@router.post("/rules/reload")
async def reload_safety_rules():
    """
    热重载安全规则(管理员)

    重新加载安全规则配置，无需重启服务。
    """
    try:
        safety_guard.reload()
        return {
            "success": True,
            "message": "安全规则已重新加载",
            "rule_count": len(safety_guard._rules),
        }
    except Exception as e:
        logger.error("[SafetyRouter] 规则重载失败: %s", e)
        raise HTTPException(status_code=500, detail=f"规则重载失败: {e}")
