"""
顺时 并行执行器 + 结果合并器 + 智能编排决策
Parallel Skill Execution, Result Merging, and Orchestration Planning

功能:
1. ParallelSkillExecutor - 多 Skill 并行执行 (asyncio.gather)
2. SkillResultMerger - 多结果智能合并 (去重/截断/排序)
3. SkillOrchestratorEnhanced - 执行计划编排 (并行批次/串行批次)

作者: Claw 🦅
日期: 2026-03-18
"""

from __future__ import annotations

import asyncio
import time
import hashlib
import logging
from typing import List, Dict, Any, Tuple, Optional

from .executor import (
    SkillInput,
    SkillOutput,
    SkillExecutor,
    get_fallback_response,
)

logger = logging.getLogger(__name__)


# ==================== Skill 优先级映射 ====================

# Skill 类别优先级，数字越小越优先
SKILL_CATEGORY_PRIORITY: Dict[str, int] = {
    "constitution": 0,
    "diet": 1,
    "tea": 2,
    "acupoint": 3,
    "exercise": 4,
    "sleep": 5,
    "emotion": 6,
    "season": 7,
    "daily_plan": 8,
    "lifestyle": 9,
    "follow_up": 10,
    "family": 11,
    "safety": -1,   # 安全永远最优先
    "meta": 12,
    "reflection": 13,
}


# ==================== 并行执行器 ====================

class ParallelSkillExecutor:
    """多 Skill 并行执行器"""

    def __init__(self, executor: Optional[SkillExecutor] = None):
        self.executor = executor or SkillExecutor(llm_client=None)

    async def execute_parallel(
        self,
        skills: List[Tuple[str, dict]],  # [(skill_name, input_data), ...]
        user_id: str = None,
        timeout_per_skill: float = 25.0,
        max_skills: int = 3,
    ) -> List[Dict[str, Any]]:
        """
        并行执行多个 Skill。

        规则:
        - 最多 max_skills 个 Skill 并行
        - 每个 Skill 独立超时
        - 失败的 Skill 返回 fallback 模板
        - 返回按执行时间排序的结果列表

        Args:
            skills: [(skill_name, {input_key: value, ...}), ...]
            user_id: 用户 ID
            timeout_per_skill: 单个 Skill 超时(秒)
            max_skills: 最大并行数量

        Returns:
            [
                {
                    "skill": str,
                    "status": "success" | "timeout" | "fallback" | "error",
                    "data": SkillOutput,
                    "latency_ms": float,
                },
                ...
            ]
        """
        if not skills:
            return []

        # 截断到最大并行数
        if len(skills) > max_skills:
            logger.warning(
                f"[ParallelExecutor] 请求 {len(skills)} 个 Skill，"
                f"截断为 {max_skills}"
            )
            skills = skills[:max_skills]

        tasks = [
            self._execute_one(name, data, user_id, timeout_per_skill)
            for name, data in skills
        ]

        results = await asyncio.gather(*tasks, return_exceptions=True)

        processed = []
        for i, result in enumerate(results):
            skill_name = skills[i][0]
            if isinstance(result, Exception):
                processed.append({
                    "skill": skill_name,
                    "status": "fallback",
                    "data": get_fallback_response(skill_name),
                    "latency_ms": timeout_per_skill * 1000,
                    "error": str(result),
                })
            else:
                processed.append(result)

        # 按延迟排序(快的在前)
        return sorted(processed, key=lambda x: x.get("latency_ms", 0))

    async def _execute_one(
        self,
        skill_name: str,
        input_data: dict,
        user_id: Optional[str],
        timeout: float,
    ) -> Dict[str, Any]:
        """执行单个 Skill（带独立超时）"""
        start = time.perf_counter()

        try:
            skill_input = SkillInput(
                skill_name=skill_name,
                user_id=user_id or "anonymous",
                context=input_data,
            )

            result: SkillOutput = await asyncio.wait_for(
                self.executor.execute_with_fallback(skill_input),
                timeout=timeout,
            )

            latency_ms = (time.perf_counter() - start) * 1000
            status = "success"
            if hasattr(result, "data") and isinstance(result.data, dict):
                if result.data.get("fallback"):
                    status = "fallback"

            return {
                "skill": skill_name,
                "status": status,
                "data": result,
                "latency_ms": latency_ms,
            }

        except asyncio.TimeoutError:
            return {
                "skill": skill_name,
                "status": "timeout",
                "data": get_fallback_response(skill_name),
                "latency_ms": timeout * 1000,
            }
        except Exception as e:
            return {
                "skill": skill_name,
                "status": "error",
                "data": get_fallback_response(skill_name),
                "latency_ms": (time.perf_counter() - start) * 1000,
                "error": str(e),
            }


# ==================== 结果合并器 ====================

class SkillResultMerger:
    """合并多个 Skill 的结果"""

    # 最大合并长度（字符）
    MAX_MERGED_LENGTH = 1000

    def merge_for_chat(
        self,
        results: List[Dict[str, Any]],
        user_message: str = "",
    ) -> str:
        """
        将多个 Skill 结果合并为一段完整的 AI 回复参考。

        策略:
        1. 如果只有 1 个结果，直接使用
        2. 如果有多个，按优先级排序后拼接
        3. 去除重复内容
        4. 控制总长度(不超过 MAX_MERGED_LENGTH 字)

        Args:
            results: execute_parallel 的返回值
            user_message: 用户原始消息(可用于上下文)

        Returns:
            合并后的文本
        """
        if not results:
            return ""

        if len(results) == 1:
            text = self._extract_text(results[0])
            if len(text) > self.MAX_MERGED_LENGTH:
                text = text[: self.MAX_MERGED_LENGTH - 50] + "\n\n...（更多建议请继续提问）"
            return text

        # 按类别优先级排序
        sorted_results = sorted(
            results,
            key=lambda r: SKILL_CATEGORY_PRIORITY.get(
                self._get_category(r), 99
            ),
        )

        # 提取文本，去重
        seen_texts = set()
        merged_parts = []

        for r in sorted_results:
            text = self._extract_text(r)
            if not text:
                continue
            # 基于文本哈希去重
            text_hash = hashlib.md5(text.encode()).hexdigest()[:12]
            if text_hash not in seen_texts:
                seen_texts.add(text_hash)
                merged_parts.append(text)

        combined = "\n\n".join(merged_parts)

        # 截断
        if len(combined) > self.MAX_MERGED_LENGTH:
            combined = combined[: self.MAX_MERGED_LENGTH - 50] + "\n\n...（更多建议请继续提问）"

        return combined

    def merge_content_cards(
        self,
        results: List[Dict[str, Any]],
    ) -> List[Dict[str, Any]]:
        """
        合并多个 Skill 的 content_cards，去重。

        去重基于 (title + summary) 的哈希。
        """
        seen_hashes = set()
        cards = []

        for r in results:
            card_list = self._extract_content_cards(r)
            for card in card_list:
                key = (card.get("title", ""), card.get("summary", ""))
                h = hashlib.md5(str(key).encode()).hexdigest()[:12]
                if h not in seen_hashes:
                    seen_hashes.add(h)
                    card["_source_skill"] = r.get("skill", "unknown")
                    cards.append(card)

        return cards

    def merge_suggestions(
        self,
        results: List[Dict[str, Any]],
        max_suggestions: int = 3,
    ) -> List[str]:
        """
        合并多个 Skill 的建议，限制数量。

        优先选择成功 Skill 的建议，按优先级排序。
        """
        # 按优先级排序结果
        sorted_results = sorted(
            results,
            key=lambda r: (
                0 if r.get("status") == "success" else 1,
                SKILL_CATEGORY_PRIORITY.get(self._get_category(r), 99),
            ),
        )

        seen = set()
        suggestions = []

        for r in sorted_results:
            sug_list = self._extract_suggestions(r)
            for s in sug_list:
                if s not in seen:
                    seen.add(s)
                    suggestions.append(s)
                    if len(suggestions) >= max_suggestions:
                        return suggestions

        return suggestions

    # ---------- 内部方法 ----------

    def _extract_text(self, result: Dict[str, Any]) -> str:
        """从结果中提取文本"""
        data = result.get("data")
        if isinstance(data, str):
            return data
        if isinstance(data, SkillOutput):
            return data.content
        if isinstance(data, dict):
            return data.get("text", "")
        return ""

    def _get_category(self, result: Dict[str, Any]) -> str:
        """从结果中提取类别名"""
        skill_name = result.get("skill", "")
        # 尝试从 skill_name 推断 category
        for cat_key in SKILL_CATEGORY_PRIORITY:
            if cat_key in skill_name:
                return cat_key
        # 尝试从 SkillOutput 中获取
        data = result.get("data")
        if isinstance(data, SkillOutput) and hasattr(data, "data"):
            d = data.data
            if isinstance(d, dict) and "category" in d:
                return d["category"]
        return "lifestyle"

    def _extract_content_cards(
        self, result: Dict[str, Any]
    ) -> List[Dict[str, Any]]:
        """从结果中提取 content_cards"""
        data = result.get("data")
        if isinstance(data, SkillOutput) and hasattr(data, "data"):
            d = data.data
            if isinstance(d, dict):
                return d.get("content_cards", [])
        if isinstance(data, dict):
            return data.get("content_cards", [])
        return []

    def _extract_suggestions(self, result: Dict[str, Any]) -> List[str]:
        """从结果中提取 suggestions"""
        data = result.get("data")
        if isinstance(data, SkillOutput) and hasattr(data, "followup_suggestions"):
            return data.followup_suggestions or []
        if isinstance(data, SkillOutput) and hasattr(data, "data"):
            d = data.data
            if isinstance(d, dict):
                return d.get("suggestions", [])
        if isinstance(data, dict):
            return data.get("suggestions", [])
        return []


# ==================== 智能编排决策 ====================

class SkillOrchestratorEnhanced:
    """
    增强编排器：决定哪些 Skill 可以并行，哪些必须串行。

    使用方式:
        planner = SkillOrchestratorEnhanced()
        plan = planner.plan_execution(["diet", "tea", "sleep"])
        # => [["diet", "tea"], ["sleep"]]  (diet+tea 并行，sleep 串行)
    """

    # 可以并行的 Skill 组合
    PARALLEL_GROUPS: List[frozenset] = [
        frozenset(["diet", "tea", "acupoint", "food_recommend", "tea_recommend", "acupressure_routine"]),
        frozenset(["exercise", "sleep", "sleep_winddown", "office_micro_break"]),
        frozenset(["emotion", "mood_support"]),
        frozenset(["constitution", "body_constitution"]),
    ]

    # 依赖关系：key 必须在 value 之前执行
    DEPENDENCIES: Dict[str, List[str]] = {
        "diet": ["constitution"],
        "food_recommend": ["body_constitution", "constitution"],
        "tea": ["constitution"],
        "tea_recommend": ["body_constitution", "constitution"],
        "acupoint": ["constitution"],
        "acupressure_routine": ["body_constitution", "constitution"],
    }

    def plan_execution(self, intent_skills: List[str]) -> List[List[str]]:
        """
        根据Skill组合决定执行计划。

        算法:
        1. 识别依赖关系，将依赖的 Skill 放在前面
        2. 剩余无依赖的 Skill 按 PARALLEL_GROUPS 分组并行
        3. 不在任何并行组中的 Skill 单独一批

        Args:
            intent_skills: 需要执行的 Skill 名称列表

        Returns:
            [[并行批次1], [并行批次2], ...]
            例如: [["diet", "tea"], ["sleep"]]
        """
        if not intent_skills:
            return []

        skill_set = set(intent_skills)
        remaining = list(intent_skills)
        plan: List[List[str]] = []

        # Step 1: 提取依赖 Skill，确保先执行
        dep_batch = set()
        for skill in remaining:
            deps = self.DEPENDENCIES.get(skill, [])
            for dep in deps:
                if dep in skill_set and dep not in dep_batch and dep not in remaining:
                    # 依赖不在请求列表中，跳过
                    pass
                elif dep in skill_set and dep in remaining and dep != skill:
                    dep_batch.add(dep)

        if dep_batch:
            plan.append(sorted(dep_batch))
            remaining = [s for s in remaining if s not in dep_batch]

        # Step 2: 对剩余 Skill 按 PARALLEL_GROUPS 分组
        grouped: List[set] = []
        ungrouped: List[str] = []

        for skill in remaining:
            placed = False
            for group in self.PARALLEL_GROUPS:
                # 检查 skill 是否在这个并行组中
                if skill in group or any(skill in g for g in [group]):
                    # 找到已有的对应批次
                    found_batch = None
                    for g in grouped:
                        if g & group:
                            found_batch = g
                            break
                    if found_batch is not None:
                        found_batch.add(skill)
                    else:
                        grouped.append({skill})
                    placed = True
                    break
            if not placed:
                ungrouped.append(skill)

        # Step 3: 将分组和未分组的按顺序加入计划
        for group in grouped:
            batch = sorted(group)
            if batch not in plan:
                plan.append(batch)

        # 未分组的每个 Skill 独立一批（串行）
        for skill in ungrouped:
            if skill not in [s for batch in plan for s in batch]:
                plan.append([skill])

        return plan if plan else [remaining]

    def can_parallel(self, skill_a: str, skill_b: str) -> bool:
        """判断两个 Skill 是否可以并行执行"""
        # 有依赖关系的不能并行
        deps_a = self.DEPENDENCIES.get(skill_a, [])
        deps_b = self.DEPENDENCIES.get(skill_b, [])
        if skill_a in deps_b or skill_b in deps_a:
            return False

        # 在同一个 PARALLEL_GROUP 中的可以并行
        for group in self.PARALLEL_GROUPS:
            if skill_a in group and skill_b in group:
                return True

        return False
