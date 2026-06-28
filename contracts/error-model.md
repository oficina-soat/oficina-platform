# Contrato de Erros REST

## Objetivo

Definir o formato padronizado de respostas de erro das APIs REST da plataforma da oficina mecânica.

Este contrato deve ser usado por `oficina-os-service`, `oficina-billing-service` e `oficina-execution-service` para manter respostas previsíveis, facilitar retries por clientes e acelerar troubleshooting em logs, traces e dashboards.

---

## Escopo

Este contrato se aplica a todas as APIs REST versionadas em:

```text
/api/v1
```

Eventos assíncronos, DLQs e erros de consumidores continuam regidos pelos contratos de mensageria, mas devem reutilizar os mesmos identificadores transversais (`correlationId` e `traceId`) quando houver relação com uma chamada HTTP.

---

## Princípios

- Toda resposta de erro deve usar `application/json`.
- Toda resposta de erro deve possuir um `code` estável e legível por máquina.
- Mensagens em `message` devem ser seguras para exposição ao consumidor da API.
- Detalhes internos, stack traces, queries, tokens, secrets e dados sensíveis não devem ser retornados no corpo da resposta.
- Todo erro deve ser rastreável em logs e traces por `correlationId`.
- Erros inesperados devem retornar uma mensagem genérica para o cliente e registrar detalhes técnicos apenas em logs internos.

---

## Headers Transversais

### Requisição

Clientes podem enviar o header:

```text
X-Correlation-Id: <identificador>
```

Quando informado, o valor deve ser propagado pelo serviço para logs, traces, chamadas HTTP internas e eventos de domínio relacionados.

Quando ausente, o serviço deve gerar um novo `correlationId`.

### Resposta

Toda resposta de erro deve retornar:

```text
X-Correlation-Id: <correlationId>
```

Quando houver instrumentação distribuída disponível, o serviço também deve retornar:

```text
traceparent: <w3c-trace-context>
```

O header `traceparent` deve seguir o padrão W3C Trace Context quando suportado pela stack de observabilidade.

---

## Formato Padrão

```json
{
  "timestamp": "2026-06-23T15:30:00Z",
  "status": 400,
  "error": "Bad Request",
  "code": "VALIDATION_ERROR",
  "message": "Requisicao invalida.",
  "path": "/api/v1/ordens-servico",
  "correlationId": "7f4d0c4b6b8a4bb8a2f49bb8f06e1c3d",
  "requestId": "d290f1ee-6c54-4b01-90e6-d701748f0851",
  "traceId": "4bf92f3577b34da6a3ce929d0e0e4736",
  "spanId": "00f067aa0ba902b7",
  "service": "oficina-os-service",
  "logReference": "oficina-os-service/2026-06-23/7f4d0c4b6b8a4bb8a2f49bb8f06e1c3d",
  "details": [
    {
      "field": "clienteId",
      "code": "REQUIRED",
      "message": "Campo obrigatório."
    }
  ]
}
```

### Campos

| Campo | Obrigatório | Descrição |
|---|---|---|
| `timestamp` | Sim | Data e hora do erro em ISO-8601 UTC. |
| `status` | Sim | Código HTTP numérico retornado. |
| `error` | Sim | Razão HTTP curta, como `Bad Request` ou `Conflict`. |
| `code` | Sim | Código funcional estável para tratamento por clientes. |
| `message` | Sim | Mensagem segura para exibição ou diagnóstico pelo consumidor. |
| `path` | Sim | Caminho chamado, incluindo `/api/v1`. |
| `correlationId` | Sim | Identificador transversal da operação, propagado entre serviços, eventos, logs e traces. |
| `requestId` | Não | Identificador único da requisição HTTP dentro do serviço que respondeu. |
| `traceId` | Não | Identificador do trace distribuído, quando houver instrumentação. |
| `spanId` | Não | Identificador do span atual, quando houver instrumentação. |
| `service` | Não | Nome canônico do serviço que gerou a resposta. |
| `logReference` | Não | Referência segura para localização do erro em logs ou dashboards internos. |
| `details` | Não | Lista de detalhes estruturados, principalmente erros de validação por campo. |

### Detalhes de Validação

O campo `details` deve ser usado para erros `400` ou `422` quando múltiplos campos do payload precisam ser explicados.

```json
{
  "field": "descricaoProblema",
  "code": "REQUIRED",
  "message": "Campo obrigatório."
}
```

| Campo | Obrigatório | Descrição |
|---|---|---|
| `field` | Não | Campo, parâmetro ou header relacionado ao erro. |
| `code` | Sim | Código específico do detalhe. |
| `message` | Sim | Mensagem segura sobre o detalhe. |

---

## Códigos HTTP Padronizados

| HTTP | Uso |
|---|---|
| `400 Bad Request` | Payload, parâmetro ou header inválido. |
| `401 Unauthorized` | Token JWT ausente, inválido ou expirado. |
| `403 Forbidden` | Token válido sem permissão para a operação. |
| `404 Not Found` | Recurso inexistente ou indisponível para o consumidor. |
| `409 Conflict` | Duplicidade, conflito de estado, saldo insuficiente ou conflito de idempotência. |
| `422 Unprocessable Entity` | Requisição sintaticamente válida, mas rejeitada por regra de negócio. |
| `429 Too Many Requests` | Limite de taxa excedido. |
| `500 Internal Server Error` | Falha inesperada no serviço. |
| `502 Bad Gateway` | Falha inválida ou inesperada em dependência síncrona. |
| `503 Service Unavailable` | Serviço ou dependência temporariamente indisponível. |
| `504 Gateway Timeout` | Timeout ao chamar dependência síncrona. |

---

## Códigos Funcionais Canônicos

| `code` | HTTP esperado | Uso |
|---|---:|---|
| `VALIDATION_ERROR` | 400 | Campos, query params, path params ou headers inválidos. |
| `AUTHENTICATION_REQUIRED` | 401 | Credencial ausente. |
| `AUTHENTICATION_INVALID` | 401 | JWT inválido, expirado ou com issuer/audience incompatível. |
| `ACCESS_DENIED` | 403 | Consumidor autenticado sem autorização. |
| `RESOURCE_NOT_FOUND` | 404 | Entidade inexistente. |
| `DUPLICATE_RESOURCE` | 409 | Tentativa de criar recurso já existente. |
| `INVALID_STATE_TRANSITION` | 409 | Operação incompatível com o estado atual da entidade. |
| `IDEMPOTENCY_KEY_REQUIRED` | 400 | Operação crítica exige `X-Idempotency-Key`. |
| `IDEMPOTENCY_IN_PROGRESS` | 409 | Chave já aceita e ainda em processamento. |
| `IDEMPOTENCY_CONFLICT` | 409 | Reuso de `X-Idempotency-Key` com payload divergente. |
| `BUSINESS_RULE_VIOLATION` | 422 | Regra de negócio rejeitou a operação. |
| `RATE_LIMIT_EXCEEDED` | 429 | Limite de taxa excedido. |
| `DEPENDENCY_FAILURE` | 502 | Dependência respondeu com falha inesperada. |
| `DEPENDENCY_UNAVAILABLE` | 503 | Dependência indisponível. |
| `DEPENDENCY_TIMEOUT` | 504 | Timeout ao chamar dependência. |
| `INTERNAL_ERROR` | 500 | Falha inesperada não classificada. |

Serviços podem criar códigos funcionais mais específicos apenas quando houver necessidade clara de tratamento pelo cliente. Códigos específicos devem manter o HTTP compatível com esta tabela e ser documentados no OpenAPI do serviço.

---

## Rastreabilidade, Logs e Troubleshooting

### Correlation ID

O `correlationId` é o identificador primário de troubleshooting.

Ele deve ser:

- aceito de `X-Correlation-Id` quando enviado pelo cliente;
- gerado pelo serviço quando ausente;
- retornado no corpo e no header `X-Correlation-Id`;
- incluído em todos os logs emitidos durante a requisição;
- propagado em chamadas REST entre microsserviços;
- propagado em eventos relacionados, preferencialmente no payload ou metadata definida pelo produtor;
- preservado em processamentos assíncronos originados pela requisição.

### Trace ID e Span ID

Quando a stack de observabilidade estiver habilitada, `traceId` e `spanId` devem refletir os identificadores reais do trace distribuído.

Esses campos não substituem `correlationId`; eles complementam a investigação técnica em ferramentas de tracing.

### Log Reference

`logReference` deve ser uma referência segura e estável para busca do erro em logs, sem expor detalhes internos sensíveis.

Exemplos válidos:

```text
oficina-os-service/2026-06-23/7f4d0c4b6b8a4bb8a2f49bb8f06e1c3d
oficina-billing-service:pagamentos:7f4d0c4b6b8a4bb8a2f49bb8f06e1c3d
```

Não devem ser retornados:

- stack trace;
- SQL;
- payload completo da requisição;
- JWT ou claims sensíveis;
- secrets;
- dados de cartão ou credenciais de provedores externos.

### Logs Estruturados

Todo erro retornado ao cliente deve gerar log estruturado contendo, no mínimo:

| Campo de log | Descrição |
|---|---|
| `timestamp` | Data e hora do log. |
| `level` | `WARN` para erros esperados de cliente, `ERROR` para falhas internas ou dependências. |
| `service` | Nome canônico do serviço. |
| `correlationId` | Mesmo valor retornado na resposta. |
| `requestId` | Identificador da requisição local. |
| `traceId` | Trace distribuído, quando disponível. |
| `spanId` | Span atual, quando disponível. |
| `http.method` | Método HTTP. |
| `http.path` | Caminho chamado. |
| `http.status` | Código HTTP retornado. |
| `error.code` | Mesmo valor de `code` da resposta. |
| `error.message` | Mensagem técnica segura para logs. |

---

## Exemplos

### Erro de Validação

```json
{
  "timestamp": "2026-06-23T15:30:00Z",
  "status": 400,
  "error": "Bad Request",
  "code": "VALIDATION_ERROR",
  "message": "Requisicao invalida.",
  "path": "/api/v1/clientes",
  "correlationId": "7f4d0c4b6b8a4bb8a2f49bb8f06e1c3d",
  "requestId": "d290f1ee-6c54-4b01-90e6-d701748f0851",
  "service": "oficina-os-service",
  "details": [
    {
      "field": "documento",
      "code": "REQUIRED",
      "message": "Campo obrigatório."
    }
  ]
}
```

### Conflito de Estado

```json
{
  "timestamp": "2026-06-23T15:30:00Z",
  "status": 409,
  "error": "Conflict",
  "code": "INVALID_STATE_TRANSITION",
  "message": "A Ordem de Serviço não pode ser alterada a partir do estado atual.",
  "path": "/api/v1/ordens-servico/d290f1ee-6c54-4b01-90e6-d701748f0851/estado",
  "correlationId": "7f4d0c4b6b8a4bb8a2f49bb8f06e1c3d",
  "traceId": "4bf92f3577b34da6a3ce929d0e0e4736",
  "spanId": "00f067aa0ba902b7",
  "service": "oficina-os-service",
  "logReference": "oficina-os-service/2026-06-23/7f4d0c4b6b8a4bb8a2f49bb8f06e1c3d"
}
```

### Falha de Dependência

```json
{
  "timestamp": "2026-06-23T15:30:00Z",
  "status": 503,
  "error": "Service Unavailable",
  "code": "DEPENDENCY_UNAVAILABLE",
  "message": "Dependencia temporariamente indisponivel.",
  "path": "/api/v1/orcamentos",
  "correlationId": "7f4d0c4b6b8a4bb8a2f49bb8f06e1c3d",
  "requestId": "d290f1ee-6c54-4b01-90e6-d701748f0851",
  "traceId": "4bf92f3577b34da6a3ce929d0e0e4736",
  "service": "oficina-billing-service",
  "logReference": "oficina-billing-service/2026-06-23/7f4d0c4b6b8a4bb8a2f49bb8f06e1c3d"
}
```

---

## Relação com Idempotência

Erros relacionados a `X-Idempotency-Key` devem usar `409 Conflict`.

O código funcional padrão para payload divergente com a mesma chave é:

```text
IDEMPOTENCY_CONFLICT
```

Reprocessamento válido de uma operação idempotente não deve retornar erro apenas por repetição da chave. O comportamento detalhado deve ser definido em `contracts/idempotency.md`.

---

## Relação com Mensageria

Quando uma requisição HTTP gerar eventos de domínio, o `correlationId` da requisição deve ser propagado para a cadeia assíncrona.

Consumidores que moverem mensagens para DLQ devem registrar logs com:

- `correlationId`, quando disponível;
- `eventId`;
- `eventType`;
- `eventVersion`;
- `aggregateId`;
- tópico de origem;
- motivo da falha.

---

## Critérios de Pronto

Um serviço está compatível com este contrato quando:

- todas as respostas de erro usam o formato padrão;
- todos os erros retornam `X-Correlation-Id`;
- logs de erro incluem `correlationId`, `requestId`, `service`, `http.status` e `error.code`;
- erros esperados de cliente não expõem detalhes internos;
- falhas inesperadas retornam `INTERNAL_ERROR` com mensagem genérica;
- OpenAPI referencia o schema `ErrorResponse` compatível com este contrato.
