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
