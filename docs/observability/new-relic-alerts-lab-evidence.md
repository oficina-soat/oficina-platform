# Evidência dos Alertas Mínimos no New Relic

## Resultado

Em 2026-07-15, a policy `Oficina SOAT - Alertas Minimos Lab` foi criada na conta New Relic `8254132` com ID `7756164` e preferência de incidente `PER_CONDITION_AND_TARGET`.

As nove condições NRQL foram validadas antes da criação e relidas após a mutation:

| Condição | ID | Prioridade | Critério principal |
|---|---:|---|---|
| Serviço indisponível | `63810235` | Crítica | readiness abaixo de uma réplica ou ausência do sinal por 5 minutos |
| Erro HTTP elevado | `63810236` | Crítica | mais de 5 respostas `5xx` em 5 minutos |
| Latência HTTP p95 elevada | `63810237` | Warning | p95 acima de `2000ms` por 5 minutos |
| Outbox parada | `63810239` | Crítica | evento mais antigo acima de `300s` por 5 minutos |
| Outbox com falha | `63810240` | Crítica | incremento de `outbox_failed_count_total` |
| DLQ recebendo mensagens | `63810241` | Crítica | incremento de `messaging_dlq_count_total` |
| Saga em falha manual | `63810243` | Crítica | incremento de `saga_instances_failed_count_total` |
| Pagamento indisponível | `63810244` | Crítica | mais de uma indisponibilidade do Mercado Pago em 5 minutos |
| Banco indisponível | `63810245` | Crítica | operação de persistência com `result=failure` e `error=unavailable` |

A releitura via NerdGraph confirmou exatamente nove condições, todas com `enabled=true`. Nenhum destination, workflow ou canal de notificação foi criado, pois a tarefa não autorizou mensagens externas. A policy e suas violações permanecem visíveis no New Relic e podem ser conectadas posteriormente aos destinos definidos pela equipe.

O template versionado está em [Policy de Alertas Mínimos](new-relic-alert-policy.json), e os procedimentos de resposta estão nos [Runbooks Operacionais Mínimos](operational-runbooks.md).
