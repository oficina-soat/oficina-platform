# Documentação

Este diretório concentra a documentação normativa da plataforma em grupos temáticos.

## Arquitetura

- [Diagrama geral da arquitetura final](architecture/architecture-diagram.md)
- [Matriz de Ownership por Microsserviço](architecture/service-ownership.md)
- [Plano de Decomposição do oficina-app](architecture/oficina-app-decomposition.md)
- [Fluxos da Saga da Ordem de Serviço](architecture/saga-flows.md)
- [Padrão Outbox por Serviço](architecture/outbox-pattern.md)

## Infraestrutura

- [Conta, região e ambientes AWS](infrastructure/aws-environments.md)
- [Nomes de runtime, secrets e infraestrutura](infrastructure/infra-runtime-naming.md)
- [Rotas públicas do API Gateway](infrastructure/api-gateway-public-routes.md)
- [Escopo do Repositório Unificado de Infraestrutura](infrastructure/infrastructure-repository-scope.md)
- [Plano de migração para o repositório unificado de infraestrutura](infrastructure/infrastructure-migration-plan.md)
- [Estratégia de entrega dos manifestos Kubernetes](infrastructure/kubernetes-manifest-strategy.md)
- [Padrão de isolamento PostgreSQL no RDS compartilhado](infrastructure/rds-postgresql-isolation.md)
- [Proposta de Migrations PostgreSQL Decompostas](infrastructure/postgres-migrations-decomposition.md)
- [Padrão DynamoDB do oficina-execution-service](infrastructure/dynamodb-execution-service.md)

## Observabilidade

- [Padrão de Observabilidade Distribuída](observability/observability.md)
- [Validação local de observabilidade](observability/observability-local-validation.md)
- [Dashboards New Relic](observability/new-relic-dashboards.md)
- [Dashboard operacional dos microsserviços](observability/new-relic-dashboard-operational.json)
- [Dashboard da Saga e OS](observability/new-relic-dashboard-saga.json)
- [Dashboard Mercado Pago](observability/new-relic-dashboard-mercado-pago.json)
- [Policy de Alertas Mínimos](observability/new-relic-alert-policy.json)
- [Evidência dos Alertas Mínimos no New Relic](observability/new-relic-alerts-lab-evidence.md)
- [Evidência do Dashboard Mercado Pago no Lab](observability/mercado-pago-dashboard-lab-evidence.md)
- [Runbooks Operacionais Mínimos](observability/operational-runbooks.md)
- [Relatório D-NR-REM-005 — E2E no ambiente lab](observability/d-nr-rem-005-e2e-lab-report.md)

## Entrega e Validação

- [Histórico consolidado do roadmap](delivery/roadmap-history.md)
- [Enunciado Fase 4](delivery/Enunciado%20Fase%204.md)
- [Padrão BDD, Cobertura e Qualidade](delivery/bdd-testing.md)
- [Proteção da branch main dos microsserviços](delivery/github-branch-protection.md)
- [Evidência de Proteção da Branch main](delivery/github-branch-protection-evidence.md)
- [Checklist de Deploy Independente](delivery/independent-deploy-checklist.md)
- [Checklist Final de Entrega da Fase 4](delivery/phase-4-delivery-checklist.md)
- [Roteiro do Vídeo de Demonstração da Fase 4](delivery/video-demonstration-script.md)
- [Ferramentas de validação local](delivery/validation-tooling.md)
