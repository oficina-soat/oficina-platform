# Dashboards New Relic

Este documento reúne templates JSON para criar manualmente os dashboards mínimos da Fase 4 no New Relic.

Os templates seguem o [Padrão de Observabilidade Distribuída](observability.md), usam o ambiente canônico definido em [Conta, região e ambientes AWS](../infrastructure/aws-environments.md) e dependem do New Relic OpenTelemetry Collector instalado pelo `oficina-infra`, conforme [Nomes de runtime, secrets e infraestrutura](../infrastructure/infra-runtime-naming.md).

## Arquivos

| Dashboard | Arquivo | Objetivo |
|---|---|---|
| Microsserviços Lab | [Dashboard operacional dos microsserviços](new-relic-dashboard-operational.json) | Golden signals, falhas HTTP, logs, traces, CPU, memória, restarts, readiness de Deployments e busca por `correlationId`. |
| Saga e Ordem de Serviço Lab | [Dashboard da Saga e OS](new-relic-dashboard-saga.json) | Fluxo da OS, eventos da Saga, compensações, falha manual, Outbox e correlação por `aggregateId` e `correlationId`. |
| Persistência e Mensageria Lab | [Dashboard de persistência e mensageria](new-relic-dashboard-persistence-messaging.json) | Operações e latência de persistência, backlog e idade da Outbox, publicação e consumo de eventos, SQS, DLQ, retries e conflitos de idempotência. |

## Como Importar

1. Abra o arquivo JSON do dashboard desejado.
2. Substitua todas as ocorrências de `"accountIds": [0]` pelo ID numérico da sua conta New Relic.
3. No New Relic, acesse `Dashboards`.
4. Use `Import dashboard`.
5. Cole o JSON ajustado.
6. Salve o dashboard com a permissão adequada para a entrega.

A documentação oficial do New Relic descreve a [importação pela UI](https://docs.newrelic.com/docs/query-your-data/explore-query-data/dashboards/dashboards-charts-import-export-data/) em `Dashboards > Import dashboard` e a colagem do JSON exportado/importável. A documentação de [widgets via NerdGraph](https://docs.newrelic.com/docs/apis/nerdgraph/examples/create-widgets-dashboards-api/) também mostra `viz.line`, `viz.area`, `viz.bar`, `viz.billboard`, `viz.table` e `viz.markdown` como visualizações suportadas para dashboards.

O campo `variables` do dashboard não centraliza `accountIds`. Variáveis de dashboard são filtros ou placeholders usados nas consultas NRQL; `accountIds` é um campo estrutural de cada widget. Por isso, a própria documentação do New Relic para dashboards JSON orienta substituir `"accountId": 0` ou `"accountIds": [0]` em cada ocorrência do JSON.

Os arquivos já incluem `pages[].guid`, `widgets[].id`, `linkedEntityGuids` e `variables`, pois a UI de importação valida esses campos em alguns fluxos. Esses identificadores são internos ao template JSON; para criar um novo dashboard, mantenha-os e altere apenas o `accountIds`.

Se estiver usando `Manage JSON` dentro de um dashboard já criado, preserve o `guid` real da página existente no New Relic. Esse fluxo atualiza um dashboard existente, enquanto `Import dashboard` cria um dashboard novo a partir do JSON.

## Renderização Local

Para informar o account ID uma única vez e gerar cópias prontas para colar na UI, execute:

```bash
NEW_RELIC_ACCOUNT_ID=1234567

for dashboard in docs/observability/new-relic-dashboard-operational.json docs/observability/new-relic-dashboard-saga.json docs/observability/new-relic-dashboard-persistence-messaging.json; do
  output="/tmp/$(basename "${dashboard}")"
  jq --argjson account_id "${NEW_RELIC_ACCOUNT_ID}" \
    'walk(if type == "object" and has("accountIds") then .accountIds = [$account_id] else . end)' \
    "${dashboard}" > "${output}"
  printf 'Gerado: %s\n' "${output}"
done
```

Depois abra o arquivo gerado em `/tmp` e cole o JSON no `Import dashboard`.

## Filtros Canônicos

Painéis de `Span`, `Log` e métricas Prometheus dos microsserviços usam os filtros:

```nrql
service.namespace = 'oficina'
deployment.environment = 'lab'
service.name IN ('oficina-os-service', 'oficina-billing-service', 'oficina-execution-service')
```

Painéis de métricas Kubernetes usam `k8s.cluster.name = 'eks-lab'`, `k8s.namespace.name = 'default'` e, quando possível, `k8s.deployment.name` para reduzir ruído de ReplicaSets antigos, conforme o formato enviado pelo New Relic OpenTelemetry Collector.

Os sinais esperados são:

- `Span` para throughput, latência, status HTTP e traces lentos;
- `Log` para mensagens estruturadas, `correlationId`, erros, eventos e Saga;
- `Metric` para métricas Kubernetes enviadas pelo New Relic OpenTelemetry Collector e para métricas Prometheus raspadas de `/q/metrics` nos microsserviços.

Falhas HTTP esperadas, como validações `400` e conflitos de negócio `409`, são registradas hoje como logs estruturados de requisição com `level=INFO` e `http.status >= 400`. Por isso, os widgets de falhas operacionais usam `Log` com `numeric(http.status) >= 400`, enquanto widgets de erro real em `Span` continuam focados em spans marcados como erro ou status `5xx`.

Os widgets de CPU e memória usam as métricas confirmadas na conta New Relic `8254132`: `container.cpu.usage`, `k8s.pod.cpu_limit_utilization`, `container.memory.usage` e `k8s.pod.memory_limit_utilization`. O readiness usa `kube_deployment_status_replicas_ready`, `kube_deployment_status_replicas_available` e `kube_deployment_spec_replicas`.

## Evidência Remota

Em 2026-07-11, os dashboards existentes na conta New Relic `8254132` foram atualizados via NerdGraph e revalidados por NRQL:

| Dashboard | GUID | Página | Resultado |
|---|---|---|---|
| Microsserviços Lab | `ODI1NDEzMnxWSVp8REFTSEJPQVJEfGRhOjEyODcwMzQ1` | `Operacional` | 15 widgets salvos; falhas HTTP, logs, métricas Prometheus, CPU, memória, restarts e readiness retornando dados. |
| Saga e Ordem de Serviço Lab | `ODI1NDEzMnxWSVp8REFTSEJPQVJEfGRhOjEyODcwMzQ2` | `Saga OS` | 14 widgets salvos; eventos, Outbox, `aggregateId`, `correlationId`, traces lentos e falhas relacionadas retornando dados. |
| Persistência e Mensageria Lab | `ODI1NDEzMnxWSVp8REFTSEJPQVJEfGRhOjEyODgzNTkw` | `Dependencias` | 10 widgets criados em 2026-07-14; consultas de persistência, Outbox, mensageria, DLQ e idempotência validadas via NerdGraph com dados reais e sem erros NRQL. |

As métricas `payment_provider_*` ainda não aparecem no inventário `Metric` da conta, embora estejam implementadas no `oficina-billing-service`. O dashboard específico do Mercado Pago deve ser criado somente depois de corrigir e comprovar a emissão ou coleta dessas séries. A visão completa de duração por etapa da Saga também depende da emissão das métricas `saga.instances.*` e `saga.step.duration` pelo `oficina-os-service`.

O widget `Traces com erro` do dashboard operacional pode retornar zero linhas quando não houver spans com `error IS true`, `otel.status_code = 'ERROR'` ou status HTTP `5xx`. Esse resultado não indica falha de coleta: validações `400` e conflitos de negócio `409` aparecem nos widgets de falhas HTTP baseados em `Log`.

## Ajustes Esperados

Alguns atributos podem variar conforme o mapeamento do collector ou a versão de semântica OpenTelemetry usada pelo New Relic:

| Uso | Atributo principal | Alternativa comum |
|---|---|---|
| Status HTTP | `http.response.status_code` | `http.status_code` |
| Rota HTTP | `http.route` | `http.target` ou `name` |
| Tipo de span | `span.kind = 'server'` | `span.kind = 'SERVER'` |
| Identificador de trace em logs | `traceId` | `trace.id` |
| Readiness Kubernetes | `kube_deployment_status_replicas_ready` | `kube_pod_status_ready` |
| CPU Kubernetes | `container.cpu.usage` | `k8s.pod.cpu_limit_utilization` |
| Memória Kubernetes | `container.memory.usage` | `k8s.pod.memory_limit_utilization` |

Se um painel ficar sem dados, valide primeiro a presença dos atributos com consultas exploratórias como:

```nrql
FROM Span SELECT keyset() WHERE service.namespace = 'oficina' SINCE 30 minutes ago
```

```nrql
FROM Log SELECT keyset() WHERE service.namespace = 'oficina' SINCE 30 minutes ago
```

```nrql
FROM Metric SELECT keyset() WHERE k8s.cluster.name = 'eks-lab' SINCE 30 minutes ago
```

```nrql
FROM Metric SELECT keyset() WHERE service.namespace = 'oficina' SINCE 30 minutes ago
```

## Campos da Saga

O dashboard de Saga usa os atributos confirmados em logs estruturados de Outbox: `domainEventType`, `event.type`, `aggregateId`, `producer`, `topic`, `messageStatus`, `correlationId`, `traceId` e `spanId`. O campo canônico emitido pelos microsserviços continua sendo `eventType`; no New Relic, use `domainEventType` ou `event.type`, porque `eventType` é reservado pela ingestão e pode não aparecer como atributo consultável.

Campos específicos de uma futura instrumentação interna da Saga, como `sagaId`, `saga.etapa`, `saga.estado`, `saga.duracaoMs` e `ordemServicoId`, ainda não são emitidos como atributos estruturados. Quando eles forem adicionados aos logs dos serviços, novos widgets podem ser criados sem substituir os painéis atuais baseados em `aggregateId` e `domainEventType`.
