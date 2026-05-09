# SEASONS — App Store Data Safety Questionnaire Answers

## Apple's Data Safety Form (App Store Connect)

### Does your app collect data? ✅ Yes

### Data Collected

#### 1. Contact Information
- **Email address** — Collected for account creation
  - Purpose: User authentication ✅
  - Purpose: Account functionality ✅
  - Is it linked to identity? Yes
  - Is it used for tracking? No

#### 2. Health & Fitness
- **Health data** (body constitution, wellness preferences)
  - Purpose: App functionality ✅
  - Is it linked to identity? Yes
  - Is it used for tracking? No
- **Other user content** (journal entries)
  - Purpose: App functionality ✅
  - Is it linked to identity? Yes
  - Is it used for tracking? No

#### 3. Usage Data
- **Product interaction** (features used, session duration)
  - Purpose: Analytics ✅
  - Is it linked to identity? No (anonymous)
  - Is it used for tracking? No

#### 4. Diagnostics
- **Crash data**
  - Purpose: App functionality ✅
  - Is it linked to identity? No
  - Is it used for tracking? No

### Data NOT Collected

- ❌ Precise location (only approximate for solar term calculation)
- ❌ Contacts
- ❌ Photos or videos
- ❌ Browser history
- ❌ Search history
- ❌ Financial info (payment processed by Stripe/Apple directly)
- ❌ Sensitive info (racial/ethnic data, sexual orientation, political opinions)
- ❌ Biometric data
- ❌ User content beyond journal entries and chat

### Data Sharing

**Do you share data with third parties?** Yes, limited:
- **AI service provider** — Chat messages processed for AI responses, not stored long-term
- **Stripe** — Payment processing (Stripe handles card data directly, we don't see it)

### Data Retention

- Account data: Retained while account is active, deleted within 30 days of account deletion request
- Journal entries: Retained until user deletes or account is deleted
- Anonymous usage data: Aggregated, no retention limit

### Encryption

**Is data encrypted in transit?** Yes (TLS 1.2+)
**Is data encrypted at rest?** Yes

### Can users request data deletion? ✅ Yes
### Is data independent of user identity? No (health data is personal)
### Does the app comply with applicable data privacy laws? Yes (GDPR, CCPA ready)

---

## Content Rating Questionnaire Answers

### Frequency of Content

| Question | Answer |
|----------|--------|
| Cartoon/fantasy violence | None |
| Realistic violence | None |
| Sexual content/nudity | None |
| Profanity/crude humor | None |
| Alcohol/tobacco/drug use | None |
| Mature/suggestive themes | None |
| Horror/fear themes | None |
| Gambling | None |
| Contests | None |
| Unrestricted web access | No |
| Medical/treatment info | Yes — provides general wellness info based on TCM, not medical advice |

> Note: Select "Yes" for medical info but clarify it's informational/educational, not diagnosis or treatment.

## Expected Rating: **4+**
