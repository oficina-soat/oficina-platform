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
    def test_converts_data_id_to_lowercase_before_calculating(self):
        uppercase_signature = MODULE.calculate_signature(
            "your_secret_key_here",
            "ORD01JQ4S4KY8HWQ6NA5PXB65B3D3",
            "2066ca19-c6f1-498a-be75-1923005edd06",
            "1742505638683",
        )
        lowercase_signature = MODULE.calculate_signature(
            "your_secret_key_here",
            "ord01jq4s4ky8hwq6na5pxb65b3d3",
            "2066ca19-c6f1-498a-be75-1923005edd06",
            "1742505638683",
        )

        self.assertEqual(lowercase_signature, uppercase_signature)

    def test_matches_documented_hmac_algorithm(self):
        signature = MODULE.calculate_signature(
            "secret", "ORDER", "request", "123"
        )

        self.assertEqual(
            "37222538c95fb9767794da6db9dcbd341e140c8238d6ce4cea946cf3a277f279",
            signature,
        )


if __name__ == "__main__":
    unittest.main()
