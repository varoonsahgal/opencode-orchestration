"""Promotion service for Panic Pantry.

POLICY: discounts strictly greater than 20 percent require manager approval.
They are stored as "pending_approval" and must never become active through
any automated path. Exactly 20 percent is allowed and becomes active.
All new entry points (importers, APIs, scripts) must create promotions
through PromotionService.create_promotion so this policy holds everywhere.
"""

import json
from pathlib import Path

from .models import Promotion

APPROVAL_THRESHOLD_PCT = 20

# Fixed timestamp keeps the sandbox deterministic; a real shop would inject a clock.
_FIXED_TIMESTAMP = "2026-01-01T00:00:00Z"


class PromotionError(Exception):
    """Base error for promotion operations."""


class InvalidPromotionError(PromotionError):
    """Code format, discount range, or state is invalid."""


class DuplicatePromotionError(PromotionError):
    """A promotion with this code already exists."""


class PromotionService:
    """In-memory promotion store persisted to a JSON file."""

    def __init__(self, data_path="data/promotions.json", now=None):
        self._path = Path(data_path)
        self._now = now or (lambda: _FIXED_TIMESTAMP)
        self._promotions = {}
        if self._path.exists():
            raw = json.loads(self._path.read_text(encoding="utf-8") or "{}")
            self._promotions = {c: Promotion.from_dict(d) for c, d in raw.items()}

    def create_promotion(self, code, discount_pct):
        """Create a promotion, enforcing the approval policy.

        Policy: a discount of 20 percent or less becomes "active" immediately.
        A discount strictly greater than 20 percent requires manager approval:
        it is stored as "pending_approval" and is not usable at checkout until
        a manager calls approve().

        Raises InvalidPromotionError for a bad code format or discount value,
        DuplicatePromotionError if the code already exists. Never overwrites.
        """
        if code in self._promotions:
            raise DuplicatePromotionError(f"promotion {code!r} already exists")
        needs_approval = (
            isinstance(discount_pct, int)
            and not isinstance(discount_pct, bool)
            and discount_pct > APPROVAL_THRESHOLD_PCT
        )
        status = "pending_approval" if needs_approval else "active"
        try:
            promo = Promotion(
                code=code, discount_pct=discount_pct, status=status, created_at=self._now()
            )
        except ValueError as exc:
            raise InvalidPromotionError(str(exc)) from exc
        self._promotions[code] = promo
        self._save()
        return promo

    def get(self, code):
        """Return the Promotion for code, or None."""
        return self._promotions.get(code)

    def list_active(self):
        """Return active promotions, sorted by code."""
        active = [p for p in self._promotions.values() if p.status == "active"]
        return sorted(active, key=lambda p: p.code)

    def approve(self, code):
        """Manager-only path: activate a pending promotion.

        Only a human manager may call this; automated imports must never
        approve promotions. Raises InvalidPromotionError if the code is
        unknown or not pending approval.
        """
        promo = self._promotions.get(code)
        if promo is None:
            raise InvalidPromotionError(f"unknown promotion: {code!r}")
        if promo.status != "pending_approval":
            raise InvalidPromotionError(f"promotion {code!r} is not pending approval")
        promo.status = "active"
        self._save()
        return promo

    def _save(self):
        self._path.parent.mkdir(parents=True, exist_ok=True)
        payload = {c: p.to_dict() for c, p in sorted(self._promotions.items())}
        self._path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
