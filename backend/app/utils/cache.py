"""
顺时 ShunShi — Redis 缓存工具层
提供统一的缓存接口，Redis 不可用时优雅降级。
"""
import json
import logging
import hashlib
from typing import Optional, Any
from functools import wraps

from app.db.database import get_redis

logger = logging.getLogger(__name__)

# ==================== 缓存前缀 ====================
PREFIX = "shunshi:"

# TTL 常量（秒）
TTL_SHORT = 60          # 1 分钟
TTL_MEDIUM = 300        # 5 分钟
TTL_LONG = 3600         # 1 小时
TTL_DAY = 86400         # 1 天
TTL_WEEK = 604800       # 1 周


def _key(namespace: str, key: str) -> str:
    """生成带前缀的缓存 key"""
    return f"{PREFIX}{namespace}:{key}"


def cache_get(namespace: str, key: str) -> Optional[Any]:
    """从缓存读取（反序列化 JSON）"""
    r = get_redis()
    if r is None:
        return None
    try:
        val = r.get(_key(namespace, key))
        return json.loads(val) if val else None
    except Exception as e:
        logger.debug("cache_get error: %s", e)
        return None


def cache_set(namespace: str, key: str, value: Any, ttl: int = TTL_MEDIUM) -> bool:
    """写入缓存（序列化为 JSON）"""
    r = get_redis()
    if r is None:
        return False
    try:
        r.setex(_key(namespace, key), ttl, json.dumps(value, ensure_ascii=False, default=str))
        return True
    except Exception as e:
        logger.debug("cache_set error: %s", e)
        return False


def cache_delete(namespace: str, key: str) -> bool:
    """删除缓存"""
    r = get_redis()
    if r is None:
        return False
    try:
        r.delete(_key(namespace, key))
        return True
    except Exception as e:
        logger.debug("cache_delete error: %s", e)
        return False


def cache_clear_namespace(namespace: str) -> int:
    """清除指定命名空间的所有缓存"""
    r = get_redis()
    if r is None:
        return 0
    try:
        pattern = f"{PREFIX}{namespace}:*"
        keys = list(r.scan_iter(match=pattern, count=100))
        if keys:
            return r.delete(*keys)
        return 0
    except Exception as e:
        logger.debug("cache_clear error: %s", e)
        return 0


# ==================== 装饰器 ====================
def cached(namespace: str, ttl: int = TTL_MEDIUM, key_builder=None):
    """
    缓存装饰器 — 用于 FastAPI 路由函数。

    使用方法:
        @router.get("/items")
        @cached("items", ttl=300)
        async def list_items(page: int = 1):
            ...

    key_builder: 自定义 key 生成函数，接受 (*args, **kwargs) 返回 str
    """
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            # 构建 cache key
            if key_builder:
                cache_key = key_builder(*args, **kwargs)
            else:
                # 默认：函数名 + 参数 hash
                raw = f"{func.__name__}:{json.dumps(kwargs, sort_keys=True, default=str)}"
                cache_key = hashlib.md5(raw.encode()).hexdigest()

            # 尝试命中缓存
            result = cache_get(namespace, cache_key)
            if result is not None:
                return result

            # 未命中 → 执行函数
            result = await func(*args, **kwargs)

            # 写入缓存
            cache_set(namespace, cache_key, result, ttl=ttl)
            return result

        return wrapper
    return decorator
