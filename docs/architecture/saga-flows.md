# Fluxos da Saga da Ordem de Serviço

## Objetivo

Detalhar os fluxos da Saga orquestrada pelo `oficina-os-service` para a Ordem de Serviço, incluindo fluxo feliz, recusa de orçamento, pagamento recusado, falhas de execução, compensações, timeouts, retentativas e testes de contrato.

Este documento complementa a [ADR-009 - Estratégia de Saga Pattern](../../adr/ADR-009%20-%20Estratégia%20de%20Saga%20Pattern.md), o [Contrato de Saga do oficina-os-service](../../contracts/saga/oficina-os-saga-v1.md), o [Contrato de Estados da Ordem de Serviço](../../contracts/Contrato%20de%20Estados%20da%20Ordem%20de%20Serviço.md), o [Contrato de Eventos de Domínio](../../contracts/Contrato%20de%20Eventos%20de%20Domínio.md), o [Contrato de Tópicos de Mensageria](../../contracts/Contrato%20de%20Tópicos%20de%20Mensageria.md) e o [Contrato de Idempotência](../../contracts/idempotency.md).

## Premissas

- O `oficina-os-service` é o orquestrador e a autoridade sobre o estado global da OS e da Saga.
- `oficina-billing-service` é autoridade sobre orçamento e pagamento.
- `oficina-execution-service` é autoridade sobre diagnóstico, execução e estoque operacional.
- Comandos da Saga usam APIs REST existentes com `X-Idempotency-Key` determinística.
- Confirmações de etapas são recebidas por eventos de domínio publicados via Outbox.
- A Saga não cria eventos novos além dos eventos já definidos em [Contrato de Eventos de Domínio](../../contracts/Contrato%20de%20Eventos%20de%20Domínio.md).

## Estados da Saga

| Estado | Descrição |
|---|---|
| `INICIADA` | OS criada e Saga registrada no `oficina-os-service`. |
| `EM_DIAGNOSTICO` | Diagnóstico operacional em andamento no `oficina-execution-service`. |
| `AGUARDANDO_ORCAMENTO` | Diagnóstico concluído e orçamento solicitado ao `oficina-billing-service`. |
| `AGUARDANDO_APROVACAO` | Orçamento gerado e aguardando aprovação ou recusa. |
| `EM_EXECUCAO` | Orçamento aprovado e execução técnica em andamento. |
| `AGUARDANDO_PAGAMENTO` | Execução finalizada e pagamento solicitado. |
| `AGUARDANDO_ENTREGA` | Pagamento confirmado e veículo liberado para entrega. |
| `FINALIZADA_COM_SUCESSO` | Veículo entregue e Saga encerrada com sucesso. |
| `EM_COMPENSACAO` | Falha tratável exige compensações idempotentes. |
| `COMPENSADA` | Compensações concluídas e evento `sagaCompensada` publicado. |
| `FALHA_MANUAL` | Falha não compensável automaticamente exige intervenção operacional. |

## Fluxo feliz

| Ordem | Acionador | Responsável | Operação | Evento esperado | Estado da OS |
|---:|---|---|---|---|---|
| 1 | `POST /api/v1/ordens-servico` | `oficina-os-service` | Criar OS e Saga | `ordemDeServicoCriada` | `RECEBIDA` |
| 2 | `ordemDeServicoCriada` | `oficina-os-service` | Solicitar criação da execução | nenhum evento obrigatório | `RECEBIDA` |
| 3 | Comando da Saga | `oficina-execution-service` | Iniciar diagnóstico | `diagnosticoIniciado` | `EM_DIAGNOSTICO` |
| 4 | Técnico conclui diagnóstico | `oficina-execution-service` | Concluir diagnóstico | `diagnosticoFinalizado` | `AGUARDANDO_APROVACAO` |
| 5 | `diagnosticoFinalizado` | `oficina-os-service` | Solicitar orçamento | `orcamentoGerado` | `AGUARDANDO_APROVACAO` |
| 6 | Aprovação do cliente | `oficina-billing-service` | Aprovar orçamento | `orcamentoAprovado` | `AGUARDANDO_APROVACAO` |
| 7 | `orcamentoAprovado` | `oficina-execution-service` | Iniciar reparo autorizado de forma idempotente | `execucaoIniciada` | `EM_EXECUCAO` |
| 8 | Técnico conclui reparo | `oficina-execution-service` | Finalizar execução e baixar estoque consumido | `execucaoFinalizada`, `estoqueBaixado` quando aplicável | `FINALIZADA` |
| 9 | `execucaoFinalizada` | `oficina-os-service` | Registrar finalização técnica da OS | `ordemDeServicoFinalizada` | `FINALIZADA` |
| 10 | `ordemDeServicoFinalizada` | `oficina-billing-service` | Solicitar pagamento | `pagamentoSolicitado` | `FINALIZADA` |
| 11 | Confirmação financeira | `oficina-billing-service` | Confirmar pagamento | `pagamentoConfirmado` | `FINALIZADA` |
| 12 | `pagamentoConfirmado` | `oficina-os-service` | Liberar entrega | nenhum evento obrigatório | `FINALIZADA` |
| 13 | Entrega ao cliente | `oficina-os-service` | Entregar veículo | `ordemDeServicoEntregue`, `sagaFinalizadaComSucesso` | `ENTREGUE` |

## Recusa de orçamento

Quando o cliente recusa o orçamento, o `oficina-billing-service` publica `orcamentoRecusado`.

| Etapa | Comportamento |
|---|---|
| Estado anterior | OS em `AGUARDANDO_APROVACAO` e Saga em `AGUARDANDO_APROVACAO`. |
| Evento de falha de negócio | `orcamentoRecusado`. |
| Ação do orquestrador | Registrar histórico, retornar OS para `EM_DIAGNOSTICO` e mover Saga para `EM_DIAGNOSTICO`. |
| Compensação | Não há compensação distribuída obrigatória, pois execução, baixa de estoque e pagamento ainda não ocorreram. |
| Evento de Saga | Não publicar `sagaCompensada`; a Saga continua ativa para revisão de diagnóstico e novo orçamento. |

## Pagamento recusado

Quando o pagamento é recusado, o `oficina-billing-service` publica `pagamentoRecusado`.

| Etapa | Comportamento |
|---|---|
| Estado anterior | OS em `FINALIZADA` e Saga em `AGUARDANDO_PAGAMENTO`. |
| Evento de falha de negócio | `pagamentoRecusado`. |
| Retentativa | Permitir nova tentativa de pagamento com chave idempotente diferente quando houver novo pedido do cliente ou retentativa operacional autorizada. |
| Compensação automática | Não estornar execução nem estoque automaticamente, pois o serviço já foi concluído tecnicamente. |
| Resultado após exceder política | Saga vai para `FALHA_MANUAL`; veículo não deve avançar para `ENTREGUE` enquanto o pagamento não for resolvido. |

## Falhas de execução e estoque

Falhas operacionais antes de `execucaoFinalizada` devem ser tratadas sem publicar eventos de sucesso artificiais.

| Falha | Ponto | Comportamento |
|---|---|---|
| Falha ao iniciar execução | Antes de `execucaoIniciada` | Retentar comando; se exceder política, manter OS em `AGUARDANDO_APROVACAO` e Saga em `FALHA_MANUAL`. |
| Falha de reserva ou disponibilidade de estoque | Antes de execução efetiva | Retentar validação/reserva; se a indisponibilidade for definitiva, mover Saga para `EM_COMPENSACAO` e publicar `sagaCompensada` após registrar motivo. |
| Falha durante reparo | Depois de `execucaoIniciada` e antes de `execucaoFinalizada` | Cancelar execução quando possível; se houver estoque reservado ou baixado parcialmente, executar estorno idempotente. |
| Falha após `execucaoFinalizada` | Depois da conclusão técnica | Não reabrir execução automaticamente; mover Saga para `FALHA_MANUAL` se o próximo passo não puder ser concluído. |

## Compensações

| Etapa concluída | Compensação | Serviço executor | Idempotency key |
|---|---|---|---|
| Orçamento gerado | Cancelar ou invalidar orçamento quando houver endpoint implementado | `oficina-billing-service` | `saga:<sagaId>:compensar-orcamento:<orcamentoId>` |
| Execução iniciada | Cancelar execução | `oficina-execution-service` | `saga:<sagaId>:cancelar-execucao:<execucaoId>` |
| Estoque reservado ou baixado parcialmente | Estornar estoque | `oficina-execution-service` | `saga:<sagaId>:compensar-estoque:<ordemServicoId>` |
| OS ainda não entregue | Bloquear entrega e registrar falha | `oficina-os-service` | `saga:<sagaId>:bloquear-entrega:<ordemServicoId>` |

Compensações concluídas devem resultar em `sagaCompensada`. Fluxos concluídos com entrega devem resultar em `sagaFinalizadaComSucesso`.

## Timeouts e retentativas

| Espera | Timeout inicial | Retentativa | Resultado ao exceder |
|---|---:|---|---|
| `diagnosticoIniciado` | 15 minutos | 3 tentativas com backoff exponencial | `FALHA_MANUAL` |
| `diagnosticoFinalizado` | 7 dias | Sem retentativa automática de negócio | `FALHA_MANUAL` após alerta operacional |
| `orcamentoGerado` | 15 minutos | 3 tentativas com backoff exponencial | `EM_COMPENSACAO` |
| `orcamentoAprovado` ou `orcamentoRecusado` | 7 dias | Sem retentativa automática de negócio | `FALHA_MANUAL` após alerta operacional |
| `execucaoIniciada` | 15 minutos | 3 tentativas com backoff exponencial | `FALHA_MANUAL` |
| `execucaoFinalizada` | 7 dias | Sem retentativa automática de negócio | `FALHA_MANUAL` após alerta operacional |
| `pagamentoSolicitado` | 15 minutos | 3 tentativas com backoff exponencial | `FALHA_MANUAL` |
| `pagamentoConfirmado` ou `pagamentoRecusado` | 24 horas | Retentativas definidas pelo provedor financeiro | `FALHA_MANUAL` |

Retentativas técnicas não devem criar novos agregados, eventos duplicados ou novos `eventId` para o mesmo evento lógico já persistido em Outbox.

## Testes de contrato

Os testes de contrato da Saga devem cobrir:

- sequência feliz até `sagaFinalizadaComSucesso`;
- recusa de orçamento retornando a OS para `EM_DIAGNOSTICO`;
- pagamento recusado bloqueando `ordemDeServicoEntregue`;
- falha de execução antes de `execucaoFinalizada`;
- falha de estoque com estorno idempotente;
- duplicidade de eventos por `eventId`;
- reuso de `X-Idempotency-Key` com payload diferente retornando erro do [Contrato de Erros REST](../../contracts/error-model.md);
- timeouts levando ao estado de Saga esperado.
