# Estratégia de entrega dos manifestos Kubernetes

## Objetivo

Definir como entregar manifestos Kubernetes por microsserviço sem criar cópias divergentes entre `oficina-platform`, `oficina-infra` e os repositórios dos serviços.

Esta decisão concilia o requisito do [Enunciado do projeto](../delivery/Enunciado%20Fase%204.md), que lista manifestos Kubernetes como entregável dos repositórios Git dos microsserviços, com a governança definida no [Escopo do Repositório Unificado de Infraestrutura](infrastructure-repository-scope.md).

## Decisão

Cada repositório de microsserviço é a fonte canônica de sua base Kubernetes executável em `k8s/base/`.

O `oficina-platform` mantém os templates normativos em [Template Kubernetes Base](../../templates/kubernetes/base/README.md), e os repositórios `oficina-os-service`, `oficina-billing-service` e `oficina-execution-service` documentam em seus READMEs onde ficam:

- o template Kubernetes aplicável ao serviço;
- o destino canônico no `oficina-infra`;
- a condição para habilitar deploy automatizado pelo workflow do serviço.

O `oficina-infra` não mantém cópias dessas bases. Ele é responsável pelos componentes compartilhados, pelos valores e secrets do ambiente `lab` e pelo script que compõe a base selecionada com a imagem publicada. Assim, mudanças de Deployment, Service, ServiceAccount e ConfigMap acompanham o ciclo de vida do serviço sem duplicação.

## Fontes e destinos

| Serviço | Template normativo | Base executável canônica |
|---|---|---|
| `oficina-os-service` | [templates/kubernetes/base/oficina-os-service/](../../templates/kubernetes/base/oficina-os-service/) | `../oficina-os-service/k8s/base/` |
| `oficina-billing-service` | [templates/kubernetes/base/oficina-billing-service/](../../templates/kubernetes/base/oficina-billing-service/) | `../oficina-billing-service/k8s/base/` |
| `oficina-execution-service` | [templates/kubernetes/base/oficina-execution-service/](../../templates/kubernetes/base/oficina-execution-service/) | `../oficina-execution-service/k8s/base/` |

Em cada serviço, os manifests executáveis ficam materializados em:

```text
../<nome-do-servico>/k8s/base/
```

O overlay `lab` permanece responsável por componentes compartilhados do cluster. A aplicação dos microsserviços é feita por `../oficina-infra/scripts/manual/apply-microservices.sh`, que gera um `kustomization.yaml` temporário com os serviços selecionados, substitui a imagem ECR e os valores de autenticação e aplica apenas os serviços com imagem disponível.

## Regras de ownership

| Artefato | Fonte canônica | Regra |
|---|---|---|
| Convenções de recursos Kubernetes | `oficina-platform` | Definidas no [Template Kubernetes Base](../../templates/kubernetes/base/README.md). |
| Base executável de deploy | Repositório do microsserviço | Mantém Deployment, Service, ServiceAccount, ConfigMap e kustomization junto do código. |
| Composição do ambiente `lab` | `oficina-infra` | Mantém componentes compartilhados, imagens ECR, secrets e integração com EKS. |
| Dockerfile | Repositório do microsserviço | Cada serviço mantém seu próprio build de imagem. |
| Workflow de deploy | Repositório do microsserviço | Publica imagem, cria release e materializa ou atualiza o Deployment do próprio serviço por padrão, salvo quando `ENABLE_K8S_DEPLOY=false`. |
| Valores sensíveis | `oficina-infra` e AWS | Não devem ser copiados para `oficina-platform` nem para os repositórios dos serviços. |
| Evidência para entrega | README do microsserviço | Deve apontar para o template e para o destino canônico no `oficina-infra`. |

## Deploy automatizado

O job de deploy dos microsserviços fica ativo por padrão no push para `main` e deve ser mantido assim quando as seguintes condições estiverem atendidas:

- o nome do Deployment e do container for igual ao nome canônico do serviço;
- a base executável estiver materializada em `k8s/base/` do próprio serviço;
- o script `scripts/manual/apply-microservices.sh` do `oficina-infra` conseguir criar ou atualizar os secrets e ConfigMaps esperados pelo serviço;
- a imagem ECR do serviço puder ser publicada pelo workflow;
- o workflow do serviço conseguir fazer checkout do `oficina-infra`;
- `ENABLE_K8S_DEPLOY` não estiver configurado como `false` no repositório do microsserviço.

Enquanto essas condições não estiverem atendidas, configure `ENABLE_K8S_DEPLOY=false` para manter o workflow executando CI e publicação opcional de imagem sem acionar deploy Kubernetes. Quando `ENABLE_K8S_DEPLOY` não é `false`, mas o `Deployment` ainda não existir no cluster, o workflow deve criar o recurso a partir do manifest canônico do `oficina-infra`, aguardar o rollout e conferir se a imagem final do container é a imagem publicada pelo próprio workflow.

## Validação esperada

No `oficina-platform`, validar os templates:

```bash
kubectl kustomize templates/kubernetes/base
```

Em cada repositório de microsserviço, validar sua base:

```bash
kubectl kustomize k8s/base
```

No `oficina-infra`, validar o overlay compartilhado:

```bash
kubectl kustomize k8s/overlays/lab
```

Nos repositórios dos microsserviços, validar que os READMEs apontam para esta estratégia, para o template aplicável e para o destino canônico no `oficina-infra`.

## Critério de pronto

A estratégia está resolvida quando:

- esta decisão está documentada no `oficina-platform`;
- o [Template Kubernetes Base](../../templates/kubernetes/base/README.md) aponta para esta decisão;
- cada microsserviço contém e valida sua base executável em `k8s/base/`;
- o `oficina-infra` declara sua responsabilidade pela composição do ambiente;
- os três READMEs dos microsserviços apontam para o template aplicável e para o destino canônico no `oficina-infra`;
- o [ROADMAP](../../ROADMAP.md) registra que a estratégia de entrega dos manifests foi fechada.
