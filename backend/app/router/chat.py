# 聊天 API 路由
from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel
from typing import List, Optional, Dict
from datetime import datetime
import random
import uuid
import logging

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/chat", tags=["聊天"])

# ============ LLM & Intent & Safety ============

from app.llm.siliconflow import (
    SiliconFlowClient, ChatMessage, MessageRole, get_client,
)
from app.router.config import UserTier, RoutingContext
from app.router.router import ModelRouter
from app.llm.fallback import (
    ModelFallbackChain,
    get_fallback_chain,
    FallbackResult,
    FALLBACK_TEMPLATES,
)
from app.prompts.registry import prompt_registry
from app.prompts.store import prompt_store
from app.core.intent_detector import intent_detector, INTENT_SYSTEM_PROMPTS
from app.core.safety_filter import safety_filter as _legacy_safety_filter, SafetyLevel as _LegacySafetyLevel
# 优先使用新的 SafetyGuard 模块
from app.safety.guard import safety_guard, SafetyLevel, SafetyResult
from app.skills.executor import init_skill_executor
from app.services.response_parser import parse_ai_response
from app.services.presence_level import calculate_presence_level

# 模型路由器
model_router = ModelRouter()

# ============ In-memory storage ============

conversations_db = {}
messages_db = {}

# ============ Context Management ============

MAX_HISTORY_MESSAGES = 10
MAX_CONTEXT_CHARS = 8000  # 简单的字符数限制


def _get_conversation_history(conversation_id: str) -> List[Dict]:
    """获取最近 N 条对话历史"""
    if conversation_id not in conversations_db:
        return []
    
    conv = conversations_db[conversation_id]
    all_messages = conv.get("messages", [])
    # 取最近 N 条
    recent = all_messages[-MAX_HISTORY_MESSAGES:]
    return [
        {"role": msg["role"], "content": msg["content"]}
        for msg in recent
    ]


def _build_context_window(
    system_prompt: str,
    history: List[Dict],
    user_message: str,
) -> List[ChatMessage]:
    """
    构建上下文窗口
    
    system_prompt + history + user_message
    通过字符数控制总量
    """
    messages = [ChatMessage(role=MessageRole.SYSTEM, content=system_prompt)]
    
    total_chars = len(system_prompt)
    user_chars = len(user_message)
    
    # 从最近的 history 开始倒序加入，控制总字符数
    remaining = MAX_CONTEXT_CHARS - user_chars - 500  # 500 buffer
    
    for msg in reversed(history):
        msg_chars = len(msg["content"])
        if total_chars + msg_chars > remaining:
            break
        messages.insert(1, ChatMessage(
            role=MessageRole.SYSTEM if msg["role"] == "system" else MessageRole(msg["role"]),
            content=msg["content"],
        ))
        total_chars += msg_chars
    
    messages.append(ChatMessage(role=MessageRole.USER, content=user_message))
    return messages


# ============ AI Response Templates (fallback) ============

AI_RESPONSES = {
    "greeting": [
        "你好！有什么养生问题我可以帮你解答吗？",
        "早上好！今天想聊些什么呢？",
        "你好！让我们一起探索养生的奥秘吧~"
    ],
    "tired": [
        "今天辛苦了，适当休息对身体很重要哦~建议喝杯温热的红枣枸杞茶，补气养血。",
        "感到疲惫时，建议给自己泡一杯温热的菊花茶，缓解一下疲劳。",
        "劳累的时候，记得深呼吸几次，让自己的身体放松下来。"
    ],
    "sleep": [
        "良好的睡眠是养生的基础。建议睡前泡泡脚（水温40°C左右，15-20分钟），有助于睡眠质量的提升。",
        "关于睡眠，我建议固定作息时间，让身体形成良好的生物钟。子时（23:00-1:00）是养肝的最佳时间，尽量在11点前入睡。",
        "睡前半小时尽量少看电子设备，让大脑得到充分休息。可以喝一小杯温牛奶或薰衣草花茶帮助入眠。"
    ],
    "stress": [
        "压力过大时，可以尝试深呼吸放松法：吸气4秒，屏气7秒，呼气8秒。这是中医推荐的调息养生法。",
        "现代人压力大很正常，建议每天给自己留15分钟的独处时间。可以尝试冥想或八段锦来放松身心。",
        "适当的运动可以帮助释放压力，比如散步、瑜伽、太极拳都是不错的选择。"
    ],
    "tea": [
        "根据您的体质，推荐饮用菊花茶，具有清热明目的功效。菊花搭配枸杞，效果更佳，特别适合长时间用眼的朋友。",
        "绿茶富含茶多酚，有抗氧化作用，但胃寒者建议少饮。如果胃不太好，可以改喝红茶或普洱熟茶，温胃养胃。",
        "玫瑰花茶疏肝理气，适合情绪不畅时饮用；桂花茶温中散寒，适合秋冬季节暖身。"
    ],
    "food": [
        "春季养肝，建议多吃绿色蔬菜如菠菜、荠菜、韭菜；少吃酸味食物，适当增加甘味食材如山药、大枣。",
        "夏季养心，宜清淡饮食，推荐绿豆汤、冬瓜汤清热解暑。注意不要贪凉饮冷，以免伤脾胃。",
        "秋冬养肺补肾，推荐银耳雪梨汤、芝麻核桃粥、羊肉萝卜汤，温补而不燥。",
        "中医讲'药食同源'，日常饮食也要注意平衡。五谷杂粮为主，蔬菜水果为辅，荤素搭配，不偏食不挑食。"
    ],
    "exercise": [
        "推荐每天坚持30分钟以上的中等强度运动。快走、慢跑、游泳都是很好的选择，贵在坚持。",
        "八段锦是传统养生功法，动作简单，不受场地限制，每天练习15分钟即可达到舒筋活络的效果。",
        "太极拳柔中带刚，既能锻炼身体又能调养心神，特别适合中老年人。建议清晨练习，效果更佳。",
        "上班族建议每隔1小时起身活动5分钟，做做颈部旋转、肩部拉伸，预防颈椎病。"
    ],
    "constitution": [
        "中医将人的体质分为九种：平和质、气虚质、阳虚质、阴虚质、痰湿质、湿热质、血瘀质、气郁质、特禀质。建议通过体质测试了解自己的体质类型，针对性地调养。",
        "气虚质的人容易疲劳、气短，建议多吃补气食物如黄芪炖鸡、山药粥，避免过度劳累。",
        "阳虚质的人畏寒怕冷，建议多吃温热食物如羊肉、生姜、桂圆，注意保暖，适当晒太阳。"
    ],
    "solar_term": [
        "二十四节气是中医养生的重要时间参考。每个节气都有对应的饮食起居建议，顺应节气变化调养身体效果最好。",
        "春分时节昼夜平分，饮食宜阴阳调和。可多吃春笋、荠菜等时令蔬菜，适当增加户外活动。",
        "白露时节天气转凉，早晚温差大，注意添加衣物。饮食上宜润肺养阴，推荐百合银耳羹。"
    ],
    "season": [
        "中医讲究'春生夏长秋收冬藏'，顺应四季变化来调整生活方式是养生的根本。",
        "春天万物复苏，是养肝的好时节。建议多户外踏青，保持心情舒畅，早睡早起。",
        "夏季阳气最盛，养心为主。避免午时（11-13点）暴晒，可以午休30分钟养心神。",
        "秋季干燥，养肺为先。多吃润肺食物如梨、百合、银耳，注意皮肤保湿。",
        "冬季寒冷，补肾为要。早睡晚起，注意保暖，可以适当进补温热食物。"
    ],
    "pain": [
        "中医讲'不通则痛'，身体疼痛往往与气血运行不畅有关。建议适当运动促进气血流通，也可以尝试艾灸或热敷缓解。",
        "颈肩酸痛的话，建议每天做做颈部操：缓慢转动脖子各10圈，配合耸肩放松。久坐是颈椎病的大敌，记得定时起身活动。",
        "关节疼痛在潮湿天气容易加重，中医认为是'湿邪入侵'。注意关节保暖，可以煮薏米红豆汤祛湿。"
    ],
    "cold_flu": [
        "感冒初期可以煮生姜红糖水喝，发汗驱寒。同时注意休息，多喝温水，让身体自然恢复。",
        "预防感冒建议平时注意保暖，尤其是头部、颈部和脚部。秋冬季节出门戴围巾，每晚热水泡脚。",
        "如果感冒症状持续超过一周或伴有高烧，建议及时就医。养生讲究'未病先防'，日常增强体质比生病后治疗更重要。"
    ],
    "weight": [
        "中医认为肥胖多与脾虚痰湿有关。建议健脾祛湿：多吃山药、薏米、冬瓜，少吃甜腻生冷食物。",
        "控制体重不等于节食。规律三餐、细嚼慢咽、七八分饱即可。配合适度运动，循序渐进最健康。",
        "饭后百步走，活到九十九。饭后半小时散步有助于消化，但不要立即剧烈运动。"
    ],
    "skin": [
        "皮肤状况反映了内在脏腑的健康。皮肤干燥多为阴虚，建议多喝水，多吃银耳、百合等滋阴润燥食物。",
        "痤疮反复可能与肺热或湿热体质有关，建议少吃辛辣油腻，多吃清热食物如苦瓜、绿豆。",
        "气血充足则面色红润有光泽。建议多吃红枣、桂圆、枸杞，配合充足睡眠，让皮肤自然焕发光彩。"
    ],
    "women": [
        "女性养生重在调气血。经期前后注意保暖，避免生冷食物。平时可以喝当归红枣茶补血养颜。",
        "更年期女性容易出现潮热、失眠等症状，建议多食豆制品补充植物雌激素，配合适度运动和冥想。",
        "产后恢复很重要，建议充分休息，适当补充营养。当归生姜羊肉汤是传统产后调养的佳品。"
    ],
    "default": [
        "养生之道，在于顺应自然、调和阴阳。有什么具体的养生问题想了解的吗？比如饮食、运动、睡眠、体质调理等，我都可以给你建议。",
        "身体健康是最重要的。中医养生讲究'未病先防'，日常注意饮食起居、情志调节，就能远离很多疾病。有什么想聊的养生话题吗？",
        "每个人的体质不同，养生方法也应因人而异。建议先了解自己的体质类型，再有针对性地调养。你想聊聊哪方面的养生呢？",
        "顺时养生，就是跟着大自然的节奏生活。春养肝、夏养心、秋养肺、冬养肾，每个季节都有不同的养生重点。你想了解哪个季节的养生方法呢？"
    ]
}

# Keyword to topic mapping (order matters - first match wins)
_KEYWORD_TOPICS = [
    ("greeting", ["你好", "早", "晚好", "嗨", "hello", "hi", "在吗"]),
    ("tea", ["茶", "茶饮", "花茶", "绿茶", "红茶", "普洱", "枸杞茶", "菊花茶", "喝茶"]),
    ("food", ["吃", "食物", "饮食", "食谱", "营养", "食疗", "菜", "汤", "粥", "三餐", "早餐", "午餐", "晚餐", "水果", "蔬菜"]),
    ("exercise", ["运动", "锻炼", "健身", "跑步", "散步", "瑜伽", "太极", "八段锦", "拉伸", "健身"]),
    ("constitution", ["体质", "九种体质", "气虚", "阳虚", "阴虚", "痰湿", "湿热", "平和质"]),
    ("solar_term", ["节气", "春分", "秋分", "夏至", "冬至", "白露", "立春", "雨水", "惊蛰", "清明", "谷雨", "小满", "芒种", "小暑", "大暑", "立秋", "处暑", "寒露", "霜降", "立冬", "小雪", "大雪", "小寒", "大寒"]),
    ("season", ["春天", "夏天", "秋天", "冬天", "春季", "夏季", "秋季", "冬季", "四季", "当季"]),
    ("women", ["女性", "经期", "月经", "更年期", "产后", "孕妇", "备孕"]),
    ("sleep", ["睡眠", "睡觉", "失眠", "梦", "入睡", "熬夜", "早起", "作息"]),
    ("tired", ["累", "疲惫", "困", "想睡", "没精神", "乏力", "无力", "疲劳"]),
    ("stress", ["压力", "焦虑", "烦", "心情", "抑郁", "情绪", "紧张", "烦躁", "郁闷", "不开心"]),
    ("pain", ["痛", "疼", "腰酸", "颈椎", "肩膀", "关节", "头痛", "胃痛", "腹痛", "腰痛"]),
    ("cold_flu", ["感冒", "发烧", "咳嗽", "流鼻涕", "喉咙", "打喷嚏", "鼻塞"]),
    ("weight", ["减肥", "瘦身", "胖", "瘦", "体重", "控制体重", "长胖"]),
    ("skin", ["皮肤", "脸", "痘痘", "痤疮", "护肤", "美容", "皱纹", "色斑", "气色"]),
]


def generate_ai_response(user_message: str) -> dict:
    """生成 AI 回复 (Template fallback)"""
    message_lower = user_message.lower()
    
    topic = "default"
    for topic_name, keywords in _KEYWORD_TOPICS:
        if any(word in message_lower for word in keywords):
            topic = topic_name
            break
    
    template = random.choice(AI_RESPONSES[topic])
    
    follow_ups = [
        {"in_days": 1, "intent": "sleep_check", "question": "昨晚睡得怎么样？"},
        {"in_days": 2, "intent": "mood_check", "question": "今天心情如何？"},
        {"in_days": 1, "intent": "exercise_check", "question": "今天运动了吗？"}
    ]
    follow_up = random.choice(follow_ups) if random.random() > 0.5 else None
    
    return {
        "text": template,
        "tone": "gentle",
        "care_status": "stable",
        "follow_up": follow_up,
        "offline_encouraged": True,
        "presence_level": "normal",
        "safety_flag": "none",
    }


def _determine_tone(text: str, intent: str) -> str:
    """根据意图和内容确定语气"""
    if intent == "mood_support":
        return "empathetic"
    if intent == "sleep":
        return "gentle"
    if intent == "exercise":
        return "encouraging"
    if intent == "food_recommendation" or intent == "solar_term":
        return "informative"
    return "gentle"


def _generate_follow_up(intent: str) -> Optional[dict]:
    """根据意图生成跟进建议"""
    follow_up_map = {
        "sleep": {"in_days": 1, "intent": "sleep_check", "question": "今晚试试早睡半小时，明天感觉会好很多哦~"},
        "mood_support": {"in_days": 1, "intent": "mood_check", "question": "明天想聊聊天吗？我随时都在。"},
        "exercise": {"in_days": 1, "intent": "exercise_check", "question": "明天记得活动一下哦，哪怕10分钟也好~"},
        "food_recommendation": {"in_days": 2, "intent": "food_check", "question": "今天试了推荐的食谱吗？感觉怎么样？"},
    }
    # 50% 概率生成 follow-up
    if intent in follow_up_map and random.random() > 0.5:
        return follow_up_map[intent]
    return None


# ============ Models ============

class ChatRequest(BaseModel):
    message: str
    conversation_id: Optional[str] = None

class Message(BaseModel):
    id: str
    role: str  # user / assistant
    content: str
    created_at: str

class ChatResponse(BaseModel):
    message_id: str
    conversation_id: str
    text: str
    tone: str
    care_status: str
    follow_up: Optional[dict] = None
    offline_encouraged: bool
    presence_level: str
    safety_flag: str

# ============ API Endpoints ============

@router.post("", response_model=dict)
async def chat(
    message: str = Query(...),
    conversation_id: Optional[str] = Query(None),
    user_id: str = Query("user-001")
):
    """发送消息"""
    # 创建或获取会话
    if not conversation_id:
        conversation_id = f"conv_{user_id}_{datetime.now().strftime('%Y%m%d%H%M%S')}"
    
    if conversation_id not in conversations_db:
        conversations_db[conversation_id] = {
            "id": conversation_id,
            "user_id": user_id,
            "title": message[:20] + "...",
            "created_at": datetime.now().isoformat(),
            "messages": []
        }
    
    # 保存用户消息
    user_message_id = str(uuid.uuid4())
    user_message = {
        "id": user_message_id,
        "role": "user",
        "content": message,
        "created_at": datetime.now().isoformat()
    }
    conversations_db[conversation_id]["messages"].append(user_message)
    
    # ============ Step 1: Safety Check (输入安全过滤) ============
    safety_result = safety_guard.check_input(message, {"user_id": user_id})

    # Crisis 模式：直接阻断，返回安全资源
    if safety_result.level == SafetyLevel.CRISIS:
        ai_message_id = str(uuid.uuid4())
        ai_message = {
            "id": ai_message_id,
            "role": "assistant",
            "content": safety_result.override_response,
            "created_at": datetime.now().isoformat()
        }
        conversations_db[conversation_id]["messages"].append(ai_message)

        return {
            "success": True,
            "data": {
                "message_id": ai_message_id,
                "conversation_id": conversation_id,
                "text": safety_result.override_response,
                "tone": "empathetic",
                "care_status": "crisis",
                "follow_up": None,
                "offline_encouraged": False,
                "presence_level": "normal",
                "safety_flag": "crisis",
            }
        }

    # Block 模式（医疗边界等）：不调用LLM，直接返回
    if safety_result.should_block and safety_result.override_response:
        ai_message_id = str(uuid.uuid4())
        ai_message = {
            "id": ai_message_id,
            "role": "assistant",
            "content": safety_result.override_response,
            "created_at": datetime.now().isoformat()
        }
        conversations_db[conversation_id]["messages"].append(ai_message)

        return {
            "success": True,
            "data": {
                "message_id": ai_message_id,
                "conversation_id": conversation_id,
                "text": safety_result.override_response,
                "tone": "gentle",
                "care_status": "stable",
                "follow_up": None,
                "offline_encouraged": True,
                "presence_level": "normal",
                "safety_flag": safety_result.flag,
            }
        }
    
    # ============ Step 2: Intent Detection ============
    intent_result = intent_detector.detect(message)
    logger.info(f"[Chat] Intent: {intent_result.intent} (confidence: {intent_result.confidence})")
    
    # ============ Step 3: Get System Prompt ============
    # 优先使用 PromptStore（版本管理 + 灰度），降级到内存 registry
    base_system_prompt = prompt_store.get_prompt("chat.system", user_id=user_id)
    if not base_system_prompt:
        base_system_prompt = prompt_registry.get("core") or ""
    intent_system_prompt = INTENT_SYSTEM_PROMPTS.get(intent_result.intent, "")
    
    # 拼接：base + intent-specific
    if base_system_prompt and intent_system_prompt:
        system_prompt = f"{base_system_prompt}\n\n---\n\n{intent_system_prompt}"
    else:
        system_prompt = intent_system_prompt or base_system_prompt or "你是顺时，一个温暖贴心的 AI 养生健康陪伴助手。"
    
    # EmotionalDistress 模式：添加共情前缀
    if safety_result.level == SafetyLevel.EMOTIONAL_DISTRESS and safety_result.prefix:
        system_prompt = safety_result.prefix + system_prompt
    elif safety_result.level == SafetyLevel.SENSITIVE and safety_result.prefix:
        system_prompt = safety_result.prefix + system_prompt
    
    # ============ Step 4: Build Context Window ============
    history = _get_conversation_history(conversation_id)
    context_messages = _build_context_window(system_prompt, history, message)
    
    # ============ Step 5: Route Model Selection ============
    routing_context = RoutingContext(
        user_id=user_id,
        user_tier=UserTier.FREE,
        api_path="/chat/send",
        prompt=message,
    )
    route_result = model_router.select_model(routing_context)
    selected_model = route_result.selected_model

    # ============ Step 5.5: RAG Knowledge Enhancement ============
    try:
        from app.rag.retriever import retrieve as rag_retrieve
        relevant_chunks = rag_retrieve(message, lang='cn', top_k=3)
        if relevant_chunks:
            knowledge_context = "\n\n".join([c['content'][:500] for c in relevant_chunks])
            system_prompt += f"\n\n--- 参考知识（来自顺时知识库，请结合这些信息回答） ---\n{knowledge_context}"
            logger.info(f"[Chat] RAG 注入 {len(relevant_chunks)} 个知识 chunks")
    except Exception as rag_err:
        logger.warning(f"[Chat] RAG 检索失败，跳过知识注入: {rag_err}")

    # ============ Step 6: Call LLM (with Fallback Chain) ============
    ai_response = None
    tone = "gentle"
    care_status = "stable"
    safety_flag = "none"
    
    try:
        fallback_chain = get_fallback_chain()
        fb_result: FallbackResult = await fallback_chain.chat(
            user_id=user_id,
            messages=context_messages,
            primary_provider="siliconflow",
            primary_model=selected_model,
            skill_chain=[intent_result.intent] if intent_result else [],
            route_decision=f"model_router_selected={selected_model}",
            temperature=0.7,
            max_tokens=4096,
            user_tier="free",  # TODO: 从用户数据获取
        )
        
        if fb_result.response_text:
            ai_text = fb_result.response_text
            
            # 使用3级降级解析 AI 响应
            parsed = parse_ai_response(ai_text)
            
            # 计算 presence_level
            conv_messages = conversations_db[conversation_id].get("messages", [])
            user_timestamps = [
                msg["created_at"] for msg in conv_messages if msg["role"] == "user"
            ]
            presence = calculate_presence_level(
                message_timestamps=user_timestamps[-20:]  # 最近20条用户消息
            )
            
            ai_response = {
                "text": parsed["text"],
                "tone": parsed.get("tone") or _determine_tone(message, intent_result.intent),
                "care_status": parsed.get("care_status") or ("distressed" if safety_result.level == SafetyLevel.EMOTIONAL_DISTRESS else "stable"),
                "follow_up": parsed.get("follow_up") or _generate_follow_up(intent_result.intent),
                "offline_encouraged": parsed.get("offline_encouraged", True),
                "presence_level": presence,
                "safety_flag": parsed.get("safety_flag") or safety_result.level.value,
            }

            # Fallback 事件日志
            if fb_result.fallback_reason:
                logger.warning(
                    f"[Chat] Fallback 发生: reason={fb_result.fallback_reason.value}, "
                    f"from={fb_result.fallback_from}, to={fb_result.provider}/{fb_result.model}, "
                    f"tried={fb_result.tried_providers}"
                )
            else:
                logger.info(
                    f"[Chat] LLM 回复成功: model={fb_result.model}, "
                    f"provider={fb_result.provider}, tokens={fb_result.tokens_in + fb_result.tokens_out}, "
                    f"presence={presence}"
                )
    
    except Exception as e:
        logger.error(f"[Chat] LLM 调用失败: {e}, 降级到模板匹配")
    
    # ============ Step 7: Fallback to Template ============
    if ai_response is None:
        ai_response = generate_ai_response(message)
        ai_response["safety_flag"] = safety_result.level.value
        if safety_result.level == SafetyLevel.EMOTIONAL_DISTRESS:
            ai_response["care_status"] = "distressed"
        # 为模板响应也计算 presence_level
        conv_msgs = conversations_db[conversation_id].get("messages", [])
        user_ts = [m["created_at"] for m in conv_msgs if m["role"] == "user"]
        ai_response["presence_level"] = calculate_presence_level(
            message_timestamps=user_ts[-20:]
        )
    
    # ============ Step 7.5: Output Safety Check ============
    if ai_response is not None and ai_response.get("text"):
        output_safety = safety_guard.check_output(
            ai_response["text"],
            {"user_id": user_id, "model": selected_model},
        )
        if output_safety.level != SafetyLevel.NORMAL:
            # 追加警告后缀到AI回复
            if output_safety.prefix:
                ai_response["text"] = ai_response["text"] + output_safety.prefix
                ai_response["safety_flag"] = output_safety.flag

    # ============ Step 8: Save & Return ============
    ai_message_id = str(uuid.uuid4())
    ai_message = {
        "id": ai_message_id,
        "role": "assistant",
        "content": ai_response["text"],
        "created_at": datetime.now().isoformat()
    }
    conversations_db[conversation_id]["messages"].append(ai_message)
    
    return {
        "success": True,
        "data": {
            "message_id": ai_message_id,
            "conversation_id": conversation_id,
            **ai_response
        }
    }


@router.get("/conversations", response_model=dict)
async def get_conversations(
    user_id: str = Query("user-001"),
    limit: int = Query(20, ge=1, le=100)
):
    """获取会话列表"""
    user_conversations = [
        {"id": conv_id, "title": conv["title"], "created_at": conv["created_at"], "message_count": len(conv["messages"])}
        for conv_id, conv in conversations_db.items()
        if conv.get("user_id") == user_id
    ]
    
    user_conversations.sort(key=lambda x: x["created_at"], reverse=True)
    
    return {
        "success": True,
        "data": {
            "items": user_conversations[:limit],
            "total": len(user_conversations)
        }
    }

@router.get("/conversations/{conversation_id}", response_model=dict)
async def get_conversation(
    conversation_id: str,
    user_id: str = Query("user-001")
):
    """获取会话详情"""
    if conversation_id not in conversations_db:
        raise HTTPException(status_code=404, detail="会话不存在")
    
    conv = conversations_db[conversation_id]
    
    if conv.get("user_id") != user_id:
        raise HTTPException(status_code=403, detail="无权访问此会话")
    
    return {
        "success": True,
        "data": conv
    }

@router.delete("/conversations/{conversation_id}", response_model=dict)
async def delete_conversation(
    conversation_id: str,
    user_id: str = Query("user-001")
):
    """删除会话"""
    if conversation_id in conversations_db:
        conv = conversations_db[conversation_id]
        if conv.get("user_id") != user_id:
            raise HTTPException(status_code=403, detail="无权删除此会话")
        del conversations_db[conversation_id]
    
    return {"success": True, "message": "会话已删除"}

@router.get("/history/{conversation_id}", response_model=dict)
async def get_history(
    conversation_id: str,
    user_id: str = Query("user-001"),
    limit: int = Query(50, ge=1, le=200)
):
    """获取历史消息"""
    if conversation_id not in conversations_db:
        raise HTTPException(status_code=404, detail="会话不存在")
    
    conv = conversations_db[conversation_id]
    messages = conv.get("messages", [])[-limit:]
    
    return {
        "success": True,
        "data": {
            "items": messages,
            "total": len(conv.get("messages", []))
        }
    }
