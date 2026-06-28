# Padrao DynamoDB do oficina-execution-service

## Objetivo

Definir a baseline de tabelas, chaves, indices, seeds e streams DynamoDB do `oficina-execution-service`.

Este documento e normativo para implementacao do repositorio `oficina-execution-service` e complementa:

- `docs/service-ownership.md`;
- `contracts/openapi/oficina-execution-service.yaml`;
- `contracts/Contrato de Eventos de Domínio.md`;
- `contracts/Contrato de Tópicos de Mensageria.md`;
- `contracts/idempotency.md`.

O `oficina-execution-service` e o unico servico autorizado a acessar diretamente estas tabelas. Outros servicos devem integrar por REST ou eventos.

## Decisoes

- Usar Amazon DynamoDB como banco proprio do `oficina-execution-service`.
- Separar tabelas por agregado operacional para manter consultas simples e ownership explicito.
- Usar `uuid` como identificador canonico de `pecaId`, `servicoId`, `execucaoId` e `movimentoId`, alinhado ao OpenAPI.
- Usar atributos `createdAt` e `updatedAt` em formato ISO-8601 UTC.
- Publicar eventos somente via Outbox local.
- Habilitar DynamoDB Streams apenas nas tabelas em que o fluxo de publicacao, auditoria ou projecao depende de alteracoes de item.
- Nao criar eventos de catalogo no contrato fundamental da Fase 4; alteracoes de pecas e servicos ficam internas ao `oficina-execution-service`.

## Tabelas canonicas

| Tabela | Proposito | Stream | Retencao |
|---|---|---|---|
| `oficina-execution-catalog` | Catalogo tecnico de pecas e servicos | Desabilitado | Indefinida |
| `oficina-execution-stock` | Saldos e movimentos de estoque | Habilitado com `NEW_AND_OLD_IMAGES` | Indefinida |
| `oficina-execution-work` | Execucoes, diagnosticos, reparos e historico operacional | Habilitado com `NEW_AND_OLD_IMAGES` | Indefinida |
| `oficina-execution-outbox` | Eventos pendentes de publicacao | Habilitado com `NEW_AND_OLD_IMAGES` | TTL apos publicacao |
| `oficina-execution-idempotency` | Controle de idempotencia REST e consumo de eventos | Desabilitado | TTL obrigatorio |

Os nomes acima sao nomes logicos por ambiente. A infraestrutura pode prefixar ou sufixar ambiente conforme `docs/infra-runtime-naming.md`, desde que preserve o nome logico e o ownership.

## `oficina-execution-catalog`

Tabela do catalogo tecnico de pecas e servicos.

### Chaves

| Atributo | Tipo | Uso |
|---|---|---|
| `PK` | string | `PECA#<pecaId>` ou `SERVICO#<servicoId>` |
| `SK` | string | `METADATA` |

### Atributos principais

| Atributo | Obrigatorio | Descricao |
|---|---|---|
| `entityType` | Sim | `PECA` ou `SERVICO` |
| `pecaId` | Condicional | Presente quando `entityType = PECA` |
| `servicoId` | Condicional | Presente quando `entityType = SERVICO` |
| `nome` | Sim | Nome exibido nos contratos REST |
| `codigo` | Condicional | Codigo unico da peca |
| `descricao` | Nao | Descricao tecnica |
| `valorUnitario` | Condicional | Valor de peca |
| `valorBase` | Condicional | Valor base de servico |
| `ativo` | Sim | Indica se pode ser usado em novas OS |
| `createdAt` | Sim | Criacao do item |
| `updatedAt` | Sim | Ultima atualizacao |

### Indices

| Indice | PK | SK | Consulta suportada |
|---|---|---|---|
| `GSI1` | `entityType` | `nomeNormalizado` | Listar pecas ou servicos por tipo e nome |
| `GSI2` | `codigo` | `entityType` | Buscar peca por codigo |

`codigo` deve existir apenas para pecas. O `GSI2` e esparso.

### Regras

- `codigo` de peca deve ser unico.
- Itens inativos nao devem ser incluidos em novas Ordens de Servico.
- Atualizacoes de valor nao alteram snapshots ja persistidos pelo `oficina-os-service`.
- Alteracoes de catalogo nao publicam eventos no contrato fundamental da Fase 4.

## `oficina-execution-stock`

Tabela de saldo e movimentos de estoque.

### Chaves

| Item | PK | SK |
|---|---|---|
| Saldo atual | `PECA#<pecaId>` | `SALDO` |
| Movimento | `PECA#<pecaId>` | `MOVIMENTO#<createdAt>#<movimentoId>` |

### Atributos do saldo

| Atributo | Obrigatorio | Descricao |
|---|---|---|
| `entityType` | Sim | `ESTOQUE_SALDO` |
| `pecaId` | Sim | Identificador da peca |
| `quantidadeDisponivel` | Sim | Quantidade disponivel para reserva |
| `quantidadeReservada` | Sim | Quantidade reservada para OS |
| `updatedAt` | Sim | Ultima atualizacao |

### Atributos do movimento

| Atributo | Obrigatorio | Descricao |
|---|---|---|
| `entityType` | Sim | `ESTOQUE_MOVIMENTO` |
| `movimentoId` | Sim | Identificador do movimento |
| `pecaId` | Sim | Identificador da peca |
| `ordemServicoId` | Condicional | Obrigatorio para `RESERVA`, `CONSUMO` e `ESTORNO` quando o movimento estiver ligado a OS |
| `tipo` | Sim | `ENTRADA`, `RESERVA`, `CONSUMO` ou `ESTORNO` |
| `quantidade` | Sim | Inteiro positivo |
| `motivo` | Nao | Justificativa operacional |
| `createdAt` | Sim | Data do movimento |
| `correlationId` | Sim | Correlacao HTTP/evento |
| `sourceEventId` | Condicional | Evento consumido que originou o movimento |

### Indices

| Indice | PK | SK | Consulta suportada |
|---|---|---|---|
| `GSI1` | `ordemServicoId` | `createdAt` | Movimentos de estoque por OS |
| `GSI2` | `movimentoId` | `entityType` | Busca direta de movimento |

### Regras

- `ENTRADA` aumenta `quantidadeDisponivel`.
- `RESERVA` diminui `quantidadeDisponivel` e aumenta `quantidadeReservada`.
- `CONSUMO` diminui `quantidadeReservada`.
- `ESTORNO` reverte reserva ou consumo conforme contexto registrado no movimento original.
- Movimentos devem ser gravados em transacao junto com a atualizacao do saldo e o item da Outbox quando houver evento a publicar.
- Saldo nao pode ficar negativo.
- `estoqueAcrescentado` deve ser publicado para `ENTRADA`.
- `estoqueBaixado` deve ser publicado para `RESERVA` e `CONSUMO`, conforme schema atual.

## `oficina-execution-work`

Tabela de execucoes, diagnosticos, reparos e historico operacional.

### Chaves

| Item | PK | SK |
|---|---|---|
| Execucao | `EXECUCAO#<execucaoId>` | `METADATA` |
| Historico da execucao | `EXECUCAO#<execucaoId>` | `HISTORICO#<createdAt>#<historicoId>` |

### Atributos da execucao

| Atributo | Obrigatorio | Descricao |
|---|---|---|
| `entityType` | Sim | `EXECUCAO` |
| `execucaoId` | Sim | Identificador da execucao |
| `ordemServicoId` | Sim | Identificador da OS |
| `status` | Sim | `CRIADA`, `EM_DIAGNOSTICO`, `DIAGNOSTICO_CONCLUIDO`, `EM_REPARO`, `REPARO_CONCLUIDO` ou `CANCELADA` |
| `diagnostico` | Nao | Resultado tecnico |
| `observacoesReparo` | Nao | Observacoes do reparo |
| `createdAt` | Sim | Criacao |
| `updatedAt` | Sim | Ultima atualizacao |
| `correlationId` | Sim | Correlacao HTTP/evento |

### Atributos do historico

| Atributo | Obrigatorio | Descricao |
|---|---|---|
| `entityType` | Sim | `EXECUCAO_HISTORICO` |
| `historicoId` | Sim | Identificador do registro |
| `execucaoId` | Sim | Execucao relacionada |
| `ordemServicoId` | Sim | OS relacionada |
| `statusAnterior` | Nao | Estado anterior |
| `statusNovo` | Sim | Estado novo |
| `descricao` | Nao | Descricao operacional |
| `createdAt` | Sim | Data do historico |
| `sourceEventId` | Condicional | Evento consumido que originou a transicao |

### Indices

| Indice | PK | SK | Consulta suportada |
|---|---|---|---|
| `GSI1` | `ordemServicoId` | `entityType` | Buscar execucao de uma OS |
| `GSI2` | `status` | `updatedAt` | Listar execucoes por status |

### Regras

- Deve existir no maximo uma execucao ativa por `ordemServicoId`.
- A transicao de status deve ser condicional sobre o status atual esperado.
- `diagnosticoIniciado` deve ser publicado ao entrar em `EM_DIAGNOSTICO`.
- `diagnosticoFinalizado` deve ser publicado ao entrar em `DIAGNOSTICO_CONCLUIDO`.
- `execucaoIniciada` deve ser publicado ao entrar em `EM_REPARO`.
- `execucaoFinalizada` deve ser publicado ao entrar em `REPARO_CONCLUIDO`.
- Cancelamentos nao possuem evento fundamental proprio na Fase 4; efeitos distribuidos devem ocorrer por `sagaCompensada` quando orquestrados pelo `oficina-os-service`.

## `oficina-execution-outbox`

Tabela de Outbox local para publicacao confiavel de eventos.

### Chaves

| Atributo | Tipo | Uso |
|---|---|---|
| `PK` | string | `OUTBOX#<eventId>` |
| `SK` | string | `EVENT` |

### Atributos

| Atributo | Obrigatorio | Descricao |
|---|---|---|
| `eventId` | Sim | Mesmo valor do envelope do evento |
| `eventType` | Sim | Nome logico do evento |
| `eventVersion` | Sim | Versao do contrato |
| `topic` | Sim | Topico canonico |
| `producer` | Sim | `oficina-execution-service` |
| `aggregateId` | Sim | Agregado principal do evento |
| `payload` | Sim | Payload conforme schema JSON |
| `status` | Sim | `PENDING`, `PUBLISHED` ou `FAILED` |
| `attempts` | Sim | Numero de tentativas |
| `nextAttemptAt` | Nao | Proxima tentativa |
| `publishedAt` | Nao | Data de publicacao |
| `expiresAt` | Condicional | TTL para eventos publicados |
| `correlationId` | Sim | Correlacao do fluxo |
| `createdAt` | Sim | Criacao |
| `updatedAt` | Sim | Ultima atualizacao |

### Indices

| Indice | PK | SK | Consulta suportada |
|---|---|---|---|
| `GSI1` | `status` | `nextAttemptAt` | Buscar eventos pendentes de publicacao |
| `GSI2` | `aggregateId` | `createdAt` | Auditoria por agregado |

### Regras

- Eventos devem ser criados na mesma transacao DynamoDB que altera o agregado de negocio.
- O publicador deve buscar `PENDING` por `GSI1`, publicar no topico canonico e atualizar para `PUBLISHED`.
- Falhas temporarias devem incrementar `attempts` e reagendar `nextAttemptAt`.
- Falhas definitivas devem marcar `FAILED` e exigir analise operacional.
- TTL deve ser aplicado apenas depois de `PUBLISHED`, nunca enquanto o evento estiver `PENDING` ou `FAILED`.

## `oficina-execution-idempotency`

Tabela de idempotencia para comandos REST e consumo de eventos.

### Chaves

| Atributo | Tipo | Uso |
|---|---|---|
| `PK` | string | `IDEMPOTENCY#<scope>#<key>` |
| `SK` | string | `REQUEST` ou `EVENT` |

### Atributos

| Atributo | Obrigatorio | Descricao |
|---|---|---|
| `scope` | Sim | Operacao REST ou consumidor de evento |
| `key` | Sim | `X-Idempotency-Key` ou `eventId` |
| `requestHash` | Condicional | Hash do corpo REST |
| `responseStatus` | Condicional | Status HTTP retornado |
| `responseBody` | Condicional | Corpo retornado quando reutilizavel |
| `processingStatus` | Sim | `PROCESSING`, `COMPLETED` ou `FAILED` |
| `createdAt` | Sim | Criacao |
| `updatedAt` | Sim | Ultima atualizacao |
| `expiresAt` | Sim | TTL |

### Regras

- Comandos REST com efeito colateral devem seguir `contracts/idempotency.md`.
- Consumo de eventos deve registrar `eventId` antes de aplicar mudancas.
- Reprocessamento do mesmo `eventId` deve ser tratado como sucesso idempotente.
- Reuso da mesma chave REST com corpo diferente deve retornar conflito.

## Streams

| Tabela | Stream | Consumidor previsto |
|---|---|---|
| `oficina-execution-stock` | `NEW_AND_OLD_IMAGES` | Auditoria operacional ou projecoes internas futuras |
| `oficina-execution-work` | `NEW_AND_OLD_IMAGES` | Auditoria operacional ou projecoes internas futuras |
| `oficina-execution-outbox` | `NEW_AND_OLD_IMAGES` | Publicador de eventos do proprio servico |

Streams nao substituem a Outbox. A Outbox continua sendo a origem de publicacao dos eventos externos para os topicos canonicos.

## Seeds iniciais

A massa inicial da Fase 4 deve ser limpa e criada no repositorio `oficina-execution-service`, reaproveitando apenas dados funcionais do `import.sql` historico do `oficina-app` quando fizer sentido.

Seeds minimos:

| Tipo | Campos obrigatorios |
|---|---|
| Peca | `pecaId`, `nome`, `codigo`, `valorUnitario`, `ativo` |
| Servico | `servicoId`, `nome`, `descricao`, `valorBase`, `ativo` |
| Saldo inicial | `pecaId`, `quantidadeDisponivel`, `quantidadeReservada = 0` |

Regras:

- Seeds devem ser idempotentes.
- Seeds nao devem gerar eventos de dominio.
- Seeds nao devem criar execucoes ou historico operacional.
- Saldos iniciais devem ser tratados como baseline de ambiente, nao como movimento `ENTRADA`.

## Eventos produzidos

| Operacao | Evento | Topico |
|---|---|---|
| Inicio de diagnostico | `diagnosticoIniciado` | `oficina.execution.diagnostico-iniciado` |
| Conclusao de diagnostico | `diagnosticoFinalizado` | `oficina.execution.diagnostico-finalizado` |
| Inicio de reparo | `execucaoIniciada` | `oficina.execution.execucao-iniciada` |
| Conclusao de reparo | `execucaoFinalizada` | `oficina.execution.execucao-finalizada` |
| Entrada de estoque | `estoqueAcrescentado` | `oficina.execution.estoque-acrescentado` |
| Reserva ou consumo de estoque | `estoqueBaixado` | `oficina.execution.estoque-baixado` |

Os payloads devem seguir os schemas JSON em `contracts/events/schemas/`.

## Eventos consumidos

| Evento | Uso no DynamoDB |
|---|---|
| `ordemDeServicoCriada` | Criar ou validar contexto operacional local quando necessario |
| `pecaIncluidaNaOrdemDeServico` | Validar peca ativa e preparar reserva quando o fluxo da Saga exigir |
| `servicoIncluidoNaOrdemDeServico` | Validar servico ativo para execucao futura |
| `orcamentoAprovado` | Liberar execucao operacional da OS |
| `ordemDeServicoFinalizada` | Encerrar pendencias operacionais da OS |
| `sagaCompensada` | Estornar reservas ou cancelar execucao conforme estado local |
| `sagaFinalizadaComSucesso` | Marcar fluxo operacional como concluido para auditoria |

Consumidores devem ser idempotentes e nao podem alterar dados de outros microsservicos.

## Referencias

- `contracts/openapi/oficina-execution-service.yaml`
- `contracts/events/schemas/diagnosticoIniciado.schema.json`
- `contracts/events/schemas/diagnosticoFinalizado.schema.json`
- `contracts/events/schemas/execucaoIniciada.schema.json`
- `contracts/events/schemas/execucaoFinalizada.schema.json`
- `contracts/events/schemas/estoqueAcrescentado.schema.json`
- `contracts/events/schemas/estoqueBaixado.schema.json`
