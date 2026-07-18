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
| Hospedagem | Container Nginx opcional no EKS, exposto pelo HTTP API compartilhado |
| Infraestrutura | Extensão opcional no `oficina-infra`, com root module e state próprios |
| Entrega | Pipeline independente no repositório `oficina-ui` |
| Escopo inicial | Login, atendimento e fila do mecânico |

Referências: [ciclo oficial de releases do Angular](https://angular.dev/reference/releases), documentação do Nginx e padrões Kubernetes adotados pelos demais repositórios.

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

- [x] `[UI-ADR-001]` Criar ADR na plataforma para registrar repositório independente, Angular SPA, ausência inicial de BFF/SSR, fronteira sem regras de negócio e ownership do frontend. Concluído na [ADR-013](../../adr/ADR-013%20-%20Frontend%20Operacional%20Angular.md), posteriormente atualizada com a hospedagem compatível com o lab.
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
- [x] `[UI-MECHANIC-WORKSPACE-001]` Reunir no atendimento acessado pela fila os dados e a composição da OS com os comandos da execução; cada seção deve renderizar exclusivamente as capabilities retornadas por seu backend. Concluído localmente com navegação única de atendimento mecânico, composição de peças/serviços e comandos operacionais cobertos por testes unitários e E2E.
- [ ] `[UI-MECHANIC-WORKSPACE-RECON-001]` Exibir de forma explícita OS operacionais ainda sem execução associada e orientar a reconciliação, sem sintetizar capabilities ou comandos no Angular.
- [x] `[UI-MECHANIC-WORKSPACE-REM-001]` Implantar e homologar no `lab` a jornada do mecânico em uma única tela, incluindo item, diagnóstico e reparo. Concluído com a [homologação do atendimento mecânico unificado](../delivery/mechanic-workspace-lab-evidence.md) pela UI real.
- [x] `[UI-ACTIONS-001]` Evoluir o `oficina-os-service`, o `oficina-execution-service` e suas OpenAPI para retornarem identificadores canônicos de ações permitidas nos detalhes da OS e da execução; depois adaptar o `oficina-ui` para renderizar somente as ações informadas, sem inferir permissões ou transições a partir de estado ou papel. Concluído nos commits `07e24e7` do `oficina-platform`, `1f51594` do `oficina-os-service`, `87cfa77` e `3a7d6dc` do `oficina-execution-service`, e `82d28f3`, `33672b7` e `00ebff8` do `oficina-ui`. Os testes de contrato, backend, adapters e apresentação foram aprovados; os deploys [OS 1.4.0](https://github.com/oficina-soat/oficina-os-service/actions/runs/29448582538), [Execution 1.1.0](https://github.com/oficina-soat/oficina-execution-service/actions/runs/29448583776) e [Execution 1.1.1](https://github.com/oficina-soat/oficina-execution-service/actions/runs/29449705183) foram concluídos, e OS, detalhes e fila foram validados diretamente no API Gateway do `lab` com ações canônicas por estado.

#### Trilha de composição técnica da OS

Esta trilha completa a jornada operacional que hoje permite abrir a OS somente com o problema relatado. O `oficina-execution-service` continua responsável pelos catálogos técnicos e pelo estoque, o `oficina-os-service` pela composição da OS e o `oficina-billing-service` pelos snapshots e cálculos financeiros. A UI apenas pesquisa, coleta a escolha do operador e apresenta ações e resultados canônicos.

- [x] `[UI-OS-ITEMS-DISCOVERY-001]` Auditar o fluxo atual, os estados da OS, os catálogos de serviços e peças, os eventos e os consumidores para definir ownership, momento de inclusão, quantidade, remoção, alteração e reflexos em orçamento e estoque. Concluído na [auditoria da composição técnica da OS](os-items-discovery.md): o primeiro incremento preserva a inclusão durante `EM_DIAGNOSTICO`, snapshots no OS Service e eventos existentes; alteração e remoção ficam fora do MVP por não existirem no domínio e exigirem novos contratos distribuídos. Nenhuma mudança de ownership ou ADR foi necessária.
- [x] `[UI-OS-ITEMS-CONTRACT-001]` Evoluir as OpenAPI de Execution e OS para oferecer catálogos paginados e filtráveis e a composição detalhada da OS, com identificadores, quantidades, snapshots necessários, erros, idempotência e `acoesPermitidas` para inclusão. Concluído nos contratos normativos com filtro de itens ativos, composição detalhada na leitura da OS e comandos idempotentes separados para peça e serviço; nome e valores são snapshots autoritativos resolvidos pelo backend.
- [x] `[UI-OS-ITEMS-CATALOG-001]` Ajustar no `oficina-execution-service` somente as lacunas de consulta dos catálogos identificadas na auditoria, sem expor decisão de estoque ao frontend. Concluído no commit `3c7733a` do Execution `1.3.0`: os filtros, paginação e campo canônico `ativo` já existentes foram preservados, e as consultas agora aceitam `ativo=true|false`; o `clean verify` aprovou 106 testes, arquitetura e cobertura JaCoCo.
- [x] `[UI-OS-ITEMS-BACKEND-001]` Implementar no `oficina-os-service` a persistência e os comandos idempotentes de inclusão na OS, revalidando estado, autorização, item, quantidade e ações permitidas exclusivamente no backend. Concluído no commit `c07d701` do OS Service `1.6.0`: os comandos recebem somente o identificador e a quantidade, resolvem o item ativo no catálogo autoritativo, permitem inclusão apenas durante `EM_DIAGNOSTICO` e persistem snapshots de nome e valores por meio da migration V6.
- [x] `[UI-OS-ITEMS-INTEGRATION-001]` Integrar a composição com eventos, Billing, Execution e estoque, preservando snapshots financeiros, deduplicação, consistência eventual, compensação e observabilidade por `correlationId`. Concluído no commit `c07d701`: o OS Service consulta o Execution com timeout e propagação do `correlationId`, grava item e Outbox atomicamente e publica os contratos existentes consumidos por Billing e Execution; chaves únicas, idempotência HTTP e Inbox dos consumidores preservam a deduplicação. O `clean verify` aprovou 187 testes, PostgreSQL/Flyway, LocalStack, contratos, arquitetura e cobertura JaCoCo.
- [x] `[UI-OS-ITEMS-CLIENT-001]` Criar no `oficina-ui` modelos de apresentação, ports, casos de uso, mappers e adapters HTTP para catálogos e itens da OS, sem transportar DTOs externos nem regras de disponibilidade ou cálculo para a apresentação. Concluído no commit `74abbf1`: contratos sincronizados e clientes regenerados, modelos internos separados dos DTOs, pesquisa dos catálogos ativos no Execution e comandos idempotentes de composição no Attendance.
- [x] `[UI-OS-ITEMS-VIEW-001]` Implementar no detalhe da OS a pesquisa e seleção acessível de serviços e peças, quantidade, composição atual e confirmações, exibindo inclusão somente quando informada por `acoesPermitidas`. Concluído no commit `74abbf1`: o detalhe apresenta snapshots e totais recebidos do backend e renderiza cada formulário exclusivamente para `INCLUIR_SERVICO` ou `INCLUIR_PECA`, com pesquisa, seleção e quantidade acessíveis.
- [x] `[UI-OS-ITEMS-TEST-001]` Cobrir contratos, regras e idempotência nos backends, integração por eventos, adapters, estados de tela, autorização visual, teclado, acessibilidade e os fluxos E2E de composição e rejeição. Concluído no commit `74abbf1`: 85 testes unitários cobrem aplicação, mappers, HTTP e apresentação, e os 10 cenários Playwright incluem composição idempotente com axe; arquitetura, lint, cobertura, build, segurança e auditoria sem vulnerabilidades foram aprovados.
- [x] `[UI-OS-ITEMS-REM-001]` Implantar e homologar no `lab` a composição de uma OS com serviço e peça, comprovando orçamento derivado, reflexo de estoque, eventos, retries seguros e correlação, sem registrar dados pessoais ou financeiros sensíveis. Concluído em 2026-07-16 com uma nova jornada sentinela coerente: composição de `R$ 250,00`, orçamento derivado e aprovado, pagamento confirmado, eventos consumidos em ordem, retries idempotentes, conflito de payload, ausência de movimentação prematura de estoque e renderização acessível na UI publicada; detalhes estão na [evidência do MVP no lab](ui-mvp-lab-evidence.md).

### Qualidade, segurança e entrega do MVP

- [x] `[UI-TEST-001]` Criar testes unitários de apresentação/aplicação, testes dos adapters com HTTP simulado e testes de arquitetura. Concluído no `oficina-ui` com 63 testes em 22 arquivos, cobertura global acima dos pisos obrigatórios, adapters HTTP simulados e guardrails executáveis para as fronteiras arquiteturais.
- [x] `[UI-E2E-001]` Criar testes E2E para login, atendimento e fila do mecânico, cobrindo caminho feliz, rejeição, autorização, idempotência visual e expiração de sessão. Concluído no `oficina-ui` com cinco cenários Playwright executados em Chromium contra a aplicação real e APIs simuladas apenas na fronteira HTTP, sem dependência ou mutação do `lab`.
- [x] `[UI-A11Y-001]` Validar navegação por teclado, foco, labels, contraste, leitores de tela e comportamento responsivo. Concluído no commit `e045b67` do `oficina-ui` com foco no conteúdo após navegação, diálogo com confinamento e restauração de foco, suporte a movimento reduzido, ajustes responsivos, checklist manual documentado e testes automatizados WCAG 2.1 A/AA com axe-core em desktop e viewport móvel. Validação concluída com 64 testes unitários, 7 testes E2E, lint, guardrails arquiteturais, cobertura e build de produção aprovados.
- [x] `[UI-SEC-001]` Configurar CSP, headers de segurança, auditoria de dependências e verificação de que build, logs e source maps públicos não expõem credenciais ou dados sensíveis. Concluído nos commits `5e0e017` do `oficina-ui` e `77de317` do `oficina-infra`: source maps e chunks nomeados estão explicitamente desabilitados, a configuração de runtime aceita somente campos contratados e endpoints relativos ou HTTPS, logs não serializam erros, e o build é inspecionado contra arquivos de chave, source maps e padrões de credenciais ou tokens. A entrega atual mantém esses headers no Nginx e acrescenta container não-root, capabilities removidas e filesystem somente leitura.
- [x] `[UI-CI-001]` Criar pipeline com instalação reproduzível, lint, format check, testes, cobertura, build e Quality Gate antes da publicação. Concluído no commit `89b1409` do `oficina-ui` com workflow reutilizável em pull requests, execução manual e bloqueio obrigatório do deploy. O pipeline executa em paralelo o gate de build, testes, arquitetura, segurança e auditoria e o gate E2E com Chromium, teclado e axe; somente o artefato validado é entregue ao deploy, sem recompilação. A reprodução local aprovou `npm ci`, 69 testes com cobertura, 7 E2E, build, scanner de segurança e zero vulnerabilidades de produção.
- [x] `[UI-OBS-001]` Instrumentar erros e desempenho do navegador sem CPF, JWT ou dados financeiros, propagando `correlationId` para permitir diagnóstico conjunto com os backends. Concluído no commit `ee7e7b0` do `oficina-ui` com instrumentação independente de fornecedor para falhas HTTP, erros globais e métricas de navegação, LCP, CLS e INP. Os envelopes usam allowlist e não carregam URL, rota, query string, payload, mensagem, stack ou conteúdo de formulários; o envio opcional por `sendBeacon` não possui persistência nem retry e falhas HTTP incluem apenas método, status, código canônico e `correlationId`. O gate aprovou 73 testes, 7 E2E, cobertura, build, scanner e auditoria; ingestão real e busca cruzada serão evidenciadas na homologação do `lab`.
- [x] `[UI-MVP-REM-001]` Homologar no `lab` os três fluxos do MVP com os papéis reais e registrar evidências de segurança, acessibilidade, pipeline e operação. Concluído em 2026-07-16 com publicação, atendimento administrativo, composição, orçamento automático, pagamento único, segurança, acessibilidade, telemetria e fila/execução pela UI real com uma credencial exclusivamente mecânica. A correlação foi preservada em OS, Execution e Billing, o segundo pagamento retornou `409/DUPLICATE_RESOURCE` e a credencial sentinela foi inativada; detalhes estão na [evidência do MVP no lab](ui-mvp-lab-evidence.md).

## Trilha extra — workload opcional no lab

Esta trilha oferece acesso operacional conveniente à UI, mas não integra os requisitos obrigatórios da infraestrutura da solução. Sua execução, falha ou remoção não pode bloquear deploys, validações ou destruição controlada dos backends e dos componentes exigidos.

- [x] `[UI-INFRA-001]` Criar no `oficina-infra` uma composição Terraform opcional, em root module próprio e com backend/state independente de `terraform/environments/lab`. A primeira implementação usou S3 privado e CloudFront; após os bloqueios da role `voclabs`, a composição foi migrada para ECR, NLB interno e rota `$default`, preservando o isolamento operacional e o histórico da decisão.
- [x] `[UI-DEPLOY-001]` Publicar pelo pipeline independente do `oficina-ui` a imagem rastreável criada a partir do build validado, materializar configuração de runtime e realizar rollout seguro no EKS. Concluído pelo [run 29505861890](https://github.com/oficina-soat/oficina-ui/actions/runs/29505861890), que aprovou Quality Gate, E2E, teclado e acessibilidade, publicou a revisão `3dbf8a7`, materializou os endpoints canônicos e concluiu o rollout. Raiz, rota Angular com recarga, configuração de runtime, metadados e health check foram validados pelo API Gateway conforme a [evidência do MVP no lab](ui-mvp-lab-evidence.md).

## Evoluções posteriores ao MVP

Estes itens permanecem fora da sequência ativa até a homologação do MVP. Em cada
trilha, contratos e capacidades do backend antecedem adapters e telas para impedir
que decisões de negócio sejam reconstruídas no Angular.

### Estoque

- [x] `[UI-FUT-STOCK-CONTRACT-001]` Auditar e evoluir a OpenAPI do Execution para catálogo paginado, filtros, saldos, movimentações e ações permitidas, incluindo erros e idempotência canônicos. Concluído localmente com paginação canônica, filtros remotos e `REGISTRAR_ENTRADA` fornecido no saldo.
- [x] `[UI-FUT-STOCK-BACKEND-001]` Implementar no Execution somente as consultas e ações ausentes identificadas na auditoria, com autorização e invariantes no backend. Concluído localmente no `oficina-execution-service` 1.2.0.
- [x] `[UI-FUT-STOCK-CLIENT-001]` Criar modelos de apresentação, ports, mappers e adapters HTTP para o contrato de estoque, sem expor DTOs à apresentação. Concluído localmente na feature `execution/stock`.
- [x] `[UI-FUT-STOCK-VIEW-001]` Implementar catálogo e consulta de saldo com paginação, filtros remotos e estados de loading, vazio, erro e retry. Concluído localmente na rota `/estoque`.
- [x] `[UI-FUT-STOCK-MOVE-001]` Implementar histórico de movimentações e comandos exibidos exclusivamente a partir das ações permitidas retornadas pela API. Concluído localmente com histórico paginado e entrada condicionada a `acoesPermitidas`.
- [x] `[UI-FUT-STOCK-TEST-001]` Cobrir aplicação, adapters, acessibilidade e o fluxo E2E principal de estoque. Concluído localmente com testes de aplicação, HTTP, apresentação e Playwright com axe.

### Orçamento e pagamento

- [x] `[UI-FUT-BILLING-CONTRACT-001]` Auditar e evoluir as OpenAPI de OS e Billing para consulta de orçamento, itens, aprovação/recusa, pagamento, estados da Saga e ações permitidas. Concluído localmente com as ações financeiras canônicas e preservação do estado global consultado na OS.
- [x] `[UI-FUT-BILLING-BACKEND-001]` Implementar nos serviços responsáveis as consultas ou ações ausentes, mantendo cálculo, autorização, idempotência e transições fora da UI. Concluído localmente com ações derivadas pelas entidades financeiras e revalidação pelos casos de uso existentes.
- [x] `[UI-FUT-BILLING-CLIENT-001]` Criar modelos, ports, mappers e adapters HTTP de orçamento e pagamento. Concluído localmente na feature isolada `billing`.
- [x] `[UI-FUT-BILLING-BUDGET-001]` Implementar consulta detalhada e aprovação/recusa de orçamento apenas quando oferecidas pela resposta canônica. Concluído localmente com consulta por OS e decisões idempotentes condicionadas a `acoesPermitidas`.
- [x] `[UI-FUT-BILLING-PAYMENT-001]` Implementar acompanhamento de pagamento e Saga, sem calcular valores nem inferir sucesso ou compensação. Concluído localmente exibindo valores e estados recebidos das APIs responsáveis.
- [x] `[UI-FUT-BILLING-TEST-001]` Cobrir aplicação, adapters, rejeições, acessibilidade e fluxos E2E de aprovação e pagamento. Concluído localmente com testes unitários, HTTP, apresentação e Playwright com axe.

### Administração de usuários

- [x] `[UI-FUT-USERS-CONTRACT-001]` Auditar o contrato administrativo de usuários para paginação, filtros, detalhes, papéis, estado da credencial e ações permitidas. Concluído na [auditoria da administração de usuários](users-admin-discovery.md): foram identificados filtros declarados mas ausentes no runtime, ausência de ações canônicas e falta de consulta sanitizada do estado da credencial; o contrato alvo preserva OS e Auth como autoridades separadas.
- [x] `[UI-FUT-USERS-BACKEND-001]` Evoluir OS e Auth: publisher da Outbox desacoplado do long polling; filtros remotos por nome, CPF, estado e papel antes da paginação; `acoesPermitidas`; comandos idempotentes de bloqueio e reativação; consulta sanitizada do estado da credencial; contratos e testes atualizados. As mensagens históricas da DLQ foram diagnosticadas e reconciliadas separadamente, preservando rastreabilidade operacional.
- [x] `[UI-FUT-USERS-CLIENT-001]` Criar a feature `administration/users` com modelos, ports, casos de uso, mappers e adapters separados para OS e Auth, sem transportar senha, token ou CPF para telemetria. Concluído localmente com tipos OpenAPI isolados por autoridade, casos de uso sem regra de negócio e testes de aplicação, filtros, mapeamento, idempotência e separação da credencial.
- [x] `[UI-FUT-USERS-VIEW-001]` Implementar lista paginada, filtros remotos, detalhe, edição de dados e papéis, além do estado da credencial com indisponibilidade parcial explícita. Concluído localmente com rota e navegação administrativas, CPF mascarado na lista, edição condicionada a `ATUALIZAR_DADOS`, credencial carregada separadamente e retry que preserva o cadastro operacional.
- [x] `[UI-FUT-USERS-ACTIONS-001]` Implementar ativação, bloqueio, reativação e inativação exibindo somente ações retornadas pelas respectivas autoridades e exigindo confirmação acessível. Concluído localmente com diálogos acessíveis, comandos idempotentes de estado, token de ativação transitório e atualização pelas respostas canônicas de OS e Auth.
- [x] `[UI-FUT-USERS-TEST-001]` Cobrir contratos, autorização visual, idempotência, consistência eventual, aplicação, adapters, acessibilidade, falha parcial e fluxos E2E administrativos; homologar no `lab` com dados sentinela e investigar previamente a DLQ de `usuarioAdicionado`. Cobertura automatizada e [homologação ponta a ponta no lab](users-admin-lab-evidence.md) concluídas. A rodada final confirmou criação, filtros remotos, `acoesPermitidas`, projeção sanitizada da credencial, ativação, bloqueio, reativação e inativação, incluindo a autorização de login esperada em cada estado. O sentinela terminou inativo.

### Dashboard operacional

- [x] `[UI-FUT-DASHBOARD-DISCOVERY-001]` Definir personas, decisões operacionais, indicadores necessários, atualização e limites de dados do dashboard. Concluído no [discovery do dashboard operacional](dashboard-operational-discovery.md), que separa a visão de negócio da observabilidade técnica, prioriza cards e filas acionáveis por papel, exige agregações canônicas nos backends e explicita atualização, consistência parcial, segurança e itens fora do primeiro incremento.
- [x] `[UI-FUT-DASHBOARD-CONTRACT-001]` Contratar consultas agregadas próprias nos backends ou em uma API de leitura, incluindo período, atualização e indisponibilidade parcial. Concluído no [contrato do dashboard operacional](../../contracts/dashboard-operational.md) e nas OpenAPIs das quatro autoridades. A primeira versão usa snapshots atuais por domínio, com `generatedAt`, `dataAsOf`, atualização opcional, filas limitadas e composição parcial na UI; intervalos históricos e uma API transversal permanecem fora do escopo até decisão arquitetural específica.
- [x] `[UI-FUT-DASHBOARD-BACKEND-001]` Implementar as projeções agregadas sem transferir cálculos, joins de domínio ou interpretação de estados para o navegador. Concluído localmente no OS `1.10.0`, Execution `1.4.0`, Billing `1.6.0` e Auth `1.4.0`, com contagens e filas limitadas calculadas por cada autoridade, autorização por papel, timestamps de snapshot, cobertura automatizada e rotas correspondentes no `oficina-infra`. Alertas de estoque permanecem vazios até existir uma política canônica de reposição.
- [x] `[UI-FUT-DASHBOARD-UI-001]` Implementar cards, tabelas e visualizações acessíveis consumindo somente agregados canônicos. Concluído no commit `030cd9f` do `oficina-ui`, com feature isolada por camadas, blocos selecionados por papel, snapshots e filas preservados conforme cada autoridade, atualização manual, referência temporal e degradação parcial que mantém o último dado válido sem calcular indicadores no navegador.
- [x] `[UI-FUT-DASHBOARD-TEST-001]` Validar dados parciais, vazio, erro, responsividade, acessibilidade e contrato dos indicadores. Concluído localmente com cobertura de aplicação, mapeamento dos quatro contratos canônicos e apresentação para estados vazio, parcial, erro total, retry e preservação do último snapshot válido; o Playwright também valida autorização visual, responsividade móvel e acessibilidade automatizável. A rodada final aprovou 104 testes unitários, 13 cenários E2E, build de produção, validações arquiteturais e auditoria sem vulnerabilidades de produção.

### Atualização em tempo real

- [x] `[UI-FUT-REALTIME-MEASURE-001]` Medir latência, custo e impacto operacional do polling nos fluxos já implantados. Concluído na [medição de atualização do dashboard](realtime-update-measurement.md): a SPA atual não faz polling, e a rodada no `lab` mediu 50 respostas bem-sucedidas, latência mediana por bloco entre 457 e 549 ms e caudas de até 3,9 s. A projeção de 30 segundos demonstrou custo direto baixo no porte atual, mas pressão proporcional a sessões e registros porque os snapshots ainda percorrem coleções completas. A recomendação é preservar atualização manual e exigir necessidade operacional mensurável antes de ADR ou implementação em tempo real.

### BFF e sessão

- [ ] `[UI-FUT-BFF-DISCOVERY-001]` Levantar riscos e requisitos de sessão que não sejam atendidos com segurança pela SPA atual.
- [ ] `[UI-FUT-BFF-ADR-001]` Registrar ADR com ameaça, custo operacional, CSRF, CORS, escalabilidade e decisão de adotar ou rejeitar BFF com cookie `HttpOnly`.
- [ ] `[UI-FUT-BFF-CONTRACT-001]` Se aprovado, definir contratos de sessão, renovação, logout, CSRF e propagação de identidade sem mover regras de negócio ao BFF.
- [ ] `[UI-FUT-BFF-BACKEND-001]` Implementar e observar o BFF com privilégio mínimo e sem credenciais de domínio próprias.
- [ ] `[UI-FUT-BFF-UI-001]` Migrar autenticação e adapters da SPA para o contrato de sessão aprovado.
- [ ] `[UI-FUT-BFF-TEST-001]` Cobrir segurança de cookies, CSRF, expiração, logout, indisponibilidade e migração/rollback.

### Atualização em tempo real — trilha condicional

Os itens abaixo não integram a sequência executável enquanto os gatilhos definidos na [medição de atualização do dashboard](realtime-update-measurement.md) não forem observados. A trilha deve começar pela ADR, sem implementar antecipadamente uma solução.

- [ ] `[UI-FUT-REALTIME-ADR-001]` Registrar ADR comparando manter polling, SSE e WebSocket somente se a medição demonstrar necessidade.
- [ ] `[UI-FUT-REALTIME-CONTRACT-001]` Contratar autenticação, retomada, ordenação, deduplicação e fallback da alternativa escolhida.
- [ ] `[UI-FUT-REALTIME-IMPL-001]` Implementar backend e UI da atualização escolhida, preservando atualização manual como fallback observável.
- [ ] `[UI-FUT-REALTIME-TEST-001]` Testar reconexão, expiração de sessão, eventos duplicados/fora de ordem e degradação para fallback.

## Critério de pronto do MVP

O MVP funcional da UI estará pronto quando login, atendimento e fila do mecânico funcionarem contra o `lab`; nenhum componente contiver regra de negócio; as fronteiras arquiteturais forem verificadas automaticamente; APIs revalidarem todas as operações; e testes, acessibilidade, segurança e Quality Gate estiverem aprovados. O workload no EKS pertence à trilha extra e não altera o atendimento dos requisitos obrigatórios da infraestrutura.
