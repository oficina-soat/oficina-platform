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

# Eventos Relacionados a Usuários Operacionais

- [usuarioAdicionado](events/usuarioAdicionado.md)
- [usuarioAtualizado](events/usuarioAtualizado.md)
- [usuarioExcluido](events/usuarioExcluido.md)

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

Observabilidade pode consumir qualquer tópico da tabela, mas não deve ser tratada como microsserviço de domínio.

---

# Schemas JSON

Os schemas JSON dos eventos ficam em:

```text
contracts/events/schemas/
```

Cada schema de evento deve validar o envelope padrão de mensageria e fixar `eventType`, `eventVersion`, `producer`, tópico canônico e payload obrigatório do evento.

O arquivo [common.schema.json](events/schemas/common.schema.json) concentra tipos compartilhados extraídos dos contratos REST atuais e da comunicação existente no `oficina-app`, como identificadores, datas, estados da Ordem de Serviço, status de execução, status de orçamento, status de pagamento, itens de peça, itens de serviço e movimentos de estoque.

---

# Eventos Fora do Escopo Inicial

Os eventos abaixo não fazem parte do contrato fundamental atual e podem ser definidos posteriormente caso surja necessidade de integração entre microsserviços:

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

7. `correlationId` é opcional no envelope para compatibilidade com eventos já publicados. Produtores devem preenchê-lo quando a operação tiver sido iniciada por uma requisição correlacionada ou pelo consumo de outro evento; consumidores devem preservá-lo nos eventos subsequentes. Na ausência do campo, o `eventId` é o identificador de correlação de fallback.
