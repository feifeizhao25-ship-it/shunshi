# SEASONS — API Reference

> Backend API reference for the SEASONS Global app.
> Base URL: `http://116.62.32.43/api/v1/`
> All requests: `Content-Type: application/json`
> Authenticated requests: `Authorization: Bearer <token>`

---

## Table of Contents

1. [Health](#health)
2. [Authentication](#authentication)
3. [User](#user)
4. [Chat / AI Companion](#chat--ai-companion)
5. [Daily Insight](#daily-insight)
6. [Reflection / Journal](#reflection--journal)
7. [Content Library](#content-library)
8. [Seasons / Seasonal Wellness](#seasons--seasonal-wellness)
9. [Home Dashboard](#home-dashboard)
10. [Onboarding](#onboarding)
11. [Models](#models)

---

## Health

### `GET /health`

Health check endpoint.

**Response**

```json
{
  "status": "ok",
  "version": "1.0.0"
}
```

---

## Authentication

> Auth tokens are obtained via OAuth (Google Sign-In, Sign in with Apple) on the client side.
> The token is stored in `flutter_secure_storage` and injected into all subsequent requests via `ApiService.updateAuthToken(token)`.

### OAuth Flow

```
1. User taps "Continue with Google" / "Continue with Apple"
2. flutter_riverpod oauth package completes OAuth handshake
3. Server validates token, returns session JWT
4. Client stores JWT in flutter_secure_storage
5. Client calls ApiService.updateAuthToken(jwt)
```

---

## User

### `GET /user/:userId`

Get user profile.

**Path Parameters**

| Name | Type | Description |
|---|---|---|
| `userId` | string | User ID |

**Response**

```json
{
  "id": "usr_abc123",
  "email": "user@example.com",
  "name": "Jane",
  "avatar_url": "https://example.com/avatar.jpg",
  "country": "US",
  "subscription": "premium",
  "created_at": "2025-01-15T10:30:00Z"
}
```

**Flutter Model:** `UserResponse` in `api_service.dart`

---

### `PUT /user/:userId`

Update user profile.

**Path Parameters**

| Name | Type | Description |
|---|---|---|
| `userId` | string | User ID |

**Request Body**

```json
{
  "name": "Jane Doe",
  "avatar_url": "https://example.com/new-avatar.jpg",
  "preferences": {
    "theme": "dark",
    "notifications_enabled": true
  }
}
```

All fields are optional. Send only the fields you want to update.

---

## Chat / AI Companion

### `POST /ai/chat`

Send a message to the AI companion and receive a response.

**Request Body**

```json
{
  "prompt": "I'm feeling tired today, what can I do?",
  "conversation_id": "conv_xyz789",
  "user_id": "usr_abc123",
  "model": "seasons-large"
}
```

| Field | Type | Required | Description |
|---|---|---|---|
| `prompt` | string | ✅ | User's message text |
| `conversation_id` | string | No | Continues an existing conversation thread |
| `user_id` | string | No | User identifier for context |
| `model` | string | No | AI model to use. Defaults to `seasons-small` |

**Response**

```json
{
  "text": "I hear you — feeling tired can be your body asking for rest...",
  "tone": "calm",
  "suggestions": [
    "Try a 5-minute breathing exercise",
    "What did you sleep like last night?",
    "Would you like a gentle stretch routine?"
  ],
  "follow_up": {
    "in_days": 2,
    "intent": "check_in_tiredness"
  },
  "safety_flag": "none",
  "model": "seasons-large",
  "tokens_used": 342,
  "latency_ms": 1240
}
```

**Flutter Model:** `ChatResponse` in `api_service.dart`

---

### `POST /ai/chat/stream`

Streaming variant of the chat endpoint. Returns a Server-Sent Events (SSE) stream.

**Request Body** — same as `/ai/chat`

**Response** — `Content-Type: text/event-stream`

Each chunk is a raw JSON fragment:

```
data: {"text": "I "}
data: {"text": "hear "}
data: {"text": "you..."}
data: [DONE]
```

**Flutter Usage:**

```dart
Stream<String> streamChat(String prompt, {String? conversationId}) async* {
  final response = await _dio.post<ResponseBody>(
    '/ai/chat/stream',
    data: {'prompt': prompt, if (conversationId != null) 'conversation_id': conversationId},
    options: Options(responseType: ResponseType.stream),
  );
  final stream = response.data?.stream;
  if (stream != null) {
    await for (final chunk in stream) {
      yield String.fromCharCodes(chunk);
    }
  }
}
```

---

## Daily Insight

### `POST /ai/daily-insight`

Get the AI-generated daily insight card for the home screen.

**Query Parameters**

| Name | Type | Description |
|---|---|---|
| `user_id` | string | User ID |
| `season` | string | Current season (`spring`, `summer`, `autumn`, `winter`) |

**Response**

```json
{
  "text": "Today is a day for gentle beginnings. The early spring light invites you to stretch slowly and breathe deeply.",
  "season": "spring",
  "generated_at": "2025-03-20T08:00:00Z"
}
```

**Flutter Model:** `DailyInsightResponse` in `api_service.dart`

---

## Reflection / Journal

### `POST /reflection/submit`

Submit a daily reflection entry.

**Request Body**

```json
{
  "user_id": "usr_abc123",
  "mood": "calm",
  "energy": "medium",
  "sleep": "good",
  "notes": "Felt good after the morning walk."
}
```

| Field | Type | Required | Description |
|---|---|---|---|
| `mood` | string | ✅ | One of: `great`, `good`, `okay`, `low`, `struggling` |
| `energy` | string | ✅ | One of: `high`, `medium`, `low`, `exhausted` |
| `sleep` | string | ✅ | One of: `great`, `good`, `okay`, `poor`, `insomnia` |
| `notes` | string | No | Free-text journal note |

**Response:** `204 No Content` on success

---

### `GET /reflection/list`

Get list of reflection entries for a user.

**Query Parameters**

| Name | Type | Description |
|---|---|---|
| `user_id` | string | User ID |

**Response**

```json
[
  {
    "id": "ref_001",
    "date": "2025-03-20T00:00:00Z",
    "mood": "calm",
    "energy": "medium",
    "sleep": "good",
    "notes": "Felt good after the morning walk."
  },
  {
    "id": "ref_002",
    "date": "2025-03-19T00:00:00Z",
    "mood": "good",
    "energy": "high",
    "sleep": "great",
    "notes": null
  }
]
```

**Flutter Model:** `List<ReflectionResponse>` in `api_service.dart`

---

### `POST /reflection/weekly`

Get AI-generated weekly reflection summary.

**Request Body**

```json
{
  "user_id": "usr_abc123",
  "week_start": "2025-03-10T00:00:00Z",
  "week_end": "2025-03-16T23:59:59Z"
}
```

**Response**

```json
{
  "ai_summary": "This week you felt more energized compared to last week...",
  "ai_insight": "Your energy peaks around midday. Consider scheduling important tasks then.",
  "mood_trend": ["good", "great", "okay", "good", "calm", "good", "great"],
  "average_energy": "medium",
  "average_sleep": "good",
  "streak_days": 5
}
```

**Flutter Model:** `WeeklyReflectionResponse` in `api_service.dart`

---

## Content Library

### `GET /content/list`

Get paginated list of wellness content (articles, audio, video).

**Query Parameters**

| Name | Type | Description |
|---|---|---|
| `type` | string | Filter by type: `article`, `audio`, `video` |
| `season` | string | Filter by season: `spring`, `summer`, `autumn`, `winter` |
| `page` | int | Page number (default: 1) |
| `limit` | int | Items per page (default: 20) |

**Response**

```json
[
  {
    "id": "cnt_001",
    "title": "Morning Rituals for Spring Energy",
    "description": "Start your day with these gentle spring morning practices.",
    "type": "article",
    "image_url": "https://cdn.seasons.app/spring-morning.jpg",
    "video_url": null,
    "audio_url": null,
    "duration_seconds": null,
    "tags": ["morning", "spring", "ritual"],
    "is_premium": false
  },
  {
    "id": "cnt_002",
    "title": "5-Minute Breathing for Anxiety",
    "description": "A guided audio for quick anxiety relief.",
    "type": "audio",
    "image_url": "https://cdn.seasons.app/breathing.jpg",
    "audio_url": "https://cdn.seasons.app/breathing-5min.mp3",
    "duration_seconds": 300,
    "tags": ["breathing", "anxiety", "quick"],
    "is_premium": true
  }
]
```

**Flutter Model:** `List<ContentResponse>` in `api_service.dart`

---

### `GET /content/:contentId`

Get full details of a single content item.

**Response** — same shape as items in `/content/list` but with full body text for articles.

---

## Seasons / Seasonal Wellness

### `GET /season/current`

Get the current season for a user (based on hemisphere).

**Query Parameters**

| Name | Type | Description |
|---|---|---|
| `user_id` | string | User ID |

**Response**

```json
{
  "name": "spring",
  "insight": "Spring is a time of renewal and gentle activation...",
  "food_suggestions": ["Spinach smoothie", "Asparagus soup", "Green tea"],
  "stretch_routines": ["Morning sun salutation", "Gentle neck rolls"],
  "sleep_rituals": ["Open window for fresh air", "Light evening walk"]
}
```

**Flutter Model:** `SeasonResponse` in `api_service.dart`

---

### `GET /season/list`

Get all 24 solar terms / seasons with their date ranges.

**Response** — `List<SeasonResponse>`

---

## Home Dashboard

### `GET /seasons/home/dashboard`

Get the full home screen payload in one call.

**Query Parameters**

| Name | Type | Default | Description |
|---|---|---|---|
| `user_id` | string | ✅ | User ID |
| `hemisphere` | string | `north` | `north` or `south` |

**Response**

```json
{
  "greeting": "Good morning, Jane",
  "daily_insight": {
    "id": "ins_001",
    "text": "Today the early light invites slowness...",
    "season": "spring",
    "generated_at": "2025-03-20T08:00:00Z"
  },
  "suggestions": [
    {
      "id": "sug_001",
      "text": "Take a 10-minute walk outside",
      "category": "movement",
      "icon_name": "directions_walk"
    }
  ],
  "season_card": {
    "name": "Spring",
    "emoji": "🌸",
    "color": "#A8D5A2"
  }
}
```

**Flutter Model:** `HomeDashboardResponse` in `api_service.dart`

---

## Onboarding

### `POST /seasons/onboarding/complete`

Submit onboarding answers to personalize the app.

**Request Body**

```json
{
  "feeling": "a_bit_stressed",
  "help_goal": "reduce_stress",
  "life_stage": "young_adult",
  "support_time": "morning",
  "style_preference": "gentle"
}
```

| Field | Type | Options |
|---|---|---|
| `feeling` | string | `great`, `okay`, `a_bit_stressed`, `struggling` |
| `help_goal` | string | `reduce_stress`, `sleep_better`, `healthy_habits`, `emotional_support` |
| `life_stage` | string | `student`, `young_adult`, `working_professional`, `parent`, `retired` |
| `support_time` | string | `morning`, `afternoon`, `evening`, `any_time` |
| `style_preference` | string | `gentle`, `direct`, `spiritual`, `practical` |

**Response:** `204 No Content` on success

---

## Models

### `GET /models`

List available AI models.

**Response**

```json
[
  {
    "id": "seasons-small",
    "provider": "openai",
    "cost": "low",
    "speed": "fast"
  },
  {
    "id": "seasons-large",
    "provider": "openai",
    "cost": "high",
    "speed": "slow"
  }
]
```

**Flutter Model:** `List<ModelInfo>` in `api_service.dart`

---

## Error Responses

All endpoints may return error responses:

| Status Code | Meaning |
|---|---|
| `400` | Bad Request — invalid parameters |
| `401` | Unauthorized — missing or expired auth token |
| `403` | Forbidden — premium content requires subscription |
| `404` | Not Found — resource does not exist |
| `429` | Rate Limited — too many requests |
| `500` | Internal Server Error |

Error response body:

```json
{
  "error": "rate_limit_exceeded",
  "message": "Too many requests. Please wait 60 seconds.",
  "retry_after": 60
}
```

---

## Rate Limits

| Endpoint Pattern | Limit |
|---|---|
| `/ai/chat` | 20 req/min per user |
| `/ai/chat/stream` | 10 req/min per user |
| All other endpoints | 60 req/min per user |

---

*Last updated: 2026-03*
