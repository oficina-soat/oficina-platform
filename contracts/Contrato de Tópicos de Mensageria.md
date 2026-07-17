# Contrato de Mensageria v1

## Objetivo

Definir os contratos de comunicação assíncrona da plataforma distribuída da oficina mecânica.

Este documento estabelece os tópicos, convenções de nomenclatura, estrutura de mensagens e diretrizes de publicação e consumo de eventos entre os microsserviços da solução.

Os contratos aqui definidos devem ser considerados estáveis e versionados.

---

## Convenções Gerais

### Estratégia

A comunicação assíncrona será baseada em eventos de domínio.

Cada evento representa uma mudança de estado relevante do negócio e deve ser publicado após a persistência bem-sucedida da transação local utilizando o padrão Outbox.

### Convenção de Nomes

Todos os tópicos devem seguir o padrão:

```text
oficina.<dominio>.<evento>
```

Exemplos:

```text
oficina.os.ordem-de-servico-criada
oficina.billing.orcamento-aprovado
oficina.execution.execucao-finalizada
```

### Versionamento

A evolução dos eventos deve ocorrer através do campo:

```json
{
  "eventVersion": 1
}
```

Mudanças incompatíveis exigem incremento da versão.

---

## Envelope Padrão dos Eventos

Todos os eventos publicados na plataforma devem seguir a seguinte estrutura:

```json
{
  "eventId": "uuid",
  "eventType": "orcamentoAprovado",
  "eventVersion": 1,
  "occurredAt": "2026-06-23T15:30:00Z",
  "producer": "oficina-billing-service",
  "aggregateId": "uuid",
  "payload": {}
}
```

### Campos Obrigatórios

| Campo | Descrição |
|---|---|
| eventId | Identificador único do evento |
| eventType | Nome lógico do evento |
| eventVersion | Versão do contrato |
| occurredAt | Data e hora da ocorrência |
| producer | Serviço emissor |
| aggregateId | Identificador da entidade principal |
| payload | Dados específicos do evento |

---

# Tópicos do OS Service

## Usuários operacionais

```text
oficina.os.usuario-adicionado
oficina.os.usuario-atualizado
oficina.os.usuario-excluido
```

## Ciclo de Vida da Ordem de Serviço

```text
oficina.os.ordem-de-servico-criada
oficina.os.peca-incluida-na-ordem-de-servico
oficina.os.servico-incluido-na-ordem-de-servico
oficina.os.ordem-de-servico-finalizada
oficina.os.ordem-de-servico-entregue
```

---

# Tópicos do Billing Service

## Orçamentos

```text
oficina.billing.orcamento-gerado
oficina.billing.orcamento-aprovado
oficina.billing.orcamento-recusado
```

## Pagamentos

```text
oficina.billing.pagamento-solicitado
oficina.billing.pagamento-confirmado
oficina.billing.pagamento-recusado
```

---

# Tópicos do Execution Service

## Execução

```text
oficina.execution.diagnostico-iniciado
oficina.execution.diagnostico-finalizado
oficina.execution.execucao-iniciada
oficina.execution.execucao-finalizada
```

## Estoque

```text
oficina.execution.estoque-acrescentado
oficina.execution.estoque-baixado
```

---

# Eventos de Compensação

Para permitir padronização de rollback distribuído e evolução futura da arquitetura de Saga, a plataforma reserva os seguintes tópicos:

```text
oficina.saga.saga-compensada
oficina.saga.saga-finalizada-com-sucesso
```

Esses tópicos podem ser utilizados por implementações futuras de Saga híbrida ou orquestrada sem necessidade de alteração dos contratos existentes.

---

# Fluxo Principal da Saga

O fluxo principal esperado para uma Ordem de Serviço é:

```text
ordemDeServicoCriada
        ↓
diagnosticoIniciado
        ↓
diagnosticoFinalizado
        ↓
orcamentoGerado
        ↓
orcamentoAprovado
        ↓
execucaoIniciada
        ↓
execucaoFinalizada
        ↓
ordemDeServicoFinalizada
        ↓
pagamentoSolicitado
        ↓
pagamentoConfirmado
        ↓
ordemDeServicoEntregue
        ↓
sagaFinalizadaComSucesso
```

---

# Tabela Canônica de Roteamento

Esta tabela deve ser mantida coerente com o [Contrato de Eventos de Domínio](Contrato%20de%20Eventos%20de%20Domínio.md) e com os schemas JSON de eventos.

| Evento | Tópico canônico | Produtor | Consumidores |
|---|---|---|---|
| `ordemDeServicoCriada` | `oficina.os.ordem-de-servico-criada` | `oficina-os-service` | `oficina-billing-service`, `oficina-execution-service` |
| `diagnosticoIniciado` | `oficina.execution.diagnostico-iniciado` | `oficina-execution-service` | `oficina-os-service` |
| `pecaIncluidaNaOrdemDeServico` | `oficina.os.peca-incluida-na-ordem-de-servico` | `oficina-os-service` | `oficina-billing-service`, `oficina-execution-service` |
| `servicoIncluidoNaOrdemDeServico` | `oficina.os.servico-incluido-na-ordem-de-servico` | `oficina-os-service` | `oficina-billing-service`, `oficina-execution-service` |
| `diagnosticoFinalizado` | `oficina.execution.diagnostico-finalizado` | `oficina-execution-service` | `oficina-os-service`, `oficina-billing-service` |
| `orcamentoGerado` | `oficina.billing.orcamento-gerado` | `oficina-billing-service` | `oficina-os-service` |
| `orcamentoAprovado` | `oficina.billing.orcamento-aprovado` | `oficina-billing-service` | `oficina-os-service`, `oficina-execution-service` |
| `orcamentoRecusado` | `oficina.billing.orcamento-recusado` | `oficina-billing-service` | `oficina-os-service`, `oficina-execution-service` |
| `execucaoIniciada` | `oficina.execution.execucao-iniciada` | `oficina-execution-service` | `oficina-os-service` |
| `execucaoFinalizada` | `oficina.execution.execucao-finalizada` | `oficina-execution-service` | `oficina-os-service`, `oficina-billing-service` |
| `ordemDeServicoFinalizada` | `oficina.os.ordem-de-servico-finalizada` | `oficina-os-service` | `oficina-billing-service`, `oficina-execution-service` |
| `ordemDeServicoEntregue` | `oficina.os.ordem-de-servico-entregue` | `oficina-os-service` | `oficina-billing-service` |
| `pagamentoSolicitado` | `oficina.billing.pagamento-solicitado` | `oficina-billing-service` | `oficina-os-service` |
| `pagamentoConfirmado` | `oficina.billing.pagamento-confirmado` | `oficina-billing-service` | `oficina-os-service` |
| `pagamentoRecusado` | `oficina.billing.pagamento-recusado` | `oficina-billing-service` | `oficina-os-service` |
| `estoqueAcrescentado` | `oficina.execution.estoque-acrescentado` | `oficina-execution-service` | `oficina-billing-service` |
| `estoqueBaixado` | `oficina.execution.estoque-baixado` | `oficina-execution-service` | `oficina-billing-service` |
| `usuarioAdicionado` | `oficina.os.usuario-adicionado` | `oficina-os-service` | `oficina-auth-sync-lambda` |
| `usuarioAtualizado` | `oficina.os.usuario-atualizado` | `oficina-os-service` | `oficina-auth-sync-lambda` |
| `usuarioExcluido` | `oficina.os.usuario-excluido` | `oficina-os-service` | `oficina-auth-sync-lambda` |
| `sagaCompensada` | `oficina.saga.saga-compensada` | `oficina-os-service` | `oficina-billing-service`, `oficina-execution-service` |
| `sagaFinalizadaComSucesso` | `oficina.saga.saga-finalizada-com-sucesso` | `oficina-os-service` | `oficina-billing-service`, `oficina-execution-service` |

---

# Garantias de Entrega

## Publicação

Os eventos devem ser publicados exclusivamente através do mecanismo Outbox.

A publicação direta para o broker durante a transação de negócio não é permitida.

## Consumo

Consumidores devem ser:

- idempotentes;
- tolerantes a reprocessamento;
- tolerantes a eventos duplicados;
- compatíveis com processamento assíncrono.

O `oficina-auth-sync-lambda` é um consumidor serverless da mesma mensageria. Suas filas devem acionar a função por event source mapping com resposta parcial de lote habilitada. O consumidor confirma eventos duplicados já registrados por `eventId` e retorna como falha somente os itens que não puderam ser aplicados, preservando os demais itens do lote.

## Ordenação

A plataforma não garante ordenação global nem entre tópicos diferentes.

Quando necessário, o consumidor deve controlar a progressão pelo identificador do agregado (`aggregateId`) e pelo instante do fato (`occurredAt`). Como os três eventos de usuário usam filas distintas, o `oficina-auth-sync-lambda` persiste o último `occurredAt` aplicado por usuário. Um evento com instante igual ou anterior é registrado para idempotência, mas não pode sobrescrever a projeção mais recente.

## Retentativas

Falhas temporárias devem ser tratadas através de retentativas automáticas do mecanismo de mensageria.

Eventos inválidos devem ser encaminhados para fila de erro (Dead Letter Queue).

---

# Dead Letter Queue

Cada consumidor deverá possuir uma fila de erro correspondente.

Convenção:

```text
<topico>.dlq
```

Exemplo:

```text
oficina.billing.pagamento-confirmado.dlq
```

---

# Eventos Removidos do Contrato Fundamental

Os seguintes eventos não fazem parte deste contrato fundamental por não possuírem consumidores diretos previstos entre microsserviços:

```text
oficina.os.cliente-criado
oficina.os.cliente-atualizado
oficina.os.veiculo-criado
oficina.os.veiculo-atualizado
oficina.execution.peca-criada
oficina.execution.peca-atualizada
oficina.execution.servico-criado
oficina.execution.servico-atualizado
oficina.execution.estoque-entrada-registrada
```

Esses eventos poderão ser definidos futuramente em contratos específicos caso passem a ser necessários para integração entre microsserviços.

---

# Referências

- ADR-010 — Separação dos Microsserviços
- Contrato de Estados da Ordem de Serviço
- Contrato de Eventos de Domínio
- Contrato de APIs REST
- ADR de Comunicação e Integração Entre Microsserviços
- ADR de Saga Pattern
