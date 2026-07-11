# Dashboards New Relic

Este documento reúne templates JSON para criar manualmente os dashboards mínimos da Fase 4 no New Relic.

Os templates seguem o [Padrão de Observabilidade Distribuída](observability.md), usam o ambiente canônico definido em [Conta, região e ambientes AWS](aws-environments.md) e dependem do New Relic OpenTelemetry Collector instalado pelo `oficina-infra`, conforme [Nomes de runtime, secrets e infraestrutura](infra-runtime-naming.md).

## Arquivos

| Dashboard | Arquivo | Objetivo |
|---|---|---|
| Microsserviços Lab | [Dashboard operacional dos microsserviços](new-relic-dashboard-operational.json) | Golden signals, logs, traces, pods, CPU, memória, restarts e busca por `correlationId`. |
| Saga e Ordem de Serviço Lab | [Dashboard da Saga e OS](new-relic-dashboard-saga.json) | Fluxo da OS, eventos da Saga, compensações, falha manual, Outbox e correlação por `ordemServicoId` e `correlationId`. |

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

for dashboard in docs/new-relic-dashboard-operational.json docs/new-relic-dashboard-saga.json; do
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

Painéis de métricas Kubernetes usam `k8s.cluster.name = 'eks-lab'` e `k8s.namespace.name = 'default'`, conforme o formato enviado pelo New Relic OpenTelemetry Collector.

Os sinais esperados são:

- `Span` para throughput, latência, erro e traces lentos;
- `Log` para mensagens estruturadas, `correlationId`, erros, eventos e Saga;
- `Metric` para métricas Kubernetes enviadas pelo New Relic OpenTelemetry Collector e para métricas Prometheus raspadas de `/q/metrics` nos microsserviços.

## Ajustes Esperados

Alguns atributos podem variar conforme o mapeamento do collector ou a versão de semântica OpenTelemetry usada pelo New Relic:

| Uso | Atributo principal | Alternativa comum |
|---|---|---|
| Status HTTP | `http.response.status_code` | `http.status_code` |
| Rota HTTP | `http.route` | `http.target` ou `name` |
| Tipo de span | `span.kind = 'server'` | `span.kind = 'SERVER'` |
| Identificador de trace em logs | `traceId` | `trace.id` |

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

## Limite Atual da Saga

O dashboard de Saga já contém consultas para `domainEventType`, `eventType`, `ordemServicoId`, `sagaId`, `saga.etapa`, `saga.estado`, `saga.duracaoMs` e `outbox.status`. O campo canônico emitido pelos microsserviços continua sendo `eventType`; no New Relic, use `domainEventType` quando `eventType` não aparecer como atributo consultável após a ingestão. Esses campos precisam chegar como atributos estruturados nos logs para que todos os widgets fiquem completos.

Enquanto os serviços ainda não emitirem todos esses atributos como logs estruturados, use os painéis baseados em `Span`, `message`, `correlationId` e `traceId` como visão inicial. Ao evoluir os logs de Outbox e Saga, preserve os nomes acima para manter compatibilidade com os dashboards.
