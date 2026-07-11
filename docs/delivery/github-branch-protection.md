# Proteção da branch main dos microsserviços

## Objetivo

Definir a configuração obrigatória de proteção da branch `main` para os repositórios da Fase 4:

- `oficina-os-service`;
- `oficina-billing-service`;
- `oficina-execution-service`.

Esta política atende ao requisito de repositórios protegidos do [Enunciado Fase 4](Enunciado%20Fase%204.md) e deve ser aplicada em conjunto com os workflows derivados do [Template GitHub Actions para Microsserviços](../../templates/github-actions/README.md).

## Regra canônica

Cada repositório deve proteger a branch `main` com:

- pull request obrigatório antes de merge;
- check automático obrigatório `service-ci-validate` antes de merge.

O check obrigatório `service-ci-validate` é produzido pelo workflow `.github/workflows/service-ci.yml` dos três microsserviços. O workflow `.github/workflows/open-pr-to-main.yml` usa o check `develop-validate` e não deve ser configurado como check obrigatório de merge para a `main`, porque ele serve apenas para preparar PRs a partir da branch `develop`.

Não são requisitos canônicos da Fase 4: aprovação obrigatória, descarte de aprovações antigas, aprovação do último push, resolução obrigatória de conversas, branch atualizada em relação à `main`, histórico linear, bloqueio explícito de force push/deleção ou aplicação da regra para administradores. Esses controles podem ser adotados como endurecimento administrativo, mas não devem bloquear a conclusão do item de roadmap quando o requisito do enunciado estiver atendido.

A validação de conformidade da Fase 4 deve considerar somente os dois requisitos canônicos acima.

## Pré-requisitos

A aplicação remota exige uma credencial GitHub com permissão administrativa nos três repositórios e autorização para administrar branch protection.

## Escopo administrativo

A aplicação efetiva da proteção de branch no GitHub é uma tarefa administrativa fora do escopo dos agentes.

Agentes podem manter esta política, revisar coerência com os workflows, gerar comandos e registrar evidências fornecidas pelo responsável pela administração do GitHub. Agentes não devem solicitar, armazenar ou operar credenciais administrativas do GitHub para aplicar branch protection remotamente.

O item permanece aberto no [ROADMAP](../../ROADMAP.md) até existir evidência administrativa da proteção configurada nos três repositórios.

Variáveis esperadas no terminal:

```bash
export GITHUB_TOKEN=<token-com-permissao-admin>
export GITHUB_OWNER=oficina-soat
```

## Aplicação via API

Quando a proteção for configurada pela API clássica de branch protection, execute para cada repositório. O payload abaixo mantém desativados os controles que não fazem parte do requisito mínimo do enunciado.

```bash
for repo in oficina-os-service oficina-billing-service oficina-execution-service; do
  curl --fail-with-body \
    --request PUT \
    --url "https://api.github.com/repos/${GITHUB_OWNER}/${repo}/branches/main/protection" \
    --header "Accept: application/vnd.github+json" \
    --header "Authorization: Bearer ${GITHUB_TOKEN}" \
    --header "X-GitHub-Api-Version: 2022-11-28" \
    --data '{
      "required_status_checks": {
        "strict": false,
        "contexts": [
          "service-ci-validate"
        ]
      },
      "enforce_admins": false,
      "required_pull_request_reviews": {
        "dismiss_stale_reviews": false,
        "require_code_owner_reviews": false,
        "required_approving_review_count": 0,
        "require_last_push_approval": false
      },
      "restrictions": null,
      "required_linear_history": false,
      "allow_force_pushes": null,
      "allow_deletions": false,
      "block_creations": false,
      "required_conversation_resolution": false,
      "lock_branch": false,
      "allow_fork_syncing": false
    }'
done
```

## Verificação via API

Após aplicar a política, verifique os pontos principais:

```bash
for repo in oficina-os-service oficina-billing-service oficina-execution-service; do
  curl --fail-with-body \
    --request GET \
    --url "https://api.github.com/repos/${GITHUB_OWNER}/${repo}/branches/main/protection" \
    --header "Accept: application/vnd.github+json" \
    --header "Authorization: Bearer ${GITHUB_TOKEN}" \
    --header "X-GitHub-Api-Version: 2022-11-28"
done
```

Confirme em cada resposta:

- `required_status_checks` configurado;
- `required_status_checks.contexts` contendo `service-ci-validate`;
- `required_pull_request_reviews` configurado, ainda que com `required_approving_review_count` igual a `0`.

Quando a proteção for implementada por Rulesets em vez da branch protection clássica, confirme que as regras aplicáveis à branch `main` incluem:

- regra `pull_request`;
- regra `required_status_checks` com o check `service-ci-validate`.

## Estado operacional

Esta política é a fonte canônica para a configuração de branch protection dos três microsserviços. A aplicação efetiva deve ser registrada no [Checklist Final de Entrega da Fase 4](phase-4-delivery-checklist.md) quando houver evidência do GitHub para os três repositórios.
