# Padrão Outbox por Serviço

## Objetivo

Definir o padrão de Outbox para publicação confiável de eventos nos microsserviços da plataforma.

Este documento complementa:

- [Contrato de Eventos de Domínio](../../contracts/Contrato%20de%20Eventos%20de%20Domínio.md);
- [Contrato de Tópicos de Mensageria](../../contracts/Contrato%20de%20Tópicos%20de%20Mensageria.md);
- [Contrato de Idempotência](../../contracts/idempotency.md);
- [Matriz de Ownership por Microsserviço](service-ownership.md);
- [Proposta de Migrations PostgreSQL Decompostas](../infrastructure/postgres-migrations-decomposition.md);
- [Padrão DynamoDB do oficina-execution-service](../infrastructure/dynamodb-execution-service.md).

O padrão é obrigatório para `oficina-os-service`, `oficina-billing-service` e `oficina-execution-service`.

## Decisão

Todo evento de domínio deve ser persistido primeiro na Outbox local do serviço produtor, na mesma transação que altera o agregado de negócio.

A publicação direta no broker durante a operação de negócio não é permitida.

## Escopo por Serviço

| Serviço | Persistência | Outbox local | Eventos produzidos |
|---|---|---|---|
| `oficina-os-service` | PostgreSQL database `oficina_os` | Tabela `outbox_event` | Eventos de OS e Saga |
| `oficina-billing-service` | PostgreSQL database `oficina_billing` | Tabela `outbox_event` | Eventos financeiros |
| `oficina-execution-service` | Amazon DynamoDB | Tabela `oficina-execution-lab-outbox` | Eventos operacionais e de estoque |

Cada serviço deve publicar apenas eventos em que aparece como produtor na tabela canônica do [Contrato de Eventos de Domínio](../../contracts/Contrato%20de%20Eventos%20de%20Domínio.md).

## Envelope Persistido

Cada registro de Outbox deve conter o envelope completo ou dados suficientes para reconstruí-lo sem consultar outro serviço.

Campos obrigatórios:

| Campo | Descrição |
|---|---|
| `eventId` | Identificador único e estável do evento. |
| `eventType` | Nome lógico camelCase do evento. |
| `eventVersion` | Versão do contrato do evento. |
| `occurredAt` | Data em que o fato de negócio ocorreu. |
| `producer` | Serviço produtor canônico. |
| `aggregateId` | Identificador do agregado principal. |
| `topic` | Tópico canônico de publicação. |
| `payload` | Payload validável pelo schema JSON do evento. |
| `correlationId` | Identificador transversal do fluxo. |

O `eventId` deve ser gerado uma única vez quando a Outbox é criada. Retentativas de publicação não podem gerar novo `eventId` para o mesmo evento lógico.

## Estados

Os estados canônicos da Outbox são:

| Estado | Uso |
|---|---|
| `PENDING` | Evento gravado e ainda não publicado com sucesso. |
| `PUBLISHED` | Evento publicado no tópico canônico e confirmado pelo publicador. |
| `FAILED` | Evento excedeu a política de retentativa ou falhou por erro não recuperável. |

Não deve existir estado `PROCESSING` persistido como contrato da plataforma. Concorrência deve ser controlada pelo mecanismo de lock, condição de escrita ou stream usado pelo publicador.

## Fluxo de Escrita

Operações que produzem evento devem seguir esta ordem:

1. validar comando, autorização e idempotência;
2. alterar o agregado de negócio;
3. criar o registro de Outbox com `status = PENDING`;
4. confirmar a transação local;
5. publicar assíncronamente pelo job, worker ou stream do próprio serviço.

Se a transação local falhar, nenhum evento deve ser publicado.

Se a publicação assíncrona falhar, o agregado de negócio permanece confirmado e o evento continua na Outbox para retentativa ou análise operacional.

## PostgreSQL

`oficina-os-service` e `oficina-billing-service` devem usar a tabela `outbox_event` no database próprio do serviço.

Estrutura mínima:

```sql
CREATE TABLE outbox_event (
  id uuid PRIMARY KEY,
  aggregate_id varchar(100) NOT NULL,
  event_type varchar(100) NOT NULL,
  event_version integer NOT NULL,
  topic varchar(200) NOT NULL,
  producer varchar(100) NOT NULL,
  payload jsonb NOT NULL,
  status varchar(30) NOT NULL DEFAULT 'PENDING',
  correlation_id varchar(100),
  occurred_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL,
  published_at timestamptz,
  attempts integer NOT NULL DEFAULT 0,
  next_attempt_at timestamptz,
  last_error text,
  CONSTRAINT ck_outbox_event_status CHECK (status IN ('PENDING', 'PUBLISHED', 'FAILED'))
);
```

Índices mínimos:

```sql
CREATE INDEX ix_outbox_event_status_next_attempt
  ON outbox_event (status, next_attempt_at, created_at);

CREATE INDEX ix_outbox_event_aggregate
  ON outbox_event (aggregate_id, occurred_at);
```

O publicador PostgreSQL deve selecionar eventos elegíveis com lock transacional, por exemplo `FOR UPDATE SKIP LOCKED`, publicar no tópico canônico e atualizar a linha para `PUBLISHED` na mesma unidade de trabalho do publicador.

## DynamoDB

`oficina-execution-service` deve usar a tabela `oficina-execution-lab-outbox` no ambiente canônico `lab`, conforme o [Padrão DynamoDB do oficina-execution-service](../infrastructure/dynamodb-execution-service.md).

Chaves canônicas:

| Atributo | Valor |
|---|---|
| `PK` | `OUTBOX#<eventId>` |
| `SK` | `EVENT` |

Índices mínimos:

| Índice | PK | SK | Uso |
|---|---|---|---|
| `GSI1` | `status` | `nextAttemptAt` | Buscar eventos pendentes. |
| `GSI2` | `aggregateId` | `createdAt` | Auditoria por agregado. |

O item de Outbox deve ser gravado na mesma transação DynamoDB que altera o agregado de negócio.

DynamoDB Streams pode acionar o publicador, mas a origem normativa da publicação continua sendo a tabela de Outbox. Se o stream falhar ou atrasar, um job de varredura por `GSI1` deve conseguir retomar a publicação.

## Retentativas

Falhas temporárias devem ser reagendadas com backoff exponencial e limite máximo de tentativas.

Política recomendada:

| Tentativa | Atraso mínimo |
|---:|---:|
| 1 | 30 segundos |
| 2 | 2 minutos |
| 3 | 5 minutos |
| 4 | 15 minutos |
| 5 | 1 hora |

Após exceder o limite configurado, o evento deve ser marcado como `FAILED` e gerar alerta operacional.

Eventos `FAILED` não devem ser descartados automaticamente. Reprocessamento manual deve preservar o mesmo `eventId`.

## DLQ

A DLQ pertence ao lado consumidor do tópico, conforme o [Contrato de Tópicos de Mensageria](../../contracts/Contrato%20de%20Tópicos%20de%20Mensageria.md).

A Outbox trata falha de publicação pelo produtor. A DLQ trata falha de processamento pelo consumidor.

Um evento publicado com sucesso e depois rejeitado por consumidor não deve voltar para a Outbox do produtor. O consumidor deve registrar a falha, mover a mensagem para a DLQ correspondente e preservar `eventId`, `eventType`, `aggregateId` e `correlationId`.

## Idempotência

A idempotência da publicação deve considerar:

- `eventId`;
- `eventType`;
- `eventVersion`;
- `producer`;
- `aggregateId`;
- transação local que originou o evento.

Consumidores devem registrar `eventId` processado conforme o [Contrato de Idempotência](../../contracts/idempotency.md).

Reprocessar o mesmo evento no mesmo consumidor deve ser sucesso idempotente ou retornar a resposta gravada anteriormente, sem duplicar efeito colateral.

## Observabilidade

Todo publicador de Outbox deve registrar logs estruturados com:

- `service`;
- `eventId`;
- `eventType`;
- `eventVersion`;
- `topic`;
- `producer`;
- `aggregateId`;
- `status`;
- `attempts`;
- `correlationId`;
- `traceId`, quando disponível.

Métricas mínimas:

| Métrica | Tipo | Dimensões |
|---|---|---|
| `outbox.pending.count` | Gauge | `service`, `eventType` |
| `outbox.published.count` | Counter | `service`, `eventType`, `topic` |
| `outbox.failed.count` | Counter | `service`, `eventType`, `topic` |
| `outbox.publish.latency` | Histogram | `service`, `eventType`, `topic` |
| `outbox.oldest.pending.age` | Gauge | `service` |

Alertas mínimos:

- evento `PENDING` acima do SLA operacional;
- crescimento contínuo de `outbox.pending.count`;
- qualquer evento marcado como `FAILED`;
- falha recorrente por tópico ou produtor.

## Retenção

Eventos `PENDING` e `FAILED` não devem expirar automaticamente.

Eventos `PUBLISHED` podem ser retidos por auditoria e troubleshooting.

Retenção mínima recomendada:

| Estado | Retenção |
|---|---:|
| `PENDING` | Indefinida até publicação ou falha final |
| `FAILED` | Indefinida até intervenção operacional |
| `PUBLISHED` | 7 dias em ambientes efêmeros; 30 dias em ambientes compartilhados |

No DynamoDB, TTL deve ser aplicado apenas a eventos `PUBLISHED`.

## Critérios de Implementação

Um microsserviço está aderente ao padrão quando:

- grava evento na Outbox na mesma transação do agregado;
- publica somente tópicos canônicos do seu domínio;
- preserva o mesmo `eventId` em retentativas;
- registra `correlationId` em Outbox, logs e publicação;
- possui retentativa com backoff e marcação de `FAILED`;
- expõe métricas mínimas do publicador;
- não publica evento diretamente no broker dentro da transação de negócio;
- trata consumidores de eventos de forma idempotente por `eventId`.
