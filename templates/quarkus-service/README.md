# Template Quarkus de Microsservico

## Objetivo

Template base para criar ou normalizar os repositorios:

- `oficina-os-service`
- `oficina-billing-service`
- `oficina-execution-service`

O template preserva a estrutura do `oficina-app`, usando Quarkus e extensoes Quarkus. Dependencias que variam por tipo de persistencia ficam separadas por perfil Maven.

## Versoes

- Quarkus Platform: `3.37.0`
- Quarkiverse Amazon Services: `3.19.0`
- Java: `25`

As versoes foram verificadas no Maven Central em 2026-06-28.

## Como usar

Copiar o conteudo deste diretorio para o repositorio do microsservico destino e ajustar:

- `artifactId`
- `version`
- `quarkus.application.name`
- pacote Java base
- perfil de persistencia
- migrations, seeds e configuracoes especificas do servico

Comandos esperados:

```bash
./mvnw test
./mvnw verify
./mvnw package
```

Enquanto o wrapper Maven nao existir no repositorio destino, usar:

```bash
mvn test
mvn verify
mvn package
```

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

Usado por todos os servicos:

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

## Configuracoes

`application.properties` contem somente configuracoes comuns, derivadas do `oficina-app`:

- nome da aplicacao via `OTEL_SERVICE_NAME`
- Swagger UI
- logs JSON
- metricas Prometheus em `/q/metrics`
- traces OpenTelemetry
- health checks SmallRye
- JWT com issuer/audience atuais

Para servicos PostgreSQL, incorporar os valores de `application-postgresql.properties.example`.

Para o `oficina-execution-service`, incorporar os valores de `application-dynamodb.properties.example`.

## Health checks

O template mantem o padrao atual do `oficina-app`:

- extensao `quarkus-smallrye-health`
- endpoints padrao do Quarkus em `/q/health`, `/q/health/live` e `/q/health/ready`
- health fora do OpenAPI por `quarkus.smallrye-health.openapi.included=false`
- health excluido de traces por `quarkus.otel.traces.suppress-application-uris`

Health checks customizados devem ser adicionados apenas quando o servico tiver dependencia operacional que precise de verificacao explicita.

## Migrations

Servicos PostgreSQL devem usar Flyway com scripts em:

```text
src/main/resources/db/migration/
```

Baselines propostas:

- `docs/postgres-migrations-decomposition.md`

O `oficina-execution-service` nao usa migrations PostgreSQL.

## Limites

- Nao criar biblioteca Java compartilhada entre microsservicos.
- Nao mover codigo de aplicacao para o `oficina-platform`.
- Nao acessar banco de outro microsservico.
- Nao adicionar extensoes que nao sejam Quarkus ou Quarkiverse sem nova decisao documentada.
