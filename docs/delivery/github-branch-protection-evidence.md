# Evidência de Proteção da Branch `main`

## Objetivo

Registrar a verificação remota de `[B2-GH-REM-001]` nos repositórios `oficina-os-service`, `oficina-billing-service` e `oficina-execution-service`, conforme a [Política de Proteção da Branch Main](github-branch-protection.md) e o [Checklist final de entrega](phase-4-delivery-checklist.md).

## Verificação de 2026-07-13

A consulta pública da API do GitHub confirmou que a branch `main` está marcada como protegida nos três repositórios. As regras efetivamente aplicáveis foram consultadas pelo endpoint `GET /repos/oficina-soat/<repositorio>/rules/branches/main`.

| Repositório | Ruleset ativo | PR obrigatório | Check obrigatório encontrado | Check canônico esperado | Resultado |
|---|---:|---|---|---|---|
| `oficina-os-service` | `18530104` | Sim | `develop-validate` | `service-ci-validate` | Não conforme |
| `oficina-billing-service` | `18530103` | Sim | `develop-validate` | `service-ci-validate` | Não conforme |
| `oficina-execution-service` | `18530102` | Sim | `develop-validate` | `service-ci-validate` | Não conforme |

Os três Rulesets ativos, todos chamados `Ruleset 1`, também impedem deleção e atualização `non-fast-forward`. Esses controles adicionais não prejudicam o requisito mínimo.

## Diagnóstico

Os workflows locais dos três microsserviços confirmam a distinção:

| Workflow | Job/check | Finalidade |
|---|---|---|
| `.github/workflows/service-ci.yml` | `service-ci-validate` | Validar PR e merge da mudança do microsserviço, incluindo testes, cobertura e SonarCloud. |
| `.github/workflows/open-pr-to-main.yml` | `develop-validate` | Validar a branch `develop` antes de preparar o PR para `main`. |

Exigir `develop-validate` na `main` não implementa a política canônica. O check pode não pertencer ao commit do PR que está sendo homologado e não substitui `service-ci-validate`.

## Correção Administrativa Indicada na Verificação Inicial

Para cada repositório, um administrador deve acessar `Settings → Rules → Rulesets → Ruleset 1` e, na regra de status checks:

1. remover `develop-validate`;
2. adicionar `service-ci-validate`;
3. manter a regra de pull request ativa;
4. salvar o Ruleset como `Active`.

A política do repositório proíbe agentes de solicitar, armazenar ou operar credenciais administrativas para aplicar branch protection. Por isso, esta verificação inicial não alterou os Rulesets remotamente.

## Revalidação após a correção administrativa

Em 13/07/2026, os detalhes dos mesmos Rulesets foram consultados novamente pela API autenticada do GitHub. Os três permanecem ativos, aplicam-se à branch padrão e mantêm as regras de pull request, bloqueio de deleção e bloqueio de atualização `non-fast-forward`.

| Repositório | Ruleset ativo | Branch alvo | PR obrigatório | Check obrigatório | Integração | Resultado |
|---|---:|---|---|---|---:|---|
| `oficina-os-service` | `18530104` | `~DEFAULT_BRANCH` | Sim | `service-ci-validate` | GitHub Actions (`15368`) | Conforme |
| `oficina-billing-service` | `18530103` | `~DEFAULT_BRANCH` | Sim | `service-ci-validate` | GitHub Actions (`15368`) | Conforme |
| `oficina-execution-service` | `18530102` | `~DEFAULT_BRANCH` | Sim | `service-ci-validate` | GitHub Actions (`15368`) | Conforme |

Nenhum dos Rulesets exige mais `develop-validate`. A configuração agora atende à [Política de Proteção da Branch Main](github-branch-protection.md), concluindo `[B2-GH-REM-001]`.

## Comando de Revalidação

Após a correção administrativa, a configuração pode ser conferida sem expor credenciais:

```bash
for repo in oficina-os-service oficina-billing-service oficina-execution-service; do
  curl --fail --silent --show-error \
    --header 'Accept: application/vnd.github+json' \
    --header 'X-GitHub-Api-Version: 2022-11-28' \
    "https://api.github.com/repos/oficina-soat/${repo}/rules/branches/main" \
    | jq --arg repo "${repo}" '{
        repository: $repo,
        pullRequestRequired: any(.[]; .type == "pull_request"),
        requiredChecks: [
          .[]
          | select(.type == "required_status_checks")
          | .parameters.required_status_checks[].context
        ]
      }'
done
```

O item estará conforme somente quando as três respostas apresentarem:

```json
{
  "pullRequestRequired": true,
  "requiredChecks": [
    "service-ci-validate"
  ]
}
```

## Critério para Encerrar o Roadmap

Após a correção:

- repetir a consulta para os três repositórios;
- registrar data, Ruleset e resultado conforme;
- atualizar o [Checklist final de entrega](phase-4-delivery-checklist.md);
- marcar `[B2-GH-REM-001]` como concluído no [ROADMAP](../../ROADMAP.md).
