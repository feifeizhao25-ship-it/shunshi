"""
顺时 Prompt Registry
Prompt 版本管理系统

功能：
- Prompt 版本化管理
- 灰度发布
- 回滚支持
- 动态加载

作者: Claw 🦅
日期: 2026-03-09
"""

from typing import Dict, List, Optional, Any
from datetime import datetime
from enum import Enum
import logging

logger = logging.getLogger(__name__)


class PromptType(str, Enum):
    """Prompt 类型"""
    CORE = "core"           # 核心提示词
    POLICY = "policy"       # 策略提示词
    TASK = "task"           # 任务提示词
    SKILL = "skill"         # Skill 提示词
    SYSTEM = "system"       # 系统提示词


class PromptStatus(str, Enum):
    """Prompt 状态"""
    DRAFT = "draft"         # 草稿
    ACTIVE = "active"       # 生效中
    DEPRECATED = "deprecated"  # 已废弃
    ROLLED_BACK = "rolled_back"  # 已回滚


class PromptVersion:
    """Prompt 版本"""
    def __init__(
        self,
        version: str,
        content: str,
        author: str = "system",
        changelog: str = "",
    ):
        self.version = version
        self.content = content
        self.author = author
        self.changelog = changelog
        self.created_at = datetime.now()
        self.status = PromptStatus.DRAFT


class PromptEntry:
    """Prompt 条目"""
    def __init__(
        self,
        name: str,
        prompt_type: PromptType,
        description: str = "",
    ):
        self.name = name
        self.prompt_type = prompt_type
        self.description = description
        self.versions: Dict[str, PromptVersion] = {}
        self.active_version: Optional[str] = None
    
    def add_version(
        self,
        version: str,
        content: str,
        author: str = "system",
        changelog: str = "",
        activate: bool = False,
    ) -> None:
        """添加版本"""
        self.versions[version] = PromptVersion(
            version=version,
            content=content,
            author=author,
            changelog=changelog,
        )
        
        if activate or not self.active_version:
            self.activate_version(version)
        
        logger.info(f"[PromptRegistry] 添加版本: {self.name} v{version}")
    
    def activate_version(self, version: str) -> bool:
        """激活版本"""
        if version not in self.versions:
            logger.warning(f"[PromptRegistry] 版本不存在: {version}")
            return False
        
        # 旧版本废止
        if self.active_version and self.active_version in self.versions:
            self.versions[self.active_version].status = PromptStatus.DEPRECATED
        
        self.active_version = version
        self.versions[version].status = PromptStatus.ACTIVE
        logger.info(f"[PromptRegistry] 激活版本: {self.name} v{version}")
        return True
    
    def get_active(self) -> Optional[str]:
        """获取当前激活版本内容"""
        if not self.active_version:
            return None
        version = self.versions.get(self.active_version)
        if version:
            return version.content
        return None
    
    def rollback(self, target_version: str) -> bool:
        """回滚版本"""
        if target_version not in self.versions:
            return False
        
        self.activate_version(target_version)
        self.versions[target_version].status = PromptStatus.ROLLED_BACK
        logger.info(f"[PromptRegistry] 回滚: {self.name} → v{target_version}")
        return True


class PromptRegistry:
    """
    顺时 Prompt 注册表
    
    管理所有 Prompt 的版本化
    """
    
    def __init__(self):
        self.prompts: Dict[str, PromptEntry] = {}
        self._init_default_prompts()
    
    def _init_default_prompts(self) -> None:
        """初始化默认 Prompts"""
        
        # Core Prompt - 核心提示词
        core = PromptEntry("core", PromptType.CORE, "AI 核心行为定义")
        core.add_version(
            "v1",
            """你是顺时，一个温暖贴心的 AI 养生健康陪伴助手。

你的核心特质：
- 温暖、专业、有耐心
- 永远把用户健康放在第一位
- 回答简洁实用，不说教

你必须遵守：
- 不做疾病诊断
- 不推荐药物
- 不解释体检报告
- 不给医疗建议

你可以做的：
- 提供养生知识
- 分享食疗方法
- 讲解节气养生
- 给予情绪支持
- 给出睡眠/运动建议

永远记住：用户来找你，是想要一份温暖和陪伴。""",
            author="feifei",
            changelog="初始版本",
            activate=True,
        )
        self.prompts["core"] = core
        
        # Policy Prompt - 安全策略
        policy = PromptEntry("policy", PromptType.POLICY, "安全策略定义")
        policy.add_version(
            "v1",
            """# 安全边界规则

## 禁止行为 (必须拒绝)
- 疾病诊断：「你可能是XX病」
- 药物推荐：「吃XX药」
- 医疗建议：「去医院做XX检查」
- 体检报告解读：「你的报告显示...」
- 偏方建议：「民间偏方说...」

## 允许行为 (可以回答)
- 养生知识：「春季养肝多吃青色食物」
- 生活方式：「建议规律作息」
- 食疗推荐：「可以喝点红枣桂圆茶」
- 情绪支持：「我理解你的感受」
- 就医引导：「建议咨询专业医生」

## 响应模板
当遇到医疗相关问题：
1. 表达理解
2. 提供一般养生建议
3. 建议咨询专业医生
4. 保持温暖语气""",
            author="feifei",
            changelog="安全规则 v1",
            activate=True,
        )
        self.prompts["policy"] = policy
        
        # Skill Prompts
        solar_term = PromptEntry(
            "skill_solar_term", 
            PromptType.SKILL, 
            "节气养生 Skill"
        )
        solar_term.add_version(
            "v1",
            """# 节气养生 Skill

当前节气：{current_solar_term}
日期：{current_date}

## 节气特点
- 气候特征：{climate_features}
- 养生重点：{health_focus}

## 养生建议
### 饮食
{food_suggestions}

### 起居
{living_suggestions}

### 运动
{exercise_suggestions}

### 情志
{emotion_suggestions}

## 今日养生要点
{highlights}""",
            author="system",
            changelog="节气养生模板",
            activate=True,
        )
        self.prompts["skill_solar_term"] = solar_term
        
        # Food Tea Recommender
        food_tea = PromptEntry(
            "skill_food_tea",
            PromptType.SKILL,
            "食疗茶饮 Skill"
        )
        food_tea.add_version(
            "v1",
            """# 食疗茶饮推荐 Skill

用户体质：{constitution}
当前季节：{season}
场景：{scenario}

## 推荐原则
- 因人制宜
- 因时制宜
- 食药同源

## 推荐方案

### 食疗方
{name}
{description}
{ingredients}
{instructions}

### 茶饮方
{tea_name}
{tea_description}
{tea_ingredients}
{tea_preparation}

## 注意事项
{cautions}""",
            author="system",
            changelog="食疗推荐模板",
            activate=True,
        )
        self.prompts["skill_food_tea"] = food_tea
        
        # Emotion Support
        emotion = PromptEntry(
            "skill_emotion",
            PromptType.SKILL,
            "情绪支持 Skill"
        )
        emotion.add_version(
            "v1",
            """# 情绪支持 Skill

用户情绪：{emotion_type}
情绪强度：{intensity}
背景：{background}

## 支持策略
1. **共情回应** - 表达理解和接纳
2. **情绪确认** - 认可感受的合理性
3. **温暖陪伴** - 给予情感支持
4. **实用建议** - 给出可执行的小建议

## 回应要点
- 避免说教
- 不急于解决问题
- 保持温暖语调
- 给出1-2个可执行建议

## 跟进建议
{followup_suggestions}""",
            author="system",
            changelog="情绪支持模板",
            activate=True,
        )
        self.prompts["skill_emotion"] = emotion
    
    def get(self, name: str) -> Optional[str]:
        """获取 Prompt"""
        if name in self.prompts:
            return self.prompts[name].get_active()
        return None
    
    def get_with_metadata(self, name: str) -> Optional[Dict[str, Any]]:
        """获取 Prompt 及元数据"""
        if name not in self.prompts:
            return None
        
        entry = self.prompts[name]
        active_content = entry.get_active()
        
        if not active_content:
            return None
        
        return {
            "name": entry.name,
            "type": entry.prompt_type,
            "description": entry.description,
            "active_version": entry.active_version,
            "content": active_content,
            "versions": [
                {
                    "version": v.version,
                    "status": v.status,
                    "author": v.author,
                    "changelog": v.changelog,
                    "created_at": v.created_at.isoformat(),
                }
                for v in entry.versions.values()
            ],
        }
    
    def list_prompts(self) -> List[Dict[str, Any]]:
        """列出所有 Prompts"""
        return [
            {
                "name": entry.name,
                "type": entry.prompt_type,
                "description": entry.description,
                "active_version": entry.active_version,
                "versions_count": len(entry.versions),
            }
            for entry in self.prompts.values()
        ]
    
    def update(
        self,
        name: str,
        version: str,
        content: str,
        changelog: str = "",
        activate: bool = False,
    ) -> bool:
        """更新 Prompt"""
        if name not in self.prompts:
            logger.warning(f"[PromptRegistry] Prompt 不存在: {name}")
            return False
        
        self.prompts[name].add_version(
            version, content, changelog=changelog, activate=activate
        )
        return True


# ==================== 全局实例 ====================

prompt_registry = PromptRegistry()


# ==================== 使用示例 ====================

def demo_prompt_registry():
    """演示 Prompt Registry"""
    registry = PromptRegistry()
    
    print("=" * 60)
    print("顺时 Prompt Registry 演示")
    print("=" * 60)
    
    # 列出所有 Prompts
    print("\n[所有 Prompts]")
    for p in registry.list_prompts():
        print(f"  - {p['name']} ({p['type']}) v{p['active_version']}")
    
    # 获取 Core Prompt
    print("\n[Core Prompt 前100字]")
    core = registry.get("core")
    if core:
        print(core[:100] + "...")
    
    # 获取带元数据
    print("\n[Emotion Skill 详情]")
    emotion = registry.get_with_metadata("skill_emotion")
    if emotion:
        print(f"  Name: {emotion['name']}")
        print(f"  Type: {emotion['type']}")
        print(f"  Active Version: {emotion['active_version']}")
        print(f"  Versions: {emotion['versions_count']}")


if __name__ == "__main__":
    demo_prompt_registry()
