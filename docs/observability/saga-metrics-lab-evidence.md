# Evidência das Métricas e do Dashboard da Saga no Lab

## Objetivo

Registrar a conclusão de `[D-NR-REM-003]`, comprovando a ingestão das métricas implementadas em `[D-OBS-SAGA-IMPL-001]` e a atualização da visão adicional da Saga no New Relic.

## Cenário sentinela

Em 2026-07-15, com o `oficina-os-service:1.3.0` saudável no ambiente `lab`, foi executado um fluxo real e curto pelas APIs públicas:

1. criação de cliente;
2. criação de veículo;
3. abertura de Ordem de Serviço;
4. cancelamento controlado da Ordem de Serviço.

| Artefato | Valor |
|---|---|
| `correlationId` | `d-nr-rem-003-20260715T121213Z` |
| Cliente | `76b4dd57-816f-4dcc-b05c-e6971fd546dc` |
| Veículo | `530b6992-051a-4c3d-93f6-6ed0ccdf4799` |
| Ordem de Serviço | `844863c1-cfb0-4f34-bef4-39fecd20af57` |
| Saga | `48c63d27-010f-4149-bd94-fd78790f3527` |

As três criações retornaram HTTP `201`, e o cancelamento retornou HTTP `202`.

## Sinais no serviço

O endpoint `/q/metrics`, consultado de dentro do cluster por um pod temporário removido automaticamente, confirmou:

| Série | Resultado |
|---|---|
| `saga_instances_started_count_total` | `1`, `sagaType=ordemServico` |
| `saga_instances_compensated_count_total` | `1`, `reason=operational_failure` |
| `saga_step_duration_seconds` | etapas `ordemDeServicoCriada` e `sagaCompensada`; compensação em `0.682166s` |

Os logs estruturados da transição registraram `sagaId`, `sagaStep`, `sagaState`, `previousSagaState`, `reason`, `ordemServicoId`, `correlationId`, `traceId` e `spanId`. A transição final ficou em `COMPENSADA`, etapa `sagaCompensada`, com motivo categórico `operational_failure`.

## Dashboard New Relic

O dashboard remoto foi atualizado via NerdGraph:

| Campo | Valor |
|---|---|
| Nome | `Oficina SOAT - Saga e Ordem de Servico Lab` |
| GUID | `ODI1NDEzMnxWSVp8REFTSEJPQVJEfGRhOjEyODcwMzcz` |
| Página | `Saga OS` |
| Widgets | `14` |

Os cinco widgets principais passaram a usar as métricas canônicas:

- Sagas iniciadas: `saga_instances_started_count_total`;
- Sagas finalizadas: `saga_instances_completed_count_total`;
- Sagas compensadas: `saga_instances_compensated_count_total`, por `reason`;
- Falha manual: `saga_instances_failed_count_total`, por `reason`;
- Duração da Saga por etapa p95: `saga_step_duration_seconds`, por `step`.

Todos os `13` widgets com NRQL foram executados via NerdGraph sem erro. Os painéis de início, compensação e duração retornaram os sinais da execução sentinela. Os painéis de conclusão e falha manual foram validados sintaticamente e permanecem preparados para ocorrências reais; nenhuma falha manual foi fabricada para a homologação.

Uma releitura da entidade após a mutation confirmou o mesmo GUID, a página `Saga OS`, os `14` widgets e as cinco consultas iniciando com `FROM Metric`. O template canônico permanece em [Dashboard da Saga e OS](new-relic-dashboard-saga.json), e o inventário consolidado está em [Dashboards New Relic](new-relic-dashboards.md).
