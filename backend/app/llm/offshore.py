"""境外供应商停用。只报告变量名，绝不读取或记录值。"""

from __future__ import annotations

import logging
import os

logger = logging.getLogger(__name__)

# 文档 01 / 12：出现即忽略，不参与任何调用。
FORBIDDEN_ENV = ("FAL_KEY", "OPENROUTER_API_KEY")


def present_names(env: dict | None = None) -> list[str]:
    source = os.environ if env is None else env
    return [name for name in FORBIDDEN_ENV if (source.get(name) or "").strip()]


def warn_if_present(env: dict | None = None) -> list[str]:
    names = present_names(env)
    if names:
        logger.warning("offshore secrets ignored: %s", ", ".join(names))
    return names
