# growth kit (lite, 2026-11-01)

Stdlib-only helpers that sit next to the existing growth package. **Nothing is wired in and every flag defaults to OFF.**
The existing `compliance/gate.py`, `experiments/` and `cycle.py` stay authoritative; this kit replaces none of them.

| module | adds |
|---|---|
| `flags.py` | `GROWTH_LOOP_ENABLED`, `REFERRAL_ENABLED`, `SHARECARD_ENABLED`, `SEO_PAGES_ENABLED` (default off; only the owner changes them on the server). When wiring, also honour `GrowthConfig.kill_switch`. |
| `attribution.py` | UTM/referrer to channel; drops PII-like values; never stores click ids |
| `referral.py` | HMAC-signed referral codes and anti-abuse evaluation (self-referral, duplicate pair, velocity, shared device/payment, caps, 14-day hold, fixed rewards). Today's `invite_code_for` is an unsalted md5 of the user id (guessable) and has no abuse checks. |
| `sharecard.py` | Open Graph + text share cards with language and disclaimer checks |
| `seo_quality.py` | programmatic-page quality gate + Article JSON-LD |
| `claims.py` | EN/ZH forbidden-claim scan (secondary to the existing gate) |

Tests: `python -m pytest tests/growth/test_growth_kit.py`
