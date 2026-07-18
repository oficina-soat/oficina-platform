# Evidência dos workers de jornada no lab

## Resultado

Em 18/07/2026, o `lab` foi homologado com os publicadores da Outbox separados dos consumidores e com um worker independente por fila nos três microsserviços. A jornada sintética percorreu início e conclusão de diagnóstico, recusa e retomada, nova conclusão e aprovação, reparo, pagamento e entrega.

O resultado funcional foi aprovado: a OS terminou em `ENTREGUE`, a Saga terminou em `FINALIZADA_COM_SUCESSO`, as 32 filas ativas terminaram zeradas e nenhum pod reiniciou. A rodada também expôs uma corrida idempotente no Billing durante o pagamento; ela se recuperou por retry sem duplicar o efeito financeiro, mas deve ser corrigida antes da [nova medição estatística](../../ROADMAP.md#assertividade-da-atualização-da-jornada-operacional).

Esta homologação valida o rollout e fornece amostras operacionais isoladas. Ela não substitui as 30 amostras por transição exigidas pela [ADR-014](../../adr/ADR-014%20-%20Convergência%20da%20Jornada%20e%20Isolamento%20dos%20Workers.md) e pelo [plano de remediação](../architecture/journey-freshness-remediation-plan.md#7-repetir-a-medição-e-comparar).

## Artefatos implantados

| Componente | Versão homologada | Estado observado |
|---|---:|---|
| `oficina-execution-service` | `1.5.0` | Deployment com `1/1` réplica pronta, health `UP` e zero reinício |
| `oficina-billing-service` | `1.7.0` | Deployment com `1/1` réplica pronta, health `UP` e zero reinício |
| `oficina-os-service` | `1.11.0` | Deployment com `1/1` réplica pronta, health `UP` e zero reinício |

Os logs comprovaram execução simultânea por unidades distintas: o publicador em `outbox-publisher-worker` e os consumidores em threads `domain-event-consumer-<fila>`. Os eventos correlacionados passaram de `PENDING` para `PUBLISHED`, foram recebidos pelo consumidor correspondente e terminaram confirmados.

## Cenário homologado

A correlação técnica da rodada foi `freshness-rem-20260718T165150Z`. Somente identificadores sintéticos foram preservados:

| Agregado | Identificador |
|---|---|
| Ordem de Serviço | `c3363166-3b48-4e7f-ae23-d46d61aba1bf` |
| Execução | `6af933cd-f9ba-45e2-b27e-01c1fdfb4e06` |
| Orçamento recusado | `98c0e888-cdc5-35a3-9ca2-fe0bffb8f591` |
| Orçamento aprovado | `1bb1eea9-a148-3bda-abc0-dc29f0dd5655` |
| Pagamento | `2f22bb6b-e9f9-4551-9f5b-e276bc7b9e75` |

| Marco funcional | Resultado observado | Primeira observação após o comando |
|---|---|---:|
| Primeira conclusão de diagnóstico | OS em `AGUARDANDO_APROVACAO` | `471 ms` |
| Primeiro orçamento | Orçamento gerado e depois recusado | `1.464 ms` |
| Retomada após a recusa | OS e Execution novamente em `EM_DIAGNOSTICO` | `1.205 ms` / `459 ms` |
| Segunda conclusão de diagnóstico | OS novamente em `AGUARDANDO_APROVACAO` | `483 ms` |
| Segundo orçamento | Orçamento gerado e depois aprovado | `476 ms` |
| Liberação do reparo | OS em `EM_EXECUCAO` e Execution em `EM_REPARO` | `1.216 ms` / `520 ms` |
| Conclusão do reparo | OS em `FINALIZADA` e Execution em `REPARO_CONCLUIDO` | `505 ms` / `480 ms` |
| Criação do pagamento | Pagamento disponível no Billing | `487 ms` |
| Confirmação do pagamento | Capability `ENTREGAR` disponível | `1.998 ms` |
| Entrega | OS em `ENTREGUE` e Saga finalizada com sucesso | `472 ms` |

Os tempos acima representam uma única primeira observação por polling e não uma decomposição estatística dos marcos HTTP → Outbox → SQS → persistência. Mesmo inferiores ao máximo de `10 s` da ADR, eles não autorizam concluir que o `p95 ≤ 5 s` foi atingido. Essa conclusão pertence à próxima medição, que deve comparar pelo menos 30 amostras por transição com a [linha de base de 57,192–70,450 s](../architecture/journey-freshness-measurement.md).

A tentativa de entregar a OS antes da confirmação do pagamento retornou HTTP `409`, preservando a fronteira operacional. Depois de `pagamentoConfirmado`, a capability canônica foi exposta e a entrega foi aceita.

## Saúde operacional após a jornada

| Verificação | Resultado |
|---|---|
| Readiness | Os três endpoints `/q/health/ready` responderam `UP`; os checks PostgreSQL do OS e do Billing permaneceram `UP` |
| Outbox | `outbox_oldest_pending_age = 0` e todos os gauges `outbox_pending_count` observados ficaram em zero nos três serviços |
| Filas ativas | 32 filas; zero mensagem visível, em voo ou atrasada após a convergência |
| DLQs | 22 DLQs; 45 mensagens visíveis, zero em voo e zero atrasada, com a mesma distribuição observada antes da jornada |
| Pods | Uma réplica pronta por serviço e zero reinício |
| CPU da aplicação | Aproximadamente 4,2% no OS, 1,7% no Billing e 7,2% no Execution no instante da coleta |
| Memória heap usada | Aproximadamente 44 MiB no OS, 57 MiB no Billing e 44 MiB no Execution no instante da coleta |
| Limites por pod | CPU `500m` e memória `1Gi`, com requests de CPU `250m` e memória `512Mi` |

As 45 mensagens de DLQ já existiam antes do rollout, mantiveram as mesmas contagens durante a validação e possuem idade anterior à janela desta jornada. Elas foram preservadas, sem exclusão ou redrive. A Metrics API do Kubernetes não estava disponível para `kubectl top`; por isso, consumo instantâneo foi conferido pelas métricas da aplicação e pelos limites declarados dos pods. O coletor de telemetria permaneceu implantado, mas esta evidência não infere tendência de capacidade a partir de uma única coleta.

## Atrito de idempotência encontrado

Os workers paralelos do Billing processaram concorrentemente gatilhos que convergem para a solicitação do mesmo pagamento. Às `16:55:59.525Z`, o consumo de `execucaoFinalizada` tentou persistir novamente o pagamento vinculado ao orçamento aprovado e recebeu a constraint `uk_pagamento_orcamento`.

A restrição do banco impediu efeito financeiro duplicado. A mensagem permaneceu retentável e recebeu ACK às `16:56:28.144Z`, aproximadamente `28,6 s` depois, quando o pagamento existente já pôde ser reutilizado. A fila terminou vazia e nenhuma mensagem nova chegou à DLQ.

Apesar da recuperação, tratar a colisão esperada como falha de persistência gera erro operacional e atraso desnecessário. A correção deve tornar atômico o fluxo “obter ou criar pagamento” — ou reconhecer a colisão de identidade como sucesso idempotente — e comprovar, com consumidores realmente concorrentes, uma única linha de pagamento e uma única Outbox. Essa correção foi inserida antes da nova medição no [roadmap](../../ROADMAP.md#assertividade-da-atualização-da-jornada-operacional).

## Segurança da evidência

O JWT administrativo teve validade de cinco minutos, permaneceu somente em memória durante a execução e não foi persistido. Token, secret, CPF, e-mail, links públicos e demais dados pessoais não constam nesta evidência. Uma primeira tentativa de autenticação com sujeito inexistente retornou HTTP `401`; a credencial válida foi então emitida para um sujeito administrativo já cadastrado, sem registrar sua identidade.
