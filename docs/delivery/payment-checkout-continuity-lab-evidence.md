# Homologação da continuidade do pagamento no Lab

## Resultado

Em 19/07/2026, a execução de `[D-PAYMENT-CONTINUITY-TEST-REM-001]` implantou e validou Billing `1.8.0`, infraestrutura e UI no `lab`, percorreu a jornada até a cobrança PIX e comprovou a convergência sob notificações duplicadas, fora de ordem e concorrentes. A homologação permanece parcial porque o pagamento PIX criado pela API legada `/v1/payments` ficou `pending` no sandbox do Mercado Pago. Sem uma confirmação real do provedor, o domínio corretamente não publica `pagamentoConfirmado`, não libera a capability **Registrar entrega** e não permite concluir a entrega.

Nenhum access token, JWT, secret de webhook, código PIX, imagem QR Code ou URL de pagamento foi registrado nesta evidência. As credenciais foram usadas somente em memória e as inspeções persistiram apenas status, contagens e identificadores internos.

## Deploy e Quality Gates

| Componente | Evidência remota | Resultado no `lab` |
|---|---|---|
| Billing `1.8.0` | O [PR 35](https://github.com/oficina-soat/oficina-billing-service/pull/35) passou em `service-ci-validate` e SonarCloud. O [run 29663620222](https://github.com/oficina-soat/oficina-billing-service/actions/runs/29663620222) validou, publicou os artefatos e a imagem; somente o job de deploy expirou enquanto o cluster estava suspenso. | Pod pronto com a imagem `1.8.0` publicada no ECR. |
| Infraestrutura | O [PR 53](https://github.com/oficina-soat/oficina-infra/pull/53) passou no job `validate`; o [run 29680899732](https://github.com/oficina-soat/oficina-infra/actions/runs/29680899732) retomou o ambiente. | EKS, RDS, mensageria, API Gateway e secrets de runtime disponíveis. |
| UI | O [PR 17](https://github.com/oficina-soat/oficina-ui/pull/17) passou nos gates de build, testes, segurança, E2E, teclado e acessibilidade. O [run 29682148164](https://github.com/oficina-soat/oficina-ui/actions/runs/29682148164) concluiu os mesmos gates e o deploy. | UI pronta, com revisão `8300c057a2ac727b80f3e879df3d5af629b4cc97`. |

A policy `Oficina SOAT - Alertas Minimos Lab` já possui a condição ativa **Pagamento indisponível**, ID `63810244`, conforme a [evidência dos alertas mínimos](../observability/new-relic-alerts-lab-evidence.md). A releitura remota nesta execução não foi possível porque não havia New Relic User API Key no ambiente local.

## Jornada operacional

A jornada foi criada exclusivamente pelas APIs públicas e operada também pela UI implantada:

| Marco | Resultado |
|---|---|
| Correlação | `payment-continuity-rem-20260719T095353Z` |
| Ordem de Serviço | `726925e4-1570-4dc6-b2db-eea285d93770` |
| Execução | `c72c2645-0cad-4b9e-b383-912b12b2870c` |
| Orçamento | `3d2d49f4-91bb-3eff-9c06-cc47dc1713d4`, aprovado e com valor de `R$ 10,00` |
| Reparo | Diagnóstico e reparo concluídos; OS convergiu para `FINALIZADA`. |
| Pagamento | `9f66da04-4025-31b0-b0ae-ba69f6d8d923`, método `PIX`, provedor `mercado-pago`, status `CRIADO`. |
| UI | A tela **Faturamento** exibiu as instruções PIX e **Atualizar situação** sem erro de navegador nem exposição do conteúdo na automação. |
| Reconciliação | A ação da UI e a chamada autenticada com `Idempotency-Key` retornaram sucesso; o provedor permaneceu `pending`, logo a ação canônica continuou sendo somente `ATUALIZAR_STATUS`. |

O PostgreSQL foi consultado por um pod efêmero com credenciais projetadas por Secret, sem exibir seus valores. Após todas as repetições, as contagens foram:

```text
payments|1|1|CRIADO|CRIADO
budgets|1
outbox|pagamentoSolicitado|1
```

Isso comprova um orçamento, um pagamento, uma transação externa distinta e uma única Outbox `pagamentoSolicitado` para a OS. Nenhum evento terminal foi fabricado enquanto o provedor permaneceu pendente.

## Assinatura do webhook e concorrência

A primeira chamada pública com assinatura válida retornou `401`, embora a mesma notificação enviada diretamente ao Billing retornasse `204`. A inspeção da integração ativa demonstrou que o API Gateway substituía o `x-request-id` do provedor por `$context.requestId`. Como o cabeçalho participa do manifesto HMAC, a borda invalidava notificações legítimas.

O código canônico da infraestrutura passou a preservar `$request.header.x-request-id` somente na rota do webhook, conforme a [regra da borda pública](../infrastructure/api-gateway-public-routes.md). O plano Terraform resultante foi restrito a `0 to add, 1 to change, 0 to destroy` e o `apply` atualizou somente a integração `POST /api/v1/integracoes/mercado-pago/webhooks`. Depois da correção:

- assinatura inválida continuou retornando `401`;
- assinatura válida pela URL pública passou a retornar `204`;
- duas notificações idênticas e concorrentes retornaram `204`;
- uma notificação semanticamente anterior, enviada concorrentemente, retornou `204`;
- a reconciliação autenticada concorrente retornou `200` quando recebeu a chave de idempotência obrigatória;
- o estado permaneceu `CRIADO`, sem regressão, novo pagamento ou nova Outbox, porque a consulta server-to-server confirmou que o provedor ainda estava pendente.

## Sanitização da telemetria

As verificações proporcionais à execução produziram os seguintes resultados:

| Superfície | Evidência |
|---|---|
| Logs dos três microsserviços | Sete registros correlacionados no Billing e zero ocorrência dos padrões de token, secret, assinatura, código PIX, QR Code ou URL de pagamento. |
| Métricas do Billing | `77` séries `payment_provider_*`; zero identificador da jornada e zero padrão sensível. |
| Exportador OpenTelemetry | Zero erro de exportação e zero padrão sensível nos logs do collector durante a janela. |
| Evidência versionada | Este documento contém somente metadados, contagens, estados e identificadores internos. |

A consulta dos spans já exportados no New Relic não pôde ser repetida sem uma User API Key. Portanto, a ausência de conteúdo sensível nos traces da execução ainda precisa de confirmação remota, embora o caminho de exportação esteja saudável e as demais superfícies tenham passado na inspeção.

## Pendências para concluir a tarefa

A tarefa permanece aberta no [roadmap](../../ROADMAP.md) pelos seguintes pontos dependentes do ambiente externo:

1. após a migração, acessar **Suas integrações > Webhooks** no Mercado Pago, confirmar a URL de teste HTTPS, o evento **Order (Mercado Pago)** e, durante a compatibilidade legada, **Pagamentos**, além de confirmar que o secret gerado corresponde ao secret implantado; então executar o simulador e registrar a entrega `2xx` originada pelo provedor;
2. publicar e implantar a candidata Billing `1.9.0` e a configuração já aprovadas na [evidência local da migração Orders](payment-orders-local-evidence.md). O fluxo validado nesta evidência usa `/v1/payments`, cujo PIX permaneceu `pending`; a retomada usará Orders para viabilizar a aprovação automática `APRO`;
3. após `processed/accredited`, repetir webhook ou **Atualizar situação**, comprovar uma única Outbox `pagamentoConfirmado`, a capability **Registrar entrega** e a OS em `ENTREGUE`;
4. consultar logs e spans da correlação no New Relic com uma User API Key, confirmando a sanitização e relendo o estado atual da policy de alertas.

Até esses passos, não é correto marcar `[D-PAYMENT-CONTINUITY-TEST-REM-001]` como concluída nem contornar a evidência do provedor por confirmação manual, pois isso violaria a [direção de continuidade do pagamento](../architecture/payment-checkout-continuity.md) e o [contrato REST](../../contracts/Contrato%20de%20APIs%20REST.md).
