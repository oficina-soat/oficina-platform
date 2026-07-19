# Continuidade do pagamento e entrega pela UI

## Objetivo

Explicar por que a jornada operacional não avança do reparo concluído até a entrega usando apenas a UI e decompor as mudanças necessárias para completar o pagamento PIX pelo Mercado Pago sem transferir regra financeira ao navegador. Este diagnóstico orienta a trilha de continuidade do pagamento no [roadmap](../../ROADMAP.md) e preserva o ownership definido na [Matriz de Ownership por Microsserviço](service-ownership.md).

## Diagnóstico do estado atual

O botão **Concluir reparo** já inicia o fluxo financeiro de forma assíncrona. O `oficina-execution-service` publica `execucaoFinalizada`, o `oficina-os-service` publica `ordemDeServicoFinalizada` e o `oficina-billing-service` converge os dois gatilhos para um único pagamento. Quando a integração está habilitada, o Billing chama `POST /v1/payments` do Mercado Pago uma única vez e persiste o identificador externo.

Portanto, não falta um botão para criar novamente a cobrança. Repetir essa chamada pela UI quebraria o ownership financeiro e elevaria o risco de cobrança duplicada.

A lacuna está depois da criação:

- o adapter do Mercado Pago preserva apenas identificador e status, descartando `qr_code`, `qr_code_base64` e `ticket_url` retornados para o PIX;
- o contrato `Pagamento` não expõe instruções de pagamento nem vencimento;
- a tela **Faturamento** lista pagamentos, mas descarta também `acoesPermitidas` e não oferece ação financeira;
- não existe webhook do Mercado Pago contratado, implementado ou exposto na infraestrutura;
- o endpoint atual `POST /pagamentos/{pagamentoId}/confirmacao` altera o estado local com os dados recebidos e não consulta o Mercado Pago. Exibi-lo como confirmação de uma cobrança integrada permitiria declarar sucesso sem prova do provedor;
- sem confirmação, o OS Service não recebe `pagamentoConfirmado`, não libera `ENTREGAR` e a UI não apresenta **Registrar entrega**.

A documentação oficial do Mercado Pago confirma que o checkout PIX deve disponibilizar link, QR Code ou código copia e cola ao pagador e que mudanças de estado podem ser recebidas por webhook. A consulta autenticada `GET /v1/payments/{id}` fornece a fonte de reconciliação quando a notificação precisar de confirmação ou houver ação manual de atualização:

- [Pagamento PIX e dados para apresentação](https://www.mercadopago.com.br/developers/pt/docs/checkout-bricks/payment-brick/payment-submission/pix)
- [Notificações de pagamento por Webhook](https://www.mercadopago.com.br/developers/pt/docs/checkout-pro/payment-notifications)
- [Consulta de pagamento por identificador](https://www.mercadopago.com.br/developers/pt/reference/online-payments/checkout-pro/get-payment/get)

## Direção recomendada

A UI deve chamar somente o Billing. O Billing continua sendo o único componente que usa o Access Token do Mercado Pago e interpreta o estado financeiro.

O fluxo alvo recomendado é:

1. a conclusão do reparo solicita uma única cobrança, como já ocorre;
2. o Billing persiste uma projeção sanitizada das instruções PIX e a devolve no contrato autenticado;
3. a UI apresenta **Pagar com PIX**, código copia e cola, vencimento e estado, sem enviar esses dados para logs ou telemetria;
4. o Mercado Pago notifica o Billing por webhook HTTPS com assinatura validada;
5. o Billing consulta `GET /v1/payments/{id}` antes de aplicar a transição, sem confiar somente no payload da notificação;
6. como fallback operacional, **Atualizar situação** chama um endpoint do Billing que executa a mesma reconciliação server-to-server;
7. o Billing publica `pagamentoConfirmado` ou `pagamentoRecusado` de forma idempotente;
8. após `CONFIRMADO`, a UI orienta o operador a abrir a OS e usar **Registrar entrega**.

O endpoint de confirmação manual pode continuar existindo para métodos realmente manuais ou operação explicitamente autorizada, mas não deve ser oferecido como confirmação de pagamento Mercado Pago pendente. A ação apresentada para uma cobrança integrada deve ser **Atualizar situação**, e não **Confirmar sem validação**.

## Tarefas necessárias

### 1. Contratar checkout e reconciliação

- adicionar ao `Pagamento` uma projeção opcional de instruções PIX, incluindo código copia e cola, URL segura de pagamento e vencimento; avaliar se a imagem Base64 deve ser persistida ou gerada pela UI a partir do código;
- contratar webhook público do Mercado Pago, cabeçalhos de assinatura, respostas, idempotência e erro sem expor existência de pagamentos;
- contratar uma ação autenticada de reconciliação manual, por exemplo `POST /api/v1/pagamentos/{pagamentoId}/reconciliacao`;
- separar em `acoesPermitidas` a reconciliação com o provedor da confirmação manual e definir papéis autorizados;
- documentar quais dados PIX podem aparecer na resposta e proibir token, secret, código PIX e URL de pagamento em logs, traces e métricas.

### 2. Implementar no Billing

- mapear as instruções PIX retornadas pelo Mercado Pago e persistir somente os campos aprovados;
- implementar consulta de estado por `transacaoExternaId` e o mesmo mapeamento canônico já usado na criação;
- receber webhook, validar assinatura e tolerância temporal, consultar o pagamento no provedor e verificar vínculo por referência externa antes de atualizar o domínio;
- tornar webhook e reconciliação idempotentes, sem republicar evento nem regredir estado em notificação duplicada ou fora de ordem;
- impedir confirmação manual de cobrança integrada sem evidência válida do provedor;
- cobrir expiração, recusa, cancelamento, timeout, `404`, `5xx`, assinatura inválida e concorrência entre webhook e reconciliação manual.

### 3. Preparar infraestrutura

- expor somente a rota pública do webhook no API Gateway e manter as demais rotas financeiras autenticadas;
- armazenar o secret de assinatura no Secrets Manager e projetá-lo no pod sem registrá-lo;
- configurar URLs de teste e produção e o evento de pagamentos na aplicação Mercado Pago;
- adicionar limites, logs sanitizados, métricas, alarme de falha e runbook de reconciliação;
- preservar rollout e rollback independentes do Billing e da UI.

### 4. Completar a UI

- preservar `acoesPermitidas` no modelo de pagamento;
- apresentar instruções PIX de forma acessível, com ação de copiar, link externo seguro e indicação de vencimento;
- implementar **Atualizar situação** chamando o Billing com `Idempotency-Key`, sem chamada direta ao Mercado Pago;
- manter atualização manual do snapshot e mensagens claras para pagamento pendente, confirmado, recusado, cancelado, expirado ou temporariamente indisponível;
- após confirmação e convergência, oferecer navegação para o detalhe da OS, onde a capability canônica libera **Registrar entrega**;
- não inferir confirmação, capability ou estado da Saga no frontend.

### 5. Validar e homologar

- cobrir contrato, adapter, casos de uso, assinatura, idempotência, segurança, acessibilidade e estados visuais;
- executar cenário ponta a ponta reparo → cobrança única → instruções PIX → notificação ou reconciliação → `pagamentoConfirmado` → entrega;
- comprovar uma cobrança, um pagamento, uma Outbox e um efeito de negócio sob webhook duplicado e concorrência;
- validar ausência de secrets e dados PIX em logs, traces e métricas;
- implantar no `lab`, validar Quality Gates e registrar evidência com sandbox do Mercado Pago antes de concluir a trilha.

## Estado da implementação local

As etapas que não dependem do `lab` foram concluídas:

- os [contratos REST](../../contracts/Contrato%20de%20APIs%20REST.md), a [OpenAPI do Billing](../../contracts/openapi/oficina-billing-service.yaml) e o [contrato de idempotência](../../contracts/idempotency.md) incluem instruções PIX, reconciliação autenticada e webhook assinado;
- o Billing `1.8.0` persiste as instruções, consulta o provedor e converge webhook e atualização manual por transição condicional e Outbox determinística, sem permitir confirmação manual de cobrança integrada;
- a infraestrutura contrata somente o webhook como rota pública, projeta o secret no Billing e mantém a reconciliação protegida;
- a UI apresenta as instruções PIX, executa **Atualizar situação** e encaminha o operador ao detalhe da OS após a confirmação, preservando a capability canônica para **Registrar entrega**.

A [homologação da continuidade do pagamento no lab](../delivery/payment-checkout-continuity-lab-evidence.md) já comprovou implantação, Quality Gates, apresentação do PIX, assinatura pública, duplicidade, ordem, concorrência, unicidade e sanitização local. A tarefa permanece aberta no [roadmap](../../ROADMAP.md) para a notificação originada pelo painel do Mercado Pago, a aprovação real do pagamento no sandbox, a entrega e a releitura remota de traces e alertas.

## Relação com atualização da jornada

A [nova medição da jornada](journey-freshness-remeasurement.md) comprovou p95 inferior a `457 ms` entre comando e convergência canônica. A continuidade do pagamento não exige SSE ou WebSocket: a UI pode atualizar o snapshot sob ação explícita do operador, e o webhook resolve a comunicação provedor → Billing sem manter conexão com o navegador.
