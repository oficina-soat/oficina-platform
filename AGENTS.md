# AGENTS.md

## Contexto

Este repositório é a fonte oficial de governança da plataforma da oficina mecânica. Ele concentra decisões arquiteturais, contratos, padrões e artefatos compartilhados que direcionam a evolução dos microsserviços e dos repositórios de infraestrutura.

Stack e escopo atual do projeto:

- ADRs em `adr/`
- contratos REST, eventos, mensageria e estados em `contracts/`
- especificações OpenAPI em `contracts/openapi/`
- roadmap incremental em `ROADMAP.md`
- documentação geral em `README.md`

Os microsserviços definidos para a plataforma são:

- `oficina-os-service`
- `oficina-billing-service`
- `oficina-execution-service`

A direção da plataforma é que cada microsserviço tenha seu próprio repositório independente, seguindo a governança, os contratos e os padrões definidos aqui. Ao criar ou evoluir esses repositórios, use os nomes dos microsserviços acima como referência canônica.

Este repositório faz parte de uma suíte maior. Alguns repositórios irmãos existentes ainda podem servir como referência, mesmo que parte deles deixe de ser usada conforme os novos microsserviços forem criados. Assuma que, quando presentes na mesma raiz deste diretório, os repositórios irmãos relevantes são:

- `../oficina-app`
- `../oficina-auth-lambda`
- `../oficina-infra-db`
- `../oficina-infra-k8s`

Quando esses repositórios estiverem disponíveis, eles devem ser consultados para manter consistência de nomes, contratos e integrações compartilhadas da suíte, especialmente:

- nomes de environments
- nomes de secrets
- nomes de variáveis de ambiente
- rotas expostas publicamente
- contratos REST e OpenAPI
- nomes de eventos, tópicos e produtores
- issuer, audience e JWKS usados na autenticação
- padrões de banco de dados, Kubernetes, CI/CD e deploy

## Diretrizes Gerais

- Trate este repositório como fonte normativa da plataforma. Mudanças em ADRs, contratos e padrões devem reduzir ambiguidade para implementação em outros repositórios.
- Preserve a estrutura já usada no projeto: decisões em `adr/`, contratos em `contracts/`, eventos individuais em `contracts/events/` e OpenAPI por microsserviço em `contracts/openapi/`.
- Use o `ROADMAP.md` como referência de prioridade e critério de pronto para novas alterações.
- Prefira mudanças pequenas, objetivas e compatíveis com os contratos já existentes.
- Evite criar novos padrões, diretórios, microsserviços, tópicos ou formatos de contrato sem necessidade clara.
- Ao alterar uma decisão compartilhada, atualize todos os artefatos afetados no mesmo escopo da mudança.
- Quando houver divergência entre documentação conceitual e contratos implementáveis, explicite a decisão e normalize os artefatos relacionados.
- Quando houver dúvida sobre nomes que precisam ser iguais entre plataforma, aplicação, autenticação, banco e infraestrutura, consulte os repositórios irmãos antes de definir novos valores.

## Implementação

- Mantenha AWS como plataforma de nuvem definida, salvo nova ADR explícita.
- Preserve a governança multi-repositório: este repositório define padrões e contratos, mas não deve absorver código de aplicação, Lambda, banco ou infraestrutura executável.
- Preserve a divisão atual dos microsserviços entre `oficina-os-service`, `oficina-billing-service` e `oficina-execution-service`.
- Preserve a estratégia de comunicação híbrida: REST para integrações síncronas e mensageria assíncrona para eventos de domínio.
- Preserve a Saga Pattern orquestrada pelo `oficina-os-service`, salvo mudança arquitetural documentada por ADR.
- Preserve persistência poliglota por microsserviço conforme ADRs e padrões existentes.
- Ao mexer em contratos REST, mantenha coerência entre `contracts/Contrato de APIs REST.md` e os arquivos em `contracts/openapi/`.
- Ao mexer em eventos, mantenha coerência entre `contracts/Contrato de Eventos de Domínio.md`, `contracts/events/`, `contracts/Contrato de Tópicos de Mensageria.md` e eventuais schemas JSON.
- Ao mexer em estados de Ordem de Serviço, mantenha coerência com os fluxos REST, eventos e Saga.
- Ao criar contratos OpenAPI, inclua endpoints, schemas de request e response, códigos HTTP esperados, erros padronizados, autenticação e exemplos mínimos.
- Ao criar schemas de eventos, use o envelope padrão de mensageria com `eventId`, `eventType`, `eventVersion`, `occurredAt`, `producer`, `aggregateId` e `payload`.
- Não altere nomes de eventos, tópicos, produtores, rotas ou estados sem atualizar os documentos correlatos.
- Se houver erro simples, warning simples ou ajuste mecânico evidente no escopo da tarefa, resolva junto em vez de deixar pendência.

## Prioridades

Siga a priorização do `ROADMAP.md` para orientar alterações incrementais.

Prioridade atual recomendada:

1. Contratos implementáveis:
   - normalizar eventos e tópicos;
   - criar tabela canônica `evento -> tópico -> produtor -> consumidores`;
   - criar schemas JSON dos eventos fundamentais;
   - manter OpenAPI dos três microsserviços;
   - criar contrato de erros REST;
   - criar contrato de idempotência.
2. Blueprint dos microsserviços:
   - criar matriz de ownership por serviço;
   - criar template Quarkus de microsserviço;
   - criar pipeline padrão de CI/CD;
   - criar manifests Kubernetes base;
   - criar documentação local padrão.
3. Saga e integração distribuída:
   - detalhar fluxo principal da Ordem de Serviço;
   - documentar compensações, timeouts, retentativas e cenários de erro;
   - definir contratos de comandos e eventos usados pela Saga.
4. Operação e entrega:
   - documentar observabilidade;
   - definir logs estruturados, métricas, traces e `correlationId`;
   - criar runbooks, checklist de release e checklist de revisão de contratos.

## Validação

Antes de encerrar uma alteração, execute a validação compatível com o impacto da mudança.

Para mudanças em Markdown:

```bash
find . -path ./.git -prune -o -name '*.md' -print
```

Para mudanças em OpenAPI YAML:

```bash
find contracts/openapi -name '*.yaml' -print
```

Para mudanças em JSON Schema:

```bash
find contracts/events -name '*.schema.json' -print
```

Use validações adicionais quando houver ferramentas disponíveis no repositório ou quando a mudança afetar contratos executáveis, exemplos JSON, OpenAPI, schemas de eventos, templates, CI/CD ou Kubernetes.

Checklist mínimo de revisão antes da resposta final:

- confirmar se o artefato criado está no diretório correto;
- confirmar se nomes de serviços, eventos, tópicos e rotas batem com os contratos relacionados;
- confirmar se mudanças em um contrato exigem atualização de OpenAPI, schema, ADR ou roadmap;
- confirmar se o `README.md` ou o `ROADMAP.md` precisam ser atualizados;
- registrar claramente qualquer validação que não pôde ser executada.

## Versionamento e Build

Este projeto depende de versionamento explícito dos contratos e decisões para manter governança entre repositórios.

- Preserve compatibilidade com contratos já publicados, salvo alteração deliberada e documentada.
- Mudanças incompatíveis em eventos devem incrementar `eventVersion` ou documentar a estratégia de migração.
- Mudanças incompatíveis em APIs devem preservar versionamento por URI, atualmente `/api/v1`, ou documentar nova versão.
- Ao identificar necessidade de alterar decisões arquiteturais, sugira a mudança e aguarde avaliação do usuário antes de criar ou alterar ADRs.
- Ao alterar padrões que impactem microsserviços ou infraestrutura, confirme se templates, contratos e documentação precisam ser atualizados.
- Não introduza mudanças que exijam intervenção manual implícita sem registrar isso no repositório.

## Commits

Sempre que houver alterações no repositório como resultado da tarefa, crie um commit ao final do trabalho quando o usuário solicitar entrega versionada ou quando o fluxo da tarefa pedir explicitamente commit.

Antes de criar o commit:

- adicione ao Git todos os arquivos novos criados no escopo da tarefa com `git add <arquivos-da-tarefa>`
- faça stage dos arquivos alterados que pertencem à tarefa
- não inclua arquivos locais ou não relacionados, como metadados de IDE

Ao criar o commit, use mensagens em português seguindo Conventional Commits:

```bash
git add <arquivos-da-tarefa>
git commit -m "<tipo>: <resumo>"
```

Exemplos válidos:

- `docs: adiciona orientações para agentes do repositorio`
- `docs: normaliza contratos de eventos e topicos`
- `docs: adiciona contrato de idempotencia`
- `chore: adiciona template base de microsservico`

Prefira mensagens curtas, objetivas e diretamente relacionadas à alteração.

## Restrições Práticas

- Não transforme este repositório em implementação de microsserviço.
- Não mova para este repositório responsabilidades que pertencem à aplicação, autenticação, banco ou infraestrutura Kubernetes.
- Não altere silenciosamente contratos compartilhados com `oficina-app`, `oficina-auth-lambda`, `oficina-infra-db` ou `oficina-infra-k8s`.
- Não crie novos microsserviços fora da divisão atual sem ADR e atualização dos contratos relacionados.
- Não troque soluções já adotadas por alternativas mais complexas sem justificativa técnica clara.
- Não ignore divergências simples entre Markdown, OpenAPI, eventos, tópicos e schemas quando estiverem no escopo da tarefa.
- Não inclua arquivos locais de IDE, caches ou artefatos gerados que não sejam parte explícita da mudança.
