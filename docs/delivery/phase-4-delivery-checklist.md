# Checklist Final de Entrega da Fase 4

## Objetivo

Consolidar os entregáveis finais da Fase 4, com os links e evidências que devem ser conferidos antes da entrega no portal.

Este checklist complementa o [Enunciado Fase 4](Enunciado%20Fase%204.md), o [ROADMAP](../../ROADMAP.md), o [Diagrama Geral da Arquitetura Final](../architecture/architecture-diagram.md), a [Matriz de Ownership por Microsserviço](../architecture/service-ownership.md), o [Padrão BDD, Cobertura e Qualidade](bdd-testing.md), a [ADR-009 - Estratégia de Saga Pattern](../../adr/ADR-009%20-%20Estratégia%20de%20Saga%20Pattern.md), a [ADR-010 - Estratégia de Divisão dos Microsserviços](../../adr/ADR-010%20-%20Estratégia%20de%20Divisão%20dos%20Microsserviços.md), a [ADR-011 - Estratégia de Persistência Poliglota por Microsserviço](../../adr/ADR-011%20-%20Estratégia%20de%20Persistência%20Poliglota%20por%20Microsserviço.md), a [ADR-012 - Estratégia de CI/CD e Deploy Independente](../../adr/ADR-012%20-%20Estratégia%20de%20CI%20CD%20e%20Deploy%20Independente.md), o [Checklist de Deploy Independente](independent-deploy-checklist.md), o [Padrão de Observabilidade Distribuída](../observability/observability.md), os [Runbooks Operacionais Mínimos](../observability/operational-runbooks.md) e as [Rotas públicas do API Gateway](../infrastructure/api-gateway-public-routes.md).

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
| `oficina-os-service` | `git@github.com:oficina-soat/oficina-os-service.git` | A preencher | A preencher | [OpenAPI canônica](../../contracts/openapi/oficina-os-service.yaml) | A preencher | A preencher | Pendente |
| `oficina-billing-service` | `git@github.com:oficina-soat/oficina-billing-service.git` | A preencher | A preencher | [OpenAPI canônica](../../contracts/openapi/oficina-billing-service.yaml) | A preencher | A preencher | Pendente |
| `oficina-execution-service` | `git@github.com:oficina-soat/oficina-execution-service.git` | A preencher | A preencher | [OpenAPI canônica](../../contracts/openapi/oficina-execution-service.yaml) | A preencher | A preencher | Pendente |
| `oficina-infra` | A preencher | A preencher | Não aplicável | Não aplicável | A preencher | A preencher | Pendente |
| `oficina-auth-lambda` | A preencher | A preencher | A preencher | [OpenAPI canônica](../../contracts/openapi/oficina-auth-lambda.yaml) | A preencher | Não aplicável | Pendente |

## Checklist por Microsserviço

Cada repositório de microsserviço deve possuir:

- [ ] código-fonte do serviço, sem dependência runtime do `oficina-app`;
- [ ] `README.md` com setup local, variáveis de ambiente, execução, testes, build, Docker, deploy e links de evidências;
- [ ] Dockerfile funcional;
- [ ] pipeline independente de CI/CD;
- [ ] deploy independente validado conforme o [Checklist de Deploy Independente](independent-deploy-checklist.md);
- [x] proteção da branch `main` com PR obrigatório e `service-ci-validate` exigido nos três microsserviços, conforme a [evidência remota dos Rulesets](github-branch-protection-evidence.md);
- [ ] testes unitários e de integração;
- [ ] evidência de cobertura mínima de 80%, conforme [Padrão BDD, Cobertura e Qualidade](bdd-testing.md);
- [ ] Quality Gate SonarCloud externo ou equivalente aprovado;
- [ ] link para Swagger, OpenAPI ou collection Postman atualizada;
- [ ] autenticação JWT configurada conforme contratos da suíte;
- [ ] tratamento de erros conforme [Contrato de Erros REST](../../contracts/error-model.md);
- [ ] idempotência conforme [Contrato de Idempotência](../../contracts/idempotency.md);
- [ ] propagação de `correlationId` em HTTP, eventos, logs e traces;
- [ ] documentação da Saga orquestrada pelo `oficina-os-service`, com links para [ADR-009](../../adr/ADR-009%20-%20Estratégia%20de%20Saga%20Pattern.md), [Fluxos da Saga da Ordem de Serviço](../architecture/saga-flows.md) e [Contrato de Saga do oficina-os-service](../../contracts/saga/oficina-os-saga-v1.md);
- [ ] evidência de manifests Kubernetes aplicáveis, conforme a [Estratégia de entrega dos manifestos Kubernetes](../infrastructure/kubernetes-manifest-strategy.md).
- [ ] runbooks aplicáveis revisados conforme os [Runbooks Operacionais Mínimos](../observability/operational-runbooks.md).

## Checklist de Domínio e Contratos

| Requisito | Evidência esperada | Link |
|---|---|---|
| Separação em três microsserviços | Repositórios independentes e responsabilidades alinhadas à [Matriz de Ownership por Microsserviço](../architecture/service-ownership.md). | A preencher |
| Banco próprio por microsserviço | `oficina_os`, `oficina_billing` e tabelas DynamoDB do `oficina-execution-service`. | A preencher |
| Banco SQL | PostgreSQL em RDS compartilhado com databases isolados, conforme [Padrão de isolamento PostgreSQL no RDS compartilhado](../infrastructure/rds-postgresql-isolation.md). | [Billing validado no PostgreSQL real, inclusive após restart](billing-postgresql-lab-evidence.md) |
| Banco NoSQL | DynamoDB do `oficina-execution-service`, conforme [Padrão DynamoDB do oficina-execution-service](../infrastructure/dynamodb-execution-service.md). | A preencher |
| Comunicação REST | Rotas aderentes ao [Contrato de APIs REST](../../contracts/Contrato%20de%20APIs%20REST.md), às OpenAPI dos três serviços e às [Rotas públicas do API Gateway](../infrastructure/api-gateway-public-routes.md). | A preencher |
| Mensageria assíncrona | Eventos e tópicos aderentes ao [Contrato de Eventos de Domínio](../../contracts/Contrato%20de%20Eventos%20de%20Domínio.md) e ao [Contrato de Tópicos de Mensageria](../../contracts/Contrato%20de%20Tópicos%20de%20Mensageria.md). | A preencher |
| Saga Pattern | Orquestração pelo `oficina-os-service`, com caminho feliz e falha compensada. | A preencher |
| Mercado Pago | Integração financeira documentada e evidência de cobrança PIX sandbox executada pelo `oficina-billing-service`, com `pagamentoId`, `transacaoExternaId`, referência externa do Mercado Pago, logs/traces por `correlationId` e evento financeiro correspondente. | [Cobrança PIX sandbox e correlação no New Relic concluídas](mercado-pago-sandbox-evidence.md) |
| Observabilidade | Logs estruturados, métricas, traces e dashboards mínimos conforme [Padrão de Observabilidade Distribuída](../observability/observability.md). | A preencher |
| Diagrama geral | Arquitetura final alinhada ao [Diagrama Geral da Arquitetura Final](../architecture/architecture-diagram.md). | [Diagrama Geral da Arquitetura Final](../architecture/architecture-diagram.md) |

## Cenários de Demonstração

Roteiro canônico: [Roteiro do Vídeo de Demonstração da Fase 4](video-demonstration-script.md).

O vídeo de até 15 minutos deve demonstrar:

- [ ] fluxo completo de uma OS passando por `oficina-os-service`, `oficina-billing-service` e `oficina-execution-service`;
- [ ] Saga finalizada com sucesso, incluindo eventos `ordemDeServicoCriada`, `diagnosticoFinalizado`, `orcamentoGerado`, `orcamentoAprovado`, `execucaoFinalizada`, `pagamentoConfirmado`, `ordemDeServicoEntregue` e `sagaFinalizadaComSucesso`;
- [ ] falha tratável com compensação, resultando em `sagaCompensada`;
- [ ] execução de testes e evidência de cobertura mínima de 80%;
- [ ] Quality Gate externo aprovado quando SonarCloud estiver configurado, ou pendência/evidência alternativa registrada;
- [ ] deploy automatizado de pelo menos um microsserviço em Kubernetes;
- [ ] rastreamento distribuído com `correlationId` em logs e traces;
- [x] cobrança PIX sandbox no Mercado Pago pelo fluxo real `POST /api/v1/pagamentos`, sem simulação manual de confirmação;
- [ ] painel ou consulta New Relic com métricas de consumo Mercado Pago do `oficina-billing-service`;
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

- [ ] comparar READMEs dos microsserviços com este checklist;
- [ ] validar links para OpenAPI, contratos, cobertura e pipelines;
- [ ] confirmar que os nomes de serviços, eventos, tópicos, bancos, secrets e variáveis seguem os contratos canônicos;
- [ ] conferir que o vídeo e o PDF usam os mesmos nomes canônicos dos contratos;
- [ ] confirmar que nenhuma evidência aponta para `oficina-app` como backend runtime da Fase 4;
- [ ] registrar neste documento a data final, participantes, links dos repositórios e link do vídeo.
