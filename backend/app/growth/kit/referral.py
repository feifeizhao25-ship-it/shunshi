"""Referral codes and anti-abuse evaluation (pure functions; storage is supplied by the caller).

Principles (research: Management Science 2024 field experiment, G20; FTC fake-engagement rules, G14):
- the invitee's reward is certain and fixed; the inviter's reward is a fixed amount too (no lottery here);
- a reward is only released after a qualifying action (e.g. first paid renewal or day-N retention) AND a hold period;
- idempotent: one reward per (inviter, invitee) pair;
- caps, velocity limits, self-referral and shared-device/payment checks; flagged claims go to manual review, never silently paid.
"""
from __future__ import annotations

import hashlib
import hmac
from dataclasses import dataclass, field
from datetime import datetime, timedelta

CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"  # no 0/O/1/I


def make_code(user_id: str, secret: bytes, length: int = 8) -> str:
    """Deterministic, non-guessable code. `secret` must come from server config, never from the repo."""
    if not secret:
        raise ValueError("secret required")
    digest = hmac.new(secret, f"ref:{user_id}".encode(), hashlib.sha256).digest()
    n = int.from_bytes(digest[:8], "big")
    out = []
    for _ in range(length):
        n, r = divmod(n, len(CODE_ALPHABET))
        out.append(CODE_ALPHABET[r])
    return "".join(out)


def fingerprint(value: str, secret: bytes) -> str:
    """Salted hash of a device id / payment instrument id so the ledger never stores raw identifiers."""
    return hmac.new(secret, f"fp:{value}".encode(), hashlib.sha256).hexdigest()[:32]


@dataclass(frozen=True)
class Policy:
    max_invites_per_day: int = 20
    max_rewarded_lifetime: int = 50
    hold_days: int = 14
    invitee_must_be_new: bool = True
    reward_inviter: int = 1      # fixed units (e.g. months); never random
    reward_invitee: int = 1      # fixed units; certain


@dataclass
class Claim:
    inviter_id: str
    invitee_id: str
    claimed_at: datetime
    invitee_created_at: datetime
    inviter_device_fp: str = ""
    invitee_device_fp: str = ""
    inviter_payment_fp: str = ""
    invitee_payment_fp: str = ""
    qualified_at: datetime | None = None  # when the invitee completed the qualifying action


@dataclass
class History:
    claims_last_24h: int = 0
    rewarded_lifetime: int = 0
    paired: set = field(default_factory=set)  # {(inviter, invitee)} already rewarded or pending


@dataclass(frozen=True)
class Decision:
    status: str                 # "pending" | "release" | "reject" | "review"
    reasons: tuple = ()
    release_at: datetime | None = None
    inviter_units: int = 0
    invitee_units: int = 0


def evaluate(claim: Claim, hist: History, pol: Policy, now: datetime) -> Decision:
    reasons = []
    if claim.inviter_id == claim.invitee_id:
        return Decision("reject", ("self_referral",))
    if (claim.inviter_id, claim.invitee_id) in hist.paired:
        return Decision("reject", ("duplicate_pair",))
    if pol.invitee_must_be_new and claim.invitee_created_at < claim.claimed_at - timedelta(hours=24):
        return Decision("reject", ("invitee_not_new",))
    if hist.rewarded_lifetime >= pol.max_rewarded_lifetime:
        return Decision("reject", ("lifetime_cap",))
    if hist.claims_last_24h >= pol.max_invites_per_day:
        reasons.append("velocity")
    if claim.inviter_device_fp and claim.inviter_device_fp == claim.invitee_device_fp:
        reasons.append("shared_device")
    if claim.inviter_payment_fp and claim.inviter_payment_fp == claim.invitee_payment_fp:
        reasons.append("shared_payment")
    if reasons:
        return Decision("review", tuple(reasons))  # humans decide; nothing is paid automatically
    if claim.qualified_at is None:
        return Decision("pending", ("awaiting_qualifying_action",))
    release_at = claim.qualified_at + timedelta(days=pol.hold_days)
    if now < release_at:
        return Decision("pending", ("hold_period",), release_at=release_at)
    return Decision("release", (), release_at=release_at, inviter_units=pol.reward_inviter, invitee_units=pol.reward_invitee)
