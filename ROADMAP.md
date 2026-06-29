# ROADMAP.md

## Objetivo

Orientar a evolução do `oficina-platform` como fonte oficial de governança da arquitetura, contratos e padrões compartilhados da plataforma de oficina mecânica.

Este roadmap foi estruturado para facilitar o trabalho incremental com agentes, reduzindo ambiguidade sobre prioridades, artefatos esperados, dependências e critérios de pronto.

---

## Estado atual da plataforma

### Definições já consolidadas

- Plataforma de nuvem definida como AWS.
- Repositório `oficina-platform` definido como fonte central de arquitetura, contratos e padrões.
- Governança multi-repositório definida, mantendo microsserviços em repositórios independentes.
- Divisão inicial definida em três microsserviços, com repositórios independentes criados na suíte:
  - `oficina-os-service`;
  - `oficina-billing-service`;
  - `oficina-execution-service`.
- Destino do `oficina-app` definido: o código existente será decomposto e migrado para os três novos microsserviços conforme suas responsabilidades, sem manter o `oficina-app` como backend monolítico da Fase 4.
- Destino do `oficina-auth-lambda` definido: apesar do nome, o repositório continuará existindo como componente serverless independente responsável pelos fluxos de autenticação e emissão de notificações conforme a ADR-003, sem ser absorvido pelos três microsserviços.
- Comunicação definida como híbrida, combinando APIs REST e mensageria assíncrona.
- Saga Pattern definido como orquestrado pelo `oficina-os-service`.
- Persistência poliglota definida por microsserviço.
- Estratégia de PostgreSQL definida para a Fase 4 como uma única instância Amazon RDS compartilhada, com databases independentes por microsserviço relacional:
  - `oficina_os`, acessado apenas pelo `oficina-os-service`;
  - `oficina_billing`, acessado apenas pelo `oficina-billing-service`.
- Uso de Amazon DynamoDB definido para o `oficina-execution-service`, atendendo ao requisito de banco não relacional, com padrão de tabelas, chaves, índices, seeds e streams registrado em [Padrão DynamoDB do oficina-execution-service](docs/dynamodb-execution-service.md).
- Estratégia de CI/CD independente definida por microsserviço.
- Conta, região e ambiente AWS definidos em [Conta, região e ambientes AWS](docs/aws-environments.md):
  - conta AWS parametrizada por `AWS_ACCOUNT_ID`, sem número fixo canônico;
  - região `us-east-1`;
  - ambiente `lab`;
  - infraestrutura compartilhada `eks-lab`.
- Decisão de separar o código de infraestrutura no repositório unificado `oficina-infra`, consolidando as responsabilidades hoje distribuídas entre `oficina-infra-db` e `oficina-infra-k8s`, conforme [Escopo do Repositório Unificado de Infraestrutura](docs/infrastructure-repository-scope.md).
- Enunciado da Fase 4 incluído como referência normativa em [Enunciado Fase 4](docs/Enunciado%20Fase%204.md).
- Contratos fundamentais criados para:
  - APIs REST;
  - eventos de domínio;
  - tópicos de mensageria;
  - estados da Ordem de Serviço.

---

## Definições que ainda precisam ser fechadas

As ADRs e contratos fundamentais estão suficientes para iniciar a decomposição dos microsserviços, mas ainda há definições importantes para tornar o trabalho dos agentes mais eficiente e reduzir decisões implícitas durante a implementação.

### 1. Contratos OpenAPI formais

**Situação atual:** há um contrato REST em Markdown com rotas e responsabilidades principais e já existem especificações OpenAPI iniciais para os três microsserviços.

**Definição faltante:** revisar continuamente as especificações OpenAPI para manter coerência com o contrato REST, com o modelo de erros e com as regras de idempotência.

**Artefatos sugeridos:**

```text
contracts/openapi/oficina-os-service.yaml
contracts/openapi/oficina-billing-service.yaml
contracts/openapi/oficina-execution-service.yaml
```

**Critério de pronto:** cada arquivo deve conter endpoints, schemas de request/response, códigos HTTP esperados, erros padronizados, autenticação e exemplos mínimos, sem divergência em relação ao [Contrato de APIs REST](contracts/Contrato%20de%20APIs%20REST.md).

### 2. Schemas formais dos eventos

**Situação atual:** existem arquivos Markdown individuais para eventos e schemas JSON iniciais em [contracts/events/schemas/](contracts/events/schemas/).

**Definição faltante:** evoluir os schemas conforme novos campos forem estabilizados nos contratos REST, Saga e implementações dos microsserviços, preservando compatibilidade ou incrementando `eventVersion` quando houver mudança incompatível.

**Artefatos sugeridos:**

```text
contracts/events/schemas/<nome-do-evento>.schema.json
```

**Critério de pronto:** cada evento deve possuir `eventType`, `eventVersion`, `producer`, `aggregateId`, `payload` tipado, exemplo válido e vínculo com o tópico correspondente.

### 3. Normalização entre eventos e tópicos

**Situação atual:** eventos e tópicos foram normalizados em torno dos nomes lógicos camelCase dos eventos e tópicos kebab-case por domínio do produtor.

**Decisão tomada:** os nomes lógicos camelCase dos arquivos em [contracts/events/](contracts/events/) são a referência para `eventType`; os tópicos usam kebab-case no domínio do produtor; e os produtores devem usar os nomes canônicos dos microsserviços (`oficina-os-service`, `oficina-billing-service` e `oficina-execution-service`).

**Definição faltante:** manter a tabela canônica `evento -> tópico -> produtor -> consumidores` como referência para criação dos schemas JSON e para implementação dos produtores/consumidores.

**Critério de pronto:** todo evento fundamental deve possuir exatamente um tópico canônico, um produtor compatível com os microsserviços definidos e consumidores explícitos quando houver integração entre serviços.

### 4. Catálogo de responsabilidades por microsserviço

**Situação atual:** as responsabilidades principais estão definidas nas ADRs e contratos, e a matriz operacional única para agentes foi criada em [Matriz de Ownership por Microsserviço](docs/service-ownership.md).

**Definição faltante:** manter a matriz de ownership atualizada sempre que APIs, eventos, bancos, jobs/outbox, integrações externas ou limites de responsabilidade forem alterados.

**Artefato sugerido:**

```text
docs/service-ownership.md
```

**Critério de pronto:** um agente deve conseguir identificar rapidamente onde implementar uma regra sem consultar todas as ADRs.

### 5. Plano de decomposição do `oficina-app`

**Situação atual:** o plano inicial de decomposição foi criado em [Plano de Decomposição do oficina-app](docs/oficina-app-decomposition.md), usando o `oficina-app` como referência de código, testes e seed funcional para a arquitetura de microsserviços da Fase 4.

**Decisão:** o código do `oficina-app` será dividido entre `oficina-os-service`, `oficina-billing-service` e `oficina-execution-service`, respeitando os limites de responsabilidade, contratos REST, eventos, bancos e regras de ownership definidos neste repositório.

Também foi definido que:

- `Pessoa` e `Usuario` pertencem ao `oficina-os-service`;
- não será criada biblioteca `common` compartilhada entre os microsserviços;
- não haverá migração histórica de dados;
- a massa inicial da Fase 4 será criada por seed limpo, reaproveitando os dados funcionais do `import.sql` atual do `oficina-app`;
- não há front-end ou consumidores externos a migrar neste cenário;
- após a decomposição, o `oficina-app` fica apenas como referência histórica.

**Artefato:**

```text
docs/oficina-app-decomposition.md
```

**Definição faltante:** detalhar, durante a implementação dos microsserviços, os mapeamentos finais de classes, testes e seeds executáveis conforme cada repositório evoluir.

As decisões para as baselines PostgreSQL decompostas de `oficina-os-service` e `oficina-billing-service` foram registradas em [Proposta de Migrations PostgreSQL Decompostas](docs/postgres-migrations-decomposition.md).

**Critério de pronto:** cada componente relevante do `oficina-app` deve possuir destino explícito, estratégia de seed ou descarte, e critério de retenção apenas como referência.

### 6. Fluxos da Saga em formato executável para implementação

**Situação atual:** a estratégia de Saga está documentada conceitualmente na ADR-009, os fluxos implementáveis foram detalhados em [Fluxos da Saga da Ordem de Serviço](docs/saga-flows.md) e o contrato operacional foi criado em [Contrato de Saga do oficina-os-service](contracts/saga/oficina-os-saga-v1.md).

**Definição faltante:** evoluir os fluxos conforme a implementação dos microsserviços estabilizar payloads, endpoints auxiliares ou novas compensações.

**Artefatos sugeridos:**

```text
docs/saga-flows.md
contracts/saga/oficina-os-saga-v1.md
```

**Critério de pronto:** cada etapa deve informar acionador, serviço responsável, operação síncrona ou assíncrona, evento de sucesso, evento de falha e compensação.

### 7. Padrões técnicos para repositórios de microsserviços

**Situação atual:** há decisões sobre CI/CD, deploy independente e governança; o template base Quarkus foi criado em [Template Quarkus de Microsserviço](templates/quarkus-service/README.md); o pipeline padrão foi criado em [Template GitHub Actions para Microsserviços](templates/github-actions/README.md); os manifests Kubernetes base foram criados em [Template Kubernetes Base](templates/kubernetes/base/README.md); e o padrão DynamoDB do `oficina-execution-service` foi definido em [Padrão DynamoDB do oficina-execution-service](docs/dynamodb-execution-service.md).

**Definição faltante:** evoluir os templates com documentação local específica quando esses padrões forem fechados nos repositórios dos microsserviços.

**Artefatos sugeridos:**

```text
templates/quarkus-service/
templates/github-actions/service-ci.yml
templates/github-actions/open-pr-to-main.yml
templates/quarkus-service/Dockerfile
templates/kubernetes/base/
```

**Critério de pronto:** um agente deve conseguir criar um novo microsserviço consistente usando o template sem reinterpretar a arquitetura.

### 8. Repositório unificado de infraestrutura

**Situação atual:** os repositórios `oficina-infra-db` e `oficina-infra-k8s` existem como referências separadas para banco de dados e Kubernetes, e o repositório unificado `oficina-infra` já existe como destino canônico da Fase 4.

**Definição fechada:** o escopo e as responsabilidades do `oficina-infra` foram definidos em [Escopo do Repositório Unificado de Infraestrutura](docs/infrastructure-repository-scope.md).

**Critério de pronto:** o novo repositório deve concentrar os artefatos de infraestrutura compartilhada da suíte, mantendo nomes de ambientes, secrets, variáveis, manifests, migrations e padrões de deploy compatíveis com os contratos e decisões deste repositório.

### 9. Isolamento dos bancos PostgreSQL na Fase 4

**Situação atual:** o enunciado exige banco de dados próprio por microsserviço, pelo menos um banco SQL, pelo menos um banco NoSQL e proíbe acesso direto ao banco de outro serviço.

**Decisão:** para reduzir custo e complexidade operacional na Fase 4, `oficina-os-service` e `oficina-billing-service` usarão uma única instância Amazon RDS for PostgreSQL compartilhada, mas com databases independentes, usuários independentes, credenciais independentes e migrações independentes por serviço.

**Configuração canônica:**

```text
Amazon RDS for PostgreSQL
+-- database: oficina_os
|   +-- owner: oficina_os_user
+-- database: oficina_billing
    +-- owner: oficina_billing_user

Amazon DynamoDB
+-- tabelas do oficina-execution-service
```

**Restrições obrigatórias:**

- O `oficina-os-service` não pode acessar o database `oficina_billing`.
- O `oficina-billing-service` não pode acessar o database `oficina_os`.
- Nenhum serviço pode executar joins, queries ou migrations sobre estruturas pertencentes a outro microsserviço.
- A comunicação entre serviços deve ocorrer exclusivamente por APIs REST e eventos de domínio.
- O `oficina-execution-service` permanece em Amazon DynamoDB para atender ao requisito de banco não relacional.

**Critério de pronto:** a infraestrutura deve criar databases, usuários, permissões, secrets e connection strings separados por microsserviço, demonstrando ownership e isolamento lógico mesmo com instância RDS compartilhada.

### 10. Padrão de observabilidade distribuída

**Situação atual:** o padrão operacional foi criado em [Padrão de Observabilidade Distribuída](docs/observability.md), consolidando logs estruturados, métricas, traces, health checks, dashboards e alertas no Datadog, além da propagação de `correlationId`.

**Definição faltante:** manter o padrão coerente com os manifests Kubernetes, pipelines, instalação do Datadog Agent ou collector no repositório de infraestrutura e implementações dos microsserviços conforme esses artefatos forem evoluídos.

**Artefato sugerido:**

```text
docs/observability.md
```

**Critério de pronto:** todos os serviços devem expor o mesmo conjunto mínimo de sinais e propagar `correlationId` em HTTP, eventos e logs.

### 11. Padrão de erros e idempotência

**Situação atual:** existem contratos formais para respostas de erro REST e idempotência, referenciados pelo contrato REST e refletidos nas especificações OpenAPI iniciais.

**Definição faltante:** manter as OpenAPI e as implementações dos microsserviços coerentes com o formato único de erro, os códigos HTTP, as chaves de idempotência, o tratamento de duplicidade e o comportamento esperado para consumidores de eventos.

**Artefatos sugeridos:**

```text
contracts/error-model.md
contracts/idempotency.md
```

**Critério de pronto:** APIs e consumidores devem ter comportamento previsível em retry, duplicidade, timeout e conflito de estado.

### 12. BDD, cobertura e qualidade de código

**Situação atual:** o padrão BDD, cobertura e qualidade foi definido em [Padrão BDD, Cobertura e Qualidade](docs/bdd-testing.md), com Cucumber JVM, JUnit Platform, JaCoCo com mínimo de 80% e Quality Gate SonarCloud obrigatório no CI.

**Definição faltante:** implementar o padrão nos três repositórios de microsserviços, criando os cenários BDD, evidências de cobertura e configuração real do SonarCloud conforme cada serviço evoluir.

**Artefatos sugeridos:**

```text
docs/bdd-testing.md
templates/quarkus-service/src/test/resources/features/
templates/github-actions/service-ci.yml
```

**Critério de pronto:** os três microsserviços devem executar testes unitários, integração e contrato no CI; pelo menos um fluxo completo da OS deve ter cenário BDD automatizado; cada serviço deve publicar evidência de cobertura mínima de 80%; e o pipeline deve falhar quando o Quality Gate configurado não for atendido.

### 13. Evidências e entregáveis finais da Fase 4

**Situação atual:** o checklist consolidado dos entregáveis finais foi criado em [Checklist Final de Entrega da Fase 4](docs/phase-4-delivery-checklist.md), cobrindo evidências por repositório, cobertura, Swagger/OpenAPI, vídeo, PDF, diagrama, Saga, deploy e observabilidade.

**Definição faltante:** preencher os links reais de cobertura, Swagger/OpenAPI, pipelines, vídeo, PDF e diagrama final conforme os repositórios de microsserviço e infraestrutura forem concluídos.

**Artefatos sugeridos:**

```text
docs/phase-4-delivery-checklist.md
docs/architecture-diagram.md
```

**Critério de pronto:** cada repositório de microsserviço deve possuir README com link de cobertura e Swagger/OpenAPI; a plataforma deve possuir checklist final da entrega; e o PDF/vídeo devem demonstrar fluxo completo da OS, Saga com falha/compensação, deploy automatizado e observabilidade distribuída.

### 14. Manifestos Kubernetes como entregável por microsserviço

**Situação atual:** a governança da suíte definiu o repositório `oficina-infra` como destino canônico da infraestrutura executável, mas o enunciado da Fase 4 lista manifestos Kubernetes como entregável dos repositórios de microsserviço.

**Definição faltante:** decidir se os manifestos Kubernetes específicos de cada serviço serão copiados para os repositórios dos microsserviços, mantidos apenas no `oficina-infra` com links e evidências nos READMEs dos serviços, ou mantidos em ambos com uma fonte canônica explícita.

**Opção recomendada:** manter `oficina-infra` como fonte canônica de deploy e registrar nos READMEs dos microsserviços links diretos para os manifestos aplicáveis, evitando divergência operacional. Se a avaliação exigir manifestos dentro de cada repositório, copiar versões de referência e documentar que o deploy real continua no `oficina-infra`.

**Artefatos sugeridos:**

```text
../oficina-infra/
templates/kubernetes/base/
README.md dos microsserviços
```

**Critério de pronto:** a entrega deve demonstrar onde estão os manifestos Kubernetes de cada serviço, qual repositório é a fonte canônica de deploy e como evitar divergência entre cópias ou referências.

---

## Priorização recomendada

### Marco 1 — Contratos implementáveis

**Objetivo:** transformar contratos conceituais em artefatos diretamente utilizáveis por agentes e pipelines.

**Entregas:**

1. Normalizar eventos e tópicos.
2. Criar schemas JSON dos eventos fundamentais.
3. Revisar OpenAPI inicial dos três microsserviços contra erros padronizados e idempotência.
4. Definir modelo de erro e idempotência.

**Resultado esperado:** agentes conseguem gerar código de controllers, DTOs, produtores e consumidores com menor ambiguidade.

### Marco 2 — Blueprint dos microsserviços

**Objetivo:** criar a base reutilizável para implementação dos repositórios independentes.

**Pré-condição atendida:** os repositórios `oficina-os-service`, `oficina-billing-service` e `oficina-execution-service` já existem como repositórios independentes da suíte.

**Entregas:**

1. Criar matriz de ownership por serviço.
2. Criar plano de decomposição do `oficina-app` para os três microsserviços.
3. Criar template Quarkus de microsserviço.
4. Criar pipeline padrão de CI/CD.
5. Criar manifests Kubernetes base.
6. Criar documentação local padrão para cada repositório.
7. Definir o escopo do novo repositório unificado de infraestrutura que substituirá a separação entre `oficina-infra-db` e `oficina-infra-k8s`.
8. Criar padrão de provisionamento para o RDS PostgreSQL compartilhado com databases, usuários, secrets e migrations isolados por microsserviço.

**Resultado esperado:** agentes conseguem criar ou evoluir repositórios de serviço seguindo o mesmo padrão.

### Marco 3 — Implementação dos microsserviços da Fase 4

**Objetivo:** transformar os contratos e planos já definidos em baselines executáveis nos três repositórios de microsserviços.

**Entregas:**

1. Criar baseline Quarkus nos repositórios `oficina-os-service`, `oficina-billing-service` e `oficina-execution-service`, usando [Template Quarkus de Microsserviço](templates/quarkus-service/README.md), [Template GitHub Actions para Microsserviços](templates/github-actions/README.md) e [Template Kubernetes Base](templates/kubernetes/base/README.md).
2. Copiar e adaptar o domínio de atendimento do `oficina-app` para o `oficina-os-service`, conforme [Plano de Decomposição do oficina-app](docs/oficina-app-decomposition.md).
3. Copiar e adaptar o domínio de peças, serviços e estoque do `oficina-app` para o `oficina-execution-service`, reimplementando a persistência em DynamoDB conforme [Padrão DynamoDB do oficina-execution-service](docs/dynamodb-execution-service.md).
4. Criar a implementação nova do `oficina-billing-service`, sem origem equivalente no `oficina-app`, a partir do [Contrato de APIs REST](contracts/Contrato%20de%20APIs%20REST.md), da [OpenAPI do oficina-billing-service](contracts/openapi/oficina-billing-service.yaml), dos eventos e da [Matriz de Ownership por Microsserviço](docs/service-ownership.md).
5. Separar seeds e migrations executáveis por serviço, preservando seed limpo e isolamento de banco conforme [Proposta de Migrations PostgreSQL Decompostas](docs/postgres-migrations-decomposition.md) e [Padrão de isolamento PostgreSQL no RDS compartilhado](docs/rds-postgresql-isolation.md).
6. Implementar producers, consumers, Outbox, idempotência, tratamento de erros, autenticação JWT e propagação de `correlationId` nos três microsserviços.
7. Criar testes unitários, de contrato, de integração e BDD por serviço, incluindo validação mínima das OpenAPI, eventos, fluxos de Saga e cobertura mínima de 80%.
8. Aplicar os workflows de CI/CD nos três repositórios de microsserviços, com build, testes, relatório de cobertura, Quality Gate SonarCloud ou equivalente, publicação de imagem e deploy automatizado em Kubernetes.

**Resultado esperado:** os três microsserviços deixam de ser placeholders e passam a executar as capacidades mínimas da Fase 4, sem manter dependência runtime do `oficina-app`.

### Marco 4 — Saga e integração distribuída

**Objetivo:** detalhar o fluxo distribuído principal e seus cenários alternativos.

**Entregas:**

1. Documentar Saga principal da Ordem de Serviço.
2. Documentar compensações e timeouts.
3. Definir contratos de comandos/eventos usados pela Saga.
4. Definir estratégia de testes de integração entre serviços.
5. Definir cenário BDD do fluxo completo da OS passando por OS, Billing e Execution, incluindo ao menos um caso de falha com compensação.

**Resultado esperado:** agentes conseguem implementar o fluxo distribuído sem decisões ad hoc sobre sequência, compensação ou ownership.

### Marco 5 — Operação e entrega

**Objetivo:** fechar requisitos de execução em Kubernetes, observabilidade e governança operacional.

**Entregas:**

1. Documentar padrão de observabilidade.
2. Definir dashboards e alertas mínimos.
3. Definir runbooks operacionais.
4. Criar checklist de release por serviço.
5. Criar checklist de revisão de contratos.
6. Criar checklist dos entregáveis finais da Fase 4, incluindo evidências de cobertura, Swagger/OpenAPI, vídeo, PDF e diagrama de arquitetura.

**Resultado esperado:** a plataforma fica pronta para operação, demonstração e evolução controlada.

---

## Backlog orientado a agentes

### Épico A — Contratos

- [x] Revisar divergências entre eventos de domínio e tópicos de mensageria.
- [x] Criar tabela canônica `evento -> tópico -> produtor -> consumidores`.
- [x] Criar schemas JSON para eventos fundamentais.
- [x] Criar OpenAPI do `oficina-os-service`.
- [x] Criar OpenAPI do `oficina-billing-service`.
- [x] Criar OpenAPI do `oficina-execution-service`.
- [x] Criar contrato de erros REST.
- [x] Criar contrato de idempotência.

### Épico B — Microsserviços

- [x] Criar repositórios independentes `oficina-os-service`, `oficina-billing-service` e `oficina-execution-service`.
- [x] Criar matriz de ownership por microsserviço.
- [x] Criar plano de decomposição do `oficina-app` por componente e microsserviço destino.
- [x] Definir estratégia de migração ou descarte do `oficina-app` após a decomposição.
- [x] Criar proposta inicial de migrations PostgreSQL decompostas para OS e Billing.
- [x] Criar template base Quarkus.
- [x] Criar padrão de configuração por ambiente.
- [x] Criar padrão de health checks.
- [x] Criar padrão de migrations para PostgreSQL.
- [x] Criar padrão de tabelas/streams para DynamoDB.
- [x] Criar padrão Outbox por serviço.
- [x] Definir escopo e responsabilidades do novo repositório unificado de infraestrutura.
- [x] Criar padrão de isolamento para `oficina_os` e `oficina_billing` no RDS PostgreSQL compartilhado.

### Épico B2 — Implementações da Fase 4

- [x] Criar baseline Quarkus executável em `oficina-os-service`, com estrutura, dependências, health checks, configuração por ambiente, autenticação JWT, erro padronizado, idempotência e observabilidade.
- [x] Criar baseline Quarkus executável em `oficina-billing-service`, com estrutura, dependências, health checks, configuração por ambiente, autenticação JWT, erro padronizado, idempotência e observabilidade.
- [x] Criar baseline Quarkus executável em `oficina-execution-service`, com estrutura, dependências, health checks, configuração por ambiente, autenticação JWT, erro padronizado, idempotência e observabilidade.
- [x] Criar diretivas locais para agentes, README operacional e backlog local nos três repositórios de microsserviços antes de iniciar a migração de domínio.
- [x] Copiar e adaptar para `oficina-os-service` o domínio de Pessoa, Usuário, Cliente, Veículo e Ordem de Serviço do `oficina-app`, conforme [Plano de Decomposição do oficina-app](docs/oficina-app-decomposition.md).
- [x] Copiar e adaptar para `oficina-os-service` controllers, presenters, DTOs, validações, testes e seed de atendimento do `oficina-app`, alinhando rotas com a [OpenAPI do oficina-os-service](contracts/openapi/oficina-os-service.yaml).
- [x] Criar migrations e seed limpo do `oficina-os-service` para o database `oficina_os`, preservando isolamento de acesso e ownership.
- [x] Implementar no `oficina-os-service` a orquestração da Saga, histórico de estados, Outbox, publicação dos eventos de OS e consumo dos eventos de Billing e Execution.
- [x] Copiar e adaptar para `oficina-execution-service` o domínio de catálogo técnico, peças, serviços e estoque do `oficina-app`, conforme [Plano de Decomposição do oficina-app](docs/oficina-app-decomposition.md).
- [x] Reimplementar no `oficina-execution-service` a persistência de catálogo, estoque, execução, Outbox e idempotência em DynamoDB, sem migrar diretamente adapters PostgreSQL/Panache do `oficina-app`.
- [x] Implementar no `oficina-execution-service` diagnóstico, execução, reparo, movimentação de estoque, producers e consumers definidos nos contratos de eventos.
- [x] Criar seed limpo do `oficina-execution-service` para tabelas DynamoDB, reaproveitando apenas os dados funcionais aplicáveis do `import.sql` do `oficina-app`.
- [ ] Criar do zero no `oficina-billing-service` o domínio de orçamento, aprovação, recusa, pagamento e integração financeira, porque não há módulo equivalente no `oficina-app`.
- [ ] Criar migrations e seed limpo do `oficina-billing-service` para o database `oficina_billing`, preservando isolamento de acesso e ownership.
- [ ] Implementar no `oficina-billing-service` cálculo e snapshot financeiro de itens, fluxo de aprovação/recusa, pagamento, producers e consumers definidos nos contratos de eventos.
- [ ] Implementar integração de pagamentos com Mercado Pago no `oficina-billing-service`, incluindo configuração, adapter, tratamento de falhas, testes e documentação operacional.
- [ ] Implementar fila de execução da OS no `oficina-execution-service`, incluindo priorização mínima, consulta de fila, início/finalização de diagnóstico e reparo, e eventos correspondentes.
- [ ] Criar testes unitários e de integração mínimos nos três microsserviços para controllers, use cases, persistência, idempotência, eventos e cenários principais da Saga.
- [ ] Criar cenário BDD automatizado para pelo menos um fluxo completo da OS atravessando `oficina-os-service`, `oficina-billing-service` e `oficina-execution-service`, incluindo evidência de execução no CI.
- [ ] Configurar cobertura mínima de 80% por serviço, com relatório JaCoCo publicado no CI e link ou evidência registrada no README de cada microsserviço.
- [ ] Validar os três microsserviços contra contratos OpenAPI, schemas JSON de eventos, [Contrato de Erros REST](contracts/error-model.md), [Contrato de Idempotência](contracts/idempotency.md) e [Contrato de Saga do oficina-os-service](contracts/saga/oficina-os-saga-v1.md).
- [ ] Copiar e adaptar workflows de CI/CD para os três repositórios de microsserviços, garantindo build, testes, Quality Gate SonarCloud ou equivalente, publicação de imagem e deploy automatizado em Kubernetes.
- [ ] Configurar proteção da branch `main` nos três repositórios de microsserviços, com PR obrigatório e checagens automáticas exigidas antes de merge.
- [ ] Registrar Swagger/OpenAPI ou collection Postman atualizada no README de cada microsserviço, com link para o contrato canônico correspondente.
- [ ] Registrar nos READMEs dos três microsserviços a escolha da Saga orquestrada pelo `oficina-os-service`, com justificativa e links para ADR, contrato e fluxos.
- [ ] Resolver e documentar a estratégia de entrega dos manifestos Kubernetes por microsserviço, conciliando a exigência do enunciado com o repositório canônico `oficina-infra`.
- [ ] Atualizar continuamente a documentação local dos três repositórios de microsserviços com setup, variáveis de ambiente, execução local, testes, build, Docker, deploy e decisões específicas que surgirem durante a implementação.
- [ ] Marcar o `oficina-app` como referência histórica após a decomposição, sem aplicar adaptações da Fase 4 diretamente nele.

### Épico C — Saga

- [x] Detalhar fluxo feliz da Saga.
- [x] Detalhar fluxo de recusa de orçamento.
- [x] Detalhar fluxo de pagamento recusado.
- [x] Detalhar falha de estoque/execução.
- [x] Definir eventos de compensação.
- [x] Definir timeouts e retentativas.
- [x] Definir testes de contrato da Saga.
- [ ] Definir e implementar cenário BDD do fluxo completo da Saga, incluindo um caminho feliz e pelo menos uma falha compensada.

### Épico D — Plataforma e operação

- [x] Criar padrão de observabilidade.
- [x] Criar padrão de logs estruturados.
- [x] Criar propagação de `correlationId`.
- [x] Criar manifests Kubernetes base.
- [x] Criar pipeline padrão de CI/CD.
- [ ] Normalizar valores legados de conta, região e ambiente AWS nos repositórios antigos conforme [Conta, região e ambientes AWS](docs/aws-environments.md). Item adiado: por enquanto, `oficina-app`, `oficina-infra-db` e `oficina-infra-k8s` serão usados apenas como fonte de cópia; ajustes necessários no `oficina-auth-lambda` podem ser feitos diretamente nele.
- [x] Planejar a migração de `oficina-infra-db` e `oficina-infra-k8s` para o novo repositório unificado de infraestrutura.
- [x] Criar baseline executável do RDS PostgreSQL compartilhado no `oficina-infra`, com Terraform e bootstrap de databases, usuários e secrets independentes para OS e Billing.
- [ ] Aplicar o RDS PostgreSQL compartilhado em AWS usando VPC, subnets e security groups reais do ambiente `lab`.
- [x] Migrar e adaptar EKS, ECR, API Gateway e Kubernetes compartilhado de `oficina-infra-k8s` para `oficina-infra`, removendo dependências operacionais do `oficina-app`.
- [ ] Adicionar DynamoDB do `oficina-execution-service` e mensageria da Fase 4 ao `oficina-infra`.
- [x] Migrar workflows e scripts operacionais úteis de `oficina-infra-db` e `oficina-infra-k8s` para `oficina-infra`, normalizando state, secrets, conta, região e ambiente.
- [ ] Criar checklist de deploy independente.
- [ ] Criar runbooks mínimos.
- [x] Criar checklist final de entrega da Fase 4, cobrindo repositórios, cobertura, Swagger/OpenAPI, vídeo, PDF, diagrama geral, estratégia de Saga, justificativa de microsserviços e tecnologias.
- [ ] Registrar data de entrega da Fase 4, participantes, links dos repositórios e link do vídeo no checklist final ou no documento de entrega.
- [ ] Criar diagrama geral da arquitetura final com microsserviços, bancos, mensageria, Kubernetes, observabilidade e integração Mercado Pago.
- [ ] Preparar roteiro e evidências do vídeo de demonstração de até 15 minutos, incluindo fluxo completo da OS, Saga com falha/compensação, deploy automatizado e rastreamento distribuído.

---

## Ordem sugerida para execução com agentes

1. **Agente de contratos:** normalizar eventos, tópicos e schemas.
2. **Agente de APIs:** gerar OpenAPI por microsserviço a partir do contrato REST.
3. **Agente de plataforma:** criar templates de repositório, CI/CD e Kubernetes.
4. **Agente de decomposição:** copiar e adaptar o código do `oficina-app` para `oficina-os-service` e `oficina-execution-service`, criando do zero o `oficina-billing-service` conforme os contratos.
5. **Agente de integração:** implementar Saga, producers, consumers, Outbox, idempotência e testes distribuídos.
6. **Agente de operação:** documentar observabilidade, runbooks e checklists.

Essa ordem evita que agentes implementem templates ou código antes de os contratos canônicos estarem fechados.

---

## Critérios de pronto da plataforma de documentação

A plataforma pode ser considerada pronta para guiar os repositórios dos microsserviços quando possuir:

- ADRs aceitas para decisões arquiteturais principais.
- Contratos REST em OpenAPI.
- Eventos com schemas JSON versionados.
- Mapeamento canônico de tópicos de mensageria.
- Matriz de ownership por microsserviço.
- Fluxo da Saga com compensações.
- Padrões de erro, idempotência e observabilidade.
- Padrão BDD e meta de cobertura mínima de 80% por microsserviço.
- Templates mínimos de serviço, pipeline e deploy.
- Backlog explícito para cópia controlada do `oficina-app`, criação das implementações novas da Fase 4 e validação dos microsserviços contra contratos.
- Checklists de revisão de contrato, release e entrega final da Fase 4.

---

## Próximo passo recomendado

O próximo passo mais importante é abrir duas frentes paralelas e controladas: consolidar o repositório `oficina-infra`, migrando e adaptando os artefatos ainda úteis de `oficina-infra-k8s` e `oficina-infra-db` conforme o [Plano de migração para o repositório unificado de infraestrutura](docs/infrastructure-migration-plan.md), e iniciar as baselines executáveis dos três microsserviços conforme o [Plano de Decomposição do oficina-app](docs/oficina-app-decomposition.md).

A ordem recomendada é:

1. criar baseline Quarkus executável nos três microsserviços;
2. criar diretivas locais para agentes, README operacional e backlog local nos três repositórios de microsserviços;
3. copiar e adaptar o domínio de OS/atendimento para `oficina-os-service`;
4. copiar e adaptar catálogo, peças, serviços e estoque para `oficina-execution-service`, reimplementando DynamoDB;
5. criar do zero orçamento, aprovação, recusa e pagamento no `oficina-billing-service`;
6. implementar BDD, cobertura mínima de 80% e Quality Gate nos três microsserviços;
7. aplicar os workflows de CI/CD e configurar proteção da branch `main` nos três repositórios;
8. aplicar o baseline do RDS PostgreSQL compartilhado em AWS quando `vpc_id`, subnets e security groups reais do ambiente `lab` estiverem disponíveis;
9. adicionar DynamoDB do `oficina-execution-service` e mensageria conforme os contratos da plataforma;
10. definir rotas reais do API Gateway quando os endpoints dos microsserviços estiverem publicados;
11. resolver a estratégia de evidência dos manifestos Kubernetes por microsserviço;
12. revisar checklists de deploy independente, runbooks mínimos e entregáveis finais da Fase 4.
