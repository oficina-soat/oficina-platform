# Checklist Final de Entrega da Fase 4

## Objetivo

Consolidar os entregáveis finais da Fase 4, com os links e evidências que devem ser conferidos antes da entrega no portal.

Este checklist complementa o [Enunciado Fase 4](Enunciado%20Fase%204.md), o [ROADMAP](../ROADMAP.md), a [Matriz de Ownership por Microsserviço](service-ownership.md), o [Padrão BDD, Cobertura e Qualidade](bdd-testing.md), a [ADR-009 - Estratégia de Saga Pattern](../adr/ADR-009%20-%20Estratégia%20de%20Saga%20Pattern.md), a [ADR-010 - Estratégia de Divisão dos Microsserviços](../adr/ADR-010%20-%20Estratégia%20de%20Divisão%20dos%20Microsserviços.md), a [ADR-011 - Estratégia de Persistência Poliglota por Microsserviço](../adr/ADR-011%20-%20Estratégia%20de%20Persistência%20Poliglota%20por%20Microsserviço.md), a [ADR-012 - Estratégia de CI/CD e Deploy Independente](../adr/ADR-012%20-%20Estratégia%20de%20CI%20CD%20e%20Deploy%20Independente.md) e o [Padrão de Observabilidade Distribuída](observability.md).

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
| `oficina-os-service` | `git@github.com:oficina-soat/oficina-os-service.git` | A preencher | A preencher | [OpenAPI canônica](../contracts/openapi/oficina-os-service.yaml) | A preencher | A preencher | Pendente |
| `oficina-billing-service` | `git@github.com:oficina-soat/oficina-billing-service.git` | A preencher | A preencher | [OpenAPI canônica](../contracts/openapi/oficina-billing-service.yaml) | A preencher | A preencher | Pendente |
| `oficina-execution-service` | `git@github.com:oficina-soat/oficina-execution-service.git` | A preencher | A preencher | [OpenAPI canônica](../contracts/openapi/oficina-execution-service.yaml) | A preencher | A preencher | Pendente |
| `oficina-infra` | A preencher | A preencher | Não aplicável | Não aplicável | A preencher | A preencher | Pendente |
| `oficina-auth-lambda` | A preencher | A preencher | A preencher | Não aplicável | A preencher | Não aplicável | Pendente |

## Checklist por Microsserviço

Cada repositório de microsserviço deve possuir:

- [ ] código-fonte do serviço, sem dependência runtime do `oficina-app`;
- [ ] `README.md` com setup local, variáveis de ambiente, execução, testes, build, Docker, deploy e links de evidências;
- [ ] Dockerfile funcional;
- [ ] pipeline independente de CI/CD;
- [ ] proteção da branch `main` com PR obrigatório e checagens automáticas;
- [ ] testes unitários e de integração;
- [ ] evidência de cobertura mínima de 80%, conforme [Padrão BDD, Cobertura e Qualidade](bdd-testing.md);
- [ ] Quality Gate SonarCloud ou equivalente aprovado;
- [ ] link para Swagger, OpenAPI ou collection Postman atualizada;
- [ ] autenticação JWT configurada conforme contratos da suíte;
- [ ] tratamento de erros conforme [Contrato de Erros REST](../contracts/error-model.md);
- [ ] idempotência conforme [Contrato de Idempotência](../contracts/idempotency.md);
- [ ] propagação de `correlationId` em HTTP, eventos, logs e traces;
- [ ] documentação da Saga orquestrada pelo `oficina-os-service`, com links para [ADR-009](../adr/ADR-009%20-%20Estratégia%20de%20Saga%20Pattern.md), [Fluxos da Saga da Ordem de Serviço](saga-flows.md) e [Contrato de Saga do oficina-os-service](../contracts/saga/oficina-os-saga-v1.md);
- [ ] evidência de manifests Kubernetes aplicáveis, conforme a [Estratégia de entrega dos manifestos Kubernetes](kubernetes-manifest-strategy.md).

## Checklist de Domínio e Contratos

| Requisito | Evidência esperada | Link |
|---|---|---|
| Separação em três microsserviços | Repositórios independentes e responsabilidades alinhadas à [Matriz de Ownership por Microsserviço](service-ownership.md). | A preencher |
| Banco próprio por microsserviço | `oficina_os`, `oficina_billing` e tabelas DynamoDB do `oficina-execution-service`. | A preencher |
| Banco SQL | PostgreSQL em RDS compartilhado com databases isolados, conforme [Padrão de isolamento PostgreSQL no RDS compartilhado](rds-postgresql-isolation.md). | A preencher |
| Banco NoSQL | DynamoDB do `oficina-execution-service`, conforme [Padrão DynamoDB do oficina-execution-service](dynamodb-execution-service.md). | A preencher |
| Comunicação REST | Rotas aderentes ao [Contrato de APIs REST](../contracts/Contrato%20de%20APIs%20REST.md) e OpenAPI dos três serviços. | A preencher |
| Mensageria assíncrona | Eventos e tópicos aderentes ao [Contrato de Eventos de Domínio](../contracts/Contrato%20de%20Eventos%20de%20Domínio.md) e ao [Contrato de Tópicos de Mensageria](../contracts/Contrato%20de%20Tópicos%20de%20Mensageria.md). | A preencher |
| Saga Pattern | Orquestração pelo `oficina-os-service`, com caminho feliz e falha compensada. | A preencher |
| Mercado Pago | Integração financeira documentada no `oficina-billing-service`, conforme a [Referência API Mercado Pago](https://www.mercadopago.com.br/developers/pt/reference). | A preencher |
| Observabilidade | Logs estruturados, métricas, traces e dashboards mínimos conforme [Padrão de Observabilidade Distribuída](observability.md). | A preencher |

## Cenários de Demonstração

O vídeo de até 15 minutos deve demonstrar:

- [ ] fluxo completo de uma OS passando por `oficina-os-service`, `oficina-billing-service` e `oficina-execution-service`;
- [ ] Saga finalizada com sucesso, incluindo eventos `ordemDeServicoCriada`, `diagnosticoFinalizado`, `orcamentoGerado`, `orcamentoAprovado`, `execucaoFinalizada`, `pagamentoConfirmado`, `ordemDeServicoEntregue` e `sagaFinalizadaComSucesso`;
- [ ] falha tratável com compensação, resultando em `sagaCompensada`;
- [ ] execução de testes e evidência de cobertura mínima de 80%;
- [ ] Quality Gate aprovado;
- [ ] deploy automatizado de pelo menos um microsserviço em Kubernetes;
- [ ] rastreamento distribuído com `correlationId` em logs e traces;
- [ ] consulta de Swagger/OpenAPI ou collection Postman atualizada.

## PDF Final

O PDF entregue no portal deve conter:

- [ ] nome e identificação dos participantes;
- [ ] links dos repositórios;
- [ ] link do vídeo;
- [ ] diagrama geral da arquitetura final;
- [ ] descrição da estratégia de Saga orquestrada pelo `oficina-os-service`;
- [ ] justificativa da divisão em `oficina-os-service`, `oficina-billing-service` e `oficina-execution-service`;
- [ ] justificativa das tecnologias usadas: Quarkus, AWS, PostgreSQL, DynamoDB, mensageria, Kubernetes, Datadog, SonarCloud e Mercado Pago;
- [ ] links para evidências de cobertura, Swagger/OpenAPI, pipelines e deploy;
- [ ] observações sobre limitações conhecidas ou pendências aceitas para a apresentação.

## Diagrama Geral

O diagrama final deve mostrar:

- usuários e chamadas REST públicas;
- `oficina-os-service`, `oficina-billing-service` e `oficina-execution-service`;
- `oficina-auth-lambda` quando usado para autenticação ou notificações;
- Amazon RDS PostgreSQL com databases `oficina_os` e `oficina_billing`;
- tabelas DynamoDB do `oficina-execution-service`;
- mensageria assíncrona com tópicos e filas por domínio;
- Kubernetes em Amazon EKS;
- Amazon ECR;
- API Gateway ou entrada pública adotada;
- Datadog Agent ou collector;
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
