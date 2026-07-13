# Evidência da Integração Mercado Pago no Lab

## Escopo

Este documento registra as validações remotas de `[B2-MP-REM-001]` e as tentativas de `[B2-MP-EVID-001]` no ambiente `lab`, conforme os [nomes de runtime, secrets e infraestrutura](../infrastructure/infra-runtime-naming.md) e o [Checklist Final de Entrega da Fase 4](phase-4-delivery-checklist.md).

Nenhum access token, JWT, segredo AWS ou conteúdo de Secret Kubernetes foi exibido ou registrado. As consultas automatizadas usaram as credenciais apenas em memória e registraram somente metadados e respostas sanitizadas.

## Habilitação do Runtime

Validação executada em 13/07/2026:

| Evidência | Resultado |
|---|---|
| GitHub Variable `OFICINA_MERCADO_PAGO_ENABLED` | Configurada como `true` no `oficina-infra`. |
| GitHub Secret `OFICINA_MERCADO_PAGO_ACCESS_TOKEN` | Disponível ao workflow e exibido somente como valor mascarado. |
| Publicação do Billing | O [run 29279434097](https://github.com/oficina-soat/oficina-billing-service/actions/runs/29279434097) concluiu Maven, SonarCloud, publicação da imagem no ECR e rollout no EKS. |
| Deploy da infraestrutura | O [run 29281650258](https://github.com/oficina-soat/oficina-infra/actions/runs/29281650258) concluiu com sucesso. |
| Secret Kubernetes | O log registrou `secret/oficina-billing-service-mercado-pago-env created`, sem exibir seu conteúdo. |
| Deployment | O log registrou a aplicação de `oficina-billing-service` e `deployment.apps/oficina-billing-service patched` após a atualização dos checksums de runtime. |

Essas evidências concluem `[B2-MP-REM-001]`: a integração está habilitada no runtime do Billing e a credencial é entregue fora do Git.

## Tentativa de Cobrança PIX

A Auth Lambda foi reaplicada no novo API Gateway pelo [run 29281966848](https://github.com/oficina-soat/oficina-auth-lambda/actions/runs/29281966848). O login seed do lab retornou sucesso, e a chamada abaixo chegou ao `oficina-billing-service`:

```http
POST /api/v1/pagamentos
X-Correlation-Id: b2-mp-evid-001-20260713T202400Z
Idempotency-Key: 7db9ad59-4a2c-4f34-9f7f-55f289cb36d1
Content-Type: application/json

{
  "ordemServicoId": "6b2276e8-fa72-4f4c-a3b0-2c5b1bf427ef",
  "orcamentoId": "91000000-0000-4000-8000-000000000002",
  "valor": 190.00,
  "metodo": "PIX"
}
```

Resposta recebida em `2026-07-13T20:27:56Z`:

```json
{
  "status": 502,
  "error": "Bad Gateway",
  "code": "DEPENDENCY_FAILURE",
  "message": "Mercado Pago recusou a solicitacao de pagamento com HTTP 401.",
  "path": "/api/v1/pagamentos",
  "correlationId": "b2-mp-evid-001-20260713T202400Z",
  "service": "oficina-billing-service"
}
```

O resultado comprova que a integração habilitada chamou o Mercado Pago. Entretanto, a API do provedor rejeitou a credencial com HTTP `401`, antes da persistência do pagamento. Portanto, não foram gerados `pagamentoId`, `transacaoExternaId` nem `external_reference` comprovável pela API sandbox.

### Revalidação após atualização informada do token

Uma nova aplicação foi executada pelo [run 29283226983](https://github.com/oficina-soat/oficina-infra/actions/runs/29283226983). O workflow concluiu com sucesso, mas o Kubernetes registrou `secret/oficina-billing-service-mercado-pago-env unchanged`, indicando que o valor efetivamente entregue ao `oficina-infra` era idêntico ao da execução anterior. O Deployment recebeu novamente o patch de checksum.

A cobrança foi repetida com identificadores inéditos:

| Campo | Valor |
|---|---|
| `correlationId` | `b2-mp-evid-001-20260713T204200Z` |
| `Idempotency-Key` | `14c79872-2a6c-4ab6-ac52-541ed35e4142` |
| Status HTTP local | `502` |
| Código local | `DEPENDENCY_FAILURE` |
| Resposta do Mercado Pago | HTTP `401` |

Essa revalidação confirma que a credencial consumida pelo workflow continuou sendo rejeitada pelo provedor. O token deve ser atualizado no escopo que disponibiliza `OFICINA_MERCADO_PAGO_ACCESS_TOKEN` ao repositório `oficina-soat/oficina-infra`; atualizar um secret homônimo apenas no repositório do Billing não altera o workflow central de infraestrutura.

### Revalidação com a nova aplicação

Após a criação de uma aplicação configurada para Checkout Transparente e API de Pagamentos, o [run 29286065300](https://github.com/oficina-soat/oficina-infra/actions/runs/29286065300) concluiu com sucesso. O deploy registrou `secret/oficina-billing-service-mercado-pago-env configured` e atualizou o checksum do `oficina-billing-service`, confirmando que o pod recebeu a nova configuração sem expor a credencial.

A cobrança foi repetida com os seguintes identificadores:

| Campo | Valor |
|---|---|
| `correlationId` | `b2-mp-evid-001-20260713T212500Z` |
| `Idempotency-Key` | `c815e422-667d-49af-8fe0-1c855b9a188a` |
| Status HTTP local | `502` |
| Código local | `DEPENDENCY_FAILURE` |
| Resposta do Mercado Pago | HTTP `400` |
| `traceId` no pod | `8eb8e4a508a9d17f0ea652c953df5082` |
| `requestId` no pod | `bf7c4746-990d-4740-aeb3-190c822867f7` |

Uma chamada diagnóstica direta ao mesmo endpoint do provedor, com resposta sanitizada, revelou o erro `2034` (`Invalid users involved`). A inspeção segura do Secret implantado confirmou posteriormente que a credencial pertence à classe `TEST`; portanto, a hipótese inicial de credencial produtiva estava incorreta.

A causa era o e-mail `test_user_br@testuser.com`. Esse valor pertence ao roteiro de teste do Checkout Transparente via `/v1/orders`, enquanto o Billing usa a API legada `/v1/payments`, documentada no fluxo do Checkout Bricks. A [documentação oficial de teste do Checkout Bricks](https://www.mercadopago.com.br/developers/pt/docs/checkout-bricks/integration-test/test-payment-flow) orienta explicitamente a não usar e-mail de usuário de teste e a informar um e-mail comum diferente do e-mail da conta Mercado Pago. Uma chamada direta com `cliente.local@oficina.com` retornou HTTP `201`, transação `1348556009`, status `pending` e `external_reference=e0b09832-eab6-4ee4-a57a-29bb29585f6c`.

### Cobrança PIX concluída pelo fluxo real

A variável `OFICINA_MERCADO_PAGO_PAYER_EMAIL` foi corrigida para `cliente.local@oficina.com`, e o [run 29286908886](https://github.com/oficina-soat/oficina-infra/actions/runs/29286908886) reaplicou a configuração e concluiu o rollout do Billing. Como os orçamentos aprovados do seed já possuíam pagamento, o orçamento `91000000-0000-4000-8000-000000000001` foi aprovado pela API pública antes da cobrança, sem alteração direta no banco.

Request funcional:

```http
POST /api/v1/pagamentos
X-Correlation-Id: b2-mp-evid-001-20260713T214100Z
Idempotency-Key: ecdf4cc0-7a17-4c6c-88f0-610481a47da5
Content-Type: application/json

{
  "ordemServicoId": "5b2276e8-fa72-4f4c-a3b0-2c5b1bf427ef",
  "orcamentoId": "91000000-0000-4000-8000-000000000001",
  "valor": 220.00,
  "metodo": "PIX"
}
```

Resposta HTTP `201`:

```json
{
  "pagamentoId": "1d43fc0b-8802-4b20-bc7f-483c722e3468",
  "ordemServicoId": "5b2276e8-fa72-4f4c-a3b0-2c5b1bf427ef",
  "orcamentoId": "91000000-0000-4000-8000-000000000001",
  "valor": 220.00,
  "metodo": "PIX",
  "status": "CRIADO",
  "provedor": "mercado-pago",
  "transacaoExternaId": "1327656764"
}
```

O `GET /api/v1/pagamentos/1d43fc0b-8802-4b20-bc7f-483c722e3468` retornou HTTP `200` com os mesmos dados, comprovando a persistência local. O `GET /v1/payments/1327656764` na API do Mercado Pago também retornou HTTP `200`, `status=pending`, `status_detail=pending_waiting_transfer`, `payment_method_id=pix` e `external_reference=1d43fc0b-8802-4b20-bc7f-483c722e3468`.

O pod registrou a requisição HTTP `201` e o evento Outbox `pagamentoSolicitado` com:

| Campo | Valor |
|---|---|
| `eventId` | `99b5557e-1271-4257-9c98-532778b59455` |
| `aggregateId` | `1d43fc0b-8802-4b20-bc7f-483c722e3468` |
| `correlationId` | `b2-mp-evid-001-20260713T214100Z` |
| `traceId` | `a8806fb6555e7695f3e7772223e4149b` |
| `spanId` | `ec1ab93b801be5b1` |
| Tópico | `oficina.billing.pagamento-solicitado` |

## Pendência

`[B2-MP-EVID-001]` permanece aberto somente pela comprovação no New Relic. A cobrança, a persistência local, a consulta na API sandbox, o `external_reference`, os logs, o trace e o evento Outbox já foram confirmados. A tentativa de consultar o evento por NerdGraph com a licença do collector retornou HTTP `401`, comportamento esperado porque essa chave autoriza ingestão, não consultas. Para concluir, executar com uma New Relic User API Key:

```nrql
FROM Log SELECT count(*)
WHERE correlationId = 'b2-mp-evid-001-20260713T214100Z'
  AND domainEventType = 'pagamentoSolicitado'
SINCE 30 minutes ago
```
