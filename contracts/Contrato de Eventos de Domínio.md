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
