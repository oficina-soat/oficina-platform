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

O payload deve incluir os itens financeiros do orçamento em um único array `itens`.

Cada item representa um snapshot financeiro de peça ou serviço calculado pelo `oficina-billing-service` a partir dos itens da Ordem de Serviço.

Campos mínimos:

- `orcamentoId`
- `ordemServicoId`
- `itens`
- `valorTotal`
- `status`
- `geradoEm`

Os itens devem seguir o schema `itemOrcamento` em `contracts/events/schemas/common.schema.json`.
