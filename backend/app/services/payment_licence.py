"""Online checkout stays closed until an operator sets a payment-licence flag.

Same rule as energy-intelligence PR #119: unset, empty, or ``0`` is closed.
``1``, ``true``, ``yes``, or ``granted`` opens checkout. Production compose
does not set ``BUSINESS_LICENSE_GRANTED``, so paid checkout is off there.
Refunds and reads of stored orders do not use this gate.
"""
from __future__ import annotations

import os
from collections.abc import Mapping

_OPEN = {"1", "true", "yes", "granted"}


def license_granted_from_env(env: Mapping[str, str] | None = None) -> bool:
    source = os.environ if env is None else env
    raw = str(source.get("BUSINESS_LICENSE_GRANTED") or "").strip().lower()
    return raw in _OPEN


def paid_checkout_open(license_granted: bool) -> bool:
    return bool(license_granted)
