# orcamentoRecusado

## Descrição

Indica que o orçamento foi recusado pelo cliente.

## Emissor

```text
oficina-billing-service
```

## Tópico canônico

```text
oficina.billing.orcamento-recusado
```

## Consumidores potenciais

```text
oficina-os-service
```

O `aggregateId` deve identificar a Ordem de Serviço que coordena a Saga. O
identificador financeiro permanece disponível em `payload.orcamentoId`.
