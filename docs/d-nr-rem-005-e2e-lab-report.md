# Relatório D-NR-REM-005 — E2E no ambiente lab

## Contexto

Este relatório registra a execução remota da etapa `[D-NR-REM-005]` do [ROADMAP](../ROADMAP.md), relacionada ao [Padrão de Observabilidade Distribuída](observability.md), às [Rotas públicas do API Gateway](api-gateway-public-routes.md), ao [Contrato de APIs REST](../contracts/Contrato%20de%20APIs%20REST.md), ao [Contrato de Erros REST](../contracts/error-model.md) e ao [Contrato de Saga do oficina-os-service](../contracts/saga/oficina-os-saga-v1.md).

Execução realizada em `2026-07-11 09:23:40 -03` (`2026-07-11T12:23:40Z`) contra o ambiente `lab`.

Endpoint público usado:

```text
https://mpjdgp1wx2.execute-api.us-east-1.amazonaws.com
```

Os testes usaram autenticação via `POST /auth/token`. O JWT e credenciais não foram registrados neste relatório.

## Resultado Geral

| Validação | Resultado |
|---|---|
| Autenticação remota | Sucesso: `/auth/token` retornou `200` e emitiu token. |
| Caminho feliz da Ordem de Serviço | Sucesso: 19 de 19 chamadas retornaram o status esperado. |
| Falha compensada | Sucesso funcional: 18 de 18 chamadas retornaram o status esperado, incluindo falha esperada de estoque e compensação operacional. |
| `X-Correlation-Id` em respostas HTTP | Sucesso: 37 de 37 chamadas limpas retornaram o mesmo `correlationId` enviado. |
| Logs com `correlationId` do fluxo | Sucesso na revalidação pós-merge: o New Relic retornou logs dos três serviços para `correlationId=d-nr-rem-005-reval-tracefix-20260711T143832Z`. |
| Traces distribuídos | Sucesso após correção do collector: o New Relic retornou `Span` para `oficina-os-service`, `oficina-billing-service` e `oficina-execution-service`. |
| Métricas `/q/metrics` | Sucesso: os três serviços expuseram métricas no cluster e a ingestão em `Metric` foi confirmada no New Relic. |
| Dashboards New Relic | Corrigido parcialmente: a ausência de métricas foi corrigida na coleta e confirmada via NRQL; ainda falta validar visualmente ou reimportar os dashboards remotos com os widgets atualizados. |
| Eventos com `correlationId` | Parcial: Outbox/eventos aparecem como logs estruturados com `correlationId`, `eventId`, `eventVersion`, `topic`, `producer`, `aggregateId` e `messageStatus`; o campo literal `eventType` existe no stdout do pod, mas não fica como atributo consultável no `Log` do New Relic. |
| Consulta direta ao New Relic | Sucesso parcial: a user key permitiu consultar a conta `8254132`; `Metric`, `Span` e `Log` com `correlationId` foram comprovados. Falta publicar/deployar aliases de evento para consultar `domainEventType` no New Relic. |

Conclusão atual: o fluxo REST de ponta a ponta foi executado, e `Metric`, `Span` e `Log` com `correlationId` foram comprovados depois das correções. A etapa `[D-NR-REM-005]` ainda não deve ser marcada como concluída porque o tipo lógico dos eventos precisa aparecer como atributo consultável no New Relic; o stdout dos pods contém `eventType`, mas a ingestão do New Relic remove esse nome.

Atualização de remediação em 2026-07-11: o `oficina-infra` recebeu a pipeline `traces/oficina-microservices` no New Relic OpenTelemetry Collector e o release Helm foi atualizado no `lab`. Os três microsserviços receberam correção local para manter `eventType` no JSON do pod e emitir aliases consultáveis `domainEventType` e `event.type`, com versões publicáveis incrementadas e suítes locais executadas com sucesso. Falta publicar/deployar essas novas imagens para reexecutar a validação remota dos aliases de evento.

## Revalidação Pós-Merge

Execução complementar realizada em `2026-07-11 11:38:32 -03` (`2026-07-11T14:38:32Z`) após os merges dos repositórios de microsserviço e infraestrutura.

Versões implantadas no `lab` durante a revalidação:

| Serviço | Imagem |
|---|---|
| `oficina-os-service` | `1.0.3` |
| `oficina-billing-service` | `1.0.4` |
| `oficina-execution-service` | `1.0.3` |

Tráfego mínimo gerado para a validação de sinais:

| Artefato | Valor |
|---|---|
| `correlationId` | `d-nr-rem-005-reval-tracefix-20260711T143832Z` |
| Ordem de Serviço usada como agregado | `5863a0eb-c678-4990-941e-d9cfdeff4b53` |
| Execução | `11dea9e8-c3f7-4026-a4ef-0a7fb0df885f` |
| Orçamento | `6c5de11e-3154-447a-9655-dd856d5aa8db` |
| Cliente | `be08e5fc-f1f4-438a-93ac-52686a894bc7` |

Chamadas executadas:

| Chamada | Status | `X-Correlation-Id` |
|---|---|---|
| `POST /api/v1/clientes` | `201` | preservado |
| `POST /api/v1/orcamentos` | `201` | preservado |
| `POST /api/v1/execucoes` | `201` | preservado |
| `POST /api/v1/execucoes/{execucaoId}/diagnostico/inicio` | `200` | preservado |

Evidência NRQL na conta `8254132`:

| Consulta | Resultado |
|---|---|
| `FROM Metric SELECT count(*) WHERE service.namespace = 'oficina' SINCE 30 minutes ago FACET service.name` | `oficina-os-service=10497`, `oficina-billing-service=10232`, `oficina-execution-service=8662` |
| `FROM Span SELECT count(*) WHERE service.namespace = 'oficina' SINCE 60 minutes ago FACET service.name` | `oficina-os-service=3`, `oficina-execution-service=2`, `oficina-billing-service=1` |
| `FROM Log SELECT count(*) WHERE correlationId = 'd-nr-rem-005-reval-tracefix-20260711T143832Z' SINCE 30 minutes ago FACET service.name` | `oficina-execution-service=3`, `oficina-billing-service=2`, `oficina-os-service=1` |
| `FROM Log SELECT count(*) WHERE correlationId = 'd-nr-rem-005-reval-tracefix-20260711T143832Z' AND message = 'outbox event registered' AND eventType IS NOT NULL SINCE 30 minutes ago` | `0` |
| `FROM Log SELECT keyset() WHERE correlationId = 'd-nr-rem-005-reval-tracefix-20260711T143832Z' AND message = 'outbox event registered' SINCE 30 minutes ago` | retornou atributos estruturados de Outbox, incluindo `aggregateId`, `correlationId`, `eventId`, `eventVersion`, `topic`, `producer`, `messageStatus`, `traceId` e `spanId`, mas sem `eventType`. |

Diagnóstico final da revalidação: o collector estava aceitando métricas e logs, mas o Deployment do collector não tinha pipeline de traces. A pipeline `traces/oficina-microservices` foi adicionada ao `oficina-infra`, o release Helm foi atualizado para a revision `5`, e os spans passaram a chegar para os três serviços. Para eventos, a causa restante é a ingestão do New Relic remover o atributo literal `eventType`; por isso, os microsserviços foram ajustados para emitir também `domainEventType` e `event.type`.

Testes locais reexecutados após a correção dos aliases:

| Repositório | Comando | Resultado |
|---|---|---|
| `oficina-os-service` | `./mvnw -B test -Ppostgresql` | `89` testes, `0` falhas, `0` erros, `0` ignorados. |
| `oficina-billing-service` | `./mvnw -B test -Ppostgresql` | `42` testes, `0` falhas, `0` erros, `0` ignorados. |
| `oficina-execution-service` | `./mvnw -B test -Pdynamodb` | `42` testes, `0` falhas, `0` erros, `0` ignorados. |

Versões preparadas para o próximo rollout:

| Serviço | Versão preparada |
|---|---|
| `oficina-os-service` | `1.0.4` |
| `oficina-billing-service` | `1.0.5` |
| `oficina-execution-service` | `1.0.4` |

## Caminho Feliz

`correlationId`:

```text
d-nr-rem-005-happy-20260711T122204Z
```

Artefatos gerados:

| Artefato | ID |
|---|---|
| Ordem de Serviço | `a0a3a34f-1239-4f56-babd-e7d6d6690d5a` |
| Execução | `0c0d2a2c-3c49-40fd-939a-b4c5f078a27b` |
| Orçamento | `5d8911e6-381a-4f26-863b-ddfc24833975` |
| Pagamento | `0c9894a2-5199-4b4c-9a33-d6cb371a65fb` |
| Estado final da OS | `ENTREGUE` |
| Registros de histórico da OS | `6` |

Chamadas executadas com sucesso:

| Etapa | Status |
|---|---|
| Criar cliente | `201` |
| Criar veículo | `201` |
| Abrir OS | `201` |
| Criar execução | `201` |
| Iniciar diagnóstico | `200` |
| Alterar OS para `EM_DIAGNOSTICO` | `200` |
| Concluir diagnóstico | `200` |
| Alterar OS para `AGUARDANDO_APROVACAO` | `200` |
| Gerar orçamento | `201` |
| Aprovar orçamento | `200` |
| Iniciar reparo | `200` |
| Alterar OS para `EM_EXECUCAO` | `200` |
| Concluir reparo | `200` |
| Alterar OS para `FINALIZADA` | `200` |
| Criar pagamento | `201` |
| Confirmar pagamento | `200` |
| Alterar OS para `ENTREGUE` | `200` |
| Consultar OS final | `200` |
| Consultar histórico | `200` |

## Falha Compensada

`correlationId`:

```text
d-nr-rem-005-compensated-20260711T122340Z
```

Artefatos gerados:

| Artefato | ID |
|---|---|
| Ordem de Serviço | `aa1eefc8-bb48-468c-a645-95a8c1d36108` |
| Execução | `ba5087bc-1417-471c-bc89-6ce898a43b9e` |
| Orçamento | `20e001f1-5963-4f75-9a2a-92a54d26cd54` |
| Peça sem estoque | `eb934ffd-7253-4b5e-909c-791f514e64de` |
| Estado final da execução | `CANCELADA` |
| Estado final observado da OS | `EM_EXECUCAO` |

Falha esperada:

```text
Saldo de estoque insuficiente para a peca: eb934ffd-7253-4b5e-909c-791f514e64de
```

Chamadas executadas com sucesso funcional:

| Etapa | Status |
|---|---|
| Criar cliente | `201` |
| Criar veículo | `201` |
| Abrir OS | `201` |
| Criar execução | `201` |
| Iniciar diagnóstico | `200` |
| Alterar OS para `EM_DIAGNOSTICO` | `200` |
| Concluir diagnóstico | `200` |
| Alterar OS para `AGUARDANDO_APROVACAO` | `200` |
| Gerar orçamento | `201` |
| Aprovar orçamento | `200` |
| Iniciar reparo | `200` |
| Alterar OS para `EM_EXECUCAO` | `200` |
| Criar peça sem estoque | `201` |
| Reservar estoque indisponível | `409` esperado |
| Cancelar execução | `200` |
| Solicitar compensação/cancelamento da OS | `202` |
| Consultar execução final | `200` |
| Consultar OS após compensação | `200` |

Observação: a compensação funcional cancelou a execução, mas a consulta pública da OS permaneceu em `EM_EXECUCAO`. A Saga compensada não ficou exposta por endpoint consultável, e os eventos de compensação não foram comprovados em logs ou New Relic.

## Evidências de Observabilidade

### Kubernetes e Collector

Verificações executadas:

- `aws sts get-caller-identity`;
- `aws eks update-kubeconfig --region us-east-1 --name eks-lab`;
- `kubectl get pods -A`;
- `kubectl get pods -n newrelic`;
- `kubectl logs -n newrelic ds/nr-k8s-otel-collector-daemonset --since=20m`.

Resultado:

- `oficina-os-service`, `oficina-billing-service` e `oficina-execution-service` estavam `1/1 Running`;
- `nr-k8s-otel-collector-daemonset`, `nr-k8s-otel-collector-deployment` e `kube-state-metrics` estavam `1/1 Running`;
- o daemonset do collector estava acompanhando arquivos de log dos pods dos microsserviços.

### Métricas

As métricas foram validadas por port-forward temporário para `/q/metrics`:

| Serviço | Resultado |
|---|---|
| `oficina-os-service` | Sucesso: endpoint respondeu, com 339 linhas de métricas e 61 linhas relacionadas a HTTP. |
| `oficina-billing-service` | Sucesso: endpoint respondeu, com 324 linhas de métricas e 46 linhas relacionadas a HTTP. |
| `oficina-execution-service` | Sucesso: endpoint respondeu, com 290 linhas de métricas e 67 linhas relacionadas a HTTP. |

### Dashboards New Relic

Evidência manual informada em 2026-07-11: os dashboards do New Relic exibiram logs, mas nenhum outro gráfico indicou recebimento de métricas.

Interpretação original: a exposição local de `/q/metrics` nos pods estava funcional, mas a coleta, transformação, envio ou consulta das métricas no New Relic não tinha sido comprovada.

### Troubleshooting das métricas

Execução complementar em 2026-07-11:

- causa identificada: o ConfigMap gerado pelo chart `nr-k8s-otel-collector` tinha jobs Prometheus para `kube-state-metrics`, `apiserver`, `cadvisor` e `kubelet`, mas não tinha job para raspar `/q/metrics` dos pods dos microsserviços;
- correção aplicada no `oficina-infra`: `values.lab.yaml` passou a configurar o receiver `prometheus/oficina-microservices`, com descoberta dos pods `oficina-os-service`, `oficina-billing-service` e `oficina-execution-service` no namespace `default`;
- correção aplicada nos manifests dos microsserviços no `oficina-infra`: os três Deployments receberam anotações `prometheus.io/scrape=true`, `prometheus.io/path=/q/metrics` e `prometheus.io/port=8080`;
- correção aplicada no ambiente `lab`: o release Helm `nr-k8s-otel-collector` foi atualizado para a revision `3`, e os três Deployments foram anotados e tiveram rollout concluído;
- validação no cluster: o Deployment do collector ficou `1/1 Running`, os três microsserviços ficaram `1/1`, e os logs do collector registraram `Scrape job added` para `jobName=oficina-microservices`, sem erro de scrape/exportação nos logs recentes;
- validação no New Relic: a conta `8254132` retornou métricas em `Metric` para `k8s.cluster.name = 'eks-lab'` e `service.namespace = 'oficina'`; a conta `8254133` não tinha dados do ambiente.

Evidência NRQL em 2026-07-11:

| Consulta | Resultado |
|---|---|
| `FROM Metric SELECT count(*) WHERE k8s.cluster.name = 'eks-lab' SINCE 60 minutes ago` | `78305` |
| `FROM Metric SELECT count(*) WHERE service.namespace = 'oficina' SINCE 60 minutes ago` | `21580` |
| `FROM Metric SELECT count(*) WHERE service.namespace = 'oficina' SINCE 5 minutes ago FACET service.name` | `oficina-os-service=1644`, `oficina-billing-service=1485`, `oficina-execution-service=1333` |
| Widget de métricas Prometheus dos serviços | retornou `process_uptime_seconds`, `jvm_threads_live_threads` e `http_server_active_requests` para os três serviços. |
| `FROM Span SELECT count(*) WHERE service.namespace = 'oficina' SINCE 60 minutes ago` | `0` |
| `FROM Log SELECT count(*) WHERE correlationId IN (...) SINCE 6 hours ago` | `0` |
| `FROM Log SELECT count(*) WHERE service.namespace = 'oficina' AND eventType IS NOT NULL SINCE 6 hours ago` | `0` |

Conclusão daquele troubleshooting: a falha de métricas foi corrigida e comprovada no New Relic, mas naquele momento traces distribuídos, logs de negócio com `correlationId` e eventos/outbox com `eventType` ainda não tinham evidência. A [revalidação pós-merge](#revalidação-pós-merge) comprovou posteriormente `Span` e `Log` com `correlationId`, restando apenas a evidência remota do alias consultável de evento.

### Logs

Consulta executada nos logs dos três Deployments com os `correlationId` dos cenários:

```text
d-nr-rem-005-happy-20260711T122204Z
d-nr-rem-005-compensated-20260711T122340Z
```

Resultado: nenhuma entrada contendo esses valores foi encontrada nos logs dos pods. Os logs estruturados de inicialização contêm `service.name`, `service.namespace` e `deployment.environment`, mas o fluxo de negócio não gerou logs rastreáveis por `correlationId`.

### Traces

Os três serviços tinham as variáveis de runtime esperadas:

- `OTEL_SERVICE_NAME`;
- `OTEL_RESOURCE_ATTRIBUTES=service.namespace=oficina,deployment.environment=lab`;
- `OTEL_EXPORTER_OTLP_ENDPOINT=http://nr-k8s-otel-collector-gateway.newrelic.svc.cluster.local:4317`;
- `QUARKUS_OTEL_TRACES_EXPORTER=cdi`.

Porém, os três serviços registraram o aviso:

```text
quarkus.otel.traces.exporter is set to 'cdi' but it is build time fixed to 'none'
```

Resultado: traces distribuídos não foram comprovados.

### Eventos

Na execução original, o fluxo REST gerou efeitos funcionais de orçamento, pagamento, execução, estoque e compensação, mas não houve evidência consultável de eventos com `correlationId`:

- não há endpoint público de Outbox/Saga para evidência operacional;
- não foram encontrados logs com `eventType` e `correlationId` dos cenários;
- a consulta direta ao New Relic ainda não tinha sido executada por ausência de chave de consulta NRQL no ambiente local.

Na revalidação pós-merge, os logs de Outbox apareceram no New Relic com `correlationId` e identificadores estruturados, mas o atributo literal `eventType` foi removido pela ingestão. A correção preparada nos microsserviços adiciona `domainEventType` e `event.type` para consulta remota, preservando `eventType` no stdout dos pods.

## Erros e Limitações

| Item | Tipo | Detalhe | Impacto |
|---|---|---|---|
| Tentativa inicial do cenário compensado | Erro operacional corrigido | Foram usados CPFs inválidos para o `oficina-os-service` (`36655462007` e `17245011010`). A execução limpa usou `12345678909`. | Não afeta o resultado final, mas gerou respostas `400` e dependências vazias nas tentativas descartadas. |
| Consolidação inicial do relatório | Erro operacional corrigido | Um uso incorreto de `jq` falhou ao agregar o primeiro arquivo de resultados. | Não afetou as chamadas REST; o resumo foi refeito com os arquivos temporários. |
| Logs de negócio | Corrigido e comprovado | A revalidação pós-merge confirmou logs no New Relic com `correlationId` para os três serviços. | Não bloqueia mais `[D-NR-REM-005]`. |
| Traces | Corrigido e comprovado | A revalidação pós-merge confirmou `Span` no New Relic para os três serviços após adicionar a pipeline `traces/oficina-microservices` no collector. | Não bloqueia mais `[D-NR-REM-005]`. |
| Dashboards sem métricas | Falha corrigida parcialmente | A causa local foi identificada, corrigida no collector e confirmada por NRQL em `Metric`. | Falta validar visualmente ou reimportar os dashboards remotos com o JSON atualizado. |
| Eventos | Falha residual com correção local preparada | Eventos/outbox aparecem como logs estruturados no New Relic, mas `eventType` é removido como atributo consultável. Em 2026-07-11, os três serviços passaram a emitir aliases `domainEventType` e `event.type`. | Impede concluir `[D-NR-REM-005]` até publicar/deployar as novas imagens e confirmar `domainEventType` por NRQL. |
| New Relic remoto | Limitação corrigida | A user key foi fornecida depois da execução original e permitiu confirmar métricas e ausência de spans/eventos. | Mantém pendente apenas a validação visual dos dashboards remotos e a correção dos sinais ausentes. |

## Pendências Recomendadas

1. Publicar e deployar `oficina-os-service:1.0.4`, `oficina-billing-service:1.0.5` e `oficina-execution-service:1.0.4`, contendo aliases `domainEventType` e `event.type` para logs de eventos.
2. Reexecutar as consultas NRQL de `Log` por `domainEventType` após o rollout, mantendo `eventType` como campo canônico do stdout dos pods.
3. Validar visualmente ou reimportar no New Relic os dashboards remotos usando os widgets atualizados em [Dashboard operacional dos microsserviços](new-relic-dashboard-operational.json).
4. Expor evidência operacional segura para Saga/Outbox ou criar consultas NRQL versionadas para validar eventos e correlação no New Relic.
5. Reexecutar `[D-NR-REM-005]` após as correções de logs, traces e eventos, confirmando correlação entre `Log`, `Span`, `Metric` e sinais de evento/Saga.
