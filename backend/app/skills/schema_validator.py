"""
顺时 Skill Schema Validator - 输出 Schema 校验与降级
对 LLM 输出进行结构化 JSON 校验，确保符合预期格式

校验流程：
1. 必填字段检查
2. 枚举值校验
3. 数组长度限制
4. 类型检查
5. 修复尝试（补缺省值）
6. 降级为纯文本（修复失败时）

标准输出 Schema:
{
    "text": "回复文本",
    "tone": "gentle|warm|encouraging",
    "care_status": "stable|tired|needs_attention|crisis",
    "suggestions": ["建议1", "建议2", "建议3"],
    "content_cards": [{"type": "food|tea|exercise|acupoint|sleep", "title": "", "summary": ""}],
    "follow_up": {"in_days": 2, "intent": "sleep_check", "soft": true},
    "presence_level": "present|normal|retreating",
    "safety_flag": "none|medical|risk|crisis",
    "offline_encouraged": true
}

作者: Claw 🦅
日期: 2026-03-17
"""

import json
import re
import logging
from typing import Dict, Any, Optional, List, Tuple
from pydantic import BaseModel, Field, field_validator
from enum import Enum

logger = logging.getLogger(__name__)


# ==================== 枚举定义 ====================

class Tone(str, Enum):
    """语气风格"""
    GENTLE = "gentle"              # 温和
    WARM = "warm"                  # 温暖
    ENCOURAGING = "encouraging"    # 鼓励


class CareStatus(str, Enum):
    """关怀状态"""
    STABLE = "stable"                    # 稳定
    TIRED = "tired"                      # 疲惫
    NEEDS_ATTENTION = "needs_attention"  # 需要关注
    CRISIS = "crisis"                    # 危机


class ContentType(str, Enum):
    """内容卡片类型"""
    FOOD = "food"
    TEA = "tea"
    EXERCISE = "exercise"
    ACUPOINT = "acupoint"
    SLEEP = "sleep"


class PresenceLevel(str, Enum):
    """存在感级别"""
    PRESENT = "present"        # 在场
    NORMAL = "normal"          # 正常
    RETREATING = "retreating"  # 退隐


class SafetyFlag(str, Enum):
    """安全标志"""
    NONE = "none"      # 无
    MEDICAL = "medical"  # 涉及医疗
    RISK = "risk"      # 有风险
    CRISIS = "crisis"  # 危机


# ==================== Pydantic 模型 ====================

class FollowUp(BaseModel):
    """跟进计划"""
    in_days: int = Field(default=2, ge=1, le=30, description="跟进天数")
    intent: str = Field(default="general_check", description="跟进意图")
    soft: bool = Field(default=True, description="是否软性跟进")


class ContentCard(BaseModel):
    """内容卡片"""
    type: str = Field(description="卡片类型")
    title: str = Field(default="", description="标题")
    summary: str = Field(default="", description="摘要")

    @field_validator("type")
    @classmethod
    def validate_type(cls, v: str) -> str:
        valid_types = {"food", "tea", "exercise", "acupoint", "sleep"}
        if v.lower() in valid_types:
            return v.lower()
        return "food"  # 默认类型


class SkillOutput(BaseModel):
    """
    Skill 标准输出 Schema

    所有 Skill 的 LLM 输出都应遵循此 Schema
    """
    text: str = Field(default="", description="回复文本")
    tone: str = Field(default="gentle", description="语气风格")
    care_status: str = Field(default="stable", description="关怀状态")
    suggestions: List[str] = Field(default_factory=list, description="建议列表")
    content_cards: List[Dict[str, Any]] = Field(default_factory=list, description="内容卡片")
    follow_up: Optional[Dict[str, Any]] = Field(default=None, description="跟进计划")
    presence_level: str = Field(default="normal", description="存在感级别")
    safety_flag: str = Field(default="none", description="安全标志")
    offline_encouraged: bool = Field(default=True, description="是否鼓励离线实践")

    @field_validator("tone")
    @classmethod
    def validate_tone(cls, v: str) -> str:
        valid = {"gentle", "warm", "encouraging"}
        return v if v in valid else "gentle"

    @field_validator("care_status")
    @classmethod
    def validate_care_status(cls, v: str) -> str:
        valid = {"stable", "tired", "needs_attention", "crisis"}
        return v if v in valid else "stable"

    @field_validator("presence_level")
    @classmethod
    def validate_presence_level(cls, v: str) -> str:
        valid = {"present", "normal", "retreating"}
        return v if v in valid else "normal"

    @field_validator("safety_flag")
    @classmethod
    def validate_safety_flag(cls, v: str) -> str:
        valid = {"none", "medical", "risk", "crisis"}
        return v if v in valid else "none"

    @field_validator("suggestions")
    @classmethod
    def validate_suggestions(cls, v: List[str]) -> List[str]:
        # 限制长度为 1-5
        return v[:5] if len(v) > 5 else v

    @field_validator("content_cards")
    @classmethod
    def validate_content_cards(cls, v: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        # 限制数量为 1-10
        return v[:10] if len(v) > 10 else v


# ==================== 校验结果 ====================

class ValidationResult:
    """
    Schema 校验结果

    Attributes:
        success: 是否校验成功
        data: 校验后的数据（已修复缺省值）
        errors: 校验错误列表
        warnings: 警告列表
        is_fallback: 是否使用了降级模式
    """
    def __init__(
        self,
        success: bool,
        data: Dict[str, Any],
        errors: List[str] = None,
        warnings: List[str] = None,
        is_fallback: bool = False,
    ):
        self.success = success
        self.data = data
        self.errors = errors or []
        self.warnings = warnings or []
        self.is_fallback = is_fallback

    def to_dict(self) -> Dict[str, Any]:
        return {
            "success": self.success,
            "data": self.data,
            "errors": self.errors,
            "warnings": self.warnings,
            "is_fallback": self.is_fallback,
        }


# ==================== Schema Validator ====================

class SchemaValidator:
    """
    Skill 输出 Schema 校验器

    核心职责：
    1. 解析 LLM 原始输出为 JSON
    2. 校验 JSON 结构是否符合 SkillOutput Schema
    3. 自动修复常见问题（缺省值、枚举值）
    4. 校验失败时降级为纯文本
    """

    def __init__(self):
        """初始化校验器"""
        self.total_validations = 0
        self.success_count = 0
        self.fallback_count = 0
        self.repair_count = 0

    def validate(self, raw_response: str) -> ValidationResult:
        """
        校验 LLM 原始输出

        Args:
            raw_response: LLM 返回的原始文本

        Returns:
            ValidationResult
        """
        self.total_validations += 1

        # Step 1: 尝试解析 JSON
        data = self._parse_json(raw_response)
        if data is None:
            # 解析失败，降级为纯文本
            return self._fallback(raw_response, ["JSON 解析失败"])

        # Step 2: Pydantic 校验
        try:
            validated = SkillOutput(**data)
            validated_data = validated.model_dump()

            # 处理 follow_up 嵌套
            if data.get("follow_up") and isinstance(data["follow_up"], dict):
                try:
                    fu = FollowUp(**data["follow_up"])
                    validated_data["follow_up"] = fu.model_dump()
                except Exception:
                    validated_data["follow_up"] = FollowUp().model_dump()

            # 处理 content_cards 嵌套
            validated_cards = []
            for card in validated_data.get("content_cards", []):
                if isinstance(card, dict):
                    try:
                        cc = ContentCard(**card)
                        validated_cards.append(cc.model_dump())
                    except Exception:
                        validated_cards.append(card)
            validated_data["content_cards"] = validated_cards

            # 检查是否进行了修复
            warnings = self._detect_repairs(data, validated_data)
            if warnings:
                self.repair_count += 1

            self.success_count += 1
            return ValidationResult(
                success=True,
                data=validated_data,
                warnings=warnings,
            )

        except Exception as e:
            # Pydantic 校验失败，尝试修复
            repaired = self._repair_data(data)
            if repaired:
                self.repair_count += 1
                try:
                    validated = SkillOutput(**repaired)
                    self.success_count += 1
                    return ValidationResult(
                        success=True,
                        data=validated.model_dump(),
                        warnings=["已自动修复部分字段"],
                    )
                except Exception as e2:
                    return self._fallback(raw_response, [f"校验失败: {e2}"])
            else:
                return self._fallback(raw_response, [f"校验失败: {e}"])

    def _parse_json(self, text: str) -> Optional[Dict[str, Any]]:
        """
        从文本中解析 JSON

        尝试多种策略：
        1. 直接解析
        2. 提取 JSON 块
        3. 修复常见 JSON 错误
        """
        if not text:
            return None

        # 策略 1: 直接解析
        try:
            result = json.loads(text.strip())
            if isinstance(result, dict):
                return result
        except (json.JSONDecodeError, TypeError):
            pass

        # 策略 2: 提取 JSON 块
        extracted = self._extract_json_block(text)
        if extracted:
            try:
                result = json.loads(extracted)
                if isinstance(result, dict):
                    return result
            except (json.JSONDecodeError, TypeError):
                pass

        # 策略 3: 修复 JSON
        fixed = self._fix_json_text(text)
        if fixed:
            try:
                result = json.loads(fixed)
                if isinstance(result, dict):
                    return result
            except (json.JSONDecodeError, TypeError):
                pass

        return None

    def _extract_json_block(self, text: str) -> Optional[str]:
        """从文本中提取 JSON 块"""
        # 尝试匹配 ```json ... ``` 代码块
        patterns = [
            r'```json\s*\n?([\s\S]*?)\n?```',  # ```json ... ```
            r'```\s*\n?([\s\S]*?)\n?```',        # ``` ... ```
            r'\{[\s\S]*\}',                        # { ... }
        ]

        for pattern in patterns:
            matches = re.findall(pattern, text)
            for match in matches:
                match = match.strip()
                if match.startswith('{'):
                    return match

        return None

    def _fix_json_text(self, text: str) -> Optional[str]:
        """修复常见 JSON 错误"""
        text = text.strip()

        # 移除 markdown 代码块标记
        text = re.sub(r'^```(?:json)?\s*', '', text)
        text = re.sub(r'\s*```$', '', text)

        # 修复尾部逗号
        text = re.sub(r',(\s*[}\]])', r'\1', text)

        # 修复单引号（简单场景）
        # 注意：不处理包含单引号的内容值
        text = re.sub(r"'([^']*)':", r'"\1":', text)   # 键
        text = re.sub(r":\s*'([^']*)'", r': "\1"', text)  # 值

        # 移除控制字符
        text = re.sub(r'[\x00-\x1f\x7f-\x9f]', ' ', text)

        # 移除注释
        text = re.sub(r'//.*?$', '', text, flags=re.MULTILINE)
        text = re.sub(r'/\*.*?\*/', '', text, flags=re.DOTALL)

        return text if text.strip() else None

    def _repair_data(self, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """
        修复数据使其符合 Schema

        策略：
        1. 确保必填字段存在
        2. 修正枚举值
        3. 修正数组长度
        """
        if not isinstance(data, dict):
            return None

        repaired = {}

        # 必填字段
        repaired["text"] = str(data.get("text", data.get("message", data.get("content", ""))))
        if not repaired["text"]:
            return None

        # 枚举值修复
        tone = data.get("tone", "gentle")
        repaired["tone"] = tone if tone in {"gentle", "warm", "encouraging"} else "gentle"

        care = data.get("care_status", "stable")
        repaired["care_status"] = care if care in {"stable", "tired", "needs_attention", "crisis"} else "stable"

        presence = data.get("presence_level", "normal")
        repaired["presence_level"] = presence if presence in {"present", "normal", "retreating"} else "normal"

        safety = data.get("safety_flag", "none")
        repaired["safety_flag"] = safety if safety in {"none", "medical", "risk", "crisis"} else "none"

        # 数组字段
        suggestions = data.get("suggestions", [])
        if isinstance(suggestions, list):
            repaired["suggestions"] = [str(s) for s in suggestions[:5]]
        else:
            repaired["suggestions"] = []

        content_cards = data.get("content_cards", [])
        if isinstance(content_cards, list):
            repaired["content_cards"] = content_cards[:10]
        else:
            repaired["content_cards"] = []

        # follow_up
        follow_up = data.get("follow_up")
        if isinstance(follow_up, dict):
            repaired["follow_up"] = {
                "in_days": follow_up.get("in_days", 2),
                "intent": str(follow_up.get("intent", "general_check")),
                "soft": follow_up.get("soft", True),
            }
        else:
            repaired["follow_up"] = None

        # 布尔字段
        repaired["offline_encouraged"] = bool(data.get("offline_encouraged", True))

        return repaired

    def _detect_repairs(
        self, original: Dict[str, Any], validated: Dict[str, Any]
    ) -> List[str]:
        """检测自动修复了哪些字段"""
        warnings = []

        # 检查枚举值修复
        for field in ["tone", "care_status", "presence_level", "safety_flag"]:
            orig = original.get(field)
            valid = validated.get(field)
            if orig and orig != valid:
                warnings.append(f"{field}: '{orig}' → '{valid}'")

        # 检查缺省值填充
        default_fields = {
            "tone": "gentle", "care_status": "stable",
            "presence_level": "normal", "safety_flag": "none",
        }
        for field, default in default_fields.items():
            if field not in original and validated.get(field) == default:
                warnings.append(f"{field}: 使用默认值 '{default}'")

        return warnings

    def _fallback(self, text: str, errors: List[str]) -> ValidationResult:
        """降级为纯文本"""
        self.fallback_count += 1

        # 清理文本
        text = text.strip()
        text = re.sub(r'^```.*?\n', '', text)
        text = re.sub(r'\n```$', '', text)
        text = text.strip()

        if len(text) > 2000:
            text = text[:2000] + "..."

        return ValidationResult(
            success=False,
            data={
                "text": text,
                "tone": "gentle",
                "care_status": "stable",
                "suggestions": [],
                "content_cards": [],
                "follow_up": None,
                "presence_level": "normal",
                "safety_flag": "none",
                "offline_encouraged": True,
                "_fallback": True,
            },
            errors=errors,
            warnings=["已降级为纯文本模式"],
            is_fallback=True,
        )

    def get_stats(self) -> Dict[str, Any]:
        """获取校验统计"""
        total = max(self.total_validations, 1)
        return {
            "total_validations": self.total_validations,
            "success_count": self.success_count,
            "fallback_count": self.fallback_count,
            "repair_count": self.repair_count,
            "success_rate": round(self.success_count / total * 100, 1),
            "fallback_rate": round(self.fallback_count / total * 100, 1),
            "repair_rate": round(self.repair_count / total * 100, 1),
        }


# ==================== 全局实例 ====================

schema_validator = SchemaValidator()


# ==================== 使用示例 ====================

def demo_validator():
    """演示 Schema Validator"""
    validator = SchemaValidator()

    print("=" * 60)
    print("顺时 Schema Validator 演示")
    print("=" * 60)

    # 正常 JSON
    test1 = '{"text": "建议你喝点菊花茶", "tone": "warm", "care_status": "stable"}'
    result1 = validator.validate(test1)
    print(f"\n[正常 JSON] 成功: {result1.success}")
    print(f"  data: {result1.data}")

    # 带 Markdown 代码块
    test2 = '''```json
{
    "text": "今天适合泡脚",
    "tone": "gentle",
    "care_status": "tired",
    "suggestions": ["泡脚", "早睡"],
    "follow_up": {"in_days": 2, "intent": "sleep_check"}
}
```'''
    result2 = validator.validate(test2)
    print(f"\n[Markdown 代码块] 成功: {result2.success}")
    print(f"  warnings: {result2.warnings}")

    # 非法枚举值
    test3 = '{"text": "测试", "tone": "angry", "care_status": "unknown"}'
    result3 = validator.validate(test3)
    print(f"\n[非法枚举] 成功: {result3.success}")
    print(f"  warnings: {result3.warnings}")
    print(f"  tone: {result3.data['tone']}")

    # 纯文本降级
    test4 = "这不是JSON，只是普通文本回复"
    result4 = validator.validate(test4)
    print(f"\n[纯文本] 成功: {result4.success}")
    print(f"  is_fallback: {result4.is_fallback}")
    print(f"  text: {result4.data['text'][:50]}")

    print(f"\n[统计] {validator.get_stats()}")


if __name__ == "__main__":
    demo_validator()
