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
- Divisão inicial definida em três microsserviços:
  - `oficina-os-service`;
  - `oficina-billing-service`;
  - `oficina-execution-service`.
- Comunicação definida como híbrida, combinando APIs REST e mensageria assíncrona.
- Saga Pattern definido como orquestrado pelo `oficina-os-service`.
- Persistência poliglota definida por microsserviço.
- Estratégia de CI/CD independente definida por microsserviço.
- Contratos fundamentais criados para:
  - APIs REST;
  - eventos de domínio;
  - tópicos de mensageria;
  - estados da Ordem de Serviço.

---

## Definições que ainda precisam ser fechadas

As ADRs e contratos fundamentais estão suficientes para iniciar a decomposição dos microsserviços, mas ainda há definições importantes para tornar o trabalho dos agentes mais eficiente e reduzir decisões implícitas durante a implementação.

### 1. Contratos OpenAPI formais

**Situação atual:** há um contrato REST em Markdown com rotas e responsabilidades principais.

**Definição faltante:** criar especificações OpenAPI versionadas por microsserviço.

**Artefatos sugeridos:**

```text
contracts/openapi/oficina-os-service.yaml
contracts/openapi/oficina-billing-service.yaml
contracts/openapi/oficina-execution-service.yaml
```

**Critério de pronto:** cada arquivo deve conter endpoints, schemas de request/response, códigos HTTP esperados, erros padronizados, autenticação e exemplos mínimos.

### 2. Schemas formais dos eventos

**Situação atual:** existem arquivos Markdown individuais para eventos, mas eles ainda não possuem payload obrigatório, schema validável e tópico canônico associado.

**Definição faltante:** criar schemas JSON por evento, mantendo compatibilidade com o envelope definido no contrato de mensageria.

**Artefatos sugeridos:**

```text
contracts/events/schemas/<nome-do-evento>.schema.json
```

**Critério de pronto:** cada evento deve possuir `eventType`, `eventVersion`, `producer`, `aggregateId`, `payload` tipado, exemplo válido e vínculo com o tópico correspondente.

### 3. Normalização entre eventos e tópicos

**Situação atual:** há divergências de nomenclatura entre alguns eventos de domínio e tópicos de mensageria.

**Exemplos a revisar:**

- `diagnosticoFinalizado` versus `diagnostico-concluido`;
- `execucaoFinalizada` versus `reparo-concluido`;
- `pagamentoSolicitado` versus `pagamento-criado`;
- eventos de estoque com emissor `Inventory Service`, enquanto a divisão atual prevê estoque dentro do `oficina-execution-service`.

**Definição faltante:** escolher uma nomenclatura canônica e refletir a decisão nos contratos de eventos, tópicos e APIs.

**Critério de pronto:** todo evento fundamental deve possuir exatamente um tópico canônico e um produtor compatível com os microsserviços definidos.

### 4. Catálogo de responsabilidades por microsserviço

**Situação atual:** as responsabilidades principais estão definidas nas ADRs e contratos, mas ainda não há uma matriz operacional única para agentes.

**Definição faltante:** criar uma matriz de ownership contendo entidades, APIs, eventos produzidos, eventos consumidos, banco de dados, jobs/outbox e integrações externas por microsserviço.

**Artefato sugerido:**

```text
docs/service-ownership.md
```

**Critério de pronto:** um agente deve conseguir identificar rapidamente onde implementar uma regra sem consultar todas as ADRs.

### 5. Fluxos da Saga em formato executável para implementação

**Situação atual:** a estratégia de Saga está documentada conceitualmente.

**Definição faltante:** detalhar a máquina de estados da Saga, comandos, eventos esperados, compensações, timeouts e cenários de erro.

**Artefatos sugeridos:**

```text
docs/saga-flows.md
contracts/saga/oficina-os-saga-v1.md
```

**Critério de pronto:** cada etapa deve informar acionador, serviço responsável, operação síncrona ou assíncrona, evento de sucesso, evento de falha e compensação.

### 6. Padrões técnicos para repositórios de microsserviços

**Situação atual:** há decisões sobre CI/CD, deploy independente e governança, mas ainda faltam templates práticos para agentes criarem os repositórios.

**Definição faltante:** criar um template mínimo de serviço com estrutura, comandos padrão, pipeline, Dockerfile, Kubernetes manifests, observabilidade e documentação local.

**Artefatos sugeridos:**

```text
templates/quarkus-service/
templates/github-actions/service-ci.yml
templates/kubernetes/base/
```

**Critério de pronto:** um agente deve conseguir criar um novo microsserviço consistente usando o template sem reinterpretar a arquitetura.

### 7. Padrão de observabilidade distribuída

**Situação atual:** observabilidade é requisito recorrente nas ADRs, mas falta contrato operacional detalhado.

**Definição faltante:** padronizar logs, métricas, traces, correlation IDs, dashboards mínimos e alertas.

**Artefato sugerido:**

```text
docs/observability.md
```

**Critério de pronto:** todos os serviços devem expor o mesmo conjunto mínimo de sinais e propagar `correlationId` em HTTP, eventos e logs.

### 8. Padrão de erros e idempotência

**Situação atual:** o contrato REST cita idempotência para criação, mas faltam respostas de erro padronizadas e regras de reprocessamento.

**Definição faltante:** documentar formato único de erro, códigos HTTP, chaves de idempotência, tratamento de duplicidade e comportamento esperado para consumidores de eventos.

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
3. Criar OpenAPI inicial dos três microsserviços.
4. Definir modelo de erro e idempotência.

**Resultado esperado:** agentes conseguem gerar código de controllers, DTOs, produtores e consumidores com menor ambiguidade.

### Marco 2 — Blueprint dos microsserviços

**Objetivo:** criar a base reutilizável para implementação dos repositórios independentes.

**Entregas:**

1. Criar matriz de ownership por serviço.
2. Criar template Quarkus de microsserviço.
3. Criar pipeline padrão de CI/CD.
4. Criar manifests Kubernetes base.
5. Criar documentação local padrão para cada repositório.

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

- [ ] Revisar divergências entre eventos de domínio e tópicos de mensageria.
- [ ] Criar tabela canônica `evento -> tópico -> produtor -> consumidores`.
- [ ] Criar schemas JSON para eventos fundamentais.
- [ ] Criar OpenAPI do `oficina-os-service`.
- [ ] Criar OpenAPI do `oficina-billing-service`.
- [ ] Criar OpenAPI do `oficina-execution-service`.
- [ ] Criar contrato de erros REST.
- [ ] Criar contrato de idempotência.

### Épico B — Microsserviços

- [ ] Criar matriz de ownership por microsserviço.
- [ ] Criar template base Quarkus.
- [ ] Criar padrão de configuração por ambiente.
- [ ] Criar padrão de health checks.
- [ ] Criar padrão de migrations para PostgreSQL.
- [ ] Criar padrão de tabelas/streams para DynamoDB.
- [ ] Criar padrão Outbox por serviço.

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

O próximo passo mais importante é normalizar eventos e tópicos antes de gerar OpenAPI e schemas JSON. Essa etapa reduz inconsistências de vocabulário e evita que agentes propaguem nomes divergentes para implementações, testes e pipelines.
