# Proteção da branch main dos microsserviços

## Objetivo

Definir a configuração obrigatória de proteção da branch `main` para os repositórios da Fase 4:

- `oficina-os-service`;
- `oficina-billing-service`;
- `oficina-execution-service`.

Esta política atende ao requisito de repositórios protegidos do [Enunciado Fase 4](Enunciado%20Fase%204.md) e deve ser aplicada em conjunto com os workflows derivados do [Template GitHub Actions para Microsserviços](../templates/github-actions/README.md).

## Regra canônica

Cada repositório deve proteger a branch `main` com:

- pull request obrigatório antes de merge;
- pelo menos uma aprovação obrigatória;
- aprovação anterior descartada quando novos commits forem enviados;
- resolução obrigatória de conversas antes de merge;
- branch atualizada em relação à `main` antes de merge;
- check obrigatório `service-ci-validate`;
- histórico linear obrigatório;
- force push desabilitado;
- deleção da branch desabilitada;
- aplicação da regra também para administradores.

O check obrigatório `service-ci-validate` é produzido pelo workflow `.github/workflows/service-ci.yml` dos três microsserviços. O workflow `.github/workflows/open-pr-to-main.yml` usa o check `develop-validate` e não deve ser configurado como check obrigatório de merge para a `main`, porque ele serve apenas para preparar PRs a partir da branch `develop`.

## Pré-requisitos

A aplicação remota exige uma credencial GitHub com permissão administrativa nos três repositórios e autorização para administrar branch protection.

Variáveis esperadas no terminal:

```bash
export GITHUB_TOKEN=<token-com-permissao-admin>
export GITHUB_OWNER=oficina-soat
```

## Aplicação via API

Execute para cada repositório:

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
        "strict": true,
        "contexts": [
          "service-ci-validate"
        ]
      },
      "enforce_admins": true,
      "required_pull_request_reviews": {
        "dismiss_stale_reviews": true,
        "require_code_owner_reviews": false,
        "required_approving_review_count": 1,
        "require_last_push_approval": true
      },
      "restrictions": null,
      "required_linear_history": true,
      "allow_force_pushes": false,
      "allow_deletions": false,
      "block_creations": false,
      "required_conversation_resolution": true,
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

- `required_status_checks.strict` igual a `true`;
- `required_status_checks.contexts` contendo `service-ci-validate`;
- `required_pull_request_reviews.required_approving_review_count` igual a `1`;
- `required_pull_request_reviews.dismiss_stale_reviews` igual a `true`;
- `required_conversation_resolution.enabled` igual a `true`;
- `required_linear_history.enabled` igual a `true`;
- `allow_force_pushes.enabled` igual a `false`;
- `allow_deletions.enabled` igual a `false`.

## Estado operacional

Esta política é a fonte canônica para a configuração de branch protection dos três microsserviços. A aplicação efetiva deve ser registrada no [Checklist Final de Entrega da Fase 4](phase-4-delivery-checklist.md) quando houver evidência do GitHub para os três repositórios.
