"""
LLM 调用配额管理
- Redis 存储当日已用量
- 免费用户: 10次/天 (可配置 RATE_LIMIT_AI_PER_DAY_FREE)
- 付费用户: 100次/天 (可配置 RATE_LIMIT_AI_PER_DAY_PAID)
- 超额返回 429
"""
import redis
import os
import logging
from datetime import datetime
from ..core.settings import settings

logger = logging.getLogger(__name__)


class LLMQuotaManager:
    def __init__(self):
        self._redis = None

    def _get_redis(self):
        if self._redis is None:
            try:
                self._redis = redis.from_url(settings.REDIS_URL, socket_connect_timeout=3)
            except Exception:
                pass
        return self._redis

    def check_quota(self, user_id: str, tier: str = "free") -> bool:
        """检查用户是否还有配额，返回 True=可用"""
        key = f"llm_quota:{datetime.now().strftime('%Y-%m-%d')}:{user_id}"
        limit = settings.RATE_LIMIT_AI_PER_DAY_PAID if tier == "paid" else settings.RATE_LIMIT_AI_PER_DAY_FREE
        r = self._get_redis()
        if r:
            try:
                count = r.incr(key)
                if count == 1:
                    r.expire(key, 86400)
                return count <= limit
            except Exception:
                return True  # Redis故障时放行
        return True

    def get_remaining(self, user_id: str, tier: str = "free") -> int:
        """获取用户当日剩余配额"""
        key = f"llm_quota:{datetime.now().strftime('%Y-%m-%d')}:{user_id}"
        limit = settings.RATE_LIMIT_AI_PER_DAY_PAID if tier == "paid" else settings.RATE_LIMIT_AI_PER_DAY_FREE
        r = self._get_redis()
        if r:
            try:
                count = int(r.get(key) or 0)
                return max(0, limit - count)
            except Exception:
                pass
        return limit


llm_quota = LLMQuotaManager()
