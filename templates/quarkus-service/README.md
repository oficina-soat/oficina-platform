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
- Java: `25`

As versões foram verificadas no Maven Central em 2026-06-28.

## Como usar

Copiar o conteúdo deste diretório para o repositório do microsserviço destino e ajustar:

- `artifactId`
- `version`
- `quarkus.application.name`
- pacote Java base
- perfil de persistência
- migrations, seeds e configurações específicas do serviço

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
- logs JSON
- métricas Prometheus em `/q/metrics`
- traces OpenTelemetry
- health checks SmallRye
- JWT com issuer/audience atuais

Para serviços PostgreSQL, incorporar os valores de `application-postgresql.properties.example`.

Para o `oficina-execution-service`, incorporar os valores de `application-dynamodb.properties.example`.

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

- [Proposta de Migrations PostgreSQL Decompostas](../../docs/postgres-migrations-decomposition.md)

O `oficina-execution-service` não usa migrations PostgreSQL.

## Limites

- Não criar biblioteca Java compartilhada entre microsserviços.
- Não mover código de aplicação para o `oficina-platform`.
- Não acessar banco de outro microsserviço.
- Não adicionar extensões que não sejam Quarkus ou Quarkiverse sem nova decisão documentada.
