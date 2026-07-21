#!/usr/bin/env python3
"""Calcula a assinatura v1 de um webhook conforme o SDK Python do Mercado Pago."""

import argparse
import binascii
import hashlib
import hmac


def normalize(value: str) -> str | None:
    """Replica a normalização do WebhookSignatureValidator oficial."""
    text = str(value).strip()
    return text if text else None


def calculate_signature(secret: str, data_id: str, request_id: str, ts: str) -> str:
    """Replica a construção do manifesto e o HMAC-SHA256 do SDK oficial."""
    secret = normalize(secret)
    data_id = normalize(data_id)
    request_id = normalize(request_id)
    ts = normalize(ts)

    if secret is None:
        raise ValueError("A chave secreta não pode ser vazia.")
    if ts is None:
        raise ValueError("O ts não pode ser vazio.")

    parts = []
    if data_id:
        parts.append(f"id:{data_id}")
    if request_id:
        parts.append(f"request-id:{request_id}")
    parts.append(f"ts:{ts}")
    signedTemplate = ";".join(parts) + ";"

    cyphedSignature = binascii.hexlify(
        hmac.new(secret.encode(), signedTemplate.encode(), hashlib.sha256).digest()
    )
    return cyphedSignature.decode()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Calcula a assinatura v1 conforme o SDK Python oficial do Mercado Pago."
    )
    parser.add_argument("secret", help="Chave secreta da assinatura Webhook")
    parser.add_argument("data_id", help="Valor de data.id exatamente como recebido")
    parser.add_argument("request_id", help="Valor do header x-request-id")
    parser.add_argument("ts", help="Valor ts do header x-signature")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    print(calculate_signature(args.secret, args.data_id, args.request_id, args.ts))


if __name__ == "__main__":
    main()
