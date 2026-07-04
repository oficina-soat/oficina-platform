# Template Kubernetes Base

## Objetivo

Fornecer manifests Kubernetes base para os três microsserviços canônicos da plataforma:

- `oficina-os-service`;
- `oficina-billing-service`;
- `oficina-execution-service`.

Este template complementa o [Template Quarkus de Microsserviço](../../quarkus-service/README.md), o [Padrão de Observabilidade Distribuída](../../../docs/observability.md), os [Nomes de runtime, secrets e infraestrutura](../../../docs/infra-runtime-naming.md) e a definição de [Conta, região e ambientes AWS](../../../docs/aws-environments.md).

A estratégia de entrega está definida em [Estratégia de entrega dos manifestos Kubernetes](../../../docs/kubernetes-manifest-strategy.md): este diretório é a referência normativa, enquanto o `oficina-infra` é a fonte canônica dos manifests executáveis de deploy.

## Estrutura

```text
templates/kubernetes/base/
  kustomization.yaml
  oficina-os-service/
    kustomization.yaml
    service-account.yaml
    configmap.yaml
    deployment.yaml
    service.yaml
  oficina-billing-service/
    ...
  oficina-execution-service/
    ...
```

## Uso esperado

O repositório `oficina-infra` deve consumir este template como referência para os manifests base e criar os manifests executáveis e overlays de ambiente, como `lab`, sem alterar os nomes canônicos dos serviços.

Comando de validação local:

```bash
kubectl kustomize templates/kubernetes/base
```

Para aplicar em um cluster, o repositório de infraestrutura deve substituir:

- `IMAGE_PLACEHOLDER` pela imagem publicada no ECR do serviço;
- `OFICINA_AUTH_ISSUER_PLACEHOLDER` pelo issuer canônico do ambiente;
- `OFICINA_AUTH_JWKS_URI_PLACEHOLDER` pela localização JWKS do ambiente;
- secrets Kubernetes de banco dos serviços PostgreSQL;
- permissões IAM ou anotações de `ServiceAccount` quando necessárias pelo ambiente.

## Decisões do template

- Os recursos usam `namespace: default`, conforme [Nomes de runtime, secrets e infraestrutura](../../../docs/infra-runtime-naming.md).
- Os `Deployment`, `Service`, `ServiceAccount` e `ConfigMap` preservam o nome completo do microsserviço.
- Os `Service` são `ClusterIP` por padrão. Exposição via API Gateway, NLB, Ingress ou `NodePort` pertence ao repositório de infraestrutura.
- As probes usam os endpoints Quarkus definidos no [Padrão de Observabilidade Distribuída](../../../docs/observability.md): `/q/health/live` e `/q/health/ready`.
- As métricas ficam disponíveis em `/q/metrics`.
- Os traces OpenTelemetry usam `QUARKUS_OTEL_TRACES_EXPORTER=cdi` para acionar o exportador OTLP gerenciado pelo Quarkus e são enviados por padrão para `http://datadog-agent.datadog.svc.cluster.local:4317`, conforme [Nomes de runtime, secrets e infraestrutura](../../../docs/infra-runtime-naming.md).
- O secret `oficina-jwt-keys` é montado em `/jwt`, mantendo compatibilidade com a autenticação da suíte.
- `oficina-os-service` e `oficina-billing-service` usam secrets Kubernetes separados para materializar `JDBC_DATABASE_URL`, `REACTIVE_DATABASE_URL`, `DB_USERNAME` e `DB_PASSWORD`.
- `oficina-execution-service` usa as variáveis DynamoDB canônicas do ambiente `lab`.

## Fora do escopo

- Criar `Ingress`, `Gateway`, `NodePort` fixo ou rota pública.
- Definir imagens finais de container.
- Criar secrets com valores sensíveis.
- Criar recursos AWS, IAM, RDS, DynamoDB ou mensageria.
- Executar migrations de domínio.
