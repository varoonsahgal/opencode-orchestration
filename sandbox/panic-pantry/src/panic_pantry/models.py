"""Data model for Panic Pantry promotions."""

from dataclasses import dataclass
import re

CODE_PATTERN = re.compile(r"^[A-Z0-9-]{3,20}$")
VALID_STATUSES = ("active", "pending_approval")


@dataclass
class Promotion:
    """A discount promotion.

    code: uppercase letters, digits, and dashes, 3-20 chars (CODE_PATTERN).
    discount_pct: whole percent, integer 1-100 inclusive.
    status: "active" or "pending_approval".
    created_at: ISO-8601 string supplied by the service (fixed in this sandbox
        so tests stay deterministic).
    """

    code: str
    discount_pct: int
    status: str
    created_at: str

    def __post_init__(self):
        if not isinstance(self.code, str) or not CODE_PATTERN.match(self.code):
            raise ValueError(f"invalid promotion code: {self.code!r}")
        if (
            not isinstance(self.discount_pct, int)
            or isinstance(self.discount_pct, bool)
            or not 1 <= self.discount_pct <= 100
        ):
            raise ValueError(
                f"discount_pct must be an integer from 1 to 100, got {self.discount_pct!r}"
            )
        if self.status not in VALID_STATUSES:
            raise ValueError(f"invalid status: {self.status!r}")

    def to_dict(self):
        return {
            "code": self.code,
            "discount_pct": self.discount_pct,
            "status": self.status,
            "created_at": self.created_at,
        }

    @classmethod
    def from_dict(cls, raw):
        return cls(
            code=raw["code"],
            discount_pct=raw["discount_pct"],
            status=raw["status"],
            created_at=raw["created_at"],
        )
