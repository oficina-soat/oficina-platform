# Checklist de Deploy Independente

## Objetivo

Definir a verificação operacional mínima para publicar um microsserviço sem exigir deploy simultâneo dos demais.

Este checklist implementa a [ADR-012 - Estratégia de CI/CD e Deploy Independente](../adr/ADR-012%20-%20Estratégia%20de%20CI%20CD%20e%20Deploy%20Independente.md) e complementa o [Template GitHub Actions para Microsserviços](../templates/github-actions/README.md), a [Estratégia de entrega dos manifestos Kubernetes](kubernetes-manifest-strategy.md), o [Escopo do Repositório Unificado de Infraestrutura](infrastructure-repository-scope.md), os [Nomes de runtime, secrets e infraestrutura](infra-runtime-naming.md), as [Rotas públicas do API Gateway](api-gateway-public-routes.md) e o [Checklist Final de Entrega da Fase 4](phase-4-delivery-checklist.md).

## Escopo

Serviços cobertos:

| Serviço | Pipeline | Imagem | Deployment esperado |
|---|---|---|---|
| `oficina-os-service` | `.github/workflows/service-ci.yml` | ECR `oficina-os-service:<project.version>` | `oficina-os-service` |
| `oficina-billing-service` | `.github/workflows/service-ci.yml` | ECR `oficina-billing-service:<project.version>` | `oficina-billing-service` |
| `oficina-execution-service` | `.github/workflows/service-ci.yml` | ECR `oficina-execution-service:<project.version>` | `oficina-execution-service` |

O deploy independente significa que cada serviço pode publicar nova imagem, atualizar seu próprio `Deployment` no `eks-lab` e validar rollout sem reconstruir, reimplantar ou alterar os outros dois microsserviços.

## Pré-condições

Antes de manter `ENABLE_IMAGE_PUBLISH` e `ENABLE_K8S_DEPLOY` ativos por padrão em um repositório de microsserviço, confirmar:

- [ ] a branch `main` está protegida conforme [Proteção da branch main dos microsserviços](github-branch-protection.md);
- [ ] o workflow `.github/workflows/service-ci.yml` deriva do [Template GitHub Actions para Microsserviços](../templates/github-actions/README.md);
- [ ] `SERVICE_NAME` coincide com o nome canônico do repositório ou pode ser derivado do nome do repositório;
- [ ] `MAVEN_PROFILE` está definido ou pode ser derivado como `postgresql` para `oficina-os-service` e `oficina-billing-service`, ou `dynamodb` para `oficina-execution-service`;
- [ ] `AWS_REGION=us-east-1`, `EKS_CLUSTER_NAME=eks-lab` e `K8S_NAMESPACE=default` estão configurados como variáveis do repositório ou da organização;
- [ ] `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` e `AWS_SESSION_TOKEN` estão disponíveis como secrets do repositório ou da organização;
- [ ] `SONAR_TOKEN` está configurado como secret do repositório ou da organização GitHub;
- [ ] Automatic Analysis está desabilitada no projeto SonarCloud quando o workflow `service-ci-validate` executar análise baseada em CI;
- [ ] o SonarScanner for Maven importa `target/jacoco-report/jacoco.xml` e aguarda o Quality Gate quando o SonarCloud for usado como evidência da entrega;
- [ ] o repositório ECR do serviço existe no `oficina-infra`;
- [ ] o `Deployment` e o container Kubernetes usam exatamente o nome canônico do serviço;
- [ ] os manifests executáveis estão materializados no `../oficina-infra/k8s/base/microservices/<servico>/` e referenciados pelo overlay `../oficina-infra/k8s/overlays/lab/`;
- [ ] o overlay `lab` renderiza sem erro com `kubectl kustomize k8s/overlays/lab` no `oficina-infra`;
- [ ] secrets, ConfigMaps, service accounts e políticas IAM necessárias ao serviço estão disponíveis no ambiente `lab`;
- [ ] a imagem atualmente publicada, a release `v<project.version>` e a versão em `pom.xml` estão coerentes com a regra de versionamento do workflow;
- [ ] qualquer versão já existente como GitHub Release ou tag de imagem ECR pertence ao build anterior esperado; para novo build, release ou rollout, planejar uma nova versão SemVer fechada.

## Checklist por mudança

Para cada alteração candidata a deploy:

- [ ] classificar se a mudança altera artefato publicável: código Java, `pom.xml`, `Dockerfile`, configuração runtime, resources, migrations, dependências, observabilidade, segurança, mensageria, testes que alterem o artefato validado ou scripts usados pelo build da imagem;
- [ ] quando a mudança for publicável, incrementar `project.version` no mesmo PR para uma versão SemVer fechada `MAJOR.MINOR.PATCH`, maior que a versão da base e ainda não publicada como release `v<project.version>` ou imagem `<project.version>`;
- [ ] identificar se a mudança é compatível com os contratos atuais de REST, eventos, estados, erro e idempotência;
- [ ] atualizar OpenAPI, schemas JSON, ADR, README ou roadmap quando a mudança alterar contrato compartilhado;
- [ ] confirmar que não há mudança incompatível sem versionamento por URI ou `eventVersion`;
- [ ] revisar variáveis de ambiente novas ou alteradas contra [Nomes de runtime, secrets e infraestrutura](infra-runtime-naming.md);
- [ ] executar testes locais do serviço, incluindo unitários, integração, contratos e BDD quando aplicável;
- [ ] confirmar cobertura mínima de 80%;
- [ ] confirmar que a mudança não exige deploy coordenado dos demais serviços;
- [ ] quando houver dependência de infraestrutura, confirmar que o `oficina-infra` já materializou o recurso antes do deploy do serviço.

## Fluxo de release

1. Abrir PR no repositório do microsserviço.
2. Confirmar aprovação e execução bem-sucedida do check `service-ci-validate`.
3. Confirmar Quality Gate SonarCloud aprovado e cobertura importada de `target/jacoco-report/jacoco.xml` quando SonarCloud estiver configurado.
4. Confirmar que `project.version` no `pom.xml` foi incrementado para toda mudança publicável antes do merge; a versão não pode ser `SNAPSHOT`, menor ou igual à base do PR, nem já publicada para outro build.
5. Fazer merge na `main`.
6. No push da `main`, confirmar que o workflow:
   - [ ] rejeitou versão `SNAPSHOT`;
   - [ ] rejeitou alteração publicável sem incremento de `project.version`;
   - [ ] executou SonarCloud com `SONAR_TOKEN`, importou `target/jacoco-report/jacoco.xml` e aprovou o Quality Gate;
   - [ ] resolveu a tag `v<project.version>`;
   - [ ] publicou imagem no ECR quando `ENABLE_IMAGE_PUBLISH` não é `false`;
   - [ ] criou GitHub Release quando a release ainda não existia;
   - [ ] atualizou somente o `Deployment` do serviço quando `ENABLE_K8S_DEPLOY` não é `false`;
   - [ ] validou rollout do `Deployment`.
7. Registrar a URL do workflow, tag, digest da imagem e release no [Checklist Final de Entrega da Fase 4](phase-4-delivery-checklist.md), quando a validação for usada como evidência final.

## Validação pós-deploy

Após rollout bem-sucedido de um serviço:

- [ ] confirmar `kubectl rollout status deployment/<servico> -n <namespace>`;
- [ ] confirmar que a imagem do `Deployment` usa a tag e digest esperados;
- [ ] confirmar readiness e liveness do pod pelo Kubernetes;
- [ ] chamar uma rota de negócio simples do serviço pelo caminho esperado no ambiente;
- [ ] não expor `/q/health`, `/q/metrics`, `/q/openapi`, `/q/swagger-ui` ou `/api/v1/status` como API pública permanente, conforme [Rotas públicas do API Gateway](api-gateway-public-routes.md);
- [ ] verificar logs estruturados com `service.name`, `deployment.environment` e `correlationId` quando houver chamada HTTP;
- [ ] verificar que métricas em `/q/metrics` continuam coletáveis pelo New Relic OpenTelemetry Collector quando a coleta estiver habilitada;
- [ ] para mudanças com evento, publicar ou simular fluxo que confirme Outbox, tópico, fila consumidora e idempotência sem quebrar os demais serviços;
- [ ] para mudanças de persistência, confirmar que o serviço acessa apenas seu próprio database ou tabelas DynamoDB.

## Smoke tests mínimos

| Serviço | Smoke test local ou operacional |
|---|---|
| `oficina-os-service` | Criar ou listar cliente, depois consultar OS quando houver massa disponível. |
| `oficina-billing-service` | Consultar orçamento ou pagamento por OS quando houver massa disponível. |
| `oficina-execution-service` | Listar serviços ou peças e consultar fila de execução quando houver massa disponível. |

Quando o API Gateway público ainda não tiver `integration_uri` real para todos os backends, executar smoke tests por rota interna do cluster, port-forward controlado ou endpoint operacional documentado no `oficina-infra`. Essa exceção não altera o contrato público permanente.

## Rollback

Se o deploy falhar ou degradar o serviço:

- [ ] interromper novos deploys do mesmo serviço;
- [ ] registrar a versão, imagem, workflow e erro observado;
- [ ] executar rollback do `Deployment` do serviço afetado ou redeploy da última imagem conhecida como estável;
- [ ] confirmar rollout do rollback;
- [ ] validar smoke test do serviço revertido;
- [ ] verificar se mensagens ficaram em DLQ, Outbox parada ou Saga em falha manual;
- [ ] abrir correção no repositório do microsserviço ou no `oficina-infra`, conforme ownership do erro;
- [ ] registrar a ocorrência e a evidência no [Checklist Final de Entrega da Fase 4](phase-4-delivery-checklist.md), se impactar a entrega.

Rollback de um serviço não deve reverter bancos, tópicos, filas, secrets ou manifests de outro microsserviço sem decisão explícita e revisão anti-divergência.

## Evidências

Para cada deploy usado como evidência final, registrar:

| Evidência | Onde registrar |
|---|---|
| PR aprovado | README do serviço ou [Checklist Final de Entrega da Fase 4](phase-4-delivery-checklist.md) |
| Check `service-ci-validate` aprovado | README do serviço ou checklist final |
| Quality Gate externo e cobertura | README do serviço ou checklist final |
| Tag GitHub Release | README do serviço ou checklist final |
| URI ou digest da imagem ECR | README do serviço ou checklist final |
| Rollout Kubernetes | README do serviço ou checklist final |
| Smoke test pós-deploy | README do serviço ou checklist final |
| Logs, métricas ou traces | Checklist final ou evidência de observabilidade |

## Critério de pronto

O deploy independente de um serviço está pronto quando:

- a mudança passou por PR protegido;
- CI, testes, cobertura e Quality Gate externo foram aprovados quando aplicável;
- imagem versionada foi publicada no ECR;
- apenas o `Deployment` do serviço foi atualizado;
- rollout e smoke test passaram;
- contratos e documentação relacionados continuam coerentes;
- evidências necessárias foram registradas.
