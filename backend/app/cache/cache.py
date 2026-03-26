"""
顺时 AI Cache 系统
AI Cache Layer + Redis 支持

功能：
- 基于 prompt + skill + user_stage 的缓存
- 自动过期 (TTL 24小时)
- 缓存命中统计
- Redis 后端支持（不可用时自动回退到内存）

作者: Claw 🦅
日期: 2026-03-09 (原始), 2026-03-17 (Redis 升级)
"""

import hashlib
import json
import os
import threading
import logging
from typing import Optional, Any, Dict
from datetime import datetime, timedelta

logger = logging.getLogger(__name__)

# 尝试导入 Redis
try:
    import redis
    _REDIS_AVAILABLE = True
except ImportError:
    _REDIS_AVAILABLE = False
    logger.info("[Cache] redis-py 未安装，使用内存缓存")


# ============ 统一缓存接口 ============

class UnifiedCache:
    """
    统一缓存接口
    
    支持 Redis 后端 + 内存回退：
    - Redis 可用时：使用 Redis 作为主缓存
    - Redis 不可用时：自动回退到内存缓存
    
    接口：
    - get(key) -> Optional[str]
    - set(key, value, ttl) -> bool
    - delete(key) -> bool
    - exists(key) -> bool
    """
    
    def __init__(self, redis_url: Optional[str] = None):
        self._redis: Optional[Any] = None
        self._redis_connected = False
        self._memory: Dict[str, Dict[str, Any]] = {}
        self._lock = threading.Lock()
        
        redis_url = redis_url or os.getenv("REDIS_URL", "redis://localhost:6379/0")
        
        if _REDIS_AVAILABLE:
            try:
                self._redis = redis.from_url(
                    redis_url,
                    decode_responses=True,
                    socket_connect_timeout=3,
                    socket_timeout=3,
                )
                self._redis.ping()
                self._redis_connected = True
                logger.info(f"[Cache] Redis 连接成功: {redis_url}")
            except Exception as e:
                self._redis = None
                self._redis_connected = False
                logger.warning(f"[Cache] Redis 连接失败，回退到内存缓存: {e}")
    
    @property
    def backend(self) -> str:
        return "redis" if self._redis_connected else "memory"
    
    def get(self, key: str) -> Optional[str]:
        """获取缓存值"""
        if self._redis_connected:
            try:
                value = self._redis.get(key)
                if value is not None:
                    return value
            except Exception as e:
                logger.warning(f"[Cache] Redis get 失败，回退到内存: {e}")
        
        # 内存回退
        with self._lock:
            entry = self._memory.get(key)
            if entry:
                if datetime.now() < entry["expires_at"]:
                    return entry["value"]
                else:
                    del self._memory[key]
        return None
    
    def set(self, key: str, value: str, ttl: int = 86400) -> bool:
        """设置缓存值 (ttl 单位: 秒)"""
        if self._redis_connected:
            try:
                self._redis.setex(key, ttl, value)
                return True
            except Exception as e:
                logger.warning(f"[Cache] Redis set 失败，回退到内存: {e}")
        
        # 内存回退
        with self._lock:
            self._memory[key] = {
                "value": value,
                "expires_at": datetime.now() + timedelta(seconds=ttl),
            }
        return True
    
    def delete(self, key: str) -> bool:
        """删除缓存值"""
        if self._redis_connected:
            try:
                self._redis.delete(key)
            except Exception as e:
                logger.warning(f"[Cache] Redis delete 失败: {e}")
        
        with self._lock:
            self._memory.pop(key, None)
        return True
    
    def exists(self, key: str) -> bool:
        """检查 key 是否存在"""
        if self._redis_connected:
            try:
                return bool(self._redis.exists(key))
            except Exception as e:
                logger.warning(f"[Cache] Redis exists 失败: {e}")
        
        with self._lock:
            entry = self._memory.get(key)
            if entry:
                if datetime.now() < entry["expires_at"]:
                    return True
                else:
                    del self._memory[key]
        return False
    
    def get_many(self, keys: list) -> Dict[str, Optional[str]]:
        """批量获取"""
        result = {}
        if self._redis_connected:
            try:
                values = self._redis.mget(keys)
                for k, v in zip(keys, values):
                    result[k] = v
                return result
            except Exception as e:
                logger.warning(f"[Cache] Redis mget 失败: {e}")
        
        for k in keys:
            result[k] = self.get(k)
        return result
    
    def set_many(self, mapping: Dict[str, str], ttl: int = 86400) -> bool:
        """批量设置"""
        if self._redis_connected:
            try:
                pipe = self._redis.pipeline()
                for k, v in mapping.items():
                    pipe.setex(k, ttl, v)
                pipe.execute()
                return True
            except Exception as e:
                logger.warning(f"[Cache] Redis mset 失败: {e}")
        
        for k, v in mapping.items():
            self.set(k, v, ttl)
        return True
    
    def cleanup_expired(self) -> int:
        """清理过期内存缓存（Redis 自动处理）"""
        with self._lock:
            now = datetime.now()
            expired_keys = [
                k for k, v in self._memory.items()
                if now >= v["expires_at"]
            ]
            for key in expired_keys:
                del self._memory[key]
            return len(expired_keys)
    
    def clear(self) -> bool:
        """清空所有缓存"""
        if self._redis_connected:
            try:
                self._redis.flushdb()
            except Exception as e:
                logger.warning(f"[Cache] Redis flushdb 失败: {e}")
        
        with self._lock:
            count = len(self._memory)
            self._memory.clear()
            return count
    
    def info(self) -> Dict[str, Any]:
        """缓存信息"""
        info = {"backend": self.backend}
        
        if self._redis_connected and self._redis:
            try:
                info["redis"] = self._redis.info(section="memory")
            except Exception:
                pass
        
        info["memory_entries"] = len(self._memory)
        return info


# ============ AI 缓存层（向后兼容） ============

class AICache:
    """
    顺时 AI 缓存层
    
    缓存策略：
    - Key: hash(prompt + skill + user_stage)
    - TTL: 24 小时
    - 适用场景: 重复性高的问题
    - 后端: UnifiedCache (Redis or memory)
    """
    
    def __init__(self, ttl_hours: int = 24, redis_url: Optional[str] = None):
        self.ttl_seconds = ttl_hours * 3600
        self._cache = UnifiedCache(redis_url=redis_url)
        self._stats = {
            "hits": 0,
            "misses": 0,
            "saves": 0,
        }
    
    def _generate_key(
        self, 
        prompt: str, 
        skill: Optional[str] = None,
        user_stage: Optional[str] = None,
        model: Optional[str] = None
    ) -> str:
        """生成缓存 Key"""
        components = [prompt]
        if skill:
            components.append(skill)
        if user_stage:
            components.append(user_stage)
        if model:
            components.append(model)
        
        key_string = "|".join(components)
        return f"ai_cache:{hashlib.sha256(key_string.encode()).hexdigest()[:16]}"
    
    def get(
        self, 
        prompt: str, 
        skill: Optional[str] = None,
        user_stage: Optional[str] = None,
        model: Optional[str] = None
    ) -> Optional[str]:
        """获取缓存"""
        key = self._generate_key(prompt, skill, user_stage, model)
        
        value = self._cache.get(key)
        if value is not None:
            self._stats["hits"] += 1
            logger.info(f"[AICache] 命中缓存: {key.split(':')[-1]}... (backend={self._cache.backend})")
            return value
        
        self._stats["misses"] += 1
        return None
    
    def set(
        self, 
        prompt: str, 
        response: str,
        skill: Optional[str] = None,
        user_stage: Optional[str] = None,
        model: Optional[str] = None
    ) -> None:
        """设置缓存"""
        key = self._generate_key(prompt, skill, user_stage, model)
        
        self._cache.set(key, response, ttl=self.ttl_seconds)
        self._stats["saves"] += 1
        logger.info(f"[AICache] 保存缓存: {key.split(':')[-1]}..., TTL={self.ttl_seconds}s (backend={self._cache.backend})")
    
    def invalidate(self, skill: Optional[str] = None) -> int:
        """
        清除缓存
        
        Note: 带 skill 前缀的批量删除在 Redis 中需要 scan 匹配，
        这里简化为清理所有过期缓存。
        """
        return self._cache.cleanup_expired()
    
    def get_stats(self) -> Dict[str, Any]:
        """获取缓存统计"""
        total = self._stats["hits"] + self._stats["misses"]
        hit_rate = self._stats["hits"] / total if total > 0 else 0
        
        return {
            "hits": self._stats["hits"],
            "misses": self._stats["misses"],
            "saves": self._stats["saves"],
            "hit_rate": f"{hit_rate:.1%}",
            "backend": self._cache.backend,
        }
    
    def cleanup_expired(self) -> int:
        """清理过期缓存"""
        count = self._cache.cleanup_expired()
        if count:
            logger.info(f"[AICache] 清理过期缓存: {count} 条")
        return count
    
    @property
    def backend(self) -> str:
        return self._cache.backend
    
    @property
    def cache_info(self) -> Dict[str, Any]:
        return self._cache.info()


# ==================== 全局缓存实例 ====================

ai_cache = AICache(ttl_hours=24)


# ==================== 缓存使用示例 ====================

def demo_cache():
    """演示缓存使用"""
    cache = AICache(ttl_hours=1)
    
    prompts = [
        "春天适合吃什么养生",
        "今天适合吃什么",
        "春天适合吃什么养生",  # 重复
        "失眠怎么办",
    ]
    
    print("=" * 50)
    print("顺时 AI Cache 演示")
    print(f"缓存后端: {cache.backend}")
    print("=" * 50)
    
    for prompt in prompts:
        cached = cache.get(prompt, skill="food_tea_recommender")
        
        if cached:
            print(f"\n[缓存命中] {prompt}")
            print(f"  返回: {cached}")
        else:
            print(f"\n[缓存未命中] {prompt}")
            response = f"关于「{prompt}」的建议..."
            cache.set(prompt, response, skill="food_tea_recommender")
            print(f"  生成新响应并缓存")
    
    print("\n" + "=" * 50)
    print("缓存统计:", cache.get_stats())
    print("缓存信息:", cache.cache_info)


if __name__ == "__main__":
    demo_cache()
