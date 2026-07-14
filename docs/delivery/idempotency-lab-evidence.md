# Evidência de Idempotência Persistente no Lab

## Escopo

Este documento registra a validação remota de `[B2-IDEMP-REM-001]` no ambiente `lab`, conforme o [Contrato de Idempotência](../../contracts/idempotency.md) e o [Checklist Final de Entrega da Fase 4](phase-4-delivery-checklist.md).

Foram exercitadas operações `POST` reais dos três microsserviços com uma chave `X-Idempotency-Key` exclusiva por serviço. Para cada operação, a mesma requisição foi repetida, a chave foi reutilizada com payload divergente e ambas as verificações foram refeitas depois da substituição controlada dos pods.

## Ambiente validado

Os três Deployments estavam saudáveis com uma réplica pronta:

| Serviço | Imagem |
|---|---|
| `oficina-os-service` | `oficina-os-service:1.2.3` |
| `oficina-billing-service` | `oficina-billing-service:1.1.2` |
| `oficina-execution-service` | `oficina-execution-service:1.0.16` |

As chamadas foram feitas pelos Services Kubernetes por port-forwards temporários e autenticadas por JWT emitido pela Auth Lambda do `lab`. Nenhum token, senha ou conteúdo de Secret foi registrado.

## Resultado antes do restart

| Serviço | Operação sentinela | Primeira resposta | Replay idêntico | Payload divergente |
|---|---|---:|---:|---:|
| OS | `POST /api/v1/clientes` | `201`, `clienteId=2ad6104d-4254-4abe-9fac-53d086d0f320` | `201`, mesmo `clienteId` e mesmo corpo | `409`, `IDEMPOTENCY_CONFLICT` |
| Billing | `POST /api/v1/orcamentos` | `201`, `orcamentoId=5f5bbfc7-70a6-496b-9c7a-bfb7bd0ca6bb` | `201`, mesmo `orcamentoId` e mesmo corpo | `409`, `IDEMPOTENCY_CONFLICT` |
| Execution | `POST /api/v1/servicos` | `201`, `servicoId=58bb6f35-c142-4554-a9d7-ba1bb8c7f99b` | `201`, mesmo `servicoId` e mesmo corpo | `409`, `IDEMPOTENCY_CONFLICT` |

As chaves usadas foram:

- `b2-idemp-rem-001-20260714101504-os`;
- `b2-idemp-rem-001-20260714101523-billing`;
- `b2-idemp-rem-001-20260714101541-execution`.

Nos três conflitos, a mensagem retornada foi `Chave de idempotencia reutilizada com payload divergente.`.

## Persistência após restart

Os três Deployments receberam um `rollout restart` simultâneo. Os pods anteriores foram substituídos por:

| Serviço | Novo pod | Início UTC |
|---|---|---|
| OS | `oficina-os-service-8ff95454f-fr6r6` | `2026-07-14T10:16:30Z` |
| Billing | `oficina-billing-service-7cc68b458b-pbhr2` | `2026-07-14T10:16:30Z` |
| Execution | `oficina-execution-service-58f96f48b7-p7vln` | `2026-07-14T10:16:30Z` |

Depois dos três rollouts concluírem e os novos pods ficarem prontos:

- o replay no OS retornou HTTP `201` e o mesmo `clienteId`;
- o replay no Billing retornou HTTP `201` e o mesmo `orcamentoId`;
- o replay no Execution retornou HTTP `201` e o mesmo `servicoId`;
- o payload divergente continuou retornando HTTP `409` com `IDEMPOTENCY_CONFLICT` nos três serviços.

Os identificadores preservados comprovam que a resposta foi recuperada dos registros persistentes de idempotência, sem executar novamente o efeito colateral. A preservação do conflito depois da troca dos processos também comprova que o vínculo entre chave, escopo e hash do payload não dependia da memória do pod.

Nenhum ajuste de Terraform, IAM, EKS ou outro recurso AWS foi necessário durante a validação. Com replay estável, rejeição de payload divergente e preservação após restart comprovados nos três microsserviços, `[B2-IDEMP-REM-001]` está concluído.
