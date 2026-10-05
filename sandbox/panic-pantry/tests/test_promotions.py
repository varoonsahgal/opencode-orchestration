"""Deterministic tests for the existing promotion service and store."""

import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "src"))

from panic_pantry import store  # noqa: E402
from panic_pantry.promotions import (  # noqa: E402
    DuplicatePromotionError,
    InvalidPromotionError,
    PromotionService,
)


class PromotionServiceTests(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.data_path = Path(self._tmp.name) / "promotions.json"
        self.service = PromotionService(self.data_path)

    def tearDown(self):
        self._tmp.cleanup()

    def test_small_discount_is_active(self):
        promo = self.service.create_promotion("SNACK10", 10)
        self.assertEqual(promo.status, "active")
        self.assertIn("SNACK10", [p.code for p in self.service.list_active()])

    def test_boundary_exactly_20_is_active(self):
        promo = self.service.create_promotion("MIDNIGHT20", 20)
        self.assertEqual(promo.status, "active")

    def test_21_requires_approval(self):
        promo = self.service.create_promotion("JUSTOVER", 21)
        self.assertEqual(promo.status, "pending_approval")
        self.assertNotIn("JUSTOVER", [p.code for p in self.service.list_active()])

    def test_25_requires_approval(self):
        promo = self.service.create_promotion("VIP25", 25)
        self.assertEqual(promo.status, "pending_approval")

    def test_duplicate_code_rejected_and_not_overwritten(self):
        self.service.create_promotion("CRUNCH10", 10)
        with self.assertRaises(DuplicatePromotionError):
            self.service.create_promotion("CRUNCH10", 15)
        self.assertEqual(self.service.get("CRUNCH10").discount_pct, 10)

    def test_bad_code_format_rejected(self):
        for bad in ["free-all", "AB", "SNACK_10", "WAY-TOO-LONG-CODE-NAME-123", ""]:
            with self.assertRaises(InvalidPromotionError, msg=bad):
                self.service.create_promotion(bad, 10)

    def test_bad_discount_range_rejected(self):
        for bad in [0, 101, -5, "10"]:
            with self.assertRaises(InvalidPromotionError, msg=repr(bad)):
                self.service.create_promotion("OKCODE", bad)
        self.assertIsNone(self.service.get("OKCODE"))

    def test_approve_moves_pending_to_active(self):
        self.service.create_promotion("BIGDEAL", 30)
        promo = self.service.approve("BIGDEAL")
        self.assertEqual(promo.status, "active")
        self.assertIn("BIGDEAL", [p.code for p in self.service.list_active()])

    def test_approve_requires_pending_promotion(self):
        self.service.create_promotion("SNACK10", 10)
        with self.assertRaises(InvalidPromotionError):
            self.service.approve("SNACK10")
        with self.assertRaises(InvalidPromotionError):
            self.service.approve("NOPE")

    def test_persistence_roundtrip(self):
        self.service.create_promotion("SNACK10", 10)
        self.service.create_promotion("BIGDEAL", 30)
        reloaded = PromotionService(self.data_path)
        self.assertEqual(reloaded.get("SNACK10").status, "active")
        self.assertEqual(reloaded.get("BIGDEAL").status, "pending_approval")


class StoreTests(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.service = PromotionService(Path(self._tmp.name) / "promotions.json")

    def tearDown(self):
        self._tmp.cleanup()

    def test_subtotal(self):
        self.assertEqual(store.subtotal(["PRETZEL-CLASSIC", "COCOA-EMERGENCY"]), 750)

    def test_apply_active_promotion(self):
        self.service.create_promotion("SNACK10", 10)
        self.assertEqual(store.apply_promotion(self.service, "SNACK10", 1000), 900)

    def test_apply_rejects_pending_promotion(self):
        self.service.create_promotion("FREE-ALL", 100)
        self.assertEqual(self.service.get("FREE-ALL").status, "pending_approval")
        with self.assertRaises(store.PromotionNotActiveError):
            store.apply_promotion(self.service, "FREE-ALL", 1000)

    def test_apply_rejects_unknown_code(self):
        with self.assertRaises(store.PromotionNotActiveError):
            store.apply_promotion(self.service, "GHOST-CODE", 1000)


if __name__ == "__main__":
    unittest.main()
