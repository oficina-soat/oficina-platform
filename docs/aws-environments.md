# Conta, regiao e ambientes AWS

Este documento define os valores canonicos de conta, regiao e ambientes AWS da suite da oficina para a Fase 4.

Os valores abaixo foram consolidados a partir dos repositórios já existentes da suite, especialmente `oficina-infra-k8s`, `oficina-infra-db`, `oficina-app` e `oficina-auth-lambda`.

Os nomes detalhados de runtime, secrets, variáveis e padrões de infraestrutura estão consolidados em [infra-runtime-naming.md](infra-runtime-naming.md).

---

## Conta AWS

A conta AWS nao deve ser tratada como valor canonico fixo da arquitetura. Em ambientes academicos e laboratoriais, o numero da conta pode mudar entre execucoes, turmas ou credenciais temporarias.

O valor deve ser resolvido em tempo de deploy por:

```text
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
```

Variavel padronizada:

```text
AWS_ACCOUNT_ID=<aws-account-id>
```

ARNs, buckets e referencias IAM devem ser parametrizados com `<aws-account-id>`:

```text
arn:aws:iam::<aws-account-id>:role/<lab-eks-cluster-role>
arn:aws:iam::<aws-account-id>:role/<lab-eks-node-role>
arn:aws:iam::<aws-account-id>:role/voclabs
```

Valores numericos de conta encontrados em repositórios antigos devem ser tratados como exemplos ou legados locais. Novos artefatos nao devem depender de uma conta AWS hardcoded.

---

## Regiao AWS canonica

A regiao AWS canonica da suite é:

```text
us-east-1
```

Variáveis padronizadas:

```text
AWS_REGION=us-east-1
AWS_DEFAULT_REGION=us-east-1
TF_STATE_REGION=us-east-1
```

Novos repositórios, pipelines, scripts e manifests devem usar `us-east-1`, salvo decisão arquitetural posterior registrada em ADR.

---

## Ambiente AWS canonico

Para a Fase 4, será mantido um único ambiente AWS principal:

```text
lab
```

Esse ambiente é usado por:

- GitHub Actions environments;
- Terraform environment directories;
- Kubernetes overlays;
- nomes de secrets;
- nomes de artefatos;
- atributos de observabilidade.

Valores padronizados:

```text
DEPLOYMENT_ENVIRONMENT=lab
deployment.environment=lab
OFICINA_ENVIRONMENT_NAME=lab
```

A criação de ambientes AWS adicionais, como `dev`, `staging`, `homolog` ou `prod`, não faz parte do escopo atual da Fase 4.

---

## Infraestrutura compartilhada

Nome canonico da infraestrutura compartilhada:

```text
eks-lab
```

Valores relacionados:

```text
EKS_CLUSTER_NAME=eks-lab
SHARED_INFRA_NAME=eks-lab
cluster_name=eks-lab
shared_infra_name=eks-lab
```

Recursos derivados:

```text
VPC: eks-lab-vpc
HTTP API Gateway: eks-lab-http-api
Terraform shared bucket: tf-shared-eks-lab-<aws-account-id>-us-east-1
```

---

## State remoto Terraform

Bucket compartilhado canonico:

```text
tf-shared-eks-lab-<aws-account-id>-us-east-1
```

Chaves de state usadas por escopo:

```text
Infraestrutura Kubernetes:
oficina/lab/terraform.tfstate

Infraestrutura de banco:
oficina/lab/database/terraform.tfstate
```

Variáveis padronizadas:

```text
TF_STATE_BUCKET=tf-shared-eks-lab-<aws-account-id>-us-east-1
TERRAFORM_SHARED_DATA_BUCKET_NAME=tf-shared-eks-lab-<aws-account-id>-us-east-1
TF_STATE_REGION=us-east-1
```

---

## Nomes de recursos existentes

Banco PostgreSQL RDS:

```text
DB_IDENTIFIER=oficina-postgres-lab
```

Para a Fase 4, esse RDS deve ser ajustado para o padrão definido no roadmap: uma instância PostgreSQL compartilhada com databases independentes para `oficina-os-service` e `oficina-billing-service`.

Lambdas:

```text
AUTH_LAMBDA_FUNCTION_NAME=oficina-auth-lambda-lab
NOTIFICACAO_LAMBDA_FUNCTION_NAME=oficina-notificacao-lambda-lab
```

Artefatos Lambda:

```text
AUTH_LAMBDA_ARTIFACT_PREFIX=oficina/lab/lambda/oficina-auth-lambda
NOTIFICACAO_LAMBDA_ARTIFACT_PREFIX=oficina/lab/lambda/oficina-notificacao-lambda
```

Secrets já usados:

```text
K8S_DATABASE_SECRET_ID=oficina/lab/database/app
K8S_JWT_SECRET_ID=oficina/lab/jwt
APP_SECRET_NAME=oficina/lab/database/app
```

---

## Pendencias de normalizacao

Antes de evoluir o novo repositório unificado de infraestrutura, revisar e normalizar os seguintes pontos encontrados nos repositórios antigos:

- Remover ou parametrizar contas AWS hardcoded em ARNs, nomes de buckets e exemplos de Terraform.
- Normalizar qualquer ocorrência local de `simple-eks` para `eks-lab`, quando o valor representar o cluster EKS da suite.
- Atualizar contratos de secrets de banco para refletir a separação futura entre `oficina_os` e `oficina_billing`.
- Garantir que os três microsserviços novos usem `DEPLOYMENT_ENVIRONMENT=lab` e `deployment.environment=lab` em logs, métricas e traces.

Essas pendências não mudam a decisão canonica deste documento; elas apenas registram ajustes necessários nos repositórios que ainda carregam valores históricos.
