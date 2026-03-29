# SEASONS API Documentation

> **Base URL:** `http://116.62.32.43/api/v1`
> **SEASONS API:** `http://116.62.32.43/api/v1/seasons`
> **Health:** `http://116.62.32.43/api/v1/seasons/season/current`

---

## Table of Contents

1. [SEASONS Global API](#-seasons-global-api)
2. [Authentication](#-authentication)
3. [Content Library](#-content-library)
4. [Body Constitution](#-body-constitution)
5. [Family & Members](#-family--members)
6. [Chat](#-chat)
7. [Payments](#-payments)
8. [User Management](#-user-management)
9. [Wellness Content](#-wellness-content)
10. [Admin & CMS](#-admin--cms)

---

## 🔵 SEASONS Global API

All endpoints under `/api/v1/seasons/*`

### Reflections

#### Submit Daily Reflection
```
POST /api/v1/seasons/reflection/submit
```
**Request Body:**
```json
{
  "user_id": "string",
  "mood": "happy|calm|neutral|sad|anxious",
  "energy": "high|medium|low",
  "sleep": "good|fair|poor",
  "notes": "string (optional)"
}
```
**Response:**
```json
{
  "id": "uuid",
  "success": true
}
```

#### Get Reflection History
```
GET /api/v1/seasons/reflection/list?user_id=xxx
```
**Response:** Array of up to 30 most recent reflections, newest first.

#### Weekly Reflection Summary
```
POST /api/v1/seasons/reflection/weekly
```
**Request Body:**
```json
{
  "user_id": "string",
  "week_start": "2026-03-16",
  "week_end": "2026-03-22"
}
```
**Response:**
```json
{
  "ai_summary": "string",
  "ai_insight": "string",
  "mood_trend": ["happy", "calm", ...],
  "average_energy": "medium",
  "average_sleep": "good",
  "streak_days": 7
}
```

---

### Seasons

#### Get Current Season
```
GET /api/v1/seasons/season/current?user_id=xxx&hemisphere=north|south
```
**Response:**
```json
{
  "name": "Spring|Summer|Autumn|Winter",
  "insight": "Today, consider starting something new...",
  "food_suggestions": ["Leafy greens", "Sprouts", ...],
  "stretch_routines": ["Morning Wake-Up Stretch", ...],
  "sleep_rituals": ["Wind-down routine", ...]
}
```

#### List All Seasons
```
GET /api/v1/seasons/season/list
```
**Response:**
```json
[
  {"name": "Spring", "emoji": "🌱", "insight": "...", "phase": "early"},
  {"name": "Summer", "emoji": "☀️", "insight": "...", "phase": "mid"},
  {"name": "Autumn", "emoji": "🍂", "insight": "...", "phase": "mid"},
  {"name": "Winter", "emoji": "❄️", "insight": "...", "phase": "late"}
]
```

---

### Users

#### Get User Profile
```
GET /api/v1/seasons/user/{user_id}
```

#### Update User Profile
```
PUT /api/v1/seasons/user/{user_id}
```
**Request Body:**
```json
{
  "name": "string",
  "avatar_url": "string",
  "country": "US|CN|...",
  "subscription": "free|premium|team"
}
```

---

### Content Library

#### List Content
```
GET /api/v1/seasons/content/list?type=breathing|stretch|tea|sleep|meditation|reflection&season=spring&page=1&limit=20
```

**Content Types:**
- `breathing` — 7 breathing exercises (4-7-8, Box, Diaphragmatic, etc.)
- `stretch` — 7 stretch routines (Morning Wake-Up, Sun Salutation, etc.)
- `tea` — 7 tea recipes (Chamomile, Peppermint, Matcha, etc.)
- `sleep` — 7 sleep practices (Sleep Hygiene, PMR, Wind-Down, etc.)
- `meditation` — 7 meditations (Body Scan, Loving-Kindness, etc.)
- `reflection` — 7 reflection prompts (Gratitude, Mood Check-In, etc.)

#### Get Content Detail
```
GET /api/v1/seasons/content/{content_id}
```
Example content IDs: `breathing_1`, `stretch_1`, `tea_1`, `sleep_1`, `meditation_1`, `reflection_1`

---

## 🔐 Authentication

### Register
```
POST /api/v1/auth/register
```
**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "string",
  "name": "string"
}
```

### Login
```
POST /api/v1/auth/login
```
**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "string"
}
```
**Response:**
```json
{
  "access_token": "string",
  "refresh_token": "string",
  "user": { ... }
}
```

### Refresh Token
```
POST /api/v1/auth/refresh
```

### Social Login
```
POST /api/v1/auth/google
POST /api/v1/auth/apple/login
POST /api/v1/auth/apple/refresh
```

### Guest Login
```
POST /api/v1/auth/guest-login
POST /api/v1/auth/guest/convert  (convert guest to full account)
```

### SMS Auth (China)
```
POST /api/v1/auth/sms/send
POST /api/v1/auth/sms/verify
```

### Get Current User
```
GET /api/v1/auth/me
```

### Logout
```
POST /api/v1/auth/logout
```

### Device Management
```
GET  /api/v1/auth/devices
DELETE /api/v1/auth/devices/{device_id}
```

### Account Management
```
DELETE /api/v1/auth/account          (delete account)
POST  /api/v1/auth/account/cancel-delete
POST  /api/v1/auth/data/export
POST  /api/v1/auth/memory/reset
```

---

## 📚 Content Library (Legacy)

### Articles
```
GET /api/v1/articles
GET /api/v1/articles/recommended
GET /api/v1/articles/{slug_or_id}
```

### Beverages
```
GET /api/v1/beverages
GET /api/v1/beverages/{beverage_id}
GET /api/v1/beverages/recommended
```

### Audio Content
```
GET /api/v1/audio/list
GET /api/v1/audio/{audio_id}
GET /api/v1/audio/recommended
```

---

## 🧘 Body Constitution

### Get Body Types
```
GET /api/v1/constitution/types
```

### Get Questions
```
GET /api/v1/constitution/questions
```

### Submit Test
```
POST /api/v1/constitution/submit
```

### Get Result
```
GET /api/v1/constitution/result/{user_id}
```

### Get Detailed Type
```
GET /api/v1/constitution/types/{name}
```

---

## 👨‍👩‍👧 Family & Members

### Get Family Overview
```
GET /api/v1/family/
```

### Get Family Members
```
GET /api/v1/family/{family_id}/members
```

### Add Family Member
```
POST /api/v1/family/{family_id}/members
```

### Update Member
```
PUT /api/v1/family/{family_id}/members/{member_id}
```

### Remove Member
```
DELETE /api/v1/family/{family_id}/members/{member_id}
```

### Get Member Health
```
GET /api/v1/family/members/{member_id}/health
```

### Get Family Seats
```
GET /api/v1/family/family-seats
```

---

## 💬 Chat

### SEASONS Chat (Global AI Chat)
```
POST /api/v1/seasons/chat/send
GET  /api/v1/seasons/chat/conversations
GET  /api/v1/seasons/chat/conversations/{conversation_id}
DELETE /api/v1/seasons/chat/conversations/{conversation_id}
GET  /api/v1/seasons/chat/history/{conversation_id}
```

### Legacy Chat
```
POST /api/v1/chat/
GET  /api/v1/chat/context
```

---

## 💳 Payments

### Products
```
GET /api/v1/products
GET /api/v1/subscription/products
```

### Create Order
```
POST /api/v1/subscription/create-order
POST /api/v1/stripe/create-order
```

### Query Order
```
GET /api/v1/subscription/query-order?order_id=xxx
GET /api/v1/stripe/query-order
```

### Refund
```
POST /api/v1/subscription/refund
```

### Payment Notify (Webhook)
```
POST /api/v1/subscription/notify
POST /api/v1/stripe/notify
```

### Alipay (China)
```
GET /api/v1/subscription/alipay/order/{order_id}
```

---

## 👤 User Management

### Profile
```
GET  /api/v1/users/{user_id}
PUT  /api/v1/users/{user_id}
DELETE /api/v1/users/{user_id}
```

### Memory
```
GET  /api/v1/memory
POST /api/v1/memory
DELETE /api/v1/memory/{memory_id}
DELETE /api/v1/memory
```

### Lifecycle
```
GET  /api/v1/lifecycle/
```

### Follow-up
```
GET  /api/v1/followup/
POST /api/v1/followup/
DELETE /api/v1/followup/{followup_id}
```

---

## 🌿 Wellness Content

### Solar Terms (24节气)
```
GET /api/v1/solar-terms/current          (or enhanced/current)
GET /api/v1/solar-terms/list
GET /api/v1/solar-terms/daily
GET /api/v1/solar-terms/morning
GET /api/v1/solar-terms/noon
GET /api/v1/solar-terms/afternoon
GET /api/v1/solar-terms/evening
GET /api/v1/solar-terms/night
GET /api/v1/solar-terms/enhanced/current
GET /api/v1/solar-terms/enhanced/all
GET /api/v1/solar-terms/enhanced/{term_name}
```

### Daily Plan
```
GET /api/v1/today-plan/daily
GET /api/v1/today-plan/due
GET /api/v1/today-plan/check-due
```

### Records
```
GET /api/v1/records/{record_type}/{record_id}
POST /api/v1/records/
DELETE /api/v1/records/{record_type}/{record_id}
```

### Wellness Reports
```
GET /api/v1/wellness-reports/
```

### Care
```
GET /api/v1/care/today
GET /api/v1/care/stats
GET /api/v1/care
```

---

## 🛠️ Admin & CMS

### Content CMS
```
GET  /api/v1/cms/content/{content_id}
POST /api/v1/cms/content
PUT  /api/v1/cms/content/{content_id}
DELETE /api/v1/cms/content/{content_id}
POST /api/v1/cms/content/{content_id}/publish
POST /api/v1/cms/content/{content_id}/archive
POST /api/v1/cms/content/{content_id}/media
GET  /api/v1/cms/content/{content_id}/media
GET  /api/v1/cms/tags
POST /api/v1/cms/tags
```

### Content Review
```
POST /api/v1/cms/review/submit/{content_id}
POST /api/v1/cms/review/approve/{content_id}
POST /api/v1/cms/review/reject/{content_id}
```

### Cards
```
GET /api/v1/cards/
```

### Recommendations
```
GET /api/v1/recommendations/list
POST /api/v1/recommendations/relevant
POST /api/v1/recommendations/personalized-plan
POST /api/v1/recommendations/personalized-plan/daily
POST /api/v1/recommendations/constitution-analyze
```

### Notifications
```
GET  /api/v1/notifications/
POST /api/v1/notifications/
DELETE /api/v1/notifications/{notification_id}
```

### Settings
```
GET /api/v1/settings/config
GET /api/v1/settings/preferences
```

### Subscription Stats
```
GET /api/v1/subscription/stats
GET /api/v1/subscription/usage
```

---

## 🔧 System Endpoints

### Health
```
GET /               → {"service": "ShunShi AI Router", "status": "running"}
GET /health         → {"status": "healthy", "timestamp": "..."}
GET /metrics        → Prometheus metrics (text/plain)
```

### Models
```
GET /models         → List available LLM models
```

### Stats
```
GET /stats          → Cache and audit statistics
```

### Prompts
```
GET /prompts        → List all prompts
GET /prompts/{name} → Get prompt by name
```

### Audio Models
```
GET /api/v1/speech/models  → Available voice models
```

---

## Error Responses

All errors return a standard JSON structure:

```json
{
  "detail": "Error message description"
}
```

Common HTTP status codes:
- `200` — Success
- `400` — Bad Request (validation error)
- `401` — Unauthorized (missing/invalid token)
- `403` — Forbidden
- `404` — Not Found
- `422` — Validation Error
- `500` — Internal Server Error
- `502` — Bad Gateway (LLM call failed)

---

## Rate Limits

No explicit rate limits are enforced at the API level. The routing layer uses Redis caching for LLM responses to reduce costs.

---

*Last updated: 2026-03-24*
