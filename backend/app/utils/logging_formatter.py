"""
请求感知的日志格式化器 — 在每条日志中注入 request_id
"""
import logging
from app.utils.request_id import get_request_id


class RequestFormatter(logging.Formatter):
    """在格式化日志时自动注入当前请求的 request_id"""

    def format(self, record):
        record.request_id = get_request_id()
        return super().format(record)


# 格式: [2026-03-18 17:00:00] [abc12345] [INFO] user=xxx GET /api/v1/chat 200 150ms
LOG_FORMAT = "[%(asctime)s] [%(request_id)s] [%(levelname)s] %(message)s"
DATE_FORMAT = "%Y-%m-%d %H:%M:%S"


def configure_logging(level: int = logging.INFO) -> None:
    """配置根 logger 使用 RequestFormatter"""
    import sys

    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(RequestFormatter(LOG_FORMAT, datefmt=DATE_FORMAT))

    root = logging.getLogger()
    root.handlers = [handler]
    root.setLevel(level)
