# AI Schema 验证与降级服务

import json
import re
from typing import Dict, Any, Optional
from pydantic import BaseModel, ValidationError

class AIResponseSchema(BaseModel):
    """标准 AI 响应 Schema"""
    text: str
    tone: str = "gentle"
    care_status: str = "stable"
    follow_up: Optional[Dict[str, Any]] = None
    offline_encouraged: bool = True
    presence_level: str = "normal"
    safety_flag: str = "none"

class SchemaValidator:
    """Schema 验证与降级处理器"""
    
    def __init__(self):
        self.validation_attempts = 0
        self.fallback_count = 0
    
    def validate_and_parse(self, raw_response: str) -> Dict[str, Any]:
        """
        验证并解析 AI 响应
        失败时自动降级
        """
        self.validation_attempts += 1
        
        # 尝试 1: 直接 JSON 解析
        try:
            data = json.loads(raw_response)
            return self._validate_schema(data)
        except json.JSONDecodeError:
            pass
        
        # 尝试 2: 提取 JSON
        try:
            data = self._extract_json(raw_response)
            return self._validate_schema(data)
        except Exception:
            pass
        
        # 尝试 3: 修复常见 JSON 错误
        try:
            data = self._fix_json(raw_response)
            return self._validate_schema(data)
        except Exception:
            pass
        
        # 降级: 纯文本
        self.fallback_count += 1
        return self._fallback_to_text(raw_response)
    
    def _extract_json(self, text: str) -> Dict[str, Any]:
        """从文本中提取 JSON"""
        # 查找 JSON 块
        patterns = [
            r'\{[^{}]*\}',  # 简单对象
            r'\{.*\}',      # 贪婪匹配
        ]
        
        for pattern in patterns:
            matches = re.findall(pattern, text, re.DOTALL)
            for match in matches:
                try:
                    return json.loads(match)
                except:
                    continue
        
        # 最后尝试: 整个文本作为 JSON
        return json.loads(text)
    
    def _fix_json(self, text: str) -> Dict[str, Any]:
        """修复常见 JSON 错误"""
        # 移除可能的 markdown 代码块
        text = re.sub(r'^```json\s*', '', text)
        text = re.sub(r'^```\s*', '', text)
        text = re.sub(r'\s*```$', '', text)
        
        # 修复尾部逗号
        text = re.sub(r',(\s*[}\]])', r'\1', text)
        
        # 修复单引号
        text = text.replace("'", '"')
        
        # 移除控制字符
        text = re.sub(r'[\x00-\x1f\x7f-\x9f]', '', text)
        
        return json.loads(text)
    
    def _validate_schema(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """验证 Schema"""
        try:
            validated = AIResponseSchema(**data)
            return validated.model_dump()
        except ValidationError as e:
            # 尝试部分验证
            return self._partial_validate(data)
    
    def _partial_validate(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """部分验证 - 保留有效字段"""
        result = {
            "text": data.get("text", data.get("message", str(data))),
            "tone": data.get("tone", "gentle"),
            "care_status": data.get("care_status", "stable"),
            "follow_up": data.get("follow_up"),
            "offline_encouraged": data.get("offline_encouraged", True),
            "presence_level": data.get("presence_level", "normal"),
            "safety_flag": data.get("safety_flag", "none")
        }
        return result
    
    def _fallback_to_text(self, text: str) -> Dict[str, Any]:
        """降级为纯文本"""
        # 清理文本
        text = text.strip()
        text = re.sub(r'^```.*\n', '', text)
        text = re.sub(r'\n```$', '', text)
        
        # 限制长度
        if len(text) > 2000:
            text = text[:2000] + "..."
        
        return {
            "text": text,
            "tone": "gentle",
            "care_status": "stable",
            "follow_up": None,
            "offline_encouraged": True,
            "presence_level": "normal",
            "safety_flag": "none",
            "_fallback": True
        }
    
    def get_stats(self) -> Dict[str, int]:
        """获取验证统计"""
        return {
            "total_attempts": self.validation_attempts,
            "fallback_count": self.fallback_count,
            "success_rate": (
                (self.validation_attempts - self.fallback_count) / 
                max(self.validation_attempts, 1) * 100
            )
        }


class PresenceLevelHandler:
    """Presence Level 处理器"""
    
    LEVELS = {
        "normal": {
            "description": "用户正常在线",
            "follow_up_delay": 0,
            "notification": False
        },
        "away": {
            "description": "用户离开",
            "follow_up_delay": 3600,  # 1小时后
            "notification": False
        },
        "busy": {
            "description": "用户忙碌",
            "follow_up_delay": 7200,  # 2小时后
            "notification": True
        },
        "offline": {
            "description": "用户离线",
            "follow_up_delay": 86400,  # 1天后
            "notification": True
        }
    }
    
    @classmethod
    def get_config(cls, level: str) -> Dict[str, Any]:
        """获取级别配置"""
        return cls.LEVELS.get(level, cls.LEVELS["normal"])
    
    @classmethod
    def should_send_notification(cls, level: str) -> bool:
        """是否应该发送通知"""
        return cls.get_config(level).get("notification", False)
    
    @classmethod
    def get_follow_up_delay(cls, level: str) -> int:
        """获取 Follow-up 延迟时间(秒)"""
        return cls.get_config(level).get("follow_up_delay", 0)
    
    @classmethod
    def determine_level(cls, user_activity: Dict[str, Any]) -> str:
        """根据用户活动确定级别"""
        # 基于最后活跃时间
        last_active = user_activity.get("last_active_at")
        if not last_active:
            return "normal"
        
        from datetime import datetime, timedelta
        try:
            last = datetime.fromisoformat(last_active)
            now = datetime.now()
            diff = (now - last).total_seconds()
            
            if diff < 300:  # 5分钟内
                return "normal"
            elif diff < 1800:  # 30分钟内
                return "away"
            elif diff < 3600:  # 1小时内
                return "busy"
            else:
                return "offline"
        except:
            return "normal"


# 全局实例
schema_validator = SchemaValidator()
