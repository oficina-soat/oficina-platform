# Evidência PostgreSQL do Serviço de OS no Lab

## Escopo

Este documento registra a validação remota de `[B2-OS-DB-REM-001]` no ambiente `lab`, conforme o [Padrão de isolamento PostgreSQL no RDS compartilhado](../infrastructure/rds-postgresql-isolation.md) e o [Checklist final de entrega](phase-4-delivery-checklist.md).

Nenhuma senha, URL completa de conexão ou conteúdo de Secret Kubernetes foi exibido ou registrado. As consultas usaram o Secret `oficina-os-service-database-env` somente por referência em pods temporários, removidos ao final da validação.

## Imagem e configuração do runtime

O Deployment estava saudável com uma réplica da imagem `oficina-os-service:1.2.3` e apresentava:

- `OFICINA_PERSISTENCE_KIND=postgresql` no ConfigMap `oficina-os-service-config`;
- ConfigMap e Secret PostgreSQL injetados por `envFrom`;
- profile Quarkus `prod` e ambiente lógico `lab` ativos;
- Flyway conectado ao database `oficina_os` como `oficina_os_user`;
- PostgreSQL `16.13` e schema na versão `5`.

A consulta a `flyway_schema_history` confirmou as cinco migrations aplicadas com sucesso: schema do serviço de OS, seed, tabelas da Saga, idempotência persistente e remoção do hash de senha do usuário operacional.

## Evidência no database `oficina_os`

Antes da criação da evidência, o PostgreSQL já continha dois clientes, dois veículos, cinco Ordens de Serviço e quinze estados históricos. Para comprovar a persistência da Saga pelo fluxo real, uma requisição `POST /api/v1/ordens-servico` foi executada internamente pelo Service Kubernetes, com chave de idempotência e `correlationId` próprios.

A requisição criou a OS sentinela `48f2a5be-b4ee-4ae5-b8b5-5b209b5063cd`. Consultas SQL somente leitura executadas em seguida retornaram:

| Tabela | Quantidade |
|---|---:|
| `pessoa` | `5` |
| `cliente` | `2` |
| `veiculo` | `2` |
| `ordem_de_servico` | `6` |
| `estado_ordem_servico` | `16` |
| `saga_ordem_servico` | `1` |
| `saga_estado_historico` | `1` |
| `outbox_event` | `1` |
| `idempotency_record` | `1` |

Registros sentinela:

| Categoria | Evidência |
|---|---|
| Cliente | `cliente.id=d290f1ee-6c54-4b01-90e6-d701748f0851`, associado a uma `pessoa` do tipo `FISICA`. |
| Veículo | `veiculo.id=7b1f1a8d-7f4a-4f25-8e74-27d50210a61e`, placa `ABC1D23`, associado ao cliente sentinela. |
| Ordem de Serviço | `ordem_de_servico.id=48f2a5be-b4ee-4ae5-b8b5-5b209b5063cd`, estado `RECEBIDA`, associada ao cliente e veículo sentinela. |
| Histórico da OS | A mesma OS possui o estado `RECEBIDA` em `estado_ordem_servico`. |
| Saga | `saga_ordem_servico.id=f015b04b-ff3e-4c2b-ad3c-7ff955bf1d4c`, estado `INICIADA`, etapa `ordemDeServicoCriada` e `correlation_id=b2-os-db-rem-001-20260713`. |
| Histórico da Saga | A Saga possui a etapa `ordemDeServicoCriada`, estado `INICIADA` e estado da OS `RECEBIDA`. |

Esses resultados, junto da Outbox e da idempotência criadas pela mesma requisição, comprovam que o fluxo usa os adapters PostgreSQL e não o store em memória.

## Isolamento do database

Usando exatamente o usuário `oficina_os_user` e a mesma instância RDS, uma tentativa explícita de conexão ao database `oficina_billing` falhou com `permission denied for database "oficina_billing"`.

O resultado comprova que o serviço usa credencial própria e não possui acesso ao database canônico do Billing.

## Persistência após restart

O pod `oficina-os-service-5bfb694c5f-nwt7v`, UID `358f71a0-0585-4ca4-93ed-4068ee34ca7e`, foi excluído de forma controlada. O Deployment criou `oficina-os-service-5bfb694c5f-r7qh2`, UID `2b058f09-4db6-45f1-905f-8b6ab127081f`, usando a mesma imagem `1.2.3`.

O novo pod iniciou com o profile `prod`, reconectou ao database `oficina_os` e confirmou o schema Flyway `5` atualizado. Após ficar pronto:

- `GET /api/v1/ordens-servico/48f2a5be-b4ee-4ae5-b8b5-5b209b5063cd` retornou a mesma OS sentinela;
- as nove contagens permaneceram idênticas;
- os registros sentinela de Cliente, Veículo, OS, histórico e Saga permaneceram idênticos;
- a tentativa de acesso a `oficina_billing` continuou sendo negada.

Com as gravações reais, o isolamento entre databases e a preservação após restart comprovados, `[B2-OS-DB-REM-001]` está concluído.
