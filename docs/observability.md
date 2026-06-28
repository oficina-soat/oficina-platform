# Padrão de Observabilidade Distribuída

## Objetivo

Definir o padrão mínimo de logs, métricas, traces, headers de correlação, dashboards e alertas para os microsserviços da plataforma.

Este documento complementa:

- [Contrato de APIs REST](../contracts/Contrato%20de%20APIs%20REST.md);
- [Contrato de Erros REST](../contracts/error-model.md);
- [Contrato de Idempotência](../contracts/idempotency.md);
- [Contrato de Tópicos de Mensageria](../contracts/Contrato%20de%20Tópicos%20de%20Mensageria.md);
- [Padrão Outbox por Serviço](outbox-pattern.md);
- [Contrato de Saga do oficina-os-service](../contracts/saga/oficina-os-saga-v1.md);
- [Conta, região e ambientes AWS](aws-environments.md);
- [Nomes de runtime, secrets e infraestrutura](infra-runtime-naming.md);
- [Template Quarkus de Microsserviço](../templates/quarkus-service/README.md).

O padrão é obrigatório para:

- `oficina-os-service`;
- `oficina-billing-service`;
- `oficina-execution-service`.

## Decisão

Os microsserviços devem usar observabilidade distribuída baseada em:

- logs estruturados em JSON;
- métricas Prometheus expostas pelo Micrometer;
- traces OpenTelemetry;
- propagação obrigatória de `correlationId` em HTTP, metadados operacionais de eventos, logs e traces;
- atributos padronizados de serviço, namespace e ambiente.

O ambiente canônico da Fase 4 é `lab`, conforme [Conta, região e ambientes AWS](aws-environments.md).

## Configuração de Runtime

Variáveis obrigatórias por microsserviço:

| Variável | Valor esperado |
|---|---|
| `OTEL_SERVICE_NAME` | Nome canônico do serviço, como `oficina-os-service`. |
| `DEPLOYMENT_ENVIRONMENT` | `lab`. |
| `OTEL_RESOURCE_ATTRIBUTES` | `service.namespace=oficina,deployment.environment=lab`. |
| `OFICINA_OBSERVABILITY_ENABLED` | `true`, salvo execução local controlada. |
| `OFICINA_OBSERVABILITY_JSON_LOGS_ENABLED` | Mesmo valor de `OFICINA_OBSERVABILITY_ENABLED`, salvo exceção local. |
| `OFICINA_OBSERVABILITY_METRICS_ENABLED` | Mesmo valor de `OFICINA_OBSERVABILITY_ENABLED`. |
| `OFICINA_OBSERVABILITY_TRACING_ENABLED` | Mesmo valor de `OFICINA_OBSERVABILITY_ENABLED`. |

O [template Quarkus](../templates/quarkus-service/README.md) já define essas chaves em `application.properties` e deve ser a referência inicial para novos repositórios.

## Identificadores Transversais

### Correlation ID

`correlationId` é o identificador primário de troubleshooting da plataforma.

Regras obrigatórias:

- aceitar `X-Correlation-Id` em todas as requisições HTTP;
- gerar um novo `correlationId` quando o header estiver ausente;
- retornar `X-Correlation-Id` nas respostas de erro, conforme [Contrato de Erros REST](../contracts/error-model.md);
- propagar o mesmo valor em chamadas REST entre microsserviços;
- persistir o valor em registros de idempotência;
- persistir o valor em registros de Outbox;
- associar o valor a eventos relacionados à operação por metadados de publicação, registro de Outbox ou contexto operacional do consumidor, sem alterar o envelope v1 dos schemas JSON;
- registrar o valor em todos os logs do fluxo;
- associar o valor ao trace quando a instrumentação estiver habilitada.

### Trace Context

Os serviços devem aceitar e propagar o header W3C:

```text
traceparent
```

Quando houver instrumentação OpenTelemetry ativa, `traceId` e `spanId` devem refletir os identificadores reais do trace distribuído.

`traceId` não substitui `correlationId`. O `correlationId` continua sendo o identificador funcional estável entre HTTP, metadados operacionais de eventos, logs, Outbox e Saga.

## Logs Estruturados

Logs de runtime devem ser emitidos em JSON nos ambientes compartilhados.

Campos mínimos em todos os logs:

| Campo | Regra |
|---|---|
| `timestamp` | Data e hora em ISO-8601 UTC. |
| `level` | Nível do log. |
| `message` | Mensagem curta e segura. |
| `service.name` | Nome canônico do microsserviço. |
| `service.namespace` | `oficina`. |
| `service.version` | Versão da aplicação quando disponível. |
| `deployment.environment` | `lab`. |
| `correlationId` | Obrigatório quando o log estiver ligado a uma requisição, evento ou Saga. |
| `traceId` | Obrigatório quando houver trace ativo. |
| `spanId` | Obrigatório quando houver span ativo. |

Campos mínimos para logs HTTP:

| Campo | Regra |
|---|---|
| `http.method` | Método recebido. |
| `http.path` | Path chamado, incluindo `/api/v1` quando aplicável. |
| `http.status` | Status retornado. |
| `requestId` | Identificador local da requisição no serviço. |
| `durationMs` | Duração da requisição em milissegundos. |
| `subject` | Identificador seguro do usuário ou sistema, quando disponível. |

Campos mínimos para logs de eventos:

| Campo | Regra |
|---|---|
| `eventId` | Identificador único do evento. |
| `eventType` | Nome lógico camelCase. |
| `eventVersion` | Versão do contrato. |
| `topic` | Tópico canônico. |
| `producer` | Serviço produtor. |
| `consumer` | Serviço consumidor, quando aplicável. |
| `aggregateId` | Identificador do agregado. |
| `messageStatus` | Resultado do processamento ou publicação. |

Campos mínimos para logs da Saga:

| Campo | Regra |
|---|---|
| `sagaId` | Identificador da Saga. |
| `ordemServicoId` | Agregado principal. |
| `sagaState` | Estado atual da Saga. |
| `sagaStep` | Etapa executada. |
| `idempotencyKey` | Chave usada no comando, quando aplicável. |

Logs não devem expor:

- JWT;
- secrets;
- dados de cartão;
- stack trace em respostas ao cliente;
- payload completo com dados sensíveis;
- queries SQL com valores sensíveis.

## Métricas

Todos os serviços devem expor métricas em:

```text
/q/metrics
```

O endpoint deve ser consumível por Prometheus ou ferramenta compatível.

Métricas HTTP mínimas:

| Métrica | Tipo | Dimensões |
|---|---|---|
| `http.server.requests.count` | Counter | `service`, `method`, `pathTemplate`, `status` |
| `http.server.requests.duration` | Histogram | `service`, `method`, `pathTemplate`, `status` |
| `http.server.errors.count` | Counter | `service`, `method`, `pathTemplate`, `status`, `errorCode` |

Métricas de eventos mínimas:

| Métrica | Tipo | Dimensões |
|---|---|---|
| `messaging.events.published.count` | Counter | `service`, `eventType`, `topic` |
| `messaging.events.consumed.count` | Counter | `service`, `eventType`, `topic` |
| `messaging.events.failed.count` | Counter | `service`, `eventType`, `topic`, `reason` |
| `messaging.events.processing.duration` | Histogram | `service`, `eventType`, `topic` |
| `messaging.dlq.count` | Counter | `service`, `eventType`, `topic` |

Métricas de Outbox devem seguir o [Padrão Outbox por Serviço](outbox-pattern.md):

| Métrica | Tipo | Dimensões |
|---|---|---|
| `outbox.pending.count` | Gauge | `service`, `eventType` |
| `outbox.published.count` | Counter | `service`, `eventType`, `topic` |
| `outbox.failed.count` | Counter | `service`, `eventType`, `topic` |
| `outbox.publish.latency` | Histogram | `service`, `eventType`, `topic` |
| `outbox.oldest.pending.age` | Gauge | `service` |

Métricas de Saga mínimas para `oficina-os-service`:

| Métrica | Tipo | Dimensões |
|---|---|---|
| `saga.instances.started.count` | Counter | `service`, `sagaType` |
| `saga.instances.completed.count` | Counter | `service`, `sagaType` |
| `saga.instances.compensated.count` | Counter | `service`, `sagaType`, `reason` |
| `saga.instances.failed.count` | Counter | `service`, `sagaType`, `reason` |
| `saga.step.duration` | Histogram | `service`, `sagaType`, `step` |

## Traces

Traces devem cobrir:

- entrada HTTP;
- chamadas REST entre microsserviços;
- publicação pela Outbox;
- consumo de eventos;
- comandos executados pela Saga;
- chamadas a dependências externas, como Mercado Pago, AWS Secrets Manager, DynamoDB e PostgreSQL.

Endpoints operacionais não devem gerar spans de aplicação:

```text
/q/health
/q/health/*
/q/metrics
/q/openapi
/q/swagger-ui
/q/swagger-ui/*
```

Todo span ligado a fluxo de negócio deve conter, quando disponível:

| Atributo | Regra |
|---|---|
| `service.name` | Nome canônico do serviço. |
| `service.namespace` | `oficina`. |
| `deployment.environment` | `lab`. |
| `correlationId` | Identificador transversal do fluxo. |
| `aggregateId` | Identificador do agregado principal. |
| `eventType` | Em spans de mensageria. |
| `topic` | Em spans de mensageria. |
| `sagaId` | Em spans da Saga. |
| `sagaStep` | Em spans da Saga. |

## Health Checks

Todos os serviços devem expor os endpoints padrão do Quarkus:

```text
/q/health
/q/health/live
/q/health/ready
```

Health checks customizados devem existir apenas para dependências operacionais críticas do serviço.

Critérios mínimos:

| Serviço | Dependências de readiness esperadas |
|---|---|
| `oficina-os-service` | PostgreSQL `oficina_os`, broker de mensageria quando configurado. |
| `oficina-billing-service` | PostgreSQL `oficina_billing`, broker de mensageria, dependência financeira quando obrigatória para a operação. |
| `oficina-execution-service` | DynamoDB, broker de mensageria quando configurado. |

## Dashboards Mínimos

Cada serviço deve possuir visão operacional com:

- taxa de requisições por rota;
- latência p50, p95 e p99 por rota;
- erros HTTP por `status` e `error.code`;
- eventos publicados, consumidos e rejeitados;
- backlog e falhas de Outbox;
- eventos em DLQ;
- uso de CPU e memória do pod;
- reinícios de pod;
- status de readiness;
- traces mais lentos por rota e por etapa da Saga.

O `oficina-os-service` deve possuir visão adicional da Saga com:

- Sagas iniciadas;
- Sagas finalizadas com sucesso;
- Sagas compensadas;
- Sagas em falha manual;
- duração por etapa;
- eventos inválidos por estado.

## Alertas Mínimos

Alertas obrigatórios:

| Alerta | Condição |
|---|---|
| Serviço indisponível | Readiness falhando de forma contínua. |
| Erro HTTP elevado | Aumento sustentado de respostas `5xx`. |
| Latência elevada | p95 acima do limite operacional definido para a rota. |
| Outbox parada | `outbox.oldest.pending.age` acima do SLA operacional. |
| Outbox com falha | Qualquer evento marcado como `FAILED`. |
| DLQ recebendo mensagens | Qualquer incremento em `messaging.dlq.count`. |
| Saga em falha manual | Qualquer Saga em `FALHA_MANUAL`. |
| Pagamento indisponível | Falhas recorrentes na dependência financeira. |
| Banco indisponível | Falha contínua de conexão com PostgreSQL ou DynamoDB. |

Limiares numéricos podem variar por ambiente, mas a existência dos alertas é obrigatória.

## Critérios de Implementação

Um microsserviço está aderente a este padrão quando:

- configura `OTEL_SERVICE_NAME` com o próprio nome canônico;
- usa `DEPLOYMENT_ENVIRONMENT=lab`;
- emite logs JSON com `service.name`, `service.namespace`, `deployment.environment` e `correlationId`;
- aceita, gera e propaga `X-Correlation-Id`;
- propaga `traceparent` quando disponível;
- inclui `correlationId` em erros, registros de idempotência, Outbox, metadados operacionais de eventos e logs;
- expõe `/q/metrics`;
- expõe `/q/health`, `/q/health/live` e `/q/health/ready`;
- instrumenta HTTP, mensageria, Outbox e Saga quando aplicável;
- não gera spans para endpoints operacionais suprimidos;
- possui dashboards e alertas mínimos configurados no ambiente compartilhado.
