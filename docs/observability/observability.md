# Padrão de Observabilidade Distribuída

## Objetivo

Definir o padrão mínimo de logs, métricas, traces, headers de correlação, dashboards e alertas para os microsserviços da plataforma.

Este documento complementa:

- [Contrato de APIs REST](../../contracts/Contrato%20de%20APIs%20REST.md);
- [Contrato de Erros REST](../../contracts/error-model.md);
- [Contrato de Idempotência](../../contracts/idempotency.md);
- [Contrato de Tópicos de Mensageria](../../contracts/Contrato%20de%20Tópicos%20de%20Mensageria.md);
- [Padrão Outbox por Serviço](../architecture/outbox-pattern.md);
- [Contrato de Saga do oficina-os-service](../../contracts/saga/oficina-os-saga-v1.md);
- [Conta, região e ambientes AWS](../infrastructure/aws-environments.md);
- [Nomes de runtime, secrets e infraestrutura](../infrastructure/infra-runtime-naming.md);
- [Runbooks Operacionais Mínimos](operational-runbooks.md);
- [Template Quarkus de Microsserviço](../../templates/quarkus-service/README.md).

O padrão é obrigatório para:

- `oficina-os-service`;
- `oficina-billing-service`;
- `oficina-execution-service`.

## Decisão

Os microsserviços devem usar observabilidade distribuída baseada em:

- logs estruturados em JSON;
- métricas Prometheus expostas pelo Micrometer;
- traces OpenTelemetry;
- New Relic como backend canônico para dashboards, alertas, logs, métricas e traces no ambiente compartilhado;
- New Relic OpenTelemetry Collector instalado no cluster EKS por Helm como coletor oficial do ambiente `lab`;
- propagação obrigatória de `correlationId` em HTTP, metadados operacionais de eventos, logs e traces;
- atributos padronizados de serviço, namespace e ambiente.

O ambiente canônico da Fase 4 é `lab`, conforme [Conta, região e ambientes AWS](../infrastructure/aws-environments.md).

AWS continua sendo a plataforma de nuvem da solução. A coleta dos sinais operacionais deve ser feita pelo New Relic OpenTelemetry Collector instalado no cluster EKS `eks-lab` por Helm, com OTLP/gRPC habilitado para traces, coleta de logs dos pods e coleta das métricas expostas em `/q/metrics`.

O collector roda dentro do cluster, mas o backend, os dashboards, os alertas e a interface de consulta pertencem ao New Relic. Portanto, a operacionalização exige uma conta New Relic, uma license key configurada como secret no ambiente `lab` e o endpoint OTLP do New Relic aplicável à região da conta.

Referências operacionais oficiais:

- [Install OpenTelemetry Collector on Kubernetes](https://docs.newrelic.com/docs/kubernetes-pixie/k8s-otel/install/);
- [New Relic OTLP endpoint](https://docs.newrelic.com/docs/opentelemetry/best-practices/opentelemetry-otlp/);
- [OpenTelemetry data in New Relic](https://docs.newrelic.com/docs/opentelemetry/best-practices/opentelemetry-data-overview/).

## Configuração de Runtime

Variáveis obrigatórias por microsserviço:

| Variável | Valor esperado |
|---|---|
| `OTEL_SERVICE_NAME` | Nome canônico do serviço, como `oficina-os-service`. |
| `DEPLOYMENT_ENVIRONMENT` | `lab`. |
| `OTEL_RESOURCE_ATTRIBUTES` | `service.namespace=oficina,deployment.environment=lab`. |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | `http://nr-k8s-otel-collector-gateway.newrelic.svc.cluster.local:4317`, salvo alteração coordenada de `NEW_RELIC_NAMESPACE` ou `NEW_RELIC_OTEL_COLLECTOR_LOCAL_SERVICE_NAME` no `oficina-infra`. |
| `OTEL_EXPORTER_OTLP_PROTOCOL` | `grpc`. |
| `OTEL_METRICS_EXPORTER` | `none`; métricas de aplicação são expostas em `/q/metrics` para coleta compatível com Prometheus. |
| `OTEL_LOGS_EXPORTER` | `none`; logs são emitidos em JSON no stdout para coleta pelo agente. |
| `OFICINA_OBSERVABILITY_ENABLED` | `true`, salvo execução local controlada. |
| `OFICINA_OBSERVABILITY_JSON_LOGS_ENABLED` | Mesmo valor de `OFICINA_OBSERVABILITY_ENABLED`, salvo exceção local. |
| `OFICINA_OBSERVABILITY_METRICS_ENABLED` | Mesmo valor de `OFICINA_OBSERVABILITY_ENABLED`. |
| `OFICINA_OBSERVABILITY_TRACING_ENABLED` | Mesmo valor de `OFICINA_OBSERVABILITY_ENABLED`. |

O exportador de traces do Quarkus deve ficar fixado em `quarkus.otel.traces.exporter=cdi` no build dos microsserviços, usando o exportador OTLP gerenciado pelo Quarkus. Não use `QUARKUS_OTEL_TRACES_EXPORTER=none` para desabilitar tracing em runtime, pois essa chave é build-time; para execução local ou testes, desabilite por `OFICINA_OBSERVABILITY_TRACING_ENABLED=false` ou por perfil `%test.quarkus.otel.traces.enabled=false`.

O [template Quarkus](../../templates/quarkus-service/README.md) já define essas chaves em `application.properties` e deve ser a referência inicial para novos repositórios.

O endpoint OTLP interno, a instalação do New Relic OpenTelemetry Collector via Helm, a license key e qualquer secret necessário pertencem ao repositório de infraestrutura. A configuração executável fica em [New Relic OpenTelemetry Collector no EKS lab](../../../oficina-infra/docs/new-relic-otel-collector.md). Este repositório define apenas o contrato de runtime esperado pelos microsserviços e pelos manifests base.

Variáveis operacionais do collector no ambiente `lab`:

| Variável | Valor esperado |
|---|---|
| `INSTALL_NEW_RELIC_OTEL_COLLECTOR` | `auto` por padrão; instala ou atualiza o collector quando `NEW_RELIC_LICENSE_KEY` está disponível. Use `false` para desabilitar explicitamente ou `true` para exigir a instalação. |
| `NEW_RELIC_LICENSE_KEY` | Secret externo ao repositório, informado como secret do repositório/organização ou localmente. |
| `NEW_RELIC_NAMESPACE` | `newrelic`. |
| `NEW_RELIC_OTEL_COLLECTOR_HELM_RELEASE` | `nr-k8s-otel-collector`. |
| `NEW_RELIC_OTEL_COLLECTOR_LOCAL_SERVICE_NAME` | `nr-k8s-otel-collector-gateway`. |
| `NEW_RELIC_LICENSE_KEY_SECRET_NAME` | `new-relic-license-key`. |
| `NEW_RELIC_LICENSE_KEY_SECRET_KEY` | `licenseKey`. |
| `NEW_RELIC_CLUSTER_NAME` | `eks-lab`. |
| `NEW_RELIC_REGION` | `US`, salvo conta New Relic em outra região. |
| `NEW_RELIC_OTLP_ENDPOINT` | `https://otlp.nr-data.net`, salvo conta New Relic em outra região. |

## Identificadores Transversais

### Correlation ID

`correlationId` é o identificador primário de troubleshooting da plataforma.

Regras obrigatórias:

- aceitar `X-Correlation-Id` em todas as requisições HTTP;
- gerar um novo `correlationId` quando o header estiver ausente;
- retornar `X-Correlation-Id` nas respostas de erro, conforme [Contrato de Erros REST](../../contracts/error-model.md);
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
| `domainEventType` | Cópia de `eventType` para consultas NRQL quando o backend reservar ou normalizar o nome `eventType`. |
| `event.type` | Alias compatível com semântica OpenTelemetry para o tipo lógico do evento. |
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

Métricas de Outbox devem seguir o [Padrão Outbox por Serviço](../architecture/outbox-pattern.md):

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

Métricas de provedor financeiro mínimas para `oficina-billing-service`:

| Métrica | Tipo | Dimensões |
|---|---|---|
| `payment.provider.enabled` | Gauge | `service`, `provider`, `environment` |
| `payment.provider.requests.count` | Counter | `service`, `provider`, `method`, `outcome`, `providerStatus` |
| `payment.provider.request.duration` | Histogram | `service`, `provider`, `method`, `outcome` |
| `payment.provider.amount` | Distribution | `service`, `provider`, `method`, `outcome`, `currency` |
| `payment.provider.failures.count` | Counter | `service`, `provider`, `method`, `reason` |
| `payment.provider.unavailable.count` | Counter | `service`, `provider`, `reason` |

Para Mercado Pago, `provider` deve ser `mercado-pago` e `method` deve refletir o método local de pagamento, como `PIX`. `outcome` deve usar valores de baixa cardinalidade, como `confirmed`, `rejected`, `pending`, `failure` ou `not_integrated`. `providerStatus` deve refletir apenas os status de negócio retornados pelo provedor, como `approved`, `rejected`, `cancelled`, `refunded`, `charged_back`, `pending` ou `in_process`.

As métricas de provedor financeiro não devem usar `pagamentoId`, `ordemServicoId`, `transacaoExternaId`, CPF, e-mail, `correlationId` ou qualquer identificador de alta cardinalidade como dimensão. Esses identificadores pertencem a logs e traces.

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

## New Relic

Os painéis de observabilidade da plataforma devem ser criados no New Relic.

Para o ambiente `lab`, a forma oficial de coleta é New Relic OpenTelemetry Collector no cluster EKS instalado por Helm. Os microsserviços enviam traces para o endpoint OTLP interno do collector; logs e métricas são coletados dentro do cluster e encaminhados ao New Relic pelo collector configurado no `oficina-infra`.

Os templates JSON para criação manual dos painéis ficam em [Dashboards New Relic](new-relic-dashboards.md).

Regras obrigatórias:

- todos os dashboards devem filtrar por `service.name`, `service.namespace` e `deployment.environment`;
- `service.namespace` deve ser `oficina`;
- `deployment.environment` deve ser `lab` no ambiente da Fase 4;
- traces devem chegar ao New Relic por OTLP recebido pelo New Relic OpenTelemetry Collector, usando o exportador gerenciado pelo Quarkus;
- logs JSON devem ser coletados do stdout dos pods e correlacionados com `service.name`, `correlationId`, `traceId` e `spanId` quando disponíveis;
- métricas expostas em `/q/metrics` devem ser coletadas pelo New Relic OpenTelemetry Collector com configuração compatível com Prometheus;
- alertas devem referenciar dashboards e políticas de alerta do New Relic, sem depender de painéis operacionais no Amazon CloudWatch como visão principal.

O Amazon CloudWatch pode continuar recebendo logs ou métricas nativas da AWS quando isso for consequência da plataforma, mas não é o backend canônico para os painéis de observabilidade dos microsserviços.

## Dashboards Mínimos

Cada serviço deve possuir visão operacional no New Relic com:

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

O `oficina-billing-service` deve possuir visão adicional de consumo Mercado Pago quando a integração estiver habilitada:

- chamadas ao provedor por método e desfecho;
- taxa de sucesso, recusa, pendência e falha;
- latência p95 e p99 da chamada externa;
- valor financeiro total por desfecho;
- indisponibilidade por motivo;
- logs e traces correlacionáveis por `correlationId` para a mesma cobrança sandbox.

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

A triagem e a contenção inicial desses alertas devem seguir os [Runbooks Operacionais Mínimos](operational-runbooks.md).

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
