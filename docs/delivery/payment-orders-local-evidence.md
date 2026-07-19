# Evidência local da migração Mercado Pago Orders

## Resultado

Em 19/07/2026, as quatro etapas preparatórias do [plano de migração para a API Orders](../architecture/mercado-pago-orders-migration-plan.md) foram concluídas localmente. O Billing `1.9.0`, a infraestrutura e os contratos estão prontos para publicação e homologação no `lab`; a UI não precisou de alteração porque o contrato público de pagamento permaneceu compatível.

Nenhum push, deploy, workflow do GitHub Actions ou mutação no `lab` foi executado. A próxima tarefa aberta no [roadmap](../../ROADMAP.md) é `[D-PAYMENT-CONTINUITY-TEST-REM-001]`, que depende de autorização explícita para as operações remotas necessárias.

Os commits locais que materializam a preparação são `c301cb4` no `oficina-platform` para os contratos, `7114561` no `oficina-billing-service` para a candidata `1.9.0` e `fe34668` no `oficina-infra` para runtime e operação.

## Escopo implementado

| Componente | Resultado local |
|---|---|
| Contratos | Criação e consulta Orders, webhook `type=order`, resposta `200`, idempotência, tradução de estados, compatibilidade Payments e configurações sandbox normalizadas. |
| Billing `1.9.0` | Client e DTOs próprios de `/v1/orders`; valores monetários serializados como strings decimais; vínculo por `pagamentoId`; instruções PIX; tradução estrita; migration V9; referência `ORDER|PAYMENT`; webhook dual; restrição de `APRO`; modo de rollback da criação. |
| Infraestrutura | Runtime canônico `orders`, parâmetros oficiais do cenário `APRO`, validação preventiva, projeção no secret Kubernetes e runbook para evento **Order (Mercado Pago)**, rollout, rollback e convivência. |
| UI | Sem diff. A tela continua consumindo `instrucoesPix`, `ATUALIZAR_STATUS` e capabilities públicas, sem conhecer Orders. |

A implementação foi confrontada com a documentação oficial de [integração PIX](https://www.mercadopago.com.br/developers/pt/docs/checkout-api-orders/payment-integration/pix), [teste PIX com `APRO`](https://www.mercadopago.com.br/developers/pt/docs/checkout-api-orders/integration-test/pix), [status da order](https://www.mercadopago.com.br/developers/pt/docs/checkout-api-orders/payment-management/status/order-status) e [notificações Orders](https://www.mercadopago.com.br/developers/pt/docs/checkout-api-orders/notifications).

## Validações

| Superfície | Comando ou verificação | Resultado |
|---|---|---|
| Billing | `./mvnw -B clean verify -Ppostgresql -DskipITs=false -DfailIfNoTests=false` | 190 testes, zero falha; build Quarkus `1.9.0`; checks JaCoCo aprovados. |
| Cobertura Billing | `target/jacoco-report/jacoco.xml` | 3.008 de 3.208 linhas, 93,77%; 835 de 1.049 branches, 79,60%. |
| PostgreSQL | Testcontainers `postgres:16-alpine` e migration isolada V8→V9 | Backfill de referência legada para `PAYMENT`, persistência `ORDER`, consulta tipada e coexistência do mesmo ID externo aprovados. |
| Contratos | Parse OpenAPI/YAML, links e busca anti-divergência | Contrato REST, OpenAPI, idempotência, runtime e plano coerentes. |
| Infraestrutura | `bash scripts/actions/validate.sh` com os repositórios irmãos | Terraform dos dois módulos válido, overlays renderizados, 14 testes Python e simulação seca aprovados. |
| Linters de infraestrutura | `terraform fmt -check`, `tflint`, `actionlint`, `shellcheck`, `bash -n`, `yq`, `kubeconform -strict` e `git diff --check` | Aprovados. O `shfmt -d` continua apontando a indentação global preexistente do script de apply; as linhas novas preservam o estilo vigente para evitar uma reescrita fora de escopo. |
| UI | Node `24.15.0`; `format:check`, `lint`, `test:architecture`, `test:ci`, `build` e `test:security` | 105 testes, zero falha; 81,91% de linhas; build de produção e inspeção contra source maps e segredos aprovados; worktree sem alterações. |

O `SONAR_TOKEN` não estava disponível. Assim, não houve upload ao SonarCloud nem alegação de Quality Gate remoto; o `clean verify` com JaCoCo é a evidência local equivalente, e os gates remotos permanecem obrigatórios na homologação.

## Ponto de retomada no lab

Antes da jornada, devem ser publicados e implantados o Billing `1.9.0` e a configuração de infraestrutura correspondente. No painel do Mercado Pago, é necessário selecionar **Order (Mercado Pago)**, preservar **Pagamentos** durante a compatibilidade e confirmar a URL assinada sem registrar o secret em evidência.

A homologação deve então provar reparo → uma order PIX `APRO` → `action_required/waiting_transfer` → `processed/accredited` → uma única Outbox `pagamentoConfirmado` → capability **Registrar entrega** → OS `ENTREGUE`, incluindo callbacks duplicados, fora de ordem e concorrentes e a inspeção sanitizada de logs, traces e métricas definida na [evidência parcial anterior](payment-checkout-continuity-lab-evidence.md).
