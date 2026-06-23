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
oficina.execution.reparo-concluido
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

## Ciclo de Vida da Ordem de Serviço

```text
oficina.os.ordem-de-servico-criada
oficina.os.estado-da-ordem-de-servico-alterado
oficina.os.ordem-de-servico-cancelada
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
oficina.billing.pagamento-criado
oficina.billing.pagamento-confirmado
oficina.billing.pagamento-recusado
oficina.billing.pagamento-cancelado
```

---

# Tópicos do Execution Service

## Execução

```text
oficina.execution.execucao-criada
oficina.execution.diagnostico-iniciado
oficina.execution.diagnostico-concluido
oficina.execution.reparo-iniciado
oficina.execution.reparo-concluido
oficina.execution.execucao-cancelada
```

## Estoque

```text
oficina.execution.estoque-reservado
oficina.execution.estoque-consumido
oficina.execution.estoque-estornado
oficina.execution.estoque-insuficiente-identificado
```

---

# Eventos de Compensação

Para permitir padronização de rollback distribuído e evolução futura da arquitetura de Saga, a plataforma reserva os seguintes tópicos:

```text
oficina.saga.compensacao-iniciada
oficina.saga.compensacao-concluida
```

Esses tópicos podem ser utilizados por implementações futuras de Saga híbrida ou orquestrada sem necessidade de alteração dos contratos existentes.

---

# Fluxo Principal da Saga

O fluxo principal esperado para uma Ordem de Serviço é:

```text
ordemDeServicoCriada
        ↓
orcamentoGerado
        ↓
orcamentoAprovado
        ↓
execucaoCriada
        ↓
diagnosticoConcluido
        ↓
reparoConcluido
        ↓
pagamentoCriado
        ↓
pagamentoConfirmado
        ↓
estadoDaOrdemDeServicoAlterado(FINALIZADA)
```

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

## Ordenação

A plataforma não garante ordenação global.

Quando necessário, a ordenação deve ser garantida pelo identificador do agregado (`aggregateId`).

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