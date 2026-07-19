# Homologação da continuidade do pagamento no Lab

## Resultado

Em 19/07/2026, a primeira execução de `[D-PAYMENT-CONTINUITY-TEST-REM-001]` validou Billing `1.8.0`, infraestrutura e UI no `lab`, percorreu a jornada até a cobrança PIX pela API legada `/v1/payments` e comprovou a convergência sob notificações duplicadas, fora de ordem e concorrentes. Na retomada do mesmo dia, os deploys e Quality Gates de Billing `1.9.0`, infraestrutura e UI estavam concluídos, mas a criação pela API Orders foi recusada pelo Mercado Pago porque o secret implantado usava uma credencial `TEST-*`. A documentação atual do provedor exige Access Token de teste com prefixo `APP_USR` para Orders.

A homologação permanece parcial: nenhuma confirmação financeira foi fabricada, nenhuma capability **Registrar entrega** foi liberada e nenhuma entrega foi concluída sem evidência válida do provedor.

Nenhum access token, JWT, secret de webhook, código PIX, imagem QR Code ou URL de pagamento foi registrado nesta evidência. As credenciais foram usadas somente em memória e as inspeções persistiram apenas status, contagens e identificadores internos.

## Deploy e Quality Gates

| Componente | Evidência remota | Resultado no `lab` |
|---|---|---|
| Billing `1.8.0` | O [PR 35](https://github.com/oficina-soat/oficina-billing-service/pull/35) passou em `service-ci-validate` e SonarCloud. O [run 29663620222](https://github.com/oficina-soat/oficina-billing-service/actions/runs/29663620222) validou, publicou os artefatos e a imagem; somente o job de deploy expirou enquanto o cluster estava suspenso. | Pod pronto com a imagem `1.8.0` publicada no ECR. |
| Infraestrutura | O [PR 53](https://github.com/oficina-soat/oficina-infra/pull/53) passou no job `validate`; o [run 29680899732](https://github.com/oficina-soat/oficina-infra/actions/runs/29680899732) retomou o ambiente. | EKS, RDS, mensageria, API Gateway e secrets de runtime disponíveis. |
| UI | O [PR 17](https://github.com/oficina-soat/oficina-ui/pull/17) passou nos gates de build, testes, segurança, E2E, teclado e acessibilidade. O [run 29682148164](https://github.com/oficina-soat/oficina-ui/actions/runs/29682148164) concluiu os mesmos gates e o deploy. | UI pronta, com revisão `8300c057a2ac727b80f3e879df3d5af629b4cc97`. |

Na retomada para Orders, a inspeção somente leitura confirmou:

| Componente | Evidência remota | Resultado no `lab` |
|---|---|---|
| Billing `1.9.0` | O [run 29689106181](https://github.com/oficina-soat/oficina-billing-service/actions/runs/29689106181) concluiu `service-ci-validate`, SonarCloud, publicação e deploy. | Pod pronto com a imagem `1.9.0`. |
| Infraestrutura | O [run 29689155772](https://github.com/oficina-soat/oficina-infra/actions/runs/29689155772) concluiu validação e deploy. | Runtime aplicado; a rota pública com validação obrigatória de assinatura e os secrets esperados estão presentes. |
| UI | O [run 29682148164](https://github.com/oficina-soat/oficina-ui/actions/runs/29682148164) concluiu os Quality Gates e o deploy. | Revisão `8300c057a2ac727b80f3e879df3d5af629b4cc97` pronta. |

As variáveis não sensíveis do cenário foram normalizadas para `OFICINA_MERCADO_PAGO_PAYER_EMAIL=test_user_br@testuser.com` e `OFICINA_MERCADO_PAGO_PAYER_FIRST_NAME=APRO`, e o Billing foi reiniciado com sucesso. Nenhum workflow foi disparado nessa normalização.

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

## Retomada com a API Orders

A nova jornada percorreu as APIs públicas desde a recepção até o reparo concluído:

| Marco | Resultado |
|---|---|
| Correlação | `payment-orders-rem-20260719T134506Z` |
| Ordem de Serviço | `33ee78c1-2fc8-4776-90af-60ab7fccf15d` |
| Execução | `933cc395-dfb3-494a-be55-6a40ee69379a` |
| Orçamento | `188a4e8e-04c9-39d9-a58b-836f5e202443`, valor de `R$ 10,00`, aprovado pelo link público entregue no MailHog. |
| Reparo | Diagnóstico e reparo concluídos; a execução convergiu para `REPARO_CONCLUIDO`. |
| Criação da order | As mensagens `execucaoFinalizada` e `ordemDeServicoFinalizada` chegaram ao Billing, mas as tentativas de criar `POST /v1/orders` receberam `401`. |
| Pagamento | Não criado e não persistido; não há referência externa nem instrução PIX para esta jornada. |

O token implantado respondeu `200` em `GET /users/me`, mas um probe de autorização de `POST /v1/orders`, com corpo vazio e chave de idempotência exclusiva, foi recusado com `401 invalid_credentials` antes da validação do payload. Nenhuma order foi criada pelo probe. A [documentação oficial do teste PIX com Orders](https://www.mercadopago.com.br/developers/pt/docs/checkout-api-orders/integration-test/pix) confirma que o Access Token de teste da aplicação deve começar com `APP_USR`; o secret atual começa com `TEST-`.

A inspeção do PostgreSQL, novamente por pod efêmero e sem exibir credenciais, produziu:

```text
budgets|1|APROVADO
payments|0|none
outbox|orcamentoAprovado|1|PUBLISHED
outbox|orcamentoGerado|1|PUBLISHED
projection|1|true
```

As filas de origem terminaram sem mensagens visíveis nem em processamento. A DLQ de `ordemDeServicoFinalizada` tinha cinco mensagens no total, das quais três mensagens inspecionadas pertenciam à correlação desta jornada; a DLQ de `execucaoFinalizada` tinha seis mensagens no total, sem atribuição integral à jornada. Nada foi removido ou redirecionado porque a credencial inválida faria o processamento falhar novamente.

Na janela da retomada, os logs correlacionados do OS e do Billing não continham padrões de token, assinatura, QR Code, código ou URL PIX. As métricas do Billing continham zero identificador da jornada e zero padrão sensível. A releitura dos traces e da policy **Pagamento indisponível** continua limitada pela ausência de New Relic User API Key.

Como prevenção, o deploy canônico da infraestrutura passou a rejeitar credenciais `TEST-*` no modo `orders` antes de acessar o cluster e documenta o caminho correto para obter a credencial `APP_USR`. Isso evita que uma configuração conhecida como incompatível volte a ser aplicada silenciosamente.

## Pendências para concluir a tarefa

A tarefa permanece aberta no [roadmap](../../ROADMAP.md) pelos seguintes pontos dependentes do ambiente externo:

1. substituir o secret `OFICINA_MERCADO_PAGO_ACCESS_TOKEN` do ambiente `lab` por um Access Token de teste `APP_USR` da aplicação, obtido em **Suas integrações > Dados da integração > Testes > Credenciais de teste**, e executar novo deploy da infraestrutura; o valor não deve ser enviado por chat nem registrado em evidência;
2. no painel do Mercado Pago, confirmar a URL de teste HTTPS, o evento **Order (Mercado Pago)** e, durante a compatibilidade legada, **Pagamentos**, além de confirmar que o secret de webhook corresponde ao implantado;
3. executar uma nova jornada e, após `processed/accredited`, repetir webhook ou **Atualizar situação**, comprovando uma order, um pagamento, uma única Outbox `pagamentoConfirmado`, a capability **Registrar entrega** e a OS em `ENTREGUE`, inclusive sob duplicidade, ordem invertida e concorrência;
4. consultar logs e spans da correlação no New Relic com uma User API Key, confirmando a sanitização e relendo o estado atual da policy de alertas.

Até esses passos, não é correto marcar `[D-PAYMENT-CONTINUITY-TEST-REM-001]` como concluída nem contornar a evidência do provedor por confirmação manual, pois isso violaria a [direção de continuidade do pagamento](../architecture/payment-checkout-continuity.md) e o [contrato REST](../../contracts/Contrato%20de%20APIs%20REST.md).
