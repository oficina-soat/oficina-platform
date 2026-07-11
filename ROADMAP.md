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
  - infraestrutura compartilhada `eks-lab`;
  - IDs físicos efêmeros de VPC, subnets, security groups e integrações devem ser resolvidos por variáveis, outputs ou descoberta em tempo de deploy, pois a infraestrutura do laboratório pode ser criada e destruída a cada ciclo de teste.
- Decisão de separar o código de infraestrutura no repositório unificado `oficina-infra`, consolidando as responsabilidades hoje distribuídas entre `oficina-infra-db` e `oficina-infra-k8s`, conforme [Escopo do Repositório Unificado de Infraestrutura](docs/infrastructure-repository-scope.md).
- Rotas públicas do API Gateway definidas em [Rotas públicas do API Gateway](docs/api-gateway-public-routes.md): todas as APIs REST de negócio dos três microsserviços devem ser expostas pelo `eks-lab-http-api`, sem publicar endpoints operacionais como `/q/metrics`, `/q/health` e `/api/v1/status`.
- Forma oficial de coleta New Relic definida como New Relic OpenTelemetry Collector instalado por Helm no cluster EKS `eks-lab`, com OTLP/gRPC, coleta de logs dos pods e coleta das métricas dos microsserviços.
- Baseline executável do New Relic OpenTelemetry Collector criado no `oficina-infra`, com Helm values do ambiente `lab`, script de instalação, Secret Kubernetes esperado, endpoint OTLP/gRPC interno e integração automática ao deploy quando `NEW_RELIC_LICENSE_KEY` está configurada.
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

**Situação atual:** os repositórios `oficina-infra-db` e `oficina-infra-k8s` existem como referências separadas para banco de dados e Kubernetes, e o repositório unificado `oficina-infra` já existe como destino canônico da Fase 4. O `oficina-infra` já possui módulos Terraform para RDS PostgreSQL compartilhado, EKS, ECR, API Gateway, DynamoDB do `oficina-execution-service` e mensageria SNS/SQS da Fase 4.

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

**Situação atual:** o padrão operacional foi criado em [Padrão de Observabilidade Distribuída](docs/observability.md), consolidando logs estruturados, métricas, traces, health checks, dashboards e alertas no New Relic, além da propagação de `correlationId`.

**Definição faltante:** manter o padrão coerente com os manifests Kubernetes, pipelines, instalação do New Relic OpenTelemetry Collector no repositório de infraestrutura e implementações dos microsserviços conforme esses artefatos forem evoluídos.

**Etapas locais e pendências remotas para New Relic:**

1. [x] Definir a forma de coleta oficial para o ambiente `lab`: New Relic OpenTelemetry Collector instalado por Helm no cluster EKS, preservando New Relic como backend canônico.
2. [x] Criar no `oficina-infra` os Helm values e scripts necessários para instalar o New Relic OpenTelemetry Collector no cluster `eks-lab`, incluindo Secret Kubernetes esperado, endpoint OTLP/gRPC interno, coleta de logs dos pods, métricas Prometheus e traces.
3. [x] Definir secrets e variáveis operacionais do New Relic no ambiente `lab`, incluindo `NEW_RELIC_LICENSE_KEY`, endpoint OTLP interno e integração com os nomes de runtime descritos em [Nomes de runtime, secrets e infraestrutura](docs/infra-runtime-naming.md).
4. Concluído localmente: `[D-OBS-IMPL-001]` propagar `OTEL_EXPORTER_OTLP_ENDPOINT`, `OTEL_EXPORTER_OTLP_PROTOCOL`, `OTEL_RESOURCE_ATTRIBUTES`, `DEPLOYMENT_ENVIRONMENT` e `OTEL_SERVICE_NAME` nos manifests dos três microsserviços.
5. Concluído localmente: `[D-OBS-IMPL-002]` validar nos três microsserviços, por inspeção local e testes locais aplicáveis, a emissão de logs JSON, exposição de `/q/metrics`, health checks Quarkus e configuração de traces OpenTelemetry conforme [Validação local de observabilidade](docs/observability-local-validation.md).
6. [x] Automatizar no workflow de deploy do `oficina-infra` a instalação ou atualização do New Relic OpenTelemetry Collector quando a secret GitHub `NEW_RELIC_LICENSE_KEY` estiver presente, mantendo `INSTALL_NEW_RELIC_OTEL_COLLECTOR=false` como override explícito para pular a etapa.

As instalações reais, dashboards, alertas, testes de ponta a ponta no `eks-lab` e evidências externas ficam apartados em [Validações remotas e evidências externas](#validações-remotas-e-evidências-externas).

**Artefato sugerido:**

```text
docs/observability.md
docs/infra-runtime-naming.md
docs/phase-4-delivery-checklist.md
```

**Critério de pronto:** todos os serviços devem expor o mesmo conjunto mínimo de sinais, propagar `correlationId` em HTTP, eventos, logs e traces, enviar dados reais ao New Relic no ambiente `lab` por meio do New Relic OpenTelemetry Collector, possuir dashboards e alertas mínimos ativos e ter evidências registradas no checklist final.

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

**Situação atual:** o padrão BDD, cobertura e qualidade foi definido em [Padrão BDD, Cobertura e Qualidade](docs/bdd-testing.md), com Cucumber JVM, JUnit Platform, JaCoCo com mínimo de 80% e Quality Gate SonarCloud obrigatório no CI. O cenário BDD da Saga está implementado no `oficina-os-service` e foi verificado localmente em 2026-07-04 com `./mvnw -B -Dtest=RunCucumberTest test`, cobrindo caminho feliz e falha compensada. A evidência remota do BDD no CI foi confirmada em 2026-07-10 pelo workflow `Service CI/CD` em `main` do `oficina-os-service` no [run 29116182460](https://github.com/oficina-soat/oficina-os-service/actions/runs/29116182460). Em 2026-07-11 foi identificada ausência de métricas de cobertura nos dashboards SonarCloud porque a Automatic Analysis não importa cobertura; o padrão foi ajustado para análise baseada em CI com `SONAR_TOKEN`, SonarScanner for Maven e importação de `target/jacoco-report/jacoco.xml`. Em 2026-07-11, o cache do SonarCloud no `service-ci-validate` foi atualizado para `actions/cache@v6`, compatível com Node.js 24, removendo a dependência da série `v4` com runtime Node.js 20 depreciado. Também foi reforçada a pinagem por SHA completo para actions de terceiros usadas no pipeline, preservando comentário com a tag semântica de origem.

**Definição fechada:** as evidências remotas de BDD, cobertura mínima e Quality Gate devem vir do workflow `service-ci-validate`, que executa Maven `verify`, gera JaCoCo e envia o XML ao SonarCloud. O [Checklist Final de Entrega da Fase 4](docs/phase-4-delivery-checklist.md) ainda deve receber os links finais consolidados quando o documento de entrega for preenchido.

**Artefatos sugeridos:**

```text
docs/bdd-testing.md
templates/quarkus-service/src/test/resources/features/
templates/github-actions/service-ci.yml
```

**Critério de pronto:** os três microsserviços devem executar testes unitários, integração e contrato no CI; pelo menos um fluxo completo da OS deve ter cenário BDD automatizado; cada serviço deve publicar evidência de cobertura mínima de 80%; e o pipeline deve falhar quando o Quality Gate configurado não for atendido.

### 13. Evidências e entregáveis finais da Fase 4

**Situação atual:** o checklist consolidado dos entregáveis finais foi criado em [Checklist Final de Entrega da Fase 4](docs/phase-4-delivery-checklist.md), cobrindo evidências por repositório, cobertura, Swagger/OpenAPI, vídeo, PDF, diagrama, Saga, deploy e observabilidade. O [Diagrama Geral da Arquitetura Final](docs/architecture-diagram.md) registra a visão consolidada de microsserviços, bancos, mensageria, Kubernetes, observabilidade e Mercado Pago.

**Definição faltante:** preencher os links reais de cobertura, Swagger/OpenAPI, pipelines, vídeo e PDF final conforme os repositórios de microsserviço e infraestrutura forem concluídos.

**Artefatos sugeridos:**

```text
docs/phase-4-delivery-checklist.md
docs/architecture-diagram.md
```

**Critério de pronto:** cada repositório de microsserviço deve possuir README com link de cobertura e Swagger/OpenAPI; a plataforma deve possuir checklist final da entrega; e o PDF/vídeo devem demonstrar fluxo completo da OS, Saga com falha/compensação, deploy automatizado e observabilidade distribuída.

### 14. Manifestos Kubernetes como entregável por microsserviço

**Situação atual:** a governança da suíte definiu o repositório `oficina-infra` como destino canônico da infraestrutura executável, mas o enunciado da Fase 4 lista manifestos Kubernetes como entregável dos repositórios de microsserviço.

**Decisão:** a estratégia foi fechada em [Estratégia de entrega dos manifestos Kubernetes](docs/kubernetes-manifest-strategy.md). O `oficina-infra` é a fonte canônica dos manifests executáveis; o [Template Kubernetes Base](templates/kubernetes/base/README.md) permanece como referência normativa; e os READMEs dos microsserviços apontam para o template aplicável e para o destino canônico no `oficina-infra`.

Se uma avaliação exigir arquivos Kubernetes dentro de cada repositório de microsserviço, as cópias devem ser registradas como referência não canônica. O deploy real continua pertencendo ao `oficina-infra`.

**Artefatos sugeridos:**

```text
../oficina-infra/
templates/kubernetes/base/
README.md dos microsserviços
docs/kubernetes-manifest-strategy.md
```

**Critério de pronto:** a entrega deve demonstrar onde estão os manifestos Kubernetes de cada serviço, qual repositório é a fonte canônica de deploy e como evitar divergência entre cópias ou referências.

### 15. Ambiente local integrado para testes entre microsserviços

**Situação atual:** os repositórios `oficina-os-service`, `oficina-billing-service` e `oficina-execution-service` já possuem baselines executáveis e APIs iniciais, e o ambiente local integrado foi criado no `../oficina-infra` para subir dependências compartilhadas, testar endpoints em portas distintas e preparar a base de mensageria da integração.

**Decisão:** criar o ambiente local executável no repositório canônico `../oficina-infra`, preservando este repositório apenas como fonte de governança. O ambiente local deve ser complementar ao deploy AWS/EKS e não substitui os artefatos Terraform, Kubernetes ou contratos oficiais.

**Etapas:**

1. [x] Criar `compose.local.yml` no `../oficina-infra` com PostgreSQL, DynamoDB Local e LocalStack para SNS/SQS.
2. [x] Criar bootstrap local de PostgreSQL com os databases `oficina_os` e `oficina_billing`, usuários independentes e permissões compatíveis com o [Padrão de isolamento PostgreSQL no RDS compartilhado](docs/rds-postgresql-isolation.md).
3. [x] Criar bootstrap local de DynamoDB com as tabelas canônicas do `oficina-execution-service`, conforme o [Padrão DynamoDB do oficina-execution-service](docs/dynamodb-execution-service.md).
4. [x] Criar bootstrap local de SNS/SQS com tópicos, filas e DLQs alinhados ao [Contrato de Tópicos de Mensageria](contracts/Contrato%20de%20Tópicos%20de%20Mensageria.md).
5. [x] Adicionar profile opcional no Compose para subir os três microsserviços com portas locais distintas, sem tornar esse profile pré-requisito para validar dependências.
6. [x] Documentar comandos locais para subir dependências, executar bootstrap, consultar status e desligar o ambiente.

**Artefatos sugeridos:**

```text
../oficina-infra/compose.local.yml
../oficina-infra/docs/local-integration.md
../oficina-infra/scripts/local/
```

**Critério de pronto:** um agente deve conseguir subir as dependências locais com Docker Compose, preparar bancos, tabelas DynamoDB, tópicos, filas e DLQs, rodar os três microsserviços em portas diferentes e chamar `/api/v1/status` em cada serviço. A validação distribuída completa da Saga continua dependente da implementação de Outbox, producers e consumers nos microsserviços.

### 16. Rotas públicas do API Gateway

**Situação atual:** as OpenAPI dos três microsserviços definem a superfície REST de negócio da Fase 4, todas sob `/api/v1`, e o `oficina-infra` já possui módulo de API Gateway parametrizado para receber rotas HTTP.

**Decisão:** todas as APIs REST de negócio dos três microsserviços serão públicas via API Gateway HTTP `eks-lab-http-api`, conforme [Rotas públicas do API Gateway](docs/api-gateway-public-routes.md). "Públicas" significa roteáveis pela entrada pública da plataforma; a decisão não remove os contratos de autenticação, erro padronizado, idempotência e `correlationId`.

Os endpoints operacionais `/api/v1/status`, `/q/health`, `/q/metrics`, `/q/openapi` e `/q/swagger-ui` não fazem parte da superfície pública permanente de negócio. Se forem usados em demonstração ou evidência, devem ser tratados como exceção operacional temporária no `oficina-infra`.

**Definição fechada:** as rotas públicas foram materializadas no `oficina-infra` e validadas no ambiente `lab` em 2026-07-10. O HTTP API `eks-lab-http-api` publicou rotas específicas por método e path para os três microsserviços, sem rota catch-all única e sem expor `/q/health`, `/q/metrics` ou `/api/v1/status` como API pública de negócio.

**Artefatos sugeridos:**

```text
docs/api-gateway-public-routes.md
../oficina-infra/terraform/environments/lab/
../oficina-infra/terraform/modules/api_gateway/
```

**Critério de pronto:** o API Gateway deve rotear cada método e path público para o microsserviço correto, sem usar uma rota catch-all única para todos os serviços e sem expor endpoints operacionais como API de negócio. Confirmado em 2026-07-10 pela lista remota de rotas do API Gateway e por chamadas representativas para OS, Billing e Execution no endpoint público do ambiente `lab`.

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
7. Criar ambiente local integrado no `oficina-infra` para dependências, bootstrap e teste manual dos três microsserviços.
8. Operacionalizar New Relic no ambiente `lab` com New Relic OpenTelemetry Collector via Helm, dashboards, alertas e evidências de correlação distribuída.

**Resultado esperado:** a plataforma fica pronta para operação, demonstração e evolução controlada.

---

## Backlog orientado a agentes

Esta seção contém tarefas implementáveis por agentes com validação local ou revisão de arquivos no workspace. Itens que dependem de AWS aplicada, GitHub remoto, SonarCloud, New Relic, gravação de vídeo ou evidência externa ficam apartados em [Validações remotas e evidências externas](#validações-remotas-e-evidências-externas).

Convenção de identificadores para itens abertos:

- `A-*`: contratos;
- `B-*`: microsserviços;
- `B2-*`: implementação da Fase 4;
- `C-*`: Saga;
- `D-*`: plataforma e operação;
- sufixo `IMPL`: implementação ou validação local;
- sufixo `REM`: validação remota;
- sufixo `EVID`: evidência final ou registro externo.

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
- [x] Criar do zero no `oficina-billing-service` o domínio de orçamento, aprovação, recusa, pagamento e integração financeira, porque não há módulo equivalente no `oficina-app`.
- [x] Criar migrations e seed limpo do `oficina-billing-service` para o database `oficina_billing`, preservando isolamento de acesso e ownership.
- [x] Implementar no `oficina-billing-service` cálculo e snapshot financeiro de itens, fluxo de aprovação/recusa, pagamento, producers e consumers definidos nos contratos de eventos.
- [x] Implementar integração de pagamentos com Mercado Pago no `oficina-billing-service`, incluindo configuração, adapter, tratamento de falhas, testes e documentação operacional, conforme a [Referência API Mercado Pago](https://www.mercadopago.com.br/developers/pt/reference).
- [x] Implementar fila de execução da OS no `oficina-execution-service`, incluindo priorização mínima, consulta de fila, início/finalização de diagnóstico e reparo, e eventos correspondentes.
- [x] Criar testes unitários e de integração mínimos nos três microsserviços para controllers, use cases, persistência, idempotência, eventos e cenários principais da Saga.
- [x] Criar cenário BDD automatizado para pelo menos um fluxo completo da OS atravessando `oficina-os-service`, `oficina-billing-service` e `oficina-execution-service`; validação local executada em 2026-07-04 com `./mvnw -B -Dtest=RunCucumberTest test` no `oficina-os-service`.
- [x] Configurar cobertura mínima de 80% por serviço, com relatório JaCoCo publicado no CI e link ou evidência registrada no README de cada microsserviço.
- [x] Validar os três microsserviços contra contratos OpenAPI, schemas JSON de eventos, [Contrato de Erros REST](contracts/error-model.md), [Contrato de Idempotência](contracts/idempotency.md) e [Contrato de Saga do oficina-os-service](contracts/saga/oficina-os-saga-v1.md).
- [x] Copiar e adaptar workflows de CI/CD para os três repositórios de microsserviços, garantindo build, testes, Quality Gate SonarCloud ou equivalente, publicação de imagem e deploy automatizado em Kubernetes. A publicação de imagem e o deploy foram mantidos condicionais por variáveis/execução manual até a estratégia de manifestos Kubernetes e infraestrutura final estarem fechadas.
- [x] Registrar Swagger/OpenAPI ou collection Postman atualizada no README de cada microsserviço, com link para o contrato canônico correspondente.
- [x] Registrar nos READMEs dos três microsserviços a escolha da Saga orquestrada pelo `oficina-os-service`, com justificativa e links para ADR, contrato e fluxos.
- [x] Resolver e documentar a estratégia de entrega dos manifestos Kubernetes por microsserviço, conciliando a exigência do enunciado com o repositório canônico `oficina-infra`.
- [x] Atualizar continuamente a documentação local dos três repositórios de microsserviços com setup, variáveis de ambiente, execução local, testes, build, Docker, deploy e decisões específicas que surgirem durante a implementação.
- [x] Marcar o `oficina-app` como referência histórica após a decomposição, sem aplicar adaptações da Fase 4 diretamente nele.

### Épico C — Saga

- [x] Detalhar fluxo feliz da Saga.
- [x] Detalhar fluxo de recusa de orçamento.
- [x] Detalhar fluxo de pagamento recusado.
- [x] Detalhar falha de estoque/execução.
- [x] Definir eventos de compensação.
- [x] Definir timeouts e retentativas.
- [x] Definir testes de contrato da Saga.
- [x] Definir e implementar cenário BDD do fluxo completo da Saga, incluindo um caminho feliz e pelo menos uma falha compensada.

### Épico D — Plataforma e operação

- [x] Criar padrão de observabilidade.
- [x] Criar padrão de logs estruturados.
- [x] Criar propagação de `correlationId`.
- [x] Criar manifests Kubernetes base.
- [x] Criar pipeline padrão de CI/CD.
- [x] `[D-NR-IMPL-001]` Criar baseline executável do New Relic no `oficina-infra` com New Relic OpenTelemetry Collector via Helm, Secret Kubernetes esperado, endpoint OTLP/gRPC interno e coleta de logs, métricas e traces.
- [x] `[D-OBS-IMPL-001]` Propagar `OTEL_EXPORTER_OTLP_ENDPOINT`, `OTEL_EXPORTER_OTLP_PROTOCOL`, `OTEL_RESOURCE_ATTRIBUTES`, `DEPLOYMENT_ENVIRONMENT` e `OTEL_SERVICE_NAME` nos manifests dos três microsserviços.
- [x] `[D-OBS-IMPL-002]` Validar nos três microsserviços, por inspeção local e testes locais aplicáveis, a emissão de logs JSON, exposição de `/q/metrics`, health checks Quarkus e configuração de traces OpenTelemetry conforme [Validação local de observabilidade](docs/observability-local-validation.md).
- [x] `[D-AWS-IMPL-001]` Encerrar a normalização direta de valores legados de conta, região e ambiente AWS nos repositórios antigos. Decisão: `oficina-app`, `oficina-infra-db` e `oficina-infra-k8s` permanecem apenas como fontes históricas ou origem de cópia controlada; as normalizações aplicáveis foram concentradas nos destinos canônicos, especialmente `oficina-infra`, conforme [Conta, região e ambientes AWS](docs/aws-environments.md), [Plano de migração para o repositório unificado de infraestrutura](docs/infrastructure-migration-plan.md) e [Nomes de runtime, secrets e infraestrutura](docs/infra-runtime-naming.md). Ajustes diretos continuam permitidos apenas em `oficina-auth-lambda` quando a mudança pertencer ao próprio componente serverless.
- [x] Planejar a migração de `oficina-infra-db` e `oficina-infra-k8s` para o novo repositório unificado de infraestrutura.
- [x] Criar baseline executável do RDS PostgreSQL compartilhado no `oficina-infra`, com Terraform e bootstrap de databases, usuários e secrets independentes para OS e Billing.
- [x] Migrar e adaptar EKS, ECR, API Gateway e Kubernetes compartilhado de `oficina-infra-k8s` para `oficina-infra`, removendo dependências operacionais do `oficina-app`.
- [x] Definir as rotas públicas de negócio do API Gateway para os três microsserviços, conforme [Rotas públicas do API Gateway](docs/api-gateway-public-routes.md).
- [x] `[D-INFRA-IMPL-001]` Adicionar DynamoDB do `oficina-execution-service` e mensageria da Fase 4 ao `oficina-infra`.
- [x] Criar ambiente local integrado no `oficina-infra` com PostgreSQL, DynamoDB Local, LocalStack SNS/SQS, bootstrap de dependências e profile opcional para os três microsserviços.
- [x] Migrar workflows e scripts operacionais úteis de `oficina-infra-db` e `oficina-infra-k8s` para `oficina-infra`, normalizando state, secrets, conta, região e ambiente.
- [x] `[D-REL-IMPL-001]` Criar checklist de deploy independente.
- [x] `[D-OPS-IMPL-001]` Criar runbooks mínimos.
- [x] Criar checklist final de entrega da Fase 4, cobrindo repositórios, cobertura, Swagger/OpenAPI, vídeo, PDF, diagrama geral, estratégia de Saga, justificativa de microsserviços e tecnologias.
- [x] `[D-DIAG-IMPL-001]` Criar diagrama geral da arquitetura final com microsserviços, bancos, mensageria, Kubernetes, observabilidade e integração Mercado Pago.
- [ ] `[D-VIDEO-IMPL-001]` Preparar roteiro do vídeo de demonstração de até 15 minutos, incluindo fluxo completo da OS, Saga com falha/compensação, deploy automatizado e rastreamento distribuído.

---

## Validações remotas e evidências externas

Esta seção concentra tarefas que dependem de ambiente externo, credenciais administrativas, execução real em AWS, SonarCloud, GitHub, New Relic, gravação de vídeo ou publicação de evidências. Elas não devem ser tratadas como próxima tarefa de implementação por agentes, salvo pedido explícito do usuário.

### Épico B2 — CI, qualidade e governança remota

- [x] `[B2-CI-REM-000]` Configurar SonarCloud nos três repositórios de microsserviços antes da homologação dos PRs: criar ou vincular os projetos no SonarCloud, configurar `SONAR_TOKEN` como secret GitHub e usar análise baseada em CI pelo SonarScanner for Maven. Ajustado em 2026-07-11 para substituir a dependência de Automatic Analysis, que não importa cobertura, por envio explícito de `target/jacoco-report/jacoco.xml` no workflow `service-ci-validate`.
- [x] `[B2-CI-REM-001]` Registrar evidência remota da execução BDD no CI quando os pipelines finais estiverem homologados. Evidência: `Service CI/CD` em `main` do `oficina-os-service` concluído com sucesso em 2026-07-10 no [run 29116182460](https://github.com/oficina-soat/oficina-os-service/actions/runs/29116182460), incluindo o job `service-ci-validate`; o README do serviço registra que o Cucumber BDD roda no ciclo Maven `verify`.
- [x] `[B2-CI-REM-002]` Registrar evidência remota do Quality Gate SonarCloud aprovado e da cobertura mínima de 80% nos três microsserviços. Ajuste complementar em 2026-07-11: os workflows devem executar SonarCloud após o Maven `verify`, falhar quando `target/jacoco-report/jacoco.xml` não existir e aguardar o Quality Gate, garantindo que a cobertura apareça no dashboard SonarCloud.
- [ ] `[B2-GH-REM-001]` Confirmar proteção da branch `main` nos três repositórios de microsserviços, com PR obrigatório e checagens automáticas exigidas antes de merge. A política canônica foi documentada em [Proteção da branch main dos microsserviços](docs/github-branch-protection.md); a aplicação remota depende de credencial GitHub com permissão administrativa e fica fora do escopo dos agentes.

### Épico D — AWS, New Relic e entrega final

- [x] `[D-NR-REM-000]` Preparar o acesso New Relic antes da validação de observabilidade: confirmar a conta New Relic, gerar `NEW_RELIC_LICENSE_KEY`, configurar o secret no repositório ou na organização GitHub, manter `INSTALL_NEW_RELIC_OTEL_COLLECTOR=auto` ou usar `true` para exigir a execução remota, e confirmar acesso ao contexto AWS/EKS do cluster `eks-lab`, conforme [Padrão de Observabilidade Distribuída](docs/observability.md) e [Nomes de runtime, secrets e infraestrutura](docs/infra-runtime-naming.md). Evidência conferida em 2026-07-10: o workflow `Deploy Lab` do `oficina-infra` concluiu com sucesso no [run 29125719440](https://github.com/oficina-soat/oficina-infra/actions/runs/29125719440), o contexto EKS `eks-lab` estava acessível e o Secret Kubernetes `new-relic-license-key` existia no namespace `newrelic`.
- [x] `[D-NR-REM-001]` Instalar e validar o New Relic OpenTelemetry Collector no cluster `eks-lab` quando `NEW_RELIC_LICENSE_KEY` e contexto AWS/EKS estiverem disponíveis. Evidência conferida em 2026-07-10: o release Helm `nr-k8s-otel-collector` ficou `deployed` no namespace `newrelic`, o Deployment, o DaemonSet e o `kube-state-metrics` ficaram `1/1 Running`, o Service interno `nr-k8s-otel-collector-gateway` expôs OTLP/gRPC e OTLP/HTTP, e os logs do DaemonSet registraram `Everything is ready` com o receiver `filelog` lendo os arquivos de `oficina-os-service`, `oficina-billing-service` e `oficina-execution-service`. A causa do `CrashLoopBackOff` anterior foi corrigida no node atual ajustando o IMDS `HttpPutResponseHopLimit` para `2`; a persistência foi registrada no módulo EKS do repositório `oficina-infra`.
- [ ] `[D-NR-REM-002]` Criar dashboards mínimos no New Relic para `oficina-os-service`, `oficina-billing-service` e `oficina-execution-service`, filtrando por `service.name`, `service.namespace=oficina` e `deployment.environment=lab`. Templates locais preparados em [Dashboards New Relic](docs/new-relic-dashboards.md) e [Dashboard operacional dos microsserviços](docs/new-relic-dashboard-operational.json). Evidência manual informada em 2026-07-11: os dashboards exibiram logs, mas nenhum gráfico indicou recebimento de métricas; a validação remota completa permanece pendente.
- [ ] `[D-NR-REM-003]` Criar visão adicional da Saga no New Relic para o `oficina-os-service`, cobrindo Sagas iniciadas, finalizadas, compensadas, em falha manual e duração por etapa. Template local preparado em [Dashboard da Saga e OS](docs/new-relic-dashboard-saga.json); a criação remota e a evidência no New Relic continuam pendentes.
- [ ] `[D-NR-REM-004]` Criar alertas mínimos no New Relic para indisponibilidade, erro HTTP elevado, latência elevada, Outbox parada, Outbox com falha, DLQ, Saga em falha manual, pagamento indisponível e banco indisponível.
- [ ] `[D-NR-REM-005]` Executar teste de ponta a ponta no ambiente `lab` gerando uma Ordem de Serviço com caminho feliz e uma falha compensada, confirmando correlação por `correlationId` entre logs, traces, métricas e eventos. Execução registrada em 2026-07-11 no [Relatório D-NR-REM-005 — E2E no ambiente lab](docs/d-nr-rem-005-e2e-lab-report.md): o fluxo REST passou, mas a etapa permanece pendente porque a correlação em logs, traces e eventos não foi comprovada; nos dashboards New Relic, foi observado recebimento de logs, mas não de métricas.
- [ ] `[D-NR-EVID-001]` Registrar evidências de observabilidade distribuída no checklist final da Fase 4, incluindo links ou identificadores dos dashboards, alertas, traces e consultas de logs usadas na validação.
- [x] `[D-AWS-REM-001]` Aplicar o RDS PostgreSQL compartilhado em AWS usando valores variáveis do ambiente `lab`, como `vpc_id`, subnets e security groups resolvidos por Terraform outputs, variáveis de pipeline ou descoberta em tempo de deploy. Evidência conferida em 2026-07-10: a instância `oficina-postgres-lab` estava `available`, com endpoint RDS, security group e subnet group resolvidos no ambiente AWS `lab`.
- [x] `[D-API-REM-001]` Materializar e validar no `oficina-infra` as rotas públicas do API Gateway quando os backends reais e `integration_uri` dos microsserviços estiverem disponíveis no ambiente `lab`. Evidência conferida em 2026-07-10: o HTTP API `eks-lab-http-api` expôs rotas específicas para os três microsserviços; chamadas públicas representativas retornaram respostas dos serviços corretos e endpoints operacionais como `/q/health` e `/api/v1/status` permaneceram sem rota pública.
- [ ] `[D-DELIVERY-EVID-001]` Registrar data de entrega da Fase 4, participantes, links dos repositórios e link do vídeo no checklist final ou no documento de entrega.
- [ ] `[D-VIDEO-EVID-001]` Registrar evidências finais do vídeo de demonstração de até 15 minutos após gravação e homologação do ambiente.

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

O próximo passo para agentes deve priorizar itens `IMPL` abertos no [Backlog orientado a agentes](#backlog-orientado-a-agentes). Itens `REM` e `EVID` ficam apartados em [Validações remotas e evidências externas](#validações-remotas-e-evidências-externas) e só devem ser tratados quando o usuário pedir explicitamente validação remota, homologação externa ou registro de evidências.

A ordem local recomendada é:

1. `[D-VIDEO-IMPL-001]` Preparar roteiro do vídeo de demonstração.

As validações remotas prioritárias, quando o ambiente externo estiver disponível, são `[B2-GH-REM-001]`, `[D-NR-REM-001]` a `[D-NR-REM-005]` e os itens `EVID` finais.
