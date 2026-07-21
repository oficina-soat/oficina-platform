# Homologação da continuidade do pagamento no Lab

## Resultado

Em 19/07/2026, a primeira execução de `[D-PAYMENT-CONTINUITY-TEST-REM-001]` validou Billing `1.8.0`, infraestrutura e UI no `lab`, percorreu a jornada até a cobrança PIX pela API legada `/v1/payments` e comprovou a convergência sob notificações duplicadas, fora de ordem e concorrentes. Na retomada do mesmo dia, os deploys e Quality Gates de Billing `1.9.0`, infraestrutura e UI estavam concluídos, mas a criação pela API Orders foi recusada pelo Mercado Pago porque o secret implantado usava uma credencial `TEST-*`. Após a substituição pelo Access Token de teste `APP_USR` exigido pelo provedor, a mesma jornada convergiu por reconciliação para uma order PIX, um pagamento confirmado, uma Outbox financeira terminal e uma entrega.

A confirmação ocorreu exclusivamente por reconciliação server-to-server com o Mercado Pago; nenhuma confirmação financeira foi fabricada. Uma jornada adicional confirmou que o painel envia notificações reais de Orders e que a telemetria está disponível no New Relic, mas revelou uma incompatibilidade na tolerância temporal da assinatura: o provedor envia `ts` em milissegundos e o Billing `1.9.0` o compara como epoch em segundos. O Billing `1.10.1` corrigiu essa incompatibilidade e o `1.10.2` acrescentou diagnóstico sanitizado da etapa de validação. Callbacks reais recebidos pelo `1.10.2` foram classificados como `hash_mismatch`, enquanto simulações de teste e produção do painel foram aceitas com `200`. A causa permanece em investigação: os identificadores distintos apresentados nas credenciais de teste e nos dados da integração pertencem à mesma aplicação e não comprovam divergência de aplicação, token ou secret.

Nenhum access token, JWT, secret de webhook, código PIX, imagem QR Code ou URL de pagamento foi registrado nesta evidência. As consultas e inspeções aqui documentadas apresentam apenas status, contagens e identificadores internos.

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

Após a troca do secret, o [PR 57 da infraestrutura](https://github.com/oficina-soat/oficina-infra/pull/57) publicou a validação preventiva de credenciais e o [run 29691640986](https://github.com/oficina-soat/oficina-infra/actions/runs/29691640986) concluiu os jobs `validate` e `deploy`. O rollout deixou o Billing `1.9.0` pronto no modo `orders` com credencial da classe `APP_USR`; um probe vazio passou da autenticação e recebeu `400` de validação de payload, sem criar order.

Após a rotação do secret de webhook, o [run 29695522333](https://github.com/oficina-soat/oficina-infra/actions/runs/29695522333) concluiu validação e deploy. O novo pod do Billing ficou pronto no modo `orders`; um probe com assinatura inválida recebeu `401` e outro, assinado com o secret efetivamente projetado, passou da autenticação e recebeu `404` para uma order deliberadamente inexistente.

O Billing `1.10.1` foi publicado e implantado pelo [PR 37](https://github.com/oficina-soat/oficina-billing-service/pull/37) e pelo [run 29698187287](https://github.com/oficina-soat/oficina-billing-service/actions/runs/29698187287). Como o callback real continuou recebendo `401`, o Billing `1.10.2` passou a registrar somente o motivo de baixa cardinalidade da rejeição, sem headers, assinatura, corpo ou identificadores externos. O [PR 38](https://github.com/oficina-soat/oficina-billing-service/pull/38), o [run 29699146767](https://github.com/oficina-soat/oficina-billing-service/actions/runs/29699146767) e a [release `v1.10.2`](https://github.com/oficina-soat/oficina-billing-service/releases/tag/v1.10.2) concluíram Quality Gate, publicação e deploy; o pod ficou pronto com a imagem `1.10.2`.

A aplicação canônica dos Secrets Kubernetes também foi endurecida para usar Server-Side Apply e remover a annotation legada `kubectl.kubernetes.io/last-applied-configuration`, que não deve armazenar material reversível de credenciais. O [PR 59](https://github.com/oficina-soat/oficina-infra/pull/59) introduziu a proteção, o [PR 60](https://github.com/oficina-soat/oficina-infra/pull/60) assumiu explicitamente o ownership dos campos anteriormente gerenciados pelo Client-Side Apply e o [PR 61](https://github.com/oficina-soat/oficina-infra/pull/61) aplicou o mesmo padrão à licença do New Relic. O [run 29700717753](https://github.com/oficina-soat/oficina-infra/actions/runs/29700717753) concluiu validação e deploy; a varredura de todos os namespaces encontrou zero Secret com essa annotation, todos os workloads da oficina ficaram prontos e os três pods do collector permaneceram `Running` e prontos.

A policy `Oficina SOAT - Alertas Minimos Lab` já possuía a condição ativa **Pagamento indisponível**, ID `63810244`, conforme a [evidência dos alertas mínimos](../observability/new-relic-alerts-lab-evidence.md). Naquela etapa, a releitura remota não foi possível porque ainda não havia New Relic User API Key no ambiente local; a verificação foi concluída posteriormente neste documento.

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

Na janela daquela retomada, os logs correlacionados do OS e do Billing não continham padrões de token, assinatura, QR Code, código ou URL PIX. As métricas do Billing continham zero identificador da jornada e zero padrão sensível. A releitura dos traces e da policy **Pagamento indisponível** ainda estava limitada pela ausência de New Relic User API Key e foi concluída na jornada adicional registrada abaixo.

Como prevenção, o deploy canônico da infraestrutura passou a rejeitar credenciais `TEST-*` no modo `orders` antes de acessar o cluster e documenta o caminho correto para obter a credencial `APP_USR`. Isso evita que uma configuração conhecida como incompatível volte a ser aplicada silenciosamente.

### Continuação após a correção da credencial

Uma cópia do evento `ordemDeServicoFinalizada` desta jornada foi reenviada da DLQ para a fila de origem do Billing, sem remover a mensagem de auditoria. O processamento criou a order e publicou `pagamentoSolicitado`. A consulta pública apresentou o pagamento `CRIADO`, a ação canônica `ATUALIZAR_STATUS` e as instruções de copia e cola e QR Code, sem expor o conteúdo na evidência.

A reconciliação autenticada, com `Idempotency-Key`, consultou a order no Mercado Pago e retornou `200` com o pagamento `CONFIRMADO`. O evento `pagamentoConfirmado` convergiu no OS, que expôs a capability canônica `ENTREGAR`; a transição autenticada retornou `200` e deixou a OS em `ENTREGUE`.

Depois da confirmação, foram submetidos concorrentemente pela URL pública:

- dois webhooks assinados `order.updated`, ambos com `200`;
- um webhook assinado semanticamente anterior `order.created`, com `200`;
- uma reconciliação autenticada com chave distinta, com `200`;
- duas novas cópias do mesmo evento terminal de OS para o Billing.

As contagens finais confirmaram convergência sem duplicação nem regressão:

```text
budgets|1|APROVADO
payments|1|external_refs=1|CONFIRMADO|ORDER
outbox|orcamentoAprovado|1|PUBLISHED
outbox|orcamentoGerado|1|PUBLISHED
outbox|pagamentoConfirmado|1|PUBLISHED
outbox|pagamentoSolicitado|1|PUBLISHED
terminal_consumed|ordemDeServicoFinalizada|1
os|ENTREGUE
delivery_history|1
```

A auditoria da janela final encontrou 21 registros correlacionados no OS, 16 no Billing e 20 no Execution, todos sem ocorrência genérica ou exata de access token, webhook secret, assinatura, identificador externo, CPF, e-mail, código ou URL PIX. As métricas continham 153 séries `payment_provider_*`, zero identificador da jornada e zero padrão sensível. Os collectors OpenTelemetry não registraram erro de exportação nem padrão sensível.

## Webhook real após a rotação do secret

Uma jornada nova e isolada foi executada exclusivamente pelas APIs públicas, sem reutilizar pagamento ou order anterior e sem chamar reconciliação manual:

| Marco | Resultado |
|---|---|
| Correlação | `payment-orders-real-webhook-20260719T170650Z` |
| Ordem de Serviço | `c9f49dff-6cf0-4609-8ce4-0db03a329bf6`, finalizada após diagnóstico, orçamento e reparo. |
| Execução | `7cc83db8-0e0c-4123-8c9a-1e1394a66ec5`, em `REPARO_CONCLUIDO`. |
| Orçamento | `c063b380-4a1d-3631-af0f-ffb14ac70d45`, aprovado, no valor de `R$ 10,00`. |
| Pagamento | `7c388135-75df-334d-a5f0-97ce83f2d646`, método PIX, persistido como `CRIADO`. |
| Mercado Pago | A consulta autenticada somente leitura retornou a order como `processed/accredited`, com a transação `processed` e `external_reference` correspondente ao `pagamentoId`. |
| Outbox correlacionada | Uma ocorrência de `orcamentoGerado`, uma de `orcamentoAprovado` e uma de `pagamentoSolicitado`; nenhuma `pagamentoConfirmado`. |

Entre `17:09:01Z` e `17:09:07Z`, o API Gateway recebeu quatro chamadas reais na rota `POST /api/v1/integracoes/mercado-pago/webhooks`, originadas de quatro endereços do provedor. Todas chegaram ao Billing e todas receberam `401`. Isso confirma URL, evento **Order (Mercado Pago)** e entrega pelo provedor; o pagamento local permaneceu `CRIADO` porque nenhuma notificação passou pela validação HMAC.

A [documentação oficial de notificações de Orders](https://www.mercadopago.com.br/developers/pt/docs/checkout-api-orders/notifications) exemplifica `x-signature` com `ts` de 13 dígitos e constrói o manifesto com o valor recebido sem alteração. O Billing `1.9.0` também usa o valor bruto no manifesto, mas compara esse mesmo número diretamente com `Instant.getEpochSecond()` para aplicar a tolerância. Dois probes sem order válida, assinados com o secret de runtime e sem efeito de negócio, isolaram a divergência:

```text
timestamp em segundos      -> 404, assinatura aceita e order inexistente
timestamp em milissegundos -> 401, assinatura rejeitada antes da consulta
```

Portanto, a rotação do secret foi implantada e o painel está enviando notificações, mas o Billing `1.9.0` rejeita o webhook real de Orders por incompatibilidade de unidade temporal.

### Correção e diagnóstico no Billing `1.10.1` e `1.10.2`

O commit `5cb92e9` normaliza para segundos somente o valor usado no cálculo da idade quando o epoch possui 13 dígitos. O `ts` original continua no manifesto HMAC e a comparação constante do hash não foi alterada; notificações legadas de 10 dígitos permanecem compatíveis. Foram adicionados testes de aceitação dentro da janela e rejeição fora da janela para milissegundos.

A validação da candidata passou com 199 testes, PostgreSQL 16 real, todas as 10 migrations, constraints de arquitetura e JaCoCo de 93,84% de linhas e 79,89% de branches. O relatório XML foi gerado e o Quality Gate remoto aprovou a publicação.

Depois do deploy, probes controlados com o secret efetivamente projetado aceitaram tanto `ts` de 10 como de 13 dígitos e avançaram até o `404` esperado de uma order inexistente. Isso eliminou a unidade temporal como causa residual. O commit `9b740dc`, publicado em `1.10.2`, adicionou a classificação sanitizada das rejeições. Um callback real do Mercado Pago recebido em `19:16:12Z` foi registrado como `webhookValidationReason=hash_mismatch`; a mesma ocorrência foi relida no New Relic com `service.version=1.10.2`.

O diagnóstico oficial somente leitura de notificações do Mercado Pago encontrou duas notificações de Orders, ambas com retorno `401` e nenhuma entrega bem-sucedida na janela consultada. A implementação oficial de validação do [SDK Node.js do Mercado Pago](https://github.com/mercadopago/sdk-nodejs/blob/03f66609884f724dfa718db3afba729462569a4c/src/utils/webhook/index.ts) usa o mesmo manifesto formado por `id`, `request-id` e `ts` bruto. O algoritmo, a unidade temporal e a projeção local foram validados, mas a aceitação das simulações e a rejeição dos callbacks reais exigem comparar de forma instrumentada os componentes recebidos e o manifesto canônico antes de atribuir a causa a credenciais ou configuração externa.

## Releitura remota no New Relic

A New Relic User API Key permitiu concluir as verificações antes pendentes:

- a correlação nova possui 62 logs no Billing, 28 no OS e 21 no Execution, totalizando 111 registros e 65 `traceId` distintos;
- uma amostra de 20 desses traces encontrou spans nos três serviços: 7 no Billing, 8 no OS e 10 no Execution;
- a janela do webhook registrou os `401` reais e os probes controlados sem incluir headers ou payloads sensíveis;
- a versão `1.10.2` registrou uma única classificação `hash_mismatch` para o callback real, sem persistir assinatura, secret ou payload;
- não houve atributo com nome relacionado a secret, assinatura, autorização, access token, QR Code, URL de pagamento ou código copia e cola nos logs e spans correlacionados;
- não houve ocorrência dos padrões sensíveis conhecidos nas mensagens de log ou nos nomes de spans;
- a policy **Oficina SOAT - Alertas Minimos Lab** mantém nove condições, e **Pagamento indisponível**, ID `63810244`, está ativa, com prioridade crítica e sem incidente aberto na releitura.

## Pendências para concluir a tarefa

A configuração do evento Orders, a observabilidade remota, a correção temporal e a rotação possível do secret deixaram de ser pendências. Para concluir `[D-PAYMENT-CONTINUITY-TEST-REM-001]` ainda é necessário:

1. executar o item de instrumentação temporária `[D-PAYMENT-CONTINUITY-WEBHOOK-DIAG-001]` do [roadmap](../../ROADMAP.md), comparando somente metadados não secretos do callback real e da simulação;
2. corrigir a causa comprovada, remover a instrumentação temporária — ou reduzi-la a métricas operacionais seguras — e repetir uma jornada `APRO` sem reconciliação manual;
3. comprovar webhook real `200` → `pagamentoConfirmado` único → capability **Registrar entrega** → `ENTREGUE`, incluindo duplicidade, ordem invertida, concorrência e sanitização.

Até o diagnóstico e a nova homologação, não é correto marcar a tarefa como concluída. A jornada permaneceu em estado seguro: o provedor é a fonte de verdade, o Billing não fabricou confirmação e nenhuma Outbox terminal foi publicada sem uma notificação autenticada ou reconciliação explícita.
