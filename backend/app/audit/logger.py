"""
顺时 AI Audit 日志系统
AI Audit Logging System

功能：
- 请求记录
- 响应记录
- 成本追踪
- 性能监控
- 问题追溯

作者: Claw 🦅
日期: 2026-03-09
"""

from typing import Optional, Dict, Any, List
from datetime import datetime, timedelta
from enum import Enum
from dataclasses import dataclass, field
import json
import logging

logger = logging.getLogger(__name__)


class AuditEventType(str, Enum):
    """审计事件类型"""
    REQUEST = "request"           # AI 请求
    RESPONSE = "response"         # AI 响应
    ERROR = "error"               # 错误
    FALLBACK = "fallback"         # 模型降级
    CACHE_HIT = "cache_hit"       # 缓存命中
    CACHE_MISS = "cache_miss"     # 缓存未命中
    SAFETY_BLOCK = "safety_block" # 安全拦截
    RATE_LIMIT = "rate_limit"    # 限流


class AuditSeverity(str, Enum):
    """严重级别"""
    INFO = "info"
    WARNING = "warning"
    ERROR = "error"
    CRITICAL = "critical"


@dataclass
class AuditEvent:
    """审计事件"""
    event_id: str
    event_type: AuditEventType
    timestamp: datetime = field(default_factory=datetime.now)
    
    # 用户信息
    user_id: str = ""
    user_tier: str = "free"
    
    # 请求信息
    api_path: str = ""
    skill_name: Optional[str] = None
    prompt: str = ""
    prompt_tokens: int = 0
    
    # 模型信息
    model: str = ""
    fallback_model: Optional[str] = None
    
    # 响应信息
    response: str = ""
    response_tokens: int = 0
    latency_ms: int = 0
    
    # 成本
    cost_usd: float = 0.0
    
    # 状态
    status: str = "success"
    error_message: Optional[str] = None
    
    # 严重级别
    severity: AuditSeverity = AuditSeverity.INFO
    
    # 元数据
    metadata: Dict[str, Any] = field(default_factory=dict)
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            "event_id": self.event_id,
            "event_type": self.event_type,
            "timestamp": self.timestamp.isoformat(),
            "user_id": self.user_id,
            "user_tier": self.user_tier,
            "api_path": self.api_path,
            "skill_name": self.skill_name,
            "prompt": self.prompt[:200] + "..." if len(self.prompt) > 200 else self.prompt,
            "prompt_tokens": self.prompt_tokens,
            "model": self.model,
            "fallback_model": self.fallback_model,
            "response": self.response[:200] + "..." if len(self.response) > 200 else self.response,
            "response_tokens": self.response_tokens,
            "latency_ms": self.latency_ms,
            "cost_usd": self.cost_usd,
            "status": self.status,
            "error_message": self.error_message,
            "severity": self.severity,
            "metadata": self.metadata,
        }


class AuditLogger:
    """
    顺时 AI 审计日志
    
    功能：
    - 全量请求记录
    - 成本追踪
    - 性能监控
    - 问题追溯
    """
    
    def __init__(self, retention_days: int = 30):
        self.retention_days = retention_days
        self._events: List[AuditEvent] = []
        self._stats = {
            "total_requests": 0,
            "total_cost_usd": 0.0,
            "cache_hits": 0,
            "fallbacks": 0,
            "errors": 0,
        }
    
    def log_request(
        self,
        event_id: str,
        user_id: str,
        user_tier: str,
        api_path: str,
        prompt: str,
        model: str,
        skill_name: Optional[str] = None,
        **metadata,
    ) -> AuditEvent:
        """记录请求"""
        event = AuditEvent(
            event_id=event_id,
            event_type=AuditEventType.REQUEST,
            user_id=user_id,
            user_tier=user_tier,
            api_path=api_path,
            skill_name=skill_name,
            prompt=prompt,
            model=model,
            metadata=metadata,
        )
        
        self._events.append(event)
        self._stats["total_requests"] += 1
        
        logger.info(f"[Audit] 请求: {event_id[:8]}... {api_path} → {model}")
        return event
    
    def log_response(
        self,
        event_id: str,
        response: str,
        response_tokens: int,
        latency_ms: int,
        cost_usd: float,
        **metadata,
    ) -> None:
        """记录响应"""
        event = self._find_event(event_id)
        if not event:
            logger.warning(f"[Audit] 事件不存在: {event_id}")
            return
        
        event.event_type = AuditEventType.RESPONSE
        event.response = response
        event.response_tokens = response_tokens
        event.latency_ms = latency_ms
        event.cost_usd = cost_usd
        event.metadata.update(metadata)
        
        self._stats["total_cost_usd"] += cost_usd
        
        logger.info(f"[Audit] 响应: {event_id[:8]}..., latency={latency_ms}ms, cost=${cost_usd:.4f}")
    
    def log_fallback(
        self,
        event_id: str,
        from_model: str,
        to_model: str,
        reason: str,
    ) -> None:
        """记录降级"""
        event = self._find_event(event_id)
        if event:
            event.event_type = AuditEventType.FALLBACK
            event.fallback_model = to_model
            event.metadata["fallback_reason"] = reason
            event.severity = AuditSeverity.WARNING
        
        self._stats["fallbacks"] += 1
        logger.warning(f"[Audit] 降级: {event_id[:8]}... {from_model} → {to_model} ({reason})")
    
    def log_cache_hit(self, event_id: str) -> None:
        """记录缓存命中"""
        event = self._find_event(event_id)
        if event:
            event.event_type = AuditEventType.CACHE_HIT
            event.status = "cached"
        
        self._stats["cache_hits"] += 1
    
    def log_error(
        self,
        event_id: str,
        error_message: str,
        severity: AuditSeverity = AuditSeverity.ERROR,
    ) -> None:
        """记录错误"""
        event = self._find_event(event_id)
        if event:
            event.event_type = AuditEventType.ERROR
            event.status = "error"
            event.error_message = error_message
            event.severity = severity
        
        self._stats["errors"] += 1
        logger.error(f"[Audit] 错误: {event_id[:8]}... {error_message}")
    
    def _find_event(self, event_id: str) -> Optional[AuditEvent]:
        """查找事件"""
        for event in reversed(self._events):
            if event.event_id == event_id:
                return event
        return None
    
    def get_stats(self) -> Dict[str, Any]:
        """获取统计信息"""
        return {
            **self._stats,
            "total_events": len(self._events),
            "avg_cost_per_request": (
                self._stats["total_cost_usd"] / self._stats["total_requests"]
                if self._stats["total_requests"] > 0 else 0
            ),
            "cache_hit_rate": (
                self._stats["cache_hits"] / self._stats["total_requests"]
                if self._stats["total_requests"] > 0 else 0
            ),
        }
    
    def get_recent_events(
        self,
        limit: int = 100,
        event_type: Optional[AuditEventType] = None,
        user_id: Optional[str] = None,
    ) -> List[Dict[str, Any]]:
        """获取最近事件"""
        events = self._events[-limit:]
        
        if event_type:
            events = [e for e in events if e.event_type == event_type]
        
        if user_id:
            events = [e for e in events if e.user_id == user_id]
        
        return [e.to_dict() for e in reversed(events)]
    
    def cleanup_old_events(self) -> int:
        """清理过期事件"""
        cutoff = datetime.now() - timedelta(days=self.retention_days)
        original_count = len(self._events)
        
        self._events = [
            e for e in self._events
            if e.timestamp > cutoff
        ]
        
        removed = original_count - len(self._events)
        if removed > 0:
            logger.info(f"[Audit] 清理过期事件: {removed} 条")
        
        return removed


# ==================== 全局实例 ====================

audit_logger = AuditLogger(retention_days=30)


# ==================== 使用示例 ====================

def demo_audit():
    """演示审计系统"""
    import uuid
    
    logger = AuditLogger()
    
    print("=" * 60)
    print("顺时 AI Audit 系统演示")
    print("=" * 60)
    
    # 模拟请求
    event_id = str(uuid.uuid4())
    logger.log_request(
        event_id=event_id,
        user_id="user_001",
        user_tier="premium",
        api_path="/chat/send",
        prompt="今天适合吃什么",
        model="deepseek-v3.2",
    )
    
    # 模拟响应
    logger.log_response(
        event_id=event_id,
        response="春季宜养肝，多吃青色食物...",
        response_tokens=50,
        latency_ms=1200,
        cost_usd=0.002,
    )
    
    # 模拟降级
    event_id2 = str(uuid.uuid4())
    logger.log_request(
        event_id=event_id2,
        user_id="user_002",
        user_tier="free",
        api_path="/weekly-report",
        prompt="生成周报",
        model="qwen3-235b",
    )
    logger.log_fallback(
        event_id=event_id2,
        from_model="qwen3-235b",
        to_model="kimi-k2-thinking",
        reason="Qwen3 超时",
    )
    
    # 统计
    print("\n[统计信息]")
    stats = logger.get_stats()
    for k, v in stats.items():
        print(f"  {k}: {v}")
    
    # 最近事件
    print("\n[最近事件]")
    for e in logger.get_recent_events(limit=2):
        print(f"  - {e['event_type']}: {e['api_path']} → {e['model']}")


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    demo_audit()
