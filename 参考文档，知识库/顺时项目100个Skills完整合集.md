# 顺时（ShunShi）项目完整 Skills 合集

本文档包含顺时项目的全部15个OpenClaw Skills，每个Skill均为完整可用的生产级规范。

---

# Skill 1: shunshi-solar-term

## SKILL.md

```yaml
---
name: shunshi-solar-term
description: "二十四节气养生引擎。计算当前节气、生成节气养生内容、提供节气饮食/起居/运动/情绪建议。Use when: (1) calculating current or upcoming solar terms, (2) generating seasonal wellness content, (3) providing solar-term-based diet/sleep/exercise/emotion advice, (4) building solar term calendar features, (5) triggering solar term change notifications."
---
```

# Solar Term Wellness Engine

## Overview
Compute Chinese 24 Solar Terms (二十四节气) dates, determine the current solar term, and generate personalized wellness content (diet, sleep, exercise, emotion) for each solar term.

## Solar Term Calculation

Use the `scripts/solar_term_calculator.py` script to compute exact solar term dates for any year.

```
python scripts/solar_term_calculator.py --year 2026
```

The script uses astronomical longitude calculations. Each solar term corresponds to a specific solar longitude (0°–345° in 15° increments).

## Solar Term Data Structure

Each solar term record must contain:
```json
{
  "code": "lichun",
  "name_cn": "立春",
  "name_en": "Start of Spring",
  "sequence": 1,
  "season": "spring",
  "month_typical": 2,
  "day_typical": 4,
  "organ_focus": "liver",
  "theme_color": "#7CB342",
  "wellness": {
    "principle": "养肝护阳，顺应升发",
    "diet": {
      "principle": "少酸增甘，以养脾气",
      "recommended": ["韭菜","豆芽","香椿","菠菜","枸杞","大枣"],
      "restricted": ["辛辣燥热过量","过食酸味"],
      "recipes": ["枸杞菊花茶","韭菜炒鸡蛋","红枣枸杞粥"]
    },
    "sleep": {
      "advice": "早睡早起，不宜熬夜",
      "bedtime": "22:30",
      "waketime": "06:30"
    },
    "exercise": {
      "advice": "散步、慢跑、踏青、八段锦",
      "intensity": "light",
      "focus": "左右开弓似射雕（舒展胸肺）"
    },
    "emotion": {
      "advice": "保持心情愉悦，避免暴怒",
      "practice": "赏花、听轻音乐、冥想"
    },
    "acupoints": ["太冲穴","期门穴"],
    "teas": ["玫瑰花茶","菊花枸杞茶","薄荷茶"]
  }
}
```

## API Endpoints to Implement

1. `GET /api/v1/solar-terms/current` — Return current solar term with full wellness content.
2. `GET /api/v1/solar-terms/upcoming` — Return next solar term with countdown.
3. `GET /api/v1/solar-terms/calendar?year=2026` — Return full year calendar.
4. `GET /api/v1/solar-terms/{code}` — Return specific solar term details.
5. `GET /api/v1/solar-terms/{code}/recipes` — Recipes for a solar term.
6. `GET /api/v1/solar-terms/{code}/teas` — Tea recommendations.

## Determining Current Solar Term

```python
def get_current_solar_term(date=None):
    """
    1. Query solar_term_instances for the given year.
    2. Find the most recent solar term whose exact_date <= today.
    3. Return that solar term with full wellness data.
    4. Also compute days until next solar term.
    """
    if date is None:
        date = datetime.date.today()
    
    instances = SolarTermInstance.query.filter(
        SolarTermInstance.year == date.year,
        SolarTermInstance.exact_date <= date
    ).order_by(SolarTermInstance.exact_date.desc()).first()
    
    return instances.solar_term
```

## Solar Term Change Detection (Celery Task)

Run daily at 00:05 CST:
1. Check if today is a new solar term date.
2. If yes: update Redis cache key `current_solar_term`.
3. Send push notification to all users with solar term reminders enabled.
4. Refresh recommendation cache.
5. Update app home screen seasonal theme.

Notification template:
```
Title: "今日{solar_term_name}"
Body: "{solar_term_name}到了，{one_line_advice}"
```

## Content Generation Rules

When generating solar term content for the home page:
1. Personalize based on user's constitution type.
2. Cross-reference `references/solar_term_constitution_matrix.json` for type-specific advice.
3. Adjust recommendations based on time of day (morning/afternoon/evening).
4. Include one actionable tip the user can do right now.

## Reference Files
- `references/solar_term_constitution_matrix.json` — 24 solar terms × 9 constitutions cross-reference.
- `references/solar_term_dates_2024_2030.json` — Pre-computed dates.
- `scripts/solar_term_calculator.py` — Astronomical calculation script.
- `scripts/seed_solar_terms.py` — Database seeding script.

---

# Skill 2: shunshi-constitution

## SKILL.md

```yaml
---
name: shunshi-constitution
description: "中医九种体质测试与调理系统。实现体质问卷、评分算法、报告生成、个性化养生方案。Use when: (1) building the constitution type quiz/assessment, (2) computing constitution scores from answers, (3) generating personalized wellness reports, (4) providing constitution-specific diet/exercise/lifestyle advice, (5) implementing the body type result sharing feature."
---
```

# Constitution Assessment System

## Overview
Implement the Traditional Chinese Medicine (TCM) Nine Constitution Types (九种体质) assessment, scoring algorithm, report generation, and personalized wellness plans.

## Nine Constitution Types

| Code | Name CN | Name EN | Key Characteristics |
|------|---------|---------|-------------------|
| pinghe | 平和质 | Balanced | Healthy, energetic, good sleep |
| qixu | 气虚质 | Qi-Deficient | Fatigued, catches colds easily |
| yangxu | 阳虚质 | Yang-Deficient | Always cold, pale, loose stools |
| yinxu | 阴虚质 | Yin-Deficient | Warm palms, dry mouth, night sweats |
| tanshi | 痰湿质 | Phlegm-Dampness | Overweight, oily skin, heavy feeling |
| shire | 湿热质 | Damp-Heat | Oily face, acne, bitter mouth |
| xueyu | 血瘀质 | Blood-Stasis | Dark complexion, bruising easily |
| qiyu | 气郁质 | Qi-Stagnation | Depressed, sighs, throat tightness |
| tebing | 特禀质 | Sensitive | Allergies, sensitive to weather |

## Quiz Structure

Total questions: 33 (based on the standard 王琦九种体质量表).

Each question is a statement rated on a 5-point Likert scale:
- 1 = 没有 (Never)
- 2 = 很少 (Rarely)
- 3 = 有时 (Sometimes)
- 4 = 经常 (Often)
- 5 = 总是 (Always)

Questions are grouped by constitution type. See `references/constitution_questions.json` for the complete question set.

## Scoring Algorithm

```python
def calculate_constitution_scores(answers: dict) -> dict:
    """
    Standard scoring formula (王琦标准):
    
    For each constitution type:
    raw_score = sum of relevant question scores
    
    Transformed score = ((raw_score - num_questions) / (num_questions * 4)) * 100
    
    Judgment criteria:
    - 平和质: transformed >= 60 AND all others < 40 → "是"
    - 平和质: transformed >= 60 AND any other >= 40 → "基本是"
    - 偏颇体质: transformed >= 40 → "是" (for that type)
    - 偏颇体质: 30 <= transformed < 40 → "倾向是"
    - 偏颇体质: transformed < 30 → "否"
    
    Returns:
    {
      "scores": {"pinghe": 72.5, "qixu": 45.0, ...},
      "primary_type": "qixu",
      "secondary_type": "yangxu",
      "is_balanced": false,
      "type_judgments": {"pinghe": "基本是", "qixu": "是", ...}
    }
    """
    QUESTION_GROUPS = load_question_groups()  # from references/
    scores = {}
    
    for type_code, question_ids in QUESTION_GROUPS.items():
        raw = sum(answers.get(str(qid), 3) for qid in question_ids)
        n = len(question_ids)
        transformed = ((raw - n) / (n * 4)) * 100
        scores[type_code] = round(transformed, 1)
    
    # Determine primary and secondary types
    non_balanced = {k: v for k, v in scores.items() if k != 'pinghe'}
    sorted_types = sorted(non_balanced.items(), key=lambda x: x[1], reverse=True)
    
    primary = sorted_types[0][0] if sorted_types[0][1] >= 40 else 'pinghe'
    secondary = sorted_types[1][0] if len(sorted_types) > 1 and sorted_types[1][1] >= 30 else None
    
    return {
        "scores": scores,
        "primary_type": primary,
        "secondary_type": secondary
    }
```

## AI Report Generation

After scoring, generate a personalized report using AI:

```
Prompt template:
"根据体质测试结果，用户主要体质为{primary_type}（得分{score}），
次要倾向为{secondary_type}。
请生成一份温暖、实用的个性化养生方案报告，包含：
1. 体质解读（100字）
2. 饮食建议（具体食材和食谱）
3. 运动建议（具体运动方式）
4. 茶饮推荐（具体配方）
5. 穴位保健（具体穴位和方法）
6. 生活习惯建议
7. 当前节气{current_solar_term}的特别建议
语气温和亲切，避免医疗用语。"
```

## Shareable Result Card

Generate a shareable image card containing:
- User's primary constitution type name and icon
- Top 3 characteristics
- One diet recommendation
- QR code linking to quiz
- SEASONS branding

Use `scripts/generate_result_card.py` to create the image.

## API Endpoints

1. `GET /api/v1/constitution/questions` — Return all 33 questions in order.
2. `POST /api/v1/constitution/test` — Submit answers, return scores and report.
3. `GET /api/v1/constitution/result` — Get latest test result for current user.
4. `GET /api/v1/constitution/types/{code}` — Get full details for a constitution type.
5. `GET /api/v1/constitution/plan` — Get personalized plan (constitution × current solar term).

## Reference Files
- `references/constitution_questions.json` — Complete 33-question set with groupings.
- `references/constitution_types_detail.json` — Full details for all 9 types.
- `references/constitution_diet_matrix.json` — Food recommendations per type.
- `scripts/calculate_scores.py` — Scoring algorithm implementation.
- `scripts/generate_result_card.py` — Shareable card image generator.
- `scripts/seed_constitution_data.py` — Database seeding script.

---

# Skill 3: shunshi-ai-companion

## SKILL.md

```yaml
---
name: shunshi-ai-companion
description: "AI养生对话助手系统。管理对话会话、构建System Prompt、实现RAG知识检索、流式响应、上下文管理、内容推荐卡片。Use when: (1) building the AI chat interface and backend, (2) designing the system prompt with user context injection, (3) implementing RAG retrieval from the wellness knowledge base, (4) handling streaming responses via SSE, (5) managing chat sessions and message history, (6) embedding content recommendation cards in AI responses."
---
```

# AI Wellness Companion System

## Overview
Build the AI-powered wellness chat companion that provides personalized, warm, and actionable wellness advice based on user constitution, current solar term, and conversation context.

## System Prompt Construction

Build the system prompt dynamically for each request:

```python
def build_system_prompt(user, session):
    solar_term = get_current_solar_term()
    current_hour = datetime.now().hour
    shichen = get_shichen_name(current_hour)
    
    # RAG: retrieve relevant knowledge
    knowledge_context = retrieve_knowledge(session.latest_user_message, top_k=5)
    
    return f"""你是「顺时」的AI养生助手，一个温和、专业、有爱心的养生伙伴。

## 身份
- 名字：顺时小助手
- 性格：温暖、耐心、不说教、像一个懂养生的好朋友

## 规则
1. 永远不做医疗诊断，不推荐具体药物
2. 涉及疾病问题时建议就医，你只提供生活调理建议
3. 回复温和亲切，控制在200字以内
4. 适时推荐App内容（食谱/茶饮/穴位）
5. 不制造健康焦虑
6. 不确定的问题坦诚说"建议咨询医生"
7. 每次回复给出一个小行动建议

## 当前上下文
- 节气：{solar_term.name_cn}（{solar_term.wellness_principle}）
- 体质：{user.constitution_type or '未测试'}
- 性别：{user.gender_display}
- 时辰：{shichen}（{get_shichen_advice(current_hour)}）
- 季节：{solar_term.season}

## 知识参考
{knowledge_context}

## 回复格式
回复使用纯文本。如果推荐App内容，使用以下格式：
[推荐:食谱:recipe_id:食谱名称]
[推荐:茶饮:tea_id:茶饮名称]
[推荐:穴位:acupoint_id:穴位名称]
[推荐:功法:exercise_id:功法名称]
"""
```

## RAG Knowledge Retrieval

```python
def retrieve_knowledge(query: str, top_k: int = 5) -> str:
    """
    1. Embed the user query using embedding model.
    2. Search pgvector for top_k most similar knowledge chunks.
    3. Format results as context string.
    4. Return formatted context.
    """
    embedding = get_embedding(query)
    
    results = db.execute(
        text("""
        SELECT content, source, similarity
        FROM knowledge_chunks
        ORDER BY embedding <=> :query_embedding
        LIMIT :top_k
        """),
        {"query_embedding": str(embedding), "top_k": top_k}
    )
    
    context_parts = []
    for row in results:
        context_parts.append(f"[来源:{row.source}]\n{row.content}")
    
    return "\n---\n".join(context_parts)
```

## Streaming Response (SSE)

```python
@app.post("/api/v1/chat/sessions/{session_id}/messages")
async def send_message(session_id: str, body: MessageRequest, user=Depends(get_current_user)):
    # Check rate limit
    if not user.is_premium and get_daily_count(user.id) >= 3:
        raise HTTPException(429, "今日免费次数已用完，升级会员无限畅聊")
    
    # Save user message
    save_message(session_id, user.id, "user", body.content)
    
    # Build prompt
    system_prompt = build_system_prompt(user, session)
    messages = get_context_messages(session_id, limit=10)
    
    # Stream response
    async def generate():
        full_response = ""
        async for chunk in call_ai_stream(system_prompt, messages):
            full_response += chunk
            yield f"data: {json.dumps({'content': chunk})}\n\n"
        
        # Save assistant message
        save_message(session_id, user.id, "assistant", full_response)
        
        # Parse recommendation cards
        cards = parse_recommendation_cards(full_response)
        if cards:
            yield f"data: {json.dumps({'cards': cards})}\n\n"
        
        yield "data: [DONE]\n\n"
    
    return StreamingResponse(generate(), media_type="text/event-stream")
```

## Recommendation Card Parsing

Parse `[推荐:类型:id:名称]` tags from AI response and convert to structured cards:

```python
def parse_recommendation_cards(text: str) -> list:
    pattern = r'\[推荐:(食谱|茶饮|穴位|功法):([a-f0-9-]+):(.+?)\]'
    matches = re.findall(pattern, text)
    cards = []
    for type_cn, content_id, title in matches:
        type_map = {"食谱": "recipe", "茶饮": "tea", "穴位": "acupoint", "功法": "exercise"}
        cards.append({
            "type": type_map[type_cn],
            "id": content_id,
            "title": title,
            "action": "navigate"
        })
    return cards
```

## Model Selection & Fallback

```python
AI_CONFIG = {
    "free_model": "qwen-turbo",
    "premium_model": "qwen-max",
    "fallback_model": "gpt-4o-mini",
    "max_context_messages": 10,
    "max_tokens": 500,
    "temperature": 0.7,
    "timeout": 30,
    "retry_count": 2,
}

async def call_ai_stream(system_prompt, messages):
    model = AI_CONFIG["premium_model"] if user.is_premium else AI_CONFIG["free_model"]
    try:
        async for chunk in primary_ai_call(model, system_prompt, messages):
            yield chunk
    except Exception:
        async for chunk in fallback_ai_call(AI_CONFIG["fallback_model"], system_prompt, messages):
            yield chunk
```

## Quick Question Suggestions

Display contextual quick-question chips based on time and season:

| Time | Suggestions |
|------|------------|
| 06:00–09:00 | "今天早餐吃什么", "晨起怎么养生" |
| 09:00–12:00 | "办公室怎么养生", "推荐一杯提神茶" |
| 12:00–14:00 | "午餐吃什么好", "午休怎么休息" |
| 14:00–18:00 | "下午犯困怎么办", "推荐一个穴位" |
| 18:00–21:00 | "晚餐吃什么", "今天的运动" |
| 21:00–23:00 | "睡不着怎么办", "睡前怎么放松" |

## Reference Files
- `references/system_prompt_template.md` — Full system prompt template.
- `references/quick_questions.json` — Time-based quick question map.
- `references/content_card_schema.json` — Card response format specification.
- `scripts/build_knowledge_embeddings.py` — Knowledge base vectorization script.
- `scripts/test_ai_response.py` — AI response quality testing script.

---

# Skill 4: shunshi-recipe-engine

## SKILL.md

```yaml
---
name: shunshi-recipe-engine
description: "养生食谱管理引擎。创建/查询/推荐养生食谱，支持按节气/体质/功效/食材筛选，包含营养计算和份量调整。Use when: (1) building recipe CRUD and search features, (2) implementing recipe filtering by solar term, constitution, function, or ingredient, (3) generating personalized recipe recommendations, (4) computing nutrition information, (5) adjusting serving sizes, (6) building recipe detail pages with step-by-step instructions."
---
```

# Recipe Management Engine

## Overview
Manage the wellness recipe library — creation, storage, search, filtering, personalized recommendation, nutrition computation, and serving adjustment.

## Recipe Data Model

See the database schema in the project development prompt. Key fields: title, category, seasons, solar_terms, suitable_constitutions, unsuitable_constitutions, functions, target_symptoms, servings, prep_time, cook_time, difficulty, ingredients (JSONB), steps (JSONB), nutrition, cover_image_url, is_premium.

## Recipe Categories

| Category | Code | Description |
|----------|------|-------------|
| 正餐 | meal | 主食、菜肴 |
| 汤品 | soup | 养生汤 |
| 茶饮 | tea | 养生茶 |
| 粥品 | congee | 各类养生粥 |
| 甜品 | dessert | 养生甜品 |
| 小食 | snack | 养生零食 |

## Filtering & Search API

```
GET /api/v1/recipes?
    season=spring&                 # 按季节
    solar_term=lichun&             # 按节气
    constitution=qixu&             # 按体质
    function=补气&                 # 按功效
    symptom=失眠&                  # 按症状
    category=soup&                 # 按分类
    difficulty=1&                  # 按难度
    is_premium=false&              # 免费/付费
    q=山药&                        # 关键词搜索
    page=1&limit=20                # 分页
```

## Personalized Recommendation Algorithm

```python
def recommend_recipes(user, limit=10):
    solar_term = get_current_solar_term()
    constitution = user.constitution_type
    hour = datetime.now().hour
    
    # Determine meal type by time
    if 5 <= hour < 10:
        meal_preference = ["congee", "meal"]
    elif 10 <= hour < 14:
        meal_preference = ["meal", "soup"]
    elif 14 <= hour < 17:
        meal_preference = ["tea", "snack"]
    else:
        meal_preference = ["soup", "meal", "congee"]
    
    recipes = Recipe.query.filter(
        Recipe.suitable_constitutions.contains([constitution]),
        Recipe.seasons.contains([solar_term.season]),
        Recipe.is_published == True,
        ~Recipe.unsuitable_constitutions.contains([constitution])
    ).order_by(
        # Prioritize: matching solar term > matching season > matching function
        case(
            (Recipe.solar_terms.contains([solar_term.code]), 3),
            else_=1
        ).desc(),
        func.random()
    ).limit(limit * 2).all()
    
    # Boost recipes matching current meal type
    scored = []
    for r in recipes:
        score = 1.0
        if r.category in meal_preference:
            score += 2.0
        if solar_term.code in (r.solar_terms or []):
            score += 1.5
        scored.append((r, score))
    
    scored.sort(key=lambda x: x[1], reverse=True)
    return [r for r, _ in scored[:limit]]
```

## Serving Adjustment

```python
def adjust_servings(recipe, target_servings):
    """Adjust ingredient amounts proportionally."""
    ratio = target_servings / recipe.servings
    adjusted = []
    for ing in recipe.ingredients:
        new_ing = ing.copy()
        if ing.get("amount"):
            new_ing["amount"] = round(ing["amount"] * ratio, 1)
        adjusted.append(new_ing)
    return adjusted
```

## Content Seeding

Use `scripts/seed_recipes.py` to populate the database with initial recipes from `references/recipes_database.json`. The reference file should contain 200+ recipes organized by season and constitution.

## Reference Files
- `references/recipes_database.json` — Full recipe database (200+ recipes).
- `references/nutrition_database.json` — Common ingredient nutrition data.
- `references/function_tags.json` — Standardized function/symptom tag list.
- `scripts/seed_recipes.py` — Database seeding.
- `scripts/calculate_nutrition.py` — Nutrition calculator.

---

# Skill 5: shunshi-tea-formula

## SKILL.md

```yaml
---
name: shunshi-tea-formula
description: "养生茶饮配方系统。管理茶饮配方库，提供按体质/节气/功效推荐的茶饮方案，包含冲泡方法和禁忌信息。Use when: (1) building the tea recipe library and detail pages, (2) recommending teas based on constitution/solar term/time of day, (3) displaying brewing instructions and contraindications, (4) implementing the 'tea ritual' feature."
---
```

# Tea Formula System

## Overview
Manage the wellness tea/beverage library — 100+ tea formulas with ingredients, brewing methods, benefits, contraindications, and personalized recommendations.

## Tea Categories
- 花茶 (Flower tea): 玫瑰花茶, 菊花茶, 茉莉花茶
- 养生茶 (Wellness tea): 枸杞红枣茶, 黄芪茶, 决明子茶
- 凉茶 (Cooling tea): 金银花茶, 五花茶
- 暖茶 (Warming tea): 姜枣茶, 桂圆红枣茶, 肉桂茶
- 助眠茶 (Sleep tea): 酸枣仁茶, 百合莲子茶, 薰衣草茶

## Recommendation Logic

```python
def recommend_tea(user, context="general"):
    solar_term = get_current_solar_term()
    constitution = user.constitution_type
    hour = datetime.now().hour
    
    # Time-based filtering
    if hour >= 20:  # Evening: no caffeine
        exclude_tags = ["caffeinated", "提神"]
        prefer_tags = ["安神", "助眠"]
    elif hour < 10:  # Morning: warming
        prefer_tags = ["温阳", "提神", "健脾"]
    else:
        prefer_tags = []
    
    teas = TeaRecipe.query.filter(
        TeaRecipe.suitable_constitutions.contains([constitution]),
        TeaRecipe.seasons.contains([solar_term.season])
    ).all()
    
    # Score and rank
    ranked = score_teas(teas, prefer_tags, exclude_tags)
    return ranked[:5]
```

## Brewing Guide Display

Each tea detail page shows:
1. Name and description
2. Ingredients with amounts
3. Water temperature (℃)
4. Steeping time (minutes)
5. Best time to drink
6. Benefits list
7. Contraindications (red warning box)
8. Suitable/unsuitable constitutions

## Reference Files
- `references/tea_database.json` — 100+ tea formulas.
- `references/tea_constitution_matrix.json` — Tea × constitution suitability.
- `scripts/seed_teas.py` — Database seeding.

---

# Skill 6: shunshi-acupoint

## SKILL.md

```yaml
---
name: shunshi-acupoint
description: "穴位养生指导系统。管理穴位库，提供穴位定位、按摩方法、功效说明、适用症状，支持按症状/体质/经络查找穴位。Use when: (1) building the acupoint library and detail pages, (2) recommending acupoints based on symptoms or constitution, (3) displaying acupoint location guides with images/video, (4) implementing the massage timer feature, (5) generating acupoint-based wellness routines."
---
```

# Acupoint Wellness Guide System

## Overview
Manage the acupoint (穴位) library — 50+ commonly used acupoints with precise location descriptions, massage techniques, benefits, contraindications, and symptom-based recommendations.

## Acupoint Data Structure

```json
{
  "name_cn": "足三里",
  "name_pinyin": "zu san li",
  "name_en": "Zusanli (ST36)",
  "meridian": "足阳明胃经",
  "location": "外膝眼下四横指，胫骨外侧一横指处",
  "functions": ["健脾和胃", "补气养血", "扶正培元"],
  "indications": ["胃痛", "消化不良", "疲劳", "免疫力低下"],
  "massage_method": "拇指按揉，有酸胀感为宜",
  "massage_duration_minutes": 5,
  "contraindications": "无特殊禁忌",
  "related_constitutions": ["qixu", "yangxu", "tanshi"],
  "related_symptoms": ["fatigue", "digestion", "immunity"],
  "image_url": "acupoints/zusanli.png",
  "video_url": "acupoints/zusanli_guide.mp4"
}
```

## Symptom-Based Lookup

```
GET /api/v1/acupoints?symptom=失眠  →  返回: 神门穴, 涌泉穴, 安眠穴
GET /api/v1/acupoints?symptom=头痛  →  返回: 百会穴, 太阳穴, 合谷穴
GET /api/v1/acupoints?constitution=qixu  →  返回: 足三里, 气海穴, 关元穴
GET /api/v1/acupoints?meridian=肺经  →  返回: 列缺穴, 鱼际穴, 尺泽穴
```

## Massage Timer Feature

Implement a massage timer in the app:
1. User selects an acupoint.
2. Timer starts (default: acupoint's recommended duration).
3. Visual guide shows location.
4. Audio cue for breathing synchronization.
5. Completion vibration/sound.

## Reference Files
- `references/acupoint_database.json` — 50+ acupoints with full data.
- `references/symptom_acupoint_map.json` — Symptom → acupoint mapping.
- `references/acupoint_images/` — Location diagrams.
- `scripts/seed_acupoints.py` — Database seeding.

---

# Skill 7: shunshi-exercise

## SKILL.md

```yaml
---
name: shunshi-exercise
description: "传统功法与运动教程系统。管理八段锦、太极、五禽戏、办公室操、瑜伽拉伸等教程内容，提供分步骤视频/图文教学。Use when: (1) building exercise tutorial library and detail pages, (2) implementing step-by-step exercise guides with video/images, (3) recommending exercises based on constitution/season/time, (4) building the 'follow-along' practice feature with timer, (5) creating desk exercise routines for office workers."
---
```

# Exercise & Movement Tutorial System

## Overview
Manage traditional Chinese exercise tutorials (八段锦, 太极, 五禽戏) and modern wellness movement (stretching, desk exercises, yoga), with step-by-step guides, video content, and personalized recommendations.

## Exercise Categories

| Category | Code | Content |
|----------|------|---------|
| 八段锦 | baduanjin | 8 movements, complete tutorial |
| 太极基础 | taichi | Standing meditation, basic forms |
| 五禽戏 | wuqinxi | 5 animal movements |
| 办公室操 | desk_exercise | 5-minute routines for desk workers |
| 晨起拉伸 | morning_stretch | Morning wake-up stretches |
| 睡前放松 | evening_wind_down | Pre-sleep relaxation |
| 颈椎操 | neck_exercise | Cervical spine exercises |
| 眼保健操 | eye_exercise | Eye protection exercises |

## Follow-Along Practice Feature

Implement an interactive practice mode:
```
1. Display current step with image/video.
2. Show step title and instructions.
3. Show breathing cue ("吸气" / "呼气").
4. Timer for each step (countdown).
5. Audio guidance (optional).
6. Auto-advance to next step or manual control.
7. Completion summary (total time, calories estimate).
```

## Constitution-Based Exercise Matching

| Constitution | Recommended | Avoid |
|-------------|------------|-------|
| 气虚 | 太极、八段锦、散步 | 剧烈运动、大汗 |
| 阳虚 | 太极、快走、阳光下运动 | 寒冷环境运动 |
| 阴虚 | 瑜伽、游泳、太极 | 热瑜伽、高强度 |
| 痰湿 | 快走、跑步、游泳 | 久坐不动 |
| 湿热 | 游泳、跑步、球类 | — |
| 血瘀 | 跑步、太极、跳绳 | 久坐 |
| 气郁 | 跑步、登山、跳舞、团体运动 | 独处不动 |
| 特禀 | 太极、八段锦、室内运动 | 花粉季户外 |

## Reference Files
- `references/baduanjin_full.json` — Complete 八段锦 8 movements.
- `references/exercise_database.json` — All exercise tutorials.
- `references/constitution_exercise_map.json` — Constitution × exercise matching.
- `scripts/seed_exercises.py` — Database seeding.

---

# Skill 8: shunshi-sleep

## SKILL.md

```yaml
---
name: shunshi-sleep
description: "睡眠养生系统。管理助眠音频库、呼吸练习、睡前仪式引导、十二时辰睡眠理论、睡眠质量追踪和分析。Use when: (1) building the sleep audio library (nature sounds, sleep stories, guided meditations), (2) implementing breathing exercises (4-7-8, box breathing), (3) creating the bedtime routine feature, (4) implementing sleep tracking and analysis, (5) providing sleep improvement recommendations based on constitution."
---
```

# Sleep Wellness System

## Overview
Comprehensive sleep improvement system combining Traditional Chinese Medicine sleep theory (十二时辰), audio content (sleep stories, nature sounds, guided meditation), breathing exercises, bedtime routines, and sleep quality tracking.

## TCM Sleep Theory — 十二时辰

| Shichen | Time | Organ | Sleep Relevance |
|---------|------|-------|----------------|
| 子时 | 23:00–01:00 | 胆 | Must be asleep (deep sleep phase) |
| 丑时 | 01:00–03:00 | 肝 | Must be asleep (liver detox) |
| 寅时 | 03:00–05:00 | 肺 | Deep sleep → light sleep transition |
| 卯时 | 05:00–07:00 | 大肠 | Natural wake time |

Key principle: User should be asleep before 子时 (23:00) for optimal liver and gallbladder recovery.

## Audio Content Library

### Categories:
1. **助眠音频** (Sleep Sounds): Rain, forest, ocean, fireplace, white noise
2. **睡眠故事** (Sleep Stories): Narrated calming stories (15–20 min)
3. **冥想引导** (Guided Meditation): Body scan, progressive relaxation
4. **呼吸练习** (Breathing): 4-7-8, box breathing, with audio guidance

### Audio Player Requirements:
- Background playback support
- Sleep timer (15/30/45/60 min, end of track)
- Volume fade-out at timer end
- Lock screen controls
- Offline download (premium)

## Breathing Exercises

### 4-7-8 Breathing
```
Animation states:
1. INHALE (4 seconds): Circle expands, text "吸气 4..."
2. HOLD (7 seconds): Circle holds, text "屏住 7..."
3. EXHALE (8 seconds): Circle contracts, text "呼气 8..."
4. Repeat 3-4 cycles
5. Haptic feedback at transitions
```

### Box Breathing (4-4-4-4)
```
1. INHALE (4s) → HOLD (4s) → EXHALE (4s) → HOLD (4s)
2. Visual: Square animation with dot tracing edges
3. Repeat 4-6 cycles
```

## Bedtime Routine Feature

Guided evening routine sequence:
```
1. 泡脚 (Foot soak) — 20 min timer, instructions
2. 穴位按摩 (Acupoint massage) — 涌泉穴、神门穴 guide
3. 呼吸练习 (Breathing) — 4-7-8 exercise
4. 睡眠日记 (Journal) — Quick sleep intention
5. 助眠音频 (Audio) — Start sleep audio
```

## Sleep Quality Analysis

```python
def analyze_sleep(journal_entry):
    """
    Factors:
    1. Bedtime (before 23:00 = good)
    2. Duration (7-8h optimal for adults)
    3. Quality score (user-reported 1-10)
    4. Wake-ups during night
    5. Consistency (compared to user's average)
    
    Returns: score (0-100), insights, recommendations
    """
    score = 0
    insights = []
    
    bedtime_hour = journal_entry.sleep_bedtime.hour
    if bedtime_hour < 23:
        score += 25
    elif bedtime_hour == 23:
        score += 15
    else:
        insights.append("入睡时间偏晚，建议在23:00前入睡")
    
    # Duration
    duration = calculate_duration(journal_entry.sleep_bedtime, journal_entry.sleep_waketime)
    if 7 <= duration <= 8.5:
        score += 25
    elif 6 <= duration < 7 or 8.5 < duration <= 9:
        score += 15
    else:
        insights.append(f"睡眠时长{duration}小时，建议保持7-8小时")
    
    # Quality
    quality = journal_entry.sleep_quality or 5
    score += quality * 3  # max 30
    
    # Consistency
    avg_bedtime = get_user_avg_bedtime(journal_entry.user_id)
    if abs(bedtime_hour - avg_bedtime) <= 1:
        score += 20
    
    return {"score": min(score, 100), "insights": insights}
```

## Reference Files
- `references/audio_content_catalog.json` — Audio library metadata.
- `references/breathing_exercises.json` — Exercise definitions.
- `references/bedtime_routine_steps.json` — Routine sequence.
- `references/sleep_constitution_advice.json` — Constitution-specific sleep advice.
- `scripts/seed_audio.py` — Audio content seeding.

---

# Skill 9: shunshi-journal

## SKILL.md

```yaml
---
name: shunshi-journal
description: "养生日记与报告系统。记录睡眠/饮食/运动/情绪/身体状况，生成AI分析和周/月/年度养生报告。Use when: (1) building the daily wellness journal entry UI and API, (2) implementing calendar view with logged days, (3) generating AI-powered daily insights, (4) creating weekly/monthly/annual wellness reports with charts, (5) computing wellness statistics and trends."
---
```

# Wellness Journal & Report System

## Overview
Daily wellness tracking system covering sleep, diet, exercise, mood, and body condition, with AI-generated insights and periodic wellness reports.

## Daily Journal Entry Structure

See database schema. The journal entry captures 5 modules:
1. **Sleep**: bedtime, wake time, quality (1-10), dreams, wake-ups
2. **Diet**: meals (breakfast/lunch/dinner/snacks), water intake, tea, alcohol
3. **Exercise**: type, duration, intensity
4. **Mood**: score (1-10), primary emotion, stress level, triggers
5. **Body**: energy level, discomfort, bowel movement

Plus: completed wellness actions checklist.

## Calendar View

- Month view: dots on days with entries.
- Color coding by overall score:
  - Green (≥70): Good day
  - Yellow (40-69): Average
  - Red (<40): Needs attention
- Streak counter: consecutive days logged.

## AI Daily Insight

After user saves a journal entry, trigger async AI analysis:

```python
@celery.task
def generate_journal_insight(journal_id):
    journal = WellnessJournal.query.get(journal_id)
    user = journal.user
    solar_term = get_current_solar_term()
    
    # Gather recent history for context
    recent = WellnessJournal.query.filter(
        WellnessJournal.user_id == user.id,
        WellnessJournal.journal_date >= journal.journal_date - timedelta(days=7)
    ).all()
    
    prompt = f"""分析今日养生日记（100字以内，温和实用）：
体质：{user.constitution_type}，节气：{solar_term.name_cn}
睡眠：{journal.sleep_bedtime}-{journal.sleep_waketime}，质量{journal.sleep_quality}/10
饮食：早{journal.diet_breakfast}午{journal.diet_lunch}晚{journal.diet_dinner}
运动：{journal.exercise_type} {journal.exercise_duration}分钟
心情：{journal.mood_score}/10 {journal.mood_primary}
精力：{journal.energy_level}/10
近7天趋势：睡眠均分{avg_sleep}，情绪均分{avg_mood}
给出1条肯定+1条建议。"""
    
    insight = call_ai(prompt)
    journal.ai_analysis = insight
    db.session.commit()
```

## Weekly Report Generation

Every Monday at 06:00 generate weekly report:

```python
def generate_weekly_report(user_id, week_start, week_end):
    journals = get_journals_in_range(user_id, week_start, week_end)
    
    report = {
        "sleep_analysis": {
            "avg_quality": mean([j.sleep_quality for j in journals if j.sleep_quality]),
            "avg_duration": calculate_avg_duration(journals),
            "best_day": find_best_sleep_day(journals),
            "trend": "improving" / "stable" / "declining"
        },
        "mood_analysis": {
            "avg_score": mean([j.mood_score for j in journals if j.mood_score]),
            "dominant_emotion": find_dominant_emotion(journals),
            "stress_avg": mean([j.stress_level for j in journals if j.stress_level])
        },
        "exercise_analysis": {
            "active_days": count_active_days(journals),
            "total_minutes": sum_exercise_minutes(journals)
        },
        "overall_score": calculate_overall_score(journals),
        "chart_data": generate_chart_data(journals)
    }
    
    # AI summary
    report["summary"] = call_ai(build_report_prompt(report))
    report["recommendations"] = call_ai(build_recommendations_prompt(report, user))
    
    save_report(user_id, "weekly", week_start, week_end, report)
```

## Reference Files
- `references/journal_schema.json` — Complete entry schema.
- `references/report_templates.json` — Report structure templates.
- `references/mood_tags.json` — Emotion tag definitions.
- `scripts/generate_report.py` — Report generation logic.

---

# Skill 10: shunshi-recommendation

## SKILL.md

```yaml
---
name: shunshi-recommendation
description: "个性化推荐引擎。基于用户体质、当前节气、时辰、历史数据生成个性化养生推荐内容。Use when: (1) building the home page personalized recommendations, (2) implementing the 'recommended for you' content feeds, (3) computing user preference models from behavior data, (4) cross-referencing constitution × solar term for targeted advice, (5) generating 'today's wellness plan'."
---
```

# Personalized Recommendation Engine

## Overview
Multi-factor recommendation engine that combines constitution type, current solar term, time of day, user history, and behavior signals to generate personalized daily wellness plans and content feeds.

## Recommendation Dimensions

| Dimension | Weight | Source |
|-----------|--------|--------|
| Constitution Type | 40% | User profile (constitution_type) |
| Current Solar Term | 30% | Solar term engine (current term) |
| Time of Day / Shichen | 15% | System clock → shichen mapping |
| User History & Preference | 15% | Journal data, favorites, views |

## Home Page Aggregation API

```
GET /api/v1/home

Response:
{
  "current_solar_term": { ... },
  "days_to_next_term": 12,
  "daily_tips": {
    "diet": "今日宜食山药枸杞粥，健脾补肾",
    "tea": "推荐枸杞红枣茶，补气养血",
    "acupoint": "按揉足三里5分钟，增强免疫",
    "exercise": "下午适合做八段锦第三式",
    "sleep": "今晚宜22:30前入睡，养肝护阳"
  },
  "checkin_status": { "completed": ["泡脚","喝茶"], "pending": ["运动","穴位"] },
  "streak_days": 14,
  "recommended_recipes": [ ... ],
  "recommended_articles": [ ... ],
  "recommended_audio": [ ... ]
}
```

## Cross-Reference Matrix

Load from `references/solar_term_constitution_matrix.json`:
```json
{
  "lichun": {
    "qixu": {
      "diet_focus": "补气升阳",
      "key_foods": ["黄芪","红枣","山药"],
      "key_tea": "黄芪红枣茶",
      "key_acupoint": "足三里",
      "exercise": "八段锦（轻度）"
    },
    "yangxu": { ... },
    ...
  },
  ...
}
```

This matrix covers 24 solar terms × 9 constitution types = 216 combinations.

## Reference Files
- `references/solar_term_constitution_matrix.json` — 216-combination cross-reference.
- `references/shichen_advice.json` — 12 shichen wellness advice.
- `scripts/build_recommendation_cache.py` — Pre-compute and cache recommendations.

---

# Skill 11: shunshi-notification

## SKILL.md

```yaml
---
name: shunshi-notification
description: "智能提醒推送系统。管理节气提醒、作息提醒、饮水提醒、运动提醒等定时推送，支持个性化提醒内容和时间设置。Use when: (1) implementing push notification scheduling and delivery, (2) building reminder configuration UI, (3) creating notification templates for solar terms/sleep/water/exercise, (4) implementing streak reminder and re-engagement notifications."
---
```

# Smart Notification System

## Notification Types

| Type | Trigger | Default Time | Content Source |
|------|---------|-------------|---------------|
| solar_term | New solar term date | 07:00 | Solar term engine |
| wake_reminder | Daily | User's preferred wake time | Constitution advice |
| sleep_reminder | Daily | User's preferred sleep time - 30min | Sleep wellness |
| water_reminder | Interval | Every 2 hours (09:00–18:00) | Generic + seasonal |
| exercise_reminder | Daily | User configured | Constitution-based |
| journal_reminder | Daily | 21:00 | Generic |
| streak_at_risk | Missed 1 day | 10:00 next day | Re-engagement |
| weekly_report | Weekly | Monday 08:00 | Report system |

## Notification Templates

```json
{
  "solar_term": {
    "title": "今日{solar_term_name}",
    "body": "{solar_term_name}到了，{one_line_advice}",
    "action": "navigate://solar-term/{code}"
  },
  "sleep_reminder": {
    "title": "该准备休息了",
    "body": "{constitution_sleep_advice}",
    "action": "navigate://sleep"
  },
  "water_reminder": {
    "title": "记得喝水",
    "body": "已经过了{hours}小时，喝杯{seasonal_recommendation}吧",
    "action": "navigate://journal"
  }
}
```

## Implementation

Use JPush (极光推送) for China market:

```python
@celery.task
def send_scheduled_notifications():
    """Run every minute. Check for due notifications."""
    now = datetime.now(tz=CST)
    current_time = now.time()
    
    # Sleep reminders
    users_due = User.query.filter(
        User.notification_enabled == True,
        User.preferred_sleep_time - timedelta(minutes=30) == current_time.replace(second=0)
    ).all()
    
    for user in users_due:
        content = generate_sleep_reminder(user)
        push_notification(user.device_token, content)
```

## Reference Files
- `references/notification_templates.json` — All notification templates.
- `references/notification_schedule.json` — Default schedules.
- `scripts/send_notification.py` — JPush integration helper.

---

# Skill 12: shunshi-family

## SKILL.md

```yaml
---
name: shunshi-family
description: "家庭养生系统。实现家庭成员绑定、父母养生关怀、家庭养生报告、代付会员功能。Use when: (1) implementing family member invite/bind flow, (2) building the parent wellness care feature, (3) generating family wellness dashboards, (4) implementing family membership payment, (5) creating wellness care reminders for family members."
---
```

# Family Wellness System

## Features
1. **Family Binding**: Invite/accept family members via invite code or link.
2. **Parent Care**: View parent's wellness status, send care reminders.
3. **Family Report**: Aggregated family wellness dashboard.
4. **Family Membership**: One subscription, up to 4 family members.

## Invite Flow
```
User A generates invite link → Share via WeChat/SMS
→ User B opens link → Downloads app / Opens app
→ B accepts invitation → A and B are linked
→ Both receive notification: "家庭成员已绑定"
```

## Parent Care Dashboard
子女可以看到:
- 父母今日是否打卡
- 父母近7天的养生评分趋势
- 父母的体质和当前节气建议
- 一键发送关怀提醒

## Reference Files
- `references/family_invite_flow.json` — Invite flow specification.
- `references/family_dashboard_schema.json` — Dashboard data structure.
- `scripts/generate_family_report.py` — Family report generator.

---

# Skill 13: shunshi-membership

## SKILL.md

```yaml
---
name: shunshi-membership
description: "会员订阅与支付系统。管理会员方案、支付集成(微信/支付宝/Apple IAP)、订阅生命周期、积分体系、邀请奖励。Use when: (1) implementing membership plans and pricing, (2) integrating WeChat Pay, Alipay, and Apple IAP, (3) managing subscription lifecycle (create/renew/cancel/expire), (4) building the points/rewards system, (5) implementing referral rewards."
---
```

# Membership & Payment System

## Plans

| Plan | Price (CNY) | Duration | Features |
|------|------------|----------|----------|
| Free | 0 | — | 3 AI chats/day, basic content, 1 quiz |
| Monthly | 25/mo | 1 month | Unlimited AI, full content, reports |
| Annual | 199/yr | 1 year | All monthly + courses + community |
| Family | 299/yr | 1 year | Annual + up to 4 family members |

## Payment Integration

### WeChat Pay
```python
def create_wechat_order(user_id, plan):
    order = create_order(user_id, plan)
    result = wechat_pay.unified_order(
        body=f"顺时会员-{plan.name}",
        out_trade_no=order.order_no,
        total_fee=int(order.actual_price * 100),
        notify_url=f"{API_URL}/api/v1/payment/wechat/callback"
    )
    return {"prepay_id": result["prepay_id"], "order_no": order.order_no}
```

### Apple IAP
```python
def verify_apple_receipt(receipt_data):
    result = apple_iap.verify(receipt_data, APPLE_SHARED_SECRET)
    if result.is_valid:
        activate_membership(result.user_id, result.product_id, result.expires_date)
```

## Subscription Lifecycle

```
Created → Paid → Active → [Auto-renew or Expire]
                        → [Cancel → Expires at period end]
                        → [Refund → Immediate deactivation]
```

## Points System

| Action | Points | Frequency |
|--------|--------|-----------|
| Daily check-in | 5 | Daily |
| Complete journal | 10 | Daily |
| Complete constitution quiz | 20 | Once |
| Share to social media | 10 | Daily max 1 |
| Referral (registration) | 50 | Per referral |
| Referral (paid conversion) | 100 | Per conversion |

## Referral System
- Each user has unique referral code.
- Invite friend to register: Both get 7-day premium.
- Friend pays: Inviter gets 30-day premium extension.

## Reference Files
- `references/payment_config.json` — Payment gateway configurations.
- `references/plan_definitions.json` — Plan details and pricing.
- `references/points_rules.json` — Points earning/spending rules.
- `scripts/verify_payment.py` — Payment verification helpers.

---

# Skill 14: shunshi-content-cms

## SKILL.md

```yaml
---
name: shunshi-content-cms
description: "内容管理系统。管理文章、音频、视频等养生内容的创建/编辑/发布/分类/搜索，支持Markdown编辑和多媒体管理。Use when: (1) building the content management backend (articles, audio, video), (2) implementing content search with Meilisearch, (3) managing content publishing workflow, (4) building content categorization and tagging, (5) implementing content view/like/save/share tracking."
---
```

# Content Management System

## Content Types

| Type | Storage | Format | Premium Support |
|------|---------|--------|----------------|
| Articles | PostgreSQL + Meilisearch | Markdown → HTML | Yes |
| Audio | OSS + PostgreSQL | MP3/AAC | Yes |
| Video | OSS + PostgreSQL | MP4 | Yes |
| Images | OSS + CDN | WebP/JPEG | No |

## Article Management

Articles use Markdown with frontmatter:
```markdown
---
title: "立春养肝，记住这5个方子"
category: solar_term
tags: ["立春", "养肝", "食疗"]
solar_term: lichun
constitutions: ["qixu", "qiyu"]
is_premium: false
---

正文内容（Markdown格式）...
```

## Full-Text Search (Meilisearch)

Index configuration:
```python
MEILISEARCH_INDEXES = {
    "recipes": {
        "searchableAttributes": ["title", "subtitle", "functions", "ingredients.name"],
        "filterableAttributes": ["seasons", "suitable_constitutions", "category", "is_premium"],
        "sortableAttributes": ["created_at", "view_count", "like_count"]
    },
    "articles": {
        "searchableAttributes": ["title", "subtitle", "content", "tags"],
        "filterableAttributes": ["category", "solar_term_code", "is_premium"],
        "sortableAttributes": ["published_at", "view_count"]
    },
    "teas": {
        "searchableAttributes": ["name", "ingredients.name", "functions"],
        "filterableAttributes": ["seasons", "suitable_constitutions"]
    },
    "acupoints": {
        "searchableAttributes": ["name_cn", "name_pinyin", "functions", "indications"],
        "filterableAttributes": ["meridian", "related_constitutions"]
    }
}
```

## Unified Search API

```
GET /api/v1/search?q=失眠&type=all&page=1&limit=20

Response:
{
  "results": {
    "recipes": [...],
    "articles": [...],
    "teas": [...],
    "acupoints": [...],
    "exercises": [...]
  },
  "total": 42,
  "query": "失眠"
}
```

## Content Analytics

Track per content item:
- view_count (increment on detail page view)
- like_count (toggle like)
- save_count (add to favorites)
- share_count (share action triggered)

## Reference Files
- `references/content_categories.json` — Category taxonomy.
- `references/meilisearch_config.json` — Search index configurations.
- `scripts/index_content.py` — Meilisearch indexing script.
- `scripts/import_articles.py` — Batch article import.

---

# Skill 15: shunshi-emotion

## SKILL.md

```yaml
---
name: shunshi-emotion
description: "情绪调养系统。基于中医七情理论和现代情绪管理方法，提供情绪识别、调养建议、冥想引导、呼吸练习、正念练习。Use when: (1) building mood tracking and emotional wellness features, (2) implementing the emotion-organ connection (七情与脏腑), (3) creating guided meditation and mindfulness content, (4) providing emotion-specific food/tea/acupoint recommendations, (5) generating mood trend analysis and insights."
---
```

# Emotional Wellness System

## TCM Seven Emotions Theory (七情)

| Emotion | Organ | Excess Effect | Regulation Method |
|---------|-------|--------------|-------------------|
| 怒 (Anger) | 肝 (Liver) | Headache, hypertension | 深呼吸, 太冲穴 |
| 喜 (Joy) | 心 (Heart) | Restlessness | 静心冥想 |
| 思 (Overthinking) | 脾 (Spleen) | Poor appetite | 运动, 转移注意力 |
| 忧/悲 (Grief) | 肺 (Lung) | Shortness of breath | 倾诉, 社交 |
| 恐 (Fear) | 肾 (Kidney) | Incontinence | 补肾, 壮胆 |

## Emotion-Based Recommendations

When user logs a mood, provide targeted recommendations:

```python
EMOTION_RECOMMENDATIONS = {
    "anxious": {
        "tea": "玫瑰花茶 或 菊花茶",
        "acupoint": "太冲穴（疏肝理气）",
        "exercise": "4-7-8呼吸法",
        "meditation": "身体扫描冥想",
        "food": "百合莲子粥"
    },
    "sad": {
        "tea": "玫瑰红枣茶",
        "acupoint": "内关穴（宁心安神）",
        "exercise": "散步或跑步",
        "meditation": "慈悲冥想",
        "food": "红枣桂圆汤"
    },
    "angry": {
        "tea": "菊花决明子茶",
        "acupoint": "太冲穴 + 合谷穴",
        "exercise": "八段锦第二式",
        "meditation": "数息冥想",
        "food": "芹菜汁"
    },
    "tired": {
        "tea": "黄芪红枣茶",
        "acupoint": "足三里",
        "exercise": "轻度拉伸",
        "meditation": "正念休息",
        "food": "山药枸杞粥"
    }
}
```

## Guided Practices

### Mindfulness Meditation Library
1. **呼吸觉察** (Breath Awareness) — 5/10/15 min
2. **身体扫描** (Body Scan) — 10/15/20 min
3. **慈悲冥想** (Loving-Kindness) — 10 min
4. **正念行走** (Walking Meditation) — 10/20 min
5. **感恩冥想** (Gratitude Meditation) — 10 min

### Mood Trend Analysis

```python
def analyze_mood_trends(user_id, days=30):
    journals = get_recent_journals(user_id, days)
    
    return {
        "avg_mood": mean([j.mood_score for j in journals]),
        "avg_stress": mean([j.stress_level for j in journals]),
        "mood_trend": calculate_trend([j.mood_score for j in journals]),
        "most_common_emotion": find_mode([j.mood_primary for j in journals]),
        "best_day_of_week": find_best_weekday(journals),
        "worst_day_of_week": find_worst_weekday(journals),
        "correlation_sleep_mood": correlate(
            [j.sleep_quality for j in journals],
            [j.mood_score for j in journals]
        ),
        "chart_data": {
            "dates": [j.journal_date.isoformat() for j in journals],
            "mood_scores": [j.mood_score for j in journals],
            "stress_levels": [j.stress_level for j in journals]
        }
    }
```

## Seasonal Emotion Patterns

| Season | Common Pattern | Focus |
|--------|---------------|-------|
| Spring | Irritability, restlessness | 疏肝理气, 户外活动 |
| Summer | Anxiety, overexcitement | 清心降火, 静养 |
| Autumn | Sadness, melancholy | 润肺开怀, 社交 |
| Winter | Depression, low energy | 温阳补肾, 晒太阳 |

## Reference Files
- `references/emotion_organ_map.json` — Seven emotions TCM mapping.
- `references/emotion_recommendations.json` — Emotion → recommendation map.
- `references/meditation_library.json` — Guided meditation catalog.
- `references/mood_analysis_rules.json` — Trend analysis rules.
- `scripts/analyze_mood.py` — Mood analysis script.
-e 

---


# 顺时项目 Skills 合集 — 第二批（Skill 16–50）

---

# Skill 16: shunshi-shichen

```yaml
---
name: shunshi-shichen
description: "十二时辰养生系统。根据当前时辰（子丑寅卯辰巳午未申酉戌亥）提供对应脏腑的实时养生建议，包括当时辰最佳养生行为、饮食、穴位。Use when: (1) displaying real-time shichen-based wellness tips, (2) providing time-of-day organ care advice, (3) building the shichen clock widget, (4) generating 'what to do right now' suggestions."
---
```

# Twelve Shichen (时辰) Wellness System

## Shichen-Organ Mapping

```python
SHICHEN_MAP = {
    (23, 1):  {"name": "子时", "organ": "胆",   "advice": "深睡养胆，此时必须入睡", "action": "sleep", "avoid": "熬夜、进食"},
    (1, 3):   {"name": "丑时", "organ": "肝",   "advice": "深睡养肝血，肝脏排毒时间", "action": "sleep", "avoid": "饮酒"},
    (3, 5):   {"name": "寅时", "organ": "肺",   "advice": "深睡养肺，呼吸最弱时段", "action": "sleep", "avoid": "起床过早"},
    (5, 7):   {"name": "卯时", "organ": "大肠", "advice": "起床排便，喝温水一杯", "action": "wake_defecate_water", "avoid": "赖床"},
    (7, 9):   {"name": "辰时", "organ": "胃",   "advice": "吃早餐，胃气最旺", "action": "breakfast", "avoid": "不吃早餐"},
    (9, 11):  {"name": "巳时", "organ": "脾",   "advice": "工作学习最佳时段，脾主运化", "action": "work", "avoid": "过食甜腻"},
    (11, 13): {"name": "午时", "organ": "心",   "advice": "午休养心，小憩20-30分钟", "action": "nap", "avoid": "剧烈运动"},
    (13, 15): {"name": "未时", "organ": "小肠", "advice": "小肠吸收营养，适量饮水", "action": "hydrate", "avoid": "暴饮暴食"},
    (15, 17): {"name": "申时", "organ": "膀胱", "advice": "多饮水排毒，适合学习记忆", "action": "water_study", "avoid": "憋尿"},
    (17, 19): {"name": "酉时", "organ": "肾",   "advice": "补肾时段，适度运动", "action": "light_exercise", "avoid": "过劳"},
    (19, 21): {"name": "戌时", "organ": "心包", "advice": "散步放松，愉悦心情", "action": "walk_relax", "avoid": "生气动怒"},
    (21, 23): {"name": "亥时", "organ": "三焦", "advice": "准备入睡，泡脚放松", "action": "prepare_sleep", "avoid": "剧烈运动、手机"},
}
```

## API

```
GET /api/v1/shichen/current
Response: {shichen_name, organ, advice, recommended_action, avoid, recommended_tea, recommended_acupoint, next_shichen_in_minutes}
```

## Shichen Clock Widget

Display a circular 12-segment clock:
- Highlight current shichen segment
- Show organ name and icon
- Show key advice text
- Auto-refresh every minute

---

# Skill 17: shunshi-meridian

```yaml
---
name: shunshi-meridian
description: "经络系统知识库。管理十二正经+奇经八脉的完整知识，包括经络循行路线、主要穴位、对应时辰、常见症状、日常保健方法。Use when: (1) displaying meridian information and diagrams, (2) linking meridians to shichen and organs, (3) recommending meridian-based wellness practices, (4) building meridian education content."
---
```

# Meridian System Knowledge Base

## Twelve Principal Meridians

| Meridian | Code | Organ | Shichen | Key Acupoints | Common Symptoms |
|----------|------|-------|---------|--------------|-----------------|
| 手太阴肺经 | LU | 肺 | 寅时(3-5) | 列缺、鱼际、尺泽 | 咳嗽、气短、鼻塞 |
| 手阳明大肠经 | LI | 大肠 | 卯时(5-7) | 合谷、曲池 | 便秘、牙痛、咽痛 |
| 足阳明胃经 | ST | 胃 | 辰时(7-9) | 足三里、天枢 | 胃痛、消化不良 |
| 足太阴脾经 | SP | 脾 | 巳时(9-11) | 三阴交、血海 | 腹胀、乏力、水肿 |
| 手少阴心经 | HT | 心 | 午时(11-13) | 神门、少府 | 心悸、失眠 |
| 手太阳小肠经 | SI | 小肠 | 未时(13-15) | 后溪 | 肩颈痛 |
| 足太阳膀胱经 | BL | 膀胱 | 申时(15-17) | 肾俞、委中 | 腰痛、头痛 |
| 足少阴肾经 | KI | 肾 | 酉时(17-19) | 涌泉、太溪 | 腰膝酸软、耳鸣 |
| 手厥阴心包经 | PC | 心包 | 戌时(19-21) | 内关、劳宫 | 胸闷、心烦 |
| 手少阳三焦经 | TE | 三焦 | 亥时(21-23) | 外关 | 耳鸣、偏头痛 |
| 足少阳胆经 | GB | 胆 | 子时(23-1) | 风池、阳陵泉 | 偏头痛、口苦 |
| 足厥阴肝经 | LR | 肝 | 丑时(1-3) | 太冲、期门 | 胁痛、情绪不稳 |

## Daily Meridian Care

Recommend self-massage or tapping along the current shichen's meridian:
```python
def get_meridian_care(hour):
    shichen = get_shichen(hour)
    meridian = MERIDIAN_BY_SHICHEN[shichen]
    return {
        "meridian": meridian,
        "massage_method": f"沿{meridian.name}循行方向轻拍或按揉3-5分钟",
        "key_acupoints": meridian.key_acupoints,
        "benefit": meridian.daily_benefit
    }
```

---

# Skill 18: shunshi-food-therapy

```yaml
---
name: shunshi-food-therapy
description: "对症食疗方系统。按照常见症状（失眠、便秘、疲劳、胃痛、月经不调、咳嗽、头痛、脱发等20+症状）提供经典食疗方案，包含配方、做法、注意事项。Use when: (1) user reports a specific symptom, (2) recommending food remedies for common conditions, (3) building the 'symptom → food therapy' lookup feature."
---
```

# Symptom-Based Food Therapy System

## Symptom Categories

```python
SYMPTOM_FOOD_THERAPY = {
    "insomnia": {
        "name": "失眠",
        "therapies": [
            {"name": "酸枣仁粥", "ingredients": "酸枣仁15g、粳米100g", "method": "酸枣仁研末，粳米煮粥，临卧时服", "duration": "连服7-14天"},
            {"name": "百合莲子汤", "ingredients": "百合30g、莲子30g、冰糖", "method": "百合莲子加水炖40分钟", "duration": "每晚睡前1小时"},
            {"name": "龙眼肉粥", "ingredients": "龙眼肉15g、红枣5枚、粳米100g", "method": "同煮成粥", "duration": "晚餐食用"},
            {"name": "牛奶蜂蜜饮", "ingredients": "温牛奶250ml、蜂蜜1勺", "method": "牛奶加热至温热，加蜂蜜", "duration": "睡前30分钟"}
        ],
        "constitution_notes": {
            "yinxu": "加百合、麦冬润阴",
            "qixu": "加黄芪、红枣补气",
            "qiyu": "加玫瑰花疏肝"
        }
    },
    "constipation": { ... },
    "fatigue": { ... },
    "stomachache": { ... },
    "menstrual_pain": { ... },
    "cough": { ... },
    "headache": { ... },
    "hair_loss": { ... },
    "bloating": { ... },
    "cold_hands_feet": { ... },
    "dry_skin": { ... },
    "acne": { ... },
    "weight_gain": { ... },
    "poor_appetite": { ... },
    "frequent_colds": { ... },
    "back_pain": { ... },
    "eye_fatigue": { ... },
    "anxiety": { ... },
    "edema": { ... },
    "night_sweats": { ... }
}
```

## API
```
GET /api/v1/food-therapy?symptom=insomnia&constitution=qixu
→ Returns personalized food therapy recommendations
```

## Safety Rules
1. Always include "如症状持续，请及时就医" disclaimer.
2. Note contraindications for each therapy.
3. Never claim curative effects — use "辅助调理" language.
4. Flag pregnancy-unsafe ingredients.

---

# Skill 19: shunshi-seasonal-recipe-gen

```yaml
---
name: shunshi-seasonal-recipe-gen
description: "AI节气食谱生成器。根据当前节气、用户体质、可用食材、饮食偏好，使用AI生成个性化养生食谱。Use when: (1) user asks 'today what should I eat', (2) generating novel recipe ideas based on seasonal ingredients, (3) adapting recipes to user dietary restrictions, (4) creating weekly seasonal meal plans."
---
```

# AI Seasonal Recipe Generator

## Generation Prompt

```python
def generate_recipe(user, available_ingredients=None):
    solar_term = get_current_solar_term()
    prompt = f"""作为养生食谱专家，请创建一道适合当前节气的养生食谱。

要求：
- 当前节气：{solar_term.name_cn}，养生重点：{solar_term.diet_principle}
- 用户体质：{user.constitution_type}，饮食原则：{get_diet_principle(user.constitution_type)}
- 可用食材：{available_ingredients or '不限'}
- 饮食限制：{user.dietary_restrictions or '无'}

输出JSON格式：
{{
  "title": "食谱名称",
  "description": "一句话介绍",
  "servings": 2,
  "prep_time": 15,
  "cook_time": 30,
  "ingredients": [{{"name": "食材", "amount": "用量"}}],
  "steps": ["步骤1", "步骤2"],
  "wellness_benefits": "养生功效说明",
  "suitable_constitutions": ["适合体质"],
  "tips": "小贴士"
}}"""
    return call_ai_json(prompt)
```

## Weekly Meal Plan Generation

```
POST /api/v1/meal-plan/generate
Body: {days: 7, meals_per_day: 3, preferences: {...}}
→ AI generates 7-day meal plan aligned with solar term + constitution
```

---

# Skill 20: shunshi-herbal-knowledge

```yaml
---
name: shunshi-herbal-knowledge
description: "常用养生中草药/食材知识库。收录100+常用养生食材和药食同源材料的性味归经、功效、用法用量、禁忌。Use when: (1) user asks about a specific herb or ingredient, (2) displaying ingredient details in recipes, (3) checking ingredient-constitution compatibility, (4) building the ingredient encyclopedia feature."
---
```

# Herbal & Ingredient Knowledge Base

## Data Structure

```json
{
  "code": "huangqi",
  "name_cn": "黄芪",
  "name_en": "Astragalus",
  "category": "补气药",
  "nature": "温",
  "flavor": "甘",
  "meridians": ["脾经", "肺经"],
  "functions": ["补气固表", "利水消肿", "托毒生肌"],
  "usage": {
    "daily_dose": "10-30g",
    "common_forms": ["泡水", "煲汤", "煮粥"],
    "best_combination": ["红枣", "枸杞", "党参"]
  },
  "suitable_constitutions": ["qixu", "yangxu"],
  "unsuitable_constitutions": ["yinxu", "shire"],
  "contraindications": "感冒发热期间不宜，阴虚阳亢者慎用",
  "pregnancy_safe": true,
  "is_food_medicine_dual": true
}
```

## API
```
GET /api/v1/herbs — List all herbs with filters
GET /api/v1/herbs/{code} — Herb detail
GET /api/v1/herbs/search?q=补气 — Search by function
GET /api/v1/herbs/compatible?constitution=qixu — Constitution-compatible herbs
```

---

# Skill 21: shunshi-wellness-myth

```yaml
---
name: shunshi-wellness-myth
description: "养生误区纠正系统。收录50+常见养生误区与科学解读，用于AI对话纠错、内容推送、用户教育。Use when: (1) user mentions a wellness myth in chat, (2) generating myth-busting content, (3) building the 'myth vs fact' education feature."
---
```

# Wellness Myth Correction System

## Myth Database (50+ entries)

```json
[
  {
    "id": 1,
    "myth": "喝水越多越好",
    "fact": "成人每天1500-2000ml为宜，过多饮水增加肾脏负担，可能导致水中毒。体质不同饮水量也不同，痰湿体质宜少饮，阴虚体质可多饮。",
    "category": "饮食",
    "severity": "medium",
    "keywords": ["喝水", "多喝水", "八杯水"]
  },
  {
    "id": 2,
    "myth": "养生就是吃保健品",
    "fact": "养生的核心是生活方式调整——规律作息、均衡饮食、适度运动、情绪管理。保健品不能替代健康的生活方式，盲目服用反而可能有害。",
    "category": "观念",
    "severity": "high",
    "keywords": ["保健品", "补品", "吃药"]
  }
]
```

## AI Integration
在AI对话中检测用户提到的误区关键词，触发温和纠正：
```python
def check_myths(user_message):
    for myth in MYTH_DATABASE:
        if any(kw in user_message for kw in myth["keywords"]):
            return myth
    return None
```

---

# Skill 22: shunshi-food-compatibility

```yaml
---
name: shunshi-food-compatibility
description: "食物搭配/相克查询系统。提供常见食物搭配宜忌信息，帮助用户合理搭配饮食。Use when: (1) user asks if two foods can be eaten together, (2) checking recipe ingredient compatibility, (3) building the food compatibility lookup tool."
---
```

# Food Compatibility System

## Compatibility Database

```python
FOOD_INCOMPATIBLE = [
    {"food_a": "柿子", "food_b": "螃蟹", "reason": "两者皆寒凉，同食可能腹泻", "severity": "caution"},
    {"food_a": "牛奶", "food_b": "巧克力", "reason": "草酸影响钙吸收", "severity": "minor"},
    {"food_a": "蜂蜜", "food_b": "豆腐", "reason": "传统认为同食不利消化", "severity": "folk"},
    {"food_a": "绿豆", "food_b": "中药", "reason": "绿豆可能降低药效", "severity": "caution"},
]

FOOD_COMPATIBLE = [
    {"food_a": "番茄", "food_b": "鸡蛋", "benefit": "番茄红素+蛋白质，营养互补"},
    {"food_a": "菠菜", "food_b": "猪肝", "benefit": "铁质+维C，补血效果加倍"},
    {"food_a": "山药", "food_b": "红枣", "benefit": "健脾补气，气虚体质首选"},
]
```

## API
```
GET /api/v1/food-compatibility?food_a=柿子&food_b=螃蟹
→ {"compatible": false, "reason": "...", "severity": "caution"}
```

## Disclaimer
"食物相克理论部分源自传统经验，现代营养学研究表明多数'相克'说法缺乏科学依据。但适当注意搭配有助于营养均衡和消化舒适。"

---

# Skill 23: shunshi-water-tracker

```yaml
---
name: shunshi-water-tracker
description: "智能饮水追踪系统。记录每日饮水量，根据体质/季节/运动量提供个性化饮水目标和提醒，支持多种饮品类型记录。Use when: (1) tracking daily water intake, (2) calculating personalized hydration goals, (3) sending hydration reminders, (4) displaying hydration statistics."
---
```

# Smart Water Tracker

## Personalized Daily Goal

```python
def calculate_water_goal(user):
    base = 1500  # ml
    
    # Constitution adjustment
    CONST_FACTOR = {
        "yinxu": 1.15,   # 阴虚多饮
        "tanshi": 0.9,    # 痰湿少饮
        "shire": 1.1,     # 湿热适量多
        "yangxu": 0.95,   # 阳虚温饮
    }
    base *= CONST_FACTOR.get(user.constitution_type, 1.0)
    
    # Season adjustment
    season = get_current_season()
    if season == "summer":
        base *= 1.2
    elif season == "winter":
        base *= 0.95
    
    return int(base)
```

## Tracking UI
- Water drop animation filling up as user logs
- Quick-add buttons: 200ml / 350ml / 500ml / custom
- Beverage types: 白水、茶、汤、果汁、咖啡
- Daily/weekly/monthly statistics charts
- Constitution-specific water temperature recommendation (温/热/凉)

---

# Skill 24: shunshi-baduanjin

```yaml
---
name: shunshi-baduanjin
description: "八段锦专项教学系统。完整八式分步教学，含视频/图解/呼吸配合/功效说明，支持跟练模式和不同难度版本（站式/坐式）。Use when: (1) providing step-by-step Baduanjin instruction, (2) running follow-along practice sessions, (3) recommending specific movements for health conditions, (4) building seated Baduanjin for elderly users."
---
```

# Baduanjin (八段锦) Complete Tutorial System

## Eight Movements

```json
[
  {
    "number": 1,
    "name": "两手托天理三焦",
    "name_en": "Pressing the Heavens with Two Hands",
    "target_organ": "三焦",
    "steps": [
      {"instruction": "两脚平行站立，与肩同宽", "duration_sec": 5, "breathing": "自然呼吸"},
      {"instruction": "两手掌心向上，十指交叉", "duration_sec": 3, "breathing": "吸气"},
      {"instruction": "翻掌上托，头后仰看手背", "duration_sec": 5, "breathing": "吸气"},
      {"instruction": "稍停片刻", "duration_sec": 3, "breathing": "屏气"},
      {"instruction": "两手分开自体侧下落", "duration_sec": 5, "breathing": "呼气"}
    ],
    "repetitions": 6,
    "benefits": ["调理三焦", "疏通经络", "调整脏腑"],
    "suitable_for": ["all"],
    "cautions": "高血压患者上托时不宜过猛"
  },
  // ... 2-8式
]
```

## Practice Modes
1. **完整版** (Full): 8式全练，约15分钟
2. **精简版** (Quick): 选4式，约8分钟
3. **坐式版** (Seated): 坐姿适配版，老年人/行动不便者
4. **单式详解** (Single): 单独练某一式

## Constitution-Specific Recommendations
| Constitution | Priority Movements | Reason |
|-------------|-------------------|--------|
| 气虚 | 第1、3、6式 | 补气升阳 |
| 阳虚 | 第1、6、7式 | 温阳 |
| 阴虚 | 第4、5式 | 滋阴 |
| 痰湿 | 全部8式（增加次数）| 加大运动量祛湿 |
| 气郁 | 第2、4、7式 | 疏肝理气 |

---

# Skill 25: shunshi-menstrual

```yaml
---
name: shunshi-menstrual
description: "女性经期养生系统。追踪月经周期，提供经前/经期/经后分阶段养生方案（饮食/运动/情绪/穴位），包含痛经缓解方案。Use when: (1) tracking menstrual cycle, (2) providing phase-specific wellness advice, (3) managing period symptoms like cramps, (4) adjusting general wellness recommendations during menstruation."
---
```

# Menstrual Wellness System

## Cycle Phase Wellness

| Phase | Days | Focus | Diet | Exercise | Tea |
|-------|------|-------|------|----------|-----|
| 经前(Pre) | Day -7 to -1 | 疏肝理气 | 玫瑰花茶、少盐 | 瑜伽、散步 | 玫瑰红枣茶 |
| 经期(During) | Day 1-5 | 温经活血 | 红糖姜水、忌冷 | 轻度散步 | 红糖生姜茶 |
| 经后(Post) | Day 6-14 | 补血养阴 | 当归鸡汤、红枣 | 逐渐恢复 | 当归红枣茶 |
| 排卵期(Ovulation) | Day 14-16 | 阴阳转化 | 均衡饮食 | 正常运动 | 枸杞菊花茶 |

## Period Tracking
```python
class MenstrualTracker:
    def log_period(self, user_id, start_date):
        """Record period start, predict next cycle."""
        history = get_period_history(user_id)
        avg_cycle = calculate_avg_cycle(history)  # default 28 days
        predicted_next = start_date + timedelta(days=avg_cycle)
        return {"avg_cycle": avg_cycle, "predicted_next": predicted_next}
    
    def get_current_phase(self, user_id):
        """Determine current menstrual phase."""
        last_period = get_last_period(user_id)
        days_since = (date.today() - last_period.start_date).days
        if days_since <= 5: return "during"
        elif days_since <= 14: return "post"
        elif days_since >= last_period.cycle_length - 7: return "pre"
        else: return "normal"
```

## Cramp Relief Protocol
1. 热敷下腹（暖宫贴）15-20分钟
2. 按揉三阴交穴3分钟
3. 按揉关元穴3分钟
4. 红糖生姜水一杯
5. 侧卧位休息

## Integration
- Menstrual phase adjusts all general recommendations (recipes, exercises, teas)
- AI companion knows menstrual phase and adapts responses
- Notification system sends phase-appropriate reminders

---

# Skill 26: shunshi-pregnancy

```yaml
---
name: shunshi-pregnancy
description: "孕期养生系统。按孕早/中/晚期提供安全饮食、运动、情绪管理建议，标注孕期禁忌食材/穴位/运动，提供孕期营养方案。Use when: (1) user indicates pregnancy, (2) filtering content for pregnancy safety, (3) providing trimester-specific advice, (4) flagging unsafe ingredients or practices for pregnant users."
---
```

# Pregnancy Wellness System

## Trimester Advice Structure

```python
PREGNANCY_ADVICE = {
    "first_trimester": {  # 1-12 weeks
        "diet": {
            "focus": "缓解孕吐，补充叶酸",
            "recommended": ["生姜片含服", "苏打饼干", "小米粥", "酸味水果"],
            "forbidden": ["山楂", "薏苡仁", "螃蟹", "甲鱼", "芦荟", "红花", "益母草"],
            "nutrients": ["叶酸400mcg/天", "维生素B6"]
        },
        "exercise": "轻度散步，避免剧烈运动",
        "forbidden_acupoints": ["合谷穴", "三阴交", "昆仑穴", "至阴穴"],
        "emotion": "情绪波动正常，多与家人沟通"
    },
    "second_trimester": { ... },  # 13-28 weeks
    "third_trimester": { ... }    # 29-40 weeks
}
```

## Content Safety Filter

```python
def filter_for_pregnancy(content_list, trimester):
    """Filter out pregnancy-unsafe content."""
    forbidden_ingredients = PREGNANCY_FORBIDDEN[trimester]
    forbidden_acupoints = PREGNANCY_FORBIDDEN_ACUPOINTS
    
    safe_content = []
    for item in content_list:
        if isinstance(item, Recipe):
            ingredient_names = [i["name"] for i in item.ingredients]
            if not any(f in ingredient_names for f in forbidden_ingredients):
                safe_content.append(item)
        elif isinstance(item, Acupoint):
            if item.name_cn not in forbidden_acupoints:
                safe_content.append(item)
    
    return safe_content
```

## Key Safety Rule
When user.is_pregnant == True:
- ALL recipe recommendations pass through pregnancy filter
- ALL acupoint recommendations exclude forbidden points
- ALL exercise recommendations exclude contraindicated movements
- AI companion always checks pregnancy safety before recommending

---

# Skill 27: shunshi-child-wellness

```yaml
---
name: shunshi-child-wellness
description: "儿童养生系统。为3-12岁儿童提供小儿推拿手法、儿童食谱、睡眠管理、视力保护方案，支持家长为孩子制定养生计划。Use when: (1) parent asks about child wellness, (2) providing pediatric massage techniques, (3) creating child-friendly recipes, (4) managing children's sleep schedules."
---
```

# Children's Wellness System

## Pediatric Massage (小儿推拿) Techniques

```json
[
  {
    "name": "捏脊",
    "indication": "增强免疫力、健脾和胃",
    "method": "从尾骶骨沿脊柱两侧向上捏至大椎穴",
    "repetitions": "3-5遍",
    "best_time": "早晨起床后",
    "age_range": "3-12岁",
    "video_url": "massage/nieji.mp4"
  },
  {
    "name": "摩腹",
    "indication": "消食积、通便",
    "method": "以肚脐为中心顺时针揉腹100次",
    "age_range": "3-12岁"
  },
  {
    "name": "推天河水",
    "indication": "清热退烧",
    "method": "从腕横纹中点推向肘横纹中点100-200次",
    "age_range": "3-6岁",
    "caution": "发热时使用，不发热不推"
  }
]
```

## Age-Specific Sleep Guidelines

| Age | Total Sleep | Nap | Bedtime |
|-----|-----------|-----|---------|
| 3-4 | 11-13h | 1.5-2h | 20:00 |
| 5-6 | 10-11h | 0-1h | 20:30 |
| 7-9 | 9-11h | — | 21:00 |
| 10-12 | 9-10h | — | 21:00 |

## Eye Protection for Screen-Age Kids
- 20-20-20法则
- 每天户外2小时
- 护眼食材：胡萝卜、蓝莓、枸杞、鸡肝
- 护眼操5步（详见references/eye_exercise.json）

---

# Skill 28: shunshi-elderly-care

```yaml
---
name: shunshi-elderly-care
description: "老年人养生关怀系统。针对60岁以上用户提供防跌倒指南、慢病饮食管理、认知训练、简化版功法（坐式八段锦）、大字体界面适配。Use when: (1) user is elderly or caring for elderly parents, (2) providing fall prevention advice, (3) managing chronic disease lifestyle support, (4) building accessibility features for seniors."
---
```

# Elderly Care Wellness System

## Fall Prevention Checklist
```json
{
  "home_safety": [
    "室内照明充足，夜灯常开",
    "浴室安装扶手和防滑垫",
    "穿防滑鞋，避免拖鞋",
    "地面无障碍物和电线",
    "常用物品置于容易取放处"
  ],
  "rising_protocol": [
    "醒后躺30秒",
    "坐起30秒",
    "站立30秒",
    "确认不头晕后再行走"
  ],
  "daily_exercises": [
    "坐式八段锦",
    "手指操（预防认知衰退）",
    "慢速散步15-20分钟"
  ]
}
```

## Chronic Disease Lifestyle Support

| Condition | Diet Focus | Exercise | Key Reminder |
|-----------|-----------|----------|-------------|
| 高血压 | 控盐<5g/天，多钾 | 太极、散步 | 每日定时量血压 |
| 糖尿病 | 控糖、多纤维 | 餐后30分散步 | 定时监测血糖 |
| 高血脂 | 减少动物脂肪 | 有氧运动 | 定期复查血脂 |
| 骨质疏松 | 补钙1200mg/天 | 负重运动 | 防跌倒 |

**Important:** 慢病管理建议仅为生活方式辅助，必须按医嘱服药和定期检查。

## Senior-Friendly UI Adaptations
- 字体放大模式（正文18pt+）
- 高对比度配色
- 简化导航（减少层级）
- 语音播报内容
- 大按钮设计（最小48dp）
- 减少手势操作

---

# Skill 29: shunshi-office-wellness

```yaml
---
name: shunshi-office-wellness
description: "办公室养生专项系统。针对久坐上班族提供5分钟桌边运动、护眼操、颈椎操、养生茶推荐、工间休息提醒，包含完整的上班族一日养生时刻表。Use when: (1) providing desk exercises and stretches, (2) managing work break reminders, (3) building the 'office wellness routine' feature, (4) recommending desk-friendly teas and snacks."
---
```

# Office Wellness System

## One-Day Office Wellness Timeline

```python
OFFICE_TIMELINE = [
    {"time": "07:00", "action": "起床喝温水300ml", "type": "water"},
    {"time": "07:30", "action": "营养早餐（不可省略）", "type": "meal"},
    {"time": "09:00", "action": "到公司，泡一杯养生茶", "type": "tea", "recommend": "枸杞菊花茶"},
    {"time": "10:00", "action": "站起来做颈椎操2分钟", "type": "exercise"},
    {"time": "10:30", "action": "喝水200ml", "type": "water"},
    {"time": "12:00", "action": "午餐：注意营养搭配", "type": "meal"},
    {"time": "12:30", "action": "午休20分钟", "type": "rest"},
    {"time": "14:00", "action": "下午茶：坚果+水果", "type": "snack"},
    {"time": "15:00", "action": "眼保健操+肩部放松", "type": "exercise"},
    {"time": "16:00", "action": "喝水200ml", "type": "water"},
    {"time": "18:00", "action": "下班步行/骑行", "type": "exercise"},
]
```

## 5-Minute Desk Exercises

```json
{
  "neck_exercise": {
    "name": "颈椎操",
    "duration": "2分钟",
    "steps": [
      "前屈后伸各5次",
      "左右侧屈各5次",
      "左右旋转各5次",
      "肩部环绕前后各10圈"
    ]
  },
  "eye_exercise": {
    "name": "护眼操",
    "duration": "2分钟",
    "steps": [
      "闭目养神30秒",
      "眼球上下左右转各5次",
      "远近交替注视30秒",
      "按揉太阳穴30秒"
    ]
  },
  "wrist_exercise": {
    "name": "手腕操",
    "duration": "1分钟",
    "steps": [
      "手腕旋转各10圈",
      "手指张合20次",
      "按揉内关穴1分钟"
    ]
  }
}
```

## Work Break Reminder Integration
每45-60分钟推送一次桌边运动提醒，不同时段推送不同内容：
- 上午：颈椎操 + 眼保健操
- 下午：肩部放松 + 手腕操
- 提醒文案温和不打扰："该活动一下了，跟我做个2分钟颈椎操？"

---

# Skill 30: shunshi-eye-care

```yaml
---
name: shunshi-eye-care
description: "护眼养生系统。提供20-20-20法则提醒、护眼操教学、护眼食材推荐、屏幕使用时间追踪。Use when: (1) implementing eye rest reminders, (2) providing eye exercise tutorials, (3) recommending eye-friendly foods, (4) tracking screen time."
---
```

# Eye Care Wellness System

## 20-20-20 Rule Timer
每20分钟提醒用户：
- 看20英尺（6米）外的物体
- 持续20秒
- 同时做3次慢眨眼

## Eye-Friendly Foods
| Food | Nutrient | Benefit |
|------|----------|---------|
| 枸杞 | 玉米黄质 | 保护黄斑 |
| 胡萝卜 | β-胡萝卜素 | 维护视网膜 |
| 蓝莓 | 花青素 | 缓解视疲劳 |
| 菠菜 | 叶黄素 | 防蓝光伤害 |
| 鸡肝 | 维生素A | 预防夜盲 |

## Eye Exercise (5-step, 3 minutes)
1. 闭目养神30秒
2. 揉天应穴30圈
3. 按揉太阳穴30圈
4. 刮上下眼眶各10次
5. 远眺1分钟

## Constitution-Specific Eye Care
- 阴虚体质：枸杞菊花茶+蒸汽热敷
- 气虚体质：黄芪枸杞茶+远眺训练
- 肝郁体质：菊花决明子茶+按太冲穴

---

# Skill 31: shunshi-stomach-care

```yaml
---
name: shunshi-stomach-care
description: "脾胃养护系统。提供脾胃调理的饮食方案、穴位保健、生活习惯建议，覆盖胃痛、胃胀、消化不良、食欲不振等常见脾胃问题。Use when: (1) user reports digestive issues, (2) providing stomach-friendly recipes, (3) recommending digestive acupoints, (4) building stomach care routines."
---
```

# Stomach & Spleen Care System

## Common Issues & Solutions

```python
STOMACH_SOLUTIONS = {
    "stomach_cold": {
        "name": "胃寒胃痛",
        "symptoms": ["遇冷加重", "喜热饮", "大便稀"],
        "diet": ["生姜红糖水", "小米山药粥", "胡椒猪肚汤"],
        "acupoints": ["中脘穴(温灸)", "足三里"],
        "tea": "生姜红枣茶",
        "avoid": ["冰冷食物", "寒凉水果"]
    },
    "bloating": {
        "name": "胃胀气",
        "symptoms": ["饭后腹胀", "嗳气"],
        "diet": ["白萝卜排骨汤", "陈皮水"],
        "acupoints": ["中脘穴", "天枢穴"],
        "exercise": "饭后散步15分钟，顺时针摩腹100次"
    },
    "poor_appetite": {
        "name": "食欲不振",
        "symptoms": ["不想吃饭", "口淡无味"],
        "diet": ["山楂麦芽水", "山药薏米粥"],
        "acupoints": ["足三里"],
        "tea": "陈皮山楂茶"
    }
}
```

## Spleen-Stomach Daily Routine
1. 晨起：温水一杯 + 腹部按摩
2. 早餐：必须吃，以温热为主
3. 午餐：七分饱，细嚼慢咽
4. 餐后：散步15分钟
5. 晚餐：清淡，18:00-19:00间
6. 睡前：按揉足三里3分钟

---

# Skill 32: shunshi-liver-care

```yaml
---
name: shunshi-liver-care
description: "养肝护肝系统。提供养肝饮食、情绪管理（肝主疏泄）、穴位保健、春季养肝专项方案、解酒护肝方案。Use when: (1) providing liver care advice especially in spring, (2) managing anger/frustration (liver-emotion connection), (3) offering hangover recovery tips, (4) recommending liver-friendly foods and teas."
---
```

# Liver Care Wellness System

## Liver-Emotion Connection
肝主疏泄，主情志。肝气不畅→情绪抑郁、暴躁。
- 疏肝理气食材：玫瑰花、佛手、陈皮、山楂
- 疏肝穴位：太冲穴、期门穴
- 疏肝运动：跑步、登山、大声唱歌

## Spring Liver Care Protocol (春季养肝)
Spring = Liver season in TCM.
```json
{
  "diet": ["韭菜", "香椿", "菠菜", "枸杞", "菊花"],
  "avoid": ["辛辣过度", "过食酸味", "饮酒"],
  "tea": "菊花枸杞茶",
  "acupoints": ["太冲穴3分钟", "期门穴3分钟"],
  "exercise": "散步、踏青、八段锦第二式",
  "emotion": "保持心情舒畅，避免暴怒",
  "sleep": "23:00前入睡（丑时肝脏排毒）"
}
```

## Hangover Recovery (应酬解酒)
```
饮酒前：牛奶或酸奶（保护胃黏膜）
饮酒时：多吃蔬菜和豆制品
饮酒后：蜂蜜水（解酒）+ 葛花茶（解酒护肝）
次日：小米粥养胃 + 枸杞菊花茶养肝
```

---

# Skill 33: shunshi-daily-checkin

```yaml
---
name: shunshi-daily-checkin
description: "每日打卡系统。管理养生行为打卡（泡脚/喝茶/运动/穴位/冥想/早睡等），计算连续天数，生成打卡统计和激励。Use when: (1) implementing daily wellness action check-in, (2) tracking streak days, (3) generating check-in statistics, (4) triggering streak rewards."
---
```

# Daily Check-in System

## Check-in Actions
```python
CHECKIN_ACTIONS = [
    {"code": "early_sleep", "name": "早睡（23:00前）", "icon": "🌙", "points": 5},
    {"code": "morning_water", "name": "晨起一杯温水", "icon": "💧", "points": 3},
    {"code": "breakfast", "name": "吃了早餐", "icon": "🥣", "points": 3},
    {"code": "foot_soak", "name": "泡脚", "icon": "🦶", "points": 5},
    {"code": "acupoint", "name": "按穴位", "icon": "👆", "points": 5},
    {"code": "tea", "name": "喝养生茶", "icon": "🍵", "points": 3},
    {"code": "exercise", "name": "运动30分钟", "icon": "🏃", "points": 5},
    {"code": "baduanjin", "name": "八段锦", "icon": "🧘", "points": 8},
    {"code": "meditation", "name": "冥想", "icon": "🧘‍♀️", "points": 5},
    {"code": "journal", "name": "写养生日记", "icon": "📝", "points": 5},
    {"code": "no_phone", "name": "睡前不看手机", "icon": "📵", "points": 5},
]
```

## Streak System
```python
def update_streak(user_id):
    today_actions = get_today_checkins(user_id)
    if len(today_actions) >= 3:  # 完成3项算有效打卡
        user = get_user(user_id)
        yesterday = date.today() - timedelta(days=1)
        yesterday_count = count_checkins(user_id, yesterday)
        
        if yesterday_count >= 3:
            user.consecutive_days += 1
        else:
            user.consecutive_days = 1
        
        # Milestone rewards
        MILESTONES = {7: 50, 14: 100, 21: 200, 30: 500, 60: 1000, 100: 2000}
        if user.consecutive_days in MILESTONES:
            award_points(user_id, MILESTONES[user.consecutive_days])
            send_milestone_notification(user_id, user.consecutive_days)
```

---

# Skill 34: shunshi-achievement

```yaml
---
name: shunshi-achievement
description: "成就勋章系统。定义养生成就和勋章（节气通/体质达人/打卡冠军/食谱大师等），追踪用户进度，颁发勋章和奖励。Use when: (1) defining achievement criteria, (2) tracking achievement progress, (3) awarding badges, (4) displaying achievement gallery."
---
```

# Achievement & Badge System

## Achievement Categories

```python
ACHIEVEMENTS = {
    # 打卡类
    "streak_7": {"name": "初露锋芒", "desc": "连续打卡7天", "icon": "🌱", "points": 50},
    "streak_21": {"name": "习惯养成", "desc": "连续打卡21天", "icon": "🌿", "points": 200},
    "streak_100": {"name": "百日不辍", "desc": "连续打卡100天", "icon": "🌳", "points": 2000},
    
    # 节气类
    "solar_term_first": {"name": "节气初识", "desc": "第一次查看节气养生", "icon": "📅", "points": 10},
    "solar_term_12": {"name": "半年节气通", "desc": "经历12个节气", "icon": "🌗", "points": 500},
    "solar_term_24": {"name": "节气大师", "desc": "经历全部24个节气", "icon": "🌕", "points": 1000},
    
    # 体质类
    "constitution_tested": {"name": "知己", "desc": "完成体质测试", "icon": "🔍", "points": 20},
    
    # 食谱类
    "recipe_first": {"name": "初入厨房", "desc": "收藏第一个食谱", "icon": "🥄", "points": 10},
    "recipe_50": {"name": "食谱达人", "desc": "收藏50个食谱", "icon": "👨‍🍳", "points": 200},
    
    # 功法类
    "baduanjin_first": {"name": "入门弟子", "desc": "第一次完成八段锦", "icon": "🥋", "points": 20},
    "baduanjin_30": {"name": "功法精进", "desc": "完成30次八段锦", "icon": "🏅", "points": 500},
    
    # 家庭类
    "family_bind": {"name": "家的温暖", "desc": "绑定第一位家人", "icon": "👨‍👩‍👧", "points": 30},
    
    # 社交类
    "share_first": {"name": "分享快乐", "desc": "第一次分享内容", "icon": "📤", "points": 10},
    "invite_3": {"name": "养生传播者", "desc": "成功邀请3位好友", "icon": "🌟", "points": 150},
}
```

---

# Skill 35: shunshi-user-level

```yaml
---
name: shunshi-user-level
description: "用户等级体系。根据积分和使用行为定义用户等级（初级养生者→进阶养生者→养生达人→养生大师），每级解锁专属权益。Use when: (1) computing user level from points, (2) displaying level progress bar, (3) unlocking level-specific perks, (4) showing level badges."
---
```

# User Level System

## Level Definitions

| Level | Name | Points Required | Badge | Perks |
|-------|------|----------------|-------|-------|
| 1 | 养生新手 | 0 | 🌱 | 基础功能 |
| 2 | 初级养生者 | 100 | 🌿 | 解锁更多食谱 |
| 3 | 进阶养生者 | 500 | 🌲 | 专属社群入口 |
| 4 | 养生达人 | 2000 | 🌟 | 专属头像框 |
| 5 | 养生大师 | 5000 | 👑 | VIP客服+专家答疑 |

```python
def calculate_level(total_points):
    THRESHOLDS = [(5000, 5), (2000, 4), (500, 3), (100, 2), (0, 1)]
    for threshold, level in THRESHOLDS:
        if total_points >= threshold:
            return level
    return 1
```

---

# Skill 36: shunshi-share

```yaml
---
name: shunshi-share
description: "分享海报生成系统。将养生内容、体质结果、打卡记录、养生报告等生成精美分享海报/卡片，支持分享到微信/朋友圈/小红书。Use when: (1) generating shareable image cards, (2) creating social sharing flows, (3) building viral sharing features, (4) designing share templates."
---
```

# Share Card Generation System

## Card Types

| Card Type | Trigger | Elements |
|-----------|---------|----------|
| 体质报告卡 | 完成体质测试 | 体质名称+特征+建议+二维码 |
| 节气养生卡 | 节气当日 | 节气名称+插画+养生要点 |
| 打卡成就卡 | 达成连续天数 | 天数+勋章+鼓励文案 |
| 月度报告卡 | 月底 | 健康评分+关键数据+趋势 |
| 食谱分享卡 | 用户收藏食谱 | 食谱图片+名称+功效 |
| 邀请卡 | 用户点击邀请 | 品牌介绍+邀请码+二维码 |

## Card Generation

```python
def generate_share_card(card_type, data, user):
    """
    Use Pillow (PIL) to generate image cards:
    1. Load template background from assets/
    2. Render dynamic text (title, stats, user name)
    3. Add QR code (link to app download / specific content)
    4. Apply brand elements (logo, colors, watermark)
    5. Save as PNG, upload to OSS, return URL
    """
    template = Image.open(f"assets/templates/{card_type}.png")
    draw = ImageDraw.Draw(template)
    
    # Render dynamic content based on card_type
    if card_type == "constitution_result":
        draw.text((x, y), data["type_name"], font=title_font, fill=BRAND_GREEN)
        # ... add characteristics, QR code, etc.
    
    # Save and upload
    buffer = BytesIO()
    template.save(buffer, format="PNG")
    url = upload_to_oss(buffer.getvalue(), f"shares/{user.id}/{card_type}_{uuid4()}.png")
    return url
```

## WeChat Share SDK Integration

```python
def share_to_wechat(share_type, data):
    """
    share_type: 'session' (微信好友) or 'timeline' (朋友圈)
    data: {title, description, image_url, web_page_url}
    """
    # React Native side calls WeChat SDK
    return {
        "platform": "wechat",
        "type": share_type,
        "title": data["title"],
        "description": data["description"],
        "thumbImage": data["image_url"],
        "webpageUrl": data["web_page_url"]
    }
```

---

# Skill 37: shunshi-theme

```yaml
---
name: shunshi-theme
description: "节气主题切换系统。根据当前节气自动切换App的视觉主题（配色/背景图/插画/图标），支持24个节气各有独特视觉风格。Use when: (1) implementing seasonal theme switching, (2) designing solar-term-specific visual assets, (3) building the theme engine with smooth transitions."
---
```

# Seasonal Theme System

## Theme Structure

```python
SOLAR_TERM_THEMES = {
    "lichun": {
        "name": "立春",
        "primary_color": "#7CB342",
        "secondary_color": "#C5E1A5",
        "background_gradient": ["#F1F8E9", "#DCEDC8"],
        "illustration": "themes/lichun_branch.png",
        "home_bg": "themes/lichun_bg.png",
        "icon_set": "spring",
        "font_color": "#33691E"
    },
    "yushui": { ... },
    # ... all 24 solar terms
}
```

## Theme Engine

```python
def get_current_theme():
    solar_term = get_current_solar_term()
    theme = SOLAR_TERM_THEMES[solar_term.code]
    
    # Smooth transition: blend themes 3 days before/after switch
    next_term = get_next_solar_term()
    days_to_next = (next_term.date - date.today()).days
    if days_to_next <= 3:
        next_theme = SOLAR_TERM_THEMES[next_term.code]
        blend_ratio = (3 - days_to_next) / 3
        theme = blend_themes(theme, next_theme, blend_ratio)
    
    return theme
```

## Assets Required
- 24 sets of illustrations (one per solar term)
- 24 background images
- 4 icon sets (spring/summer/autumn/winter)
- 24 home screen hero images
- Transition animations (Lottie)

---

# Skill 38: shunshi-auth

```yaml
---
name: shunshi-auth
description: "用户认证系统。实现手机号验证码登录、微信登录、Apple登录，包含JWT Token管理、刷新机制、设备管理。Use when: (1) implementing phone number + SMS verification login, (2) integrating WeChat OAuth, (3) integrating Apple Sign In, (4) managing JWT tokens and refresh flow, (5) handling multi-device sessions."
---
```

# Authentication System

## Login Flows

### Phone + SMS (Primary)
```
1. POST /auth/sms/send {phone: "13800138000"}
   → Send 6-digit code via Aliyun SMS, cache in Redis (5min TTL)
2. POST /auth/sms/verify {phone: "...", code: "123456"}
   → Verify code → Create/find user → Return access_token + refresh_token
```

### WeChat OAuth
```
1. App calls WeChat SDK → User authorizes → Returns auth_code
2. POST /auth/wechat {code: "wx_auth_code"}
   → Exchange code for access_token + openid via WeChat API
   → Create/find user by openid → Return JWT tokens
```

### Apple Sign In
```
1. App calls Apple Sign In → Returns identityToken + authorizationCode
2. POST /auth/apple {identity_token: "...", authorization_code: "..."}
   → Verify identity_token with Apple → Extract sub (user_id)
   → Create/find user → Return JWT tokens
```

## JWT Token Management
```python
ACCESS_TOKEN_EXPIRE = 24 * 60  # 24 hours in minutes
REFRESH_TOKEN_EXPIRE = 30  # 30 days

def create_tokens(user_id):
    access = jwt.encode(
        {"sub": user_id, "exp": datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE), "type": "access"},
        SECRET_KEY, algorithm="HS256"
    )
    refresh = jwt.encode(
        {"sub": user_id, "exp": datetime.utcnow() + timedelta(days=REFRESH_TOKEN_EXPIRE), "type": "refresh"},
        SECRET_KEY, algorithm="HS256"
    )
    # Store refresh token hash in Redis for revocation
    redis.setex(f"refresh:{user_id}:{hash(refresh)}", REFRESH_TOKEN_EXPIRE * 86400, "valid")
    return {"access_token": access, "refresh_token": refresh}
```

## Rate Limiting
- SMS send: 1 per minute per phone, 5 per hour per phone, 10 per day per phone
- Login attempts: 5 per 15 minutes per IP
- Token refresh: 10 per hour per user

---

# Skill 39: shunshi-analytics

```yaml
---
name: shunshi-analytics
description: "数据分析追踪系统。定义和追踪关键用户行为事件，支持漏斗分析、留存分析、用户分群。Use when: (1) defining event tracking schema, (2) implementing event logging, (3) building analytics dashboards, (4) computing retention and funnel metrics."
---
```

# Analytics System

## Event Schema

```python
EVENTS = {
    # Onboarding funnel
    "app_open": {"props": ["source"]},
    "register_start": {"props": ["method"]},  # phone, wechat, apple
    "register_complete": {"props": ["method"]},
    "onboarding_start": {},
    "constitution_quiz_start": {},
    "constitution_quiz_complete": {"props": ["primary_type", "secondary_type"]},
    "onboarding_complete": {},
    
    # Core actions
    "home_view": {},
    "solar_term_view": {"props": ["solar_term_code"]},
    "recipe_view": {"props": ["recipe_id", "category"]},
    "recipe_save": {"props": ["recipe_id"]},
    "tea_view": {"props": ["tea_id"]},
    "acupoint_view": {"props": ["acupoint_id"]},
    "exercise_start": {"props": ["exercise_id", "category"]},
    "exercise_complete": {"props": ["exercise_id", "duration_sec"]},
    "audio_play": {"props": ["audio_id", "category"]},
    "article_view": {"props": ["article_id", "category"]},
    
    # AI Chat
    "chat_start": {},
    "chat_message_send": {"props": ["session_id"]},
    "chat_daily_limit_hit": {},
    
    # Journal
    "journal_open": {},
    "journal_save": {"props": ["modules_completed"]},  # ["sleep","mood","diet"]
    
    # Check-in
    "checkin_action": {"props": ["action_code"]},
    "streak_milestone": {"props": ["days"]},
    
    # Membership
    "paywall_view": {"props": ["trigger"]},
    "subscription_start": {"props": ["plan", "source"]},
    "subscription_cancel": {"props": ["plan", "reason"]},
    
    # Share & Referral
    "share_card_generate": {"props": ["card_type"]},
    "share_action": {"props": ["platform", "content_type"]},
    "referral_invite_send": {},
    "referral_invite_accept": {},
    
    # Search
    "search_query": {"props": ["query", "results_count"]},
}
```

## Key Funnels to Track

1. **Onboarding**: open → register → quiz_start → quiz_complete → onboarding_complete
2. **Activation**: register → first_recipe_view → first_chat → first_journal → day7_retain
3. **Monetization**: paywall_view → subscription_start
4. **Referral**: share_generate → share_action → referral_accept

---

# Skill 40: shunshi-cache

```yaml
---
name: shunshi-cache
description: "缓存策略系统。定义Redis缓存键、TTL、更新策略，覆盖节气数据、推荐内容、用户会话、热门内容。Use when: (1) designing cache keys and TTL, (2) implementing cache warming, (3) handling cache invalidation, (4) optimizing API response times."
---
```

# Cache Strategy System

## Cache Key Definitions

```python
CACHE_KEYS = {
    # Global (shared across users)
    "current_solar_term": {"key": "global:solar_term:current", "ttl": 3600},
    "solar_term_calendar:{year}": {"ttl": 86400 * 30},
    "popular_recipes": {"key": "global:recipes:popular", "ttl": 3600},
    "popular_articles": {"key": "global:articles:popular", "ttl": 3600},
    
    # Per-user
    "user_profile:{user_id}": {"ttl": 1800},
    "user_recommendations:{user_id}": {"ttl": 1800},
    "user_membership:{user_id}": {"ttl": 300},
    "user_checkin_today:{user_id}": {"ttl": 86400},
    "user_ai_daily_count:{user_id}": {"ttl": 86400},
    
    # Content
    "recipe_detail:{recipe_id}": {"ttl": 3600},
    "article_detail:{article_id}": {"ttl": 3600},
    "tea_detail:{tea_id}": {"ttl": 3600},
    "acupoint_detail:{acupoint_id}": {"ttl": 7200},
}
```

## Cache Warming (Celery Tasks)

```python
@celery.task
def warm_cache():
    """Run every hour to pre-warm critical caches."""
    # Current solar term
    term = compute_current_solar_term()
    redis.setex("global:solar_term:current", 3600, json.dumps(term))
    
    # Popular content
    popular = get_top_recipes(limit=20)
    redis.setex("global:recipes:popular", 3600, json.dumps(popular))
```

## Invalidation Rules
- Solar term change → Flush all `global:*` and `user_recommendations:*`
- Recipe update → Flush `recipe_detail:{id}` and `global:recipes:popular`
- User profile update → Flush `user_profile:{id}` and `user_recommendations:{id}`
- Membership change → Flush `user_membership:{id}`

---

# Skill 41: shunshi-admin-panel

```yaml
---
name: shunshi-admin-panel
description: "管理后台系统。提供内容管理、用户管理、数据看板、推送管理、运营工具等后台功能。Use when: (1) building the admin dashboard, (2) implementing content CRUD in admin, (3) building user management tools, (4) creating operations tools (push, campaigns, banners)."
---
```

# Admin Panel System

## Admin Modules

| Module | Features |
|--------|----------|
| Dashboard | DAU/MAU, 新增用户, 收入, 留存率, 实时在线 |
| User Mgmt | 用户列表/搜索/详情/封禁, 会员管理 |
| Content | 文章/食谱/茶饮/穴位/教程的CRUD |
| Solar Terms | 节气数据管理, 内容编辑 |
| Push | 推送模板管理, 发送推送, 推送历史 |
| Operations | Banner管理, 弹窗管理, 活动管理 |
| Analytics | 数据看板, 导出报表 |
| Settings | 系统配置, 管理员管理 |

## Tech Stack
- Frontend: React + Ant Design Pro
- Auth: Admin-specific JWT with RBAC (Role-Based Access Control)
- Roles: super_admin, content_editor, operations, viewer

## Key APIs
```
/admin/api/v1/dashboard/overview     # 数据总览
/admin/api/v1/users                  # 用户管理
/admin/api/v1/content/articles       # 文章管理
/admin/api/v1/content/recipes        # 食谱管理
/admin/api/v1/push/send              # 发送推送
/admin/api/v1/operations/banners     # Banner管理
/admin/api/v1/operations/campaigns   # 活动管理
```

---

# Skill 42: shunshi-banner

```yaml
---
name: shunshi-banner
description: "运营位/Banner管理系统。管理App首页Banner轮播图、弹窗、活动入口，支持定时上下线、定向人群、点击追踪。Use when: (1) building banner/carousel management, (2) implementing targeted display rules, (3) tracking banner click-through rates."
---
```

# Banner Management System

## Banner Data Structure

```python
class Banner:
    id: UUID
    title: str
    image_url: str
    action_type: str      # "url", "page", "recipe", "article", "campaign"
    action_value: str      # URL or page route or content ID
    position: str          # "home_carousel", "home_popup", "wellness_top"
    priority: int          # Display order
    start_at: datetime
    end_at: datetime
    target_audience: dict  # {"constitution": ["qixu"], "membership": ["free"], "platform": ["ios"]}
    is_active: bool
    click_count: int
    view_count: int
```

## Display Logic
```python
def get_banners(user, position):
    now = datetime.now()
    banners = Banner.query.filter(
        Banner.position == position,
        Banner.is_active == True,
        Banner.start_at <= now,
        Banner.end_at >= now
    ).order_by(Banner.priority).all()
    
    # Filter by target audience
    return [b for b in banners if matches_audience(b.target_audience, user)]
```

---

# Skill 43: shunshi-coupon

```yaml
---
name: shunshi-coupon
description: "优惠券系统。创建/发放/核销会员优惠券，支持新人券、节气券、生日券、分享奖励券等类型。Use when: (1) creating coupon campaigns, (2) distributing coupons to users, (3) applying coupons at checkout, (4) tracking coupon usage."
---
```

# Coupon System

## Coupon Types

| Type | Code | Discount | Trigger | Validity |
|------|------|----------|---------|----------|
| 新人券 | new_user | 年卡减50元 | 注册后7天内 | 7天 |
| 节气券 | solar_term | 年卡8折 | 节气当日 | 3天 |
| 生日券 | birthday | 月卡5折 | 生日当月 | 30天 |
| 分享券 | share_reward | 月卡减10元 | 分享后领取 | 14天 |
| 续费券 | renewal | 年卡续费减30元 | 会员到期前30天 | 30天 |
| 限时券 | flash | 自定义折扣 | 运营活动 | 自定义 |

## Coupon Model

```python
class Coupon:
    id: UUID
    code: str              # Unique coupon code
    type: str              # new_user, solar_term, etc.
    discount_type: str     # "fixed" or "percentage"
    discount_value: float  # 50 (元) or 0.8 (80%)
    applicable_plans: list # ["annual", "monthly"]
    min_purchase: float    # Minimum order amount
    total_quantity: int    # Total available
    used_quantity: int
    start_at: datetime
    end_at: datetime
    is_active: bool

class UserCoupon:
    id: UUID
    user_id: UUID
    coupon_id: UUID
    status: str            # "available", "used", "expired"
    used_at: datetime
    order_id: UUID
```

---

# Skill 44: shunshi-wechat-mini

```yaml
---
name: shunshi-wechat-mini
description: "微信小程序版本。开发顺时微信小程序，包含体质测试、节气养生、基础AI问答等核心功能，用于获客引流到主App。Use when: (1) building the WeChat Mini Program version, (2) implementing the quiz-to-app funnel, (3) sharing mini program cards, (4) WeChat ecosystem integration."
---
```

# WeChat Mini Program

## Tech Stack
- Framework: Taro 3.x (React syntax → 编译到小程序)
- UI: Taro UI
- State: Zustand
- Request: Taro.request

## Mini Program Pages
```
pages/
├── index          # 首页（节气+今日建议）
├── quiz           # 体质测试（核心获客入口）
├── quiz-result    # 测试结果（引导下载App）
├── solar-term     # 当前节气养生
├── recipes        # 精选食谱（展示5个，更多需App）
├── chat           # 简化版AI问答（每日1次）
└── download       # App下载引导页
```

## Mini Program → App Funnel
```
小程序体质测试 → 基础结果展示
→ "想看完整方案？下载顺时App"
→ 引导跳转App Store / 应用商店
→ App端自动匹配体质结果（通过手机号/微信绑定）
```

---

# Skill 45: shunshi-weather-wellness

```yaml
---
name: shunshi-weather-wellness
description: "天气养生联动系统。获取用户所在地实时天气，结合天气状况（温度/湿度/空气质量/降雨）提供即时养生建议。Use when: (1) fetching weather data for user location, (2) generating weather-based wellness tips, (3) adjusting daily recommendations based on weather, (4) sending weather change alerts."
---
```

# Weather-Wellness Integration

## Weather → Wellness Mapping

```python
WEATHER_WELLNESS = {
    "cold_snap": {
        "condition": "temperature_drop >= 8℃ in 24h",
        "advice": "大幅降温，注意保暖，多喝姜枣茶",
        "diet": "羊肉汤、生姜红糖水",
        "acupoint": "关元穴、命门穴"
    },
    "high_humidity": {
        "condition": "humidity >= 80%",
        "advice": "湿气重，宜健脾祛湿",
        "diet": "薏米赤豆汤、冬瓜排骨汤",
        "tea": "陈皮茶",
        "constitution_note": {"tanshi": "特别注意祛湿"}
    },
    "heat_wave": {
        "condition": "temperature >= 35℃",
        "advice": "高温天气，注意防暑降温",
        "diet": "绿豆汤、西瓜、酸梅汤",
        "avoid": "正午外出、剧烈运动"
    },
    "poor_air": {
        "condition": "AQI >= 150",
        "advice": "空气质量差，减少户外运动",
        "tea": "罗汉果茶润肺",
        "exercise": "改为室内运动"
    },
    "rainy": {
        "condition": "rain",
        "advice": "雨天注意防潮，室内运动",
        "diet": "温热食物为主",
        "mood": "阴雨天易情绪低落，听音乐或冥想"
    }
}
```

## Weather API Integration
```python
def get_weather_advice(user):
    location = get_user_location(user)
    weather = fetch_weather(location.latitude, location.longitude)
    
    applicable_conditions = []
    for key, rule in WEATHER_WELLNESS.items():
        if evaluate_condition(rule["condition"], weather):
            applicable_conditions.append(rule)
    
    return applicable_conditions
```

## Push Notification Trigger
When weather conditions change significantly:
```
"今天降温8度，记得多穿衣服，来碗姜枣茶暖暖身子 🍵"
"今天空气质量不太好（AQI 180），建议室内运动，喝杯罗汉果茶润肺"
```

---

# Skill 46: shunshi-smart-alarm

```yaml
---
name: shunshi-smart-alarm
description: "智能养生闹钟。不只是闹钟，起床时播报当日节气养生要点、天气养生建议、今日推荐行动，睡前提醒包含助眠建议。Use when: (1) building the smart alarm with wellness briefing, (2) creating morning/evening wellness summaries, (3) integrating alarm with personalized content."
---
```

# Smart Wellness Alarm

## Morning Alarm Briefing
When alarm triggers, display and optionally read aloud:
```
☀️ 早安，今天是{date}，{solar_term}
🌡 天气：{weather}，{temperature}℃
🌿 今日养生重点：{daily_tip}
🍵 推荐早茶：{morning_tea}
🥣 推荐早餐：{breakfast_suggestion}
💪 今日运动：{exercise_suggestion}
```

## Evening Wind-Down Reminder
Trigger 30 minutes before user's preferred bedtime:
```
🌙 该准备休息了
✅ 今日完成：{completed_actions}
📝 还没记日记？花2分钟记录一下
🦶 建议泡脚20分钟
🍵 推荐晚茶：{evening_tea}
😴 目标入睡时间：{target_bedtime}
```

---

# Skill 47: shunshi-onboarding

```yaml
---
name: shunshi-onboarding
description: "新用户引导流程。设计并实现首次使用的完整引导体验——欢迎页、体质测试引导、偏好设置、通知权限、核心功能介绍。Use when: (1) building the first-time user experience, (2) implementing the onboarding flow screens, (3) optimizing onboarding completion rate, (4) A/B testing onboarding variants."
---
```

# New User Onboarding Flow

## Screen Sequence

```
Screen 1: Welcome
  Illustration: 四季流转动画
  Text: "欢迎来到顺时，让我们一起找回生活的节律"
  Button: [开始体验]

Screen 2: Value Props (3 swipeable cards)
  Card 1: "AI懂你" — 个性化养生建议
  Card 2: "节气养生" — 顺应天时
  Card 3: "温和陪伴" — 不焦虑、不说教

Screen 3: Constitution Quiz Intro
  Text: "每个人的身体都不一样，3分钟了解你的体质"
  Button: [开始测试] / [稍后再说]
  Skip saves user but flags onboarding_quiz_skipped = true

Screen 4-15: Quiz Questions (12 screens if entered)
  Progress bar on top
  Single-select per question

Screen 16: Quiz Result (animated reveal)
  Body type with illustration
  Top 3 characteristics
  "你的专属养生方案已生成"
  Button: [查看方案]

Screen 17: Preferences
  起床时间 / 睡觉时间 (clock pickers)
  性别 (optional)
  生日 (optional, for age-based recommendations)

Screen 18: Notification Permission
  Text: "允许顺时在节气、作息时间温柔提醒你"
  Button: [好的，提醒我] / [暂不需要]

Screen 19: Complete
  Text: "一切准备就绪，开始你的养生之旅 🌿"
  Button: [进入顺时]
```

## Onboarding Metrics
Track completion rate at each step to optimize:
- Screen 1→2: should be >95%
- Quiz start rate: target >70%
- Quiz completion rate: target >80% (of starters)
- Notification permission rate: target >60%
- Full onboarding completion: target >50%

---

# Skill 48: shunshi-offline

```yaml
---
name: shunshi-offline
description: "离线内容缓存系统。支持用户在无网络环境下访问已缓存的食谱、文章、音频内容，会员可下载内容供离线使用。Use when: (1) implementing offline content storage, (2) managing download queue, (3) syncing offline changes when back online, (4) building the downloads management UI."
---
```

# Offline Content System

## Offline Strategy

| Content Type | Free Users | Premium Users |
|-------------|-----------|---------------|
| Viewed recipes | Auto-cache last 20 | Auto-cache last 100 |
| Viewed articles | Auto-cache last 10 | Auto-cache last 50 |
| Audio | Stream only | Download for offline |
| Exercise videos | Stream only | Download for offline |
| Journal entries | Local-first, sync later | Local-first, sync later |

## Implementation
```
Using WatermelonDB for offline-first data:
1. Content detail pages → Cached in local DB on view
2. Premium download → Dedicated download manager
3. Journal → Always write locally first, background sync
4. Sync conflict resolution: Last-write-wins for journal, server-wins for content
```

## Download Manager
```python
# React Native download manager
DownloadQueue = [
    {content_type: "audio", id: "xxx", title: "...", size_mb: 15, status: "downloading", progress: 0.45},
    {content_type: "recipe", id: "xxx", title: "...", size_mb: 0.1, status: "completed"},
]
```

---

# Skill 49: shunshi-deeplink

```yaml
---
name: shunshi-deeplink
description: "深度链接/通用链接系统。支持从外部链接（微信分享、短信、邮件、二维码）直接跳转到App内指定页面，包括节气页、食谱详情、体质测试、邀请页。Use when: (1) implementing universal links / deep links, (2) routing external URLs to app screens, (3) handling deferred deep links for new installs, (4) building QR code-based navigation."
---
```

# Deep Link System

## URL Scheme

```
shunshi://                              # Open app
shunshi://solar-term/{code}            # Solar term page
shunshi://recipe/{id}                  # Recipe detail
shunshi://tea/{id}                     # Tea detail
shunshi://acupoint/{id}                # Acupoint detail
shunshi://exercise/{id}                # Exercise detail
shunshi://article/{id}                 # Article detail
shunshi://quiz                         # Constitution quiz
shunshi://quiz/result/{test_id}        # Quiz result
shunshi://invite/{code}                # Referral invite
shunshi://checkin                      # Daily check-in
shunshi://journal                      # Journal page
shunshi://chat                         # AI chat
```

## Universal Links (HTTPS)
```
https://app.shunshi.com/solar-term/{code}
https://app.shunshi.com/recipe/{id}
https://app.shunshi.com/quiz
https://app.shunshi.com/invite/{code}
```

## Deferred Deep Link (for new installs)
```
User clicks share link → Not installed → App Store
→ Install and first open → SDK detects deferred link
→ Route to intended page after onboarding
```

---

# Skill 50: shunshi-rate-limiter

```yaml
---
name: shunshi-rate-limiter
description: "API频率限制系统。保护API免受滥用，针对不同端点和用户类型设置不同限制策略。Use when: (1) implementing rate limiting middleware, (2) configuring per-endpoint limits, (3) handling rate limit exceeded responses, (4) differentiating limits by user tier."
---
```

# Rate Limiting System

## Rate Limit Rules

```python
RATE_LIMITS = {
    # Auth endpoints
    "auth/sms/send": {"window": 60, "max": 1, "key": "phone"},      # 1/min per phone
    "auth/sms/send_hourly": {"window": 3600, "max": 5, "key": "phone"}, # 5/hour
    "auth/login": {"window": 900, "max": 5, "key": "ip"},           # 5/15min per IP
    
    # AI Chat
    "chat/message_free": {"window": 86400, "max": 3, "key": "user"},   # 3/day free users
    "chat/message_premium": {"window": 60, "max": 10, "key": "user"},  # 10/min premium
    
    # General API
    "api_general": {"window": 60, "max": 60, "key": "user"},        # 60/min per user
    "api_search": {"window": 60, "max": 20, "key": "user"},         # 20/min per user
    
    # Content actions
    "content/like": {"window": 60, "max": 30, "key": "user"},       # 30/min
    "content/save": {"window": 60, "max": 30, "key": "user"},       # 30/min
}
```

## Redis-Based Implementation

```python
from fastapi import Request
import redis

async def rate_limit(request: Request, rule_key: str):
    rule = RATE_LIMITS[rule_key]
    identifier = get_identifier(request, rule["key"])
    redis_key = f"ratelimit:{rule_key}:{identifier}"
    
    current = redis.incr(redis_key)
    if current == 1:
        redis.expire(redis_key, rule["window"])
    
    if current > rule["max"]:
        remaining_ttl = redis.ttl(redis_key)
        raise HTTPException(429, detail={
            "error": "rate_limit_exceeded",
            "retry_after": remaining_ttl,
            "message": "请求过于频繁，请稍后再试"
        })
    
    # Add headers
    response.headers["X-RateLimit-Limit"] = str(rule["max"])
    response.headers["X-RateLimit-Remaining"] = str(rule["max"] - current)
    response.headers["X-RateLimit-Reset"] = str(remaining_ttl)
```
-e 

---


# 顺时项目 Skills 合集 — 第三批（Skill 51–100）

---

# Skill 51: shunshi-lung-care
```yaml
---
name: shunshi-lung-care
description: "润肺养肺系统。秋季重点养生模块，提供润肺食疗（银耳/百合/雪梨）、呼吸训练、穴位保健、空气质量联动建议。Use when: (1) providing lung-care advice especially in autumn, (2) recommending moisturizing foods for dry conditions, (3) offering breathing exercises for respiratory wellness."
---
```
# Lung Care System
## Autumn Lung Protocol
- **Foods:** 百合、银耳、雪梨、蜂蜜、芝麻、莲藕
- **Teas:** 罗汉果茶、百合枸杞茶、川贝雪梨水
- **Acupoints:** 列缺穴、鱼际穴、肺俞穴
- **Breathing:** 腹式呼吸练习（每天10分钟）
- **Avoid:** 辛辣燥热、烟酒、干燥环境

## AQI Integration
空气质量差（AQI>150）时自动推送：润肺食谱 + 室内运动 + 口罩提醒

---

# Skill 52: shunshi-kidney-care
```yaml
---
name: shunshi-kidney-care
description: "补肾养生系统。冬季重点养生模块，提供补肾食疗、穴位保健、适宜运动、肾虚分型（肾阳虚/肾阴虚）调理方案。Use when: (1) providing kidney-care advice especially in winter, (2) distinguishing kidney-yang vs kidney-yin deficiency, (3) recommending warming/nourishing foods."
---
```
# Kidney Care System
## Kidney Deficiency Types
| Type | Symptoms | Foods | Tea | Acupoints |
|------|----------|-------|-----|-----------|
| 肾阳虚 | 畏寒怕冷、腰膝酸软 | 羊肉、核桃、韭菜 | 枸杞红茶 | 命门穴、关元穴 |
| 肾阴虚 | 手心热、盗汗、口干 | 黑芝麻、枸杞、鸭肉 | 枸杞菊花茶 | 太溪穴、照海穴 |

## Winter Kidney Protocol
- 冬至前后是最佳补肾时节
- 黑色食物补肾：黑豆、黑米、黑芝麻、黑木耳
- 每晚泡脚按揉涌泉穴
- 八段锦第六式"两手攀足固肾腰"

---

# Skill 53: shunshi-hair-care
```yaml
---
name: shunshi-hair-care
description: "养发护发系统。提供脱发预防、白发调理、头皮按摩手法、养发食疗方案，关联肝血肾精理论。Use when: (1) user reports hair loss concerns, (2) providing hair-nourishing food recommendations, (3) teaching scalp massage techniques."
---
```
# Hair Care Wellness
## TCM Hair Theory
发为血之余，发的健康与肝血、肾精密切相关。

## Hair Loss Prevention
- **Diet:** 黑芝麻、黑豆、核桃、桑葚、何首乌、枸杞
- **Recipes:** 首乌黑芝麻糊、黑豆排骨汤、枸杞核桃粥
- **Scalp Massage:** 每天5分钟，指腹从前额向后按摩，刺激百会穴
- **Lifestyle:** 23:00前入睡（养肝血）、减少压力、避免频繁染烫
- **Acupoints:** 百会穴、风池穴、肾俞穴

---

# Skill 54: shunshi-skin-care
```yaml
---
name: shunshi-skin-care
description: "中医美容养颜系统。提供由内而外的养颜方案——食疗美容、养颜茶饮、面部穴位按摩、体质对应的皮肤调理建议。Use when: (1) providing skin wellness from TCM perspective, (2) recommending beauty foods and teas, (3) teaching facial acupoint massage."
---
```
# Skin Care from TCM Perspective
## Constitution → Skin Type Mapping
| Constitution | Skin Type | Focus | Key Foods |
|-------------|-----------|-------|-----------|
| 阴虚 | 干燥缺水 | 滋阴润燥 | 银耳、百合、蜂蜜 |
| 湿热 | 油腻长痘 | 清热祛湿 | 绿豆、苦瓜、薏米 |
| 血瘀 | 暗沉无光 | 活血化瘀 | 红花、山楂、黑木耳 |
| 气虚 | 松弛下垂 | 补气固表 | 黄芪、山药、红枣 |
| 气郁 | 色斑 | 疏肝理气 | 玫瑰花、佛手、陈皮 |

## Facial Acupoint Massage (5 min)
1. 印堂穴 → 安神，减少额纹
2. 太阳穴 → 缓解眼疲劳
3. 四白穴 → 消除眼袋
4. 迎香穴 → 改善法令纹
5. 地仓穴 → 提升嘴角

---

# Skill 55: shunshi-weight-manage
```yaml
---
name: shunshi-weight-manage
description: "中医体质减重系统。根据不同体质类型提供差异化减重方案（痰湿型/气虚型/湿热型/气郁型），包含饮食计划、运动方案、茶饮配方。Use when: (1) user asks about weight management, (2) providing constitution-specific weight loss plans, (3) recommending weight-friendly recipes and teas."
---
```
# Constitution-Based Weight Management
## Type-Specific Plans
```python
WEIGHT_PLANS = {
    "tanshi": {
        "name": "痰湿型肥胖（最常见）",
        "pattern": "腹部肥胖、痰多、困倦",
        "diet": "薏米赤豆汤、冬瓜海带汤",
        "tea": "荷叶山楂茶",
        "exercise": "快走/游泳，每天45-60分钟",
        "acupoint": "丰隆穴、阴陵泉",
        "meal_order": "汤→蔬菜→蛋白质→主食"
    },
    "qixu": {
        "name": "气虚型肥胖",
        "pattern": "虚胖松软、容易累",
        "diet": "黄芪山药粥、鸡汤",
        "tea": "黄芪红枣茶",
        "exercise": "太极/散步，循序渐进",
        "acupoint": "足三里、气海穴"
    },
    "shire": {
        "name": "湿热型肥胖",
        "pattern": "面油、口臭、便秘",
        "diet": "苦瓜绿豆汤、凉拌蔬菜",
        "tea": "决明子菊花茶",
        "exercise": "跑步/HIIT，适当出汗"
    },
    "qiyu": {
        "name": "气郁型肥胖（情绪化进食）",
        "pattern": "压力大时暴食",
        "diet": "规律三餐，减少零食",
        "tea": "玫瑰薄荷茶",
        "exercise": "跳舞/跑步/团体运动",
        "emotion": "情绪管理比控制饮食更重要"
    }
}
```
## Important Disclaimer
"健康的体重管理需要科学方法。不建议节食或极端减肥。顺时提供的是生活方式调整建议，建议在专业指导下进行体重管理。"

---

# Skill 56: shunshi-allergy
```yaml
---
name: shunshi-allergy
description: "过敏体质养生系统。针对特禀体质用户提供过敏预防方案、花粉季养生、食物过敏管理、过敏体质增强免疫食疗。Use when: (1) managing allergy-prone constitution type, (2) providing seasonal allergy prevention tips, (3) filtering recipes for food allergies, (4) recommending immune-boosting strategies."
---
```
# Allergy Wellness System
## Seasonal Allergy Calendar
| Season | Allergen | Prevention |
|--------|----------|-----------|
| 春 | 花粉、柳絮 | 佩戴口罩、减少户外、按揉迎香穴 |
| 夏 | 霉菌、螨虫 | 除湿、勤换床品、通风 |
| 秋 | 秋季花粉、干燥 | 润燥、保湿、空气净化器 |
| 冬 | 室内过敏原 | 通风、防尘螨 |

## Immune Boosting for Sensitive Constitution
- **Food:** 黄芪、山药、大枣、蜂蜜
- **Classic formula:** 玉屏风散茶（黄芪、防风、白术）
- **Acupoint:** 足三里（增强免疫）、迎香穴（缓解鼻炎）
- **Exercise:** 太极、八段锦（室内练习）

## Food Allergy Filter
When user sets dietary restrictions/allergies:
```python
def filter_allergens(recipes, user_allergies):
    ALLERGEN_MAP = {
        "nuts": ["核桃","花生","杏仁","腰果","松子"],
        "seafood": ["虾","蟹","鱼","贝类"],
        "dairy": ["牛奶","奶酪","酸奶"],
        "gluten": ["小麦","面粉","面条","饺子皮"],
        "soy": ["豆腐","豆浆","黄豆"],
        "eggs": ["鸡蛋","蛋黄","蛋白"]
    }
    # Filter out recipes containing allergen ingredients
    ...
```

---

# Skill 57: shunshi-postpartum
```yaml
---
name: shunshi-postpartum
description: "产后恢复养生系统。按产后周期（第1周/第2-4周/第2-6月）提供月子食谱、催奶方案、产后运动、情绪关注。Use when: (1) providing postpartum recovery advice, (2) recommending lactation-boosting recipes, (3) managing postpartum exercise progression, (4) monitoring postpartum emotional health."
---
```
# Postpartum Recovery System
## Phase-Based Recovery
```python
POSTPARTUM_PHASES = {
    "week_1": {
        "diet": "流食/半流食为主，生化汤（遵医嘱），红糖水（不超过10天）",
        "avoid": "大补（易堵奶）、生冷、辛辣",
        "exercise": "床上翻身、简单走动",
        "reminder": "注意恶露观察"
    },
    "week_2_4": {
        "diet": "猪蹄黄豆汤、鲫鱼豆腐汤（催奶）、当归鸡汤（补血）",
        "exercise": "轻度散步、凯格尔运动",
        "emotion": "关注产后情绪变化"
    },
    "month_2_6": {
        "diet": "均衡营养、适量补钙",
        "exercise": "产后瑜伽、盆底肌恢复、腹直肌修复",
        "milestone": "产后42天检查"
    }
}
```
## Postpartum Depression Warning Signs
持续低落>2周、对婴儿缺乏兴趣、失眠/嗜睡、食欲剧变 → 建议及时就医

---

# Skill 58: shunshi-teen-wellness
```yaml
---
name: shunshi-teen-wellness
description: "青少年养生系统。针对13-18岁用户提供长高营养方案、青春痘调理、考试压力管理、经期指导（女生）。Use when: (1) providing teen-specific wellness advice, (2) growth nutrition plans, (3) exam stress management, (4) acne management from TCM perspective."
---
```
# Teen Wellness System
## Growth Nutrition (长高方案)
- 钙：每天1000-1300mg（牛奶、豆腐、芝麻）
- 蛋白：鸡蛋、瘦肉、鱼（每天60-75g）
- 锌：牡蛎、牛肉、南瓜子
- 维D：每天晒太阳15-20分钟
- 运动：跳绳（最有助长高）、篮球、游泳
- 睡眠：22:00前入睡（生长激素在深睡时分泌最多）

## Acne Management
- **Diet:** 苦瓜、绿豆、薏米、黄瓜、西红柿
- **Avoid:** 油炸、甜食、辛辣、奶茶
- **Tea:** 菊花金银花茶
- **Skincare:** 温水洁面、不挤痘、枕巾勤换

## Exam Stress Toolkit
1. 腹式呼吸3分钟
2. 蝴蝶拍（双手交叉抱肩，左右交替轻拍）
3. 番茄工作法（25+5）
4. 按揉百会穴、太阳穴提神
5. 核桃+蓝莓健脑零食

---

# Skill 59: shunshi-couple-wellness
```yaml
---
name: shunshi-couple-wellness
description: "伴侣养生系统。提供双人养生方案——共同泡脚、互按穴位、情侣养生食谱、体质互补建议。Use when: (1) providing couple wellness activities, (2) matching partner constitutions for complementary care, (3) creating romantic wellness date ideas."
---
```
# Couple Wellness System
## Partner Constitution Matching
根据双方体质提供互补养生建议。例如：一方阳虚+一方阴虚 → 互相调和。

## Couple Activities
- 共同泡脚（加不同药材）
- 互相按摩穴位（教学视频）
- 一起做八段锦
- 共同烹饪养生食谱
- 双人冥想/呼吸练习

---

# Skill 60: shunshi-pet-wellness
```yaml
---
name: shunshi-pet-wellness
description: "宠物养生联动。在养生建议中适当融入宠物元素——和宠物一起散步、宠物对情绪的正面影响、四季宠物护理提示。Use when: (1) user mentions pets, (2) incorporating pet activities into wellness routines, (3) providing seasonal pet care tips for pet owners."
---
```
# Pet Wellness Integration
## Wellness Activities with Pets
- 和狗狗一起散步（最佳运动伴侣）
- 撸猫减压（降低皮质醇）
- 带宠物晒太阳（人宠同补维D）

## Seasonal Pet Care Tips
| Season | Tips |
|--------|------|
| 春 | 宠物换毛季，勤梳毛 |
| 夏 | 防中暑，遛狗避开正午 |
| 秋 | 宠物皮肤干燥，适当保湿 |
| 冬 | 宠物保暖，小型犬穿衣服 |

---

# Skill 61: shunshi-community
```yaml
---
name: shunshi-community
description: "养生社区系统。用户发帖分享养生经验、食谱作品、打卡记录，支持点赞/评论/分享，包含内容审核和社区规则。Use when: (1) building the user community/feed feature, (2) implementing post CRUD with images, (3) managing likes/comments/shares, (4) implementing content moderation."
---
```
# Community System
## Post Types
| Type | Content | Examples |
|------|---------|---------|
| 经验分享 | 文字+图片 | "坚持泡脚一个月的变化" |
| 食谱作品 | 照片+做法 | "自制百合莲子羹" |
| 打卡展示 | 打卡卡片 | "连续21天打卡" |
| 养生问答 | 提问+回答 | "气虚体质该怎么运动？" |

## Post Model
```python
class CommunityPost:
    id: UUID
    user_id: UUID
    post_type: str       # experience, recipe_share, checkin, question
    content: str         # max 1000 chars
    images: list         # max 9 images
    tags: list
    like_count: int
    comment_count: int
    is_featured: bool    # 精选
    status: str          # pending, approved, rejected, deleted
    created_at: datetime
```

## Moderation Rules
- 新帖先过AI审核（敏感词/广告/医疗声明检测）
- AI自动标记可疑帖子
- 用户举报机制（3次举报自动下架待审）
- 禁止：医疗广告、减肥药推广、虚假养生信息

---

# Skill 62: shunshi-challenge
```yaml
---
name: shunshi-challenge
description: "21天养生挑战系统。创建限时养生挑战活动（21天早睡/祛湿/减压/节气养生），包含每日任务、打卡、排行榜、奖励。Use when: (1) creating challenge campaigns, (2) managing daily challenge tasks, (3) tracking participant progress, (4) generating challenge completion rewards."
---
```
# 21-Day Challenge System
## Challenge Structure
```python
class Challenge:
    id: UUID
    title: str             # "21天早睡挑战"
    description: str
    duration_days: int     # 21
    daily_tasks: list      # [{day: 1, task: "今晚23:00前入睡", verification: "sleep_time"}]
    reward_complete: dict  # {points: 200, badge: "早睡达人", premium_days: 7}
    reward_partial: dict   # 完成14天以上
    start_date: date
    end_date: date
    max_participants: int
    current_participants: int
    status: str            # upcoming, active, completed

class ChallengeParticipant:
    user_id: UUID
    challenge_id: UUID
    daily_completions: dict  # {1: true, 2: true, 3: false, ...}
    completion_rate: float
    rank: int
```

## Pre-Built Challenge Templates
1. "21天早睡挑战" — 每晚23:00前入睡
2. "21天祛湿挑战" — 每天喝祛湿茶+运动
3. "21天八段锦挑战" — 每天练一遍
4. "21天情绪管理挑战" — 每天冥想+感恩日记
5. "节气养生14天挑战" — 每个节气启动

---

# Skill 63: shunshi-expert-qa
```yaml
---
name: shunshi-expert-qa
description: "专家问答系统。定期邀请中医养生专家在线答疑，用户提问，专家回答，问答内容沉淀为知识库。Use when: (1) building expert Q&A sessions, (2) managing question submission and expert matching, (3) archiving Q&A content into knowledge base."
---
```
# Expert Q&A System
## Flow
```
1. 运营创建专家答疑场次（主题/专家/时间）
2. 用户提前提交问题
3. 运营筛选高质量问题
4. 专家在线回答（文字/语音）
5. 问答内容整理后进入知识库和文章库
```

## Expert Profile
```python
class Expert:
    id: UUID
    name: str
    title: str           # "主任中医师"
    hospital: str        # "北京中医药大学附属医院"
    specialties: list    # ["体质调理", "失眠", "脾胃"]
    avatar_url: str
    bio: str
```

---

# Skill 64: shunshi-live-class
```yaml
---
name: shunshi-live-class
description: "直播课堂系统。支持养生知识直播课（八段锦带练/节气养生课/专家讲座），包含直播预约、回放、互动。Use when: (1) scheduling live wellness classes, (2) implementing live streaming integration, (3) managing class replays, (4) building class reservation system."
---
```
# Live Class System
## Class Types
| Type | Frequency | Duration | Content |
|------|-----------|----------|---------|
| 八段锦晨练 | 每日7:00 | 30min | 跟练 |
| 节气养生课 | 每节气1次 | 60min | 知识+互动 |
| 专家讲座 | 每月1次 | 90min | 深度主题 |
| 冥想引导 | 每周2次 | 20min | 跟练 |

## Implementation
```
技术方案：
- 直播SDK：阿里云直播（推流+拉流）
- 实时互动：WebSocket（弹幕/问答）
- 回放：直播结束自动生成回放视频
- 预约：Celery定时任务发送开课提醒

Premium gating:
- 八段锦晨练：免费
- 节气养生课：免费
- 专家讲座：会员专享
- 回放：会员专享
```

---

# Skill 65: shunshi-meditation
```yaml
---
name: shunshi-meditation
description: "冥想引导系统。提供多种冥想练习（呼吸觉察/身体扫描/慈悲冥想/感恩冥想/正念行走），支持定时器、背景音乐、引导语音。Use when: (1) building guided meditation experiences, (2) implementing meditation timer with ambient sounds, (3) providing meditation selection based on mood/time."
---
```
# Meditation System
## Meditation Library
```json
[
  {"name": "呼吸觉察", "duration": [5,10,15], "level": "beginner", "best_for": ["calm","focus"]},
  {"name": "身体扫描", "duration": [10,15,20], "level": "beginner", "best_for": ["sleep","relax"]},
  {"name": "慈悲冥想", "duration": [10,15], "level": "intermediate", "best_for": ["compassion","peace"]},
  {"name": "感恩冥想", "duration": [10], "level": "beginner", "best_for": ["gratitude","positivity"]},
  {"name": "正念行走", "duration": [10,20], "level": "beginner", "best_for": ["energy","calm"]},
  {"name": "数息冥想", "duration": [5,10], "level": "beginner", "best_for": ["anger","anxiety"]},
  {"name": "观想冥想", "duration": [15,20], "level": "intermediate", "best_for": ["creativity","peace"]}
]
```

## Meditation Timer UI
- 选择冥想类型 + 时长
- 选择背景音（静音/自然声/轻音乐）
- 开始：倒计时 + 引导语音
- 中间：间歇提醒铃声（可选）
- 结束：温柔铃声 + 简短反思
- 记录：冥想时长计入日记

---

# Skill 66: shunshi-gratitude
```yaml
---
name: shunshi-gratitude
description: "感恩日记系统。每日引导用户记录3件感恩的事，追踪感恩习惯，生成感恩趋势和积极情绪分析。Use when: (1) implementing gratitude journaling prompts, (2) tracking gratitude streak, (3) analyzing positive emotion patterns."
---
```
# Gratitude Journal System
## Daily Prompt
每晚20:00-21:00推送：
"今天有什么值得感恩的事？哪怕很小也值得记录 🌿"

## Entry Structure
```json
{
  "date": "2026-03-21",
  "entries": [
    "今天的阳光很好",
    "同事帮我解决了一个问题",
    "晚餐的汤很好喝"
  ],
  "mood_after": 8
}
```

## Analytics
- 感恩连续天数
- 最常感恩的主题词云
- 感恩记录前后情绪变化对比

---

# Skill 67: shunshi-habit-builder
```yaml
---
name: shunshi-habit-builder
description: "养生习惯养成系统。帮助用户建立和坚持养生习惯，使用21天习惯养成法则，提供进度追踪、习惯提醒、激励机制。Use when: (1) creating custom habit tracking, (2) implementing the 21-day habit formation framework, (3) sending habit reminders, (4) visualizing habit progress."
---
```
# Habit Builder System
## Pre-Built Habits
```python
SUGGESTED_HABITS = [
    {"name": "晨起一杯温水", "icon": "💧", "time": "wake", "difficulty": "easy"},
    {"name": "每天早睡(23:00前)", "icon": "🌙", "time": "22:30", "difficulty": "medium"},
    {"name": "每天泡脚20分钟", "icon": "🦶", "time": "21:00", "difficulty": "easy"},
    {"name": "每天八段锦", "icon": "🧘", "time": "07:00", "difficulty": "medium"},
    {"name": "每天冥想10分钟", "icon": "🧘‍♀️", "time": "flexible", "difficulty": "easy"},
    {"name": "每天喝养生茶", "icon": "🍵", "time": "09:00", "difficulty": "easy"},
    {"name": "每天记养生日记", "icon": "📝", "time": "21:00", "difficulty": "easy"},
    {"name": "每天按穴位5分钟", "icon": "👆", "time": "flexible", "difficulty": "easy"},
    {"name": "三餐规律", "icon": "🥗", "time": "fixed", "difficulty": "medium"},
    {"name": "每天运动30分钟", "icon": "🏃", "time": "flexible", "difficulty": "medium"},
]
```
## 21-Day Framework
Week 1 (Day 1-7): 刻意期 — 需要强提醒，完成就奖励
Week 2 (Day 8-14): 适应期 — 减少提醒强度，习惯渐成
Week 3 (Day 15-21): 稳定期 — 轻提醒，即将达成！
Day 22+: 习惯已成 — 庆祝勋章 🎉

---

# Skill 68: shunshi-calorie-tracker
```yaml
---
name: shunshi-calorie-tracker
description: "简易热量追踪。基于中式饮食的热量估算，帮助用户了解每日摄入，但不鼓励过度计算——侧重于营养均衡而非卡路里控制。Use when: (1) estimating meal calories from Chinese food descriptions, (2) providing nutritional balance feedback, (3) gentle calorie awareness without obsession."
---
```
# Gentle Calorie Awareness
## Chinese Food Calorie Reference
```json
{
  "白米饭(1碗)": {"cal": 230, "serving": "150g"},
  "馒头(1个)": {"cal": 220, "serving": "100g"},
  "红烧肉(1份)": {"cal": 380, "serving": "150g"},
  "清炒时蔬(1份)": {"cal": 80, "serving": "200g"},
  "小米粥(1碗)": {"cal": 120, "serving": "250ml"},
  "鸡蛋(1个)": {"cal": 70, "serving": "50g"}
}
```

## Philosophy
不鼓励严格卡路里计算。用"感受饱腹度"替代"计算卡路里"：
- 七分饱 = 吃到不饿了但还能再吃 = 最佳
- 配合体质建议调整饮食结构

---

# Skill 69: shunshi-tcm-culture
```yaml
---
name: shunshi-tcm-culture
description: "中医文化知识系统。提供中医经典语录、养生典故、药食同源文化、节气文化故事，增加产品文化底蕴和内容厚度。Use when: (1) displaying daily wisdom quotes, (2) enriching content with cultural stories, (3) building the TCM culture encyclopedia."
---
```
# TCM Culture Knowledge
## Classic Quotes (50+)
```json
[
  {"text": "上医治未病", "source": "《黄帝内经》", "meaning": "最好的医生是预防疾病"},
  {"text": "春夏养阳，秋冬养阴", "source": "《黄帝内经》", "meaning": "顺应四季调养阴阳"},
  {"text": "饮食有节，起居有常", "source": "《黄帝内经》", "meaning": "规律的饮食起居是健康基础"},
  {"text": "药补不如食补，食补不如气补", "source": "民间谚语", "meaning": "养生之道，调气为上"},
  {"text": "冬吃萝卜夏吃姜", "source": "民间谚语", "meaning": "饮食顺应季节变化"}
]
```

## Daily Wisdom Feature
每日首页展示一条经典养生名言，配以解读和当日关联性。

---

# Skill 70: shunshi-voice
```yaml
---
name: shunshi-voice
description: "语音交互系统。支持语音输入养生问题、语音播报养生内容、语音引导冥想和呼吸练习。Use when: (1) implementing voice input for AI chat, (2) text-to-speech for article/recipe reading, (3) voice-guided breathing and meditation, (4) accessibility voice features for elderly users."
---
```
# Voice Interaction System
## Features
1. **语音输入:** 用户语音提问 → 语音识别(ASR) → 文字 → AI回复
2. **语音播报:** 文章/食谱/节气内容 → TTS → 音频播放
3. **语音引导:** 冥想/呼吸练习的语音引导（预录音频）
4. **无障碍:** 老年人模式下，所有重要内容支持语音播报

## Tech
- ASR: 科大讯飞语音识别 or 阿里云语音
- TTS: 科大讯飞语音合成 or 阿里云语音合成
- Voice: 选择温和、自然的女声（符合品牌调性）

---

# Skill 71: shunshi-accessibility
```yaml
---
name: shunshi-accessibility
description: "无障碍适配系统。确保App对视障/听障/老年用户友好——大字体模式、高对比度、屏幕阅读器兼容、简化模式。Use when: (1) implementing accessibility features, (2) building large-font mode, (3) ensuring screen reader compatibility, (4) creating simplified UI for elderly."
---
```
# Accessibility System
## Features
| Feature | Implementation |
|---------|---------------|
| 大字体模式 | 正文16→20pt, 标题20→26pt |
| 高对比度 | 深色背景+白色文字 or 放大对比 |
| 屏幕阅读器 | 所有UI元素添加accessibilityLabel |
| 简化模式 | 减少层级，只保留核心功能 |
| 语音播报 | 重要内容可听 |
| 大按钮 | 触摸目标最小48dp |

## React Native Implementation
```jsx
<TouchableOpacity
  accessible={true}
  accessibilityLabel="查看今日养生建议"
  accessibilityRole="button"
  style={{minHeight: 48, minWidth: 48}}
>
  <Text style={{fontSize: isLargeFont ? 20 : 16}}>今日养生</Text>
</TouchableOpacity>
```

---

# Skill 72-100: 快速定义（简明版）

以下Skills每个都有完整的YAML frontmatter和核心实现要点：

---

# Skill 72: shunshi-feedback
```yaml
---
name: shunshi-feedback
description: "用户反馈收集系统。应用内反馈表单、评分引导、Bug报告、功能建议，反馈自动分类和处理。Use when: building in-app feedback forms, rating prompts, bug reporting, feature request collection."
---
```
## Features: In-app feedback form (text + screenshot), smart rating prompt (after 3+ sessions, good experience), bug report with device info auto-attach, feedback categorization (bug/suggestion/complaint/praise), admin dashboard for feedback management.

---

# Skill 73: shunshi-i18n
```yaml
---
name: shunshi-i18n
description: "国际化基础架构。虽然顺时面向中国市场，但预留多语言支持（繁体中文/英文），为未来SEASONS共用组件做准备。Use when: setting up i18n infrastructure, managing translation files, handling locale-specific content."
---
```
## Structure: i18next setup, locale files (zh-CN, zh-TW, en), dynamic content locale field in database, date/time formatting by locale.

---

# Skill 74: shunshi-ab-test
```yaml
---
name: shunshi-ab-test
description: "A/B测试框架。支持对引导流程、付费弹窗、推荐算法、UI布局等进行A/B测试，追踪各组转化率。Use when: implementing A/B test infrastructure, creating test variants, tracking conversion by group."
---
```
## Implementation: User hash → test group assignment, feature flag system in Redis, event tracking by test group, statistical significance calculation, test management API for admin.

---

# Skill 75: shunshi-error-handling
```yaml
---
name: shunshi-error-handling
description: "全局错误处理系统。统一API错误格式、前端错误边界、网络重试策略、错误上报和告警。Use when: implementing global error handling, error reporting, retry strategies, user-friendly error messages."
---
```
## Error Response Format:
```json
{"code": "AUTH_TOKEN_EXPIRED", "message": "登录已过期，请重新登录", "status": 401, "detail": null}
```
## Chinese Error Messages: All error messages in warm, friendly Chinese. Never show technical errors to users.

---

# Skill 76: shunshi-migration
```yaml
---
name: shunshi-migration
description: "数据迁移与版本管理。使用Alembic管理数据库Schema变更，支持安全回滚，包含数据迁移脚本最佳实践。Use when: creating database migrations, handling schema changes, data migration scripts."
---
```
## Best Practices: One migration per feature, always add NOT NULL with defaults, test rollback before deploy, separate data migration from schema migration.

---

# Skill 77: shunshi-monitoring
```yaml
---
name: shunshi-monitoring
description: "系统监控告警。配置Prometheus指标收集、Grafana看板、关键业务告警（API延迟/错误率/支付异常/AI服务状态）。Use when: setting up monitoring infrastructure, defining alert rules, building dashboards."
---
```
## Key Metrics: API latency p50/p95/p99, error rate by endpoint, AI response time, payment success rate, DAU/MAU real-time, Celery queue depth. Alert channels: 钉钉/飞书 webhook.

---

# Skill 78: shunshi-backup
```yaml
---
name: shunshi-backup
description: "数据备份策略。PostgreSQL自动备份、Redis持久化、用户数据导出、灾难恢复计划。Use when: implementing automated backups, disaster recovery planning, data export features."
---
```
## Strategy: PostgreSQL: pg_dump daily at 03:00 → 阿里云OSS, retain 30 days. Redis: AOF + RDB. Cross-region replication for DR. RTO: 4 hours, RPO: 24 hours.

---

# Skill 79: shunshi-security
```yaml
---
name: shunshi-security
description: "安全防护系统。防SQL注入、XSS、CSRF，API签名验证，敏感数据加密，安全审计日志。Use when: implementing security measures, encryption, audit logging, vulnerability prevention."
---
```
## Measures: ORM parameterized queries (SQL injection), Input sanitization (XSS), CSRF token for web, Phone numbers encrypted at rest (AES-256), Audit log for sensitive operations, Rate limiting on all endpoints, JWT rotation.

---

# Skill 80: shunshi-performance
```yaml
---
name: shunshi-performance
description: "性能优化系统。API响应优化、数据库查询优化、图片加载优化、App启动速度优化。Use when: optimizing API performance, database queries, image loading, app startup time."
---
```
## Targets: API p95 < 200ms, App cold start < 2s, Image load < 1s (WebP + CDN + progressive), DB query < 50ms. Techniques: Redis cache, DB indexing, pagination, lazy loading, image thumbnails.

---

# Skill 81: shunshi-testing
```yaml
---
name: shunshi-testing
description: "测试体系。API单元测试/集成测试、前端组件测试、E2E测试、AI回复质量测试框架。Use when: writing tests, setting up CI test pipeline, testing AI response quality."
---
```
## Stack: Backend: pytest + httpx (API tests), Frontend: Jest + React Native Testing Library, E2E: Detox, AI Quality: Custom eval framework (relevance, safety, tone scoring).

---

# Skill 82: shunshi-seo
```yaml
---
name: shunshi-seo
description: "SEO优化系统。针对顺时官网和内容页的搜索引擎优化——Meta标签、结构化数据、Sitemap、Open Graph。Use when: optimizing web content for search engines, implementing structured data, managing sitemaps."
---
```
## Implementation: Dynamic meta tags for each content page, JSON-LD structured data (Recipe, Article, FAQ), Auto-generated sitemap.xml, Open Graph tags for social sharing, Canonical URLs.

---

# Skill 83: shunshi-cdp
```yaml
---
name: shunshi-cdp
description: "用户数据平台。整合用户行为数据、属性数据、交易数据，构建360度用户画像，支持精准运营。Use when: building user profiles from multi-source data, creating user segments, enabling targeted operations."
---
```
## User Profile: demographics + constitution + behavior + purchase + engagement score. Segments: active_health_seekers, lapsed_users, high_value, at_risk_churn.

---

# Skill 84: shunshi-push-strategy
```yaml
---
name: shunshi-push-strategy
description: "智能推送策略引擎。根据用户行为、偏好、活跃时段优化推送时机和内容，提升打开率，降低卸载率。Use when: optimizing push notification timing, personalizing notification content, managing notification fatigue."
---
```
## Rules: Max 3 pushes/day, respect quiet hours (22:00-07:00), personalize by constitution and behavior, A/B test notification copy, track open rate and unsubscribe rate.

---

# Skill 85: shunshi-gifting
```yaml
---
name: shunshi-gifting
description: "养生礼品卡系统。用户可购买数字礼品卡赠送亲友会员资格，适合母亲节/父亲节/重阳节等场景。Use when: implementing gift card purchase and redemption, creating seasonal gift campaigns."
---
```
## Flow: Purchase gift card (¥199/¥299) → Generate gift code → Share via WeChat → Recipient redeem → Activate membership.

---

# Skill 86: shunshi-seasonal-campaign
```yaml
---
name: shunshi-seasonal-campaign
description: "节气营销活动引擎。为每个节气自动生成/管理营销活动——限时优惠、打卡挑战、内容专题、社交传播。Use when: creating solar-term-based marketing campaigns, automating campaign lifecycle."
---
```
## Auto-Campaign per Solar Term: 预热(3天前) → 当日(限时优惠+内容推送+直播) → 持续(7天打卡挑战) → 复盘.

---

# Skill 87: shunshi-content-schedule
```yaml
---
name: shunshi-content-schedule
description: "内容排期系统。管理全平台内容发布计划——App推送、公众号、小红书、抖音等内容的排期、审核、发布。Use when: scheduling content across platforms, managing editorial calendar, coordinating multi-platform publishing."
---
```
## Calendar: Spreadsheet-style editorial calendar, auto-reminder for content due dates, approval workflow (draft→review→approved→scheduled→published).

---

# Skill 88: shunshi-data-export
```yaml
---
name: shunshi-data-export
description: "用户数据导出。支持用户导出个人养生数据（日记、报告、体质结果）为PDF/JSON，符合隐私法规要求。Use when: implementing user data export (PIPL compliance), generating PDF reports for users."
---
```
## Export formats: PDF (养生报告), JSON (完整数据), CSV (日记数据). Processing: Async generation via Celery, email download link when ready.

---

# Skill 89: shunshi-version-update
```yaml
---
name: shunshi-version-update
description: "App版本更新管理。强制更新/推荐更新逻辑、更新日志展示、灰度发布支持。Use when: implementing app update checking, forced update for critical fixes, gradual rollout."
---
```
## API: GET /api/v1/app/version → {latest_version, min_version, update_url, changelog, force_update: bool}

---

# Skill 90: shunshi-debug
```yaml
---
name: shunshi-debug
description: "开发调试工具。内置开发者调试面板——查看网络请求、缓存状态、用户状态、强制刷新、切换环境。Use when: building developer debug tools, network inspector, cache viewer."
---
```
## Debug Panel (dev builds only): Network log, Redis cache viewer, current user state, force solar term change, reset onboarding, switch API environment.

---

# Skill 91: shunshi-ci-cd
```yaml
---
name: shunshi-ci-cd
description: "CI/CD流水线。GitHub Actions配置——代码检查、测试、构建、部署自动化。Use when: setting up CI/CD pipelines, automating build and deployment."
---
```
## Pipeline: Push → Lint → Test → Build → Deploy(staging) → Manual approve → Deploy(production). Mobile: Fastlane for iOS/Android builds.

---

# Skill 92: shunshi-logging
```yaml
---
name: shunshi-logging
description: "日志系统。结构化日志、请求追踪、错误日志、审计日志，集中收集和查询。Use when: implementing structured logging, request tracing, log aggregation."
---
```
## Format: JSON structured logs with request_id, user_id, endpoint, duration, status. Stack: Python logging → Filebeat → Elasticsearch → Kibana.

---

# Skill 93: shunshi-feature-flag
```yaml
---
name: shunshi-feature-flag
description: "功能开关系统。支持灰度发布、用户分群开放新功能、紧急关闭问题功能。Use when: implementing feature flags, gradual feature rollout, emergency feature kill switch."
---
```
## Implementation: Redis-based feature flags. API: GET /api/v1/features → {features: {new_chat_ui: true, meditation_v2: false}}. Admin can toggle per user group.

---

# Skill 94: shunshi-compliance
```yaml
---
name: shunshi-compliance
description: "合规系统。确保App符合中国《个人信息保护法》、App Store审核规范、内容合规（不涉医疗声明）。Use when: implementing privacy compliance, content compliance checking, regulatory requirements."
---
```
## Requirements: Privacy policy + user agreement acceptance, data collection consent, account deletion within 15 days, content disclaimer on all health advice, no medical claims in any content, minors protection.

---

# Skill 95: shunshi-localization-cn
```yaml
---
name: shunshi-localization-cn
description: "中国本地化适配。适配中国日历（农历/节气）、中国节假日、中国手机号格式、中国城市列表、简繁体切换。Use when: implementing China-specific localizations, lunar calendar, Chinese holidays integration."
---
```
## Includes: Lunar calendar display, Chinese holidays (春节/端午/中秋), city picker (省→市→区), phone validation (1[3-9]\\d{9}), simplified/traditional Chinese toggle.

---

# Skill 96: shunshi-ai-wellness-plan
```yaml
---
name: shunshi-ai-wellness-plan
description: "AI个人养生方案生成器。基于体质测试结果+节气+用户健康目标，AI生成完整的个性化30天养生计划。Use when: generating comprehensive personalized wellness plans, creating 30-day programs, adapting plans to user progress."
---
```
## Plan Structure: 30-day plan with daily: diet plan, exercise, tea, acupoint, sleep target, emotional practice. Weekly review and AI adjustment based on journal data.

---

# Skill 97: shunshi-ai-ingredient-scan
```yaml
---
name: shunshi-ai-ingredient-scan
description: "AI食材识别。用户拍照食材，AI识别并推荐适合体质的食谱和搭配建议。Use when: implementing camera-based ingredient recognition, generating recipes from available ingredients."
---
```
## Flow: User takes photo → AI vision identifies ingredients → Cross-reference with constitution → Suggest recipes. Use multimodal AI (GPT-4V or Qwen-VL).

---

# Skill 98: shunshi-wearable
```yaml
---
name: shunshi-wearable
description: "可穿戴设备数据联动。对接Apple Health / 华为健康 / 小米运动等平台，同步心率/步数/睡眠数据，增强养生建议精准度。Use when: integrating with health platforms (Apple HealthKit, Huawei Health), syncing wearable data, enhancing recommendations with real biometric data."
---
```
## Sync: Apple HealthKit (sleep, steps, heart_rate), Huawei Health Kit, Xiaomi Health. Use synced data to enhance: sleep analysis accuracy, exercise tracking, personalized recommendations.

---

# Skill 99: shunshi-widget
```yaml
---
name: shunshi-widget
description: "手机桌面小组件。iOS Widget / Android Widget显示当前节气、今日养生建议、打卡状态、饮水进度。Use when: building iOS WidgetKit / Android App Widget, displaying at-a-glance wellness info."
---
```
## Widget Types:
- **小** (2x2): 当前节气 + 一句养生提示
- **中** (4x2): 节气 + 今日3条建议 + 打卡状态
- **大** (4x4): 节气 + 建议 + 打卡 + 饮水进度 + 下一节气倒计时

---

# Skill 100: shunshi-ai-dream
```yaml
---
name: shunshi-ai-dream
description: "AI梦境解读（趣味功能）。用户描述梦境，AI从中医角度（梦与脏腑关系）给出趣味性解读和养生建议。不做心理分析，仅为趣味互动。Use when: user describes a dream in chat, providing fun TCM-based dream interpretation as a lighthearted engagement feature."
---
```
# AI Dream Interpretation (Fun Feature)
## TCM Dream-Organ Theory
中医认为梦与脏腑状态有关：
```python
DREAM_ORGAN_MAP = {
    "梦见火/烧": {"organ": "心", "advice": "心火偏旺，可喝莲子心茶清心"},
    "梦见飞/高处": {"organ": "肺", "advice": "肺气偏虚，可做深呼吸练习"},
    "梦见水/溺水": {"organ": "肾", "advice": "肾气不足，可多吃黑色食物"},
    "梦见吃东西": {"organ": "脾", "advice": "脾胃需要关注，可喝山药粥"},
    "梦见打架/生气": {"organ": "肝", "advice": "肝气不畅，可按太冲穴、喝玫瑰花茶"},
}
```

## Important Disclaimer
"这只是基于传统文化的趣味解读，不具有任何医学或心理学诊断意义。如果睡眠质量持续不好，建议咨询专业医生。"
