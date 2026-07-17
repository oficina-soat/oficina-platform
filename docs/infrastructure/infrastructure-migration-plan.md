# Plano de migração para o repositório unificado de infraestrutura

## Objetivo

Definir como copiar, selecionar e adaptar artefatos de `oficina-app`, `oficina-infra-db` e `oficina-infra-k8s` para o repositório unificado `oficina-infra` e para os repositórios dos microsserviços, preservando a governança definida em [Escopo do Repositório Unificado de Infraestrutura](infrastructure-repository-scope.md) e no [Plano de Decomposição do oficina-app](../architecture/oficina-app-decomposition.md).

Este plano não altera `oficina-app`, `oficina-infra-db` ou `oficina-infra-k8s`. Esses repositórios devem ser usados apenas como fonte de consulta e cópia controlada; adaptações devem acontecer nos repositórios de destino.

O `oficina-auth-lambda` é exceção a essa regra: quando ajustes forem necessários nos fluxos de autenticação, sincronização do cadastro operacional ou notificações, eles devem ser feitos diretamente no próprio repositório `oficina-auth-lambda`, pois ele continua sendo componente serverless ativo da suíte.

## Fontes de cópia

| Repositório | Uso na migração | Regra de alteração |
|---|---|---|
| `../oficina-app` | Copiar ou consultar código, testes, seeds, contratos práticos e referências funcionais para decomposição nos três microsserviços. | Não alterar durante a decomposição; adaptar apenas nos repositórios de destino. |
| `../oficina-infra-db` | Copiar padrões de RDS, bootstrap de banco, secrets, scripts de migração operacional e workflows úteis. | Não alterar durante a consolidação; adaptar apenas no `oficina-infra`. |
| `../oficina-infra-k8s` | Copiar padrões de EKS, ECR, API Gateway, Kubernetes, scripts operacionais, workflows e observabilidade já validada. | Não alterar durante a consolidação; adaptar apenas no `oficina-infra`. |
| `../oficina-auth-lambda` | Consultar nomes, issuer, JWKS, secrets, artefatos e integrações de autenticação, sincronização e notificação. | Pode ser alterado diretamente quando a mudança pertencer ao componente serverless. |

O destino canônico dos artefatos de infraestrutura é sempre `../oficina-infra`. O destino canônico de código de domínio copiado do `oficina-app` são os repositórios `../oficina-os-service`, `../oficina-billing-service` e `../oficina-execution-service`, conforme ownership.

## Princípios

- Copiar primeiro, adaptar depois, dentro do `oficina-infra`.
- Não corrigir `oficina-app`, `oficina-infra-db` ou `oficina-infra-k8s` durante a migração.
- Ajustar `oficina-auth-lambda` diretamente quando a mudança for necessária para autenticação, sincronização ou notificações.
- Não promover valores históricos para contrato novo.
- Parametrizar conta AWS com `AWS_ACCOUNT_ID` ou resolução por `aws sts get-caller-identity`, conforme [Conta, região e ambientes AWS](aws-environments.md).
- Preservar `us-east-1`, `lab`, `eks-lab` e os nomes definidos em [Nomes de runtime, secrets e infraestrutura](infra-runtime-naming.md).
- Separar artefatos legados do `oficina-app` dos artefatos dos microsserviços `oficina-os-service`, `oficina-billing-service` e `oficina-execution-service`.

## Fases

### 1. Inventário inicial

Levantar, sem alterar os repositórios de origem:

| Origem | Artefatos a inventariar |
|---|---|
| `oficina-app` | código de domínio, controllers, testes, `import.sql`, configurações e integrações que sirvam de referência para decomposição. |
| `oficina-infra-db` | módulos Terraform de RDS, scripts de bootstrap, criação de secrets, workflows `deploy`/`destroy`, documentação de state e comandos manuais. |
| `oficina-infra-k8s` | módulos Terraform de EKS/ECR/API Gateway, manifests Kubernetes compartilhados, scripts de deploy e limpeza, workflows, observabilidade e exemplos de publicação. |
| `oficina-auth-lambda` | nomes de funções, secrets, issuer, JWKS, artefatos e contratos de integração usados pela autenticação, sincronização e notificações. |

Critério de pronto:

- Lista de arquivos candidatos registrada no `oficina-infra`.
- Cada candidato classificado como `copiar`, `adaptar`, `legado` ou `descartar`.
- Candidatos do `oficina-app` classificados por microsserviço destino ou por descarte.
- Ajustes necessários no `oficina-auth-lambda` separados dos artefatos que serão apenas consultados.

### 2. Estrutura base do `oficina-infra`

Criar ou normalizar a estrutura definida em [Escopo do Repositório Unificado de Infraestrutura](infrastructure-repository-scope.md):

```text
terraform/
  modules/
  environments/lab/
k8s/
  base/
  overlays/lab/
scripts/
  actions/
  lib/
  manual/
.github/workflows/
docs/
```

Critério de pronto:

- O repositório possui diretórios de destino antes da cópia dos artefatos.
- O state remoto usa a key `oficina/lab/infra/terraform.tfstate`.

### 3. Migração do RDS PostgreSQL

Copiar e adaptar a base de `oficina-infra-db` para provisionar a instância `oficina-postgres-lab` com isolamento lógico por microsserviço.

O resultado deve seguir o [Padrão de isolamento PostgreSQL no RDS compartilhado](rds-postgresql-isolation.md):

| Serviço | Database | Usuário | Secret AWS |
|---|---|---|---|
| `oficina-os-service` | `oficina_os` | `oficina_os_user` | `oficina/lab/database/oficina-os-service` |
| `oficina-billing-service` | `oficina_billing` | `oficina_billing_user` | `oficina/lab/database/oficina-billing-service` |

Critério de pronto:

- O bootstrap cria databases, usuários, permissões e secrets independentes.
- O secret legado `oficina/lab/database/app` não é usado por workloads novos.
- Migrations de domínio permanecem nos repositórios dos microsserviços.

### 4. Migração do EKS, ECR e Kubernetes compartilhado

Copiar e adaptar a base de `oficina-infra-k8s` para manter o cluster `eks-lab`, repositórios ECR, integração com Kubernetes e recursos compartilhados.

Critério de pronto:

- Os recursos seguem `lab`, `us-east-1` e `eks-lab`.
- ARNs e buckets não fixam conta AWS.
- Artefatos do `oficina-app` ficam marcados como legado ou isolados de padrões novos.
- O cluster permite deploy independente dos três microsserviços.

### 5. Migração de DynamoDB e mensageria

Adicionar ao `oficina-infra` os recursos que não existiam nos repositórios legados ou que precisam ser criados para a arquitetura atual:

- tabelas DynamoDB do `oficina-execution-service`, conforme [Padrão DynamoDB do oficina-execution-service](dynamodb-execution-service.md);
- tópicos, filas, assinaturas e DLQs conforme o [Contrato de Tópicos de Mensageria](../../contracts/Contrato%20de%20Tópicos%20de%20Mensageria.md);
- permissões IAM mínimas para produtores, consumidores e workloads Kubernetes.

Critério de pronto:

- Tabelas usam prefixo `oficina-execution-lab`.
- Todo tópico fundamental possui DLQ compatível com a convenção `<topico>.dlq`.
- Permissões separam produtores e consumidores por serviço.

### 6. Migração de workflows e scripts

Copiar workflows e scripts úteis dos repositórios antigos, adaptando nomes e variáveis para os padrões atuais.

Critério de pronto:

- Workflows não declaram GitHub Environment para evitar aprovações manuais.
- Credenciais AWS vêm de secrets do repositório ou da organização, sem valores fixos.
- Scripts possuem validação de shell.
- Comandos de deploy, destroy, plan e validação estão documentados no `README.md` do `oficina-infra`.

## Checklist anti-legado

Antes de aceitar um artefato copiado no `oficina-infra`, procurar e normalizar:

| Valor legado | Tratamento no `oficina-infra` |
|---|---|
| Conta AWS numérica em ARN ou bucket | Parametrizar com conta resolvida em runtime. |
| `simple-eks` | Substituir por `eks-lab` quando representar a infraestrutura compartilhada. |
| `oficina-app` | Manter apenas em seção legada ou substituir pelo microsserviço dono. |
| `app` como database | Substituir por `oficina_os` ou `oficina_billing` conforme ownership. |
| `oficina/lab/database/app` | Manter apenas como referência histórica; novos serviços usam secrets próprios. |
| `oficina-database-env` | Manter apenas para legado; novos serviços usam secrets Kubernetes próprios. |

## Ordem recomendada de implementação

1. Estrutura base e state remoto do `oficina-infra`.
2. RDS compartilhado com isolamento de `oficina_os` e `oficina_billing`.
3. EKS/ECR/API Gateway compartilhados.
4. DynamoDB do `oficina-execution-service`.
5. Mensageria, filas, DLQs e permissões.
6. Workflows e scripts operacionais.
7. Documentação de validação, deploy e destroy.

## Validações esperadas no `oficina-infra`

Quando os artefatos forem copiados e adaptados no repositório de destino, executar validações compatíveis com o escopo:

```bash
terraform fmt -check -recursive terraform
terraform -chdir=terraform/environments/lab init -backend=false
terraform -chdir=terraform/environments/lab validate
kubectl kustomize k8s/overlays/lab
find scripts -type f -name '*.sh' -print0 | xargs -0 bash -n
```

Também deve ser feita revisão anti-divergência contra [Nomes de runtime, secrets e infraestrutura](infra-runtime-naming.md), [Conta, região e ambientes AWS](aws-environments.md), [Padrão de isolamento PostgreSQL no RDS compartilhado](rds-postgresql-isolation.md) e [Escopo do Repositório Unificado de Infraestrutura](infrastructure-repository-scope.md).
