# Estratégia de entrega dos manifestos Kubernetes

## Objetivo

Definir como a Fase 4 entrega manifestos Kubernetes por microsserviço sem criar cópias divergentes entre `oficina-platform`, `oficina-infra` e os repositórios dos serviços.

Esta decisão concilia o requisito do [Enunciado Fase 4](Enunciado%20Fase%204.md), que lista manifestos Kubernetes como entregável dos repositórios Git dos microsserviços, com a governança definida no [Escopo do Repositório Unificado de Infraestrutura](infrastructure-repository-scope.md).

## Decisão

O repositório `oficina-infra` é a fonte canônica dos manifestos Kubernetes executáveis da Fase 4.

O `oficina-platform` mantém os templates normativos em [Template Kubernetes Base](../templates/kubernetes/base/README.md), e os repositórios `oficina-os-service`, `oficina-billing-service` e `oficina-execution-service` documentam em seus READMEs onde ficam:

- o template Kubernetes aplicável ao serviço;
- o destino canônico no `oficina-infra`;
- a condição para habilitar deploy automatizado pelo workflow do serviço.

Os repositórios dos microsserviços não devem manter cópias executáveis dos manifests enquanto o `oficina-infra` for a fonte canônica. Essa regra evita drift entre cópias, impede deploy com valores divergentes e mantém secrets, overlays, imagens e nomes de cluster sob responsabilidade do repositório de infraestrutura.

Se uma avaliação exigir arquivos Kubernetes dentro de cada repositório de microsserviço, as cópias devem ser registradas como referência não canônica e apontar para esta estratégia. O deploy real continua pertencendo ao `oficina-infra`.

## Fontes e destinos

| Serviço | Template normativo | Destino canônico no `oficina-infra` |
|---|---|---|
| `oficina-os-service` | [templates/kubernetes/base/oficina-os-service/](../templates/kubernetes/base/oficina-os-service/) | `../oficina-infra/k8s/base/microservices/oficina-os-service/` |
| `oficina-billing-service` | [templates/kubernetes/base/oficina-billing-service/](../templates/kubernetes/base/oficina-billing-service/) | `../oficina-infra/k8s/base/microservices/oficina-billing-service/` |
| `oficina-execution-service` | [templates/kubernetes/base/oficina-execution-service/](../templates/kubernetes/base/oficina-execution-service/) | `../oficina-infra/k8s/base/microservices/oficina-execution-service/` |

No `oficina-infra`, os manifests executáveis ficam materializados por serviço em:

```text
../oficina-infra/k8s/base/microservices/<nome-do-servico>/
```

O overlay `lab` permanece responsável por componentes compartilhados do cluster. A aplicação dos microsserviços é feita por `../oficina-infra/scripts/manual/apply-microservices.sh`, que gera um `kustomization.yaml` temporário com os serviços selecionados, substitui a imagem ECR e os valores de autenticação e aplica apenas os serviços com imagem disponível.

## Regras de ownership

| Artefato | Fonte canônica | Regra |
|---|---|---|
| Convenções de recursos Kubernetes | `oficina-platform` | Definidas no [Template Kubernetes Base](../templates/kubernetes/base/README.md). |
| Manifests executáveis de deploy | `oficina-infra` | Adaptam os templates para o ambiente `lab`, imagens ECR, overlays, secrets e integração com EKS. |
| Dockerfile | Repositório do microsserviço | Cada serviço mantém seu próprio build de imagem. |
| Workflow de deploy | Repositório do microsserviço | Publica imagem, cria release e materializa ou atualiza o Deployment do próprio serviço somente quando `ENABLE_K8S_DEPLOY=true`. |
| Valores sensíveis | `oficina-infra` e AWS | Não devem ser copiados para `oficina-platform` nem para os repositórios dos serviços. |
| Evidência para entrega | README do microsserviço | Deve apontar para o template e para o destino canônico no `oficina-infra`. |

## Habilitação do deploy automatizado

O job de deploy dos microsserviços só deve ser habilitado quando as seguintes condições estiverem atendidas:

- o nome do Deployment e do container for igual ao nome canônico do serviço;
- o manifest executável estiver materializado no `oficina-infra`;
- o script `scripts/manual/apply-microservices.sh` do `oficina-infra` conseguir criar ou atualizar os secrets e ConfigMaps esperados pelo serviço;
- a imagem ECR do serviço puder ser publicada pelo workflow;
- o workflow do serviço conseguir fazer checkout do `oficina-infra`;
- `ENABLE_K8S_DEPLOY=true` estiver configurado no repositório do microsserviço.

Enquanto essas condições não estiverem atendidas, o workflow deve continuar executando CI e publicação opcional de imagem sem acionar deploy Kubernetes. Quando `ENABLE_K8S_DEPLOY=true`, mas o `Deployment` ainda não existir no cluster, o workflow deve criar o recurso a partir do manifest canônico do `oficina-infra`, aguardar o rollout e conferir se a imagem final do container é a imagem publicada pelo próprio workflow.

## Validação esperada

No `oficina-platform`, validar os templates:

```bash
kubectl kustomize templates/kubernetes/base
```

No `oficina-infra`, validar a base de microsserviços e o overlay compartilhado:

```bash
kubectl kustomize k8s/base/microservices
kubectl kustomize k8s/overlays/lab
```

Nos repositórios dos microsserviços, validar que os READMEs apontam para esta estratégia, para o template aplicável e para o destino canônico no `oficina-infra`.

## Critério de pronto

A estratégia está resolvida quando:

- esta decisão está documentada no `oficina-platform`;
- o [Template Kubernetes Base](../templates/kubernetes/base/README.md) aponta para esta decisão;
- o `oficina-infra` declara que é a fonte canônica dos manifests executáveis;
- os três READMEs dos microsserviços apontam para o template aplicável e para o destino canônico no `oficina-infra`;
- o [ROADMAP](../ROADMAP.md) registra que a estratégia de entrega dos manifests foi fechada.
