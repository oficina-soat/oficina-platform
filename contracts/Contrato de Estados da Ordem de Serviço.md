# Contrato de Estados da Ordem de Serviço

## Objetivo

Este documento define os estados oficiais da Ordem de Serviço e as transições válidas entre eles.

Este contrato deve ser utilizado por todos os microsserviços que publiquem, consumam, alterem ou consultem informações relacionadas ao ciclo de vida de uma Ordem de Serviço.

## Estados oficiais

### RECEBIDA

Estado inicial da Ordem de Serviço.

Indica que a OS foi aberta e registrada, mas ainda não teve o diagnóstico técnico iniciado.

### EM_DIAGNOSTICO

Indica que a OS está em diagnóstico técnico.

Neste estado, podem ser incluídas peças e serviços necessários para compor o orçamento da OS.

### AGUARDANDO_APROVACAO

Indica que o diagnóstico foi concluído e que a OS aguarda aprovação do orçamento.

A OS pode avançar para execução caso o orçamento seja aprovado, ou retornar para diagnóstico caso o orçamento seja recusado.

### EM_EXECUCAO

Indica que o orçamento foi aprovado e que os serviços da OS estão em execução.

### FINALIZADA

Indica que a execução técnica da OS foi concluída.

A OS ainda não representa encerramento operacional completo, pois o veículo ainda precisa ser entregue ao cliente.

### ENTREGUE

Estado final da Ordem de Serviço.

Indica que o veículo foi entregue ao cliente e que o ciclo operacional da OS foi encerrado.

## Transições permitidas

| Estado atual         | Ação                  | Próximo estado       |
| -------------------- | --------------------- | -------------------- |
| RECEBIDA             | iniciar diagnóstico   | EM_DIAGNOSTICO       |
| EM_DIAGNOSTICO       | finalizar diagnóstico | AGUARDANDO_APROVACAO |
| AGUARDANDO_APROVACAO | iniciar execução      | EM_EXECUCAO          |
| AGUARDANDO_APROVACAO | recusar orçamento     | EM_DIAGNOSTICO       |
| EM_EXECUCAO          | finalizar execução    | FINALIZADA           |
| FINALIZADA           | entregar veículo      | ENTREGUE             |

## Fluxo principal

```text
RECEBIDA
  -> EM_DIAGNOSTICO
  -> AGUARDANDO_APROVACAO
  -> EM_EXECUCAO
  -> FINALIZADA
  -> ENTREGUE
```

## Fluxo de recusa do orçamento

```text
AGUARDANDO_APROVACAO
  -> EM_DIAGNOSTICO
```

Quando o orçamento é recusado, a OS retorna para diagnóstico para revisão de peças, serviços, valores ou escopo técnico.

## Regras associadas aos estados

### Inclusão de peças

Peças somente podem ser incluídas quando a OS estiver no estado:

```text
EM_DIAGNOSTICO
```

### Inclusão de serviços

Serviços somente podem ser incluídos quando a OS estiver no estado:

```text
EM_DIAGNOSTICO
```

### Alteração de estado

Toda alteração de estado deve registrar:

```text
estado
dataDoEstado
```

O histórico de estados deve preservar todas as alterações realizadas na OS.

## Estado inicial

```text
RECEBIDA
```

Toda Ordem de Serviço recém-criada deve iniciar obrigatoriamente no estado `RECEBIDA`.

## Estado final

```text
ENTREGUE
```

Após atingir o estado `ENTREGUE`, a Ordem de Serviço não deve sofrer novas transições de estado.

## Transições inválidas

Qualquer transição não listada explicitamente neste documento deve ser considerada inválida.

Exemplos:

```text
RECEBIDA -> AGUARDANDO_APROVACAO
RECEBIDA -> EM_EXECUCAO
EM_DIAGNOSTICO -> EM_EXECUCAO
AGUARDANDO_APROVACAO -> FINALIZADA
EM_EXECUCAO -> ENTREGUE
ENTREGUE -> EM_DIAGNOSTICO
```

## Observações para a Fase 4

Este contrato representa o ciclo de vida da Ordem de Serviço conhecido no domínio atual.

Na arquitetura distribuída da Fase 4, os microsserviços devem respeitar este contrato ao produzir eventos, consumir eventos, expor APIs ou executar etapas de Saga relacionadas à OS.

Alterações neste contrato devem ser tratadas como mudanças de contrato de integração e documentadas antes da implementação nos serviços consumidores.
