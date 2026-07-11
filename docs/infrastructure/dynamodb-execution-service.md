# Padrão DynamoDB do oficina-execution-service

## Objetivo

Definir a baseline de tabelas, chaves, índices, seeds e streams DynamoDB do `oficina-execution-service`.

Este documento é normativo para implementação do repositório `oficina-execution-service` e complementa:

- [Matriz de Ownership por Microsserviço](../architecture/service-ownership.md);
- [OpenAPI do oficina-execution-service](../../contracts/openapi/oficina-execution-service.yaml);
- [Contrato de Eventos de Domínio](../../contracts/Contrato%20de%20Eventos%20de%20Domínio.md);
- [Contrato de Tópicos de Mensageria](../../contracts/Contrato%20de%20Tópicos%20de%20Mensageria.md);
- [Contrato de Idempotência](../../contracts/idempotency.md);
- [Padrão Outbox por Serviço](../architecture/outbox-pattern.md).

O `oficina-execution-service` é o único serviço autorizado a acessar diretamente estas tabelas. Outros serviços devem integrar por REST ou eventos.

## Decisões

- Usar Amazon DynamoDB como banco próprio do `oficina-execution-service`.
- Separar tabelas por agregado operacional para manter consultas simples e ownership explícito.
- Usar `uuid` como identificador canônico de `pecaId`, `servicoId`, `execucaoId` e `movimentoId`, alinhado ao OpenAPI.
- Usar atributos `createdAt` e `updatedAt` em formato ISO-8601 UTC.
- Publicar eventos somente via Outbox local.
- Habilitar DynamoDB Streams apenas nas tabelas em que o fluxo de publicação, auditoria ou projeção depende de alterações de item.
- Não criar eventos de catálogo no contrato fundamental da Fase 4; alterações de peças e serviços ficam internas ao `oficina-execution-service`.

## Tabelas canônicas

Para a Fase 4, o ambiente canônico é `lab` e o prefixo materializado é `oficina-execution-lab`, conforme [Nomes de runtime, secrets e infraestrutura](infra-runtime-naming.md). O nome lógico de cada tabela deve ser preservado pelo sufixo após esse prefixo.

| Tabela | Propósito | Stream | Retenção |
|---|---|---|---|
| `oficina-execution-lab-catalogo` | Catálogo técnico de peças e serviços | Desabilitado | Indefinida |
| `oficina-execution-lab-estoque` | Saldos e movimentos de estoque | Habilitado com `NEW_AND_OLD_IMAGES` | Indefinida |
| `oficina-execution-lab-execucoes` | Execuções, diagnósticos, reparos e histórico operacional | Habilitado com `NEW_AND_OLD_IMAGES` | Indefinida |
| `oficina-execution-lab-outbox` | Eventos pendentes de publicação | Habilitado com `NEW_AND_OLD_IMAGES` | TTL após publicação |
| `oficina-execution-lab-idempotencia` | Controle de idempotência REST e consumo de eventos | Desabilitado | TTL obrigatório |

Os nomes acima são os nomes materializados canônicos do ambiente `lab`. Em ambientes futuros, a infraestrutura pode trocar apenas o componente de ambiente do prefixo, preservando ownership, sufixo lógico e variáveis runtime equivalentes.

## `oficina-execution-lab-catalogo`

Tabela do catálogo técnico de peças e serviços.

### Chaves

| Atributo | Tipo | Uso |
|---|---|---|
| `PK` | string | `PECA#<pecaId>` ou `SERVICO#<servicoId>` |
| `SK` | string | `METADATA` |

### Atributos principais

| Atributo | Obrigatório | Descrição |
|---|---|---|
| `entityType` | Sim | `PECA` ou `SERVICO` |
| `pecaId` | Condicional | Presente quando `entityType = PECA` |
| `servicoId` | Condicional | Presente quando `entityType = SERVICO` |
| `nome` | Sim | Nome exibido nos contratos REST |
| `codigo` | Condicional | Código único da peça |
| `descricao` | Não | Descrição técnica |
| `valorUnitario` | Condicional | Valor de peça |
| `valorBase` | Condicional | Valor base de serviço |
| `ativo` | Sim | Indica se pode ser usado em novas OS |
| `createdAt` | Sim | Criação do item |
| `updatedAt` | Sim | Última atualização |

### Índices

| Índice | PK | SK | Consulta suportada |
|---|---|---|---|
| `GSI1` | `entityType` | `nomeNormalizado` | Listar peças ou serviços por tipo e nome |
| `GSI2` | `codigo` | `entityType` | Buscar peça por código |

`codigo` deve existir apenas para peças. O `GSI2` é esparso.

### Regras

- `codigo` de peça deve ser único.
- Itens inativos não devem ser incluídos em novas Ordens de Serviço.
- Atualizações de valor não alteram snapshots já persistidos pelo `oficina-os-service`.
- Alterações de catálogo não publicam eventos no contrato fundamental da Fase 4.

## `oficina-execution-lab-estoque`

Tabela de saldo e movimentos de estoque.

### Chaves

| Item | PK | SK |
|---|---|---|
| Saldo atual | `PECA#<pecaId>` | `SALDO` |
| Movimento | `PECA#<pecaId>` | `MOVIMENTO#<createdAt>#<movimentoId>` |

### Atributos do saldo

| Atributo | Obrigatório | Descrição |
|---|---|---|
| `entityType` | Sim | `ESTOQUE_SALDO` |
| `pecaId` | Sim | Identificador da peça |
| `quantidadeDisponivel` | Sim | Quantidade disponível para reserva |
| `quantidadeReservada` | Sim | Quantidade reservada para OS |
| `updatedAt` | Sim | Última atualização |

### Atributos do movimento

| Atributo | Obrigatório | Descrição |
|---|---|---|
| `entityType` | Sim | `ESTOQUE_MOVIMENTO` |
| `movimentoId` | Sim | Identificador do movimento |
| `pecaId` | Sim | Identificador da peça |
| `ordemServicoId` | Condicional | Obrigatório para `RESERVA`, `CONSUMO` e `ESTORNO` quando o movimento estiver ligado a OS |
| `tipo` | Sim | `ENTRADA`, `RESERVA`, `CONSUMO` ou `ESTORNO` |
| `quantidade` | Sim | Inteiro positivo |
| `motivo` | Não | Justificativa operacional |
| `createdAt` | Sim | Data do movimento |
| `correlationId` | Sim | Correlação HTTP/evento |
| `sourceEventId` | Condicional | Evento consumido que originou o movimento |

### Índices

| Índice | PK | SK | Consulta suportada |
|---|---|---|---|
| `GSI1` | `ordemServicoId` | `createdAt` | Movimentos de estoque por OS |
| `GSI2` | `movimentoId` | `entityType` | Busca direta de movimento |

### Regras

- `ENTRADA` aumenta `quantidadeDisponivel`.
- `RESERVA` diminui `quantidadeDisponivel` e aumenta `quantidadeReservada`.
- `CONSUMO` diminui `quantidadeReservada`.
- `ESTORNO` reverte reserva ou consumo conforme contexto registrado no movimento original.
- Movimentos devem ser gravados em transação junto com a atualização do saldo e o item da Outbox quando houver evento a publicar.
- Saldo não pode ficar negativo.
- `estoqueAcrescentado` deve ser publicado para `ENTRADA`.
- `estoqueBaixado` deve ser publicado para `RESERVA` e `CONSUMO`, conforme schema atual.

## `oficina-execution-lab-execucoes`

Tabela de execuções, diagnósticos, reparos e histórico operacional.

### Chaves

| Item | PK | SK |
|---|---|---|
| Execução | `EXECUCAO#<execucaoId>` | `METADATA` |
| Histórico da execução | `EXECUCAO#<execucaoId>` | `HISTORICO#<createdAt>#<historicoId>` |

### Atributos da execução

| Atributo | Obrigatório | Descrição |
|---|---|---|
| `entityType` | Sim | `EXECUCAO` |
| `execucaoId` | Sim | Identificador da execução |
| `ordemServicoId` | Sim | Identificador da OS |
| `status` | Sim | `CRIADA`, `EM_DIAGNOSTICO`, `DIAGNOSTICO_CONCLUIDO`, `EM_REPARO`, `REPARO_CONCLUIDO` ou `CANCELADA` |
| `prioridade` | Sim | Prioridade operacional da fila. Valores menores indicam maior urgência. Valor padrão: `100`. |
| `diagnostico` | Não | Resultado técnico |
| `observacoesReparo` | Não | Observações do reparo |
| `createdAt` | Sim | Criação |
| `updatedAt` | Sim | Última atualização |
| `correlationId` | Sim | Correlação HTTP/evento |
| `filaStatus` | Condicional | Presente apenas para execuções aguardando ação operacional na fila. Valores esperados: `CRIADA` ou `DIAGNOSTICO_CONCLUIDO`. |
| `prioridadeCriadoEm` | Condicional | Chave de ordenação da fila no formato `<prioridade>#<createdAt>#<execucaoId>`. |

### Atributos do histórico

| Atributo | Obrigatório | Descrição |
|---|---|---|
| `entityType` | Sim | `EXECUCAO_HISTORICO` |
| `historicoId` | Sim | Identificador do registro |
| `execucaoId` | Sim | Execução relacionada |
| `ordemServicoId` | Sim | OS relacionada |
| `statusAnterior` | Não | Estado anterior |
| `statusNovo` | Sim | Estado novo |
| `descricao` | Não | Descrição operacional |
| `createdAt` | Sim | Data do histórico |
| `sourceEventId` | Condicional | Evento consumido que originou a transição |

### Índices

| Índice | PK | SK | Consulta suportada |
|---|---|---|---|
| `GSI1` | `ordemServicoId` | `entityType` | Buscar execução de uma OS |
| `GSI2` | `status` | `updatedAt` | Listar execuções por status |
| `GSI3` | `filaStatus` | `prioridadeCriadoEm` | Consultar fila de execução por etapa operacional |

### Regras

- Deve existir no máximo uma execução ativa por `ordemServicoId`.
- A consulta de fila deve considerar, por padrão, execuções em `CRIADA` e `DIAGNOSTICO_CONCLUIDO`, ordenando por `prioridade` crescente e `createdAt` crescente.
- Execuções em `EM_DIAGNOSTICO`, `EM_REPARO`, `REPARO_CONCLUIDO` e `CANCELADA` não devem possuir `filaStatus`.
- A transição de status deve ser condicional sobre o status atual esperado.
- `diagnosticoIniciado` deve ser publicado ao entrar em `EM_DIAGNOSTICO`.
- `diagnosticoFinalizado` deve ser publicado ao entrar em `DIAGNOSTICO_CONCLUIDO`.
- `execucaoIniciada` deve ser publicado ao entrar em `EM_REPARO`.
- `execucaoFinalizada` deve ser publicado ao entrar em `REPARO_CONCLUIDO`.
- Cancelamentos não possuem evento fundamental próprio na Fase 4; efeitos distribuídos devem ocorrer por `sagaCompensada` quando orquestrados pelo `oficina-os-service`.

## `oficina-execution-lab-outbox`

Tabela de Outbox local para publicação confiável de eventos.

### Chaves

| Atributo | Tipo | Uso |
|---|---|---|
| `PK` | string | `OUTBOX#<eventId>` |
| `SK` | string | `EVENT` |

### Atributos

| Atributo | Obrigatório | Descrição |
|---|---|---|
| `eventId` | Sim | Mesmo valor do envelope do evento |
| `eventType` | Sim | Nome lógico do evento |
| `eventVersion` | Sim | Versão do contrato |
| `topic` | Sim | Tópico canônico |
| `producer` | Sim | `oficina-execution-service` |
| `aggregateId` | Sim | Agregado principal do evento |
| `payload` | Sim | Payload conforme schema JSON |
| `status` | Sim | `PENDING`, `PUBLISHED` ou `FAILED` |
| `attempts` | Sim | Número de tentativas |
| `nextAttemptAt` | Não | Próxima tentativa |
| `publishedAt` | Não | Data de publicação |
| `expiresAt` | Condicional | TTL para eventos publicados |
| `correlationId` | Sim | Correlação do fluxo |
| `createdAt` | Sim | Criação |
| `updatedAt` | Sim | Última atualização |

### Índices

| Índice | PK | SK | Consulta suportada |
|---|---|---|---|
| `GSI1` | `status` | `nextAttemptAt` | Buscar eventos pendentes de publicação |
| `GSI2` | `aggregateId` | `createdAt` | Auditoria por agregado |

### Regras

- Eventos devem ser criados na mesma transação DynamoDB que altera o agregado de negócio.
- O publicador deve buscar `PENDING` por `GSI1`, publicar no tópico canônico e atualizar para `PUBLISHED`.
- Falhas temporárias devem incrementar `attempts` e reagendar `nextAttemptAt`.
- Falhas definitivas devem marcar `FAILED` e exigir análise operacional.
- TTL deve ser aplicado apenas depois de `PUBLISHED`, nunca enquanto o evento estiver `PENDING` ou `FAILED`.

## `oficina-execution-lab-idempotencia`

Tabela de idempotência para comandos REST e consumo de eventos.

### Chaves

| Atributo | Tipo | Uso |
|---|---|---|
| `PK` | string | `IDEMPOTENCY#<scope>#<key>` |
| `SK` | string | `REQUEST` ou `EVENT` |

### Atributos

| Atributo | Obrigatório | Descrição |
|---|---|---|
| `scope` | Sim | Operação REST ou consumidor de evento |
| `key` | Sim | `X-Idempotency-Key` ou `eventId` |
| `requestHash` | Condicional | Hash do corpo REST |
| `responseStatus` | Condicional | Status HTTP retornado |
| `responseBody` | Condicional | Corpo retornado quando reutilizável |
| `processingStatus` | Sim | `PROCESSING`, `COMPLETED` ou `FAILED` |
| `createdAt` | Sim | Criação |
| `updatedAt` | Sim | Última atualização |
| `expiresAt` | Sim | TTL |

### Regras

- Comandos REST com efeito colateral devem seguir o [Contrato de Idempotência](../../contracts/idempotency.md).
- Consumo de eventos deve registrar `eventId` antes de aplicar mudanças.
- Reprocessamento do mesmo `eventId` deve ser tratado como sucesso idempotente.
- Reuso da mesma chave REST com corpo diferente deve retornar conflito.

## Streams

| Tabela | Stream | Consumidor previsto |
|---|---|---|
| `oficina-execution-lab-estoque` | `NEW_AND_OLD_IMAGES` | Auditoria operacional ou projeções internas futuras |
| `oficina-execution-lab-execucoes` | `NEW_AND_OLD_IMAGES` | Auditoria operacional ou projeções internas futuras |
| `oficina-execution-lab-outbox` | `NEW_AND_OLD_IMAGES` | Publicador de eventos do próprio serviço |

Streams não substituem a Outbox. A Outbox continua sendo a origem de publicação dos eventos externos para os tópicos canônicos.

## Seeds iniciais

A massa inicial da Fase 4 deve ser limpa e criada no repositório `oficina-execution-service`, reaproveitando apenas dados funcionais do `import.sql` histórico do `oficina-app` quando fizer sentido.

Seeds mínimos:

| Tipo | Campos obrigatórios |
|---|---|
| Peça | `pecaId`, `nome`, `codigo`, `valorUnitario`, `ativo` |
| Serviço | `servicoId`, `nome`, `descricao`, `valorBase`, `ativo` |
| Saldo inicial | `pecaId`, `quantidadeDisponivel`, `quantidadeReservada = 0` |

Regras:

- Seeds devem ser idempotentes.
- Seeds não devem gerar eventos de domínio.
- Seeds não devem criar execuções ou histórico operacional.
- Saldos iniciais devem ser tratados como baseline de ambiente, não como movimento `ENTRADA`.

## Eventos produzidos

| Operação | Evento | Tópico |
|---|---|---|
| Início de diagnóstico | `diagnosticoIniciado` | `oficina.execution.diagnostico-iniciado` |
| Conclusão de diagnóstico | `diagnosticoFinalizado` | `oficina.execution.diagnostico-finalizado` |
| Início de reparo | `execucaoIniciada` | `oficina.execution.execucao-iniciada` |
| Conclusão de reparo | `execucaoFinalizada` | `oficina.execution.execucao-finalizada` |
| Entrada de estoque | `estoqueAcrescentado` | `oficina.execution.estoque-acrescentado` |
| Reserva ou consumo de estoque | `estoqueBaixado` | `oficina.execution.estoque-baixado` |

Os payloads devem seguir os schemas JSON em [contracts/events/schemas/](../../contracts/events/schemas/).

## Eventos consumidos

| Evento | Uso no DynamoDB |
|---|---|
| `ordemDeServicoCriada` | Criar ou validar contexto operacional local quando necessário |
| `pecaIncluidaNaOrdemDeServico` | Validar peça ativa e preparar reserva quando o fluxo da Saga exigir |
| `servicoIncluidoNaOrdemDeServico` | Validar serviço ativo para execução futura |
| `orcamentoAprovado` | Liberar execução operacional da OS |
| `ordemDeServicoFinalizada` | Encerrar pendências operacionais da OS |
| `sagaCompensada` | Estornar reservas ou cancelar execução conforme estado local |
| `sagaFinalizadaComSucesso` | Marcar fluxo operacional como concluído para auditoria |

Consumidores devem ser idempotentes e não podem alterar dados de outros microsserviços.

## Referências

- [OpenAPI do oficina-execution-service](../../contracts/openapi/oficina-execution-service.yaml)
- [diagnosticoIniciado.schema.json](../../contracts/events/schemas/diagnosticoIniciado.schema.json)
- [diagnosticoFinalizado.schema.json](../../contracts/events/schemas/diagnosticoFinalizado.schema.json)
- [execucaoIniciada.schema.json](../../contracts/events/schemas/execucaoIniciada.schema.json)
- [execucaoFinalizada.schema.json](../../contracts/events/schemas/execucaoFinalizada.schema.json)
- [estoqueAcrescentado.schema.json](../../contracts/events/schemas/estoqueAcrescentado.schema.json)
- [estoqueBaixado.schema.json](../../contracts/events/schemas/estoqueBaixado.schema.json)
- [Padrão Outbox por Serviço](../architecture/outbox-pattern.md)
