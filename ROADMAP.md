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
- Destino do `oficina-auth-lambda` definido: apesar do nome, o repositório continuará existindo como componente serverless independente responsável pelos fluxos de autenticação, sincronização do cadastro operacional e emissão de notificações conforme a ADR-003, sem ser absorvido pelos três microsserviços.
- Comunicação definida como híbrida, combinando APIs REST e mensageria assíncrona.
- Saga Pattern definido como orquestrado pelo `oficina-os-service`.
- Persistência poliglota definida por microsserviço.
- Estratégia de PostgreSQL definida para a Fase 4 como uma única instância Amazon RDS compartilhada, com databases independentes por microsserviço relacional:
  - `oficina_os`, acessado apenas pelo `oficina-os-service`;
  - `oficina_billing`, acessado apenas pelo `oficina-billing-service`.
- Uso de Amazon DynamoDB definido para o `oficina-execution-service`, atendendo ao requisito de banco não relacional, com padrão de tabelas, chaves, índices, seeds e streams registrado em [Padrão DynamoDB do oficina-execution-service](docs/infrastructure/dynamodb-execution-service.md).
- Estratégia de CI/CD independente definida por microsserviço.
- Conta, região e ambiente AWS definidos em [Conta, região e ambientes AWS](docs/infrastructure/aws-environments.md):
  - conta AWS parametrizada por `AWS_ACCOUNT_ID`, sem número fixo canônico;
  - região `us-east-1`;
  - ambiente `lab`;
  - infraestrutura compartilhada `eks-lab`;
  - IDs físicos efêmeros de VPC, subnets, security groups e integrações devem ser resolvidos por variáveis, outputs ou descoberta em tempo de deploy, pois a infraestrutura do laboratório pode ser criada e destruída a cada ciclo de teste.
- Decisão de separar o código de infraestrutura no repositório unificado `oficina-infra`, consolidando as responsabilidades hoje distribuídas entre `oficina-infra-db` e `oficina-infra-k8s`, conforme [Escopo do Repositório Unificado de Infraestrutura](docs/infrastructure/infrastructure-repository-scope.md).
- Rotas públicas do API Gateway definidas em [Rotas públicas do API Gateway](docs/infrastructure/api-gateway-public-routes.md): todas as APIs REST de negócio dos três microsserviços devem ser expostas pelo `eks-lab-http-api`, sem publicar endpoints operacionais como `/q/metrics`, `/q/health` e `/api/v1/status`.
- Forma oficial de coleta New Relic definida como New Relic OpenTelemetry Collector instalado por Helm no cluster EKS `eks-lab`, com OTLP/gRPC, coleta de logs dos pods e coleta das métricas dos microsserviços.
- Baseline executável do New Relic OpenTelemetry Collector criado no `oficina-infra`, com Helm values do ambiente `lab`, script de instalação, Secret Kubernetes esperado, endpoint OTLP/gRPC interno e integração automática ao deploy quando `NEW_RELIC_LICENSE_KEY` está configurada.
- Enunciado da Fase 4 incluído como referência normativa em [Enunciado Fase 4](docs/delivery/Enunciado%20Fase%204.md).
- Auditoria de lacunas realizada em 2026-07-11 identificou que alguns itens do roadmap estavam fechados pelo contrato ou pelo schema, mas ainda sem implementação runtime real ou sem evidência remota:
  - `oficina-os-service` recebeu adapters PostgreSQL locais para domínio, histórico, Saga, Inbox e Outbox em 2026-07-11, ficando pendente apenas a evidência remota no `lab`;
  - `oficina-billing-service` recebeu adapters PostgreSQL para orçamento, pagamento, projeção financeira de eventos consumidos e Outbox em 2026-07-11, ficando pendente apenas a evidência remota no `lab`;
  - `oficina-execution-service` recebeu acesso runtime real ao DynamoDB para catálogo, estoque, execuções, fila operacional, Outbox e idempotência em 2026-07-11, ficando pendente apenas a evidência remota no `lab`;
  - os três microsserviços conectaram Outbox, producers e consumers à mensageria SNS/SQS em 2026-07-12, com publicação assíncrona, consumo SQS, retry/backoff e testes locais com LocalStack, ficando pendente a validação remota no `lab`;
  - a idempotência persistente dos três microsserviços foi implementada em 2026-07-12, ficando pendente a validação remota no `lab`;
  - os runtimes `prod` e `lab` dos três microsserviços receberam validação fail-fast em 2026-07-12 para impedir memória, endpoints locais, mensageria desabilitada, configurações obrigatórias ausentes e dependências PostgreSQL, DynamoDB, SNS ou SQS inacessíveis;
  - o CRUD REST de usuários operacionais foi contratado e implementado no `oficina-os-service` em 2026-07-12, com Pessoa, Usuário, status, papéis, autorização administrativa, persistência PostgreSQL e exclusão lógica, sem credenciais no OS;
  - a integração de usuários operacionais com autenticação foi implementada em 2026-07-12: o `oficina-os-service` publica snapshots sem credenciais pela Outbox, a `oficina-auth-sync-lambda` projeta CPF, nome, status e papéis de forma idempotente no PostgreSQL próprio da autenticação, e a credencial é ativada diretamente na API serverless por token de uso único, sem chamada síncrona ao serviço de OS durante o login.
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

**Situação atual:** as responsabilidades principais estão definidas nas ADRs e contratos, e a matriz operacional única para agentes foi criada em [Matriz de Ownership por Microsserviço](docs/architecture/service-ownership.md).

**Definição faltante:** manter a matriz de ownership atualizada sempre que APIs, eventos, bancos, jobs/outbox, integrações externas ou limites de responsabilidade forem alterados.

**Artefato sugerido:**

```text
docs/architecture/service-ownership.md
```

**Critério de pronto:** um agente deve conseguir identificar rapidamente onde implementar uma regra sem consultar todas as ADRs.

### 5. Plano de decomposição do `oficina-app`

**Situação atual:** o plano inicial de decomposição foi criado em [Plano de Decomposição do oficina-app](docs/architecture/oficina-app-decomposition.md), usando o `oficina-app` como referência de código, testes e seed funcional para a arquitetura de microsserviços da Fase 4.

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
docs/architecture/oficina-app-decomposition.md
```

**Definição faltante:** detalhar, durante a implementação dos microsserviços, os mapeamentos finais de classes, testes e seeds executáveis conforme cada repositório evoluir.

As decisões para as baselines PostgreSQL decompostas de `oficina-os-service` e `oficina-billing-service` foram registradas em [Proposta de Migrations PostgreSQL Decompostas](docs/infrastructure/postgres-migrations-decomposition.md).

O CRUD administrativo de usuários operacionais foi materializado no `oficina-os-service`. Pessoa e Usuário permanecem sob ownership do serviço, conforme a [Matriz de Ownership por Microsserviço](docs/architecture/service-ownership.md), e a superfície REST agregada `/api/v1/usuarios` está definida no [Contrato de APIs REST](contracts/Contrato%20de%20APIs%20REST.md) e no [OpenAPI do oficina-os-service](contracts/openapi/oficina-os-service.yaml). O recurso exige o papel `administrativo`, usa os estados `ATIVO`, `INATIVO` e `BLOQUEADO`, realiza exclusão lógica por inativação e não recebe nem persiste credenciais.

O `oficina-auth-lambda` consulta seu PostgreSQL próprio para autenticar CPF e senha e não chama o `oficina-os-service` no caminho de login. A consistência operacional é assíncrona: `usuarioAdicionado`, `usuarioAtualizado` e `usuarioExcluido` transportam snapshots sem credenciais para filas exclusivas da `oficina-auth-sync-lambda`, que atualiza a projeção de CPF, nome, status e papéis, registra `eventId` processado e ignora snapshots mais antigos pelo `occurredAt`. A credencial é criada diretamente na API de autenticação por token aleatório de 256 bits, persistido somente como hash SHA-256, de uso único e válido por 24 horas por padrão. Usuários `INATIVO`, `BLOQUEADO` ou sem credencial ativada não autenticam. A decisão e as superfícies implementáveis estão alinhadas na [ADR-003 - Serverless para Autenticação e Notificações](adr/ADR-003%20-%20Serverless%20para%20Autenticação%20e%20Notificações.md), no [Contrato de APIs REST](contracts/Contrato%20de%20APIs%20REST.md), no [Contrato de Eventos de Domínio](contracts/Contrato%20de%20Eventos%20de%20Dom%C3%ADnio.md), no [Contrato de Tópicos de Mensageria](contracts/Contrato%20de%20T%C3%B3picos%20de%20Mensageria.md) e no [OpenAPI do oficina-auth-lambda](contracts/openapi/oficina-auth-lambda.yaml).

**Critério de pronto:** cada componente relevante do `oficina-app` deve possuir destino explícito, estratégia de seed ou descarte, e critério de retenção apenas como referência.

### 6. Fluxos da Saga em formato executável para implementação

**Situação atual:** a estratégia de Saga está documentada conceitualmente na ADR-009, os fluxos implementáveis foram detalhados em [Fluxos da Saga da Ordem de Serviço](docs/architecture/saga-flows.md) e o contrato operacional foi criado em [Contrato de Saga do oficina-os-service](contracts/saga/oficina-os-saga-v1.md).

**Definição faltante:** evoluir os fluxos conforme a implementação dos microsserviços estabilizar payloads, endpoints auxiliares ou novas compensações.

**Artefatos sugeridos:**

```text
docs/architecture/saga-flows.md
contracts/saga/oficina-os-saga-v1.md
```

**Critério de pronto:** cada etapa deve informar acionador, serviço responsável, operação síncrona ou assíncrona, evento de sucesso, evento de falha e compensação.

### 7. Padrões técnicos para repositórios de microsserviços

**Situação atual:** há decisões sobre CI/CD, deploy independente e governança; o template base Quarkus foi criado em [Template Quarkus de Microsserviço](templates/quarkus-service/README.md); o pipeline padrão foi criado em [Template GitHub Actions para Microsserviços](templates/github-actions/README.md); os manifests Kubernetes base foram criados em [Template Kubernetes Base](templates/kubernetes/base/README.md); e o padrão DynamoDB do `oficina-execution-service` foi definido em [Padrão DynamoDB do oficina-execution-service](docs/infrastructure/dynamodb-execution-service.md).

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

**Definição fechada:** o escopo e as responsabilidades do `oficina-infra` foram definidos em [Escopo do Repositório Unificado de Infraestrutura](docs/infrastructure/infrastructure-repository-scope.md).

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

**Situação atual:** o padrão operacional foi criado em [Padrão de Observabilidade Distribuída](docs/observability/observability.md), consolidando logs estruturados, métricas, traces, health checks, dashboards e alertas no New Relic, além da propagação de `correlationId`.

**Definição faltante:** manter o padrão coerente com os manifests Kubernetes, pipelines, instalação do New Relic OpenTelemetry Collector no repositório de infraestrutura e implementações dos microsserviços conforme esses artefatos forem evoluídos.

**Etapas locais e pendências remotas para New Relic:**

1. [x] Definir a forma de coleta oficial para o ambiente `lab`: New Relic OpenTelemetry Collector instalado por Helm no cluster EKS, preservando New Relic como backend canônico.
2. [x] Criar no `oficina-infra` os Helm values e scripts necessários para instalar o New Relic OpenTelemetry Collector no cluster `eks-lab`, incluindo Secret Kubernetes esperado, endpoint OTLP/gRPC interno, coleta de logs dos pods, métricas Prometheus e traces.
3. [x] Definir secrets e variáveis operacionais do New Relic no ambiente `lab`, incluindo `NEW_RELIC_LICENSE_KEY`, endpoint OTLP interno e integração com os nomes de runtime descritos em [Nomes de runtime, secrets e infraestrutura](docs/infrastructure/infra-runtime-naming.md).
4. Concluído localmente: `[D-OBS-IMPL-001]` propagar `OTEL_EXPORTER_OTLP_ENDPOINT`, `OTEL_EXPORTER_OTLP_PROTOCOL`, `OTEL_RESOURCE_ATTRIBUTES`, `DEPLOYMENT_ENVIRONMENT` e `OTEL_SERVICE_NAME` nos manifests dos três microsserviços.
5. Concluído localmente: `[D-OBS-IMPL-002]` validar nos três microsserviços, por inspeção local e testes locais aplicáveis, a emissão de logs JSON, exposição de `/q/metrics`, health checks Quarkus e configuração de traces OpenTelemetry conforme [Validação local de observabilidade](docs/observability/observability-local-validation.md).
6. [x] Automatizar no workflow de deploy do `oficina-infra` a instalação ou atualização do New Relic OpenTelemetry Collector quando a secret GitHub `NEW_RELIC_LICENSE_KEY` estiver presente, mantendo `INSTALL_NEW_RELIC_OTEL_COLLECTOR=false` como override explícito para pular a etapa.

As instalações reais, dashboards, alertas, testes de ponta a ponta no `eks-lab` e evidências externas ficam apartados em [Validações remotas e evidências externas](#validações-remotas-e-evidências-externas).

**Artefato sugerido:**

```text
docs/observability/observability.md
docs/infrastructure/infra-runtime-naming.md
docs/delivery/phase-4-delivery-checklist.md
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

**Situação atual:** o padrão BDD, cobertura e qualidade foi definido em [Padrão BDD, Cobertura e Qualidade](docs/delivery/bdd-testing.md), com Cucumber JVM, JUnit Platform, JaCoCo com mínimo de 80% e Quality Gate SonarCloud obrigatório no CI. O cenário BDD da Saga está implementado no `oficina-os-service` e foi verificado localmente em 2026-07-04 com `./mvnw -B -Dtest=RunCucumberTest test`, cobrindo caminho feliz e falha compensada. A evidência remota do BDD no CI foi confirmada em 2026-07-10 pelo workflow `Service CI/CD` em `main` do `oficina-os-service` no [run 29116182460](https://github.com/oficina-soat/oficina-os-service/actions/runs/29116182460). Em 2026-07-11 foi identificada ausência de métricas de cobertura nos dashboards SonarCloud porque a Automatic Analysis não importa cobertura; o padrão foi ajustado para análise baseada em CI com `SONAR_TOKEN`, SonarScanner for Maven e importação de `target/jacoco-report/jacoco.xml`. Em 2026-07-11, o cache do SonarCloud no `service-ci-validate` foi atualizado para `actions/cache@v6`, compatível com Node.js 24, removendo a dependência da série `v4` com runtime Node.js 20 depreciado. Também foi reforçada a pinagem por SHA completo para actions de terceiros usadas no pipeline, preservando comentário com a tag semântica de origem. Em 2026-07-11, após falhas de Quality Gate em `oficina-os-service` e `oficina-billing-service`, a validação pré-commit dos microsserviços passou a exigir `clean verify`, existência de `target/jacoco-report/jacoco.xml` e execução local do SonarScanner quando `SONAR_TOKEN` estiver disponível. A espera local por Quality Gate com `sonar.qualitygate.wait=true` deve ser usada apenas em contexto consultável pelo SonarCloud, como `main`, branch longa habilitada ou PR real.

**Definição fechada:** as evidências remotas de BDD, cobertura mínima e Quality Gate devem vir do workflow `service-ci-validate`, que executa Maven `verify`, gera JaCoCo e envia o XML ao SonarCloud. O [Checklist Final de Entrega da Fase 4](docs/delivery/phase-4-delivery-checklist.md) ainda deve receber os links finais consolidados quando o documento de entrega for preenchido.

**Artefatos sugeridos:**

```text
docs/delivery/bdd-testing.md
templates/quarkus-service/src/test/resources/features/
templates/github-actions/service-ci.yml
```

**Critério de pronto:** os três microsserviços devem executar testes unitários, integração e contrato no CI; pelo menos um fluxo completo da OS deve ter cenário BDD automatizado; cada serviço deve publicar evidência de cobertura mínima de 80%; e o pipeline deve falhar quando o Quality Gate configurado não for atendido.

### 13. Evidências e entregáveis finais da Fase 4

**Situação atual:** o checklist consolidado dos entregáveis finais foi criado em [Checklist Final de Entrega da Fase 4](docs/delivery/phase-4-delivery-checklist.md), cobrindo evidências por repositório, cobertura, Swagger/OpenAPI, vídeo, PDF, diagrama, Saga, deploy, cobrança Mercado Pago sandbox e observabilidade. O [Diagrama Geral da Arquitetura Final](docs/architecture/architecture-diagram.md) registra a visão consolidada de microsserviços, bancos, mensageria, Kubernetes, observabilidade e Mercado Pago.

**Definição faltante:** preencher os links reais de cobertura, Swagger/OpenAPI, pipelines, vídeo e PDF final conforme os repositórios de microsserviço e infraestrutura forem concluídos.

**Artefatos sugeridos:**

```text
docs/delivery/phase-4-delivery-checklist.md
docs/architecture/architecture-diagram.md
```

**Critério de pronto:** cada repositório de microsserviço deve possuir README com link de cobertura e Swagger/OpenAPI; a plataforma deve possuir checklist final da entrega; e o PDF/vídeo devem demonstrar fluxo completo da OS, Saga com falha/compensação, deploy automatizado e observabilidade distribuída.

### 14. Manifestos Kubernetes como entregável por microsserviço

**Situação atual:** a governança da suíte definiu o repositório `oficina-infra` como destino canônico da infraestrutura executável, mas o enunciado da Fase 4 lista manifestos Kubernetes como entregável dos repositórios de microsserviço.

**Decisão:** a estratégia foi fechada em [Estratégia de entrega dos manifestos Kubernetes](docs/infrastructure/kubernetes-manifest-strategy.md). O `oficina-infra` é a fonte canônica dos manifests executáveis; o [Template Kubernetes Base](templates/kubernetes/base/README.md) permanece como referência normativa; e os READMEs dos microsserviços apontam para o template aplicável e para o destino canônico no `oficina-infra`.

Se uma avaliação exigir arquivos Kubernetes dentro de cada repositório de microsserviço, as cópias devem ser registradas como referência não canônica. O deploy real continua pertencendo ao `oficina-infra`.

**Artefatos sugeridos:**

```text
../oficina-infra/
templates/kubernetes/base/
README.md dos microsserviços
docs/infrastructure/kubernetes-manifest-strategy.md
```

**Critério de pronto:** a entrega deve demonstrar onde estão os manifestos Kubernetes de cada serviço, qual repositório é a fonte canônica de deploy e como evitar divergência entre cópias ou referências.

### 15. Ambiente local integrado para testes entre microsserviços

**Situação atual:** os repositórios `oficina-os-service`, `oficina-billing-service` e `oficina-execution-service` já possuem baselines executáveis e APIs iniciais, e o ambiente local integrado foi criado no `../oficina-infra` para subir dependências compartilhadas, executar os serviços em portas distintas e conectar a mensageria ao LocalStack. Os containers usam explicitamente profile `dev` e ambiente `local`, sem reutilizar essa exceção nos runtimes protegidos.

**Decisão:** criar o ambiente local executável no repositório canônico `../oficina-infra`, preservando este repositório apenas como fonte de governança. O ambiente local deve ser complementar ao deploy AWS/EKS e não substitui os artefatos Terraform, Kubernetes ou contratos oficiais.

**Etapas:**

1. [x] Criar `compose.local.yml` no `../oficina-infra` com PostgreSQL, DynamoDB Local e LocalStack para SNS/SQS.
2. [x] Criar bootstrap local de PostgreSQL com os databases `oficina_os` e `oficina_billing`, usuários independentes e permissões compatíveis com o [Padrão de isolamento PostgreSQL no RDS compartilhado](docs/infrastructure/rds-postgresql-isolation.md).
3. [x] Criar bootstrap local de DynamoDB com as tabelas canônicas do `oficina-execution-service`, conforme o [Padrão DynamoDB do oficina-execution-service](docs/infrastructure/dynamodb-execution-service.md).
4. [x] Criar bootstrap local de SNS/SQS com tópicos, filas e DLQs alinhados ao [Contrato de Tópicos de Mensageria](contracts/Contrato%20de%20Tópicos%20de%20Mensageria.md).
5. [x] Adicionar profile opcional no Compose para subir os três microsserviços com portas locais distintas, sem tornar esse profile pré-requisito para validar dependências.
6. [x] Documentar comandos locais para subir dependências, executar bootstrap, consultar status e desligar o ambiente.

**Artefatos sugeridos:**

```text
../oficina-infra/compose.local.yml
../oficina-infra/docs/local-integration.md
../oficina-infra/scripts/local/
```

**Critério de pronto:** um agente deve conseguir subir as dependências locais com Docker Compose, preparar bancos, tabelas DynamoDB, tópicos, filas e DLQs, rodar os três microsserviços em portas diferentes, chamar `/api/v1/status` em cada serviço e exercitar Outbox, producers e consumers contra o LocalStack. A homologação com recursos AWS reais continua rastreada nos itens `REM` de persistência, idempotência e mensageria.

### 16. Rotas públicas do API Gateway

**Situação atual:** as OpenAPI dos três microsserviços definem a superfície REST de negócio da Fase 4, todas sob `/api/v1`, e o `oficina-infra` já possui módulo de API Gateway parametrizado para receber rotas HTTP.

**Decisão:** todas as APIs REST de negócio dos três microsserviços serão públicas via API Gateway HTTP `eks-lab-http-api`, conforme [Rotas públicas do API Gateway](docs/infrastructure/api-gateway-public-routes.md). "Públicas" significa roteáveis pela entrada pública da plataforma; a decisão não remove os contratos de autenticação, erro padronizado, idempotência e `correlationId`.

Os endpoints operacionais `/api/v1/status`, `/q/health`, `/q/metrics`, `/q/openapi` e `/q/swagger-ui` não fazem parte da superfície pública permanente de negócio. Se forem usados em demonstração ou evidência, devem ser tratados como exceção operacional temporária no `oficina-infra`.

**Definição fechada:** as rotas públicas foram materializadas no `oficina-infra` e validadas no ambiente `lab` em 2026-07-10. O HTTP API `eks-lab-http-api` publicou rotas específicas por método e path para os três microsserviços, sem rota catch-all única e sem expor `/q/health`, `/q/metrics` ou `/api/v1/status` como API pública de negócio.

**Artefatos sugeridos:**

```text
docs/infrastructure/api-gateway-public-routes.md
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
2. Copiar e adaptar o domínio de atendimento do `oficina-app` para o `oficina-os-service`, conforme [Plano de Decomposição do oficina-app](docs/architecture/oficina-app-decomposition.md).
3. Copiar e adaptar o domínio de peças, serviços e estoque do `oficina-app` para o `oficina-execution-service`, reimplementando a persistência em DynamoDB conforme [Padrão DynamoDB do oficina-execution-service](docs/infrastructure/dynamodb-execution-service.md).
4. Criar a implementação nova do `oficina-billing-service`, sem origem equivalente no `oficina-app`, a partir do [Contrato de APIs REST](contracts/Contrato%20de%20APIs%20REST.md), da [OpenAPI do oficina-billing-service](contracts/openapi/oficina-billing-service.yaml), dos eventos e da [Matriz de Ownership por Microsserviço](docs/architecture/service-ownership.md).
5. Separar seeds e migrations executáveis por serviço, preservando seed limpo e isolamento de banco conforme [Proposta de Migrations PostgreSQL Decompostas](docs/infrastructure/postgres-migrations-decomposition.md) e [Padrão de isolamento PostgreSQL no RDS compartilhado](docs/infrastructure/rds-postgresql-isolation.md).
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
- [x] Copiar e adaptar para `oficina-os-service` o domínio de Pessoa, Usuário, Cliente, Veículo e Ordem de Serviço do `oficina-app`, conforme [Plano de Decomposição do oficina-app](docs/architecture/oficina-app-decomposition.md).
- [x] Copiar e adaptar para `oficina-os-service` controllers, presenters, DTOs, validações, testes e seed de atendimento do `oficina-app`, alinhando rotas com a [OpenAPI do oficina-os-service](contracts/openapi/oficina-os-service.yaml).
- [x] Criar migrations e seed limpo do `oficina-os-service` para o database `oficina_os`, preservando isolamento de acesso e ownership.
- [x] Implementar no `oficina-os-service` a baseline funcional da orquestração da Saga, histórico de estados, Outbox, publicação lógica dos eventos de OS e consumo lógico dos eventos de Billing e Execution. A substituição do store de processo por PostgreSQL foi concluída em `[B2-OS-DB-IMPL-001]`; a conexão com SNS/SQS real foi concluída em `[B2-MSG-IMPL-001]`.
- [x] Copiar e adaptar para `oficina-execution-service` o domínio de catálogo técnico, peças, serviços e estoque do `oficina-app`, conforme [Plano de Decomposição do oficina-app](docs/architecture/oficina-app-decomposition.md).
- [x] Modelar e implementar no `oficina-execution-service` a persistência de catálogo, estoque, execução, Outbox e idempotência no formato das tabelas DynamoDB, sem migrar diretamente adapters PostgreSQL/Panache do `oficina-app`. O acesso runtime real ao DynamoDB foi concluído em `[B2-EXEC-DDB-IMPL-001]`.
- [x] Implementar no `oficina-execution-service` diagnóstico, execução, reparo, movimentação de estoque, producers e consumers definidos nos contratos de eventos. A conexão com SNS/SQS real foi concluída em `[B2-MSG-IMPL-001]`.
- [x] Criar seed limpo do `oficina-execution-service` para tabelas DynamoDB, reaproveitando apenas os dados funcionais aplicáveis do `import.sql` do `oficina-app`.
- [x] Criar do zero no `oficina-billing-service` o domínio de orçamento, aprovação, recusa, pagamento e integração financeira, porque não há módulo equivalente no `oficina-app`.
- [x] Criar migrations e seed limpo do `oficina-billing-service` para o database `oficina_billing`, preservando isolamento de acesso e ownership.
- [x] Implementar no `oficina-billing-service` cálculo e snapshot financeiro de itens, fluxo de aprovação/recusa, pagamento, producers e consumers definidos nos contratos de eventos. Os adapters PostgreSQL de orçamento/pagamento foram concluídos em `[B2-BILL-DB-IMPL-001]`; a persistência das projeções/Outbox foi concluída em `[B2-BILL-EVENTSTORE-IMPL-001]`; e a conexão com SNS/SQS real foi concluída em `[B2-MSG-IMPL-001]`.
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

#### Lacunas reabertas por auditoria de persistência, mensageria e idempotência

- [x] `[B2-BILL-DB-IMPL-001]` Substituir repositórios em memória de orçamento e pagamento do `oficina-billing-service` por adapters PostgreSQL para `orcamento`, `orcamento_item` e `pagamento`, mantendo o modo em memória apenas no profile de testes. Concluído localmente no `oficina-billing-service` em 2026-07-11 no commit `17535c2`, com `project.version=1.0.6` e validação `./mvnw -B verify -Ppostgresql -DskipITs=false -DfailIfNoTests=false`.
- [x] `[B2-OS-DB-IMPL-001]` Substituir o `AtendimentoSeedStore` do `oficina-os-service` por adapters PostgreSQL reais para Cliente, Veículo, Ordem de Serviço, histórico de estados, Saga e consultas operacionais, usando o database `oficina_os`, as migrations existentes e testes de integração com PostgreSQL. Concluído localmente no `oficina-os-service` em 2026-07-11 no commit `80ff2e8`, com `project.version=1.0.5`, store em memória restrito ao profile de teste e validação `./mvnw -B verify -Ppostgresql -DskipITs=false -DfailIfNoTests=false`.
- [x] `[B2-BILL-EVENTSTORE-IMPL-001]` Persistir no PostgreSQL do `oficina-billing-service` as projeções de eventos consumidos, itens financeiros projetados e registros de Outbox antes mantidos em `BillingEventStore`, garantindo que orçamento, pagamento, eventos pendentes e histórico de publicação sobrevivam a restart de pod. Concluído localmente no `oficina-billing-service` em 2026-07-11 no commit `0da6799`, com `project.version=1.0.10`, migration `V3__persist_billing_event_store.sql`, store em memória restrito ao profile de teste e validação `./mvnw -B clean verify -Ppostgresql -DskipITs=false -DfailIfNoTests=false`.
- [x] `[B2-EXEC-DDB-IMPL-001]` Substituir o store em memória do `oficina-execution-service` por acesso real ao Amazon DynamoDB, cobrindo catálogo, estoque, execuções, fila operacional, Outbox e idempotência nas tabelas canônicas descritas em [Padrão DynamoDB do oficina-execution-service](docs/infrastructure/dynamodb-execution-service.md). Concluído localmente no `oficina-execution-service` em 2026-07-11 no commit `053e2d1`, com `project.version=1.0.7`, `DynamoDbClient` síncrono, validação por DynamoDB Local/Testcontainers e comando `./mvnw -B clean verify -Pdynamodb -DskipITs=false -DfailIfNoTests=false`.
- [x] `[B2-IDEMP-IMPL-001]` Implementar idempotência persistente nos três microsserviços conforme [Contrato de Idempotência](contracts/idempotency.md): registrar escopo, chave, hash da requisição, status de processamento, resposta consolidada e TTL; retornar a mesma resposta em retries equivalentes; rejeitar reutilização da chave com payload divergente; e manter comportamento após restart de pod. Concluído localmente em 2026-07-12 nos commits `5677ec0` do `oficina-os-service` (`project.version=1.0.11`), `e130960` do `oficina-billing-service` (`project.version=1.0.11`) e `ab94d00` do `oficina-execution-service` (`project.version=1.0.8`). Validações executadas: `./mvnw -B clean verify -Ppostgresql -DskipITs=false -DfailIfNoTests=false` com JaCoCo nos serviços OS e Billing, e `./mvnw -B clean verify -Pdynamodb -DskipITs=false -DfailIfNoTests=false` com JaCoCo no Execution.
- [x] `[B2-MSG-IMPL-001]` Conectar Outbox, producers e consumers dos três microsserviços à mensageria real SNS/SQS provisionada pelo `oficina-infra`, conforme [Contrato de Tópicos de Mensageria](contracts/Contrato%20de%20Tópicos%20de%20Mensageria.md): publisher assíncrono com retry/backoff, marcação `PUBLISHED`/`FAILED`, consumo por filas SQS, ack/delete somente após processamento persistido, tratamento de DLQ e testes locais com LocalStack. Concluído localmente em 2026-07-12 nos commits `dac36cf` do `oficina-os-service` (`project.version=1.0.12`), `419f092` do `oficina-billing-service` (`project.version=1.0.12`) e `5a74223` do `oficina-execution-service` (`project.version=1.0.9`). Validações executadas: `./mvnw -B clean verify -Ppostgresql -DskipITs=false -DfailIfNoTests=false` com JaCoCo nos serviços OS e Billing, `./mvnw -B clean verify -Pdynamodb -DskipITs=false -DfailIfNoTests=false` com JaCoCo no Execution, e testes LocalStack SNS/SQS nos três serviços. A análise SonarCloud local não foi executada porque `SONAR_TOKEN` não estava disponível no ambiente.
- [x] `[B2-CONFIG-IMPL-001]` Impedir fallback silencioso para stores em memória nos profiles `prod` e `lab` dos três microsserviços. O serviço deve falhar na inicialização quando banco, DynamoDB, SNS/SQS ou secrets obrigatórios estiverem ausentes; o modo em memória deve ficar documentado e restrito a testes ou execução local deliberada. Concluído localmente em 2026-07-12 nos commits `4367b39` do `oficina-os-service` (`project.version=1.0.18`), `c03849a` do `oficina-billing-service` (`project.version=1.0.19`) e `68bf5d9` do `oficina-execution-service` (`project.version=1.0.15`). O comportamento canônico foi registrado em [Nomes de runtime, secrets e infraestrutura](docs/infrastructure/infra-runtime-naming.md), e o `oficina-infra` foi alinhado no commit `5050c34` com configuração explícita do runtime `lab`, profile `dev` no Compose local e `sns:GetTopicAttributes` nas policies produtoras. As validações `clean verify` aprovaram 162, 117 e 99 testes, respectivamente, com JaCoCo de 94,61%, 93,32% e 93,04% de instruções; os smoke tests negativos confirmaram falha de startup sem configuração obrigatória ou com endpoints locais em `prod`. A análise SonarCloud local não foi executada porque `SONAR_TOKEN` não estava disponível no ambiente. O primeiro deploy remoto dessas policies falhou no [run 29200769986](https://github.com/oficina-soat/oficina-infra/actions/runs/29200769986), pois o VocLabs negou `iam:CreatePolicyVersion`. A correção local `af4399c` tornou as managed policies de mensageria e DynamoDB content-addressed, com `create_before_destroy`. Os deploys seguintes de [OS](https://github.com/oficina-soat/oficina-os-service/actions/runs/29203472255), [Billing](https://github.com/oficina-soat/oficina-billing-service/actions/runs/29203476229) e [Execution](https://github.com/oficina-soat/oficina-execution-service/actions/runs/29203462467) publicaram as imagens, mas falharam no rollout: os novos pods entraram em `CrashLoopBackOff` porque a `LabEksNodeRole` não permitia `sns:GetTopicAttributes` nem `dynamodb:DescribeTable`, confirmando que as policies runtime existentes estavam sem attachments. A correção `cc30057` do `oficina-infra` detecta sessões `voclabs`, usa a `LabRole` preexistente nos nodes e troca o managed node group com `create_before_destroy`; o plano direcionado confirmou uma criação seguida de uma destruição, sem outras mudanças. O `apply` e a nova validação dos rollouts permanecem pendentes em `[B2-MSG-REM-001]`.
- [x] `[B2-OS-USERS-IMPL-001]` Contratar e implementar o CRUD REST de usuários operacionais no `oficina-os-service` após a reorganização arquitetural dos microsserviços, atualizando [Contrato de APIs REST](contracts/Contrato%20de%20APIs%20REST.md), [OpenAPI do oficina-os-service](contracts/openapi/oficina-os-service.yaml), use cases, controllers, presenters, adapters PostgreSQL, testes e documentação local. Concluído localmente em 2026-07-12 no commit `82b1a88` do `oficina-os-service`, com `project.version=1.1.0`, cinco operações em `/api/v1/usuarios`, autorização `administrativo`, persistência PostgreSQL, migration V5 para remover `usuario.password_hash`, exclusão lógica e respostas de erro canônicas. A infraestrutura expôs as cinco rotas no commit `f6aed3c` do `oficina-infra`. A validação `./mvnw -B clean verify -Ppostgresql -DskipITs=false -DfailIfNoTests=false` aprovou 173 testes e 15 passos BDD, com JaCoCo de 94,77% de instruções e 76,88% de branches; `SONAR_TOKEN` não estava disponível para análise local do Quality Gate.
- [x] `[B2-AUTH-USERS-IMPL-001]` Resolver a integração entre o CRUD administrativo de usuários do `oficina-os-service` e o store de autenticação do `oficina-auth-lambda`, sem chamada síncrona ao serviço de OS durante login e sem transportar senha nos eventos. Concluído localmente em 2026-07-14 no commit `2319bbe` do `oficina-auth-lambda`, com versão `1.1.0`: o novo módulo `auth-sync-lambda` consome SQS/SNS com resposta parcial de lote, idempotência persistente e proteção contra snapshots fora de ordem; projeta pessoa, usuário, status e papéis no PostgreSQL preservando a credencial; reconhece `BLOQUEADO`; e oferece ativação por token aleatório de 256 bits, armazenado apenas como hash SHA-256, de uso único e TTL padrão de 24 horas. Build, pacote, release e deploy independentes foram integrados aos scripts e ao workflow. O commit `be69d50` do `oficina-infra` declara pelo Terraform a função, security group, acesso ao RDS e os três event source mappings inicialmente desabilitados, que o workflow habilita apenas após instalar o pacote funcional. O `clean verify` aprovou os três módulos com testes Quarkus, H2, PostgreSQL/Testcontainers e LocalStack; `actionlint`, sintaxe Bash, `terraform fmt`, `terraform validate` e a validação geral do `oficina-infra` também passaram. Nenhum recurso AWS foi alterado; publicação e homologação permanecem em `[B2-AUTH-USERS-REM-001]`.

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

- [x] `[D-K8S-OWNERSHIP-IMPL-001]` Transferir o ownership dos manifests Kubernetes de aplicação para os respectivos repositórios `oficina-os-service`, `oficina-billing-service` e `oficina-execution-service`, mantendo no `oficina-infra` apenas a infraestrutura compartilhada do cluster e os overlays de ambiente. Implementação realizada em 2026-07-14 nos commits `ba87bc0` do OS, `a284f18` do Billing, `7530061` do Execution e `d991f07` do `oficina-infra`: cada serviço passou a versionar `Deployment`, `Service`, `ServiceAccount`, `ConfigMap` e `kustomization.yaml` em `k8s/base/`; os workflows validam a própria base; o script do `oficina-infra` consome a base do checkout do serviço; as cópias do `oficina-infra` foram removidas; e estratégia, templates, READMEs e checklists foram atualizados. `kubectl kustomize`, `kubeconform -strict`, `actionlint`, sintaxe Bash e `diff --check` aprovaram localmente. Os `clean verify` também aprovaram 180 testes e 15 passos BDD no OS (`1.2.6`), 125 testes no Billing (`1.1.4`) e 105 testes no Execution (`1.0.19`), todos com os checks de cobertura aprovados. A publicação e os rollouts independentes foram comprovados pelos runs [OS 29354035063](https://github.com/oficina-soat/oficina-os-service/actions/runs/29354035063), [Billing 29354014527](https://github.com/oficina-soat/oficina-billing-service/actions/runs/29354014527) e [Execution 29353972944](https://github.com/oficina-soat/oficina-execution-service/actions/runs/29353972944): os três jobs `deploy-service` aplicaram o manifest canônico do próprio repositório, aguardaram `successfully rolled out` no EKS e confirmaram a imagem publicada. O [Deploy Lab 29354488635](https://github.com/oficina-soat/oficina-infra/actions/runs/29354488635) também validou as três bases a partir dos repositórios de serviço e concluiu com sucesso sem cópias locais no `oficina-infra`.
- [x] `[D-OBS-SAGA-IMPL-001]` Instrumentar no `oficina-os-service` as métricas `saga.instances.started.count`, `saga.instances.completed.count`, `saga.instances.compensated.count`, `saga.instances.failed.count` e `saga.step.duration`, com dimensões categóricas `service`, `sagaType`, `step` e `reason`, além dos atributos estruturados `sagaId`, `sagaStep` e estado aplicável em logs e spans. Concluído localmente em 2026-07-14 no commit `9d842b1` do `oficina-os-service`, com versão `1.3.0`: a instrumentação ocorre após a transição persistida, ignora eventos duplicados, mede a duração real entre estados, usa somente motivos categóricos e adiciona `sagaId`, `sagaStep`, `sagaState`, `ordemServicoId` e `correlationId` aos logs, além de `sagaId`, `sagaStep`, `aggregateId` e `correlationId` ao span ativo. O `clean verify` aprovou 183 testes e 15 passos BDD, com JaCoCo de 95,04% de instruções e 76,28% de branches; o teste HTTP confirmou as séries `saga_instances_started_count` e `saga_step_duration` em `/q/metrics`. A ingestão e os widgets remotos foram posteriormente comprovados em `[D-NR-REM-003]`.
- [x] `[D-OBS-MP-COLLECT-IMPL-001]` Diagnosticar e corrigir por que as seis métricas `payment.provider.*`, embora implementadas no `oficina-billing-service`, não aparecem como séries `payment_provider_*` no inventário `Metric` do New Relic. Concluído em 2026-07-15: o bean inicializa no startup; `/q/metrics` expõe as seis famílias; o collector aplicado pelo run `29408706593` mantém a primeira amostra cumulativa; uma cobrança PIX sandbox retornou HTTP `201`; falhas controladas materializaram `provider_http_error` e `communication`; e o NerdGraph confirmou as seis famílias, labels canônicas e ausência de identificadores de alta cardinalidade. Evidência completa em [Evidência das Métricas do Mercado Pago no Lab](docs/observability/payment-provider-metrics-lab-evidence.md).
  - [x] Corrigir a inicialização tardia do bean com startup explícito e confirmar por teste automatizado que `payment.provider.enabled` é exposta em `/q/metrics` como `payment_provider_enabled` antes da primeira cobrança.
  - [x] Corrigir no manifesto Helm do collector a perda da primeira amostra durante a conversão cumulativa para delta, preservando séries de baixo tráfego com `cumulativetodelta.initial_value=keep`.
  - [x] Aplicar a configuração no `lab` e confirmar nos logs do collector que o scrape de `/q/metrics` permanece sem erros.
  - [x] Executar uma cobrança sandbox e uma falha controlada para materializar as seis famílias, confirmar labels canônicas e registrar a ingestão de `payment_provider_*` no inventário `Metric`.
- [x] Criar padrão de observabilidade.
- [x] Criar padrão de logs estruturados.
- [x] Criar propagação de `correlationId`.
- [x] Criar manifests Kubernetes base.
- [x] Criar pipeline padrão de CI/CD.
- [x] `[D-NR-IMPL-001]` Criar baseline executável do New Relic no `oficina-infra` com New Relic OpenTelemetry Collector via Helm, Secret Kubernetes esperado, endpoint OTLP/gRPC interno e coleta de logs, métricas e traces.
- [x] `[D-OBS-IMPL-001]` Propagar `OTEL_EXPORTER_OTLP_ENDPOINT`, `OTEL_EXPORTER_OTLP_PROTOCOL`, `OTEL_RESOURCE_ATTRIBUTES`, `DEPLOYMENT_ENVIRONMENT` e `OTEL_SERVICE_NAME` nos manifests dos três microsserviços.
- [x] `[D-OBS-IMPL-002]` Validar nos três microsserviços, por inspeção local e testes locais aplicáveis, a emissão de logs JSON, exposição de `/q/metrics`, health checks Quarkus e configuração de traces OpenTelemetry conforme [Validação local de observabilidade](docs/observability/observability-local-validation.md).
- [x] `[D-OBS-IMPL-003]` Instrumentar o `oficina-billing-service` com métricas de consumo da integração financeira Mercado Pago, conforme [Padrão de Observabilidade Distribuída](docs/observability/observability.md): quantidade de chamadas por provedor, método, status do provedor e desfecho; latência da chamada externa; valor financeiro por desfecho; indisponibilidade, timeout, erro de configuração e recusa de negócio. Concluído localmente em 2026-07-12 no commit `9e97be9` do `oficina-billing-service` (`project.version=1.1.0`) com as seis métricas `payment.provider.*`, histogramas de duração, distribuição de valores em BRL, categorias fechadas de desfecho/status/motivo e teste que impede IDs, CPF, e-mail ou `correlationId` como tags. O `clean verify` aprovou 119 testes, PostgreSQL/Testcontainers, LocalStack, arquitetura e exposição Prometheus, com JaCoCo de 93,56% de instruções e 80,07% de branches. A issue histórica `java:S3398` também foi corrigida; a análise SonarCloud da `develop` foi processada com sucesso e sem warnings, ficando a confirmação oficial das métricas, duplicação e zero issues para o workflow da `main`, pois a API do plano atual não expõe branches curtas.
- [x] `[D-OBS-IMPL-004]` Instrumentar métricas de persistência, idempotência, Outbox e mensageria nos três microsserviços: operações PostgreSQL/DynamoDB por resultado, latência de persistência, backlog de Outbox, tentativas de publicação, falhas por tópico/eventType, consumo SQS por fila, mensagens enviadas para DLQ, retries de idempotência e conflitos de chave. As dimensões devem ficar restritas a serviço, operação, banco/recurso, tópico, fila, `eventType`, status e erro categorizado, sem identificadores de entidade. Concluído localmente em 2026-07-13 nos commits `31d17c2` do `oficina-os-service` (`project.version=1.2.3`), `7909f32` do `oficina-billing-service` (`project.version=1.1.1`) e `3483655` do `oficina-execution-service` (`project.version=1.0.16`). A instrumentação Micrometer cobre operações PostgreSQL e DynamoDB, backlog e publicação da Outbox, publicação e consumo SNS/SQS, aproximação do redrive para DLQ pelo `ApproximateReceiveCount` e conflitos/retries de idempotência apenas com dimensões categóricas. As validações `clean verify` aprovaram 179 testes e 15 passos BDD no OS, 124 testes no Billing e 104 testes no Execution, com JaCoCo de 94,99%, 93,22% e 93,13% de instruções e 76,10%, 78,32% e 79,01% de branches, respectivamente. As três análises da branch `develop` foram enviadas ao SonarCloud, importaram os relatórios JaCoCo e foram processadas com sucesso, sem warnings; a consulta local ao Quality Gate ficou indisponível pela restrição da organização para branches não principais, mantendo o CI remoto como validação definitiva do gate.
- [x] `[D-AWS-IMPL-001]` Encerrar a normalização direta de valores legados de conta, região e ambiente AWS nos repositórios antigos. Decisão: `oficina-app`, `oficina-infra-db` e `oficina-infra-k8s` permanecem apenas como fontes históricas ou origem de cópia controlada; as normalizações aplicáveis foram concentradas nos destinos canônicos, especialmente `oficina-infra`, conforme [Conta, região e ambientes AWS](docs/infrastructure/aws-environments.md), [Plano de migração para o repositório unificado de infraestrutura](docs/infrastructure/infrastructure-migration-plan.md) e [Nomes de runtime, secrets e infraestrutura](docs/infrastructure/infra-runtime-naming.md). Ajustes diretos continuam permitidos apenas em `oficina-auth-lambda` quando a mudança pertencer ao próprio componente serverless.
- [x] Planejar a migração de `oficina-infra-db` e `oficina-infra-k8s` para o novo repositório unificado de infraestrutura.
- [x] Criar baseline executável do RDS PostgreSQL compartilhado no `oficina-infra`, com Terraform e bootstrap de databases, usuários e secrets independentes para OS e Billing.
- [x] Migrar e adaptar EKS, ECR, API Gateway e Kubernetes compartilhado de `oficina-infra-k8s` para `oficina-infra`, removendo dependências operacionais do `oficina-app`.
- [x] Definir as rotas públicas de negócio do API Gateway para os três microsserviços, conforme [Rotas públicas do API Gateway](docs/infrastructure/api-gateway-public-routes.md).
- [x] `[D-INFRA-IMPL-001]` Adicionar DynamoDB do `oficina-execution-service` e mensageria da Fase 4 ao `oficina-infra`.
- [x] Criar ambiente local integrado no `oficina-infra` com PostgreSQL, DynamoDB Local, LocalStack SNS/SQS, bootstrap de dependências e profile opcional para os três microsserviços.
- [x] Migrar workflows e scripts operacionais úteis de `oficina-infra-db` e `oficina-infra-k8s` para `oficina-infra`, normalizando state, secrets, conta, região e ambiente.
- [x] `[D-REL-IMPL-001]` Criar checklist de deploy independente.
- [x] `[D-OPS-IMPL-001]` Criar runbooks mínimos.
- [x] Criar checklist final de entrega da Fase 4, cobrindo repositórios, cobertura, Swagger/OpenAPI, vídeo, PDF, diagrama geral, estratégia de Saga, justificativa de microsserviços e tecnologias.
- [x] `[D-DIAG-IMPL-001]` Criar diagrama geral da arquitetura final com microsserviços, bancos, mensageria, Kubernetes, observabilidade e integração Mercado Pago.
- [x] `[D-VIDEO-IMPL-001]` Preparar roteiro do vídeo de demonstração de até 15 minutos, incluindo fluxo completo da OS, Saga com falha/compensação, deploy automatizado e rastreamento distribuído. Concluído localmente em 2026-07-13 com o [Roteiro do Vídeo de Demonstração da Fase 4](docs/delivery/video-demonstration-script.md), que reserva `14min30s` para arquitetura, CI/CD, rollout Kubernetes, caminho feliz, compensação por falha de estoque, correlação no New Relic, Mercado Pago sandbox, testes, cobertura, Quality Gate e OpenAPI, além de registrar pré-condições, segurança da gravação, contingências e critérios de aceite. A gravação, publicação e vinculação das evidências permanecem nos itens remotos `[D-VIDEO-EVID-001]` e `[D-DELIVERY-EVID-001]`.

### Épico D — Simulação operacional

- [ ] `[D-SIM-IMPL-001]` Criar no `oficina-infra` o núcleo determinístico do simulador de operação cotidiana da oficina, consumindo as APIs públicas reais somente em ambientes não produtivos. Disponibilizar uma CLI reproduzível, configurável por duração, intensidade, perfil e `seed`, com modo `dry-run`, limites explícitos de volume e custo, autenticação segura sem registrar tokens e narrativa legível no console com timestamp, cenário e resultado HTTP.
- [ ] `[D-SIM-IMPL-002]` Implementar o catálogo e a distribuição ponderada dos cenários do simulador: chegada e cadastro de clientes e veículos, abertura e evolução de ordens de serviço como fluxo predominante; catálogo, estoque, orçamento, execução e pagamento com frequência intermediária; e cadastro, ativação, bloqueio ou inativação de usuários com baixa frequência. Incluir caminhos felizes e falhas controladas, como orçamento recusado, estoque insuficiente, pagamento recusado, retry idempotente, payload inválido e operação não autorizada.
- [ ] `[D-SIM-IMPL-003]` Implementar as proteções e o diagnóstico do simulador: restringir alterações aos dados sintéticos criados pela própria execução, marcar esses dados, mascarar identificadores de correlação, aguardar efeitos assíncronos, oferecer cleanup opcional e classificar automaticamente falhas esperadas e regressões. Emitir resumo final com eventos executados, aprovados, esperadamente rejeitados e inesperadamente falhos.
- [ ] `[D-SIM-IMPL-004]` Validar e documentar o simulador com testes automatizados do motor determinístico e da classificação de resultados, exemplos de perfis e comandos, execução local em `dry-run` e uma execução controlada contra o ambiente não produtivo. Skills específicas podem ser criadas posteriormente como interface de configuração, execução e diagnóstico, sem substituir o script reproduzível; um subagente permanece opcional apenas para sessões exploratórias.

---

## Validações remotas e evidências externas

Esta seção concentra tarefas que dependem de ambiente externo, credenciais administrativas, execução real em AWS, SonarCloud, GitHub, New Relic, gravação de vídeo ou publicação de evidências. Elas não devem ser tratadas como próxima tarefa de implementação por agentes, salvo pedido explícito do usuário.

### Épico B2 — CI, qualidade e governança remota

- [x] `[B2-CI-REM-000]` Configurar SonarCloud nos três repositórios de microsserviços antes da homologação dos PRs: criar ou vincular os projetos no SonarCloud, configurar `SONAR_TOKEN` como secret GitHub e usar análise baseada em CI pelo SonarScanner for Maven. Ajustado em 2026-07-11 para substituir a dependência de Automatic Analysis, que não importa cobertura, por envio explícito de `target/jacoco-report/jacoco.xml` no workflow `service-ci-validate`.
- [x] `[B2-CI-REM-001]` Registrar evidência remota da execução BDD no CI quando os pipelines finais estiverem homologados. Evidência: `Service CI/CD` em `main` do `oficina-os-service` concluído com sucesso em 2026-07-10 no [run 29116182460](https://github.com/oficina-soat/oficina-os-service/actions/runs/29116182460), incluindo o job `service-ci-validate`; o README do serviço registra que o Cucumber BDD roda no ciclo Maven `verify`.
- [x] `[B2-CI-REM-002]` Registrar evidência remota do Quality Gate SonarCloud aprovado e da cobertura mínima de 80% nos três microsserviços. Ajuste complementar em 2026-07-11: os workflows devem executar SonarCloud após o Maven `verify`, falhar quando `target/jacoco-report/jacoco.xml` não existir e aguardar o Quality Gate, garantindo que a cobertura apareça no dashboard SonarCloud. O padrão de agentes também passou a exigir validação pré-commit equivalente nos microsserviços: `clean verify`, checagem do XML JaCoCo e SonarScanner local quando `SONAR_TOKEN` estiver disponível. A espera local por Quality Gate só deve ser exigida quando o SonarCloud expuser essa consulta para a branch ou PR analisado.
- [x] `[B2-GH-REM-001]` Confirmar proteção da branch `main` nos três repositórios de microsserviços, com PR obrigatório e checagens automáticas exigidas antes de merge. A política canônica foi documentada em [Proteção da branch main dos microsserviços](docs/delivery/github-branch-protection.md). Concluído remotamente em 2026-07-13: a [revalidação dos Rulesets](docs/delivery/github-branch-protection-evidence.md) confirmou que `oficina-os-service`, `oficina-billing-service` e `oficina-execution-service` possuem Ruleset ativo na branch padrão, PR obrigatório e `service-ci-validate` como única checagem obrigatória, vinculada ao GitHub Actions; `develop-validate` não é mais exigido.

### Épico B2 — Integração financeira remota

- [x] `[B2-MP-REM-001]` Habilitar a integração Mercado Pago em modo sandbox no ambiente `lab` do `oficina-billing-service`, usando GitHub Secret fora do Git para `OFICINA_MERCADO_PAGO_ACCESS_TOKEN` e GitHub Variable para `OFICINA_MERCADO_PAGO_ENABLED=true`, conforme [Nomes de runtime, secrets e infraestrutura](docs/infrastructure/infra-runtime-naming.md). Configurar `OFICINA_MERCADO_PAGO_API_URL` e `OFICINA_MERCADO_PAGO_PAYER_EMAIL` somente quando for necessário sobrescrever os defaults do serviço. Evidenciar que o Deployment recebeu a configuração sem expor o token. Concluído remotamente em 2026-07-13: a variável foi confirmada como `true`, o secret foi consumido de forma mascarada, o Billing foi publicado e implantado pelo [run 29279434097](https://github.com/oficina-soat/oficina-billing-service/actions/runs/29279434097), e o [run 29281650258](https://github.com/oficina-soat/oficina-infra/actions/runs/29281650258) criou `oficina-billing-service-mercado-pago-env` e atualizou o checksum do Deployment sem expor a credencial. Evidências e tentativa de cobrança registradas em [Evidência da Integração Mercado Pago no Lab](docs/delivery/mercado-pago-sandbox-evidence.md).
- [x] `[B2-MP-EVID-001]` Executar uma cobrança PIX sandbox pelo fluxo real `POST /api/v1/pagamentos` e registrar evidências no [Checklist Final de Entrega da Fase 4](docs/delivery/phase-4-delivery-checklist.md): request e response locais com `provedor=mercado-pago`; `pagamentoId`; `transacaoExternaId`; referência externa ou `external_reference` associada ao `pagamentoId`; comprovação no painel ou API sandbox do Mercado Pago; logs e traces com `correlationId`; e evento financeiro correspondente (`pagamentoSolicitado`, `pagamentoConfirmado` ou `pagamentoRecusado`) no New Relic. Concluído remotamente em 2026-07-13: a cobrança retornou HTTP `201` com `pagamentoId=1d43fc0b-8802-4b20-bc7f-483c722e3468`, `provedor=mercado-pago` e `transacaoExternaId=1327656764`; a API do Mercado Pago confirmou `external_reference` igual ao `pagamentoId`; e o New Relic retornou exatamente um `pagamentoSolicitado` com o mesmo `aggregateId`, `eventId` e `traceId`. Evidência completa em [Evidência da Integração Mercado Pago no Lab](docs/delivery/mercado-pago-sandbox-evidence.md).

### Épico B2 — Persistência, mensageria e idempotência remotas

- [x] `[B2-BILL-DB-REM-001]` Publicar e aplicar no `lab` a imagem do `oficina-billing-service` que contém `[B2-BILL-DB-IMPL-001]` e `[B2-BILL-EVENTSTORE-IMPL-001]`, confirmando que orçamento, pagamento, projeções financeiras, eventos consumidos e Outbox gravam no database `oficina_billing`, que o modo em memória não está ativo no pod e que os dados persistem após restart ou rollout. Concluído remotamente em 2026-07-13: a validação identificou e corrigiu a inicialização tardia do worker no commit `ee9c36c`; o [PR 22](https://github.com/oficina-soat/oficina-billing-service/pull/22) e o [run 29289563605](https://github.com/oficina-soat/oficina-billing-service/actions/runs/29289563605) publicaram e implantaram `1.1.2`; consultas somente leitura comprovaram orçamento, pagamento Mercado Pago, projeção financeira, evento consumido, Outbox publicada e idempotência em `oficina_billing`; e todos os registros permaneceram idênticos após a substituição controlada do pod. Evidência completa em [Evidência PostgreSQL do Billing no Lab](docs/delivery/billing-postgresql-lab-evidence.md).
- [x] `[B2-OS-DB-REM-001]` Após `[B2-OS-DB-IMPL-001]`, validar no `lab` que Cliente, Veículo, Ordem de Serviço, histórico e Saga são gravados no database `oficina_os`, com usuário e secret próprios, sem acesso ao database `oficina_billing`, e que os dados sobrevivem a restart de pod. Concluído remotamente em 2026-07-13 com `oficina-os-service:1.2.3`: uma OS sentinela criada pelo fluxo HTTP persistiu Cliente, Veículo, OS, histórico, Saga, histórico da Saga, Outbox e idempotência no database `oficina_os`; o usuário `oficina_os_user` recebeu `permission denied` ao tentar acessar `oficina_billing`; e a API, as contagens e os registros permaneceram idênticos após a substituição controlada do pod. Evidência completa em [Evidência PostgreSQL do Serviço de OS no Lab](docs/delivery/os-postgresql-lab-evidence.md).
- [x] `[B2-EXEC-DDB-REM-001]` Após `[B2-EXEC-DDB-IMPL-001]`, validar no `lab` que catálogo, estoque, execuções, Outbox e idempotência do `oficina-execution-service` são gravados nas tabelas DynamoDB `oficina-execution-lab-*`, usando IAM/runtime do serviço e sem fallback para store em memória. Concluído remotamente em 2026-07-13 com `oficina-execution-service:1.0.16`: fluxos HTTP reais persistiram peça, serviço, saldo e movimento de estoque, execução e histórico, duas entradas Outbox e cinco registros idempotentes nas cinco tabelas canônicas; o runtime AWS operou sem endpoint local ou credenciais estáticas no Deployment; e a API, as contagens e os itens permaneceram idênticos após a substituição controlada do pod. Evidência completa em [Evidência DynamoDB do Serviço de Execução no Lab](docs/delivery/execution-dynamodb-lab-evidence.md).
- [x] `[B2-IDEMP-REM-001]` Validar no `lab` a idempotência persistente dos três microsserviços: repetir uma requisição mutável com a mesma chave e payload deve retornar o mesmo resultado; repetir a chave com payload divergente deve retornar conflito; e o comportamento deve permanecer igual após restart do pod responsável. Concluído remotamente em 2026-07-14 com `oficina-os-service:1.2.3`, `oficina-billing-service:1.1.2` e `oficina-execution-service:1.0.16`: operações `POST` reais retornaram HTTP `201` com identificadores estáveis no replay, HTTP `409` com `IDEMPOTENCY_CONFLICT` para a mesma chave e payload divergente, e mantiveram os mesmos resultados após `rollout restart` simultâneo dos três Deployments. Evidência completa em [Evidência de Idempotência Persistente no Lab](docs/delivery/idempotency-lab-evidence.md).
- [x] `[B2-MSG-REM-001]` Validar no `lab` a mensageria real SNS/SQS da Fase 4: repetir o deploy após as correções `af4399c` e `cc30057`, confirmar a substituição das managed policies content-addressed sem `iam:CreatePolicyVersion`, criar o novo managed node group com `LabRole` antes de remover o anterior e comprovar que os três microsserviços iniciam sem negações IAM. Concluído remotamente em 2026-07-14: o único node group ativo usa `LabRole`; as policies content-addressed estão em `v1`; OS `1.2.4`, Billing `1.1.2` e Execution `1.0.17` ficaram saudáveis e sem negações IAM; o evento `ordemDeServicoCriada` saiu da Outbox, atravessou SNS/SQS, foi persistido no Billing e criou a projeção DynamoDB no Execution; as filas e a DLQ do caminho feliz ficaram vazias; e uma mensagem inválida foi retentada seis vezes e redirecionada à DLQ. Evidência completa em [Evidência de Mensageria SNS/SQS no Lab](docs/delivery/messaging-lab-evidence.md).
- [x] `[B2-AUTH-USERS-REM-001]` Publicar no `lab` as versões de `[B2-AUTH-USERS-IMPL-001]`, incluindo `oficina-os-service` `1.2.2` ou superior com as correções do SonarCloud, aplicando primeiro o `oficina-infra` e depois o workflow `Deploy Lambda Lab`. Concluído remotamente em 2026-07-14 com `oficina-os-service:1.2.4` e `oficina-auth-lambda:1.1.4`: cadastro, ativação de uso único, login, bloqueio, reativação com senha preservada e inativação foram exercitados pelas APIs reais; os eventos atravessaram Outbox/SNS/SQS e atualizaram de forma idempotente e ordenada o PostgreSQL da autenticação; o caminho homologado não acrescentou mensagens às DLQs; e duas mensagens diagnósticas anteriores comprovaram seis retries e redrive controlado. A homologação também corrigiu datasource/decoder nativo, corrida no bootstrap compartilhado, issuer JWT e serialização nativa do token de ativação nos PRs 49 a 52. Evidência completa em [Evidência da integração remota de usuários da autenticação](docs/delivery/auth-users-lab-evidence.md).
- [x] `[B2-DB-MSG-EVID-001]` Registrar no [Checklist Final de Entrega da Fase 4](docs/delivery/phase-4-delivery-checklist.md) evidências de bancos e mensageria reais: consultas ou screenshots mascarados do RDS/DynamoDB, rollout/restart com dados preservados, outputs Terraform ou nomes físicos de recursos, mensagens SNS/SQS/DLQ e logs/traces correlacionados por `correlationId`. Concluído em 2026-07-15 com uma matriz consolidada de RDS, databases isolados, cinco tabelas DynamoDB, recursos SNS/SQS/DLQ, IAM/runtime EKS, preservação após restart e correlação do fluxo Outbox por `correlationId` e `eventId`, vinculada aos relatórios remotos detalhados.

### Épico D — AWS, New Relic e entrega final

- [x] `[D-NR-REM-000]` Preparar o acesso New Relic antes da validação de observabilidade: confirmar a conta New Relic, gerar `NEW_RELIC_LICENSE_KEY`, configurar o secret no repositório ou na organização GitHub, manter `INSTALL_NEW_RELIC_OTEL_COLLECTOR=auto` ou usar `true` para exigir a execução remota, e confirmar acesso ao contexto AWS/EKS do cluster `eks-lab`, conforme [Padrão de Observabilidade Distribuída](docs/observability/observability.md) e [Nomes de runtime, secrets e infraestrutura](docs/infrastructure/infra-runtime-naming.md). Evidência conferida em 2026-07-10: o workflow `Deploy Lab` do `oficina-infra` concluiu com sucesso no [run 29125719440](https://github.com/oficina-soat/oficina-infra/actions/runs/29125719440), o contexto EKS `eks-lab` estava acessível e o Secret Kubernetes `new-relic-license-key` existia no namespace `newrelic`.
- [x] `[D-NR-REM-001]` Instalar e validar o New Relic OpenTelemetry Collector no cluster `eks-lab` quando `NEW_RELIC_LICENSE_KEY` e contexto AWS/EKS estiverem disponíveis. Evidência conferida em 2026-07-10: o release Helm `nr-k8s-otel-collector` ficou `deployed` no namespace `newrelic`, o Deployment, o DaemonSet e o `kube-state-metrics` ficaram `1/1 Running`, o Service interno `nr-k8s-otel-collector-gateway` expôs OTLP/gRPC e OTLP/HTTP, e os logs do DaemonSet registraram `Everything is ready` com o receiver `filelog` lendo os arquivos de `oficina-os-service`, `oficina-billing-service` e `oficina-execution-service`. A causa do `CrashLoopBackOff` anterior foi corrigida no node atual ajustando o IMDS `HttpPutResponseHopLimit` para `2`; a persistência foi registrada no módulo EKS do repositório `oficina-infra`.
- [x] `[D-NR-REM-002]` Criar dashboards mínimos no New Relic para `oficina-os-service`, `oficina-billing-service` e `oficina-execution-service`, filtrando por `service.name`, `service.namespace=oficina` e `deployment.environment=lab`. Templates locais preparados em [Dashboards New Relic](docs/observability/new-relic-dashboards.md) e [Dashboard operacional dos microsserviços](docs/observability/new-relic-dashboard-operational.json). Evidência conferida em 2026-07-11: o dashboard remoto `Oficina SOAT - Microsservicos Lab` foi atualizado via NerdGraph na conta `8254132`, mantendo a página `Operacional` com 15 widgets. O troubleshooting corrigiu os painéis de falhas para usar logs estruturados com `numeric(http.status) >= 400`, trocou CPU, memória, restarts e readiness para métricas Kubernetes por `k8s.deployment.name`, confirmou dados em `Metric` para os três serviços e validou todos os NRQLs do template.
- [x] `[D-NR-REM-003]` Após `[D-OBS-SAGA-IMPL-001]`, completar a visão adicional da Saga no New Relic para o `oficina-os-service`, cobrindo Sagas iniciadas, finalizadas, compensadas, em falha manual e duração por etapa. Concluído remotamente em 2026-07-15 com `oficina-os-service:1.3.0`: um cenário sentinela iniciou e compensou uma Saga real; `/q/metrics` confirmou início, compensação por `operational_failure` e duração por etapa; logs estruturados confirmaram `sagaId`, `sagaStep`, `sagaState`, `reason`, `correlationId`, `traceId` e `spanId`; e o dashboard `Oficina SOAT - Saga e Ordem de Servico Lab`, GUID `ODI1NDEzMnxWSVp8REFTSEJPQVJEfGRhOjEyODcwMzcz`, foi atualizado e relido via NerdGraph com 14 widgets. Os cinco painéis principais usam as métricas `saga_instances_*` e `saga_step_duration_seconds`, e todos os 13 NRQLs executáveis passaram sem erro. Evidência completa em [Evidência das Métricas e do Dashboard da Saga no Lab](docs/observability/saga-metrics-lab-evidence.md).
- [x] `[D-NR-REM-004]` Criar alertas mínimos no New Relic para indisponibilidade, erro HTTP elevado, latência elevada, Outbox parada, Outbox com falha, DLQ, Saga em falha manual, pagamento indisponível e banco indisponível. Concluído remotamente em 2026-07-15 com a policy `Oficina SOAT - Alertas Minimos Lab`, ID `7756164`, contendo nove condições NRQL ativas. Todas as consultas foram validadas antes da criação, e a releitura NerdGraph confirmou as nove condições com `enabled=true`. Nenhum destination ou workflow de notificação foi criado sem autorização explícita. Evidência completa em [Evidência dos Alertas Mínimos no New Relic](docs/observability/new-relic-alerts-lab-evidence.md).
- [x] `[D-NR-REM-005]` Executar teste de ponta a ponta no ambiente `lab` gerando uma Ordem de Serviço com caminho feliz e uma falha compensada, confirmando correlação por `correlationId` entre logs, traces, métricas e eventos. Execução, troubleshooting e reexecução final registrados em 2026-07-11 no [Relatório D-NR-REM-005 — E2E no ambiente lab](docs/observability/d-nr-rem-005-e2e-lab-report.md): o fluxo REST passou, `Metric`, `Span`, `Log` com `correlationId` e eventos de Outbox por `domainEventType`/`event.type` foram comprovados no New Relic para os três serviços após o rollout de `oficina-os-service:1.0.4`, `oficina-billing-service:1.0.5` e `oficina-execution-service:1.0.4`.
- [x] `[D-NR-REM-006]` Após `[D-OBS-MP-COLLECT-IMPL-001]`, criar visão New Relic para consumo Mercado Pago no `oficina-billing-service`, usando as métricas de provedor financeiro definidas no [Padrão de Observabilidade Distribuída](docs/observability/observability.md): volume de chamadas, taxa de sucesso/recusa/erro, latência p95/p99, valor total por desfecho, indisponibilidade por motivo e correlação com logs/traces por `correlationId`. Concluído remotamente em 2026-07-15 com o dashboard `Oficina SOAT - Mercado Pago Lab`, GUID `ODI1NDEzMnxWSVp8REFTSEJPQVJEfGRhOjEyODg3MzE0`, contendo 11 widgets. As dez consultas NRQL passaram sem erro; nove retornaram dados reais das cobranças e falhas controladas, e a entidade foi relida após a criação. Evidência completa em [Evidência do Dashboard Mercado Pago no Lab](docs/observability/mercado-pago-dashboard-lab-evidence.md).
- [x] `[D-NR-REM-007]` Criar ou complementar visão New Relic de persistência e mensageria para os três microsserviços, usando as métricas de `[D-OBS-IMPL-004]`: latência e erro de PostgreSQL/DynamoDB, backlog e falhas de Outbox, volume de publicação por `eventType`, consumo SQS, DLQs, retries de idempotência e conflitos de chave. Concluído remotamente em 2026-07-14 com o dashboard `Oficina SOAT - Persistencia e Mensageria Lab`, GUID `ODI1NDEzMnxWSVp8REFTSEJPQVJEfGRhOjEyODgzNTkw`, contendo 10 widgets. Consultas representativas de persistência, Outbox, publicação/consumo, DLQ e idempotência retornaram dados reais via NerdGraph sem erros NRQL; o registro consolidado está em [Dashboards New Relic](docs/observability/new-relic-dashboards.md).
- [x] `[D-NR-EVID-001]` Registrar evidências de observabilidade distribuída no checklist final da Fase 4, incluindo links ou identificadores dos dashboards, alertas, traces e consultas de logs usadas na validação. Concluído em 2026-07-15 com os GUIDs dos quatro dashboards, policy `7756164`, links das evidências remotas, `correlationId` dos cenários E2E e consultas NRQL representativas de logs, Saga, Mercado Pago e DLQ.
- [x] `[D-AWS-REM-001]` Aplicar o RDS PostgreSQL compartilhado em AWS usando valores variáveis do ambiente `lab`, como `vpc_id`, subnets e security groups resolvidos por Terraform outputs, variáveis de pipeline ou descoberta em tempo de deploy. Evidência conferida em 2026-07-10: a instância `oficina-postgres-lab` estava `available`, com endpoint RDS, security group e subnet group resolvidos no ambiente AWS `lab`.
- [x] `[D-API-REM-001]` Materializar e validar no `oficina-infra` as rotas públicas do API Gateway quando os backends reais e `integration_uri` dos microsserviços estiverem disponíveis no ambiente `lab`. Evidência conferida em 2026-07-10: o HTTP API `eks-lab-http-api` expôs rotas específicas para os três microsserviços; chamadas públicas representativas retornaram respostas dos serviços corretos e endpoints operacionais como `/q/health` e `/api/v1/status` permaneceram sem rota pública.
---

## Melhorias futuras

Esta seção registra evoluções desejáveis que não fazem parte da sequência atual de implementação, homologação ou entrega. Seus itens não devem ser tratados como a “próxima tarefa” enquanto não forem explicitamente promovidos para o [Backlog orientado a agentes](#backlog-orientado-a-agentes).

- [ ] `[FUT-AUTH-DB-001]` Isolar o store PostgreSQL da autenticação em database e usuário próprios, substituindo o database legado genérico `app` por nomes canônicos como `oficina_auth` e `oficina_auth_user`. A evolução deve abranger Terraform e bootstrap do `oficina-infra`, secret de conexão exclusivo, configuração das Lambdas `auth-lambda` e `auth-sync-lambda`, migração segura de usuários, papéis, hashes BCrypt e tokens de ativação, privilégio mínimo sem acesso aos databases `oficina_os` e `oficina_billing`, compatibilidade de rollback e validação de login e sincronização após a migração. O cadastro operacional continua pertencendo ao `oficina-os-service` no database `oficina_os`; somente a projeção necessária ao login e as credenciais pertencem ao database de autenticação.

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

O próximo item da sequência é `[D-SIM-IMPL-001]`: criar no `oficina-infra` o núcleo determinístico e a CLI segura do simulador de operação cotidiana. Em seguida devem ser executados, nesta ordem, `[D-SIM-IMPL-002]`, `[D-SIM-IMPL-003]` e `[D-SIM-IMPL-004]`.

As validações remotas prioritárias foram concluídas. `[FUT-AUTH-DB-001]` permanece fora da sequência ativa e só poderá ser promovido depois das quatro tarefas da simulação. Os itens de encerramento final continuam deliberadamente no fim do roadmap.

---

## Encerramento final da entrega

Estes itens ficam deliberadamente no fim do roadmap e só devem ser executados quando os materiais finais estiverem disponíveis:

- [ ] `[D-DELIVERY-EVID-001]` Registrar data de entrega da Fase 4, participantes, links dos repositórios e link do vídeo no checklist final ou no documento de entrega.
- [ ] `[D-VIDEO-EVID-001]` Registrar evidências finais do vídeo de demonstração de até 15 minutos após gravação e homologação do ambiente.
