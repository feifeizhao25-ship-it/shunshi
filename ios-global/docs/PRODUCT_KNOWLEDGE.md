# SEASONS — Product Knowledge Summary

> A concise reference for developers and content writers working on SEASONS.
> For the full product knowledge base, see `knowledge_base.md`.

---

## What Is SEASONS?

SEASONS is an AI-powered calm lifestyle companion app. It helps users live well according to natural rhythms — seasonal, daily, and emotional.

**Core Promise:** "Live well, season by season."

**Target Users:**
- English-speaking adults globally
- Seeking stress management, better sleep, and mindful living
- No prior knowledge of Traditional Chinese Medicine required

---

## Core Features

| Feature | Description |
|---|---|
| AI Companion | Conversational AI wellness guide (chat-based) |
| Daily Insight | AI-generated daily wellness card on home screen |
| Seasonal Living | 24 solar term guides aligned with seasonal rhythms |
| Content Library | Articles, audio sessions, breathing exercises, tea rituals |
| Reflections | Daily mood/energy/sleep journal with weekly AI summary |
| Breathing Exercises | Guided breathing for stress, sleep, energy |
| Tea Rituals | Mindful tea preparation guidance |
| Habit Tracking | Gentle daily habit encouragement |
| Subscription | Free tier + Premium (Serenity, Harmony, Family) |

---

## Seasonal Philosophy

SEASONS divides the year into 4 seasons, each with 3 phases (early/mid/late):

| Season | Months | Core Theme |
|---|---|---|
| **Spring** | Mar – May | Renewal, gentle activation |
| **Summer** | Jun – Aug | Joy, cooling, balance |
| **Autumn** | Sep – Nov | Letting go, grounding |
| **Winter** | Dec – Feb | Rest, reflection, depth |

Each season has distinct:
- **Nutrition** guidance (what to eat / avoid)
- **Movement** recommendations
- **Sleep** adjustments
- **Emotional** focus
- **Tea** rituals
- **Breathing** practices

---

## AI Skills (Global)

12 built-in AI Skills power the app's intelligent responses:

| Skill | Purpose | Premium? |
|---|---|---|
| DailyRhythmPlan | Personalized daily wellness plan | No |
| MoodFirstAid | Immediate emotional support | No |
| SleepWindDown | Pre-sleep relaxation guidance | No |
| OfficeMicroBreak | Quick office wellness breaks | No |
| SolarTermGuide | Current solar term wellness guide | No |
| BodyConstitutionLite | 9-type quick constitution quiz | Yes |
| FoodTeaRecommender | Food and tea recommendations | No |
| AcupressureRoutineLite | Self-massage acupressure guide | No |
| FollowUpGenerator | Gentle follow-up message generation | No |
| PresencePolicyDecider | AI outreach frequency decision | No |
| CareStatusUpdater | Care status scoring | No |
| FamilyCareDigest | Family wellness weekly digest | Yes |

---

## Key Constraints

### Safety
- **No medical diagnoses** — AI must not say "you have [condition]"
- **No prescriptions** — AI must not recommend specific medications
- **No cure claims** — AI must not guarantee outcomes
- **Crisis response** — High-risk emotional signals trigger SafeMode card with professional resources

### Language / Tone
- **Tone**: Warm, gentle, supportive, knowledgeable but not clinical
- **Suggestions**: Small, specific, actionable — never long lists
- **User agency**: Never blame or label the user ("you always...")

### Content
- All user-facing content in English
- Inclusive: all nationalities, all body types, all backgrounds
- Respectful of mental health — no trivializing language

---

## Screens / Pages

| Page | Route | Purpose |
|---|---|---|
| Splash | `/splash` | Launch + auth redirect |
| Onboarding | `/onboarding` | New user setup |
| Home | `/home` (tab 1) | Dashboard with insight + suggestions |
| Companion | `/companion` (tab 2) | AI chat |
| Seasons | `/seasons` (tab 3) | Seasonal content |
| Library | `/library` (tab 4) | Content library |
| Profile | `/profile` (tab 5) | User settings |
| Chat | `/chat` | Standalone AI chat page |
| Reflection | `/reflection` | Daily reflection journal |
| Subscription | `/subscribe` | Premium plans |
| Records | `/records` | History / past reflections |
| Content Detail | `/content/:id` | Single content item |
| Login | `/login` | Auth |

---

## User Data & Privacy

- **Auth**: OAuth 2.0 via Google Sign-In and Sign in with Apple
- **Token storage**: `flutter_secure_storage` (Keychain / EncryptedSharedPreferences)
- **Preferences**: `shared_preferences` (non-sensitive only)
- **No medical data** is collected or stored beyond reflection mood logs
- **Data deletion**: Users can delete account and all associated data

---

## Subscription Tiers

| Tier | Price | Features |
|---|---|---|
| **Free** | $0 | Daily insight, AI companion, basic library |
| **Serenity** | ~$9.99/mo | Body constitution, all library content |
| **Harmony** | ~$19.99/mo | All Serenity + advanced features |
| **Family** | ~$29.99/mo | Family care digest, up to 5 members |

---

## Seasonal Tea Reference

| Season | Tea Types |
|---|---|
| Spring | Green + mint, jasmine, lemon + ginger |
| Summer | Peppermint (iced), hibiscus (iced), chamomile |
| Autumn | Chai, rooibos, ginger + turmeric |
| Winter | Golden turmeric latte, cinnamon + honey, elderberry |

---

## Breathing Exercises Reference

| Technique | Duration | Best For |
|---|---|---|
| Box Breathing | 5 min | Stress, focus |
| 4-7-8 Breathing | 3 min | Sleep, anxiety |
| Diaphragmatic | 10 min | General calm |
| Sitali (Cooling) | 5 min | Heat, frustration |
| Spring Awakening | 5 min | Morning energy |
| Grounding Breath | 5 min | Autumn, anxiety |

---

*Last updated: 2026-03*
*Full knowledge base: `../knowledge_base.md` (shared with android-global)*
