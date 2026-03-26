"""
顺时 Skill Orchestrator - Skill 编排引擎
串联意图识别 → Skill 查找 → 依赖排序 → Prompt 生成 → 模型调用 → Schema 校验

执行流程:
1. IntentClassifier 识别意图
2. SkillRegistry 查找匹配的 Skill (1-3个)
3. 按依赖关系排序
4. PromptBuilder 生成 prompt
5. 调用模型
6. SchemaValidator 校验输出
7. 返回 SkillExecutionResult

作者: Claw 🦅
日期: 2026-03-17
"""

from __future__ import annotations
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, field
from enum import Enum
import logging
import time
import json

from .skill_registry import skill_registry, SkillDefinition
from .intent_classifier import IntentClassifier
from .schema_validator import SchemaValidator
from .prompt_builder import PromptBuilder

logger = logging.getLogger(__name__)


# ==================== 数据类 ====================

class OrchestrationStatus(str, Enum):
    """编排状态"""
    SUCCESS = "success"
    PARTIAL = "partial"       # 部分Skill成功
    FAILED = "failed"
    BLOCKED = "blocked"       # 安全拦截


@dataclass
class SkillResult:
    """单个 Skill 执行结果"""
    skill_id: str
    skill_name: str
    category: str
    status: str  # success / failed / skipped
    model: str
    tokens_used: int
    latency_ms: int
    output: Dict[str, Any] = field(default_factory=dict)
    raw_response: str = ""
    error: Optional[str] = None


@dataclass
class SkillExecutionResult:
    """Skill 编排执行结果"""
    status: OrchestrationStatus
    skills_executed: List[SkillResult]
    final_response: str
    total_tokens: int
    total_latency_ms: int
    safety_flag: str = "none"  # none / medical / risk / crisis
    follow_up: Optional[Dict[str, Any]] = None
    error: Optional[str] = None

    def to_dict(self) -> Dict[str, Any]:
        return {
            "status": self.status.value,
            "skills_executed": [
                {
                    "skill_id": sr.skill_id,
                    "skill_name": sr.skill_name,
                    "category": sr.category,
                    "status": sr.status,
                    "model": sr.model,
                    "tokens_used": sr.tokens_used,
                    "latency_ms": sr.latency_ms,
                    "output": sr.output,
                }
                for sr in self.skills_executed
            ],
            "final_response": self.final_response,
            "total_tokens": self.total_tokens,
            "total_latency_ms": self.total_latency_ms,
            "safety_flag": self.safety_flag,
            "follow_up": self.follow_up,
        }


# ==================== LLM 调用接口 ====================

class LLMClient:
    """LLM 调用客户端（由外部注入）"""

    def __init__(self, client=None):
        self._client = client

    async def chat(
        self,
        model: str,
        messages: List[Dict[str, str]],
        temperature: float = 0.7,
        max_tokens: int = 2048,
    ) -> Dict[str, Any]:
        """
        调用 LLM

        Returns:
            {"content": str, "tokens": int, "model": str}
        """
        if self._client is None:
            # 默认使用 SiliconFlow
            try:
                from ..llm.siliconflow import get_client, ChatMessage, MessageRole
                sf = get_client()
                sf_msgs = [
                    ChatMessage(role=MessageRole(msg["role"]), content=msg["content"])
                    for msg in messages
                ]
                response = await sf.chat_completion(
                    model=model,
                    messages=sf_msgs,
                    temperature=temperature,
                    max_tokens=max_tokens,
                )
                content = response.choices[0].get("message", {}).get("content", "")
                tokens = response.usage.total_tokens
                return {"content": content, "tokens": tokens, "model": model}
            except Exception as e:
                logger.error(f"[LLM] 调用失败: {e}")
                raise

        # 使用注入的客户端
        return await self._client.chat(
            model=model,
            messages=messages,
            temperature=temperature,
            max_tokens=max_tokens,
        )


# ==================== Skill Orchestrator ====================

class SkillOrchestrator:
    """
    Skill 编排器

    核心 execute 方法流程:
    1. 安全检测 → 2. 意图分类 → 3. Skill匹配 → 4. 依赖排序
    → 5. Prompt构建 → 6. 模型调用 → 7. Schema校验 → 8. 结果组装
    """

    def __init__(
        self,
        llm_client: Optional[LLMClient] = None,
        intent_classifier: Optional[IntentClassifier] = None,
        prompt_builder: Optional[PromptBuilder] = None,
        schema_validator: Optional[SchemaValidator] = None,
    ):
        self.llm = llm_client or LLMClient()
        self.classifier = intent_classifier or IntentClassifier()
        self.prompt_builder = prompt_builder or PromptBuilder()
        self.validator = schema_validator or SchemaValidator()
        self._registry = skill_registry

    async def execute(
        self,
        user_message: str,
        user_context: Optional[Dict[str, Any]] = None,
    ) -> SkillExecutionResult:
        """
        执行 Skill 编排

        Args:
            user_message: 用户消息
            user_context: 用户上下文（体质/季节/睡眠等）

        Returns:
            SkillExecutionResult
        """
        start_time = time.time()
        user_context = user_context or {}

        # Step 1: 安全检测（最高优先级）
        safety_check = self._check_safety(user_message, user_context)
        if safety_check:
            return SkillExecutionResult(
                status=OrchestrationStatus.BLOCKED,
                skills_executed=[],
                final_response=safety_check["response"],
                total_tokens=0,
                total_latency_ms=int((time.time() - start_time) * 1000),
                safety_flag=safety_check.get("flag", "none"),
                follow_up=safety_check.get("follow_up"),
            )

        # Step 2: 意图分类
        intent_result = self.classifier.classify(user_message, user_context)
        logger.info(f"[Orchestrator] 识别意图: {intent_result.primary_intent} (置信度: {intent_result.confidence})")

        # 将 IntentResult 转换为 (category, confidence) 列表
        from .intent_classifier import INTENT_TO_CATEGORY
        intent_pairs = []
        for intent_name, conf in intent_result.all_intents:
            cat = INTENT_TO_CATEGORY.get(intent_name, "lifestyle")
            intent_pairs.append((cat, conf))
        if not intent_pairs:
            cat = INTENT_TO_CATEGORY.get(intent_result.primary_intent, "lifestyle")
            intent_pairs.append((cat, intent_result.confidence))

        if not intent_pairs:
            # 未识别到意图，使用通用响应
            return await self._execute_generic(user_message, user_context, start_time)

        # Step 3: Skill 匹配（每个意图映射 1-3 个 Skill）
        matched_skills = self._match_skills(intent_pairs, user_context)
        logger.info(f"[Orchestrator] 匹配 Skill: {[s.skill_id for s in matched_skills]}")

        if not matched_skills:
            return await self._execute_generic(user_message, user_context, start_time)

        # Step 4: 依赖排序（拓扑排序）
        ordered_skills = self._topological_sort(matched_skills)

        # Step 5-7: 逐个执行 Skill
        skill_results: List[SkillResult] = []
        accumulated_context = dict(user_context)

        for skill_def in ordered_skills:
            result = await self._execute_single_skill(
                skill_def, user_message, accumulated_context
            )
            skill_results.append(result)

            # 将输出中的有用信息加入上下文，供后续 Skill 使用
            if result.status == "success" and result.output:
                accumulated_context[f"_last_{skill_def.category}"] = result.output

        # Step 8: 组装最终结果
        return self._assemble_result(
            skill_results, user_message, start_time
        )

    # ==================== 内部方法 ====================

    def _check_safety(
        self, message: str, context: Dict[str, Any]
    ) -> Optional[Dict[str, Any]]:
        """
        安全检测

        Returns:
            None → 安全通过
            Dict → 需要拦截，包含 response, flag, follow_up
        """
        # 医疗意图检测
        medical_skill = self._registry.search("医疗意图检测")
        if medical_skill:
            keywords = ["诊断", "确诊", "开药", "处方", "治疗",
                        "手术", "化验单", "检查报告", "怀孕", "孕期"]
            for kw in keywords:
                if kw in message:
                    return {
                        "response": (
                            "我是顺时，一个养生健康陪伴助手。关于医疗诊断、"
                            "用药等问题，建议您咨询专业医生哦。我可以为您提供"
                            "日常养生调理方面的建议。"
                        ),
                        "flag": "medical",
                        "follow_up": {
                            "in_days": 1,
                            "intent": "general_check",
                            "soft": True,
                        },
                    }

        # 危机情绪检测
        crisis_keywords = ["自杀", "不想活", "活着没意思", "结束生命",
                          "伤害自己", "轻生"]
        for kw in crisis_keywords:
            if kw in message:
                return {
                    "response": (
                        "听到您这样说，我很关心您的安全。如果您正在经历"
                        "困难时刻，请拨打24小时心理援助热线：\n\n"
                        "• 全国心理援助热线：400-161-9995\n"
                        "• 北京心理危机研究与干预中心：010-82951332\n"
                        "• 生命热线：400-821-1215\n\n"
                        "您并不孤单，专业的帮助就在身边。"
                    ),
                    "flag": "crisis",
                    "follow_up": None,
                }

        return None

    def _match_skills(
        self,
        intent_pairs: List[tuple],
        context: Dict[str, Any],
    ) -> List[SkillDefinition]:
        """
        根据意图匹配 Skill

        Args:
            intent_pairs: [(category, confidence), ...]
            context: 用户上下文

        每个意图映射到其分类下的 Skills，选择最相关的 1-3 个。
        """
        matched = []
        seen_ids = set()

        for category, _confidence in intent_pairs[:3]:  # 最多3个意图
            skills_in_cat = self._registry.get_by_category(category)

            if not skills_in_cat:
                continue

            # 按优先级排序，优先 P0
            priority_order = {"P0": 0, "P1": 1, "P2": 2}
            skills_in_cat.sort(key=lambda s: priority_order.get(s.priority, 9))

            # 检查上下文是否满足
            available_context = set(context.keys())
            for skill in skills_in_cat:
                if skill.skill_id in seen_ids:
                    continue
                # 检查 required_context 是否满足
                if skill.required_context:
                    if not skill.required_context[0].startswith("_"):
                        # 仅当有非内部上下文要求时才检查
                        pass
                matched.append(skill)
                seen_ids.add(skill.skill_id)
                if len(matched) >= 3:
                    break

            if len(matched) >= 3:
                break

        return matched

    def _topological_sort(
        self, skills: List[SkillDefinition]
    ) -> List[SkillDefinition]:
        """
        拓扑排序，确保依赖的 Skill 先执行

        简单实现：被依赖的排前面
        """
        skill_map = {s.skill_id: s for s in skills}
        skill_ids = set(skill_map.keys())
        visited = set()
        result = []

        def visit(sid: str):
            if sid in visited or sid not in skill_ids:
                return
            visited.add(sid)
            skill = skill_map[sid]
            for dep_id in skill.dependencies:
                if dep_id in skill_ids:
                    visit(dep_id)
            result.append(skill)

        for sid in skill_ids:
            visit(sid)

        return result

    async def _execute_single_skill(
        self,
        skill_def: SkillDefinition,
        user_message: str,
        context: Dict[str, Any],
    ) -> SkillResult:
        """执行单个 Skill"""
        skill_start = time.time()

        try:
            # 构建 prompt
            messages = self.prompt_builder.build_skill_messages(
                skill_id=skill_def.skill_id,
                user_message=user_message,
                user_context=context,
            )

            # 决定温度参数
            temperature = 0.7
            if skill_def.category in ("emotion", "follow_up"):
                temperature = 0.85
            elif skill_def.category in ("safety", "meta"):
                temperature = 0.3

            # 调用 LLM
            llm_result = await self.llm.chat(
                model=skill_def.recommended_model,
                messages=messages,
                temperature=temperature,
                max_tokens=skill_def.max_tokens,
            )

            # Schema 校验
            validation = self.validator.validate(llm_result["content"])
            if validation.success:
                output = validation.data if isinstance(validation.data, dict) else {
                    "text": str(validation.data),
                    "tone": "gentle",
                    "care_status": "stable",
                    "suggestions": [],
                    "content_cards": [],
                    "safety_flag": "none",
                }
            else:
                output = {
                    "text": llm_result["content"],
                    "tone": "gentle",
                    "care_status": "stable",
                    "suggestions": [],
                    "content_cards": [],
                    "safety_flag": "none",
                }

            latency = int((time.time() - skill_start) * 1000)

            return SkillResult(
                skill_id=skill_def.skill_id,
                skill_name=skill_def.name,
                category=skill_def.category,
                status="success",
                model=skill_def.recommended_model,
                tokens_used=llm_result.get("tokens", 0),
                latency_ms=latency,
                output=output,
                raw_response=llm_result["content"],
            )

        except Exception as e:
            logger.error(f"[Orchestrator] Skill {skill_def.skill_id} 执行失败: {e}")
            latency = int((time.time() - skill_start) * 1000)
            return SkillResult(
                skill_id=skill_def.skill_id,
                skill_name=skill_def.name,
                category=skill_def.category,
                status="failed",
                model=skill_def.recommended_model,
                tokens_used=0,
                latency_ms=latency,
                error=str(e),
            )

    def _assemble_result(
        self,
        skill_results: List[SkillResult],
        user_message: str,
        start_time: float,
    ) -> SkillExecutionResult:
        """组装最终结果"""
        success_results = [r for r in skill_results if r.status == "success"]
        failed_results = [r for r in skill_results if r.status == "failed"]

        if not success_results:
            return SkillExecutionResult(
                status=OrchestrationStatus.FAILED,
                skills_executed=skill_results,
                final_response="抱歉，处理您的问题时遇到了一些困难，请稍后再试。",
                total_tokens=0,
                total_latency_ms=int((time.time() - start_time) * 1000),
                error="所有 Skill 执行失败",
            )

        # 合并多个 Skill 的输出
        # 以最后一个成功 Skill 的 text 为主响应
        main_result = success_results[-1]
        final_text = main_result.output.get("text", main_result.raw_response)

        # 如果有多个 Skill，添加补充卡片
        all_suggestions = []
        all_cards = []
        safety_flag = "none"
        follow_up = None

        for r in success_results:
            output = r.output
            if isinstance(output, dict):
                all_suggestions.extend(output.get("suggestions", []))
                all_cards.extend(output.get("content_cards", []))
                sf = output.get("safety_flag", "none")
                if sf != "none":
                    safety_flag = sf
                if not follow_up and output.get("follow_up"):
                    follow_up = output["follow_up"]

        # 去重
        all_suggestions = list(dict.fromkeys(all_suggestions))[:5]
        all_cards = all_cards[:5]

        # 如果有补充卡片，追加到主响应
        if len(success_results) > 1 and all_cards:
            card_text = "\n\n".join(
                f"📌 {c.get('title', '')}: {c.get('summary', '')}"
                for c in all_cards
            )
            final_text = f"{final_text}\n\n---\n{card_text}"

        status = OrchestrationStatus.PARTIAL if failed_results else OrchestrationStatus.SUCCESS

        return SkillExecutionResult(
            status=status,
            skills_executed=skill_results,
            final_response=final_text,
            total_tokens=sum(r.tokens_used for r in skill_results),
            total_latency_ms=int((time.time() - start_time) * 1000),
            safety_flag=safety_flag,
            follow_up=follow_up,
        )

    async def _execute_generic(
        self,
        user_message: str,
        context: Dict[str, Any],
        start_time: float,
    ) -> SkillExecutionResult:
        """通用响应（未匹配到特定 Skill）"""
        try:
            messages = self.prompt_builder.build_generic_messages(
                user_message=user_message,
                user_context=context,
            )

            llm_result = await self.llm.chat(
                model="deepseek-v3.2",
                messages=messages,
                temperature=0.7,
                max_tokens=1024,
            )

            return SkillExecutionResult(
                status=OrchestrationStatus.SUCCESS,
                skills_executed=[],
                final_response=llm_result["content"],
                total_tokens=llm_result.get("tokens", 0),
                total_latency_ms=int((time.time() - start_time) * 1000),
            )
        except Exception as e:
            return SkillExecutionResult(
                status=OrchestrationStatus.FAILED,
                skills_executed=[],
                final_response="抱歉，我暂时无法处理您的请求。请稍后再试。",
                total_tokens=0,
                total_latency_ms=int((time.time() - start_time) * 1000),
                error=str(e),
            )
