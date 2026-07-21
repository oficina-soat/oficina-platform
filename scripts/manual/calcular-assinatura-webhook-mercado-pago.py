#!/usr/bin/env python3
"""Calcula a assinatura v1 de um webhook conforme o SDK Python do Mercado Pago."""

import argparse
import hashlib
import hmac


def calculate_signature(secret: str, data_id: str, request_id: str, ts: str) -> str:
    """Replica o algoritmo Python documentado, recebendo valores por argumento."""
    data_id = (data_id or "").lower()
    x_request_id = request_id

    parts = []
    if data_id:
        parts.append(f"id:{data_id}")
    if x_request_id:
        parts.append(f"request-id:{x_request_id}")
    parts.append(f"ts:{ts}")
    manifest = ";".join(parts) + ";"

    computed = hmac.new(
        secret.encode(), manifest.encode(), hashlib.sha256
    ).hexdigest()
    return computed


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Calcula a assinatura v1 conforme o SDK Python oficial do Mercado Pago."
    )
    parser.add_argument("secret", help="Chave secreta da assinatura Webhook")
    parser.add_argument("data_id", help="Valor de data.id; será convertido para minúsculas")
    parser.add_argument("request_id", help="Valor do header x-request-id")
    parser.add_argument("ts", help="Valor ts do header x-signature")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    print(calculate_signature(args.secret, args.data_id, args.request_id, args.ts))


if __name__ == "__main__":
    main()
