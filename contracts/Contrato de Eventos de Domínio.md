# Contrato de Eventos de Domínio

## Objetivo

Este documento define os eventos de domínio utilizados para integração entre microsserviços.

Os eventos aqui descritos representam fatos de negócio já ocorridos e devem ser publicados após a conclusão bem-sucedida da operação correspondente.

A nomenclatura dos eventos segue o padrão:

```text
entidade + ação no passado
```

Exemplos:

```text
ordemDeServicoCriada
diagnosticoFinalizado
orcamentoAprovado
```

---

# Eventos Fundamentais

- [ordemDeServicoCriada](events/ordemDeServicoCriada.md)
- [diagnosticoIniciado](events/diagnosticoIniciado.md)
- [pecaIncluidaNaOrdemDeServico](events/pecaIncluidaNaOrdemDeServico.md)
- [servicoIncluidoNaOrdemDeServico](events/servicoIncluidoNaOrdemDeServico.md)
- [diagnosticoFinalizado](events/diagnosticoFinalizado.md)
- [orcamentoGerado](events/orcamentoGerado.md)
- [orcamentoAprovado](events/orcamentoAprovado.md)
- [orcamentoRecusado](events/orcamentoRecusado.md)
- [execucaoIniciada](events/execucaoIniciada.md)
- [execucaoFinalizada](events/execucaoFinalizada.md)
- [ordemDeServicoFinalizada](events/ordemDeServicoFinalizada.md)
- [ordemDeServicoEntregue](events/ordemDeServicoEntregue.md)

---

# Eventos Relacionados a Pagamento

- [pagamentoSolicitado](events/pagamentoSolicitado.md)
- [pagamentoConfirmado](events/pagamentoConfirmado.md)
- [pagamentoRecusado](events/pagamentoRecusado.md)

---

# Eventos Relacionados a Estoque

- [estoqueAcrescentado](events/estoqueAcrescentado.md)
- [estoqueBaixado](events/estoqueBaixado.md)

---

# Eventos de Saga

- [sagaCompensada](events/sagaCompensada.md)
- [sagaFinalizadaComSucesso](events/sagaFinalizadaComSucesso.md)

---

# Tabela Canônica de Eventos e Tópicos

A tabela abaixo é a referência normativa para implementação de produtores, consumidores, Outbox, subscribers e schemas JSON.

| Evento | Tópico canônico | Produtor | Consumidores |
|---|---|---|---|
| `ordemDeServicoCriada` | `oficina.os.ordem-de-servico-criada` | `oficina-os-service` | `oficina-billing-service`, `oficina-execution-service` |
| `diagnosticoIniciado` | `oficina.execution.diagnostico-iniciado` | `oficina-execution-service` | `oficina-os-service` |
| `pecaIncluidaNaOrdemDeServico` | `oficina.os.peca-incluida-na-ordem-de-servico` | `oficina-os-service` | `oficina-billing-service`, `oficina-execution-service` |
| `servicoIncluidoNaOrdemDeServico` | `oficina.os.servico-incluido-na-ordem-de-servico` | `oficina-os-service` | `oficina-billing-service`, `oficina-execution-service` |
| `diagnosticoFinalizado` | `oficina.execution.diagnostico-finalizado` | `oficina-execution-service` | `oficina-os-service`, `oficina-billing-service` |
| `orcamentoGerado` | `oficina.billing.orcamento-gerado` | `oficina-billing-service` | `oficina-os-service` |
| `orcamentoAprovado` | `oficina.billing.orcamento-aprovado` | `oficina-billing-service` | `oficina-os-service`, `oficina-execution-service` |
| `orcamentoRecusado` | `oficina.billing.orcamento-recusado` | `oficina-billing-service` | `oficina-os-service` |
| `execucaoIniciada` | `oficina.execution.execucao-iniciada` | `oficina-execution-service` | `oficina-os-service` |
| `execucaoFinalizada` | `oficina.execution.execucao-finalizada` | `oficina-execution-service` | `oficina-os-service`, `oficina-billing-service` |
| `ordemDeServicoFinalizada` | `oficina.os.ordem-de-servico-finalizada` | `oficina-os-service` | `oficina-billing-service`, `oficina-execution-service` |
| `ordemDeServicoEntregue` | `oficina.os.ordem-de-servico-entregue` | `oficina-os-service` | `oficina-billing-service` |
| `pagamentoSolicitado` | `oficina.billing.pagamento-solicitado` | `oficina-billing-service` | `oficina-os-service` |
| `pagamentoConfirmado` | `oficina.billing.pagamento-confirmado` | `oficina-billing-service` | `oficina-os-service` |
| `pagamentoRecusado` | `oficina.billing.pagamento-recusado` | `oficina-billing-service` | `oficina-os-service` |
| `estoqueAcrescentado` | `oficina.execution.estoque-acrescentado` | `oficina-execution-service` | `oficina-billing-service` |
| `estoqueBaixado` | `oficina.execution.estoque-baixado` | `oficina-execution-service` | `oficina-billing-service` |
| `sagaCompensada` | `oficina.saga.saga-compensada` | `oficina-os-service` | `oficina-billing-service`, `oficina-execution-service` |
| `sagaFinalizadaComSucesso` | `oficina.saga.saga-finalizada-com-sucesso` | `oficina-os-service` | `oficina-billing-service`, `oficina-execution-service` |

Observabilidade pode consumir qualquer tópico da tabela, mas não deve ser tratada como microsserviço de domínio.

---

# Eventos Fora do Escopo Inicial

Os eventos abaixo não fazem parte do contrato fundamental da Fase 4 e podem ser definidos posteriormente caso surja necessidade de integração entre microsserviços:

```text
clienteAdicionado
clienteAtualizado
clienteExcluido

veiculoAdicionado
veiculoAtualizado
veiculoExcluido

pecaAdicionada
pecaAtualizada
pecaExcluida

servicoAdicionado
servicoAtualizado
servicoExcluido

usuarioAdicionado
usuarioAtualizado
usuarioExcluido

pessoaAdicionada
pessoaAtualizada
pessoaExcluida
```

---

# Regras Gerais

1. Eventos representam fatos já ocorridos.

2. Eventos são imutáveis.

3. Eventos devem possuir versionamento próprio.

4. Consumidores devem ser tolerantes a novos campos.

5. A publicação de eventos deve ocorrer através do padrão Outbox.

6. Todos os eventos devem possuir identificador único e timestamp de ocorrência.
