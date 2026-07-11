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
| Logs com `correlationId` do fluxo | Falha: não foram encontradas entradas dos `correlationId` dos testes nos logs dos pods. |
| Traces distribuídos | Falha: os três serviços registraram que `quarkus.otel.traces.exporter` ficou fixado em build como `none`, apesar de `QUARKUS_OTEL_TRACES_EXPORTER=cdi` em runtime. |
| Métricas `/q/metrics` | Sucesso: os três serviços expuseram métricas no cluster e a ingestão em `Metric` foi confirmada no New Relic. |
| Dashboards New Relic | Corrigido parcialmente: a ausência de métricas foi corrigida na coleta e confirmada via NRQL; ainda falta validar visualmente ou reimportar os dashboards remotos com os widgets atualizados. |
| Eventos com `correlationId` | Não comprovado: não houve evidência consultável de eventos/outbox com `correlationId` via logs, endpoint público ou New Relic. |
| Consulta direta ao New Relic | Sucesso parcial: a user key permitiu consultar a conta `8254132`; métricas e logs existem, mas `Span`, logs com `correlationId` e logs com `eventType` continuaram zerados. |

Conclusão: o fluxo REST de ponta a ponta foi executado e as métricas foram comprovadas depois da correção, mas a etapa `[D-NR-REM-005]` não deve ser marcada como concluída porque logs, traces e eventos ainda não têm evidência correlacionável por `correlationId`.

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

Conclusão do troubleshooting: a falha de métricas foi corrigida e comprovada no New Relic. A etapa `[D-NR-REM-005]` ainda deve permanecer pendente porque traces distribuídos, logs de negócio com `correlationId` e eventos/outbox com `eventType` continuam sem evidência.

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

O fluxo REST gerou efeitos funcionais de orçamento, pagamento, execução, estoque e compensação, mas não houve evidência consultável de eventos com `correlationId`:

- não há endpoint público de Outbox/Saga para evidência operacional;
- não foram encontrados logs com `eventType` e `correlationId` dos cenários;
- a consulta direta ao New Relic não foi executada por ausência de chave de consulta NRQL no ambiente local.

## Erros e Limitações

| Item | Tipo | Detalhe | Impacto |
|---|---|---|---|
| Tentativa inicial do cenário compensado | Erro operacional corrigido | Foram usados CPFs inválidos para o `oficina-os-service` (`36655462007` e `17245011010`). A execução limpa usou `12345678909`. | Não afeta o resultado final, mas gerou respostas `400` e dependências vazias nas tentativas descartadas. |
| Consolidação inicial do relatório | Erro operacional corrigido | Um uso incorreto de `jq` falhou ao agregar o primeiro arquivo de resultados. | Não afetou as chamadas REST; o resumo foi refeito com os arquivos temporários. |
| Logs de negócio | Falha de evidência | Nenhum `correlationId` dos cenários apareceu em logs dos pods. | Impede concluir a etapa `[D-NR-REM-005]`. |
| Traces | Falha de configuração/runtime | `quarkus.otel.traces.exporter` está fixado como `none` no build dos três serviços. | Impede comprovar traces no New Relic. |
| Dashboards sem métricas | Falha corrigida parcialmente | A causa local foi identificada, corrigida no collector e confirmada por NRQL em `Metric`. | Falta validar visualmente ou reimportar os dashboards remotos com o JSON atualizado. |
| Eventos | Falha de evidência | Eventos/outbox não ficaram consultáveis por logs, endpoint ou New Relic nesta execução. | Impede comprovar correlação entre eventos e demais sinais. |
| New Relic remoto | Limitação corrigida | A user key foi fornecida depois da execução original e permitiu confirmar métricas e ausência de spans/eventos. | Mantém pendente apenas a validação visual dos dashboards remotos e a correção dos sinais ausentes. |

## Pendências Recomendadas

1. Corrigir o build dos três microsserviços para que `quarkus.otel.traces.exporter` não fique fixado em `none` quando o ambiente `lab` exige tracing.
2. Emitir logs estruturados de entrada HTTP, Outbox, eventos e Saga contendo `correlationId`, `eventType`, `sagaId`, `ordemServicoId` e status operacional.
3. Validar visualmente ou reimportar no New Relic os dashboards remotos usando os widgets atualizados em [Dashboard operacional dos microsserviços](new-relic-dashboard-operational.json).
4. Expor evidência operacional segura para Saga/Outbox ou criar consultas NRQL versionadas para validar eventos e correlação no New Relic.
5. Reexecutar `[D-NR-REM-005]` após as correções de logs, traces e eventos, confirmando correlação entre `Log`, `Span`, `Metric` e sinais de evento/Saga.
