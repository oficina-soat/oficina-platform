# Conta, regiao e ambientes AWS

Este documento define os valores canonicos de conta, regiao e ambientes AWS da suite da oficina para a Fase 4.

Os valores abaixo foram consolidados a partir dos repositórios já existentes da suite, especialmente `oficina-infra-k8s`, `oficina-infra-db`, `oficina-app` e `oficina-auth-lambda`.

---

## Conta AWS canonica

Para a Fase 4, a conta AWS canonica da suite é:

```text
415459106622
```

Essa conta aparece nos ARNs de laboratório usados pelos manifests e exemplos de Terraform da infraestrutura Kubernetes.

Exemplos de roles já usadas:

```text
arn:aws:iam::415459106622:role/c207442a5275926l14475550t1w415459-LabEksClusterRole-ZJrT0UsVDXGR
arn:aws:iam::415459106622:role/c207442a5275926l14475550t1w415459106-LabEksNodeRole-o7WajVdYdjUf
arn:aws:iam::415459106622:role/voclabs
```

Qualquer valor antigo apontando para outra conta deve ser tratado como legado e normalizado antes de novos deployments.

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
Terraform shared bucket: tf-shared-eks-lab-415459106622-us-east-1
```

---

## State remoto Terraform

Bucket compartilhado canonico:

```text
tf-shared-eks-lab-415459106622-us-east-1
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
TF_STATE_BUCKET=tf-shared-eks-lab-415459106622-us-east-1
TERRAFORM_SHARED_DATA_BUCKET_NAME=tf-shared-eks-lab-415459106622-us-east-1
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

- Remover ou substituir defaults antigos de IAM roles que apontem para conta diferente de `415459106622`.
- Normalizar qualquer ocorrência local de `simple-eks` para `eks-lab`, quando o valor representar o cluster EKS da suite.
- Atualizar contratos de secrets de banco para refletir a separação futura entre `oficina_os` e `oficina_billing`.
- Garantir que os três microsserviços novos usem `DEPLOYMENT_ENVIRONMENT=lab` e `deployment.environment=lab` em logs, métricas e traces.

Essas pendências não mudam a decisão canonica deste documento; elas apenas registram ajustes necessários nos repositórios que ainda carregam valores históricos.
