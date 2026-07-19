# Plano de migração do Mercado Pago Payments para Orders

## Objetivo

Migrar a criação e a reconciliação de cobranças PIX do `oficina-billing-service` da API legada `/v1/payments` para a API `/v1/orders`, preservando os contratos públicos da plataforma, a idempotência, a compatibilidade com cobranças legadas e a segurança do webhook. A migração deve anteceder a retomada de `[D-PAYMENT-CONTINUITY-TEST-REM-001]`, para permitir que o sandbox execute o cenário oficial `APRO` e conclua pagamento, confirmação, capability **Registrar entrega** e entrega da Ordem de Serviço.

Este plano complementa a [continuidade do pagamento e entrega pela UI](payment-checkout-continuity.md) e passa a orientar a próxima sequência aberta no [roadmap](../../ROADMAP.md).

## Estado atual

O Billing `1.8.0` cria cobranças em `POST /v1/payments`, persiste o ID numérico do payment em `transacaoExternaId` e reconcilia por `GET /v1/payments/{id}`. O webhook aceita somente `type=payment`. Essa integração apresentou corretamente o PIX, mas a cobrança sandbox permaneceu pendente na [homologação parcial](../delivery/payment-checkout-continuity-lab-evidence.md).

A documentação atual do Mercado Pago define para Orders:

- criação PIX em `POST /v1/orders`, modo `automatic`, com `X-Idempotency-Key`, uma transação `pix` e `external_reference`;
- consulta da fonte financeira em `GET /v1/orders/{id}`;
- webhook com evento **Order (Mercado Pago)**, `type=order`, ação `order.*` e `data.id` contendo o ID da order;
- cenário sandbox `payer.first_name=APRO`, que começa em `action_required/waiting_transfer` e depois é aprovado automaticamente.

Referências oficiais:

- [Integração PIX via Orders](https://www.mercadopago.com.br/developers/pt/docs/checkout-api-orders/payment-integration/pix)
- [Criar order](https://www.mercadopago.com.br/developers/pt/reference/online-payments/checkout-api/create-order/post)
- [Obter order por ID](https://www.mercadopago.com.br/developers/pt/reference/online-payments/checkout-api/get-order/get)
- [Notificações da API Orders](https://www.mercadopago.com.br/developers/pt/docs/checkout-api-orders/notifications)
- [Teste PIX com APRO](https://www.mercadopago.com.br/developers/pt/docs/checkout-api-orders/integration-test/pix)
- [Status da order](https://www.mercadopago.com.br/developers/pt/docs/checkout-api-orders/payment-management/status/order-status)

## Decisões da migração

| Tema | Decisão |
|---|---|
| Ownership | O `oficina-billing-service` continua sendo o único componente que chama o Mercado Pago e interpreta estados financeiros. |
| Criação | Usar `POST /v1/orders` com `type=online`, `processing_mode=automatic` e exatamente uma transação PIX. |
| Identidade | Manter `pagamentoId` como `external_reference` e `X-Idempotency-Key`, preservando a identidade determinística já usada contra concorrência. |
| Referência externa pública | `transacaoExternaId` passa a armazenar o ID da order para novas cobranças, sem renomear ou quebrar o contrato REST. |
| Compatibilidade | Persistir internamente o tipo da referência do provedor, `PAYMENT` ou `ORDER`; registros Mercado Pago existentes são migrados para `PAYMENT` e novas cobranças usam `ORDER`. Esse campo não deve ser exposto em REST ou eventos. |
| Reconciliação | Consultar `/v1/orders/{id}` para `ORDER` e manter `/v1/payments/{id}` somente para registros legados `PAYMENT`. Não inferir o recurso pelo formato do ID. |
| Rollback operacional | Introduzir modo explícito de criação `orders`/`payments`; o runtime alvo usa `orders`, enquanto `payments` permanece temporariamente disponível para rollback sem impedir a consulta de orders já criadas. |
| Sandbox | Usar `payer.email=test_user_br@testuser.com` e a configuração opcional de `payer.first_name=APRO`; o startup deve rejeitar `APRO` fora de `lab` ou `test`. |
| Produção | Omitir o marcador `APRO`; nenhuma regra de aprovação simulada pode ser derivada do Access Token ou habilitada implicitamente. |
| Webhook | Preservar a rota pública existente e a validação HMAC, incluindo o `x-request-id` original; aceitar `type=order` e consultar a order antes de alterar o domínio. |
| Resposta do webhook | Retornar `200` após processamento idempotente, respeitando orçamento inferior aos 22 segundos informados pelo provedor. Falhas transitórias continuam não reconhecidas para permitir retry. |
| UI | Manter `instrucoesPix`, `acoesPermitidas` e a ação **Atualizar situação**; não chamar Orders diretamente no frontend. |
| Versão | Publicar a mudança como Billing `1.9.0`, pois altera de forma compatível a integração externa sem quebrar a API pública. |

Os nomes propostos para configuração são `OFICINA_MERCADO_PAGO_API_MODE=orders` e `OFICINA_MERCADO_PAGO_PAYER_FIRST_NAME=APRO` no `lab`. A primeira etapa de contrato deve ratificar esses nomes em conjunto com os artefatos de runtime antes da implementação.

## Contrato de tradução

### Request de criação

O adapter deve produzir conceitualmente:

```json
{
  "type": "online",
  "processing_mode": "automatic",
  "external_reference": "<pagamentoId>",
  "total_amount": "<valor>",
  "payer": {
    "email": "<email configurado; test_user_br@testuser.com no sandbox APRO>",
    "first_name": "<opcional e exclusivo do sandbox>"
  },
  "transactions": {
    "payments": [
      {
        "amount": "<valor>",
        "payment_method": {
          "id": "pix",
          "type": "bank_transfer"
        }
      }
    ]
  }
}
```

O Access Token, o código PIX, o QR Code, o `ticket_url` e a assinatura nunca podem aparecer em logs, traces, métricas ou evidências.

### Response e estados

Antes de aplicar qualquer transição, o adapter deve validar ID da order, `external_reference=pagamentoId`, valor total e uma única transação PIX coerente. A tradução canônica será:

| Orders `status/status_detail` | Estado local | Efeito |
|---|---|---|
| `created/*`, `processing/*`, `action_required/waiting_payment` ou `action_required/waiting_transfer` | `CRIADO` | Preservar `ATUALIZAR_STATUS` e instruções PIX. |
| `processed/accredited` | `CONFIRMADO` | Persistir condicionalmente e publicar uma única Outbox `pagamentoConfirmado`. |
| `failed/*`, `canceled/*`, `expired/*`, `refunded/*` ou `charged_back/*` | `RECUSADO` | Normalizar como desfecho financeiro negativo e publicar uma única Outbox `pagamentoRecusado`. |
| combinação ausente, contraditória ou desconhecida | sem transição | Retornar falha de dependência sanitizada e preservar o último estado válido. |

As instruções devem ser extraídas de `transactions.payments[0].payment_method.ticket_url`, `qr_code` e `qr_code_base64`. `expiraEm` continua opcional enquanto Orders não fornecer um instante absoluto contratado; não deve ser inventado a partir do relógio local sem contrato adicional.

### Webhook

O contrato deve aceitar `type=order`, `data.id=<orderId>` e ações com prefixo `order.`, sem confiar na ação ou no status do payload. O Billing valida HMAC, localiza o pagamento por referência `ORDER`, consulta `GET /v1/orders/{id}` e usa a mesma atualização condicional da reconciliação autenticada.

Durante a janela de compatibilidade, callbacks `type=payment` de cobranças legadas continuam aceitos e consultam `/v1/payments/{id}`. Duplicidade, ordem invertida e concorrência entre os dois callbacks e **Atualizar situação** não podem republicar evento terminal nem regredir estado.

## Ordem de execução

### 1. `[D-PAYMENT-ORDERS-CONTRACT-001]` — contratos e compatibilidade

- atualizar o [Contrato de APIs REST](../../contracts/Contrato%20de%20APIs%20REST.md), a [OpenAPI do Billing](../../contracts/openapi/oficina-billing-service.yaml) e o [Contrato de Idempotência](../../contracts/idempotency.md);
- contratar `type=order`, resposta `200`, actions `order.*`, consulta de Orders e janela temporária de compatibilidade com Payments;
- ratificar os nomes de configuração, a semântica de `transacaoExternaId` e o campo interno que distingue `PAYMENT` de `ORDER`;
- manter a API pública da UI aditiva e compatível.

Critério de pronto: contratos coerentes entre si, exemplos válidos, OpenAPI parseável e nenhuma ambiguidade sobre identidade, status, webhook ou rollback.

### 2. `[D-PAYMENT-ORDERS-BILLING-IMPL-001]` — Billing `1.9.0`

- criar clients e DTOs específicos de Orders sem reutilizar o shape de Payments;
- implementar criação automática, parsing aninhado, validação de vínculo e mapeamento de estados;
- adicionar migration PostgreSQL para o tipo da referência externa e backfill dos registros legados;
- rotear consulta e webhook pelo tipo persistido, mantendo Payments somente para compatibilidade;
- restringir `APRO` a `lab`/`test`, preservar métricas de baixa cardinalidade e incrementar o `project.version` para `1.9.0`.

Critério de pronto: Orders é o modo de criação alvo, pagamentos legados continuam consultáveis e nenhum dado sensível aparece em telemetria ou erros.

### 3. `[D-PAYMENT-ORDERS-INFRA-IMPL-001]` — runtime e operação

- projetar as configurações ratificadas no deployment do Billing sem criar novo secret para valores não sensíveis;
- configurar o `lab` para Orders e para o cenário `APRO`, mantendo produção sem marcador de teste;
- atualizar runbook para o evento **Order (Mercado Pago)** e preservar o `x-request-id` na borda;
- documentar rollout, rollback para criação Payments e período de convivência dos dois tipos de referência.

Critério de pronto: manifests, Terraform, scripts e documentação concordam nos nomes; validações locais passam sem disparar GitHub Actions.

### 4. `[D-PAYMENT-ORDERS-TEST-001]` — testes locais integrados

- cobrir requests, responses, status, vínculo, idempotência, timeout, `4xx`, `5xx`, resposta malformada e configuração proibida de `APRO`;
- cobrir migration/backfill e reconciliação de registros `PAYMENT` e `ORDER`;
- cobrir webhook `order.*`, assinatura, `200`, duplicidade, ordem invertida e concorrência com reconciliação;
- executar `clean verify` com PostgreSQL real e JaCoCo, além das validações de contrato, infraestrutura e UI proporcionais ao diff;
- executar SonarCloud somente se houver credencial e contexto autorizados; não disparar workflows sem pedido explícito.

Critério de pronto: Billing `1.9.0` publicável localmente, cobertura e Quality Gate local equivalente aprovados e nenhuma regressão nos contratos consumidos pela UI.

### 5. `[D-PAYMENT-CONTINUITY-TEST-REM-001]` — homologação completa

Somente depois das quatro etapas anteriores, retomar a homologação remota já aberta. Ela deve criar uma nova OS, concluir o reparo, gerar uma única order PIX `APRO`, observar `action_required` seguido de `processed/accredited`, receber webhook real ou reconciliar, publicar um único `pagamentoConfirmado`, liberar **Registrar entrega** e terminar em `ENTREGUE`.

## Validação e evidências obrigatórias

- uma solicitação `POST /v1/orders` por pagamento, mesmo com gatilhos concorrentes;
- `external_reference`, `X-Idempotency-Key`, order persistida e pagamento interno vinculados sem inferência por formato;
- uma linha de pagamento, uma Outbox `pagamentoSolicitado`, uma Outbox terminal e um efeito de negócio;
- callbacks duplicados, fora de ordem e concorrentes reconhecidos sem regressão ou republicação;
- pagamento legado `PAYMENT` ainda reconciliável durante a compatibilidade;
- UI apresentando PIX pendente, depois confirmação e **Registrar entrega** somente após a capability canônica;
- ausência de credenciais, assinatura e conteúdo PIX em logs, traces, métricas, analytics e evidências;
- documentação do painel Mercado Pago com evento **Order (Mercado Pago)**, sem registrar o secret;
- nenhuma execução de GitHub Actions sem autorização explícita do usuário.

## Rollback e encerramento da compatibilidade

Se Orders falhar antes de criar uma cobrança, o modo de criação pode voltar temporariamente para `payments`. Se uma order já foi criada, ela deve continuar sendo reconciliada pelo client de Orders; rollback de versão para `1.8.0` não é seguro porque essa versão desconhece a referência `ORDER`.

A remoção do client Payments e do campo de compatibilidade exige tarefa posterior, inventário sem pagamentos legados pendentes e evidência de que nenhuma notificação `type=payment` ainda precisa ser processada. Essa remoção não faz parte desta migração.
