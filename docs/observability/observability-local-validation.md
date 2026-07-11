# Validação local de observabilidade

Este registro fecha a validação local do item `D-OBS-IMPL-002` no [Roadmap](../../ROADMAP.md) e complementa o [Padrão de Observabilidade Distribuída](observability.md).

A validação foi executada inicialmente em 2026-07-04 por inspeção dos três microsserviços e por testes locais aplicáveis. Em 2026-07-11, a validação foi atualizada após o troubleshooting do [Relatório D-NR-REM-005 — E2E no ambiente lab](d-nr-rem-005-e2e-lab-report.md), cobrindo `quarkus.otel.traces.exporter=cdi`, instrumentação HTTP, MDC em campos planos e logs estruturados de HTTP, Outbox e eventos. Ela não substitui a validação remota do New Relic, do EKS `lab`, dos dashboards, alertas ou traces reais, que permanecem apartados em [Validações remotas e evidências externas](../../ROADMAP.md#validações-remotas-e-evidências-externas).

## Resultado

| Serviço | Inspeção local | Teste local adicionado | Suíte executada |
|---|---|---|---|
| `oficina-os-service` | `pom.xml` contém `quarkus-smallrye-health`, `quarkus-micrometer-registry-prometheus`, `quarkus-opentelemetry` e `quarkus-logging-json`; `application.properties` define logs JSON, `/q/metrics`, health checks Quarkus e traces OpenTelemetry. | `src/test/java/br/com/oficina/os/interfaces/controllers/ObservabilityEndpointTest.java` | `./mvnw -B test -Ppostgresql`: 88 testes, sucesso. |
| `oficina-billing-service` | `pom.xml` contém `quarkus-smallrye-health`, `quarkus-micrometer-registry-prometheus`, `quarkus-opentelemetry` e `quarkus-logging-json`; `application.properties` define logs JSON, `/q/metrics`, health checks Quarkus e traces OpenTelemetry. | `src/test/java/br/com/oficina/billing/interfaces/controllers/ObservabilityEndpointTest.java` | `./mvnw -B test -Ppostgresql`: 41 testes, sucesso. |
| `oficina-execution-service` | `pom.xml` contém `quarkus-smallrye-health`, `quarkus-micrometer-registry-prometheus`, `quarkus-opentelemetry` e `quarkus-logging-json`; `application.properties` define logs JSON, `/q/metrics`, health checks Quarkus e traces OpenTelemetry. | `src/test/java/br/com/oficina/execution/interfaces/controllers/ObservabilityEndpointTest.java` | `./mvnw -B test -Pdynamodb`: 41 testes, sucesso. |

## Critérios verificados

- Logs JSON: os três serviços possuem `quarkus-logging-json`, `quarkus.log.console.json.enabled=${oficina.observability.json-logs.enabled}`, `quarkus.log.console.json.mdc.flat-fields=true` e campos adicionais para `service.name`, `service.namespace`, `service.version` e `deployment.environment`. O perfil `%test` mantém logs JSON desabilitados para legibilidade da suíte local; a emissão JSON do runtime `lab` é validada por inspeção de configuração.
- Logs de negócio e eventos: os três serviços emitem logs estruturados de requisições HTTP com `correlationId`; os pontos de Outbox e consumers emitem logs com `eventId`, `eventType`, `domainEventType`, `event.type`, `eventVersion`, `producer`, `aggregateId` e `messageStatus`, além de `topic` ou `consumer` quando aplicável.
- Métricas: os três serviços expõem `/q/metrics` com saída Prometheus; os testes locais validam status HTTP 200, corpo não vazio e presença de marcador `# HELP`.
- Health checks: os três serviços expõem `/q/health/live` e `/q/health/ready`; os testes locais validam status HTTP 200 e `status=UP`.
- Traces OpenTelemetry: os três serviços possuem `quarkus-opentelemetry`, `quarkus.otel.enabled=true`, `quarkus.otel.traces.exporter=cdi`, `quarkus.otel.instrument.vertx-http=true`, `quarkus.otel.traces.enabled=${oficina.observability.tracing.enabled}`, endpoint OTLP configurável por `OTEL_EXPORTER_OTLP_ENDPOINT`, protocolo configurável por `OTEL_EXPORTER_OTLP_PROTOCOL` e supressão dos endpoints operacionais. O perfil `%test` define `%test.quarkus.otel.traces.enabled=false` para não exportar spans durante a suíte local.

## Limites da validação

Não foram executados testes contra AWS, EKS `lab` ou backend New Relic. A instalação do collector, dashboards, alertas, traces reais e correlação ponta a ponta por `correlationId` continuam nos itens remotos `D-NR-REM-*` e `D-NR-EVID-001` do [Roadmap](../../ROADMAP.md).
