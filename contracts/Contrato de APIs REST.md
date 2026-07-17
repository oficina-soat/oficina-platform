# Contrato de APIs REST

## Objetivo

Definir os contratos REST fundamentais da plataforma distribuída da oficina mecânica.

Este documento estabelece as interfaces síncronas entre os microsserviços e serve como referência para implementação, documentação OpenAPI, testes de integração e comunicação entre equipes.

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

As rotas REST de negócio dos três microsserviços devem ser expostas publicamente pelo API Gateway conforme [Rotas públicas do API Gateway](../docs/infrastructure/api-gateway-public-routes.md).

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

- Pessoas e usuários operacionais
- Clientes
- Veículos
- Ordens de serviço
- Estados da OS
- Histórico da OS

---

## Usuários operacionais

O `oficina-os-service` mantém o cadastro operacional agregado de Pessoa e Usuário. O usuário operacional é sempre uma pessoa física identificada por CPF, possui um ou mais papéis entre `administrativo`, `mecanico` e `recepcionista`, e usa um dos estados `ATIVO`, `INATIVO` ou `BLOQUEADO`.

Todas as operações desta seção exigem JWT válido com o papel `administrativo`. Um token válido sem esse papel deve receber `403 Forbidden` com `code=ACCESS_DENIED`, conforme o [Contrato de Erros REST](error-model.md).

O recurso não aceita nem devolve senha, hash, token de ativação ou qualquer outra credencial. Login, ativação de credencial, validação de senha e emissão de JWT continuam sob responsabilidade do `oficina-auth-lambda`, conforme a [ADR-003 - Serverless para Autenticação e Notificações](../adr/ADR-003%20-%20Serverless%20para%20Autenticação%20e%20Notificações.md).

As mutações bem-sucedidas publicam, pela Outbox transacional, os eventos [usuarioAdicionado](events/usuarioAdicionado.md), [usuarioAtualizado](events/usuarioAtualizado.md) e [usuarioExcluido](events/usuarioExcluido.md). O `oficina-auth-sync-lambda` projeta CPF, nome, status e papéis no store próprio de autenticação sem transportar credenciais e sem colocar uma chamada ao `oficina-os-service` no caminho de login.

### Criar usuário operacional

```http
POST /api/v1/usuarios
X-Idempotency-Key: <chave>
```

```json
{
  "nome": "Ana Silva",
  "documento": "84191404067",
  "status": "ATIVO",
  "papeis": ["mecanico"]
}
```

O campo `status` é opcional na criação e assume `ATIVO`. `nome`, `documento` e ao menos um papel são obrigatórios. Se o CPF já identificar uma Pessoa sem Usuário, a operação reutiliza essa Pessoa e atualiza seu nome canônico; se já existir Usuário para o CPF, retorna `409 Conflict` com `code=DUPLICATE_RESOURCE`.

### Consultar usuários operacionais

```http
GET /api/v1/usuarios?page=0&size=20
```

A resposta usa o envelope paginado canônico e inclui `usuarioId`, `pessoaId`, dados da Pessoa, status, papéis e timestamps.

### Consultar usuário operacional

```http
GET /api/v1/usuarios/{usuarioId}
```

### Atualizar usuário operacional

```http
PUT /api/v1/usuarios/{usuarioId}
```

`PUT` substitui integralmente nome, CPF, status e papéis. O CPF não pode pertencer a outra Pessoa; esse caso retorna `409 Conflict` com `code=DUPLICATE_RESOURCE`.

### Excluir usuário operacional

```http
DELETE /api/v1/usuarios/{usuarioId}
```

A exclusão é lógica e idempotente: altera o status para `INATIVO`, retorna `204 No Content` e preserva Pessoa e papéis para auditoria e eventual reativação por `PUT`. A primeira transição para `INATIVO` publica `usuarioExcluido`; repetições que não alteram o estado não publicam outro evento.

O contrato implementável completo, incluindo schemas, exemplos e códigos HTTP, está no [OpenAPI do oficina-os-service](openapi/oficina-os-service.yaml).

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

### Incluir serviço na OS

```http
POST /api/v1/ordens-servico/{ordemServicoId}/servicos
X-Idempotency-Key: <chave-unica>
```

O cliente envia somente `servicoId` e `quantidade`. O `oficina-os-service` consulta o catálogo do `oficina-execution-service` e persiste nome e valor como snapshot. A operação somente é oferecida e aceita em `EM_DIAGNOSTICO`.

### Incluir peça na OS

```http
POST /api/v1/ordens-servico/{ordemServicoId}/pecas
X-Idempotency-Key: <chave-unica>
```

O cliente envia somente `pecaId` e `quantidade`. Disponibilidade e movimentos de estoque permanecem sob autoridade do `oficina-execution-service`; a UI não infere reserva ou consumo.

### Alterar estado

```http
PATCH /api/v1/ordens-servico/{ordemServicoId}/estado
```

### Cancelar OS

```http
POST /api/v1/ordens-servico/{ordemServicoId}/cancelamento
```

---

# Componente serverless: oficina-auth-lambda

## Responsabilidades

- autenticar CPF e senha no store próprio;
- emitir JWT com os papéis sincronizados;
- gerar tokens de ativação de credencial para administradores;
- receber a senha inicial diretamente do usuário durante a ativação.

O `oficina-auth-lambda` não consulta o `oficina-os-service` no caminho de login e não acessa o database `oficina_os`. O componente recebe a projeção operacional exclusivamente pelo consumidor assíncrono `oficina-auth-sync-lambda`, que compartilha apenas o store de autenticação serverless.

Usuários `INATIVO`, `BLOQUEADO` ou sem senha ativada não podem autenticar. Tokens de ativação são aleatórios, de uso único, armazenados somente como hash e expiram após 24 horas por padrão. A validade pode ser configurada no runtime sem mudar o contrato.

### Solicitar ativação de credencial

```http
POST /auth/usuarios/{usuarioId}/ativacao
Authorization: Bearer <jwt-administrativo>
```

A operação exige o papel `administrativo`, localiza o usuário pelo UUID canônico do cadastro operacional e somente aceita usuários `ATIVO` ainda sem credencial ativada. A resposta `201 Created` devolve o token em texto claro uma única vez e seu `expiresAt`; apenas o hash é persistido. Solicitar um novo token invalida tokens anteriores ainda não utilizados.

O administrador deve entregar o token ao usuário por canal externo confiável. O token não deve ser enviado ao `oficina-os-service`, gravado em logs ou incluído em eventos.

### Concluir ativação de credencial

```http
POST /auth/ativacoes
```

```json
{
  "token": "<token-de-uso-unico>",
  "password": "uma-senha-com-pelo-menos-12-caracteres"
}
```

A operação é pública porque o token aleatório funciona como segredo de posse. O token deve possuir entropia mínima de 256 bits, e a senha deve ter entre 12 e 128 caracteres. Token inexistente, expirado, invalidado ou já utilizado recebe a mesma resposta genérica, sem revelar o estado do usuário. O sucesso retorna `204 No Content`, grava somente o hash BCrypt da senha e marca o token como utilizado na mesma transação.

O contrato implementável completo está no [OpenAPI do oficina-auth-lambda](openapi/oficina-auth-lambda.yaml).

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
  "status": "GERADO",
  "acoesPermitidas": ["APROVAR", "RECUSAR"]
}
```

Os itens do orçamento são snapshots financeiros calculados e persistidos pelo `oficina-billing-service` a partir dos itens da Ordem de Serviço. Eles devem preservar a composição usada para aprovação e pagamento, sem criar ownership do catálogo técnico no Billing.

Toda representação de orçamento inclui `acoesPermitidas`. A UI deve oferecer aprovação ou recusa somente quando a ação correspondente for devolvida pelo serviço; após uma decisão, a lista fica vazia.

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

### Links públicos de acompanhamento e decisão

O Billing Service preserva o fluxo de links de capacidade do sistema de referência. Estas rotas não exigem JWT; o parâmetro `actionToken` é a credencial restrita à ação, à Ordem de Serviço e ao orçamento.

```http
GET /api/v1/ordens-servico/{ordemServicoId}/acompanhar-link?actionToken={token}
GET /api/v1/ordens-servico/{ordemServicoId}/aprovar-link?actionToken={token}
POST /api/v1/ordens-servico/{ordemServicoId}/aprovar-link
GET /api/v1/ordens-servico/{ordemServicoId}/recusar-link?actionToken={token}
POST /api/v1/ordens-servico/{ordemServicoId}/recusar-link
```

Os `GET` de aprovação e recusa apresentam uma página HTML de confirmação e não alteram estado. Os `POST` recebem `actionToken` em formulário `application/x-www-form-urlencoded`, consomem o token uma única vez e apresentam o resultado em HTML. A recusa pode receber um motivo opcional.

Cada link usa token aleatório de 32 bytes, Base64 URL-safe sem padding, armazenado exclusivamente como hash SHA-256 e válido por 24 horas. A validação exige correspondência de ação, OS, orçamento e token ainda não consumido. O consumo usa lock transacional e a decisão publica no máximo um evento pela Outbox. Token inválido, expirado, incompatível ou reutilizado retorna uma página genérica com HTTP `401`, sem distinguir a causa.

Tokens não podem aparecer em logs, eventos, traces, métricas, mensagens de erro ou respostas administrativas. O contrato implementável está no [OpenAPI do oficina-billing-service](openapi/oficina-billing-service.yaml), e o ownership está na [Aprovação do orçamento pelo cliente](../docs/architecture/customer-budget-approval-gap.md).

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

Toda representação de pagamento inclui `acoesPermitidas`, calculada pelo domínio financeiro. Estados e identificadores externos são apenas apresentados pelos consumidores; sucesso, recusa, cancelamento e compensação nunca devem ser inferidos na UI.

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

A consulta aceita `nome`, `ativo`, `page` e `size`. Interfaces de composição devem solicitar `ativo=true` e não decidir localmente se um item inativo pode ser selecionado.

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

A consulta aceita `nome`, `codigo`, `ativo`, `page` e `size`. Saldo não integra o catálogo e deve ser obtido pela API de estoque quando necessário.

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

## Dashboard operacional

As consultas agregadas da interface operacional são definidas no [Contrato do dashboard operacional](dashboard-operational.md). Cada autoridade oferece uma rota de snapshot própria para ordens, usuários, credenciais, execução, estoque ou faturamento. O cliente não agrega listagens, calcula prioridade ou infere pendência a partir de estados.

As rotas são contrato alvo e somente passam a integrar o runtime após a implementação correspondente nos backends e na infraestrutura.

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
