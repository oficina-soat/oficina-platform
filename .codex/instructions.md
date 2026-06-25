# Instruções para agentes Codex

Este projeto é o repositório central de governança da plataforma da oficina mecânica. Ele define arquitetura, contratos, padrões e decisões compartilhadas para orientar a criação e evolução dos microsserviços e dos repositórios de infraestrutura.

## Regras gerais

- Use comandos reais de validação em vez de inferências.
- Trate `AGENTS.md` e `ROADMAP.md` como referências principais antes de propor ou implementar mudanças.
- Preserve a estrutura atual: ADRs em `adr/`, contratos em `contracts/`, eventos em `contracts/events/` e OpenAPI em `contracts/openapi/`.
- Não transforme este repositório em implementação de microsserviço, Lambda, banco ou infraestrutura executável.
- Não assuma que os repositórios irmãos estejam disponíveis; quando estiverem, consulte-os apenas para manter coerência de contratos, nomes e integrações.
- Considere que alguns repositórios irmãos existentes podem deixar de ser usados. A direção da plataforma é ter um repositório independente para cada microsserviço: `oficina-os-service`, `oficina-billing-service` e `oficina-execution-service`.
- Ao identificar necessidade de alterar decisões arquiteturais, sugira a mudança para avaliação do usuário antes de criar ou alterar ADRs.
- Quando a tarefa afetar contratos compartilhados, verifique se há artefatos correlatos que precisam ser atualizados no mesmo escopo.

## Contratos e documentação

Ao alterar contratos REST:

- mantenha coerência entre `contracts/Contrato de APIs REST.md` e `contracts/openapi/`;
- preserve o versionamento por URI, atualmente `/api/v1`, salvo decisão aprovada;
- inclua ou preserve endpoints, schemas, códigos HTTP, erros, autenticação e exemplos mínimos quando trabalhar em OpenAPI.

Ao alterar eventos ou mensageria:

- mantenha coerência entre `contracts/Contrato de Eventos de Domínio.md`, `contracts/events/` e `contracts/Contrato de Tópicos de Mensageria.md`;
- preserve o envelope padrão com `eventId`, `eventType`, `eventVersion`, `occurredAt`, `producer`, `aggregateId` e `payload`;
- não altere nomes de eventos, tópicos, produtores ou consumidores sem atualizar os documentos relacionados.

Ao alterar estados ou fluxos da Ordem de Serviço:

- valide coerência com REST, eventos, mensageria e Saga;
- preserve a Saga orquestrada pelo `oficina-os-service`, salvo decisão arquitetural aprovada.

## Validação

Para mudanças em Markdown, liste os documentos afetados e verifique a estrutura esperada:

```bash
find . -path ./.git -prune -o -name '*.md' -print
```

Para mudanças em OpenAPI YAML:

```bash
find contracts/openapi -name '*.yaml' -print
```

Quando houver validador OpenAPI disponível no ambiente, use-o para os arquivos alterados.

Para mudanças em JSON Schema:

```bash
find contracts/events -name '*.schema.json' -print
```

Quando houver `jq` disponível, valide exemplos ou schemas JSON alterados:

```bash
jq empty <arquivo.json>
```

Use validações adicionais quando a mudança afetar contratos executáveis, exemplos JSON, templates, CI/CD, Kubernetes ou padrões operacionais.

## Roadmap

Use `ROADMAP.md` para orientar prioridade e critério de pronto. A ordem recomendada é:

1. Contratos implementáveis.
2. Blueprint dos microsserviços.
3. Saga e integração distribuída.
4. Operação e entrega.

Se uma tarefa concluir ou alterar um item do roadmap, atualize o checklist correspondente ou explique por que ele não foi alterado.

## Git

Ao concluir qualquer alteração relevante no repositório, crie um commit ao final do trabalho. Considere alteração relevante toda mudança de documentação, contrato, ADR, template, instrução, workflow ou arquivo de projeto feita como resultado da tarefa.

Não deixe alterações relevantes sem commit, salvo quando o usuário pedir explicitamente para não commitar ou quando houver impedimento técnico que precise ser relatado.

Antes de commitar:

- adicione somente arquivos da tarefa;
- não inclua metadados de IDE, caches ou arquivos locais não relacionados;
- preserve alterações existentes que não foram feitas por você.
- verifique `git status --short` antes de fazer stage;
- use `git diff -- <arquivo>` para revisar o conteúdo que será commitado quando houver mudanças pré-existentes no repositório.

Use mensagens curtas em português seguindo Conventional Commits:

```bash
git add <arquivos-da-tarefa>
git commit -m "<tipo>: <resumo>"
```

Exemplos:

- `docs: ajusta instrucoes para agentes`
- `docs: normaliza contratos de eventos`
- `docs: adiciona contrato de idempotencia`
