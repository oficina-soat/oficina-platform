# Roadmap do frontend operacional

## Objetivo

Orientar a criação incremental do futuro `oficina-ui`: uma SPA Angular simples para uso interno de pessoas com os papéis `administrativo`, `recepcionista` e `mecanico`.

O repositório foi criado em `../oficina-ui`. Este roadmap está executável quando o usuário solicitar trabalho no frontend, sem alterar automaticamente a prioridade do [roadmap geral da plataforma](../../ROADMAP.md).

## Restrições arquiteturais

O frontend não contém regras de negócio. Ele coleta entradas, executa validações de forma e usabilidade, chama as APIs e apresenta o estado canônico retornado pelos backends.

| Permitido no frontend | Responsabilidade exclusiva do backend |
|---|---|
| Campos obrigatórios e formatos para feedback imediato | Validade definitiva de CPF, placa e demais dados |
| Estado de carregamento, erro, formulário e navegação | Transições válidas da Ordem de Serviço |
| Formatação de datas, moeda e identificadores | Cálculo de orçamento, valores ou descontos |
| Exibição de ações autorizadas pela API | Autorização definitiva e papéis permitidos |
| Paginação, filtros visuais e ordenação solicitada à API | Estoque disponível, reserva, consumo e compensação |
| Confirmação visual de ações sensíveis | Saga, pagamento, idempotência e publicação de eventos |

Não é permitido duplicar no Angular uma decisão do backend para habilitar uma operação. Quando a tela precisar conhecer uma ação possível, a API deve fornecer estado ou ações permitidas e revalidar a operação ao recebê-la.

## Direção técnica aprovada

| Tema | Direção inicial |
|---|---|
| Framework | Última versão estável do Angular no momento do scaffold; a baseline atual é Angular 22 |
| Aplicação | SPA sem SSR e sem BFF no primeiro incremento |
| Componentes | Standalone components e lazy loading por feature |
| Linguagem | TypeScript em modo estrito |
| Estado | Signals e serviços de aplicação; sem NgRx inicialmente |
| Formulários | Reactive Forms |
| Hospedagem | S3 privado e CloudFront com Origin Access Control |
| Infraestrutura | Terraform no `oficina-infra` |
| Entrega | Pipeline independente no repositório `oficina-ui` |
| Escopo inicial | Login, atendimento e fila do mecânico |

Referências: [ciclo oficial de releases do Angular](https://angular.dev/reference/releases) e [site estático seguro com S3 e CloudFront](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/getting-started-secure-static-website-cloudformation-template.html).

## Estrutura de referência

```text
src/app/
├── core/                    # sessão, configuração, erros e HTTP
├── shared/ui/               # componentes visuais sem negócio
└── features/
    └── <feature>/
        ├── application/     # coordenação de tela e ports
        ├── infrastructure/  # adapters HTTP, DTOs e mappers
        └── presentation/    # páginas, componentes e formulários
```

`application` coordena casos de uso da interface, como carregar uma OS, enviar um formulário e reagir à resposta. Essa camada não decide se a operação é válida. `infrastructure` encapsula Angular `HttpClient`, contratos externos e armazenamento de sessão. `presentation` não chama APIs diretamente.

## Sequência de implementação

### Fase 0 — Governança e contratos

- [x] `[UI-ADR-001]` Criar ADR na plataforma para registrar repositório independente, Angular SPA, ausência inicial de BFF/SSR, fronteira sem regras de negócio, S3/CloudFront e ownership do frontend. Concluído na [ADR-013](../../adr/ADR-013%20-%20Frontend%20Operacional%20Angular.md).
- [x] `[UI-SCOPE-001]` Documentar personas, mapa de navegação e escopo do MVP para `administrativo`, `recepcionista` e `mecanico`, excluindo portal do cliente. Concluído em `oficina-ui/docs/product-scope.md`.
- [x] `[UI-CONTRACT-001]` Auditar OpenAPI e rotas públicas para login, clientes, veículos, OS, histórico, fila, diagnóstico e reparo; registrar lacunas de consulta, filtros, paginação, CORS e ações permitidas sem criar decisões de negócio na UI. Concluído em `oficina-ui/docs/api-readiness.md`, com lacunas de CORS, busca e paginação da fila registradas.
- [x] `[UI-UX-001]` Criar wireframes responsivos dos fluxos do MVP, incluindo loading, vazio, erro, expiração de sessão, confirmação e rejeição da API. Concluído em `oficina-ui/docs/wireframes.md`.

### Fase 1 — Fundação do repositório

- [x] `[UI-BOOT-001]` Criar o workspace com Angular estável, standalone components, routing, strict mode, SCSS, lint, formatter, testes e configuração separada de runtime para API e autenticação. Concluído no commit `6a4647c` do `oficina-ui`.
- [x] `[UI-ARCH-001]` Materializar a estrutura por feature e as fronteiras `presentation -> application <- infrastructure`, sem camada de domínio rica e sem regra de negócio no navegador. Concluído no commit `6a4647c` do `oficina-ui`.
- [x] `[UI-ARCH-002]` Criar testes arquiteturais que impeçam `HttpClient` em componentes, imports de Angular na lógica pura de aplicação, dependência de detalhes internos entre features e uso de DTO externo como estado global da UI. Concluído no commit `6a4647c` do `oficina-ui`.
- [x] `[UI-API-001]` Gerar ou validar clientes a partir das OpenAPI e encapsulá-los em adapters; mapear respostas para modelos de apresentação sem reinterpretar estados do backend. Concluído no commit `4817f77` do `oficina-ui`.
- [x] `[UI-CORE-001]` Implementar interceptors de autenticação, `X-Correlation-Id`, erros canônicos e idempotency key para comandos mutáveis, preservando o backend como autoridade do resultado. Concluído no commit `7668d11` do `oficina-ui`.
- [x] `[UI-DESIGN-001]` Criar tokens visuais e componentes básicos acessíveis: layout, navegação, formulário, tabela, paginação, alerta, confirmação, loading e estado vazio. Concluído no commit `d1ef93d` do `oficina-ui`.

### Fase 2 — Autenticação e shell operacional

- [x] `[UI-AUTH-001]` Implementar login por CPF e senha, sessão inicialmente em memória, expiração, logout e tratamento de usuário bloqueado, inativo ou sem credencial ativada. Concluído no commit `240cfd7` do `oficina-ui`; enquanto o contrato retorna o mesmo motivo para esses três estados, a interface apresenta uma orientação segura e genérica.
- [x] `[UI-AUTH-002]` Implementar ativação de credencial conforme o contrato serverless, sem registrar senha, token de ativação ou JWT. Concluído no commit `f17ee06` do `oficina-ui`, incluindo geração administrativa do token de uso único e conclusão pública da ativação.
- [x] `[UI-AUTH-003]` Implementar guards e navegação por papel apenas como recurso de experiência; documentar e testar que a autorização definitiva permanece nas APIs. Concluído no commit `0abbe07` do `oficina-ui`, usando somente papéis conhecidos do claim `groups` para navegação visual.
- [x] `[UI-SHELL-001]` Criar shell responsivo com menu, identidade do usuário, breadcrumb, página não encontrada e tratamento global de indisponibilidade. Concluído no commit `74e3d0b` do `oficina-ui`, com identidade mascarada, navegação por papel e correlação de falhas técnicas.

### Fase 3 — MVP de atendimento

- [ ] `[UI-CLIENT-001]` Implementar pesquisa, listagem e cadastro de clientes usando filtros e paginação fornecidos pela API.
- [ ] `[UI-VEHICLE-001]` Implementar consulta e cadastro de veículos vinculados ao cliente.
- [ ] `[UI-OS-001]` Implementar abertura, consulta e listagem de ordens de serviço.
- [ ] `[UI-OS-002]` Implementar detalhes, histórico e ações retornadas/aceitas pela API, sem codificar transições válidas no Angular.
- [ ] `[UI-QUEUE-001]` Implementar fila do mecânico com atualização manual e estados retornados pelo Execution; paginação só deve ser adicionada depois de contratada no backend.
- [ ] `[UI-EXEC-001]` Implementar início/conclusão de diagnóstico e reparo, apresentando sucesso, rejeição e conflito canônicos do backend.

### Fase 4 — Qualidade, segurança e entrega do MVP

- [ ] `[UI-TEST-001]` Criar testes unitários de apresentação/aplicação, testes dos adapters com HTTP simulado e testes de arquitetura.
- [ ] `[UI-E2E-001]` Criar testes E2E para login, atendimento e fila do mecânico, cobrindo caminho feliz, rejeição, autorização, idempotência visual e expiração de sessão.
- [ ] `[UI-A11Y-001]` Validar navegação por teclado, foco, labels, contraste, leitores de tela e comportamento responsivo.
- [ ] `[UI-SEC-001]` Configurar CSP, headers de segurança, auditoria de dependências e verificação de que build, logs e source maps públicos não expõem credenciais ou dados sensíveis.
- [ ] `[UI-CI-001]` Criar pipeline com instalação reproduzível, lint, format check, testes, cobertura, build e Quality Gate antes da publicação.
- [ ] `[UI-INFRA-001]` Criar no `oficina-infra` S3 privado, CloudFront, Origin Access Control, fallback de rotas para `index.html`, headers, cache e outputs, sem domínio próprio inicialmente.
- [ ] `[UI-DEPLOY-001]` Publicar artefatos com hash e cache longo, `index.html` sem cache prolongado, invalidação seletiva do CloudFront e versão rastreável do deploy.
- [ ] `[UI-OBS-001]` Instrumentar erros e desempenho do navegador sem CPF, JWT ou dados financeiros, propagando `correlationId` para permitir diagnóstico conjunto com os backends.
- [ ] `[UI-MVP-REM-001]` Homologar no `lab` os três fluxos do MVP com os papéis reais e registrar evidências de segurança, acessibilidade, pipeline e operação.

## Evoluções posteriores ao MVP

Estes itens devem ser promovidos e detalhados somente depois da homologação do MVP.

- [ ] `[UI-FUT-STOCK-001]` Catálogo, saldo e movimentações de estoque.
- [ ] `[UI-FUT-BILLING-001]` Orçamento, aprovação/recusa e pagamentos.
- [ ] `[UI-FUT-USERS-001]` Administração, bloqueio, reativação e inativação de usuários.
- [ ] `[UI-FUT-DASHBOARD-001]` Dashboard operacional baseado em consultas agregadas fornecidas pelos backends.
- [ ] `[UI-FUT-REALTIME-001]` Avaliar atualização em tempo real somente se o polling se mostrar insuficiente.
- [ ] `[UI-FUT-BFF-001]` Avaliar BFF e cookie `HttpOnly` somente se os requisitos de sessão justificarem o custo operacional.

## Critério de pronto do MVP

O MVP estará pronto quando login, atendimento e fila do mecânico funcionarem no `lab`; nenhum componente contiver regra de negócio; as fronteiras arquiteturais forem verificadas automaticamente; APIs revalidarem todas as operações; testes, acessibilidade, segurança e Quality Gate estiverem aprovados; e o build Angular for servido por CloudFront a partir de bucket S3 privado.
