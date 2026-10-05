"""Tiny catalog and checkout stub so the shop feels real.

Prices are integer cents. Checkout only honors *active* promotions;
anything pending manager approval is rejected here.
"""

PRODUCTS = {
    "PRETZEL-CLASSIC": ("Classic Salted Pretzel", 450),
    "PRETZEL-PARTY": ("Party Pretzel Bucket", 1899),
    "MIDNIGHT-CRUNCH": ("Midnight Crunch Mix", 725),
    "COCOA-EMERGENCY": ("Emergency Cocoa Packet", 300),
}


class PromotionNotActiveError(Exception):
    """The promo code is unknown or not active at checkout."""


def subtotal(skus):
    """Sum the price in cents of the given product SKUs."""
    return sum(PRODUCTS[sku][1] for sku in skus)


def apply_promotion(service, code, amount_cents):
    """Apply an *active* promotion to an amount and return the new total.

    Pending-approval and unknown codes are rejected — this is the last line
    of defense against a runaway FREE-ALL giving away all the pretzels.
    """
    promo = service.get(code)
    if promo is None or promo.status != "active":
        raise PromotionNotActiveError(f"promotion {code!r} is not active")
    return amount_cents * (100 - promo.discount_pct) // 100
