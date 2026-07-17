# orcamentoGerado

## Descrição

Indica que o orçamento foi consolidado e disponibilizado para aprovação.

## Emissor

```text
oficina-billing-service
```

## Tópico canônico

```text
oficina.billing.orcamento-gerado
```

## Consumidores potenciais

```text
oficina-os-service
```

## Payload

O `aggregateId` deve identificar a Ordem de Serviço que coordena a Saga. O
identificador financeiro permanece disponível em `payload.orcamentoId`.

O payload deve incluir os itens financeiros do orçamento em um único array `itens`.

Cada item representa um snapshot financeiro de peça ou serviço calculado pelo `oficina-billing-service` a partir dos itens da Ordem de Serviço.

Campos mínimos:

- `orcamentoId`
- `ordemServicoId`
- `itens`
- `valorTotal`
- `status`
- `geradoEm`

Os itens devem seguir o schema `itemOrcamento` em [common.schema.json](schemas/common.schema.json).
