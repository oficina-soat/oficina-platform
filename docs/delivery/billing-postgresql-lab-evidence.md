# Evidência PostgreSQL do Billing no Lab

## Escopo

Este documento registra a validação remota de `[B2-BILL-DB-REM-001]` no ambiente `lab`, conforme o [Padrão de isolamento PostgreSQL no RDS compartilhado](../infrastructure/rds-postgresql-isolation.md) e o [Checklist final de entrega](phase-4-delivery-checklist.md).

Nenhuma senha, URL completa de conexão ou conteúdo de Secret Kubernetes foi exibido ou registrado. As consultas usaram o Secret `oficina-billing-service-database-env` apenas por referência em pods temporários, removidos ao final da validação.

## Imagem e configuração do runtime

A imagem inicialmente implantada, `oficina-billing-service:1.0.19`, já continha os commits de persistência PostgreSQL e Event Store financeiro. O Deployment apresentava:

- `OFICINA_PERSISTENCE_KIND=postgresql` no ConfigMap `oficina-billing-service-config`;
- ConfigMap e Secret PostgreSQL injetados por `envFrom`;
- profile Quarkus `prod` ativo;
- Flyway conectado ao database `oficina_billing` como `oficina_billing_user`;
- PostgreSQL `16.13` e schema na versão `4`.

A consulta ao `flyway_schema_history` confirmou as quatro migrations aplicadas com sucesso: schema financeiro, seed, Event Store persistente e idempotência persistente.

## Correção encontrada durante a validação

A primeira consulta encontrou orçamento, pagamento, Outbox e idempotência no PostgreSQL, mas `billing_consumed_event` e `financeiro_item_projection` estavam vazias. Uma mensagem contratual publicada no SNS permaneceu disponível na SQS, revelando que `DomainMessagingWorker` não era instanciado no startup do Quarkus.

O worker recebeu `@Startup`, um teste impede regressão e `project.version` foi incrementado para `1.1.2` no commit `ee9c36c` do `oficina-billing-service`. A validação local aprovou `125` testes, PostgreSQL e LocalStack via Testcontainers, constraints de arquitetura, JaCoCo e análise SonarCloud. O [PR 22](https://github.com/oficina-soat/oficina-billing-service/pull/22) foi mergeado após `service-ci-validate` e SonarCloud aprovados.

O [run 29289563605](https://github.com/oficina-soat/oficina-billing-service/actions/runs/29289563605) publicou a imagem `1.1.2`, criou a release e concluiu o deploy no EKS. Após o rollout, o worker publicou os dois registros pendentes da Outbox, consumiu e reconheceu na SQS o evento de evidência `pecaIncluidaNaOrdemDeServico`.

## Evidência no database `oficina_billing`

Consultas SQL somente leitura executadas após o consumo retornaram:

| Tabela | Quantidade |
|---|---:|
| `orcamento` | `3` |
| `orcamento_item` | `6` |
| `pagamento` | `3` |
| `financeiro_item_projection` | `1` |
| `billing_consumed_event` | `1` |
| `outbox_event` | `2` |
| `idempotency_record` | `6` |

Registros sentinela:

| Categoria | Evidência |
|---|---|
| Pagamento | `pagamento.id=1d43fc0b-8802-4b20-bc7f-483c722e3468`, `provedor=mercado-pago`, `transacao_externa_id=1327656764`. |
| Outbox | `event_type=pagamentoSolicitado`, `status=PUBLISHED`, `correlation_id=b2-mp-evid-001-20260713T214100Z`. |
| Evento consumido | `event_id=7beaed63-19b7-4c6e-9bc5-57340f1695cb`, `event_type=pecaIncluidaNaOrdemDeServico`, `producer=oficina-os-service`. |
| Projeção financeira | OS `c7dbb76f-0dc1-4a5d-96b4-3b5bdac894bd`, item `a85b14dd-f109-43dd-baf0-a5424d352ad7`, tipo `PECA`, quantidade `1.000`, valor `25.50`. |

Esses resultados comprovam que o runtime não usa o store em memória: todos os adapters exigidos gravaram no PostgreSQL canônico do Billing.

## Persistência após restart

O pod `oficina-billing-service-585f8f4c69-f5bqg`, UID `9d278730-5959-42b2-9ddf-6924687e4635`, foi excluído de forma controlada. O Deployment criou `oficina-billing-service-585f8f4c69-xln8f`, UID `04edb100-070a-4e1e-a93a-970b95d33587`, usando a mesma imagem `1.1.2`.

Após o novo pod ficar pronto:

- `GET /api/v1/pagamentos/1d43fc0b-8802-4b20-bc7f-483c722e3468` retornou HTTP `200` com o mesmo provedor e identificador externo;
- as sete contagens permaneceram idênticas;
- os registros sentinela de pagamento, Outbox, evento consumido e projeção permaneceram idênticos;
- o database e o usuário continuaram sendo `oficina_billing` e `oficina_billing_user`.

Com a publicação, as gravações reais e a preservação após restart comprovadas, `[B2-BILL-DB-REM-001]` está concluído.
