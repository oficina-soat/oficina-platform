# Contrato de Idempotência

## Objetivo

Definir o comportamento padronizado de idempotência para APIs REST, consumidores de eventos e operações de Saga da plataforma da oficina mecânica.

Este contrato complementa o [Contrato de Erros REST](error-model.md) e deve ser usado por `oficina-os-service`, `oficina-billing-service` e `oficina-execution-service` para tornar retries, duplicidades, timeouts e reprocessamentos previsíveis.

---

## Escopo

Este contrato se aplica a:

- operações REST com efeito colateral;
- comandos executados pela Saga;
- consumidores de eventos de domínio;
- publicação via Outbox;
- reprocessamento de mensagens após falhas temporárias.

Operações de leitura (`GET`) não exigem chave de idempotência.

Operações naturalmente idempotentes por identificador e substituição completa (`PUT`) devem manter o resultado final estável, mas não precisam usar `X-Idempotency-Key`.

---

## Princípios

- Repetir a mesma requisição com a mesma chave não deve duplicar efeitos colaterais.
- Repetir a mesma chave com payload diferente deve retornar erro.
- Falhas de rede, timeouts e retries automáticos não devem criar entidades, movimentos financeiros, movimentos de estoque ou eventos duplicados.
- Consumidores de eventos devem tolerar mensagens duplicadas e reprocessamento.
- A chave de idempotência não substitui validações de negócio, autorização ou controle de estado.
- Todo registro de idempotência deve ser rastreável por `correlationId`.

---

## Header HTTP

Operações REST com efeito colateral devem aceitar:

```text
X-Idempotency-Key: <chave>
```

### Formato

| Regra | Valor |
|---|---|
| Tamanho mínimo | 8 caracteres |
| Tamanho máximo | 128 caracteres |
| Caracteres recomendados | Letras, números, `-`, `_`, `.` |
| Valor recomendado | UUID v4 ou identificador determinístico gerado pelo cliente |

Exemplo:

```text
X-Idempotency-Key: 7c8f5c52-03f3-4f7a-91a3-f3d675c51c4c
```

### Obrigatoriedade

Na API v1, `X-Idempotency-Key` é obrigatório em operações mutáveis com efeito colateral, especialmente `POST` e `PATCH`.

Clientes, front-ends, Sagas e integrações entre microsserviços devem enviar a chave em todas as operações `POST` ou `PATCH` com efeito colateral.

Serviços devem rejeitar operações mutáveis sem chave. Nesse caso, devem responder `400 Bad Request` com `code` igual a `IDEMPOTENCY_KEY_REQUIRED`.

---

## Escopo da Chave

A unicidade da chave deve considerar, no mínimo:

- serviço;
- método HTTP;
- path canônico;
- consumidor autenticado quando aplicável;
- valor de `X-Idempotency-Key`.

Exemplo de escopo lógico:

```text
oficina-billing-service:POST:/api/v1/pagamentos:<cliente-ou-sujeito>:7c8f5c52-03f3-4f7a-91a3-f3d675c51c4c
```

A mesma chave pode ser reutilizada em outro endpoint sem conflito, pois o path faz parte do escopo.

---

## Assinatura da Requisição

Para detectar reuso incorreto da chave, o serviço deve persistir uma assinatura da requisição.

A assinatura deve considerar:

- método HTTP;
- path canônico;
- query params relevantes para a operação;
- payload JSON normalizado;
- sujeito autenticado quando relevante para autorização;
- versão da API.

Headers transversais como `Authorization`, `X-Correlation-Id` e `traceparent` não devem compor o hash de payload.

O hash recomendado é SHA-256 do conteúdo canônico.

---

## Estados do Registro

| Estado | Descrição |
|---|---|
| `PROCESSING` | A primeira requisição foi aceita e ainda não possui resultado final. |
| `COMPLETED` | A operação terminou com resposta final reutilizável. |
| `FAILED_RETRYABLE` | A tentativa falhou antes de confirmar efeito colateral e pode ser executada novamente. |
| `FAILED_FINAL` | A tentativa terminou em erro determinístico que pode ser retornado novamente. |

O registro deve armazenar:

- chave;
- escopo;
- hash da requisição;
- estado;
- status HTTP final quando houver;
- corpo de resposta final quando houver;
- `correlationId` original;
- `requestId` original quando houver;
- data de criação;
- data de atualização;
- data de expiração.

---

## Comportamento REST

### Primeira Requisição

Quando a chave ainda não existir no escopo:

1. validar autenticação e autorização;
2. validar formato básico da requisição;
3. criar registro `PROCESSING`;
4. executar a operação;
5. gravar resposta final;
6. marcar registro como `COMPLETED` ou `FAILED_FINAL`.

Validações rejeitadas antes da criação do registro podem retornar erro sem persistir idempotência.

### Repetição com Mesmo Payload

Quando a chave existir e o hash for igual:

| Estado atual | Resposta esperada |
|---|---|
| `PROCESSING` | `409 Conflict` com `code` `IDEMPOTENCY_IN_PROGRESS` e header `Retry-After` quando aplicável. |
| `COMPLETED` | Repetir o mesmo status HTTP e corpo gravados na primeira resposta final. |
| `FAILED_RETRYABLE` | Permitir nova tentativa da operação. |
| `FAILED_FINAL` | Repetir o mesmo status HTTP e corpo gravados na falha final. |

### Repetição com Payload Diferente

Quando a chave existir e o hash for diferente, o serviço deve responder:

```text
409 Conflict
```

Com `code`:

```text
IDEMPOTENCY_CONFLICT
```

O corpo deve seguir o [Contrato de Erros REST](error-model.md).

### Ausência de Chave

Quando a chave estiver ausente em operação que aceita idempotência:

- o serviço pode processar a requisição normalmente;
- o serviço ainda deve proteger duplicidade por restrições de negócio e banco;
- clientes não devem assumir replay seguro em caso de timeout.

Quando a operação exigir chave e ela estiver ausente:

```text
400 Bad Request
```

Com `code`:

```text
IDEMPOTENCY_KEY_REQUIRED
```

---

## Retenção

Registros de idempotência devem ser mantidos por tempo suficiente para cobrir retries de clientes, filas, Sagas e timeouts operacionais.

Valores recomendados:

| Tipo de operação | Retenção mínima |
|---|---:|
| Criação simples de cadastro | 24 horas |
| Movimentação de estoque | 72 horas |
| Pagamento ou integração financeira | 7 dias |
| Comando de Saga | 7 dias |

A remoção de registros expirados não pode remover dados de negócio nem eventos já publicados.

---

## Eventos e Consumidores

Consumidores devem ser idempotentes por:

```text
eventId
```

Quando a regra de negócio exigir proteção adicional, também devem considerar:

- `eventType`;
- `eventVersion`;
- `aggregateId`;
- etapa da Saga;
- identificador de comando externo, quando existir.

Cada consumidor deve registrar eventos processados com:

- `eventId`;
- `eventType`;
- `eventVersion`;
- `aggregateId`;
- consumidor;
- resultado;
- `correlationId`, quando disponível;
- data de processamento.

Reprocessar o mesmo `eventId` no mesmo consumidor não deve duplicar efeitos colaterais.

---

## Outbox

Produtores devem usar Outbox para publicar eventos após a transação local.

A idempotência da publicação deve considerar:

- identificador da entidade;
- tipo do evento;
- versão do evento;
- transação local que originou o evento.

Retries do publicador Outbox não devem criar novo `eventId` para o mesmo evento lógico já persistido.

O padrão operacional de tabelas, estados, retentativas, DLQ e observabilidade da Outbox está definido no [Padrão Outbox por Serviço](../docs/outbox-pattern.md).

---

## Saga

Comandos disparados pela Saga devem possuir chave determinística.

Formato recomendado:

```text
saga:<sagaId>:<etapa>:<aggregateId>
```

Exemplo:

```text
saga:1f0a0ef4-5f1a-4c3d-9d58-0382f23a83ae:solicitar-pagamento:d290f1ee-6c54-4b01-90e6-d701748f0851
```

Compensações também devem ser idempotentes e usar etapa própria:

```text
saga:<sagaId>:compensar-estoque:<aggregateId>
```

---

## Relação com Erros

Erros de idempotência devem seguir o [Contrato de Erros REST](error-model.md).

| Situação | HTTP | `code` |
|---|---:|---|
| Chave obrigatória ausente | 400 | `IDEMPOTENCY_KEY_REQUIRED` |
| Chave em processamento | 409 | `IDEMPOTENCY_IN_PROGRESS` |
| Mesma chave com payload diferente | 409 | `IDEMPOTENCY_CONFLICT` |

Exemplo:

```json
{
  "timestamp": "2026-06-23T15:30:00Z",
  "status": 409,
  "error": "Conflict",
  "code": "IDEMPOTENCY_CONFLICT",
  "message": "A chave de idempotência já foi usada com payload diferente.",
  "path": "/api/v1/pagamentos",
  "correlationId": "7f4d0c4b6b8a4bb8a2f49bb8f06e1c3d",
  "service": "oficina-billing-service"
}
```

---

## Critérios de Pronto

Um serviço está compatível com este contrato quando:

- aceita `X-Idempotency-Key` nas operações REST com efeito colateral previstas no OpenAPI;
- rejeita reuso da mesma chave com payload diferente;
- retorna a mesma resposta final para repetição equivalente;
- registra idempotência com `correlationId`;
- consumidores ignoram duplicidade por `eventId`;
- publicação Outbox não duplica eventos em retry;
- comandos e compensações da Saga usam chave determinística.
