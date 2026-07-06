# Rotas públicas do API Gateway

## Objetivo

Definir quais rotas REST da Fase 4 devem ser expostas pelo API Gateway público da suíte e quais endpoints operacionais não devem ser publicados como API de negócio.

Este documento complementa o [Contrato de APIs REST](../contracts/Contrato%20de%20APIs%20REST.md), as especificações OpenAPI em [contracts/openapi/](../contracts/openapi/), a [Estratégia de entrega dos manifestos Kubernetes](kubernetes-manifest-strategy.md), o [Escopo do Repositório Unificado de Infraestrutura](infrastructure-repository-scope.md) e os nomes canônicos de [Conta, região e ambientes AWS](aws-environments.md).

## Decisão

Todas as rotas REST de negócio documentadas nas OpenAPI dos três microsserviços devem ser expostas publicamente pelo API Gateway HTTP `eks-lab-http-api`.

Neste contexto, "pública" significa roteável pela entrada pública da plataforma. A regra não remove os contratos de autenticação, autorização, erro padronizado, idempotência e `correlationId` definidos pelo [Contrato de APIs REST](../contracts/Contrato%20de%20APIs%20REST.md), pelo [Contrato de Erros REST](../contracts/error-model.md) e pelo [Contrato de Idempotência](../contracts/idempotency.md).

Não foram identificadas, nas OpenAPI canônicas, rotas administrativas, callbacks internos, webhooks internos ou endpoints de banco/mensageria que devam ficar privados dentro do conjunto de APIs de negócio. A exposição pública deve ser limitada às rotas listadas neste documento.

## Rotas públicas por serviço

### `oficina-os-service`

Fonte canônica: [OpenAPI do oficina-os-service](../contracts/openapi/oficina-os-service.yaml).

| Método | Rota pública |
|---|---|
| `POST` | `/api/v1/clientes` |
| `GET` | `/api/v1/clientes` |
| `GET` | `/api/v1/clientes/{clienteId}` |
| `PUT` | `/api/v1/clientes/{clienteId}` |
| `POST` | `/api/v1/clientes/{clienteId}/veiculos` |
| `GET` | `/api/v1/clientes/{clienteId}/veiculos` |
| `GET` | `/api/v1/veiculos/{veiculoId}` |
| `PUT` | `/api/v1/veiculos/{veiculoId}` |
| `POST` | `/api/v1/ordens-servico` |
| `GET` | `/api/v1/ordens-servico` |
| `GET` | `/api/v1/ordens-servico/{ordemServicoId}` |
| `GET` | `/api/v1/ordens-servico/{ordemServicoId}/historico` |
| `PATCH` | `/api/v1/ordens-servico/{ordemServicoId}/estado` |
| `POST` | `/api/v1/ordens-servico/{ordemServicoId}/cancelamento` |

### `oficina-billing-service`

Fonte canônica: [OpenAPI do oficina-billing-service](../contracts/openapi/oficina-billing-service.yaml).

| Método | Rota pública |
|---|---|
| `POST` | `/api/v1/orcamentos` |
| `GET` | `/api/v1/orcamentos/{orcamentoId}` |
| `GET` | `/api/v1/ordens-servico/{ordemServicoId}/orcamentos` |
| `POST` | `/api/v1/orcamentos/{orcamentoId}/aprovacao` |
| `POST` | `/api/v1/orcamentos/{orcamentoId}/recusa` |
| `POST` | `/api/v1/pagamentos` |
| `GET` | `/api/v1/pagamentos/{pagamentoId}` |
| `GET` | `/api/v1/ordens-servico/{ordemServicoId}/pagamentos` |
| `POST` | `/api/v1/pagamentos/{pagamentoId}/confirmacao` |
| `POST` | `/api/v1/pagamentos/{pagamentoId}/recusa` |
| `POST` | `/api/v1/pagamentos/{pagamentoId}/cancelamento` |

### `oficina-execution-service`

Fonte canônica: [OpenAPI do oficina-execution-service](../contracts/openapi/oficina-execution-service.yaml).

| Método | Rota pública |
|---|---|
| `POST` | `/api/v1/servicos` |
| `GET` | `/api/v1/servicos` |
| `GET` | `/api/v1/servicos/{servicoId}` |
| `PUT` | `/api/v1/servicos/{servicoId}` |
| `POST` | `/api/v1/pecas` |
| `GET` | `/api/v1/pecas` |
| `GET` | `/api/v1/pecas/{pecaId}` |
| `PUT` | `/api/v1/pecas/{pecaId}` |
| `GET` | `/api/v1/estoques/pecas/{pecaId}/saldo` |
| `GET` | `/api/v1/estoques/movimentos` |
| `POST` | `/api/v1/estoques/movimentos/entrada` |
| `POST` | `/api/v1/estoques/movimentos/reserva` |
| `POST` | `/api/v1/estoques/movimentos/consumo` |
| `POST` | `/api/v1/estoques/movimentos/estorno` |
| `POST` | `/api/v1/execucoes` |
| `GET` | `/api/v1/execucoes` |
| `GET` | `/api/v1/execucoes/fila` |
| `GET` | `/api/v1/execucoes/{execucaoId}` |
| `GET` | `/api/v1/ordens-servico/{ordemServicoId}/execucao` |
| `POST` | `/api/v1/execucoes/{execucaoId}/diagnostico/inicio` |
| `POST` | `/api/v1/execucoes/{execucaoId}/diagnostico/conclusao` |
| `POST` | `/api/v1/execucoes/{execucaoId}/reparo/inicio` |
| `POST` | `/api/v1/execucoes/{execucaoId}/reparo/conclusao` |
| `POST` | `/api/v1/execucoes/{execucaoId}/cancelamento` |

## Endpoints que não devem ser rotas públicas de negócio

Os endpoints abaixo não fazem parte da superfície pública de negócio do API Gateway:

- `/api/v1/status` dos microsserviços, por existir com o mesmo path nos três serviços e servir apenas a smoke test local ou operacional;
- `/q/health`, `/q/health/live` e `/q/health/ready`, que pertencem a probes Kubernetes e readiness interna;
- `/q/metrics`, que deve ser coletado pelo New Relic OpenTelemetry Collector dentro do cluster;
- `/q/openapi`, `/q/swagger-ui` e `/q/swagger-ui/*`, que podem ser usados como evidência técnica, mas não devem substituir os links canônicos das OpenAPI em [contracts/openapi/](../contracts/openapi/);
- endpoints diretos de pods, Services Kubernetes, bancos, filas, tópicos, collectors ou consoles administrativos.

Se a demonstração precisar expor Swagger ou status publicamente, isso deve ser registrado como exceção temporária no `oficina-infra` e não como contrato permanente da API de negócio.

## Regras para materialização no `oficina-infra`

O `oficina-infra` deve materializar as rotas públicas com integrações HTTP para os backends dos microsserviços quando os endpoints internos estiverem publicados.

Regras obrigatórias:

- não usar rota catch-all única como `ANY /api/v1/{proxy+}` para todos os serviços, porque os três microsserviços compartilham o prefixo `/api/v1`;
- criar rotas específicas por método e path, preservando o serviço destino definido neste documento;
- manter `oficina-infra` como fonte canônica das rotas executáveis do API Gateway;
- manter as OpenAPI em [contracts/openapi/](../contracts/openapi/) como fonte canônica da semântica de request e response;
- usar authorizer JWT do API Gateway quando a autenticação for validada na entrada pública;
- preservar validação JWT no microsserviço conforme as OpenAPI, mesmo quando o API Gateway também validar o token;
- não publicar endpoints de observabilidade, banco, mensageria ou administração como rotas públicas de negócio.

Como as rotas são públicas por path e método, o roteamento para `oficina-billing-service` e `oficina-execution-service` nas rotas derivadas de `/api/v1/ordens-servico/{ordemServicoId}/...` deve ser explícito. Essas rotas não pertencem ao `oficina-os-service` apenas por compartilharem o prefixo de Ordem de Serviço.

## Critério de pronto

O item de rotas públicas está definido quando:

- este documento lista todas as rotas das OpenAPI canônicas;
- o [ROADMAP](../ROADMAP.md) aponta para esta decisão;
- o `oficina-infra` materializa as rotas no API Gateway usando os backends reais do ambiente `lab`;
- o [Checklist Final de Entrega da Fase 4](phase-4-delivery-checklist.md) registra a URL pública e a evidência de chamada das rotas relevantes para a demonstração.
