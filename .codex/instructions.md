# Instruções para agentes Codex

Este arquivo contém instruções operacionais específicas para o Codex neste repositório. As regras completas de contexto, arquitetura, validação, versionamento e restrições estão em `AGENTS.md` e devem ser seguidas como fonte principal.

## Prioridades

- Leia `AGENTS.md` antes de implementar mudanças.
- Use `ROADMAP.md` para entender prioridades, lacunas e critérios de pronto.
- Trate este repositório como fonte de governança da plataforma, não como implementação de microsserviço, Lambda, banco ou infraestrutura executável.
- Ao identificar necessidade de alterar decisões arquiteturais, sugira a mudança para avaliação do usuário antes de criar ou alterar ADRs.

## Validação

- Use comandos reais de validação em vez de inferências.
- Para mudanças em Markdown, execute:

```bash
find . -path ./.git -prune -o -name '*.md' -print
```

- Para mudanças em OpenAPI ou JSON Schema, siga os comandos e critérios definidos em `AGENTS.md`.
- Registre na resposta final qualquer validação que não pôde ser executada.

## Git

- Ao concluir alteração relevante, crie um commit local para avaliação do usuário.
- Não faça `git push`, salvo se o usuário pedir explicitamente.
- Antes do commit, revise `git status --short` e inclua somente arquivos do escopo da tarefa.
- Preserve alterações existentes que não foram feitas por você.
- Use mensagens curtas em português seguindo Conventional Commits.
