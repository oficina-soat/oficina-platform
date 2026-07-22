# oficina-platform
Seu objetivo é centralizar a governança da plataforma, fornecendo uma visão unificada da arquitetura e servindo como fonte oficial para contratos, padrões e decisões compartilhadas.

## Repositórios da plataforma

Os microsserviços canônicos da plataforma possuem repositórios independentes na mesma suíte:

| Repositório | Responsabilidade |
| --- | --- |
| `../oficina-os-service` | Gestão da Ordem de Serviço, cadastros principais e orquestração da Saga. |
| `../oficina-billing-service` | Cobrança, pagamentos e integrações financeiras. |
| `../oficina-execution-service` | Catálogo técnico de peças e serviços, diagnóstico, execução, estoque operacional e finalização do serviço. |
| `../oficina-ui` | Interface operacional Angular, sem regras de negócio, para recepção, administração e mecânicos. |

Os repositórios remotos verificados seguem a organização `oficina-soat` no GitHub:

- `git@github.com:oficina-soat/oficina-os-service.git`
- `git@github.com:oficina-soat/oficina-billing-service.git`
- `git@github.com:oficina-soat/oficina-execution-service.git`

Este repositório continua sendo a fonte normativa para ADRs, contratos, OpenAPI, eventos, padrões e artefatos compartilhados. Código de aplicação, pipelines específicos e manifestos próprios permanecem nos repositórios dos microsserviços.

## Padrões Reutilizáveis

- [Template de regras para monolito modular](templates/monolito-modular/README.md): referência canônica copiada do `oficina-app` para orientar `AGENTS.md` e testes estruturais de arquitetura nos microsserviços.

## Roadmap

O planejamento incremental da plataforma, incluindo lacunas restantes e backlog orientado a agentes, está documentado em [ROADMAP.md](ROADMAP.md).

O planejamento do frontend Angular está separado no [Roadmap do frontend operacional](docs/frontend/roadmap.md) e é executado quando o usuário direcionar o trabalho ao `oficina-ui`.

## Fluxos operacionais

Os diagramas abaixo são a visão transversal canônica. As regras detalhadas permanecem no [fluxo da Saga](docs/architecture/saga-flows.md), no [contrato da Saga](contracts/saga/oficina-os-saga-v1.md), no [contrato REST](contracts/Contrato%20de%20APIs%20REST.md) e no [contrato de tópicos](contracts/Contrato%20de%20T%C3%B3picos%20de%20Mensageria.md).

### Ciclo de vida da Ordem de Serviço

```mermaid
stateDiagram-v2
  [*] --> RECEBIDA: recepção
  RECEBIDA --> EM_DIAGNOSTICO: início do diagnóstico
  EM_DIAGNOSTICO --> AGUARDANDO_APROVACAO: orçamento gerado
  AGUARDANDO_APROVACAO --> EM_DIAGNOSTICO: orçamento recusado
  AGUARDANDO_APROVACAO --> EM_EXECUCAO: execução iniciada após aprovação
  EM_EXECUCAO --> FINALIZADA: reparo concluído
  FINALIZADA --> ENTREGUE: pagamento confirmado e entrega registrada
  ENTREGUE --> [*]
  note right of AGUARDANDO_APROVACAO
    Cancelamento não cria estado global adicional:
    falhas abortivas seguem a compensação da Saga.
  end note
```

### Orçamento e decisão do cliente

```mermaid
sequenceDiagram
  autonumber
  participant EX as Execution
  participant OS as OS / orquestrador
  participant BI as Billing
  participant AU as Auth / notificação
  actor CL as Cliente
  EX-->>OS: diagnosticoFinalizado
  EX-->>BI: diagnosticoFinalizado com itens
  BI->>BI: gera orçamento e capability armazenada como hash
  BI-->>OS: orcamentoGerado
  BI-->>AU: solicitação de notificação
  AU-->>CL: um e-mail com link unificado
  CL->>BI: abre página completa do orçamento
  alt Aprovação válida
    CL->>BI: aprovar
    BI-->>OS: orcamentoAprovado
    BI-->>EX: orcamentoAprovado
  else Recusa válida
    CL->>BI: recusar
    BI-->>OS: orcamentoRecusado
    BI-->>EX: orcamentoRecusado
    EX->>EX: retorno ao diagnóstico
  else Link expirado, substituído ou reutilizado
    BI-->>CL: erro canônico sem alterar o domínio
  end
```

### Aprovação, reparo e conclusão técnica

```mermaid
sequenceDiagram
  participant BI as Billing
  participant OS as OS / Saga
  participant EX as Execution
  BI-->>OS: orcamentoAprovado
  BI-->>EX: orcamentoAprovado
  EX->>EX: inicia o reparo
  EX-->>OS: execucaoIniciada
  OS->>OS: registra estado EM_EXECUCAO
  EX->>EX: mecânico executa e conclui o reparo
  EX-->>OS: execucaoFinalizada
  OS->>OS: registra estado FINALIZADA
  OS-->>BI: ordemDeServicoFinalizada
```

### Pagamento e entrega

```mermaid
sequenceDiagram
  actor OP as Operador
  participant OS as OS
  participant BI as Billing
  participant MP as Mercado Pago
  OP->>BI: solicita pagamento da OS finalizada
  BI->>MP: cria cobrança Pix
  MP-->>BI: identificador e QR Code
  BI-->>OP: dados para pagamento
  alt Webhook autenticado
    MP-->>BI: pagamento aprovado
    BI->>BI: persiste confirmação e Outbox
    BI-->>OS: pagamentoConfirmado
  else Reconciliação explícita
    OP->>BI: concluir/reconciliar pagamento
    BI->>MP: consulta situação atual
    MP-->>BI: pagamento aprovado
    BI->>BI: persiste confirmação e Outbox
    BI-->>OS: pagamentoConfirmado
  else Indisponibilidade ou falha transitória
    BI->>BI: mantém estado atual e registra falha observável
    MP-->>BI: webhook é reentregue ou a reconciliação é repetida
  else Pagamento recusado
    MP-->>BI: situação recusada
    BI-->>OS: pagamentoRecusado
  end
  opt pagamento confirmado
    OP->>OS: registra entrega
    OS->>OS: estado ENTREGUE
  end
```

### Saga assíncrona e confiabilidade

```mermaid
sequenceDiagram
  participant P as Serviço produtor
  participant OB as Outbox local
  participant SNS as Tópico SNS oficina.domínio.evento
  participant Q as Fila SQS por consumidor
  participant C as Serviço consumidor
  participant OS as OS / orquestrador
  P->>OB: persiste domínio + evento na mesma transação
  OB->>SNS: publica envelope com correlationId
  SNS-->>Q: fan-out
  Q->>C: entrega
  C->>C: Inbox e processamento idempotente
  C-->>OS: evento resultante
  alt falha transitória
    Q->>C: retentativa com backoff
  else tentativas esgotadas
    Q-->>Q: DLQ e alerta operacional
    OS->>OS: compensação ou FALHA_MANUAL
    OS-->>SNS: sagaCompensada
  else fluxo concluído
    OS-->>SNS: sagaFinalizadaComSucesso
  end
```

Cada evento usa o produtor, tópico e consumidores definidos na [tabela canônica de roteamento](contracts/Contrato%20de%20T%C3%B3picos%20de%20Mensageria.md#tabela-can%C3%B4nica-de-roteamento).

### Autenticação e autorização

```mermaid
sequenceDiagram
  actor U as Usuário operacional
  participant UI as UI Angular
  participant AU as Auth Lambda
  participant API as API do microsserviço
  U->>UI: informa CPF e senha
  UI->>AU: solicita autenticação
  AU->>AU: valida credencial, status e grupos/papéis
  AU-->>UI: JWT assinado
  UI->>API: Authorization: Bearer JWT
  API->>API: valida issuer, audience, assinatura e papel
  alt autorizado
    API-->>UI: recurso e ações permitidas
  else inválido ou sem papel
    API-->>UI: 401 ou 403 canônico
  end
```

### Ativação de usuário

```mermaid
sequenceDiagram
  participant OS as OS / usuários
  participant SNS as Mensageria
  participant SY as Auth Sync Lambda
  participant AU as Auth Lambda
  actor A as Administrador
  actor U as Usuário
  participant UI as UI Angular
  OS-->>SNS: usuarioAdicionado
  SNS-->>SY: snapshot sem credencial
  SY->>SY: cria identidade pendente
  A->>UI: solicita ativação do usuário
  UI->>AU: emite token com expiração e uso único
  AU-->>UI: exibe o token uma única vez
  A-->>U: entrega o token por canal controlado
  U->>UI: informa token e nova senha
  UI->>AU: conclui ativação
  alt token vigente e não consumido
    AU->>AU: ativa identidade e invalida token
    AU-->>UI: ativação concluída
  else expirado ou reutilizado
    AU-->>UI: erro canônico sem ativar identidade
  end
```

## Documentação

A documentação normativa está organizada por tema em [docs/](docs/README.md):

- [Arquitetura](docs/README.md#arquitetura)
- [Infraestrutura](docs/README.md#infraestrutura)
- [Observabilidade](docs/README.md#observabilidade)
- [Entrega e Validação](docs/README.md#entrega-e-validação)

## Scripts manuais

- [generate-bearer-token.sh](scripts/manual/generate-bearer-token.sh): gera um header `Authorization: Bearer ...` chamando `POST /auth/token` da `auth-lambda` do ambiente `lab`. Por padrão usa o usuário administrativo seedado, com papéis `administrativo`, `mecanico` e `recepcionista`.

Uso padrão:

```bash
scripts/manual/generate-bearer-token.sh
```

Para obter apenas o token, use:

```bash
scripts/manual/generate-bearer-token.sh --raw
```

Se a senha administrativa do ambiente mudar, use `AUTH_PASSWORD`, `AUTH_PASSWORD_FILE` ou `--password-file` para sobrescrever o valor seedado:

```bash
AUTH_PASSWORD_FILE=/tmp/oficina-auth-password \
  scripts/manual/generate-bearer-token.sh
```
