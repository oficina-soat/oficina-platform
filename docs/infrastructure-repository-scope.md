# Escopo do Repositório Unificado de Infraestrutura

## Objetivo

Definir o escopo e as responsabilidades do repositório `oficina-infra`, que substitui a separação histórica entre `oficina-infra-db` e `oficina-infra-k8s`.

Este documento é normativo para agentes ao evoluir infraestrutura compartilhada da suíte. O `oficina-platform` continua sendo a fonte de governança, contratos e padrões; o `oficina-infra` deve conter os artefatos executáveis de provisionamento e operação da infraestrutura.

## Decisão

O repositório canônico de infraestrutura da Fase 4 é:

```text
oficina-infra
```

Ele deve consolidar as responsabilidades atualmente distribuídas entre:

```text
oficina-infra-db
oficina-infra-k8s
```

Os repositórios legados permanecem como referência histórica até que seus artefatos úteis sejam migrados ou descartados explicitamente.

## Responsabilidades do `oficina-infra`

| Área | Responsabilidade |
|---|---|
| Terraform AWS | Provisionar recursos compartilhados da suíte no ambiente `lab`. |
| State remoto | Usar o bucket `tf-shared-eks-lab-<aws-account-id>-us-east-1` e a key `oficina/lab/infra/terraform.tfstate`. |
| Kubernetes compartilhado | Manter namespaces, secrets materializados, config maps compartilhados, ingress ou rotas comuns e integrações com o cluster `eks-lab`. |
| Banco relacional | Provisionar a instância RDS PostgreSQL compartilhada e preparar isolamento lógico para `oficina_os` e `oficina_billing`. |
| DynamoDB | Provisionar tabelas do `oficina-execution-service` com prefixo `oficina-execution-lab`. |
| Mensageria | Provisionar tópicos, filas, DLQs e permissões conforme contratos de eventos e tópicos. |
| ECR | Provisionar ou padronizar repositórios de imagem dos microsserviços. |
| IAM | Criar permissões mínimas para pipelines, workloads Kubernetes, DynamoDB, RDS, Secrets Manager e mensageria. |
| Secrets | Criar ou referenciar secrets AWS canônicos sob `oficina/lab/...`. |
| Operação | Concentrar scripts de deploy, destroy, bootstrap e validação da infraestrutura compartilhada. |

## Fora do Escopo

O `oficina-infra` não deve conter:

- código de aplicação dos microsserviços;
- controllers, entidades, regras de negócio ou testes unitários dos serviços;
- contratos OpenAPI, schemas de eventos ou ADRs normativas, que permanecem no `oficina-platform`;
- migrations executáveis próprias dos microsserviços, salvo bootstrap estritamente necessário para criar databases, usuários e permissões;
- manifests específicos que pertençam ao ciclo de vida exclusivo de um microsserviço quando esses manifests estiverem versionados no repositório do próprio serviço;
- valores hardcoded de conta AWS.

## Nomes Canônicos

O repositório deve seguir os nomes consolidados em [Nomes de runtime, secrets e infraestrutura](infra-runtime-naming.md) e [Conta, região e ambientes AWS](aws-environments.md).

Valores obrigatórios:

| Item | Valor |
|---|---|
| Região AWS | `us-east-1` |
| Ambiente | `lab` |
| Cluster EKS | `eks-lab` |
| GitHub Environment | `lab` |
| Projeto | `oficina` |
| Prefixo de secrets | `oficina/lab` |
| State Terraform | `oficina/lab/infra/terraform.tfstate` |

O número da conta AWS deve ser resolvido em tempo de execução por `aws sts get-caller-identity` e não deve ser fixado em código, documentação operacional ou workflow.

## Estrutura Recomendada

```text
oficina-infra
├── README.md
├── docs/
├── terraform/
│   ├── backend/
│   ├── modules/
│   └── environments/
│       └── lab/
├── k8s/
│   ├── base/
│   └── overlays/
│       └── lab/
├── scripts/
│   ├── actions/
│   ├── lib/
│   └── manual/
└── .github/
    └── workflows/
```

Essa estrutura é recomendada para reduzir ambiguidade. Ajustes são permitidos quando preservarem as responsabilidades e nomes canônicos deste documento.

## Migração dos Repositórios Legados

| Origem | Migrar para `oficina-infra` | Observação |
|---|---|---|
| `oficina-infra-db` | Terraform de RDS, scripts de bootstrap, padrões de secrets e workflows úteis. | Migrations legadas do `oficina-app` devem ficar apenas como referência para decomposição. |
| `oficina-infra-k8s` | Terraform/Kubernetes de EKS, API Gateway, rotas, scripts operacionais e workflows úteis. | Artefatos do backend monolítico `oficina-app` devem ser marcados como legados ou removidos quando substituídos. |

Antes de migrar qualquer artefato executável, validar se ele ainda usa nomes legados como `oficina-app`, `simple-eks`, conta AWS fixa, database `app` ou secret `oficina/lab/database/app`. Quando o valor for legado, o novo repositório deve usar os nomes canônicos da Fase 4.

## Critérios de Pronto

O `oficina-infra` estará alinhado com a governança quando:

- usar `us-east-1`, `lab` e `eks-lab`;
- usar state remoto na key `oficina/lab/infra/terraform.tfstate`;
- provisionar RDS compartilhado sem permitir acesso cruzado entre `oficina_os` e `oficina_billing`;
- provisionar tabelas DynamoDB canônicas do `oficina-execution-service`;
- materializar secrets sem expor valores sensíveis no Git;
- criar ou referenciar tópicos, filas e DLQs compatíveis com os contratos de mensageria;
- permitir deploy independente dos três microsserviços;
- manter artefatos legados claramente separados ou descartados;
- documentar comandos de deploy, destroy e validação local.

## Referências

- [Nomes de runtime, secrets e infraestrutura](infra-runtime-naming.md)
- [Conta, região e ambientes AWS](aws-environments.md)
- [Padrão DynamoDB do oficina-execution-service](dynamodb-execution-service.md)
- [Proposta de Migrations PostgreSQL Decompostas](postgres-migrations-decomposition.md)
- [Matriz de Ownership por Microsserviço](service-ownership.md)
- [Contrato de Tópicos de Mensageria](../contracts/Contrato%20de%20Tópicos%20de%20Mensageria.md)
