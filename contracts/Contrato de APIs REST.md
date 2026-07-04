# Contrato de APIs REST

## Objetivo

Definir os contratos REST fundamentais da plataforma distribuída da oficina mecânica.

Este documento estabelece as interfaces síncronas entre os microsserviços da Fase 4 e serve como referência para implementação, documentação OpenAPI, testes de integração e comunicação entre equipes.

Os contratos aqui definidos devem ser considerados estáveis e versionados.

---

## Convenções Gerais

### Versionamento

Todas as APIs deverão utilizar versionamento por URI:

```text
/api/v1
```

### Formato

- Content-Type: `application/json`
- Charset: `UTF-8`

### Identificadores

Todos os identificadores devem utilizar UUID.

Exemplo:

```json
{
  "id": "d290f1ee-6c54-4b01-90e6-d701748f0851"
}
```

### Datas

Todas as datas devem utilizar ISO-8601.

Exemplo:

```json
{
  "criadoEm": "2026-06-18T10:30:00Z"
}
```

### Autenticação

Todas as APIs protegidas devem utilizar:

```text
Authorization: Bearer <jwt>
```

### Exposição pública

As rotas REST de negócio dos três microsserviços devem ser expostas publicamente pelo API Gateway conforme [Rotas públicas do API Gateway](../docs/api-gateway-public-routes.md).

Nesse contrato, exposição pública significa rota acessível pela entrada pública da plataforma. A decisão não remove autenticação, autorização, erros padronizados, idempotência ou propagação de `correlationId`.

### Idempotência

Operações de criação que possam ser repetidas por falhas de rede devem aceitar:

```text
X-Idempotency-Key
```

O comportamento esperado para retries, duplicidade, timeout, Saga e consumidores de eventos é definido no [Contrato de Idempotência](idempotency.md).

### Erros

Todas as respostas de erro devem seguir o contrato padronizado em [Contrato de Erros REST](error-model.md), incluindo `correlationId` para rastreabilidade entre HTTP, eventos, logs e traces.

---

# Microsserviço: oficina-os-service

## Responsabilidades

- Clientes
- Veículos
- Ordens de serviço
- Estados da OS
- Histórico da OS

---

## Clientes

### Criar cliente

```http
POST /api/v1/clientes
```

### Consultar clientes

```http
GET /api/v1/clientes
```

### Consultar cliente

```http
GET /api/v1/clientes/{clienteId}
```

### Atualizar cliente

```http
PUT /api/v1/clientes/{clienteId}
```

---

## Veículos

### Criar veículo para cliente

```http
POST /api/v1/clientes/{clienteId}/veiculos
```

### Consultar veículos do cliente

```http
GET /api/v1/clientes/{clienteId}/veiculos
```

### Consultar veículo

```http
GET /api/v1/veiculos/{veiculoId}
```

### Atualizar veículo

```http
PUT /api/v1/veiculos/{veiculoId}
```

---

## Ordens de Serviço

### Abrir OS

```http
POST /api/v1/ordens-servico
```

Exemplo:

```json
{
  "clienteId": "uuid",
  "veiculoId": "uuid",
  "descricaoProblema": "Veículo não liga"
}
```

### Consultar OS

```http
GET /api/v1/ordens-servico
```

### Consultar OS por id

```http
GET /api/v1/ordens-servico/{ordemServicoId}
```

### Consultar histórico

```http
GET /api/v1/ordens-servico/{ordemServicoId}/historico
```

### Alterar estado

```http
PATCH /api/v1/ordens-servico/{ordemServicoId}/estado
```

### Cancelar OS

```http
POST /api/v1/ordens-servico/{ordemServicoId}/cancelamento
```

---

# Microsserviço: oficina-billing-service

## Responsabilidades

- Orçamentos
- Aprovações
- Recusas
- Pagamentos
- Integração Mercado Pago

---

## Orçamentos

### Gerar orçamento

```http
POST /api/v1/orcamentos
```

Solicita a geração de um orçamento para uma Ordem de Serviço já existente.

O `oficina-billing-service` não deve receber a lista completa de itens no payload. Os itens de peças e serviços devem ser obtidos a partir da Ordem de Serviço, por consulta síncrona ao `oficina-os-service` ou por projeção local alimentada por eventos.

Exemplo:

```json
{
  "ordemServicoId": "uuid"
}
```

Resposta esperada:

```json
{
  "orcamentoId": "uuid",
  "ordemServicoId": "uuid",
  "itens": [
    {
      "tipo": "PECA",
      "itemId": "uuid",
      "referenciaCatalogoId": "uuid",
      "nome": "Volante",
      "quantidade": 2.000,
      "valorUnitario": 50.00,
      "valorTotal": 100.00
    },
    {
      "tipo": "SERVICO",
      "itemId": "uuid",
      "referenciaCatalogoId": "uuid",
      "nome": "Troca de óleo",
      "quantidade": 1.000,
      "valorUnitario": 250.00,
      "valorTotal": 250.00
    }
  ],
  "valorTotal": 350.00,
  "status": "GERADO"
}
```

Os itens do orçamento são snapshots financeiros calculados e persistidos pelo `oficina-billing-service` a partir dos itens da Ordem de Serviço. Eles devem preservar a composição usada para aprovação e pagamento, sem criar ownership do catálogo técnico no Billing.

### Consultar orçamento

```http
GET /api/v1/orcamentos/{orcamentoId}
```

### Consultar orçamento da OS

```http
GET /api/v1/ordens-servico/{ordemServicoId}/orcamentos
```

### Aprovar orçamento

```http
POST /api/v1/orcamentos/{orcamentoId}/aprovacao
```

### Recusar orçamento

```http
POST /api/v1/orcamentos/{orcamentoId}/recusa
```

---

## Pagamentos

### Registrar pagamento

```http
POST /api/v1/pagamentos
```

Quando a integração Mercado Pago estiver habilitada no `oficina-billing-service`, esta operação solicita pagamento PIX no provedor financeiro externo. Falhas de comunicação com o provedor devem retornar `502 Bad Gateway`; configuração obrigatória ausente ou método sem suporte na integração direta deve retornar `503 Service Unavailable`, preservando o [Contrato de Erros REST](error-model.md).

A referência externa oficial para a integração é a [Referência API Mercado Pago](https://www.mercadopago.com.br/developers/pt/reference), usando o recurso de criação de pagamento `POST /v1/payments` quando a integração direta estiver habilitada.

### Consultar pagamento

```http
GET /api/v1/pagamentos/{pagamentoId}
```

### Consultar pagamentos da OS

```http
GET /api/v1/ordens-servico/{ordemServicoId}/pagamentos
```

### Confirmar pagamento

```http
POST /api/v1/pagamentos/{pagamentoId}/confirmacao
```

### Recusar pagamento

```http
POST /api/v1/pagamentos/{pagamentoId}/recusa
```

### Cancelar pagamento

```http
POST /api/v1/pagamentos/{pagamentoId}/cancelamento
```

---

# Microsserviço: oficina-execution-service

## Responsabilidades

- Catálogo de serviços
- Catálogo de peças
- Estoque
- Diagnóstico
- Execução
- Reparo

---

## Serviços

### Criar serviço

```http
POST /api/v1/servicos
```

### Consultar serviços

```http
GET /api/v1/servicos
```

### Consultar serviço

```http
GET /api/v1/servicos/{servicoId}
```

### Atualizar serviço

```http
PUT /api/v1/servicos/{servicoId}
```

---

## Peças

### Criar peça

```http
POST /api/v1/pecas
```

### Consultar peças

```http
GET /api/v1/pecas
```

### Consultar peça

```http
GET /api/v1/pecas/{pecaId}
```

### Atualizar peça

```http
PUT /api/v1/pecas/{pecaId}
```

---

## Estoque

### Consultar saldo

```http
GET /api/v1/estoques/pecas/{pecaId}/saldo
```

### Consultar movimentações

```http
GET /api/v1/estoques/movimentos
```

### Registrar entrada

```http
POST /api/v1/estoques/movimentos/entrada
```

### Reservar estoque

```http
POST /api/v1/estoques/movimentos/reserva
```

### Consumir estoque

```http
POST /api/v1/estoques/movimentos/consumo
```

### Estornar estoque

```http
POST /api/v1/estoques/movimentos/estorno
```

---

## Execução

### Criar execução

```http
POST /api/v1/execucoes
```

### Consultar execuções

```http
GET /api/v1/execucoes
```

### Consultar fila de execução

```http
GET /api/v1/execucoes/fila
```

A fila retorna execuções pendentes de ação operacional, ordenadas por prioridade crescente e data de criação. Quanto menor o valor de `prioridade`, mais urgente é a execução.

Por padrão, a fila inclui execuções em `CRIADA`, aguardando início de diagnóstico, e `DIAGNOSTICO_CONCLUIDO`, aguardando início de reparo. O consumidor pode filtrar por `status`.

### Consultar execução

```http
GET /api/v1/execucoes/{execucaoId}
```

### Consultar execução da OS

```http
GET /api/v1/ordens-servico/{ordemServicoId}/execucao
```

---

## Diagnóstico

### Iniciar diagnóstico

```http
POST /api/v1/execucoes/{execucaoId}/diagnostico/inicio
```

### Concluir diagnóstico

```http
POST /api/v1/execucoes/{execucaoId}/diagnostico/conclusao
```

---

## Reparo

### Iniciar reparo

```http
POST /api/v1/execucoes/{execucaoId}/reparo/inicio
```

### Concluir reparo

```http
POST /api/v1/execucoes/{execucaoId}/reparo/conclusao
```

### Cancelar execução

```http
POST /api/v1/execucoes/{execucaoId}/cancelamento
```

---

# Diretrizes de Integração

## Comunicação síncrona

APIs REST devem ser utilizadas somente para:

- consultas necessárias para processamento imediato;
- validações que exigem resposta imediata;
- operações iniciadas diretamente pelo usuário.

## Comunicação assíncrona

Mudanças de estado relevantes devem gerar eventos de domínio publicados por mensageria.

Os eventos são definidos no [Contrato de Eventos de Domínio](Contrato%20de%20Eventos%20de%20Domínio.md).

## Compatibilidade

Mudanças incompatíveis devem resultar em nova versão da API.

Exemplo:

```text
/api/v2
```

Mudanças retrocompatíveis podem ser realizadas dentro da mesma versão.

---

## Referências

- ADR-010 — Separação dos Microsserviços
- Contrato de Estados da OS
- Contrato de Eventos de Domínio
- Contrato de Mensageria
