"""
顺时 AI 结构化日志系统
Structured JSON Logging with daily rotation

在原有 AuditLogger 基础上扩展：
- 结构化 JSON 日志输出
- 日志级别：INFO/WARNING/ERROR
- 每条日志包含：timestamp, level, module, action, user_id, details
- 输出到文件：backend/logs/app.log（按日期轮转）

作者: Claw 🦅
日期: 2026-03-17
"""

import json
import os
import sys
import logging
from logging.handlers import TimedRotatingFileHandler
from datetime import datetime
from pathlib import Path
from typing import Optional, Dict, Any


# ==================== 日志目录 ====================

LOG_DIR = Path(__file__).resolve().parent.parent.parent / "logs"
LOG_DIR.mkdir(parents=True, exist_ok=True)
LOG_FILE = LOG_DIR / "app.log"


# ==================== JSON 格式化器 ====================

class JsonFormatter(logging.Formatter):
    """结构化 JSON 日志格式化器"""

    def format(self, record: logging.LogRecord) -> str:
        log_entry = {
            "timestamp": datetime.now().isoformat(),
            "level": record.levelname,
            "module": record.module,
            "function": record.funcName,
            "line": record.lineno,
            "message": record.getMessage(),
        }

        # 附加结构化字段
        if hasattr(record, "user_id"):
            log_entry["user_id"] = record.user_id
        if hasattr(record, "action"):
            log_entry["action"] = record.action
        if hasattr(record, "details"):
            log_entry["details"] = record.details
        if record.exc_info and record.exc_info[0] is not None:
            log_entry["exception"] = self.formatException(record.exc_info)

        return json.dumps(log_entry, ensure_ascii=False)


# ==================== 日志配置 ====================

def setup_logging(
    level: int = logging.INFO,
    log_file: Optional[str] = None,
    console_output: bool = True,
) -> logging.Logger:
    """
    配置结构化日志系统

    Args:
        level: 日志级别 (logging.INFO, logging.WARNING, etc.)
        log_file: 日志文件路径（默认为 backend/logs/app.log）
        console_output: 是否同时输出到控制台

    Returns:
        配置好的根 logger
    """
    log_path = log_file or str(LOG_FILE)

    # 获取根 logger
    root_logger = logging.getLogger()
    root_logger.setLevel(level)

    # 避免重复添加 handler
    if root_logger.handlers:
        return root_logger

    # JSON 格式化器
    json_formatter = JsonFormatter()

    # 文件 handler（按天轮转，保留30天）
    file_handler = TimedRotatingFileHandler(
        filename=log_path,
        when="midnight",
        interval=1,
        backupCount=30,
        encoding="utf-8",
    )
    file_handler.setLevel(level)
    file_handler.setFormatter(json_formatter)
    file_handler.suffix = "%Y-%m-%d"
    root_logger.addHandler(file_handler)

    # 控制台 handler（可选，使用简单格式）
    if console_output:
        console_formatter = logging.Formatter(
            "[%(asctime)s] %(levelname)-8s %(name)s - %(message)s",
            datefmt="%Y-%m-%d %H:%M:%S",
        )
        console_handler = logging.StreamHandler(sys.stdout)
        console_handler.setLevel(level)
        console_handler.setFormatter(console_formatter)
        root_logger.addHandler(console_handler)

    return root_logger


# ==================== 结构化日志辅助函数 ====================

def log_structured(
    level: str,
    action: str,
    message: str,
    user_id: str = "",
    details: Optional[Dict[str, Any]] = None,
    module: str = "app",
):
    """
    写入结构化日志

    Args:
        level: 日志级别 (INFO/WARNING/ERROR)
        action: 动作描述
        message: 日志消息
        user_id: 关联用户 ID
        details: 附加详情字典
        module: 模块名称
    """
    logger = logging.getLogger(module)
    log_func = {
        "INFO": logger.info,
        "WARNING": logger.warning,
        "ERROR": logger.error,
        "CRITICAL": logger.critical,
    }.get(level.upper(), logger.info)

    # Python logging extra 字段
    extra = {
        "user_id": user_id,
        "action": action,
        "details": details or {},
    }

    log_func(message, extra=extra)


def log_request(
    user_id: str = "",
    method: str = "",
    path: str = "",
    status_code: int = 200,
    duration_ms: float = 0,
    details: Optional[Dict[str, Any]] = None,
):
    """记录 HTTP 请求日志"""
    log_structured(
        level="INFO",
        action="http_request",
        message=f"{method} {path} -> {status_code} ({duration_ms:.0f}ms)",
        user_id=user_id,
        details={
            "method": method,
            "path": path,
            "status_code": status_code,
            "duration_ms": round(duration_ms, 2),
            **(details or {}),
        },
        module="app.access",
    )


def log_error(
    action: str,
    message: str,
    user_id: str = "",
    error: Optional[str] = None,
    details: Optional[Dict[str, Any]] = None,
):
    """记录错误日志"""
    log_structured(
        level="ERROR",
        action=action,
        message=message,
        user_id=user_id,
        details={
            "error": error,
            **(details or {}),
        },
        module="app.error",
    )


def log_business_event(
    action: str,
    message: str,
    user_id: str = "",
    details: Optional[Dict[str, Any]] = None,
):
    """记录业务事件日志"""
    log_structured(
        level="INFO",
        action=action,
        message=message,
        user_id=user_id,
        details=details,
        module="app.business",
    )


# ==================== 初始化 ====================

# 导入时自动配置日志（如果尚未配置）
if not logging.getLogger().handlers:
    setup_logging()
