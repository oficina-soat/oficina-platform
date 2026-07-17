# Contrato de Saga do oficina-os-service v1

## Objetivo

Definir o contrato implementável da Saga orquestrada pelo `oficina-os-service` para coordenação da Ordem de Serviço.

Este contrato deve ser usado junto com [Fluxos da Saga da Ordem de Serviço](../../docs/architecture/saga-flows.md), [Contrato de APIs REST](../Contrato%20de%20APIs%20REST.md), [Contrato de Eventos de Domínio](../Contrato%20de%20Eventos%20de%20Domínio.md), [Contrato de Tópicos de Mensageria](../Contrato%20de%20Tópicos%20de%20Mensageria.md), [Contrato de Estados da Ordem de Serviço](../Contrato%20de%20Estados%20da%20Ordem%20de%20Serviço.md), [Contrato de Erros REST](../error-model.md) e [Contrato de Idempotência](../idempotency.md).

## Identidade da Saga

| Campo | Regra |
|---|---|
| `sagaId` | UUID gerado pelo `oficina-os-service`. |
| `aggregateId` | `ordemServicoId`. |
| `producer` | `oficina-os-service` para eventos de Saga. |
| `correlationId` | Deve ser propagado em comandos REST, eventos, logs e traces. |
| `eventVersion` | `1` para os eventos atuais. |

## Estados

```text
INICIADA
EM_DIAGNOSTICO
AGUARDANDO_ORCAMENTO
AGUARDANDO_APROVACAO
EM_EXECUCAO
AGUARDANDO_PAGAMENTO
AGUARDANDO_ENTREGA
FINALIZADA_COM_SUCESSO
EM_COMPENSACAO
COMPENSADA
FALHA_MANUAL
```

Estados finais:

```text
FINALIZADA_COM_SUCESSO
COMPENSADA
FALHA_MANUAL
```

## Comandos REST da Saga

Comandos devem usar `X-Idempotency-Key` no formato definido no [Contrato de Idempotência](../idempotency.md).

| Comando lógico | Serviço | Operação REST | Chave idempotente |
|---|---|---|---|
| `criar-execucao` | `oficina-execution-service` | `POST /api/v1/execucoes` | `saga:<sagaId>:criar-execucao:<ordemServicoId>` |
| `iniciar-diagnostico` | `oficina-execution-service` | `POST /api/v1/execucoes/{execucaoId}/diagnostico/inicio` | `saga:<sagaId>:iniciar-diagnostico:<execucaoId>` |
| `gerar-orcamento` | `oficina-billing-service` | `POST /api/v1/orcamentos` | `saga:<sagaId>:gerar-orcamento:<ordemServicoId>` |
| `iniciar-execucao` | `oficina-execution-service` | `POST /api/v1/execucoes/{execucaoId}/reparo/inicio` | `saga:<sagaId>:iniciar-execucao:<execucaoId>` |
| `solicitar-pagamento` | `oficina-billing-service` | `POST /api/v1/pagamentos` | `saga:<sagaId>:solicitar-pagamento:<ordemServicoId>` |
| `cancelar-execucao` | `oficina-execution-service` | `POST /api/v1/execucoes/{execucaoId}/cancelamento` | `saga:<sagaId>:cancelar-execucao:<execucaoId>` |
| `compensar-estoque` | `oficina-execution-service` | `POST /api/v1/estoques/movimentos/estorno` | `saga:<sagaId>:compensar-estoque:<ordemServicoId>` |

## Eventos consumidos

| Evento | Próximo estado da Saga | Ação do `oficina-os-service` |
|---|---|---|
| `ordemDeServicoCriada` | `INICIADA` | Criar registro da Saga e acionar execução. |
| `diagnosticoIniciado` | `EM_DIAGNOSTICO` | Registrar transição da OS para `EM_DIAGNOSTICO`. |
| `diagnosticoFinalizado` | `AGUARDANDO_ORCAMENTO` | Solicitar geração de orçamento. |
| `orcamentoGerado` | `AGUARDANDO_APROVACAO` | Aguardar decisão do cliente. |
| `orcamentoAprovado` | `EM_EXECUCAO` | Solicitar início de execução. |
| `orcamentoRecusado` | `EM_DIAGNOSTICO` | Retornar OS para diagnóstico sem encerrar a Saga. |
| `execucaoIniciada` | `EM_EXECUCAO` | Registrar execução em andamento. |
| `execucaoFinalizada` | `AGUARDANDO_PAGAMENTO` | Registrar OS como `FINALIZADA`, publicar `ordemDeServicoFinalizada` e aguardar pagamento. |
| `pagamentoSolicitado` | `AGUARDANDO_PAGAMENTO` | Registrar pagamento pendente. |
| `pagamentoConfirmado` | `AGUARDANDO_ENTREGA` | Liberar entrega da OS. |
| `pagamentoRecusado` | `AGUARDANDO_PAGAMENTO` | Registrar recusa, bloquear entrega e permitir nova tentativa enquanto a política operacional não for excedida. |

Eventos publicados em tópicos distintos podem ser entregues fora da ordem em que foram
produzidos. O consumidor deve validar o estado atual antes de aplicar uma transição e
registrar na inbox, sem regredir a Saga, eventos incompatíveis com uma etapa já superada.
Em particular:

- `diagnosticoIniciado` só pode levar a Saga de `INICIADA` para `EM_DIAGNOSTICO` ou
  confirmar que ela já está em `EM_DIAGNOSTICO`;
- se `diagnosticoFinalizado` chegar primeiro, o `oficina-os-service` deve preservar o
  histórico válido da OS com as transições `RECEBIDA -> EM_DIAGNOSTICO ->
  AGUARDANDO_APROVACAO` e avançar a Saga para `AGUARDANDO_ORCAMENTO`;
- um `diagnosticoIniciado` entregue depois dessa conclusão deve ser tratado de forma
  idempotente, sem alterar o estado corrente.

## Eventos produzidos

| Evento | Quando publicar |
|---|---|
| `ordemDeServicoCriada` | Ao abrir a OS e iniciar a Saga. |
| `ordemDeServicoFinalizada` | Após `execucaoFinalizada` ser consumido e a OS atingir `FINALIZADA`. |
| `ordemDeServicoEntregue` | Após pagamento confirmado e entrega do veículo ao cliente. |
| `sagaCompensada` | Após compensações automáticas concluídas. |
| `sagaFinalizadaComSucesso` | Após `ordemDeServicoEntregue`. |

## Transições inválidas

- `pagamentoConfirmado` antes de `pagamentoSolicitado`.
- `execucaoIniciada` antes de `orcamentoAprovado`.
- `execucaoFinalizada` antes de `execucaoIniciada`.
- `ordemDeServicoEntregue` antes de `pagamentoConfirmado`.
- `sagaFinalizadaComSucesso` antes de `ordemDeServicoEntregue`.

Eventos inválidos para o estado atual devem ser registrados com `correlationId` e tratados de forma idempotente. Eles não devem produzir transição de estado.

## Persistência mínima

O `oficina-os-service` deve persistir:

- `sagaId`;
- `ordemServicoId`;
- estado atual da Saga;
- estado atual da OS no momento da transição;
- última etapa executada;
- IDs correlatos conhecidos, como `execucaoId`, `orcamentoId` e `pagamentoId`;
- `correlationId`;
- timestamps de criação e atualização;
- histórico de transições;
- último erro ou motivo de compensação quando houver.

## Compatibilidade

Este contrato é `v1`. Mudanças incompatíveis devem criar nova versão do contrato da Saga e preservar compatibilidade com eventos `eventVersion=1` enquanto houver consumidores ativos.
