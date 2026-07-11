# Template GitHub Actions para Microsserviços

## Objetivo

Template padrão de CI/CD para os repositórios:

- `oficina-os-service`
- `oficina-billing-service`
- `oficina-execution-service`

Este template implementa a [ADR-012 - Estratégia de CI/CD e Deploy Independente](../../adr/ADR-012%20-%20Estratégia%20de%20CI%20CD%20e%20Deploy%20Independente.md), usando GitHub Actions, SonarCloud Automatic Analysis, Amazon ECR, Amazon EKS e o ambiente canônico `lab` definido em [Conta, região e ambientes AWS](../../docs/aws-environments.md) e [Nomes de runtime, secrets e infraestrutura](../../docs/infra-runtime-naming.md).

## Como usar

Copiar os workflows deste diretório para o repositório do microsserviço destino em:

```text
.github/workflows/service-ci.yml
.github/workflows/open-pr-to-main.yml
```

O workflow assume que o repositório usa o [Template Quarkus de Microsserviço](../quarkus-service/README.md), incluindo o [Dockerfile](../quarkus-service/Dockerfile), e que o deployment Kubernetes segue o [Template Kubernetes Base](../kubernetes/base/README.md).

O repositório destino deve possuir Maven Wrapper (`mvnw` e `.mvn/wrapper/`), seguindo o mesmo fluxo do `oficina-app`.

## Variáveis e secrets

Secrets obrigatórios no repositório ou na organização GitHub:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_SESSION_TOKEN
```

O workflow não executa `sonar:sonar` nem exige secrets `SONAR_*`. A análise SonarCloud deve ser configurada fora do GitHub Actions, usando Automatic Analysis no projeto SonarCloud ou integração equivalente definida no próprio Sonar. Quando o Quality Gate for usado como evidência, trate o status emitido pelo SonarCloud como check externo ou registre a evidência no checklist da entrega.

Variáveis recomendadas no repositório ou na organização GitHub:

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
ENABLE_IMAGE_PUBLISH=true|false
ENABLE_K8S_DEPLOY=true|false
INFRA_REPOSITORY=oficina-soat/oficina-infra
INFRA_REF=main
API_GATEWAY_NAME=eks-lab-http-api
```

Quando `SERVICE_NAME` não for informado, o workflow deriva o nome do repositório GitHub. Para os três microsserviços canônicos, esse valor deve coincidir com `oficina-os-service`, `oficina-billing-service` ou `oficina-execution-service`.

As variáveis `ENABLE_IMAGE_PUBLISH` e `ENABLE_K8S_DEPLOY` controlam a separação entre CI obrigatório e entrega em AWS. Quando não são definidas, ambas assumem `true` no workflow:

- em PR para `main`, sempre roda validação Maven, testes, cobertura e contratos;
- em push na `main`, o workflow consulta ECR, publica a imagem Docker quando necessário, cria release com metadados da imagem, materializa ou atualiza o Deployment do serviço no EKS e valida o rollout;
- com `ENABLE_IMAGE_PUBLISH=false`, a publicação de imagem/release fica desabilitada;
- com `ENABLE_K8S_DEPLOY=false`, a materialização ou atualização do Deployment no EKS fica desabilitada;
- em `workflow_dispatch`, os inputs `publish_image` e `deploy` permitem forçar manualmente publicação ou deploy mesmo com as variáveis desabilitadas.

O workflow não declara GitHub Environment para evitar aprovações manuais nos jobs. Em trabalhos acadêmicos, o ponto de controle manual é o merge do PR para `main`: pushes em `develop` abrem ou atualizam automaticamente o PR, e a entrega em AWS só roda depois que esse PR é aceito.

Antes de manter o deploy automático ativo, confirme que EKS, ECR, namespace, credenciais AWS e fonte canônica dos manifests estão definidos no `oficina-infra`. O workflow do serviço faz checkout do `oficina-infra`, chama `scripts/manual/apply-microservices.sh` apenas para o próprio serviço e usa a imagem exata publicada pelo workflow.

## Fluxo

Pull Requests executam:

- validação de `project.version` para mudanças publicáveis, rejeitando versão `SNAPSHOT` ou menor ou igual à base do PR;
- build Maven;
- testes unitários, integração, contrato e BDD;
- relatório JaCoCo com cobertura mínima de 80%.

O job obrigatório para proteção da branch `main` chama-se `service-ci-validate`, conforme a política em [Proteção da branch main dos microsserviços](../../docs/github-branch-protection.md).

Pushes na branch `develop` executam o workflow auxiliar `open-pr-to-main.yml`, que valida build Maven, testes e contratos antes de criar ou atualizar o PR para `main`. Nenhum workflow deste template aciona análise SonarCloud; o projeto SonarCloud deve usar Automatic Analysis ou integração externa própria.

O workflow auxiliar pode preparar PR com `project.version` em `SNAPSHOT`, porque ele não publica imagem, release ou deploy. O PR para `main` e o fluxo de publicação/deploy da `main` bloqueiam mudanças publicáveis com versão `SNAPSHOT`, menor ou igual à base do PR, ou repetida em relação ao commit anterior da `main`.

O comportamento esperado para BDD, cobertura e evidências de qualidade está definido em [Padrão BDD, Cobertura e Qualidade](../../docs/bdd-testing.md).

Merges na `main` executam também, salvo opt-out explícito por variável:

- consulta do estado atual no ECR, GitHub Releases e Kubernetes;
- bloqueio de alteração publicável quando `project.version` não foi incrementado no push da `main`;
- build da imagem Docker apenas quando a tag de `project.version` ainda não existir;
- push para Amazon ECR;
- criação de GitHub Release com metadados da imagem;
- materialização inicial ou atualização do `Deployment` Kubernetes do serviço;
- validação do rollout no Amazon EKS e conferência da imagem final do container.

Quando `ENABLE_K8S_DEPLOY` não é `false` e o `Deployment` do serviço ainda não existir no cluster, o workflow usa o manifest canônico do `oficina-infra` para criar o recurso, aguarda `rollout status` e falha se o pod não ficar disponível ou se a imagem aplicada for diferente da imagem publicada.

O fluxo preserva o padrão do `oficina-app`: a imagem publicada usa a tag de `project.version`; versões `SNAPSHOT` não podem ser publicadas nem implantadas pela `main`; e toda mudança publicável deve incrementar `project.version` para uma versão SemVer fechada `MAJOR.MINOR.PATCH`, maior que a base e ainda não usada para outro build, release ou rollout.

Antes de usar publicação de imagem ou deploy Kubernetes como evidência da Fase 4, use o [Checklist de Deploy Independente](../../docs/independent-deploy-checklist.md) para validar pré-condições, rollout, smoke test, rollback e registro de evidências.

## Limites

- O workflow não cria ECR, cluster EKS, roles IAM nem manifests Kubernetes canônicos.
- O provisionamento de infraestrutura base pertence ao repositório `oficina-infra`, conforme [Escopo do Repositório Unificado de Infraestrutura](../../docs/infrastructure-repository-scope.md).
- O workflow pode criar ou atualizar recursos Kubernetes runtime do próprio serviço, como Deployment, Service, ServiceAccount, ConfigMap e secrets derivados dos secrets AWS, sempre a partir dos manifests canônicos do `oficina-infra`.
- O workflow não substitui as políticas de proteção da branch `main`; elas devem ser configuradas no GitHub.
