"""Growth kit (2026-11-01, lite): attribution channels, referral anti-abuse, share cards, SEO page quality gate, claims scan.

Complements the existing growth code; it replaces nothing. Rules:
- stdlib only; no network calls; no third-party account logins; no fake engagement.
- every user-visible capability is behind a flag that defaults to OFF (see flags.py).
- the existing compliance gate and self-improvement loop of this repo stay authoritative.
"""
from .flags import GrowthFlags  # noqa: F401

__all__ = ["GrowthFlags"]
