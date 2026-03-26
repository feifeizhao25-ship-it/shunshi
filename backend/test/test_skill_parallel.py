"""
Skill 并行执行 + 结果合并 + 编排决策 测试

覆盖:
- ParallelSkillExecutor: 并行执行、超时、失败隔离、截断
- SkillResultMerger: 文本合并、卡片去重、建议限制、长度截断
- SkillOrchestratorEnhanced: 执行计划编排、依赖排序、并行判断

运行: pytest test/test_skill_parallel.py -v
"""

import pytest
import asyncio
import time
from unittest.mock import AsyncMock, MagicMock, patch

from app.skills.parallel_executor import (
    ParallelSkillExecutor,
    SkillResultMerger,
    SkillOrchestratorEnhanced,
    SKILL_CATEGORY_PRIORITY,
)
from app.skills.executor import (
    SkillExecutor,
    SkillInput,
    SkillOutput,
    get_fallback_response,
)


# ==================== Helpers ====================

def make_skill_output(
    skill_name: str = "sleep_winddown",
    content: str = "测试回复内容",
    suggestions: list = None,
    content_cards: list = None,
    fallback: bool = False,
) -> SkillOutput:
    """快速构造 SkillOutput"""
    data = {"input": {}, "fallback": fallback}
    if content_cards:
        data["content_cards"] = content_cards
    if suggestions:
        data["suggestions"] = suggestions
    return SkillOutput(
        skill_name=skill_name,
        content=content,
        data=data,
        model="test-model",
        followup_suggestions=suggestions or [],
    )


def make_parallel_result(
    skill: str = "diet",
    status: str = "success",
    text: str = "饮食建议",
    latency_ms: float = 100.0,
    suggestions: list = None,
    content_cards: list = None,
) -> dict:
    """快速构造并行执行结果"""
    output = make_skill_output(
        skill_name=skill,
        content=text,
        suggestions=suggestions,
        content_cards=content_cards,
        fallback=(status == "fallback"),
    )
    return {
        "skill": skill,
        "status": status,
        "data": output,
        "latency_ms": latency_ms,
    }


# ==================== Fixtures ====================

@pytest.fixture
def executor():
    """创建无 LLM 的 SkillExecutor"""
    return SkillExecutor(llm_client=None)


@pytest.fixture
def parallel_executor(executor):
    return ParallelSkillExecutor(executor=executor)


@pytest.fixture
def merger():
    return SkillResultMerger()


@pytest.fixture
def planner():
    return SkillOrchestratorEnhanced()


# ==================== ParallelSkillExecutor Tests ====================

class TestParallelExecution:

    @pytest.mark.asyncio
    async def test_two_skills_parallel(self, parallel_executor):
        """两个 Skill 应该并行执行"""
        results = await parallel_executor.execute_parallel(
            skills=[
                ("sleep_winddown", {"sleep_quality": "poor"}),
                ("food_recommend", {"constitution": "气虚"}),
            ],
            user_id="test_user",
            timeout_per_skill=10.0,
        )

        assert len(results) == 2
        # 结果应按延迟排序
        assert results[0]["latency_ms"] <= results[1]["latency_ms"]
        # 每个 Skill 应有结果
        for r in results:
            assert "skill" in r
            assert "status" in r
            assert "data" in r
            assert "latency_ms" in r

    @pytest.mark.asyncio
    async def test_three_skills_parallel(self, parallel_executor):
        """三个 Skill 全部并行执行"""
        results = await parallel_executor.execute_parallel(
            skills=[
                ("sleep_winddown", {}),
                ("food_recommend", {}),
                ("tea_recommend", {}),
            ],
            timeout_per_skill=10.0,
        )

        assert len(results) == 3
        # 全部应成功（有 fallback/mock）
        statuses = {r["status"] for r in results}
        assert statuses.issubset({"success", "fallback"})

    @pytest.mark.asyncio
    async def test_max_three_skills(self, parallel_executor):
        """超过 max_skills 的请求应被截断"""
        skills = [
            ("sleep_winddown", {}),
            ("food_recommend", {}),
            ("tea_recommend", {}),
            ("daily_rhythm_plan", {}),
            ("mood_support", {}),
        ]
        results = await parallel_executor.execute_parallel(
            skills=skills,
            max_skills=3,
            timeout_per_skill=10.0,
        )

        # 只执行 3 个
        assert len(results) == 3

    @pytest.mark.asyncio
    async def test_timeout_fallback(self, executor):
        """超时应返回 fallback"""
        # 构造一个永远不完成的 mock
        async def hanging_execute(skill_input):
            await asyncio.sleep(100)  # 永远不会完成
            return make_skill_output("sleep_winddown")

        pe = ParallelSkillExecutor(executor=executor)
        pe.executor.execute_with_fallback = hanging_execute

        results = await pe.execute_parallel(
            skills=[("sleep_winddown", {})],
            timeout_per_skill=0.5,
        )

        assert len(results) == 1
        assert results[0]["status"] == "timeout"
        assert results[0]["data"]  # 应有 fallback 文本

    @pytest.mark.asyncio
    async def test_one_fails_others_continue(self, executor):
        """一个 Skill 失败不应影响其他 Skill"""
        call_count = {"n": 0}

        async def selective_execute(skill_input):
            call_count["n"] += 1
            if skill_input.skill_name == "food_recommend":
                raise RuntimeError("模拟失败")
            return make_skill_output(skill_input.skill_name)

        pe = ParallelSkillExecutor(executor=executor)
        pe.executor.execute_with_fallback = selective_execute

        results = await pe.execute_parallel(
            skills=[
                ("food_recommend", {}),
                ("tea_recommend", {}),
                ("sleep_winddown", {}),
            ],
            timeout_per_skill=10.0,
        )

        # 3 个都应该有结果
        assert len(results) == 3
        # food_recommend 应该是 error（异常被捕获后标记为 error）
        food_result = next(r for r in results if r["skill"] == "food_recommend")
        assert food_result["status"] == "error"
        # 其他应该成功
        other_statuses = {
            r["status"] for r in results if r["skill"] != "food_recommend"
        }
        assert "fallback" not in other_statuses

    @pytest.mark.asyncio
    async def test_empty_skills(self, parallel_executor):
        """空列表应返回空结果"""
        results = await parallel_executor.execute_parallel([])
        assert results == []

    @pytest.mark.asyncio
    async def test_results_sorted_by_latency(self, parallel_executor):
        """结果应按延迟升序排列"""
        results = await parallel_executor.execute_parallel(
            skills=[
                ("sleep_winddown", {}),
                ("tea_recommend", {}),
            ],
            timeout_per_skill=10.0,
        )

        latencies = [r["latency_ms"] for r in results]
        assert latencies == sorted(latencies)


# ==================== SkillResultMerger Tests ====================

class TestResultMerger:

    def test_merge_single_result(self, merger):
        """单个结果应直接使用其文本"""
        results = [make_parallel_result(skill="diet", text="多吃蔬菜水果")]
        merged = merger.merge_for_chat(results)
        assert "多吃蔬菜水果" in merged

    def test_merge_multiple_dedup(self, merger):
        """多个结果应去重拼接"""
        results = [
            make_parallel_result(skill="diet", text="多吃蔬菜水果", latency_ms=100),
            make_parallel_result(skill="tea", text="春季宜喝花茶", latency_ms=200),
            make_parallel_result(skill="diet", text="多吃蔬菜水果", latency_ms=50),
        ]
        merged = merger.merge_for_chat(results)
        # diet 的文本应只出现一次
        assert merged.count("多吃蔬菜水果") == 1
        assert "春季宜喝花茶" in merged

    def test_merge_content_cards(self, merger):
        """合并 content_cards 应去重"""
        card_a = {"title": "养生茶", "summary": "枸杞菊花茶明目"}
        card_b = {"title": "养生茶", "summary": "枸杞菊花茶明目"}  # 重复
        card_c = {"title": "穴位按摩", "summary": "合谷穴缓解头痛"}

        results = [
            make_parallel_result(skill="tea", content_cards=[card_a, card_b]),
            make_parallel_result(skill="acupoint", content_cards=[card_c]),
        ]

        cards = merger.merge_content_cards(results)
        titles = [c["title"] for c in cards]
        # 重复的养生茶应只出现一次
        assert titles.count("养生茶") == 1
        assert "穴位按摩" in titles
        assert len(cards) == 2

    def test_merge_suggestions_limit(self, merger):
        """合并建议应限制数量"""
        results = [
            make_parallel_result(
                skill="diet",
                suggestions=["建议1", "建议2", "建议3"],
                latency_ms=100,
            ),
            make_parallel_result(
                skill="tea",
                suggestions=["建议4", "建议5"],
                latency_ms=200,
            ),
        ]

        sug = merger.merge_suggestions(results, max_suggestions=3)
        assert len(sug) == 3

    def test_long_result_truncated(self, merger):
        """超长结果应被截断"""
        long_text = "这是一段非常长的文本。" * 200  # ~3200 字
        results = [
            make_parallel_result(skill="diet", text=long_text, latency_ms=100),
        ]
        merged = merger.merge_for_chat(results)
        # 不应超过 MAX_MERGED_LENGTH
        assert len(merged) <= 1000

    def test_merge_fallback_text(self, merger):
        """fallback 状态的结果，data 为字符串时也能正确提取"""
        results = [
            {
                "skill": "diet",
                "status": "fallback",
                "data": "关于饮食调养，建议你注意荤素搭配",
                "latency_ms": 100,
            }
        ]
        merged = merger.merge_for_chat(results)
        assert "荤素搭配" in merged

    def test_merge_empty_results(self, merger):
        """空结果应返回空字符串"""
        assert merger.merge_for_chat([]) == ""
        assert merger.merge_content_cards([]) == []
        assert merger.merge_suggestions([]) == []

    def test_merge_suggestions_prioritize_success(self, merger):
        """成功的 Skill 建议应优先于 fallback"""
        results = [
            make_parallel_result(
                skill="diet", status="fallback",
                suggestions=["fallback建议"],
                latency_ms=100,
            ),
            make_parallel_result(
                skill="tea", status="success",
                suggestions=["成功建议1", "成功建议2"],
                latency_ms=50,
            ),
        ]

        sug = merger.merge_suggestions(results, max_suggestions=2)
        # 成功的建议应排前面
        assert sug[0] == "成功建议1"

    def test_merge_content_cards_source_skill(self, merger):
        """合并的卡片应包含来源 Skill 信息"""
        card = {"title": "茶饮", "summary": "菊花茶"}
        results = [make_parallel_result(skill="tea", content_cards=[card])]

        cards = merger.merge_content_cards(results)
        assert len(cards) == 1
        assert cards[0]["_source_skill"] == "tea"


# ==================== ExecutionPlanning Tests ====================

class TestExecutionPlanning:

    def test_diet_tea_parallel(self, planner):
        """diet + tea 应在同一并行批次"""
        plan = planner.plan_execution(["diet", "tea"])
        # 应只有一个批次（diet 和 tea 并行）
        assert len(plan) == 1
        assert "diet" in plan[0] and "tea" in plan[0]

    def test_exercise_sleep_parallel(self, planner):
        """exercise + sleep 应在同一并行批次"""
        plan = planner.plan_execution(["exercise", "sleep"])
        assert len(plan) == 1
        assert "exercise" in plan[0] and "sleep" in plan[0]

    def test_dependent_skills_sequential(self, planner):
        """有依赖的 Skill 应先执行依赖项"""
        plan = planner.plan_execution(["constitution", "diet"])
        # constitution 应在 diet 之前或同一批次
        assert len(plan) >= 1
        all_skills = [s for batch in plan for s in batch]
        assert "constitution" in all_skills
        assert "diet" in all_skills
        # constitution 的索引应在 diet 之前
        const_idx = all_skills.index("constitution")
        diet_idx = all_skills.index("diet")
        assert const_idx < diet_idx

    def test_empty_plan(self, planner):
        """空列表应返回空计划"""
        assert planner.plan_execution([]) == []

    def test_can_parallel_true(self, planner):
        """同一并行组内的 Skill 应可并行"""
        assert planner.can_parallel("diet", "tea") is True
        assert planner.can_parallel("exercise", "sleep") is True

    def test_can_parallel_dependency_false(self, planner):
        """有依赖关系的 Skill 不可并行"""
        # diet 依赖 constitution
        assert planner.can_parallel("constitution", "diet") is False

    def test_can_parallel_cross_group(self, planner):
        """不同并行组的 Skill，无依赖时不可并行"""
        # diet 在 diet/tea 组，exercise 在 exercise/sleep 组
        # 无依赖 → False
        assert planner.can_parallel("diet", "exercise") is False

    def test_plan_mixed_skills(self, planner):
        """混合 Skill 应合理分批"""
        plan = planner.plan_execution(["constitution", "diet", "tea", "sleep"])
        # constitution 必须在 diet/tea 之前
        all_skills = [s for batch in plan for s in batch]
        const_idx = all_skills.index("constitution")
        diet_idx = all_skills.index("diet")
        tea_idx = all_skills.index("tea")
        assert const_idx < diet_idx
        assert const_idx < tea_idx

    def test_plan_with_ungrouped_skill(self, planner):
        """不在任何并行组中的 Skill 应单独一批"""
        plan = planner.plan_execution(["diet", "solar_term_guide"])
        # solar_term_guide 不在 PARALLEL_GROUPS 中
        all_batches = plan
        # diet 应有自己的批次
        diet_found = any("diet" in batch for batch in all_batches)
        assert diet_found

    def test_plan_no_duplicate_skills(self, planner):
        """计划中不应有重复 Skill"""
        plan = planner.plan_execution(["diet", "tea", "acupoint"])
        all_skills = [s for batch in plan for s in batch]
        assert len(all_skills) == len(set(all_skills))
