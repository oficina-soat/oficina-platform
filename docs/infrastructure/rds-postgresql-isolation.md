# Padrão de isolamento PostgreSQL no RDS compartilhado

## Objetivo

Definir o padrão canônico de isolamento lógico para os databases PostgreSQL usados por `oficina-os-service` e `oficina-billing-service` na instância Amazon RDS compartilhada da Fase 4.

Este documento complementa a [ADR-011 - Estratégia de Persistência Poliglota por Microsserviço](../../adr/ADR-011%20-%20Estratégia%20de%20Persistência%20Poliglota%20por%20Microsserviço.md), a [Matriz de Ownership por Microsserviço](../architecture/service-ownership.md), os [Nomes de runtime, secrets e infraestrutura](infra-runtime-naming.md) e o [Escopo do Repositório Unificado de Infraestrutura](infrastructure-repository-scope.md).

## Decisão

A Fase 4 usa uma única instância Amazon RDS for PostgreSQL para os serviços relacionais, com databases, usuários, credenciais, migrations e permissões independentes por microsserviço.

```text
Amazon RDS for PostgreSQL: oficina-postgres-lab
+-- database: oficina_os
|   +-- owner: oficina_os_user
+-- database: oficina_billing
    +-- owner: oficina_billing_user
```

Essa decisão reduz custo operacional no ambiente `lab` sem permitir banco compartilhado entre serviços.

## Databases e usuários

| Microsserviço | Database | Usuário owner | Secret AWS | Secret Kubernetes |
|---|---|---|---|---|
| `oficina-os-service` | `oficina_os` | `oficina_os_user` | `oficina/lab/database/oficina-os-service` | `oficina-os-service-database-env` |
| `oficina-billing-service` | `oficina_billing` | `oficina_billing_user` | `oficina/lab/database/oficina-billing-service` | `oficina-billing-service-database-env` |

O usuário administrativo do RDS deve ser usado apenas pelo bootstrap de infraestrutura. Workloads Kubernetes, pipelines dos microsserviços, jobs de migrations e aplicações não devem usar a credencial administrativa.

## Regras de isolamento

- `oficina-os-service` acessa somente o database `oficina_os`.
- `oficina-billing-service` acessa somente o database `oficina_billing`.
- Um serviço nunca executa migrations, consultas, joins, views, triggers, foreign data wrappers ou procedures sobre estruturas do outro serviço.
- Comunicação entre os serviços deve ocorrer por APIs REST e eventos definidos nos contratos da plataforma.
- Migrations do OS e do Billing devem residir nos repositórios dos respectivos microsserviços.
- O `oficina-infra` pode executar apenas o bootstrap de instância, databases, usuários, permissões e secrets.

## Bootstrap mínimo

O bootstrap de infraestrutura deve criar os databases e owners sem conceder acesso cruzado.

```sql
CREATE USER oficina_os_user WITH PASSWORD '<resolved-from-secret>';
CREATE USER oficina_billing_user WITH PASSWORD '<resolved-from-secret>';

CREATE DATABASE oficina_os OWNER oficina_os_user;
CREATE DATABASE oficina_billing OWNER oficina_billing_user;

REVOKE CONNECT ON DATABASE oficina_os FROM PUBLIC;
REVOKE CONNECT ON DATABASE oficina_billing FROM PUBLIC;

GRANT CONNECT ON DATABASE oficina_os TO oficina_os_user;
GRANT CONNECT ON DATABASE oficina_billing TO oficina_billing_user;
```

Após conectar em cada database, o bootstrap deve garantir ownership do schema público apenas ao usuário do próprio serviço.

```sql
-- conectado em oficina_os
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
GRANT USAGE, CREATE ON SCHEMA public TO oficina_os_user;
ALTER SCHEMA public OWNER TO oficina_os_user;

-- conectado em oficina_billing
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
GRANT USAGE, CREATE ON SCHEMA public TO oficina_billing_user;
ALTER SCHEMA public OWNER TO oficina_billing_user;
```

Não deve haver `GRANT` entre `oficina_os_user` e `oficina_billing_user`.

## Secrets

Cada secret de banco deve conter somente a credencial do serviço correspondente.

Campos mínimos:

```json
{
  "host": "oficina-postgres-lab.<endpoint-rds>",
  "port": 5432,
  "database": "oficina_os",
  "username": "oficina_os_user",
  "password": "<valor-sensivel>",
  "sslmode": "require"
}
```

Para o Billing, o campo `database` deve ser `oficina_billing` e o campo `username` deve ser `oficina_billing_user`.

## Variáveis de runtime

Os microsserviços Quarkus devem materializar os secrets em variáveis compatíveis com o template base em [templates/quarkus-service/](../../templates/quarkus-service/).

| Microsserviço | `JDBC_DATABASE_URL` | `DB_USERNAME` | `DB_PASSWORD` |
|---|---|---|---|
| `oficina-os-service` | `jdbc:postgresql://<host>:5432/oficina_os?sslmode=require` | `oficina_os_user` | valor do secret `oficina/lab/database/oficina-os-service` |
| `oficina-billing-service` | `jdbc:postgresql://<host>:5432/oficina_billing?sslmode=require` | `oficina_billing_user` | valor do secret `oficina/lab/database/oficina-billing-service` |

Quando `REACTIVE_DATABASE_URL` for usado, ele deve apontar para o mesmo database do serviço.

## Migrations

Cada repositório de microsserviço deve executar suas migrations com a própria credencial:

```text
oficina-os-service -> oficina_os -> oficina_os_user
oficina-billing-service -> oficina_billing -> oficina_billing_user
```

A baseline sugerida para as migrations está em [Proposta de Migrations PostgreSQL Decompostas](postgres-migrations-decomposition.md). O `oficina-infra` não deve versionar migrations de domínio desses serviços.

## Validação anti-divergência

Antes de aplicar ou revisar infraestrutura, confirmar:

- a instância RDS usa `DB_IDENTIFIER=oficina-postgres-lab`;
- os databases `oficina_os` e `oficina_billing` existem;
- os usuários `oficina_os_user` e `oficina_billing_user` existem;
- cada usuário conecta apenas no próprio database;
- os secrets `oficina/lab/database/oficina-os-service` e `oficina/lab/database/oficina-billing-service` existem sem valores sensíveis em Git;
- os secrets Kubernetes `oficina-os-service-database-env` e `oficina-billing-service-database-env` materializam apenas as variáveis do próprio serviço;
- nenhum workload novo usa o secret legado `oficina/lab/database/app`;
- migrations de domínio permanecem nos repositórios dos microsserviços.

## Fora do escopo

- Criar instâncias RDS separadas por microsserviço.
- Migrar dados históricos do `oficina-app`.
- Criar tabelas do `oficina-execution-service` em PostgreSQL.
- Executar migrations de domínio dentro do `oficina-platform`.
