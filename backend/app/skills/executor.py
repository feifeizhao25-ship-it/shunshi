"""
顺时 Skill 执行引擎
Skill Engine

包含 10 个核心 Skill:
- daily_rhythm_plan
- solar_term_guide
- food_recommend
- tea_recommend
- sleep_winddown
- mood_support
- office_micro_break
- acupressure_routine
- body_constitution
- family_digest

作者: Claw 🦅
日期: 2026-03-09
"""

from typing import Dict, Any, Optional, List
from dataclasses import dataclass
from enum import Enum
import json
import logging
import asyncio

logger = logging.getLogger(__name__)


class SkillName(str, Enum):
    """Skill 名称"""
    DAILY_RHYTHM_PLAN = "daily_rhythm_plan"
    SOLAR_TERM_GUIDE = "solar_term_guide"
    FOOD_RECOMMEND = "food_recommend"
    TEA_RECOMMEND = "tea_recommend"
    SLEEP_WINDDOWN = "sleep_winddown"
    MOOD_SUPPORT = "mood_support"
    OFFICE_MICRO_BREAK = "office_micro_break"
    ACUPRESSURE_ROUTINE = "acupressure_routine"
    BODY_CONSTITUTION = "body_constitution"
    FAMILY_DIGEST = "family_digest"


@dataclass
class SkillInput:
    """Skill 输入"""
    skill_name: str
    user_id: str
    user_stage: str = "adult"  # youth, adult, middle_age, elder
    context: Dict[str, Any] = None
    
    # 可选参数
    constitution: Optional[str] = None  # 体质
    season: Optional[str] = None         # 季节
    solar_term: Optional[str] = None     # 节气
    emotion: Optional[str] = None        # 情绪
    sleep_quality: Optional[str] = None  # 睡眠


@dataclass
class SkillOutput:
    """Skill 输出"""
    skill_name: str
    content: str
    data: Dict[str, Any]
    model: str
    followup_suggestions: list = None


# ==================== 失败兜底模板 ====================

SKILL_FALLBACK_TEMPLATES: Dict[str, str] = {
    "diet": "关于饮食调养，建议你注意荤素搭配、定时定量。",
    "tea": "喝茶养生讲究时令。春季宜花茶，冬季宜红茶。",
    "acupoint": "穴位调理建议先从简单的合谷、太冲开始。",
    "exercise": "适当运动是最好的养生。建议每天散步30分钟。",
    "sleep": "改善睡眠从规律作息开始，建议22:30前上床。",
    "emotion": "你现在的感受是正常的。给自己一点时间，我在这里陪你。",
    "constitution": "体质调理需要持之以恒，建议从日常饮食和作息开始。",
    "season": "顺应节气养生，春生夏长秋收冬藏。",
    "daily_plan": "今天的养生建议已经为你准备好了。",
    "reflection": "反思是一种很好的习惯。你觉得今天怎么样？",
    "follow_up": "上次聊到的话题，你最近感觉怎么样？",
    "family": "家人的健康也很重要。记得关心一下身边的家人。",
    "safety": "我注意到你提到了一些重要的事情。",
    "lifestyle": "养生融入日常，从每个小习惯开始。",
    "meta": "系统正在调整中，请稍后再试。",
}


def get_fallback_response(skill_name_or_category: str) -> str:
    """
    获取 Skill 的兜底回复

    优先匹配完整 skill_id，其次匹配分类名。
    """
    if skill_name_or_category in SKILL_FALLBACK_TEMPLATES:
        return SKILL_FALLBACK_TEMPLATES[skill_name_or_category]
    # 尝试按分类匹配
    for key, template in SKILL_FALLBACK_TEMPLATES.items():
        if key in skill_name_or_category or skill_name_or_category.startswith(key):
            return template
    return "抱歉，我暂时无法处理这个请求，请稍后再试。"


class SkillExecutor:
    """Skill 执行器"""
    
    def __init__(self, llm_client=None):
        self.llm_client = llm_client
        self.skills = self._init_skills()
    
    def _init_skills(self) -> Dict[str, Dict]:
        """初始化 Skill 配置"""
        return {
            SkillName.DAILY_RHYTHM_PLAN: {
                "name": "daily_rhythm_plan",
                "description": "每日养生计划",
                "model": "deepseek-v3.2",
                "input_schema": {
                    "user_stage": "youth|adult|middle_age|elder",
                    "season": "spring|summer|autumn|winter",
                    "sleep_quality": "good|normal|poor",
                },
                "prompt_template": """生成今日养生计划

用户信息：
- 年龄阶段: {user_stage}
- 当前季节: {season}
- 睡眠质量: {sleep_quality}

要求：
1. 简洁实用
2. 温和语气
3. 3-5个可执行建议""",
            },
            SkillName.SOLAR_TERM_GUIDE: {
                "name": "solar_term_guide",
                "description": "节气养生指南",
                "model": "glm-4.6",
                "input_schema": {
                    "solar_term": "24节气之一",
                    "user_stage": "youth|adult|middle_age|elder",
                },
                "prompt_template": """生成节气养生建议

当前节气: {solar_term}
用户年龄阶段: {user_stage}

包含：
1. 节气特点
2. 饮食建议
3. 起居建议
4. 运动建议
5. 情志调养""",
            },
            SkillName.FOOD_RECOMMEND: {
                "name": "food_recommend",
                "description": "食疗推荐",
                "model": "glm-4.6",
                "input_schema": {
                    "constitution": "体质类型",
                    "season": "季节",
                    "scenario": "场景(早餐/午餐/晚餐/加餐)",
                },
                "prompt_template": """推荐食疗方案

用户体质: {constitution}
当前季节: {season}
使用场景: {scenario}

包含：
1. 推荐食材
2. 食谱做法
3. 注意事项""",
            },
            SkillName.TEA_RECOMMEND: {
                "name": "tea_recommend",
                "description": "茶饮推荐",
                "model": "glm-4.6",
                "input_schema": {
                    "constitution": "体质类型",
                    "season": "季节",
                    "time_of_day": "时段( morning/afternoon/evening)",
                },
                "prompt_template": """推荐养生茶饮

用户体质: {constitution}
当前季节: {season}
使用时段: {time_of_day}

包含：
1. 茶饮名称
2. 配方
3. 功效
4. 泡法""",
            },
            SkillName.SLEEP_WINDDOWN: {
                "name": "sleep_winddown",
                "description": "睡眠改善",
                "model": "glm-4.6",
                "input_schema": {
                    "sleep_quality": "good|normal|poor",
                    "sleep_issues": "问题描述",
                    "user_stage": "youth|adult|middle_age|elder",
                },
                "prompt_template": """提供睡眠改善建议

睡眠质量: {sleep_quality}
具体问题: {sleep_issues}
年龄阶段: {user_stage}

包含：
1. 睡前习惯
2. 环境建议
3. 放松方法
4. 注意事项""",
            },
            SkillName.MOOD_SUPPORT: {
                "name": "mood_support",
                "description": "情绪支持",
                "model": "glm-4.6",
                "input_schema": {
                    "emotion": "情绪类型",
                    "intensity": "intensity_1-10",
                    "background": "背景描述",
                },
                "prompt_template": """提供情绪支持

用户情绪: {emotion}
情绪强度: {intensity}
背景: {background}

要求：
1. 先共情
2. 不说教
3. 给1-2个小建议
4. 保持温暖""",
            },
            SkillName.OFFICE_MICRO_BREAK: {
                "name": "office_micro_break",
                "description": "办公室微运动",
                "model": "deepseek-v3.2",
                "input_schema": {
                    "work_type": "office_type",
                    "duration_minutes": "时长",
                },
                "prompt_template": """推荐办公室微运动

工作类型: {work_type}
可运动时长: {duration_minutes}分钟

包含：
1. 2-3个简单动作
2. 每个动作要点
3. 注意事项""",
            },
            SkillName.ACUPRESSURE_ROUTINE: {
                "name": "acupressure_routine",
                "description": "穴位保健",
                "model": "glm-4.6",
                "input_schema": {
                    "concern": "身体问题",
                    "user_stage": "youth|adult|middle_age|elder",
                },
                "prompt_template": """推荐穴位保健

用户关注: {concern}
年龄阶段: {user_stage}

包含：
1. 推荐穴位(2-3个)
2. 位置说明
3. 按摩方法
4. 注意事项""",
            },
            SkillName.BODY_CONSTITUTION: {
                "name": "body_constitution",
                "description": "体质分析",
                "model": "kimi-k2-thinking",
                "input_schema": {
                    "symptoms": "症状描述",
                    "lifestyle": "生活方式",
                },
                "prompt_template": """分析体质类型

症状: {symptoms}
生活方式: {lifestyle}

根据中医体质分类，给出：
1. 可能体质
2. 特征分析
3. 调养建议
4. 注意事项""",
            },
            SkillName.FAMILY_DIGEST: {
                "name": "family_digest",
                "description": "家庭健康摘要",
                "model": "kimi-k2-thinking",
                "input_schema": {
                    "family_members": "家庭成员列表",
                    "time_range": "时间范围(week/month)",
                },
                "prompt_template": """生成家庭健康摘要

家庭成员: {family_members}
时间范围: {time_range}

包含：
1. 整体健康趋势
2. 成员亮点
3. 关怀提醒
4. 建议""",
            },
        }
    
    async def execute(self, skill_input: SkillInput) -> SkillOutput:
        """执行 Skill（带兜底逻辑）"""
        return await self.execute_with_fallback(skill_input)

    async def execute_with_fallback(
        self,
        skill_input: SkillInput,
        max_retries: int = 1,
        timeout_seconds: int = 30,
    ) -> SkillOutput:
        """
        执行 Skill，失败时：
        1. 重试 max_retries 次
        2. 超时 timeout_seconds 秒
        3. 全部失败返回 skill 对应的默认模板回复

        Args:
            skill_input: Skill 输入
            max_retries: 最大重试次数（不含首次尝试）
            timeout_seconds: 单次执行超时

        Returns:
            SkillOutput
        """
        skill_name = skill_input.skill_name
        last_error: Optional[Exception] = None

        for attempt in range(max_retries + 1):
            try:
                result = await asyncio.wait_for(
                    self._execute_internal(skill_input),
                    timeout=timeout_seconds,
                )
                return result
            except asyncio.TimeoutError:
                last_error = TimeoutError(
                    f"Skill {skill_name} 执行超时 ({timeout_seconds}s, attempt {attempt + 1})"
                )
                logger.warning(f"[SkillExecutor] 超时: {last_error}")
            except Exception as e:
                last_error = e
                logger.warning(
                    f"[SkillExecutor] 失败: {skill_name}, attempt {attempt + 1}: {e}"
                )

        # 全部失败，返回兜底回复
        fallback = get_fallback_response(skill_name)
        logger.info(
            f"[SkillExecutor] 使用兜底回复: {skill_name} -> {fallback[:30]}..."
        )

        return SkillOutput(
            skill_name=skill_name,
            content=fallback,
            data={"input": skill_input.__dict__, "fallback": True, "error": str(last_error)},
            model="fallback",
            followup_suggestions=self._get_followup(skill_name),
        )

    async def _execute_internal(self, skill_input: SkillInput) -> SkillOutput:
        """内部执行逻辑（不含重试/超时/兜底）"""
        skill_config = self.skills.get(skill_input.skill_name)
        
        if not skill_config:
            raise ValueError(f"Unknown skill: {skill_input.skill_name}")
        
        logger.info(f"[SkillExecutor] Executing: {skill_input.skill_name}")
        
        # 构建 prompt
        prompt = self._build_prompt(skill_config, skill_input)
        model = skill_config["model"]
        
        content = None
        
        # 如果有 LLM 客户端，调用真实 LLM
        if self.llm_client:
            content = await self._call_llm(model, prompt)
            logger.info(f"[SkillExecutor] LLM 成功: {skill_input.skill_name} ({model})")
        
        # LLM 不可用时使用 Mock
        if content is None:
            content = self._get_mock_response(skill_input.skill_name)
        
        return SkillOutput(
            skill_name=skill_input.skill_name,
            content=content,
            data={"input": skill_input.__dict__},
            model=model,
            followup_suggestions=self._get_followup(skill_input.skill_name),
        )

    async def _call_llm(self, model: str, prompt: str) -> str:
        """调用 LLM 获取 Skill 执行结果"""
        from app.llm.siliconflow import ChatMessage, MessageRole
        
        system_prompt = (
            "你是顺时，一个温暖贴心的 AI 养生健康陪伴助手。\n"
            "请根据用户的需求，提供专业、实用、温暖的养生建议。\n"
            "回答简洁有条理，使用编号或分点。语气亲切友好。"
        )
        
        messages = [
            ChatMessage(role=MessageRole.SYSTEM, content=system_prompt),
            ChatMessage(role=MessageRole.USER, content=prompt),
        ]
        
        response = await self.llm_client.chat_completion(
            model=model,
            messages=messages,
            temperature=0.7,
            max_tokens=4096,
        )
        
        return response.choices[0].get("message", {}).get("content", "")
    
    def _build_prompt(self, config: Dict, skill_input: SkillInput) -> str:
        """构建 Prompt"""
        template = config["prompt_template"]
        context = skill_input.__dict__.copy()
        
        # 填充默认值
        context.setdefault("user_stage", "adult")
        context.setdefault("season", "spring")
        
        try:
            return template.format(**context)
        except KeyError:
            return template
    
    def _get_mock_response(self, skill_name: str) -> str:
        """模拟响应"""
        responses = {
            SkillName.DAILY_RHYTHM_PLAN: "今日养生建议：\n1. 早起喝温水\n2. 适当运动\n3. 规律作息",
            SkillName.SOLAR_TERM_GUIDE: "当前节气：春分\n养生重点：阴阳平衡",
            SkillName.FOOD_RECOMMEND: "推荐食材：山药、薏米、红枣",
            SkillName.TEA_RECOMMEND: "推荐茶饮：枸杞菊花茶",
            SkillName.SLEEP_WINDDOWN: "睡前建议：泡脚、关灯、深呼吸",
            SkillName.MOOD_SUPPORT: "我理解你的感受，放松一下会好的",
            SkillName.OFFICE_MICRO_BREAK: "推荐：颈部环绕、肩部放松",
            SkillName.ACUPRESSURE_ROUTINE: "推荐穴位：足三里、百会",
            SkillName.BODY_CONSTITUTION: "体质分析：平和质",
            SkillName.FAMILY_DIGEST: "家庭健康摘要：本月整体良好",
        }
        return responses.get(skill_name, "执行完成")
    
    def _get_followup(self, skill_name: str) -> list:
        """获取跟进建议"""
        return [
            "还有其他想了解的吗？",
            "可以试试记录一下",
        ]
    
    def list_skills(self) -> list:
        """列出所有 Skills"""
        return [
            {
                "name": s["name"],
                "description": s["description"],
                "model": s["model"],
            }
            for s in self.skills.values()
        ]


# 全局实例（延迟初始化 LLM 客户端）
skill_executor = SkillExecutor(llm_client=None)


def init_skill_executor(llm_client):
    """初始化 Skill 执行器的 LLM 客户端"""
    global skill_executor
    skill_executor = SkillExecutor(llm_client=llm_client)
    logger.info("[SkillExecutor] 已初始化 LLM 客户端")


# ==================== 使用示例 ====================

async def demo():
    """演示"""
    executor = SkillExecutor()
    
    print("=" * 60)
    print("顺时 Skill 系统演示")
    print("=" * 60)
    
    # 列出 Skills
    print("\n[可用 Skills]")
    for s in executor.list_skills():
        print(f"  - {s['name']}: {s['description']} ({s['model']})")
    
    # 执行 Skill
    print("\n[执行 Skill]")
    test_input = SkillInput(
        skill_name=SkillName.SLEEP_WINDDOWN,
        user_id="user_001",
        user_stage="adult",
        sleep_quality="poor",
        sleep_issues="入睡困难",
    )
    
    result = await executor.execute(test_input)
    print(f"  Skill: {result.skill_name}")
    print(f"  Model: {result.model}")
    print(f"  Content: {result.content}")


if __name__ == "__main__":
    import asyncio
    asyncio.run(demo())
