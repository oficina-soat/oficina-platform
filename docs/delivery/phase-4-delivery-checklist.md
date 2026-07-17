# Checklist final de entrega

## Objetivo

Consolidar os entregáveis finais, com os links e evidências que devem ser conferidos antes da entrega no portal.

Este checklist complementa o [Enunciado do projeto](Enunciado%20Fase%204.md), o [ROADMAP](../../ROADMAP.md), o [Diagrama Geral da Arquitetura Final](../architecture/architecture-diagram.md), a [Matriz de Ownership por Microsserviço](../architecture/service-ownership.md), o [Padrão BDD, Cobertura e Qualidade](bdd-testing.md), a [ADR-009 - Estratégia de Saga Pattern](../../adr/ADR-009%20-%20Estratégia%20de%20Saga%20Pattern.md), a [ADR-010 - Estratégia de Divisão dos Microsserviços](../../adr/ADR-010%20-%20Estratégia%20de%20Divisão%20dos%20Microsserviços.md), a [ADR-011 - Estratégia de Persistência Poliglota por Microsserviço](../../adr/ADR-011%20-%20Estratégia%20de%20Persistência%20Poliglota%20por%20Microsserviço.md), a [ADR-012 - Estratégia de CI/CD e Deploy Independente](../../adr/ADR-012%20-%20Estratégia%20de%20CI%20CD%20e%20Deploy%20Independente.md), o [Checklist de Deploy Independente](independent-deploy-checklist.md), o [Padrão de Observabilidade Distribuída](../observability/observability.md), os [Runbooks Operacionais Mínimos](../observability/operational-runbooks.md) e as [Rotas públicas do API Gateway](../infrastructure/api-gateway-public-routes.md).

## Datas e Responsáveis

| Item | Valor |
|---|---|
| Data limite da entrega | 28/07/2026 |
| Data de fechamento das evidências | A preencher |
| Participantes | A preencher |
| Link do vídeo | A preencher |
| Link do PDF final | A preencher |

## Repositórios

| Repositório | Link remoto | README final | Cobertura | Swagger/OpenAPI | Pipeline | Kubernetes | Status |
|---|---|---|---|---|---|---|---|
| `oficina-os-service` | [GitHub](https://github.com/oficina-soat/oficina-os-service) | [README](https://github.com/oficina-soat/oficina-os-service#readme) | [Evidência no README](https://github.com/oficina-soat/oficina-os-service#cobertura) | [OpenAPI canônica](../../contracts/openapi/oficina-os-service.yaml) | [Service CI/CD](https://github.com/oficina-soat/oficina-os-service/actions/workflows/service-ci.yml) | [Manifest canônico](https://github.com/oficina-soat/oficina-os-service/tree/main/k8s/base) | Publicado e validado no `lab` |
| `oficina-billing-service` | [GitHub](https://github.com/oficina-soat/oficina-billing-service) | [README](https://github.com/oficina-soat/oficina-billing-service#readme) | [Evidência no README](https://github.com/oficina-soat/oficina-billing-service#cobertura) | [OpenAPI canônica](../../contracts/openapi/oficina-billing-service.yaml) | [Service CI/CD](https://github.com/oficina-soat/oficina-billing-service/actions/workflows/service-ci.yml) | [Manifest canônico](https://github.com/oficina-soat/oficina-billing-service/tree/main/k8s/base) | Publicado e validado no `lab` |
| `oficina-execution-service` | [GitHub](https://github.com/oficina-soat/oficina-execution-service) | [README](https://github.com/oficina-soat/oficina-execution-service#readme) | [Evidência no README](https://github.com/oficina-soat/oficina-execution-service#cobertura) | [OpenAPI canônica](../../contracts/openapi/oficina-execution-service.yaml) | [Service CI/CD](https://github.com/oficina-soat/oficina-execution-service/actions/workflows/service-ci.yml) | [Manifest canônico](https://github.com/oficina-soat/oficina-execution-service/tree/main/k8s/base) | Publicado e validado no `lab` |
| `oficina-infra` | [GitHub](https://github.com/oficina-soat/oficina-infra) | [README](https://github.com/oficina-soat/oficina-infra#readme) | Não aplicável | Não aplicável | [Deploy Lab](https://github.com/oficina-soat/oficina-infra/actions/workflows/deploy-lab.yml) | [Kubernetes](https://github.com/oficina-soat/oficina-infra/tree/main/k8s) | Publicado e validado no `lab` |
| `oficina-auth-lambda` | A preencher | A preencher | A preencher | [OpenAPI canônica](../../contracts/openapi/oficina-auth-lambda.yaml) | A preencher | Não aplicável | Pendente |

## Checklist por Microsserviço

Cada repositório de microsserviço deve possuir:

- [x] código-fonte do serviço, sem dependência runtime do `oficina-app`;
- [x] `README.md` com setup local, variáveis de ambiente, execução, testes, build, Docker, deploy e links de evidências;
- [x] Dockerfile funcional;
- [x] pipeline independente de CI/CD;
- [x] deploy independente validado no ambiente `lab`, com publicação de imagem e rollout registrados nas evidências de [OS](os-postgresql-lab-evidence.md), [Billing](billing-postgresql-lab-evidence.md) e [Execution](execution-dynamodb-lab-evidence.md);
- [x] proteção da branch `main` com PR obrigatório e `service-ci-validate` exigido nos três microsserviços, conforme a [evidência remota dos Rulesets](github-branch-protection-evidence.md);
- [x] testes unitários e de integração executados pelo ciclo Maven `verify` dos três microsserviços;
- [x] evidência de cobertura mínima de 80% registrada nos READMEs e validada pelo `service-ci-validate`, conforme [Padrão BDD, Cobertura e Qualidade](bdd-testing.md);
- [x] Quality Gate SonarCloud aprovado nos três projetos e exigido pelo `service-ci-validate`;
- [x] links para Swagger/OpenAPI atualizada registrados nos READMEs dos três microsserviços;
- [x] autenticação JWT configurada conforme contratos da suíte;
- [x] tratamento de erros conforme [Contrato de Erros REST](../../contracts/error-model.md), coberto por testes de contrato;
- [x] idempotência conforme o [Contrato de Idempotência](../../contracts/idempotency.md), validada nos três microsserviços antes e depois de restart conforme a [evidência remota do lab](idempotency-lab-evidence.md);
- [x] propagação de `correlationId` em HTTP, eventos, logs e traces comprovada no [E2E do ambiente lab](../observability/d-nr-rem-005-e2e-lab-report.md);
- [x] documentação da Saga orquestrada pelo `oficina-os-service` registrada nos READMEs, com links para [ADR-009](../../adr/ADR-009%20-%20Estratégia%20de%20Saga%20Pattern.md), [Fluxos da Saga da Ordem de Serviço](../architecture/saga-flows.md) e [Contrato de Saga do oficina-os-service](../../contracts/saga/oficina-os-saga-v1.md);
- [x] manifests Kubernetes aplicáveis materializados no `oficina-infra` e referenciados pelos READMEs, conforme a [Estratégia de entrega dos manifestos Kubernetes](../infrastructure/kubernetes-manifest-strategy.md).
- [ ] runbooks aplicáveis revisados conforme os [Runbooks Operacionais Mínimos](../observability/operational-runbooks.md).

## Checklist de Domínio e Contratos

| Requisito | Evidência esperada | Link |
|---|---|---|
| Separação em três microsserviços | Repositórios independentes e responsabilidades alinhadas à [Matriz de Ownership por Microsserviço](../architecture/service-ownership.md). | [OS](https://github.com/oficina-soat/oficina-os-service), [Billing](https://github.com/oficina-soat/oficina-billing-service) e [Execution](https://github.com/oficina-soat/oficina-execution-service) |
| Banco próprio por microsserviço | `oficina_os`, `oficina_billing` e tabelas DynamoDB do `oficina-execution-service`. | [OS](os-postgresql-lab-evidence.md), [Billing](billing-postgresql-lab-evidence.md) e [Execution](execution-dynamodb-lab-evidence.md) |
| Banco SQL | PostgreSQL em RDS compartilhado com databases isolados, conforme [Padrão de isolamento PostgreSQL no RDS compartilhado](../infrastructure/rds-postgresql-isolation.md). | [Billing validado no PostgreSQL real](billing-postgresql-lab-evidence.md) e [OS validado com isolamento entre databases e restart](os-postgresql-lab-evidence.md) |
| Banco NoSQL | DynamoDB do `oficina-execution-service`, conforme [Padrão DynamoDB do oficina-execution-service](../infrastructure/dynamodb-execution-service.md). | [Execution validado nas cinco tabelas reais, inclusive após restart](execution-dynamodb-lab-evidence.md) |
| Comunicação REST | Rotas aderentes ao [Contrato de APIs REST](../../contracts/Contrato%20de%20APIs%20REST.md), às OpenAPI dos três serviços e às [Rotas públicas do API Gateway](../infrastructure/api-gateway-public-routes.md). | [Rotas públicas materializadas e validadas](../infrastructure/api-gateway-public-routes.md) |
| Mensageria assíncrona | Eventos e tópicos aderentes ao [Contrato de Eventos de Domínio](../../contracts/Contrato%20de%20Eventos%20de%20Domínio.md) e ao [Contrato de Tópicos de Mensageria](../../contracts/Contrato%20de%20Tópicos%20de%20Mensageria.md). | [Fluxo real Outbox, SNS, SQS, persistência e DLQ validado no lab](messaging-lab-evidence.md) |
| Saga Pattern | Orquestração pelo `oficina-os-service`, com caminho feliz e falha compensada. | [BDD e E2E no ambiente lab](../observability/d-nr-rem-005-e2e-lab-report.md) |
| Mercado Pago | Integração financeira documentada e evidência de cobrança PIX sandbox executada pelo `oficina-billing-service`, com `pagamentoId`, `transacaoExternaId`, referência externa do Mercado Pago, logs/traces por `correlationId` e evento financeiro correspondente. | [Cobrança PIX sandbox e correlação no New Relic concluídas](mercado-pago-sandbox-evidence.md) |
| Observabilidade | Logs estruturados, métricas, traces, quatro dashboards e nove alertas mínimos conforme [Padrão de Observabilidade Distribuída](../observability/observability.md). | [E2E no ambiente lab](../observability/d-nr-rem-005-e2e-lab-report.md), [Dashboards New Relic](../observability/new-relic-dashboards.md) e [Alertas mínimos](../observability/new-relic-alerts-lab-evidence.md) |
| Diagrama geral | Arquitetura final alinhada ao [Diagrama Geral da Arquitetura Final](../architecture/architecture-diagram.md). | [Diagrama Geral da Arquitetura Final](../architecture/architecture-diagram.md) |

## Evidências Consolidadas de Bancos e Mensageria

| Escopo | Recurso físico ou identificador | Evidência consolidada |
|---|---|---|
| PostgreSQL compartilhado | RDS `oficina-postgres-lab`; databases `oficina_os` e `oficina_billing`; usuários próprios | [OS](os-postgresql-lab-evidence.md) e [Billing](billing-postgresql-lab-evidence.md) comprovam migrations, registros sentinela, isolamento e preservação após substituição dos pods. |
| DynamoDB | `oficina-execution-lab-catalogo`, `-estoque`, `-execucoes`, `-outbox` e `-idempotencia` | [Execution](execution-dynamodb-lab-evidence.md) comprova tabelas `ACTIVE`, nomes físicos, itens sentinela e contagens idênticas após restart. |
| Outbox e caminho feliz | Evento `ordemDeServicoCriada`, tópico `oficina.os.ordem-de-servico-criada`, filas de Billing e Execution | [Mensageria SNS/SQS](messaging-lab-evidence.md) comprova `PUBLISHED`, `CONSUMED`, `ACKED`, persistência nos consumidores e filas zeradas após ACK. |
| Retry e DLQ | Fila `oficina-billing-orcamento-gerado-oficina-os-service`; DLQ `oficina-billing-orcamento-gerado-dlq` | A mensagem sentinela foi recebida seis vezes e redirecionada à DLQ após o limite configurado. |
| IAM e runtime EKS | Node group `eks-lab-ng-20260714092902417300000007`; role `LabRole`; policies content-addressed em `v1` | O fluxo real executou sem `AccessDenied`, credencial estática ou fallback local. |
| Correlação | `b2-msg-rem-001-20260714111604`, `eventId=ff3631a6-52c6-43ec-81fd-3e843fcc82e4` | Logs estruturados ligam produtor, Outbox, SNS/SQS, consumidores e persistência pelos identificadores canônicos. |

Essa matriz conclui `[B2-DB-MSG-EVID-001]` sem reproduzir conteúdo de Secrets, endpoints privados ou credenciais.

## Evidências Consolidadas de Observabilidade

| Artefato | Identificador | Evidência |
|---|---|---|
| Dashboard operacional | `ODI1NDEzMnxWSVp8REFTSEJPQVJEfGRhOjEyODcwMzQ1` | Golden signals, HTTP, Kubernetes, logs, traces e busca por `correlationId`. |
| Dashboard da Saga | `ODI1NDEzMnxWSVp8REFTSEJPQVJEfGRhOjEyODcwMzcz` | 14 widgets, métricas `saga_instances_*`, duração por etapa e correlação; [evidência remota](../observability/saga-metrics-lab-evidence.md). |
| Dashboard de persistência e mensageria | `ODI1NDEzMnxWSVp8REFTSEJPQVJEfGRhOjEyODgzNTkw` | 10 widgets de banco, Outbox, SNS/SQS, DLQ e idempotência. |
| Dashboard Mercado Pago | `ODI1NDEzMnxWSVp8REFTSEJPQVJEfGRhOjEyODg3MzE0` | 11 widgets; volume, desfechos, p95/p99, valores, indisponibilidade, logs e traces; [evidência remota](../observability/mercado-pago-dashboard-lab-evidence.md). |
| Policy de alertas | `7756164` | Nove condições ativas para disponibilidade, HTTP, latência, Outbox, DLQ, Saga, pagamento e banco; [evidência remota](../observability/new-relic-alerts-lab-evidence.md). |
| Trace e logs E2E | `d-nr-rem-005-rerun-happy-20260711T151358Z` e `d-nr-rem-005-rerun-comp-20260711T151358Z` | [E2E no lab](../observability/d-nr-rem-005-e2e-lab-report.md) comprova sinais nos três microsserviços e eventos correlacionados. |
| Cobrança sandbox | `d-obs-mp-success-20260715T110159Z-pagamento` | Métricas, logs e cobrança Mercado Pago associados na [evidência de coleta](../observability/payment-provider-metrics-lab-evidence.md). |

Consultas NRQL representativas validadas via NerdGraph:

```nrql
FROM Log SELECT count(*) WHERE correlationId IN ('d-nr-rem-005-rerun-happy-20260711T151358Z', 'd-nr-rem-005-rerun-comp-20260711T151358Z') FACET service.name, correlationId
```

```nrql
FROM Metric SELECT percentile(saga_step_duration_seconds, 95) WHERE service = 'oficina-os-service' AND sagaType = 'ordemServico' FACET step
```

```nrql
FROM Metric SELECT sum(payment_provider_requests_count_total) WHERE service = 'oficina-billing-service' AND provider = 'mercado-pago' FACET method, outcome, providerStatus
```

```nrql
FROM Metric SELECT sum(messaging_dlq_count_total) WHERE service.namespace = 'oficina' AND deployment.environment = 'lab' FACET service.name, queue, topic
```

Essa consolidação conclui `[D-NR-EVID-001]`. GUIDs, queries completas e resultados adicionais permanecem em [Dashboards New Relic](../observability/new-relic-dashboards.md) e nos relatórios vinculados.

## Cenários de Demonstração

Roteiro canônico: [Roteiro do vídeo de demonstração](video-demonstration-script.md).

O vídeo de até 15 minutos deve demonstrar:

- [ ] fluxo completo de uma OS passando por `oficina-os-service`, `oficina-billing-service` e `oficina-execution-service`;
- [ ] Saga finalizada com sucesso, incluindo eventos `ordemDeServicoCriada`, `diagnosticoFinalizado`, `orcamentoGerado`, `orcamentoAprovado`, `execucaoFinalizada`, `pagamentoConfirmado`, `ordemDeServicoEntregue` e `sagaFinalizadaComSucesso`;
- [ ] falha tratável com compensação, resultando em `sagaCompensada`;
- [ ] execução de testes e evidência de cobertura mínima de 80%;
- [ ] Quality Gate externo aprovado quando SonarCloud estiver configurado, ou pendência/evidência alternativa registrada;
- [ ] deploy automatizado de pelo menos um microsserviço em Kubernetes;
- [ ] rastreamento distribuído com `correlationId` em logs e traces;
- [x] cobrança PIX sandbox no Mercado Pago pelo fluxo real `POST /api/v1/pagamentos`, sem simulação manual de confirmação;
- [x] painel ou consulta New Relic com métricas de consumo Mercado Pago do `oficina-billing-service`;
- [ ] consulta de Swagger/OpenAPI ou collection Postman atualizada.

## PDF Final

O PDF entregue no portal deve conter:

- [ ] nome e identificação dos participantes;
- [ ] links dos repositórios;
- [ ] link do vídeo;
- [ ] diagrama geral da arquitetura final, conforme o [Diagrama Geral da Arquitetura Final](../architecture/architecture-diagram.md);
- [ ] descrição da estratégia de Saga orquestrada pelo `oficina-os-service`;
- [ ] justificativa da divisão em `oficina-os-service`, `oficina-billing-service` e `oficina-execution-service`;
- [ ] justificativa das tecnologias usadas: Quarkus, AWS, PostgreSQL, DynamoDB, mensageria, Kubernetes, New Relic, SonarCloud e Mercado Pago;
- [ ] links para evidências de cobertura, Swagger/OpenAPI, pipelines, deploy e cobrança Mercado Pago sandbox;
- [ ] evidências de métricas de consumo Mercado Pago, incluindo volume de chamadas, desfecho, latência e valor total por status;
- [ ] observações sobre limitações conhecidas ou pendências aceitas para a apresentação.

## Diagrama Geral

Fonte canônica: [Diagrama Geral da Arquitetura Final](../architecture/architecture-diagram.md).

O diagrama final deve mostrar:

- usuários e chamadas REST públicas;
- `oficina-os-service`, `oficina-billing-service` e `oficina-execution-service`;
- `oficina-auth-lambda` quando usado para autenticação ou notificações;
- Amazon RDS PostgreSQL com databases `oficina_os` e `oficina_billing`;
- tabelas DynamoDB do `oficina-execution-service`;
- mensageria assíncrona com tópicos e filas por domínio;
- Kubernetes em Amazon EKS;
- Amazon ECR;
- API Gateway ou entrada pública adotada, conforme [Rotas públicas do API Gateway](../infrastructure/api-gateway-public-routes.md);
- New Relic OpenTelemetry Collector instalado por Helm no cluster;
- integração Mercado Pago;
- propagação de `correlationId`.

## Revisão Final

Antes de fechar a entrega:

- [x] comparar READMEs dos microsserviços com este checklist;
- [ ] validar links para OpenAPI, contratos, cobertura e pipelines;
- [ ] confirmar que os nomes de serviços, eventos, tópicos, bancos, secrets e variáveis seguem os contratos canônicos;
- [ ] conferir que o vídeo e o PDF usam os mesmos nomes canônicos dos contratos;
- [ ] confirmar que nenhuma evidência aponta para `oficina-app` como backend runtime atual;
- [ ] registrar neste documento a data final, participantes, links dos repositórios e link do vídeo.
