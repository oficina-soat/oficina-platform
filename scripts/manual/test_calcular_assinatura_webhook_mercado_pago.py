#!/usr/bin/env python3
"""Testes do cálculo de assinatura do Webhook Mercado Pago."""

import importlib.util
from pathlib import Path
import unittest


SCRIPT_PATH = Path(__file__).with_name("calcular-assinatura-webhook-mercado-pago.py")
SPEC = importlib.util.spec_from_file_location("mercado_pago_signature", SCRIPT_PATH)
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class CalculateSignatureTest(unittest.TestCase):
    def test_matches_official_sdk_vector_and_preserves_data_id_case(self):
        signature = MODULE.calculate_signature(
            "your_secret_key_here",
            "ORD01JQ4S4KY8HWQ6NA5PXB65B3D3",
            "2066ca19-c6f1-498a-be75-1923005edd06",
            "1742505638683",
        )

        self.assertEqual(
            "fb15ae6472eb449173c556793205d77787d58f384d183bb5bc3b724c27bd103c",
            signature,
        )

    def test_strips_surrounding_whitespace_like_official_validator(self):
        expected = MODULE.calculate_signature("secret", "ORDER", "request", "123")

        actual = MODULE.calculate_signature(
            " secret ", " ORDER ", " request ", " 123 "
        )

        self.assertEqual(expected, actual)


if __name__ == "__main__":
    unittest.main()
