"""
顺时 AI Router - 核心路由逻辑
Model Router Core Logic

作者: Claw 🦅
日期: 2026-03-09
"""

import logging
from typing import Optional, List, Dict, Any
from .config import (
    MODEL_CONFIG,
    API_MODEL_MAP,
    USER_TIER_MODELS,
    COST_BUDGET,
    ModelTier,
    UserTier,
    RoutingContext,
    ModelSelectionResult,
)

logger = logging.getLogger(__name__)


class ModelRouter:
    """
    顺时 AI 模型路由器
    
    核心职责：
    1. 根据上下文选择最佳模型
    2. 处理降级逻辑
    3. 控制成本
    4. 支持灰度发布
    """
    
    def __init__(self):
        self.model_config = MODEL_CONFIG
        self.api_map = API_MODEL_MAP
        self.tier_models = USER_TIER_MODELS
    
    def select_model(self, context: RoutingContext) -> ModelSelectionResult:
        """
        选择最佳模型
        
        决策顺序：
        1. API 映射 (API → Model)
        2. Skill 映射 (Skill → Model)
        3. 用户等级过滤
        4. 复杂度判断
        5. 上下文长度判断
        6. 成本控制
        """
        logger.info(f"[ModelRouter] 路由请求: {context.api_path}, user_tier={context.user_tier}")
        
        # Step 1: 获取 API 配置
        api_config = self.api_map.get(context.api_path, {})
        
        # Step 2: Skill 优先级最高
        if context.skill_name and "skill_models" in api_config:
            model = api_config["skill_models"].get(
                context.skill_name, 
                api_config.get("default_model", "deepseek-v3.2")
            )
            return self._build_result(
                model, context, 
                reason=f"Skill触发: {context.skill_name}"
            )
        
        # Step 3: 根据用户等级选择
        allowed_models = self.tier_models.get(context.user_tier, self.tier_models[UserTier.FREE])
        
        # 默认模型
        default_model = api_config.get("default_model", "deepseek-v3.2")
        
        # 会员可升级模型
        if context.user_tier == UserTier.PREMIUM and api_config.get("premium_model"):
            if context.is_premium_feature:
                default_model = api_config["premium_model"]
        
        # Step 4: 复杂度判断
        complexity = api_config.get("complexity", "simple")
        model = self._select_by_complexity(default_model, complexity, allowed_models)
        
        # Step 5: 上下文长度判断
        if context.context_length > 40000:
            model = self._select_by_context_length(model, allowed_models)
        
        # Step 6: 成本控制
        model = self._apply_cost_control(model, allowed_models)
        
        return self._build_result(model, context, reason="综合决策")
    
    def _select_by_complexity(
        self, 
        default_model: str, 
        complexity: str,
        allowed_models: List[str]
    ) -> str:
        """根据复杂度选择模型"""
        complexity_upgrade = {
            "simple": 0,      # 保持默认
            "medium": 1,      # 升一级
            "high": 2,        # 升二级
        }
        
        tier_order = [
            "deepseek-v3.2",
            "minimax-m2", 
            "glm-4.6",
            "kimi-k2-thinking",
            "qwen3-235b",
        ]
        
        current_idx = next((i for i, m in enumerate(tier_order) if m == default_model), 0)
        upgrade_steps = complexity_upgrade.get(complexity, 0)
        
        new_idx = min(current_idx + upgrade_steps, len(tier_order) - 1)
        new_model = tier_order[new_idx]
        
        # 确保用户在允许列表中
        if new_model not in allowed_models:
            for m in tier_order[new_idx::-1]:
                if m in allowed_models:
                    return m
            return allowed_models[0]
        
        return new_model
    
    def _select_by_context_length(
        self, 
        current_model: str, 
        allowed_models: List[str]
    ) -> str:
        """根据上下文长度选择模型"""
        # 长上下文优先用 Kimi 或 Qwen
        long_context_models = ["kimi-k2-thinking", "qwen3-235b"]
        
        for model in long_context_models:
            if model in allowed_models:
                logger.info(f"[ModelRouter] 长上下文升级: {current_model} → {model}")
                return model
        
        return current_model
    
    def _apply_cost_control(
        self, 
        model: str, 
        allowed_models: List[str]
    ) -> str:
        """应用成本控制策略"""
        # 免费用户默认用低成本模型
        # 已经在用户等级过滤时处理
        return model
    
    def _build_result(
        self, 
        model: str, 
        context: RoutingContext,
        reason: str
    ) -> ModelSelectionResult:
        """构建选择结果"""
        config = self.model_config.get(model, {})
        
        # 计算预估成本
        estimated_cost = config.get("cost_per_1k_input", 0.001) * (len(context.prompt) / 1000)
        
        # 判断是否可缓存
        cacheable = self._is_cacheable(context)
        
        return ModelSelectionResult(
            selected_model=model,
            fallback_model=config.get("fallback", "minimax-m2"),
            reasoning=reason,
            tier=config.get("tier", ModelTier.DEFAULT),
            estimated_cost=estimated_cost,
            cacheable=cacheable,
        )
    
    def _is_cacheable(self, context: RoutingContext) -> bool:
        """判断是否可缓存"""
        # 简单判断：日常养生问题可缓存
        cacheable_skills = [
            "solar_term_guide",
            "food_tea_recommender",
            "exercise_recommender",
            "acupoint_guide",
        ]
        
        if context.skill_name in cacheable_skills:
            return True
        
        # 日常问题
        cacheable_patterns = [
            "今天适合",
            "春天养生",
            "冬天喝什么",
            "推荐一个",
        ]
        
        for pattern in cacheable_patterns:
            if pattern in context.prompt:
                return True
        
        return False
    
    def get_fallback_chain(self, model: str) -> List[str]:
        """获取降级链"""
        chain = [model]
        config = self.model_config.get(model, {})
        
        fallback = config.get("fallback")
        if fallback:
            chain.append(fallback)
            # 继续获取降级
            fallback_config = self.model_config.get(fallback, {})
            second_fallback = fallback_config.get("fallback")
            if second_fallback:
                chain.append(second_fallback)
        
        return chain


# ==================== 路由决策示例 ====================

def demo_routing():
    """演示路由决策"""
    router = ModelRouter()
    
    test_cases = [
        # 普通聊天 - 免费用户
        RoutingContext(
            user_id="user_001",
            user_tier=UserTier.FREE,
            api_path="/chat/send",
            prompt="今天适合吃什么",
            context_length=100,
        ),
        # 普通聊天 - 会员
        RoutingContext(
            user_id="user_002",
            user_tier=UserTier.PREMIUM,
            api_path="/chat/send",
            prompt="最近睡不好，帮我做30天调理计划",
            context_length=50000,
            is_premium_feature=True,
        ),
        # Skill 触发
        RoutingContext(
            user_id="user_003",
            user_tier=UserTier.PREMIUM,
            api_path="/skill/run",
            skill_name="solar_term_guide",
            prompt="今天节气养生建议",
            context_length=200,
        ),
        # 周报生成
        RoutingContext(
            user_id="user_004",
            user_tier=UserTier.PREMIUM,
            api_path="/weekly-report",
            prompt="生成本周健康报告",
            context_length=80000,
            is_premium_feature=True,
        ),
    ]
    
    print("=" * 60)
    print("顺时 AI Router 路由决策演示")
    print("=" * 60)
    
    for i, ctx in enumerate(test_cases, 1):
        result = router.select_model(ctx)
        print(f"\n[Case {i}] {ctx.api_path}")
        print(f"  用户等级: {ctx.user_tier}")
        print(f"  Skill: {ctx.skill_name or 'N/A'}")
        print(f"  选择模型: {result.selected_model}")
        print(f"  降级模型: {result.fallback_model}")
        print(f"  决策理由: {result.reasoning}")
        print(f"  预估成本: ${result.estimated_cost:.4f}")
        print(f"  可缓存: {result.cacheable}")


if __name__ == "__main__":
    demo_routing()
