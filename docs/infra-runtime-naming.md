# Nomes de runtime, secrets e infraestrutura

Este documento consolida os nomes de runtime, secrets, variáveis e padrões de infraestrutura identificados nos repositórios irmãos da suíte.

Fontes consultadas:

- `../oficina-infra`
- `../oficina-infra-db`
- `../oficina-infra-k8s`
- `../oficina-execution-service`
- `../oficina-app`
- `../oficina-auth-lambda`

O objetivo é evitar novos nomes implícitos ao evoluir os microsserviços e o novo repositório unificado de infraestrutura.

---

## Valores fechados

Os valores abaixo já aparecem nos repositórios irmãos ou nos templates atuais deste repositório e devem ser tratados como canônicos para a Fase 4.

### Ambiente AWS

| Item | Valor |
|---|---|
| Região AWS | `us-east-1` |
| Escopo de configuração GitHub Actions | Secrets e variáveis de repositório ou organização |
| Nome lógico do ambiente | `lab` |
| Projeto | `oficina` |
| Prefixo de secrets | `oficina/lab` |
| Infraestrutura compartilhada | `eks-lab` |
| Cluster EKS | `eks-lab` |
| Namespace Kubernetes default | `default` |

Variáveis padronizadas:

```text
AWS_REGION=us-east-1
AWS_DEFAULT_REGION=us-east-1
OFICINA_PROJECT_NAME=oficina
OFICINA_ENVIRONMENT_NAME=lab
OFICINA_ENVIRONMENT=lab
OFICINA_SECRET_PREFIX=oficina/lab
SHARED_INFRA_NAME=eks-lab
EKS_CLUSTER_NAME=eks-lab
K8S_NAMESPACE=default
DEPLOYMENT_ENVIRONMENT=lab
OTEL_RESOURCE_ATTRIBUTES=service.namespace=oficina,deployment.environment=lab
OTEL_EXPORTER_OTLP_ENDPOINT=http://nr-k8s-otel-collector-gateway.newrelic.svc.cluster.local:4317
OTEL_EXPORTER_OTLP_PROTOCOL=grpc
QUARKUS_OTEL_TRACES_EXPORTER=cdi
OTEL_METRICS_EXPORTER=none
OTEL_LOGS_EXPORTER=none
```

### Observabilidade New Relic

O backend canônico para dashboards, alertas, logs, métricas e traces dos microsserviços é New Relic, conforme o [Padrão de Observabilidade Distribuída](observability.md).

A forma oficial de coleta do ambiente `lab` é New Relic OpenTelemetry Collector instalado por Helm no cluster EKS `eks-lab`, com OTLP/gRPC habilitado para traces dos microsserviços, coleta de logs dos pods e coleta das métricas expostas em `/q/metrics`.

Valores operacionais esperados no `oficina-infra`:

```text
INSTALL_NEW_RELIC_OTEL_COLLECTOR=auto
NEW_RELIC_NAMESPACE=newrelic
NEW_RELIC_OTEL_COLLECTOR_HELM_RELEASE=nr-k8s-otel-collector
NEW_RELIC_OTEL_COLLECTOR_LOCAL_SERVICE_NAME=nr-k8s-otel-collector-gateway
NEW_RELIC_LICENSE_KEY=<secret-github-ou-variavel-local-nao-versionada>
NEW_RELIC_LICENSE_KEY_SECRET_NAME=new-relic-license-key
NEW_RELIC_LICENSE_KEY_SECRET_KEY=licenseKey
NEW_RELIC_CLUSTER_NAME=eks-lab
NEW_RELIC_REGION=US
NEW_RELIC_OTLP_ENDPOINT=https://otlp.nr-data.net
OTEL_EXPORTER_OTLP_ENDPOINT=http://nr-k8s-otel-collector-gateway.newrelic.svc.cluster.local:4317
OTEL_EXPORTER_OTLP_PROTOCOL=grpc
```

`INSTALL_NEW_RELIC_OTEL_COLLECTOR=auto` mantém o deploy compatível com execuções sem conta New Relic e instala o collector automaticamente quando `NEW_RELIC_LICENSE_KEY` existe como secret do repositório/organização ou variável local segura. Use `INSTALL_NEW_RELIC_OTEL_COLLECTOR=false` para desabilitar explicitamente a etapa, ou `true` para exigir a instalação e falhar cedo quando a license key necessária não estiver disponível.

`NEW_RELIC_REGION=US` e `NEW_RELIC_OTLP_ENDPOINT=https://otlp.nr-data.net` são os padrões operacionais para contas New Relic nos Estados Unidos. Se a conta usar outra região, `NEW_RELIC_REGION` e o endpoint externo devem ser alterados em conjunto na configuração do collector no `oficina-infra`.

Com os nomes padrão, os microsserviços devem apontar para `OTEL_EXPORTER_OTLP_ENDPOINT=http://nr-k8s-otel-collector-gateway.newrelic.svc.cluster.local:4317`. Se `NEW_RELIC_NAMESPACE` ou `NEW_RELIC_OTEL_COLLECTOR_LOCAL_SERVICE_NAME` forem alterados no `oficina-infra`, o endpoint OTLP propagado aos manifests dos microsserviços deve mudar de forma consistente.

A configuração executável do collector fica no repositório de infraestrutura em [New Relic OpenTelemetry Collector no EKS lab](../../oficina-infra/docs/new-relic-otel-collector.md). Este repositório mantém os nomes canônicos e o contrato de runtime esperado pelos microsserviços.

### Credenciais AWS do GitHub Actions

Secrets obrigatórios no repositório ou na organização GitHub:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_SESSION_TOKEN
```

A conta AWS não é valor canônico fixo. Quando necessário, deve ser resolvida em tempo de deploy:

```bash
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
```

### Terraform remoto

Bucket compartilhado canônico:

```text
tf-shared-eks-lab-<aws-account-id>-us-east-1
```

Chaves de state já usadas:

```text
oficina/lab/infra/terraform.tfstate
oficina/lab/terraform.tfstate
oficina/lab/database/terraform.tfstate
```

Variáveis padronizadas:

```text
TF_STATE_BUCKET=tf-shared-eks-lab-<aws-account-id>-us-east-1
TERRAFORM_SHARED_DATA_BUCKET_NAME=tf-shared-eks-lab-<aws-account-id>-us-east-1
TF_STATE_REGION=us-east-1
TF_STATE_DYNAMODB_TABLE=<opcional>
```

Quando `TF_STATE_BUCKET` não for informado, os scripts de infraestrutura derivam o bucket a partir de `eks-lab`, conta AWS e região.

### Kubernetes

Secrets Kubernetes já usados:

```text
oficina-database-env
oficina-jwt-keys
```

Variáveis relacionadas:

```text
K8S_DATABASE_SECRET_ID=oficina/lab/database/app
K8S_JWT_SECRET_ID=oficina/lab/jwt
K8S_JWT_SECRET_KMS_KEY_ID=<opcional>
FETCH_RUNTIME_SECRETS_FROM_AWS=true
```

ConfigMaps e nomes legados do backend monolítico:

```text
oficina-app-config
oficina-app
```

Esses nomes continuam válidos apenas como referência histórica para `oficina-app`. Novos microsserviços devem usar o próprio nome canônico do serviço.

### JWT e autenticação

Secret compartilhado no AWS Secrets Manager:

```text
oficina/lab/jwt
```

Campos do secret:

```text
privateKeyPem
publicKeyPem
```

Variáveis padronizadas:

```text
JWT_SECRET_SOURCE=aws-secrets-manager
JWT_SECRET_NAME=oficina/lab/jwt
JWT_SECRET_PRIVATE_KEY_FIELD=privateKeyPem
JWT_SECRET_PUBLIC_KEY_FIELD=publicKeyPem
ROTATE_JWT_SECRET=false
OFICINA_AUTH_ISSUER=<issuer-resolvido-no-deploy>
OFICINA_AUTH_JWKS_URI=<jwks-resolvido-no-deploy>
MP_JWT_VERIFY_PUBLICKEY_LOCATION=<jwks-ou-arquivo-montado>
```

Audience JWT canônica por microsserviço:

```text
oficina-os-service
oficina-billing-service
oficina-execution-service
```

Cada microsserviço deve configurar `OFICINA_AUTH_AUDIENCE` com o próprio nome canônico. O valor `oficina-app` é legado e deve continuar apenas como referência histórica para o backend monolítico atual.

### Lambda de autenticação e notificações

Nomes canônicos já usados:

```text
OFICINA_AUTH_LAMBDA_NAME=oficina-auth-lambda
OFICINA_NOTIFICACAO_LAMBDA_NAME=oficina-notificacao-lambda
OFICINA_AUTH_LAMBDA_FUNCTION_NAME=oficina-auth-lambda-lab
OFICINA_NOTIFICACAO_LAMBDA_FUNCTION_NAME=oficina-notificacao-lambda-lab
```

Secrets e artefatos:

```text
AUTH_DB_SECRET_NAME=oficina/lab/database/auth-lambda
OFICINA_AUTH_DB_SECRET_ID=oficina/lab/database/auth-lambda
OFICINA_AUTH_LAMBDA_ARTIFACT_PREFIX=oficina/lab/lambda/oficina-auth-lambda
OFICINA_NOTIFICACAO_LAMBDA_ARTIFACT_PREFIX=oficina/lab/lambda/oficina-notificacao-lambda
```

### PostgreSQL legado e transição Fase 4

Valores encontrados nos repositórios de infraestrutura legados:

```text
DB_IDENTIFIER=oficina-postgres-lab
DB_NAME=app
DB_USERNAME=oficina_master
APP_DB_USER=oficina_app
DB_SSLMODE=require
APP_SECRET_NAME=oficina/lab/database/app
OFICINA_DB_APP_SECRET_ID=oficina/lab/database/app
```

Esses valores descrevem o modelo atual/legado. Para a Fase 4, a decisão canônica continua sendo uma instância RDS PostgreSQL compartilhada com databases, usuários, secrets e migrations isolados para `oficina-os-service` e `oficina-billing-service`, conforme [ROADMAP.md](../ROADMAP.md), [Conta, região e ambientes AWS](aws-environments.md) e [Padrão de isolamento PostgreSQL no RDS compartilhado](rds-postgresql-isolation.md).

Valores canônicos da Fase 4:

```text
DB_IDENTIFIER=oficina-postgres-lab

OFICINA_OS_DB_NAME=oficina_os
OFICINA_OS_DB_USER=oficina_os_user
OFICINA_OS_DB_SECRET_ID=oficina/lab/database/oficina-os-service

OFICINA_BILLING_DB_NAME=oficina_billing
OFICINA_BILLING_DB_USER=oficina_billing_user
OFICINA_BILLING_DB_SECRET_ID=oficina/lab/database/oficina-billing-service
```

### DynamoDB do oficina-execution-service

Valor já presente no template Quarkus deste repositório:

```text
OFICINA_DYNAMODB_TABLE_PREFIX=oficina-execution-lab
```

Variáveis já previstas para runtime local e testes:

```text
AWS_REGION=us-east-1
DYNAMODB_ENDPOINT_OVERRIDE=http://localhost:8000
```

Uso esperado:

- `AWS_REGION` aponta para DynamoDB gerenciado na AWS em runtime real.
- `DYNAMODB_ENDPOINT_OVERRIDE` deve ser usado apenas em `dev` e `test`.
- `OFICINA_DYNAMODB_TABLE_PREFIX` deve prefixar tabelas próprias do `oficina-execution-service`.

Tabelas canônicas:

```text
oficina-execution-lab-catalogo
oficina-execution-lab-estoque
oficina-execution-lab-execucoes
oficina-execution-lab-outbox
oficina-execution-lab-idempotencia
```

Responsabilidades:

- `catalogo`: peças e serviços técnicos.
- `estoque`: saldo, reservas e movimentos.
- `execucoes`: execução, diagnóstico, reparo e histórico operacional.
- `outbox`: eventos produzidos pelo serviço antes da publicação.
- `idempotencia`: controle de comandos REST, Saga e consumidores de eventos.

Variáveis runtime canônicas:

```text
OFICINA_DYNAMODB_TABLE_PREFIX=oficina-execution-lab
OFICINA_DYNAMODB_CATALOGO_TABLE=oficina-execution-lab-catalogo
OFICINA_DYNAMODB_ESTOQUE_TABLE=oficina-execution-lab-estoque
OFICINA_DYNAMODB_EXECUCOES_TABLE=oficina-execution-lab-execucoes
OFICINA_DYNAMODB_OUTBOX_TABLE=oficina-execution-lab-outbox
OFICINA_DYNAMODB_IDEMPOTENCIA_TABLE=oficina-execution-lab-idempotencia
```

`OFICINA_DYNAMODB_TABLE_PREFIX` é a configuração principal. Os nomes individuais permitem override operacional quando for necessário isolar testes, migrações, restaurações ou ambientes temporários sem alterar código.

Variáveis canônicas de infraestrutura para GitHub Actions/Terraform do novo `oficina-infra`:

```text
EXECUTION_DYNAMODB_TABLE_PREFIX=oficina-execution-lab
EXECUTION_DYNAMODB_BILLING_MODE=PAY_PER_REQUEST
EXECUTION_DYNAMODB_POINT_IN_TIME_RECOVERY_ENABLED=true
EXECUTION_DYNAMODB_STREAM_VIEW_TYPE=NEW_AND_OLD_IMAGES
EXECUTION_DYNAMODB_DELETION_PROTECTION_ENABLED=false
```

Termos:

- `EXECUTION_DYNAMODB_TABLE_PREFIX`: prefixo usado pelo Terraform para nomear todas as tabelas do `oficina-execution-service`.
- `EXECUTION_DYNAMODB_BILLING_MODE`: modo de cobrança/capacidade do DynamoDB.
- `PAY_PER_REQUEST`: cobrança sob demanda; não exige configurar capacidade de leitura/escrita e é adequado para carga variável ou ambiente `lab`.
- `EXECUTION_DYNAMODB_POINT_IN_TIME_RECOVERY_ENABLED`: liga Point-in-Time Recovery, permitindo restaurar uma tabela para um momento recente dentro da janela suportada pelo DynamoDB.
- `EXECUTION_DYNAMODB_STREAM_VIEW_TYPE`: define quais dados aparecem no DynamoDB Streams quando um item muda.
- `NEW_AND_OLD_IMAGES`: cada evento de stream carrega a versão anterior e a nova versão do item, útil para auditoria, publicação de eventos e depuração.
- `EXECUTION_DYNAMODB_DELETION_PROTECTION_ENABLED`: impede exclusão acidental da tabela quando habilitado.

Impacto prático:

- `PAY_PER_REQUEST` reduz configuração e risco de throttling por capacidade mal dimensionada no laboratório.
- Point-in-Time Recovery aumenta segurança operacional, com possível custo adicional.
- Streams com `NEW_AND_OLD_IMAGES` facilitam outbox, auditoria e integrações futuras, aumentando o volume de dados processados.
- Deletion protection `false` facilita teardown do ambiente `lab`; em ambiente permanente, o valor deveria ser `true`.

### Kubernetes dos microsserviços

Nomes canônicos:

```text
Kubernetes Deployment: oficina-os-service
Kubernetes Service: oficina-os-service
Kubernetes ServiceAccount: oficina-os-service
ConfigMap: oficina-os-service-config
Kubernetes database secret: oficina-os-service-database-env

Kubernetes Deployment: oficina-billing-service
Kubernetes Service: oficina-billing-service
Kubernetes ServiceAccount: oficina-billing-service
ConfigMap: oficina-billing-service-config
Kubernetes database secret: oficina-billing-service-database-env

Kubernetes Deployment: oficina-execution-service
Kubernetes Service: oficina-execution-service
Kubernetes ServiceAccount: oficina-execution-service
ConfigMap: oficina-execution-service-config
```

Os manifests base ficam em [Template Kubernetes Base](../templates/kubernetes/base/README.md).

O nome completo dos microsserviços deve ser preservado nos recursos Kubernetes. Secrets Kubernetes materializados no cluster usam nomes sem ambiente quando já estão isolados pelo cluster/namespace. O `oficina-execution-service` não usa secret de banco PostgreSQL.

### IAM do oficina-execution-service

Nomes canônicos:

```text
IAM role: oficina-execution-service-lab
IAM policy: oficina-execution-service-lab-dynamodb
```

O sufixo `lab` deve ser usado em recursos AWS globais ou regionais do ambiente de laboratório.

### State Terraform do novo oficina-infra

Chave canônica durante a transição para o repositório unificado:

```text
oficina/lab/infra/terraform.tfstate
```

Essa key evita colisão com os states legados:

```text
oficina/lab/terraform.tfstate
oficina/lab/database/terraform.tfstate
```

Após a substituição integral de `oficina-infra-k8s` e `oficina-infra-db`, a suíte pode avaliar uma migração de state para simplificar o nome.

---

## Padrões de infraestrutura fechados

- O ambiente lógico canônico é `lab`.
- O deploy de infraestrutura opera com AWS credentials temporárias armazenadas como secrets do repositório ou da organização.
- O state remoto Terraform usa S3, com lock DynamoDB opcional via `TF_STATE_DYNAMODB_TABLE`.
- O bucket de state é compartilhado por escopo, mas cada repositório usa sua própria key.
- Secrets runtime compartilhados ficam no AWS Secrets Manager sob `oficina/lab/...`.
- Secrets Kubernetes materializados no cluster usam nomes sem ambiente quando já estão isolados pelo cluster/namespace, como `oficina-database-env` e `oficina-jwt-keys`.
- O novo `oficina-infra` deve substituir a divisão `oficina-infra-db` + `oficina-infra-k8s`, preservando os nomes canônicos acima.

---

## Sugestões pendentes de avaliação

Não há pendências de avaliação neste escopo após a decisão sobre as variáveis de infraestrutura DynamoDB.
