# Histórico consolidado do roadmap

## Finalidade

Este documento preserva o índice das entregas retiradas do backlog ativo. Ele não substitui ADRs, contratos ou relatórios de evidência: cada assunto aponta para sua fonte canônica, evitando que decisões e resultados sejam mantidos em versões concorrentes.

A cronologia textual anterior à sanitização continua disponível no histórico Git do `ROADMAP.md`. Novas tarefas concluídas devem ser incorporadas aqui de forma resumida e removidas do roadmap operacional.

## Decisões e fundações consolidadas

| Assunto | Fonte canônica |
|---|---|
| AWS como plataforma de nuvem | [ADR-001](../../adr/ADR-001%20-%20Escolha%20da%20Plataforma%20de%20Nuvem.md) |
| Bancos relacionais e persistência poliglota | [ADR-002](../../adr/ADR-002%20-%20Estratégia%20de%20Banco%20de%20Dados.md), [ADR-011](../../adr/ADR-011%20-%20Estratégia%20de%20Persistência%20Poliglota%20por%20Microsserviço.md) |
| Autenticação e notificações serverless | [ADR-003](../../adr/ADR-003%20-%20Serverless%20para%20Autenticação%20e%20Notificações.md) |
| Comunicação REST e assíncrona | [ADR-004](../../adr/ADR-004%20-%20Padrões%20de%20comunicação.md), [ADR-008](../../adr/ADR-008%20-%20Estratégia%20de%20Comunicação%20entre%20Microsserviços.md) |
| Plataforma central e governança multi-repositório | [ADR-006](../../adr/ADR-006%20-%20Criação%20do%20Repositório%20Central%20de%20Plataforma.md), [ADR-007](../../adr/ADR-007%20-%20Governança%20Multi-Repositório%20e%20Plataforma%20Compartilhada.md) |
| Saga orquestrada pelo serviço de OS | [ADR-009](../../adr/ADR-009%20-%20Estratégia%20de%20Saga%20Pattern.md), [Contrato da Saga](../../contracts/saga/oficina-os-saga-v1.md) |
| Divisão e ownership dos microsserviços | [ADR-010](../../adr/ADR-010%20-%20Estratégia%20de%20Divisão%20dos%20Microsserviços.md), [Matriz de ownership](../architecture/service-ownership.md) |
| CI/CD e deploy independente | [ADR-012](../../adr/ADR-012%20-%20Estratégia%20de%20CI%20CD%20e%20Deploy%20Independente.md) |
| Decomposição do monólito e infraestrutura unificada | [Plano de decomposição](../architecture/oficina-app-decomposition.md), [Plano de migração da infraestrutura](../infrastructure/infrastructure-migration-plan.md) |

## Entregas concluídas

| Grupo | Resultado consolidado | Identificadores rastreáveis |
|---|---|---|
| Contratos | OpenAPI dos três serviços, eventos e schemas, tópicos, erros, idempotência, ownership e Saga foram formalizados em [Contratos](../../contracts/). | Épico `A` anterior à adoção uniforme de IDs |
| Microsserviços | Baselines, domínios, APIs, persistência, seeds, Outbox, idempotência, mensageria, testes, BDD e CI/CD foram implementados nos três repositórios canônicos. | `B2-OS-DB-IMPL-001`, `B2-BILL-DB-IMPL-001`, `B2-BILL-EVENTSTORE-IMPL-001`, `B2-EXEC-DDB-IMPL-001`, `B2-IDEMP-IMPL-001`, `B2-MSG-IMPL-001` |
| Usuários e autenticação | Cadastro operacional no OS e sincronização da projeção de autenticação foram implementados e homologados. | `B2-OS-USERS-IMPL-001`, `B2-AUTH-USERS-IMPL-001`, `B2-AUTH-USERS-REM-001` |
| Infraestrutura | RDS, DynamoDB, mensageria, EKS, ECR, API Gateway, ambiente local e composição Kubernetes foram consolidados no `oficina-infra`. | `D-AWS-IMPL-001`, `D-INFRA-IMPL-001`, `D-K8S-OWNERSHIP-IMPL-001`, `D-AWS-REM-001`, `D-API-REM-001` |
| Observabilidade | Logs, métricas, traces, Saga, Mercado Pago, persistência, mensageria, dashboards, alertas e New Relic foram implementados e validados. | `D-NR-IMPL-001`, `D-OBS-IMPL-001` a `004`, `D-OBS-SAGA-IMPL-001`, `D-OBS-MP-COLLECT-IMPL-001`, `D-NR-REM-000` a `007`, `D-NR-EVID-001` |
| Operação e entrega | Runbooks, release, diagrama geral, roteiro do vídeo, proteção de branches, qualidade e checklist final foram preparados. | `D-OPS-IMPL-001`, `D-REL-IMPL-001`, `D-DIAG-IMPL-001`, `D-VIDEO-IMPL-001`, `B2-CI-REM-000` a `002`, `B2-GH-REM-001`, `B2-DB-MSG-EVID-001` |
| Simulação operacional | O simulador determinístico, os cenários, as proteções, os testes e a execução controlada no `lab` foram concluídos no `oficina-infra`. | `D-SIM-IMPL-001` a `004` |
| Diagramas por repositório | Os READMEs canônicos passaram a documentar em Mermaid a [infraestrutura do lab](https://github.com/oficina-soat/oficina-infra/blob/develop/README.md), [Clean Architecture e Saga do OS](https://github.com/oficina-soat/oficina-os-service/blob/develop/README.md), [fluxo financeiro](https://github.com/oficina-soat/oficina-billing-service/blob/develop/README.md), [catálogo, estoque e execução](https://github.com/oficina-soat/oficina-execution-service/blob/develop/README.md) e as [três Lambdas de autenticação](https://github.com/oficina-soat/oficina-auth-lambda/blob/develop/README.md). | `D-DIAG-INFRA-IMPL-001`, `D-DIAG-OS-IMPL-001`, `D-DIAG-BILLING-IMPL-001`, `D-DIAG-EXEC-IMPL-001`, `D-DIAG-AUTH-IMPL-001` |

## Evidências remotas canônicas

| Validação | Evidência |
|---|---|
| PostgreSQL do Billing | [Evidência PostgreSQL do Billing](billing-postgresql-lab-evidence.md) |
| PostgreSQL do OS | [Evidência PostgreSQL do OS](os-postgresql-lab-evidence.md) |
| DynamoDB do Execution | [Evidência DynamoDB do Execution](execution-dynamodb-lab-evidence.md) |
| Idempotência persistente | [Evidência de idempotência](idempotency-lab-evidence.md) |
| SNS, SQS e DLQ | [Evidência de mensageria](messaging-lab-evidence.md) |
| Usuários e autenticação | [Evidência da integração de usuários](auth-users-lab-evidence.md) |
| Mercado Pago sandbox | [Evidência Mercado Pago](mercado-pago-sandbox-evidence.md) |
| Quality Gate e proteção de branches | [Proteção de branches](github-branch-protection-evidence.md), [Checklist final](phase-4-delivery-checklist.md) |
| E2E e correlação distribuída | [Relatório E2E no lab](../observability/d-nr-rem-005-e2e-lab-report.md) |
| Saga | [Métricas e dashboard da Saga](../observability/saga-metrics-lab-evidence.md) |
| Métricas de pagamento | [Coleta das métricas de pagamento](../observability/payment-provider-metrics-lab-evidence.md) |
| Dashboard Mercado Pago | [Dashboard Mercado Pago](../observability/mercado-pago-dashboard-lab-evidence.md) |
| Alertas New Relic | [Alertas mínimos](../observability/new-relic-alerts-lab-evidence.md) |
| Dashboards New Relic | [Inventário de dashboards](../observability/new-relic-dashboards.md) |

## Critério de manutenção

Uma tarefa concluída deve deixar no máximo três informações neste histórico: identificador, resultado resumido e link para a fonte canônica. Explicações de decisões pertencem às ADRs; contratos executáveis pertencem a `contracts/`; procedimentos e evidências pertencem às áreas temáticas de `docs/`.
