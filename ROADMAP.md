# Roadmap da Oficina SOAT

## Objetivo

Este arquivo é a fila operacional da plataforma. Ele contém somente trabalho ainda aberto, na ordem em que deve ser executado. Decisões arquiteturais, especificações, critérios permanentes e evidências de tarefas concluídas pertencem às ADRs, aos contratos e à documentação temática.

O histórico consolidado das entregas removidas deste backlog está no [Histórico do roadmap](docs/delivery/roadmap-history.md).

## Como interpretar

| Elemento | Significado |
|---|---|
| Ordem das seções e dos itens | Prioridade de execução |
| `[ ]` | Tarefa aberta |
| `[x]` | Tarefa concluída; deve ser transferida para o histórico na sanitização seguinte |
| `IMPL` | Implementação ou validação local |
| `REM` | Homologação ou validação remota |
| `EVID` | Registro de evidência externa ou material final |
| `FUT` | Candidata fora da sequência ativa; exige promoção explícita |

Quando o usuário solicitar a “próxima tarefa”, deve ser executado o primeiro item aberto da [Sequência ativa](#sequência-ativa). Itens futuros e de encerramento não antecipam essa ordem sem solicitação explícita.

## Referências canônicas

| Assunto | Fonte |
|---|---|
| Decisões arquiteturais | [ADRs](adr/) |
| Arquitetura e ownership | [Documentação de arquitetura](docs/architecture/) |
| APIs, eventos, tópicos, erros, idempotência e Saga | [Contratos](contracts/) |
| Infraestrutura, ambientes e nomes de runtime | [Documentação de infraestrutura](docs/infrastructure/) |
| Observabilidade e runbooks | [Documentação de observabilidade](docs/observability/) |
| Qualidade, deploy e entrega | [Documentação de entrega](docs/delivery/) |

## Sequência ativa

### Diagramas nos repositórios canônicos

Os diagramas devem ser escritos em Mermaid e incorporados diretamente ao `README.md` do respectivo repositório. Devem representar apenas componentes materializados ou contratos vigentes, usar nomes canônicos, renderizar corretamente no GitHub e apontar para documentos detalhados em vez de duplicá-los.

- [ ] `[D-DIAG-INFRA-IMPL-001]` Adicionar ao `README.md` do `oficina-infra` a arquitetura do ambiente `lab`: API Gateway, Lambdas, VPC Link e balanceamento, EKS e microsserviços, RDS com databases isolados, DynamoDB, SNS/SQS/DLQ, ECR, Secrets Manager e New Relic. Diferenciar visualmente infraestrutura AWS, workloads Kubernetes, persistência, mensageria e observabilidade sem expor dados sensíveis.
- [ ] `[D-DIAG-OS-IMPL-001]` Adicionar ao `README.md` do `oficina-os-service` a visão do serviço: API REST, aplicação e domínio, PostgreSQL, Outbox/idempotência, orquestração da Saga, SNS/SQS e ownership de Cliente, Veículo, OS e Saga.
- [ ] `[D-DIAG-BILLING-IMPL-001]` Adicionar ao `README.md` do `oficina-billing-service` a visão do fluxo financeiro: APIs de orçamento e pagamento, aplicação e domínio, PostgreSQL, Outbox/idempotência, eventos e Mercado Pago, distinguindo respostas do provedor de eventos internos.
- [ ] `[D-DIAG-EXEC-IMPL-001]` Adicionar ao `README.md` do `oficina-execution-service` a visão de catálogo, estoque e execução: APIs, aplicação e domínio, tabelas DynamoDB, Outbox/idempotência, SNS/SQS e integração assíncrona com a Saga do OS.
- [ ] `[D-DIAG-AUTH-IMPL-001]` Revisar os diagramas Mermaid do `README.md` do `oficina-auth-lambda`: `auth-lambda`, `auth-sync-lambda`, `notificacao-lambda`, API Gateway, PostgreSQL da autenticação, eventos de usuários, issuer e JWKS, preservando o cadastro operacional como responsabilidade do OS.

## Candidatas futuras

Estes itens não pertencem à sequência ativa. A promoção deve mover o item para a posição desejada na seção anterior e substituir o prefixo `FUT` por um identificador do épico correspondente.

- [ ] `[FUT-AUTH-DB-001]` Isolar a autenticação em `oficina_auth` e `oficina_auth_user`: Terraform e bootstrap, secret exclusivo, configuração das Lambdas, migração segura de credenciais e tokens, privilégio mínimo, rollback e validação de login/sincronização. O cadastro operacional permanece no `oficina-os-service`; somente a projeção de login e as credenciais pertencem à autenticação.

## Encerramento final

Estes itens permanecem deliberadamente no fim e só devem ser executados quando os materiais finais estiverem disponíveis.

- [ ] `[D-DELIVERY-EVID-001]` Registrar data da entrega da Fase 4, participantes, links dos repositórios e link do vídeo no [Checklist final da Fase 4](docs/delivery/phase-4-delivery-checklist.md) ou no documento de entrega.
- [ ] `[D-VIDEO-EVID-001]` Registrar as evidências finais do vídeo de demonstração após a gravação e a homologação do ambiente.
