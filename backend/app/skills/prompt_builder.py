"""
顺时 Prompt Builder - Skill Prompt 构建器
为每个 Skill 构建专用 Prompt，包含角色设定、安全规则、Skill 指令

三种 Prompt:
1. build_skill_messages → Skill 专用 prompt（system + user）
2. build_core_prompt → 顺时 AI 角色设定
3. build_policy_prompt → 安全规则（不诊断/不推荐药/不解读报告）

作者: Claw 🦅
日期: 2026-03-17
"""

from __future__ import annotations
from typing import Dict, List, Optional, Any
import logging

from .skill_registry import skill_registry, SkillDefinition

logger = logging.getLogger(__name__)


# ==================== 角色设定 ====================

CORE_PERSONA = """你是「顺时」，一个温暖、贴心、专业的中医养生健康陪伴助手。

## 你的核心特质
- **温暖陪伴**：像一位懂养生的知心朋友，而非冰冷的百科全书
- **专业可信**：基于中医养生智慧和现代营养学，但始终保持谦逊
- **顺应自然**：遵循天人合一理念，强调顺应节气、因人而异
- **简洁实用**：建议要具体、可执行，不讲空话大话

## 你的说话风格
- 语气温柔自然，像朋友聊天
- 避免说教和命令，多用"建议""可以试试"
- 用简单的语言解释专业概念
- 适当使用 🍵🌿🌙 等养生相关符号
- 回复简洁，重点突出，不堆砌信息

## 你的能力边界
- ✅ 日常养生调理建议（饮食、运动、作息、情绪）
- ✅ 节气养生知识科普
- ✅ 中医体质辨识参考
- ✅ 穴位按摩保健指导
- ✅ 养生茶饮和食谱推荐
- ❌ 医疗诊断
- ❌ 药物处方或用药建议
- ❌ 化验报告或影像报告解读
- ❌ 替代专业医疗建议
"""

# ==================== 安全规则 ====================

SAFETY_POLICY = """## 安全红线（必须严格遵守）

### 绝对不能做的事
1. **不诊断疾病**：不能告诉用户"你得了XX病"
2. **不推荐药物**：不能建议吃任何处方药或OTC药物
3. **不解读检查报告**：不能分析化验单、影像报告
4. **不替代医生**：任何疑似疾病症状都要引导就医
5. **不给孕期建议**：孕妇相关问题一律引导产科医生
6. **不给儿童医疗建议**：儿童疾病引导儿科医生

### 必须做的事
1. 当用户描述严重症状时，立即建议就医
2. 当用户询问药物时，说明"我是养生助手，药物问题请咨询医生"
3. 当用户分享检查报告时，引导至专业医生解读
4. 在涉及体质辨识时，强调"仅供参考，不作为诊断依据"
5. 在每个涉及身体调理的建议末尾，可以自然地提醒"如有不适请及时就医"

### 高危关键词处理
- 自杀/轻生/不想活 → 立即提供心理援助热线
- 胸痛/呼吸困难/剧烈头痛 → 立即建议拨打120
- 大量出血/意识不清 → 立即建议急诊
- 孕期出血/腹痛 → 立即建议产科急诊

### 温和但坚定
安全边界要用温暖但明确的方式表达，不要生硬拒绝，但也不能模糊处理。
示例："我很关心您的身体状况，不过关于XX的问题，建议您咨询专业医生会更准确。在日常生活中，您可以从以下几个方面来调理..."
"""


# ==================== 输出格式要求 ====================

OUTPUT_FORMAT_INSTRUCTION = """
## 输出格式要求

请按以下 JSON 格式输出：
```json
{
    "text": "主要回复文本，自然温暖的语言",
    "tone": "gentle",
    "care_status": "stable",
    "suggestions": ["建议1", "建议2", "建议3"],
    "content_cards": [
        {"type": "food", "title": "标题", "summary": "简述"}
    ],
    "follow_up": {"in_days": 2, "intent": "sleep_check", "soft": true},
    "presence_level": "normal",
    "safety_flag": "none",
    "offline_encouraged": true
}
```

字段说明：
- text: 主要回复文本
- tone: 语气 (gentle/warm/encouraging)
- care_status: 关怀状态 (stable/tired/needs_attention/crisis)
- suggestions: 2-5条实用建议
- content_cards: 0-3个内容卡片（food/tea/exercise/acupoint/sleep）
- follow_up: 跟进计划（可选）
- presence_level: 存在感 (present/normal/retreating)
- safety_flag: 安全标记 (none/medical/risk/crisis)
- offline_encouraged: 是否鼓励线下实践
"""


# ==================== Prompt Builder ====================

class PromptBuilder:
    """
    Skill Prompt 构建器

    为每个 Skill 构建完整的 prompt 消息列表，
    包含系统角色设定 + 安全规则 + Skill 指令 + 用户消息。
    """

    def __init__(self, registry=None):
        self._registry = registry or skill_registry

    def build_core_prompt(self) -> str:
        """构建顺时 AI 角色设定 prompt"""
        return CORE_PERSONA

    def build_policy_prompt(self) -> str:
        """构建安全规则 prompt"""
        return SAFETY_POLICY

    def build_skill_prompt(
        self,
        skill_ids: List[str],
        user_context: Optional[Dict[str, Any]] = None,
    ) -> str:
        """
        为多个 Skill 构建专用 system prompt

        Args:
            skill_ids: Skill ID 列表
            user_context: 用户上下文

        Returns:
            完整的 system prompt 字符串
        """
        parts = [CORE_PERSONA, "\n", SAFETY_POLICY]

        for sid in skill_ids:
            skill = self._registry.get(sid)
            if not skill:
                continue

            skill_instruction = f"""
## 当前任务: {skill.name}

{skill.description}

### 输出要求
- 模型: {skill.recommended_model}
- 建议 token 数: {skill.max_tokens}
- 优先级: {skill.priority}
"""
            if skill.tags:
                skill_instruction += f"- 相关标签: {', '.join(skill.tags)}\n"
            if skill.required_context:
                available = user_context or {}
                context_info = []
                for ctx_key in skill.required_context:
                    if ctx_key in available:
                        context_info.append(f"  - {ctx_key}: {available[ctx_key]}")
                if context_info:
                    skill_instruction += f"\n### 用户上下文\n" + "\n".join(context_info) + "\n"
            if skill.output_schema:
                skill_instruction += f"\n### 输出 Schema\n{self._schema_to_text(skill.output_schema)}\n"

            parts.append(skill_instruction)

        parts.append(OUTPUT_FORMAT_INSTRUCTION)
        return "\n".join(parts)

    def build_skill_messages(
        self,
        skill_id: str,
        user_message: str,
        user_context: Optional[Dict[str, Any]] = None,
    ) -> List[Dict[str, str]]:
        """
        为单个 Skill 构建完整的消息列表

        Returns:
            [{"role": "system", "content": "..."}, {"role": "user", "content": "..."}]
        """
        system_prompt = self.build_skill_prompt([skill_id], user_context)

        # 构建用户消息，附加上下文
        user_content = user_message
        if user_context:
            context_parts = []
            if user_context.get("constitution"):
                context_parts.append(f"[体质: {user_context['constitution']}]")
            if user_context.get("season"):
                context_parts.append(f"[节气: {user_context['season']}]")
            if user_context.get("life_stage"):
                context_parts.append(f"[人生阶段: {user_context['life_stage']}]")
            if user_context.get("emotion"):
                context_parts.append(f"[情绪状态: {user_context['emotion']}]")
            if user_context.get("sleep"):
                context_parts.append(f"[睡眠: {user_context['sleep']}]")
            if context_parts:
                user_content = f"{' '.join(context_parts)}\n\n{user_message}"

        return [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_content},
        ]

    def build_generic_messages(
        self,
        user_message: str,
        user_context: Optional[Dict[str, Any]] = None,
    ) -> List[Dict[str, str]]:
        """
        构建通用对话消息（未匹配到特定 Skill 时使用）
        """
        system_prompt = self.build_core_prompt() + "\n\n" + self.build_policy_prompt()
        system_prompt += """
## 当前任务: 通用对话

用户的消息没有匹配到特定的养生技能。请以顺时AI的身份，友好自然地回应。
如果用户的请求涉及养生健康，可以提供一般性的建议。
如果请求超出养生范围，可以温和说明你的定位。

请以 JSON 格式输出，结构如下：
```json
{
    "text": "回复文本",
    "tone": "warm",
    "care_status": "stable",
    "suggestions": [],
    "content_cards": [],
    "safety_flag": "none"
}
```
"""

        user_content = user_message
        if user_context:
            context_parts = []
            if user_context.get("constitution"):
                context_parts.append(f"[体质: {user_context['constitution']}]")
            if user_context.get("season"):
                context_parts.append(f"[节气: {user_context['season']}]")
            if context_parts:
                user_content = f"{' '.join(context_parts)}\n\n{user_message}"

        return [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_content},
        ]

    def _schema_to_text(self, schema: Dict[str, Any]) -> str:
        """将 JSON Schema 转换为人类可读的文本描述"""
        if not schema:
            return ""

        parts = []
        props = schema.get("properties", {})
        required = set(schema.get("required", []))

        for key, val in props.items():
            type_str = val.get("type", "any")
            desc = val.get("description", "")
            required_mark = " (必填)" if key in required else ""
            enum_vals = val.get("enum")
            if enum_vals:
                type_str += f" [{', '.join(enum_vals)}]"
            parts.append(f"- {key}: {type_str}{required_mark} — {desc}")

        return "\n".join(parts) if parts else "标准输出格式"
