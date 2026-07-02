# Template GitHub Actions para Microsserviços

## Objetivo

Template padrão de CI/CD para os repositórios:

- `oficina-os-service`
- `oficina-billing-service`
- `oficina-execution-service`

Este template implementa a [ADR-012 - Estratégia de CI/CD e Deploy Independente](../../adr/ADR-012%20-%20Estratégia%20de%20CI%20CD%20e%20Deploy%20Independente.md), usando GitHub Actions, SonarCloud, Amazon ECR, Amazon EKS e o ambiente canônico `lab` definido em [Conta, região e ambientes AWS](../../docs/aws-environments.md) e [Nomes de runtime, secrets e infraestrutura](../../docs/infra-runtime-naming.md).

## Como usar

Copiar os workflows deste diretório para o repositório do microsserviço destino em:

```text
.github/workflows/service-ci.yml
.github/workflows/open-pr-to-main.yml
```

O workflow assume que o repositório usa o [Template Quarkus de Microsserviço](../quarkus-service/README.md), incluindo o [Dockerfile](../quarkus-service/Dockerfile), e que o deployment Kubernetes segue o [Template Kubernetes Base](../kubernetes/base/README.md).

O repositório destino deve possuir Maven Wrapper (`mvnw` e `.mvn/wrapper/`), seguindo o mesmo fluxo do `oficina-app`.

## Variáveis e secrets

Secrets obrigatórios no GitHub Environment `lab`:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_SESSION_TOKEN
```

Secret obrigatório para Quality Gate no SonarCloud:

```text
SONAR_TOKEN
```

O workflow falha quando `SONAR_TOKEN`, `SONAR_ORGANIZATION` ou `SONAR_PROJECT_KEY` não estiverem configurados. Essa validação é obrigatória para atender ao enunciado da Fase 4 e à [ADR-012 - Estratégia de CI/CD e Deploy Independente](../../adr/ADR-012%20-%20Estratégia%20de%20CI%20CD%20e%20Deploy%20Independente.md).

Variáveis recomendadas no GitHub Environment `lab`:

```text
AWS_REGION=us-east-1
EKS_CLUSTER_NAME=eks-lab
K8S_NAMESPACE=default
```

Variáveis opcionais por repositório:

```text
SERVICE_NAME=<nome-canonico-do-microsservico>
MAVEN_PROFILE=postgresql|dynamodb
ECR_REPOSITORY_NAME=<nome-do-repositorio-ecr>
SONAR_ORGANIZATION=<organizacao-sonarcloud>
SONAR_PROJECT_KEY=<project-key-sonarcloud>
ENABLE_IMAGE_PUBLISH=false|true
ENABLE_K8S_DEPLOY=false|true
```

Quando `SERVICE_NAME` não for informado, o workflow deriva o nome do repositório GitHub. Para os três microsserviços canônicos, esse valor deve coincidir com `oficina-os-service`, `oficina-billing-service` ou `oficina-execution-service`.

As variáveis `ENABLE_IMAGE_PUBLISH` e `ENABLE_K8S_DEPLOY` controlam a separação entre CI obrigatório e entrega em AWS:

- com ambas desabilitadas, pull requests e pushes na `main` executam build Maven, testes, JaCoCo, validação de cobertura mínima e Quality Gate, sem acessar ECR ou EKS;
- com `ENABLE_IMAGE_PUBLISH=true`, o push na `main` também consulta ECR, publica a imagem Docker quando necessário e cria release com metadados da imagem;
- com `ENABLE_K8S_DEPLOY=true`, o push na `main` também consulta o Deployment no EKS e atualiza a imagem quando houver diferença;
- em `workflow_dispatch`, os inputs `publish_image` e `deploy` permitem acionar manualmente publicação ou deploy mesmo com as variáveis desabilitadas.

Enquanto a estratégia definitiva de manifestos Kubernetes por microsserviço estiver aberta, mantenha `ENABLE_K8S_DEPLOY=false`. O job de deploy deve ser habilitado somente quando os Deployments, containers, namespace, credenciais AWS e fonte canônica dos manifestos estiverem definidos no `oficina-infra` ou documentados no repositório do serviço.

## Fluxo

Pull Requests executam:

- build Maven;
- testes unitários, integração, contrato e BDD;
- relatório JaCoCo com cobertura mínima de 80%;
- análise SonarCloud com Quality Gate obrigatório.

O job obrigatório para proteção da branch `main` chama-se `service-ci-validate`, conforme a política em [Proteção da branch main dos microsserviços](../../docs/github-branch-protection.md).

O comportamento esperado para BDD, cobertura e evidências de qualidade está definido em [Padrão BDD, Cobertura e Qualidade](../../docs/bdd-testing.md).

Merges na `main` podem executar também, quando as variáveis de habilitação estiverem configuradas:

- consulta do estado atual no ECR, GitHub Releases e Kubernetes;
- build da imagem Docker apenas quando a tag de `project.version` ainda não existir;
- push para Amazon ECR;
- criação de GitHub Release com metadados da imagem;
- atualização da imagem no `Deployment` Kubernetes do serviço;
- validação do rollout no Amazon EKS.

O fluxo preserva o padrão do `oficina-app`: a imagem publicada usa a tag de `project.version`; versões `SNAPSHOT` não podem ser publicadas na `main`; e uma mudança publicável em `main` deve incrementar `project.version` quando exigir nova imagem ou release.

## Limites

- O workflow não cria ECR, cluster EKS, secrets, service accounts, roles IAM ou manifests Kubernetes.
- O provisionamento desses recursos pertence ao repositório `oficina-infra`, conforme [Escopo do Repositório Unificado de Infraestrutura](../../docs/infrastructure-repository-scope.md).
- O workflow não substitui as políticas de proteção da branch `main`; elas devem ser configuradas no GitHub.
