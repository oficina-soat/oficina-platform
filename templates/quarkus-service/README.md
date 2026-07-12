# Template Quarkus de Microsserviço

## Objetivo

Template base para criar ou normalizar os repositórios:

- `oficina-os-service`
- `oficina-billing-service`
- `oficina-execution-service`

O template preserva a estrutura do `oficina-app`, usando Quarkus e extensões Quarkus. Dependências que variam por tipo de persistência ficam separadas por perfil Maven.

## Versões

- Quarkus Platform: `3.37.0`
- Quarkiverse Amazon Services: `3.19.0`
- Cucumber JVM: `7.34.4`
- Java: `25`

As versões do Quarkus e Quarkiverse foram verificadas no Maven Central em 2026-06-28. A versão do Cucumber JVM foi verificada no Maven Central em 2026-06-29.

## Como usar

Copiar o conteúdo deste diretório para o repositório do microsserviço destino e ajustar:

- `artifactId`
- `version`
- `quarkus.application.name`
- pacote Java base
- perfil de persistência
- migrations, seeds e configurações específicas do serviço

Para deploy em Kubernetes, usar também o [Template Kubernetes Base](../kubernetes/base/README.md) como referência de `Deployment`, `Service`, `ServiceAccount`, `ConfigMap`, probes, observabilidade e variáveis de runtime.

Para CI/CD, usar o [Template GitHub Actions para Microsserviços](../github-actions/README.md), que assume o `Dockerfile` deste diretório para publicar imagens versionadas no Amazon ECR, criar release GitHub e atualizar o `Deployment` do serviço no Amazon EKS.

Comandos esperados:

```bash
./mvnw test
./mvnw verify
./mvnw package
```

Enquanto o wrapper Maven não existir no repositório destino, usar:

```bash
mvn test
mvn verify
mvn package
```

Para usar o [Template GitHub Actions para Microsserviços](../github-actions/README.md) e o `Dockerfile`, o repositório destino deve possuir Maven Wrapper (`mvnw` e `.mvn/wrapper/`). Esse requisito mantém o mesmo padrão operacional do `oficina-app`, em que os workflows e o build de imagem executam `./mvnw`.

## Estrutura

```text
src/main/java/br/com/oficina/<dominio>/
  core/
    entities/
    exceptions/
    interfaces/
    usecases/
  interfaces/
    controllers/
    presenters/
  framework/
    db/
    messaging/
    web/
src/main/resources/
  application.properties
  application-postgresql.properties.example
  application-dynamodb.properties.example
```

## Perfis Maven

### Base

Usado por todos os serviços:

- REST
- Jackson
- OpenAPI
- Health
- JWT
- JSON logs
- Micrometer Prometheus
- OpenTelemetry
- REST Client
- testes Quarkus
- Cucumber JVM com JUnit Platform
- JaCoCo com cobertura mínima de 80%

O padrão de testes, BDD, cobertura e Quality Gate está definido em [Padrão BDD, Cobertura e Qualidade](../../docs/delivery/bdd-testing.md).

### PostgreSQL

Usar em:

- `oficina-os-service`
- `oficina-billing-service`

Comando:

```bash
mvn test -Ppostgresql
```

Inclui:

- Hibernate Reactive Panache
- Reactive PostgreSQL Client
- JDBC PostgreSQL
- Flyway
- Security JPA Reactive

### DynamoDB

Usar em:

- `oficina-execution-service`

Comando:

```bash
mvn test -Pdynamodb
```

Inclui:

- Quarkiverse Amazon DynamoDB
- Quarkiverse Amazon DynamoDB Enhanced

## Configurações

`application.properties` contém somente configurações comuns, derivadas do `oficina-app`:

- nome da aplicação via `OTEL_SERVICE_NAME`
- Swagger UI
- logs JSON com MDC em campos planos para `correlationId`, `traceId`, `spanId`, `eventType` e atributos operacionais
- métricas Prometheus em `/q/metrics`
- traces OpenTelemetry exportáveis por OTLP para New Relic
- health checks SmallRye
- JWT com issuer e audience canônica do serviço

No ambiente compartilhado, o backend canônico de observabilidade é New Relic, conforme o [Padrão de Observabilidade Distribuída](../../docs/observability/observability.md). O serviço deve manter `quarkus.otel.traces.exporter=cdi` fixado em `application.properties`, pois essa configuração é build-time no Quarkus. Use `OTEL_EXPORTER_OTLP_ENDPOINT` apontando para o New Relic OpenTelemetry Collector definido pelo repositório de infraestrutura. Para execução local controlada, desabilite tracing por `OFICINA_OBSERVABILITY_TRACING_ENABLED=false`, sem trocar o exporter para `none`.

Para serviços PostgreSQL, incorporar os valores de `application-postgresql.properties.example`.

Para o `oficina-execution-service`, incorporar os valores de `application-dynamodb.properties.example`.

Quando o serviço possuir persistência ou mensageria reais, ele também deve implementar validação fail-fast no startup conforme [Nomes de runtime, secrets e infraestrutura](../../docs/infrastructure/infra-runtime-naming.md#runtime-protegido-e-validação-fail-fast). Os profiles `prod` e `lab`, assim como o ambiente `lab`, não podem aceitar store em memória, endpoints locais, mensageria desabilitada, secrets obrigatórios vazios ou dependências inacessíveis. O template distingue telemetria local e de teste com `deployment.environment=local` e `deployment.environment=test`; isso não autoriza execução local com profile `prod`.

## Health checks

O template mantém o padrão atual do `oficina-app`:

- extensão `quarkus-smallrye-health`
- endpoints padrão do Quarkus em `/q/health`, `/q/health/live` e `/q/health/ready`
- health fora do OpenAPI por `quarkus.smallrye-health.openapi.included=false`
- health excluído de traces por `quarkus.otel.traces.suppress-application-uris`

Health checks customizados devem ser adicionados apenas quando o serviço tiver dependência operacional que precise de verificação explícita.

## Migrations

Serviços PostgreSQL devem usar Flyway com scripts em:

```text
src/main/resources/db/migration/
```

Baselines propostas:

- [Proposta de Migrations PostgreSQL Decompostas](../../docs/infrastructure/postgres-migrations-decomposition.md)

O `oficina-execution-service` não usa migrations PostgreSQL.

## Limites

- Não criar biblioteca Java compartilhada entre microsserviços.
- Não mover código de aplicação para o `oficina-platform`.
- Não acessar banco de outro microsserviço.
- Não adicionar extensões que não sejam Quarkus ou Quarkiverse sem nova decisão documentada.
