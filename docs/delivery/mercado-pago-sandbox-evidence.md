# Evidência da Integração Mercado Pago no Lab

## Escopo

Este documento registra as validações remotas de `[B2-MP-REM-001]` e as tentativas de `[B2-MP-EVID-001]` no ambiente `lab`, conforme os [nomes de runtime, secrets e infraestrutura](../infrastructure/infra-runtime-naming.md) e o [Checklist Final de Entrega da Fase 4](phase-4-delivery-checklist.md).

Nenhum access token, JWT, segredo AWS ou conteúdo de Secret Kubernetes foi consultado ou registrado.

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

## Pendência

`[B2-MP-EVID-001]` permanece aberto. Para concluí-lo:

1. substituir `OFICINA_MERCADO_PAGO_ACCESS_TOKEN` por um access token sandbox válido e liberado para a API de pagamentos;
2. reaplicar o workflow `Deploy Lab` para atualizar o Secret Kubernetes e o checksum do Deployment;
3. repetir a cobrança com nova chave de idempotência e novo `correlationId`;
4. registrar a resposta com `provedor=mercado-pago`, `pagamentoId`, `transacaoExternaId`, `external_reference`, consulta na API ou painel sandbox e sinais correspondentes no New Relic.
