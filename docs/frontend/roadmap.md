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
| Infraestrutura | Extensão opcional no `oficina-infra`, com root module e state próprios |
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
- [x] `[UI-SHELL-001]` Criar shell responsivo com menu, identidade do usuário, breadcrumb, página não encontrada e tratamento global de indisponibilidade. Concluído no commit `74e3d0b` do `oficina-ui`, com identidade mascarada, navegação por papel e correlação de falhas técnicas; o dashboard operacional foi acrescentado no commit `15f19c2`.

### Fase 3 — MVP de atendimento

- [x] `[UI-CLIENT-001]` Implementar listagem paginada e cadastro idempotente de clientes conforme o contrato atual, sem pesquisa local. Concluído no commit `f812c67` do `oficina-ui` e validado em leitura contra o `lab`.
- [x] `[UI-CLIENT-002]` Implementar pesquisa de clientes por filtros operacionais somente depois que o `oficina-os-service` e sua OpenAPI oferecerem filtros por nome, CPF ou e-mail. Concluído nos commits `c9718cb` do `oficina-platform`, `5237bf1` do `oficina-os-service` e `d800caf` do `oficina-ui`: nome e e-mail aceitam trechos sem distinção de caixa, CPF usa correspondência exata, os critérios são aplicados no backend antes da paginação e a UI apenas envia e preserva os query parameters. A versão OS `1.5.0` foi implantada pelo [run 29451220202](https://github.com/oficina-soat/oficina-os-service/actions/runs/29451220202), e nome, CPF, e-mail e resultado vazio foram validados diretamente no API Gateway do `lab`.
- [x] `[UI-VEHICLE-001]` Implementar consulta e cadastro de veículos vinculados ao cliente. Concluído no commit `174a56a` do `oficina-ui`, com navegação a partir da listagem de clientes e validação de leitura no `lab`.
- [x] `[UI-OS-001]` Implementar abertura, consulta e listagem de ordens de serviço. Concluído no commit `14ba00b` do `oficina-ui`, com paginação, filtro canônico por estado, abertura a partir do veículo e validação de leitura no `lab`.
- [x] `[UI-OS-002]` Implementar detalhes, histórico e ações retornadas/aceitas pela API, sem codificar transições válidas no Angular. Concluído no `oficina-ui` com histórico canônico, alteração genérica de estado e cancelamento assíncrono; transições inválidas continuam sendo rejeitadas exclusivamente pelo backend.
- [x] `[UI-QUEUE-001]` Implementar fila do mecânico com atualização manual e estados retornados pelo Execution; paginação só deve ser adicionada depois de contratada no backend. Concluído no `oficina-ui` com rota protegida por papel para experiência, filtro canônico, ordem e posições preservadas da API e validação somente leitura no `lab`.
- [x] `[UI-EXEC-001]` Implementar início/conclusão de diagnóstico e reparo, apresentando sucesso, rejeição e conflito canônicos do backend. Concluído no `oficina-ui` com detalhe da execução, quatro comandos idempotentes e estado atualizado exclusivamente pela resposta da API; a consulta foi validada no `lab` sem avançar dados compartilhados.
- [x] `[UI-ACTIONS-001]` Evoluir o `oficina-os-service`, o `oficina-execution-service` e suas OpenAPI para retornarem identificadores canônicos de ações permitidas nos detalhes da OS e da execução; depois adaptar o `oficina-ui` para renderizar somente as ações informadas, sem inferir permissões ou transições a partir de estado ou papel. Concluído nos commits `07e24e7` do `oficina-platform`, `1f51594` do `oficina-os-service`, `87cfa77` e `3a7d6dc` do `oficina-execution-service`, e `82d28f3`, `33672b7` e `00ebff8` do `oficina-ui`. Os testes de contrato, backend, adapters e apresentação foram aprovados; os deploys [OS 1.4.0](https://github.com/oficina-soat/oficina-os-service/actions/runs/29448582538), [Execution 1.1.0](https://github.com/oficina-soat/oficina-execution-service/actions/runs/29448583776) e [Execution 1.1.1](https://github.com/oficina-soat/oficina-execution-service/actions/runs/29449705183) foram concluídos, e OS, detalhes e fila foram validados diretamente no API Gateway do `lab` com ações canônicas por estado.

### Fase 4 — Qualidade, segurança e entrega do MVP

- [x] `[UI-TEST-001]` Criar testes unitários de apresentação/aplicação, testes dos adapters com HTTP simulado e testes de arquitetura. Concluído no `oficina-ui` com 63 testes em 22 arquivos, cobertura global acima dos pisos obrigatórios, adapters HTTP simulados e guardrails executáveis para as fronteiras arquiteturais.
- [x] `[UI-E2E-001]` Criar testes E2E para login, atendimento e fila do mecânico, cobrindo caminho feliz, rejeição, autorização, idempotência visual e expiração de sessão. Concluído no `oficina-ui` com cinco cenários Playwright executados em Chromium contra a aplicação real e APIs simuladas apenas na fronteira HTTP, sem dependência ou mutação do `lab`.
- [x] `[UI-A11Y-001]` Validar navegação por teclado, foco, labels, contraste, leitores de tela e comportamento responsivo. Concluído no commit `e045b67` do `oficina-ui` com foco no conteúdo após navegação, diálogo com confinamento e restauração de foco, suporte a movimento reduzido, ajustes responsivos, checklist manual documentado e testes automatizados WCAG 2.1 A/AA com axe-core em desktop e viewport móvel. Validação concluída com 64 testes unitários, 7 testes E2E, lint, guardrails arquiteturais, cobertura e build de produção aprovados.
- [ ] `[UI-SEC-001]` Configurar CSP, headers de segurança, auditoria de dependências e verificação de que build, logs e source maps públicos não expõem credenciais ou dados sensíveis.
- [ ] `[UI-CI-001]` Criar pipeline com instalação reproduzível, lint, format check, testes, cobertura, build e Quality Gate antes da publicação.
- [ ] `[UI-OBS-001]` Instrumentar erros e desempenho do navegador sem CPF, JWT ou dados financeiros, propagando `correlationId` para permitir diagnóstico conjunto com os backends.
- [ ] `[UI-MVP-REM-001]` Homologar no `lab` os três fluxos do MVP com os papéis reais e registrar evidências de segurança, acessibilidade, pipeline e operação.

## Trilha extra — hospedagem opcional na AWS

Esta trilha oferece acesso operacional conveniente à UI, mas não integra os requisitos obrigatórios da infraestrutura da solução. Sua execução, falha ou remoção não pode bloquear deploys, validações ou destruição controlada dos backends e dos componentes exigidos.

- [x] `[UI-INFRA-001]` Criar no `oficina-infra` uma composição Terraform opcional para a hospedagem, em root module próprio e com backend/state independente de `terraform/environments/lab`. Concluído no commit `cabb066` do `oficina-infra` com S3 privado, CloudFront, Origin Access Control, fallback de rotas para `index.html`, headers de segurança, políticas distintas de cache, outputs e workflow Terraform manual próprio. A composição e seu state não possuem dependências dos recursos obrigatórios.
- [ ] `[UI-DEPLOY-001]` Publicar pelo pipeline independente do `oficina-ui` os artefatos com hash e cache longo, `index.html` sem cache prolongado, configuração de runtime, invalidação seletiva do CloudFront e versão rastreável do deploy. O pipeline foi implementado no commit `ead31a7` do `oficina-ui`, consumindo somente os outputs do state opcional e sem participar dos pipelines dos serviços; falta publicá-lo no GitHub, aplicar a stack e validar o primeiro deploy para concluir a tarefa.

## Evoluções posteriores ao MVP

Estes itens devem ser promovidos e detalhados somente depois da homologação do MVP.

- [ ] `[UI-FUT-STOCK-001]` Catálogo, saldo e movimentações de estoque.
- [ ] `[UI-FUT-BILLING-001]` Orçamento, aprovação/recusa e pagamentos.
- [ ] `[UI-FUT-USERS-001]` Administração, bloqueio, reativação e inativação de usuários.
- [ ] `[UI-FUT-DASHBOARD-001]` Dashboard operacional baseado em consultas agregadas fornecidas pelos backends.
- [ ] `[UI-FUT-REALTIME-001]` Avaliar atualização em tempo real somente se o polling se mostrar insuficiente.
- [ ] `[UI-FUT-BFF-001]` Avaliar BFF e cookie `HttpOnly` somente se os requisitos de sessão justificarem o custo operacional.

## Critério de pronto do MVP

O MVP funcional da UI estará pronto quando login, atendimento e fila do mecânico funcionarem contra o `lab`; nenhum componente contiver regra de negócio; as fronteiras arquiteturais forem verificadas automaticamente; APIs revalidarem todas as operações; e testes, acessibilidade, segurança e Quality Gate estiverem aprovados. A publicação em S3/CloudFront pertence à trilha extra e não altera o atendimento dos requisitos obrigatórios da infraestrutura.
