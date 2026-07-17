# orcamentoAprovado

## Descrição

Indica que o orçamento foi aprovado pelo cliente.

## Emissor

```text
oficina-billing-service
```

## Tópico canônico

```text
oficina.billing.orcamento-aprovado
```

## Consumidores potenciais

```text
oficina-os-service
oficina-execution-service
```

O `aggregateId` deve identificar a Ordem de Serviço que coordena a Saga. O
identificador financeiro permanece disponível em `payload.orcamentoId`.
