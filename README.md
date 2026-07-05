# oficina-platform
Seu objetivo é centralizar a governança da plataforma, fornecendo uma visão unificada da arquitetura e servindo como fonte oficial para contratos, padrões e decisões compartilhadas.

## Repositórios da plataforma

Os microsserviços canônicos da plataforma possuem repositórios independentes na mesma suíte:

| Repositório | Responsabilidade |
| --- | --- |
| `../oficina-os-service` | Gestão da Ordem de Serviço, cadastros principais e orquestração da Saga. |
| `../oficina-billing-service` | Cobrança, pagamentos e integrações financeiras. |
| `../oficina-execution-service` | Catálogo técnico de peças e serviços, diagnóstico, execução, estoque operacional e finalização do serviço. |

Os repositórios remotos verificados seguem a organização `oficina-soat` no GitHub:

- `git@github.com:oficina-soat/oficina-os-service.git`
- `git@github.com:oficina-soat/oficina-billing-service.git`
- `git@github.com:oficina-soat/oficina-execution-service.git`

Este repositório continua sendo a fonte normativa para ADRs, contratos, OpenAPI, eventos, padrões e artefatos compartilhados. Código de aplicação, pipelines específicos e manifestos próprios permanecem nos repositórios dos microsserviços.

## Roadmap

O planejamento incremental da plataforma, incluindo lacunas restantes e backlog orientado a agentes, está documentado em [ROADMAP.md](ROADMAP.md).

## Governança operacional

- [Conta, região e ambientes AWS](docs/aws-environments.md)
- [Nomes de runtime, secrets e infraestrutura](docs/infra-runtime-naming.md)
- [Rotas públicas do API Gateway](docs/api-gateway-public-routes.md)
- [Escopo do repositório unificado de infraestrutura](docs/infrastructure-repository-scope.md)
- [Plano de migração para o repositório unificado de infraestrutura](docs/infrastructure-migration-plan.md)
- [Padrão de isolamento PostgreSQL no RDS compartilhado](docs/rds-postgresql-isolation.md)
- [Padrão de observabilidade distribuída](docs/observability.md)
- [Padrão Outbox por serviço](docs/outbox-pattern.md)
- [Padrão BDD, cobertura e qualidade](docs/bdd-testing.md)
- [Fluxos da Saga da Ordem de Serviço](docs/saga-flows.md)
- [Padrão DynamoDB do oficina-execution-service](docs/dynamodb-execution-service.md)
- [Checklist de deploy independente](docs/independent-deploy-checklist.md)
- [Checklist final de entrega da Fase 4](docs/phase-4-delivery-checklist.md)
