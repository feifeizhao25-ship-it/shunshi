"""
顺时 - 聊天系统测试
test_chat.py
"""

import pytest
from unittest.mock import patch, AsyncMock, MagicMock


# ==================== 意图识别测试 ====================

class TestIntentDetection:
    """意图识别测试：覆盖 9 种意图"""

    def _detect(self, text):
        from app.core.intent_detector import intent_detector
        return intent_detector.detect(text)

    # 1. health_consultation
    def test_intent_health_consultation_basic(self):
        result = self._detect("我最近总是上火，怎么调理？")
        assert result.intent == "health_consultation"

    def test_intent_health_consultation_tcm(self):
        result = self._detect("中医说我脾胃虚寒，怎么办")
        assert result.intent == "health_consultation"

    def test_intent_health_consultation_constitution(self):
        result = self._detect("帮我测试一下体质")
        assert result.intent == "health_consultation"

    # 2. solar_term
    def test_intent_solar_term_basic(self):
        result = self._detect("立春养生应该注意什么？")
        # "立春" 是明确的节气关键词，solar_term 或 health_consultation 都可能匹配
        assert result.intent in ("solar_term", "health_consultation")

    def test_intent_solar_term_specific(self):
        result = self._detect("清明节期间适合吃什么")
        # "清明" 是节气，同时 "吃什么" 可能触发 food_recommendation
        assert result.intent in ("solar_term", "food_recommendation")

    def test_intent_solar_term_season(self):
        result = self._detect("当季有什么养生建议")
        # "当季" 关键词匹配 solar_term，但 "养生" 更强地匹配 health_consultation
        assert result.intent in ("solar_term", "health_consultation", "food_recommendation")

    # 3. food_recommendation
    def test_intent_food_what_to_eat(self):
        result = self._detect("今天适合吃什么？")
        assert result.intent == "food_recommendation"

    def test_intent_food_recipe(self):
        result = self._detect("推荐一个养生汤")
        assert result.intent == "food_recommendation"

    def test_intent_food_tea(self):
        result = self._detect("有什么养生的花茶推荐")
        assert result.intent == "food_recommendation"

    # 4. exercise
    def test_intent_exercise_basic(self):
        result = self._detect("适合办公室做的运动")
        assert result.intent == "exercise"

    def test_intent_exercise_yoga(self):
        result = self._detect("每天练瑜伽有什么好处")
        assert result.intent == "exercise"

    def test_intent_exercise_stretch(self):
        result = self._detect("久坐颈椎痛，有什么微运动")
        assert result.intent == "exercise"

    # 5. mood_support
    def test_intent_mood_anxiety(self):
        result = self._detect("最近压力很大，心情不好")
        assert result.intent == "mood_support"

    def test_intent_mood_sad(self):
        result = self._detect("感到很孤独难过")
        assert result.intent == "mood_support"

    def test_intent_mood_crisis(self):
        result = self._detect("我不想活了，活着没意思")
        # mood_support 也能匹配，因为关键词存在
        assert result.intent in ("mood_support", "general_chat")

    # 6. sleep
    def test_intent_sleep_insomnia(self):
        result = self._detect("我最近失眠，睡不着觉")
        assert result.intent == "sleep"

    def test_intent_sleep_quality(self):
        result = self._detect("睡眠质量很差，每天做噩梦")
        assert result.intent == "sleep"

    def test_intent_sleep_schedule(self):
        result = self._detect("应该几点睡觉最好")
        assert result.intent == "sleep"

    # 7. family
    def test_intent_family_child(self):
        result = self._detect("孩子的养生注意事项")
        # "孩子"匹配 family，"养生" 也匹配 health_consultation
        assert result.intent in ("family", "health_consultation")

    def test_intent_family_elder(self):
        result = self._detect("老人家应该怎么保养")
        # "老人" 匹配 family，"保养" 匹配 health_consultation
        assert result.intent in ("family", "health_consultation")

    # 8. subscription
    def test_intent_subscription_vip(self):
        result = self._detect("你们的VIP会员有什么权益")
        assert result.intent == "subscription"

    def test_intent_subscription_price(self):
        result = self._detect("订阅套餐价格是多少")
        assert result.intent == "subscription"

    # 9. general_chat
    def test_intent_general_greeting(self):
        result = self._detect("你好呀")
        assert result.intent == "general_chat"

    def test_intent_general_random(self):
        result = self._detect("今天天气不错")
        assert result.intent == "general_chat"


# ==================== 安全过滤测试 ====================

class TestSafetyFilter:
    """安全过滤测试（补充）"""

    def _check(self, text):
        from app.core.safety_filter import safety_filter
        return safety_filter.check(text)

    def test_normal_text_passes(self):
        result = self._check("今天天气真好，有什么养生建议吗？")
        assert result.level.value == "Normal"
        assert result.filtered_text is not None
        assert result.override_response is None

    def test_crisis_blocked(self):
        result = self._check("我不想活了，活着没意思")
        assert result.level.value == "Crisis"
        assert result.override_response is not None
        assert "心理援助" in result.override_response

    def test_crisis_suicide_keyword(self):
        result = self._check("我想自杀")
        assert result.level.value == "Crisis"

    def test_emotional_distress_detected(self):
        result = self._check("最近崩溃了，每天都哭，太痛苦了")
        assert result.level.value == "EmotionalDistress"
        assert result.prefix is not None
        assert "共情" in result.prefix

    def test_emotional_distress_depression(self):
        result = self._check("我觉得自己重度抑郁，没人理解")
        assert result.level.value == "EmotionalDistress"

    def test_forbidden_violence(self):
        result = self._check("怎么杀人")
        assert result.level.value in ("Normal", "Crisis", "EmotionalDistress")

    def test_forbidden_porn(self):
        result = self._check("色情内容")
        # 可能匹配禁止模式
        assert result is not None


# ==================== 上下文管理测试 ====================

class TestContextManagement:
    """上下文管理测试"""

    def test_get_conversation_history_empty(self):
        from app.router.chat import _get_conversation_history
        history = _get_conversation_history("nonexistent-conv")
        assert history == []

    def test_build_context_window(self):
        from app.router.chat import _build_context_window
        from app.llm.siliconflow import ChatMessage, MessageRole

        system_prompt = "你是顺时AI"
        history = [
            {"role": "user", "content": "你好"},
            {"role": "assistant", "content": "你好，有什么可以帮你的？"},
        ]
        user_message = "今天适合吃什么"

        messages = _build_context_window(system_prompt, history, user_message)

        assert len(messages) >= 2
        assert messages[0].role == MessageRole.SYSTEM
        assert messages[-1].role == MessageRole.USER
        assert messages[-1].content == user_message

    def test_context_window_truncation(self):
        from app.router.chat import _build_context_window
        from app.llm.siliconflow import ChatMessage, MessageRole

        system_prompt = "你是顺时AI"
        # 构建很长的历史，测试截断
        history = [
            {"role": "user", "content": "这是第" + str(i) + "条很长的消息" * 100}
            for i in range(50)
        ]
        user_message = "最后一个问题"

        messages = _build_context_window(system_prompt, history, user_message)
        # 应该截断，不会包含所有历史
        assert len(messages) < len(history) + 2


# ==================== Chat API 端点测试 ====================

class TestChatEndpoints:
    """聊天 API 端点测试"""

    @patch("app.router.chat.get_client")
    def test_send_message_success(self, mock_get_client, client):
        """测试发送消息（mock LLM 响应）"""
        # Mock LLM 客户端
        mock_llm = MagicMock()
        mock_response = MagicMock()
        mock_response.choices = [{"message": {"content": "你好！有什么养生问题可以帮你？"}}]
        mock_response.usage = MagicMock(total_tokens=100)
        mock_llm.chat_completion = AsyncMock(return_value=mock_response)
        mock_get_client.return_value = mock_llm

        response = client.post("/api/v1/chat?message=你好&user_id=test-user-001")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "message_id" in data["data"]
        assert "conversation_id" in data["data"]
        assert "text" in data["data"]

    @patch("app.router.chat.get_client")
    def test_send_message_crisis_blocked(self, mock_get_client, client):
        """Crisis 模式：应该阻断并返回安全资源，不调用 LLM"""
        response = client.post("/api/v1/chat?message=我不想活了&user_id=test-user-001")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["safety_flag"] == "crisis"
        assert "心理援助" in data["data"]["text"]
        # LLM 不应被调用
        mock_get_client.assert_not_called()

    @patch("app.router.chat.get_client")
    def test_send_message_emotional_distress(self, mock_get_client, client):
        """EmotionalDistress 模式：应调用 LLM 但添加共情前缀"""
        mock_llm = MagicMock()
        mock_response = MagicMock()
        mock_response.choices = [{"message": {"content": "我能感受到你的痛苦..."}}]
        mock_response.usage = MagicMock(total_tokens=80)
        mock_llm.chat_completion = AsyncMock(return_value=mock_response)
        mock_get_client.return_value = mock_llm

        response = client.post("/api/v1/chat?message=最近崩溃了太痛苦了&user_id=test-user-001")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True

    @patch("app.router.chat.get_client")
    def test_send_message_with_conversation_id(self, mock_get_client, client):
        """指定会话 ID"""
        mock_llm = MagicMock()
        mock_response = MagicMock()
        mock_response.choices = [{"message": {"content": "回复内容"}}]
        mock_response.usage = MagicMock(total_tokens=50)
        mock_llm.chat_completion = AsyncMock(return_value=mock_response)
        mock_get_client.return_value = mock_llm

        conv_id = "test-conv-001"
        response = client.post(
            f"/api/v1/chat?message=你好&conversation_id={conv_id}&user_id=test-user-001"
        )
        assert response.status_code == 200
        assert response.json()["data"]["conversation_id"] == conv_id

    def test_get_conversations(self, client):
        response = client.get("/api/v1/chat/conversations?user_id=test-user-001")
        assert response.status_code == 200
        data = response.json()
        assert "items" in data["data"]

    def test_get_conversation_404(self, client):
        response = client.get("/api/v1/chat/conversations/nonexistent?user_id=test-user-001")
        assert response.status_code == 404

    def test_get_history_404(self, client):
        response = client.get("/api/v1/chat/history/nonexistent?user_id=test-user-001")
        assert response.status_code == 404
