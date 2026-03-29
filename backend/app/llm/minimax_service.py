"""
MiniMax M2.7 (多模态大模型) 集成服务
支持：文本对话、内容生成、知识问答、多模态理解
文档: https://www.minimaxi.com/document
"""
import os
import json
import httpx
from typing import Optional

# ── MiniMax Native API ──────────────────────────────────────────────────────────
class MiniMaxService:
    """MiniMax M2.7 官方 API 服务"""
    
    BASE_URL = "https://api.minimax.chat/v1"
    
    def __init__(self, api_key: str = None):
        self.api_key = api_key or os.getenv("MINIMAX_API_KEY", "")
        self.model = "MiniMax-M2.7"
    
    def chat(
        self,
        messages: list,
        temperature: float = 0.7,
        max_tokens: int = 4096,
        stream: bool = False,
        **kwargs
    ) -> dict | str:
        """
        通用对话接口（与 OpenAI chat completions 兼容）
        支持 MiniMax M2.7 自我进化能力
        """
        if not self.api_key:
            return self._fallback_response(messages)

        payload = {
            "model": self.model,
            "messages": messages,
            "temperature": temperature,
            "max_tokens": max_tokens,
            "stream": stream,
        }
        if kwargs.get("top_p"):
            payload["top_p"] = kwargs["top_p"]

        try:
            with httpx.Client(timeout=60.0) as client:
                resp = client.post(
                    f"{self.BASE_URL}/chat/completions",
                    json=payload,
                    headers={
                        "Authorization": f"Bearer {self.api_key}",
                        "Content-Type": "application/json",
                    },
                )
                resp.raise_for_status()
                result = resp.json()

                if stream:
                    return result  # SSE stream response
                return result["choices"][0]["message"]["content"]
        except Exception as e:
            return self._fallback_response(messages, str(e))

    def _fallback_response(self, messages: list, error: str = None) -> str:
        """无可用 API Key 时的降级响应"""
        if error:
            return f"[MiniMax M2.7 暂时不可用: {error}]"
        return "[请配置 MINIMAX_API_KEY 以启用 MiniMax M2.7]"

    def image_understanding(self, image_url: str, prompt: str) -> str:
        """多模态：图像理解（M2.7 支持）"""
        if not self.api_key:
            return "[请配置 MINIMAX_API_KEY]"
        
        payload = {
            "model": self.model,
            "messages": [
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": prompt},
                        {"type": "image_url", "image_url": {"url": image_url}},
                    ],
                }
            ],
            "max_tokens": 1024,
        }
        try:
            with httpx.Client(timeout=30.0) as client:
                resp = client.post(
                    f"{self.BASE_URL}/chat/completions",
                    json=payload,
                    headers={"Authorization": f"Bearer {self.api_key}"},
                )
                resp.raise_for_status()
                return resp.json()["choices"][0]["message"]["content"]
        except Exception as e:
            return f"[图像理解失败: {e}]"

    def health_advisor(self, constitution_type: str, question: str, context: dict = None) -> str:
        """健康咨询专用提示词（顺时产品核心功能）"""
        system_prompt = f"""你是中医健康顾问助手，专注于体质调理和健康养生。
当前用户体质类型：{constitution_type}
参考知识：
- 气虚(qixu): 易疲乏、气短懒言，宜食用黄芪、人参、山药
- 阳虚(yangxu): 手足不温、畏寒，宜食用羊肉、桂圆、生姜
- 阴虚(yinxu): 口燥咽干、手足心热，宜食用银耳、百合、雪梨
- 痰湿(tanshi): 形体肥胖、口黏腻，宜食用薏米、赤小豆、冬瓜
- 湿热(shire): 面垢油光、口苦，宜食用绿豆、苦瓜、冬瓜
- 血瘀(xueyu): 肤色晦暗、瘀斑，宜食用山楂、红花、玫瑰花
- 气郁(qiyu): 神情抑郁、忧虑，宜食用玫瑰花茶、佛手
- 特禀(tebing): 过敏体质，避免过敏原，多食健脾益气食物

请根据用户体质类型，结合中医理论回答健康问题。
回答要科学、温和，提供具体的食疗、茶饮、运动建议。"""

        messages = [{"role": "system", "content": system_prompt}]
        if context:
            messages.append({
                "role": "user",
                "content": f"我的健康状况：{context.get('health_status', '良好')}\n问题：{question}"
            })
        else:
            messages.append({"role": "user", "content": question})

        return self.chat(messages, temperature=0.7)

    def content_generator(self, topic: str, content_type: str, style: str = "professional") -> str:
        """内容生成（ContentFlow 分发侠产品用）"""
        prompts = {
            "health_article": f"请生成一篇关于「{topic}」的健康科普文章，要求科学严谨、通俗易懂。",
            "social_post": f"请生成一条关于「{topic}」的社交媒体推文，语言活泼简洁，适合公众号传播。",
            "video_script": f"请生成「{topic}」的短视频脚本，时长约60秒，包含开场、核心内容、结尾号召。",
        }
        prompt = prompts.get(content_type, f"请生成关于「{topic}」的内容")
        return self.chat([{"role": "user", "content": prompt}])


# ── 全局实例 ───────────────────────────────────────────────────────────────────
minimax_service = MiniMaxService()
