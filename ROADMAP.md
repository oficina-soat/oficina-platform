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
- Uso de Amazon DynamoDB definido para o `oficina-execution-service`, atendendo ao requisito de banco não relacional.
- Estratégia de CI/CD independente definida por microsserviço.
- Conta, regiao e ambiente AWS definidos em `docs/aws-environments.md`:
  - conta AWS parametrizada por `AWS_ACCOUNT_ID`, sem numero fixo canonico;
  - regiao `us-east-1`;
  - ambiente `lab`;
  - infraestrutura compartilhada `eks-lab`.
- Decisão de separar o código de infraestrutura em um novo repositório unificado, a ser criado, consolidando as responsabilidades hoje distribuídas entre `oficina-infra-db` e `oficina-infra-k8s`.
- Enunciado da Fase 4 incluído como referência normativa em `docs/Enunciado Fase 4.md`.
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

**Critério de pronto:** cada arquivo deve conter endpoints, schemas de request/response, códigos HTTP esperados, erros padronizados, autenticação e exemplos mínimos, sem divergência em relação a `contracts/Contrato de APIs REST.md`.

### 2. Schemas formais dos eventos

**Situação atual:** existem arquivos Markdown individuais para eventos e schemas JSON iniciais em `contracts/events/schemas/`.

**Definição faltante:** evoluir os schemas conforme novos campos forem estabilizados nos contratos REST, Saga e implementações dos microsserviços, preservando compatibilidade ou incrementando `eventVersion` quando houver mudança incompatível.

**Artefatos sugeridos:**

```text
contracts/events/schemas/<nome-do-evento>.schema.json
```

**Critério de pronto:** cada evento deve possuir `eventType`, `eventVersion`, `producer`, `aggregateId`, `payload` tipado, exemplo válido e vínculo com o tópico correspondente.

### 3. Normalização entre eventos e tópicos

**Situação atual:** eventos e tópicos foram normalizados em torno dos nomes lógicos camelCase dos eventos e tópicos kebab-case por domínio do produtor.

**Decisão tomada:** os nomes lógicos camelCase dos arquivos em `contracts/events/` são a referência para `eventType`; os tópicos usam kebab-case no domínio do produtor; e os produtores devem usar os nomes canônicos dos microsserviços (`oficina-os-service`, `oficina-billing-service` e `oficina-execution-service`).

**Definição faltante:** manter a tabela canônica `evento -> tópico -> produtor -> consumidores` como referência para criação dos schemas JSON e para implementação dos produtores/consumidores.

**Critério de pronto:** todo evento fundamental deve possuir exatamente um tópico canônico, um produtor compatível com os microsserviços definidos e consumidores explícitos quando houver integração entre serviços.

### 4. Catálogo de responsabilidades por microsserviço

**Situação atual:** as responsabilidades principais estão definidas nas ADRs e contratos, mas ainda não há uma matriz operacional única para agentes.

**Definição faltante:** criar uma matriz de ownership contendo entidades, APIs, eventos produzidos, eventos consumidos, banco de dados, jobs/outbox e integrações externas por microsserviço.

**Artefato sugerido:**

```text
docs/service-ownership.md
```

**Critério de pronto:** um agente deve conseguir identificar rapidamente onde implementar uma regra sem consultar todas as ADRs.

### 5. Plano de decomposição do `oficina-app`

**Situação atual:** o `oficina-app` representa a base de código existente que será usada como referência e origem da migração para a arquitetura de microsserviços da Fase 4.

**Decisão:** o código do `oficina-app` será dividido entre `oficina-os-service`, `oficina-billing-service` e `oficina-execution-service`, respeitando os limites de responsabilidade, contratos REST, eventos, bancos e regras de ownership definidos neste repositório.

**Definições faltantes:**

- Mapear controllers, services, entidades, DTOs, repositories, migrations e testes do `oficina-app` para o microsserviço destino.
- Definir quais partes do `oficina-app` serão removidas, arquivadas ou mantidas apenas como referência após a migração.
- Definir a estratégia de migração de dados do modelo atual para `oficina_os`, `oficina_billing` e DynamoDB.
- Definir como o front-end ou consumidores atuais deixarão de chamar o `oficina-app` e passarão a chamar os novos endpoints dos microsserviços.

**Artefato sugerido:**

```text
docs/oficina-app-decomposition.md
```

**Critério de pronto:** cada componente relevante do `oficina-app` deve possuir destino explícito, estratégia de migração e critério de descarte ou retenção como referência.

### 6. Fluxos da Saga em formato executável para implementação

**Situação atual:** a estratégia de Saga está documentada conceitualmente.

**Definição faltante:** detalhar a máquina de estados da Saga, comandos, eventos esperados, compensações, timeouts e cenários de erro.

**Artefatos sugeridos:**

```text
docs/saga-flows.md
contracts/saga/oficina-os-saga-v1.md
```

**Critério de pronto:** cada etapa deve informar acionador, serviço responsável, operação síncrona ou assíncrona, evento de sucesso, evento de falha e compensação.

### 7. Padrões técnicos para repositórios de microsserviços

**Situação atual:** há decisões sobre CI/CD, deploy independente e governança, mas ainda faltam templates práticos para agentes criarem os repositórios.

**Definição faltante:** criar um template mínimo de serviço com estrutura, comandos padrão, pipeline, Dockerfile, Kubernetes manifests, observabilidade e documentação local.

**Artefatos sugeridos:**

```text
templates/quarkus-service/
templates/github-actions/service-ci.yml
templates/kubernetes/base/
```

**Critério de pronto:** um agente deve conseguir criar um novo microsserviço consistente usando o template sem reinterpretar a arquitetura.

### 8. Repositório unificado de infraestrutura

**Situação atual:** os repositórios `oficina-infra-db` e `oficina-infra-k8s` existem como referências separadas para banco de dados e Kubernetes.

**Definição faltante:** criar um novo repositório de infraestrutura que unifique as responsabilidades atualmente separadas entre `oficina-infra-db` e `oficina-infra-k8s`.

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

**Situação atual:** observabilidade é requisito recorrente nas ADRs, mas falta contrato operacional detalhado.

**Definição faltante:** padronizar logs, métricas, traces, correlation IDs, dashboards mínimos e alertas.

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

### Marco 3 — Saga e integração distribuída

**Objetivo:** detalhar o fluxo distribuído principal e seus cenários alternativos.

**Entregas:**

1. Documentar Saga principal da Ordem de Serviço.
2. Documentar compensações e timeouts.
3. Definir contratos de comandos/eventos usados pela Saga.
4. Definir estratégia de testes de integração entre serviços.

**Resultado esperado:** agentes conseguem implementar o fluxo distribuído sem decisões ad hoc sobre sequência, compensação ou ownership.

### Marco 4 — Operação e entrega

**Objetivo:** fechar requisitos de execução em Kubernetes, observabilidade e governança operacional.

**Entregas:**

1. Documentar padrão de observabilidade.
2. Definir dashboards e alertas mínimos.
3. Definir runbooks operacionais.
4. Criar checklist de release por serviço.
5. Criar checklist de revisão de contratos.

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
- [ ] Criar matriz de ownership por microsserviço.
- [ ] Criar plano de decomposição do `oficina-app` por componente e microsserviço destino.
- [ ] Definir estratégia de migração ou descarte do `oficina-app` após a decomposição.
- [ ] Criar template base Quarkus.
- [ ] Criar padrão de configuração por ambiente.
- [ ] Criar padrão de health checks.
- [ ] Criar padrão de migrations para PostgreSQL.
- [ ] Criar padrão de tabelas/streams para DynamoDB.
- [ ] Criar padrão Outbox por serviço.
- [ ] Definir escopo e responsabilidades do novo repositório unificado de infraestrutura.
- [ ] Criar padrão de isolamento para `oficina_os` e `oficina_billing` no RDS PostgreSQL compartilhado.

### Épico C — Saga

- [ ] Detalhar fluxo feliz da Saga.
- [ ] Detalhar fluxo de recusa de orçamento.
- [ ] Detalhar fluxo de pagamento recusado.
- [ ] Detalhar falha de estoque/execução.
- [ ] Definir eventos de compensação.
- [ ] Definir timeouts e retentativas.
- [ ] Definir testes de contrato da Saga.

### Épico D — Plataforma e operação

- [ ] Criar padrão de observabilidade.
- [ ] Criar padrão de logs estruturados.
- [ ] Criar propagação de `correlationId`.
- [ ] Criar manifests Kubernetes base.
- [ ] Criar pipeline padrão de CI/CD.
- [ ] Normalizar valores legados de conta, região e ambiente AWS nos repositórios antigos conforme `docs/aws-environments.md`.
- [ ] Planejar a migração de `oficina-infra-db` e `oficina-infra-k8s` para o novo repositório unificado de infraestrutura.
- [ ] Provisionar RDS PostgreSQL compartilhado com databases e usuários independentes para OS e Billing.
- [ ] Criar checklist de deploy independente.
- [ ] Criar runbooks mínimos.

---

## Ordem sugerida para execução com agentes

1. **Agente de contratos:** normalizar eventos, tópicos e schemas.
2. **Agente de APIs:** gerar OpenAPI por microsserviço a partir do contrato REST.
3. **Agente de plataforma:** criar templates de repositório, CI/CD e Kubernetes.
4. **Agente de integração:** detalhar Saga, comandos, eventos e compensações.
5. **Agente de operação:** documentar observabilidade, runbooks e checklists.

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
- Templates mínimos de serviço, pipeline e deploy.
- Checklists de revisão de contrato e release.

---

## Próximo passo recomendado

O próximo passo mais importante é criar a matriz de ownership por microsserviço. Essa etapa inicia o Marco 2 e permite que agentes identifiquem rapidamente onde implementar entidades, APIs, eventos, bancos, jobs/outbox e integrações externas.
