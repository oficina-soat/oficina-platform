## Status

**Aceito**

---

## Contexto

A aplicação da oficina está sendo evoluída para um ambiente distribuído em nuvem, com os seguintes requisitos:

- autenticação segura baseada em CPF
- uso de API Gateway para controle de acesso
- utilização de funções serverless para autenticação
- execução da aplicação principal em Kubernetes
- banco de dados gerenciado
- infraestrutura provisionada via Terraform
- observabilidade completa com métricas, logs e traces

Além disso, a aplicação já possui implementação inicial e experiência prévia com a plataforma AWS, reduzindo a curva de aprendizado da equipe.

Esses requisitos são definidos como obrigatórios no desafio proposto.

---

## Problema

Definir uma plataforma de nuvem que:

- atenda integralmente os requisitos técnicos do projeto
- minimize risco de entrega
- permita evolução futura da arquitetura
- mantenha equilíbrio entre custo, complexidade e produtividade

---

## Opções consideradas

### 1. AWS (Amazon Web Services)

- API Gateway
- Lambda
- EKS
- RDS PostgreSQL

### 2. Google Cloud Platform (GCP)

- API Gateway
- Cloud Functions
- GKE
- Cloud SQL

### 3. Microsoft Azure

- API Management
- Azure Functions
- AKS
- Azure SQL

---

## Decisão

Foi decidido utilizar a **AWS (Amazon Web Services)** como plataforma de nuvem principal para o projeto.

---

## Justificativa

A decisão foi baseada nos seguintes fatores:

- A AWS atende de forma nativa todos os requisitos técnicos exigidos pelo projeto;
- A equipe já possui experiência prévia com a plataforma, reduzindo a curva de aprendizado;
- Forte integração entre serviços essenciais (API Gateway, Lambda, EKS, RDS);
- Excelente suporte a infraestrutura como código com Terraform;
- Ampla documentação e maturidade do ecossistema.

Além disso, a existência de uma base já construída na AWS reduz o custo de migração e acelera a entrega.

---

## Consequências

### Positivas

- Alta aderência aos requisitos do projeto
- Redução do tempo de implementação
- Uso de serviços gerenciados reduz esforço operacional
- Facilidade de integração entre componentes da arquitetura
- Escalabilidade nativa

---

### Negativas

- Complexidade elevada na gestão de serviços e configurações
- Modelo de permissões (IAM) de difícil manutenção
- Custos potencialmente imprevisíveis sem governança adequada
- Aumento do vendor lock-in ao utilizar serviços proprietários

---

## Considerações sobre Vendor Lock-in

O uso de serviços proprietários da AWS (como Lambda e API Gateway) introduz acoplamento à plataforma.

No entanto, essa decisão é tratada como estratégica:

- reduz complexidade operacional
- acelera o desenvolvimento
- diminui custo inicial

Por outro lado:

- reduz portabilidade
- pode impactar custos no longo prazo

Portanto, o vendor lock-in será gerenciado de forma consciente, equilibrando:

- **simplicidade e velocidade no curto prazo**
- **flexibilidade no longo prazo**

---

## Considerações sobre custo

O custo na AWS não é determinado apenas pela escolha da plataforma, mas pelas decisões arquiteturais adotadas.

Serão adotadas as seguintes práticas:

- uso criterioso de serviços serverless
- monitoramento contínuo de consumo
- configuração adequada de autoscaling
- controle de logs e métricas
- escolha adequada de recursos (CPU/memória)

---

## Impacto na arquitetura

A decisão impacta diretamente a arquitetura, que passa a ser composta por:

- **API Gateway** → entrada das requisições
- **AWS Lambda** → autenticação por CPF
- **Amazon EKS** → execução da aplicação Quarkus
- **Amazon RDS (PostgreSQL)** → banco de dados gerenciado
- **Terraform** → provisionamento da infraestrutura
- **Datadog (ou similar)** → observabilidade

---

## Próximos passos

- Definir padrões de uso dos serviços AWS
- Criar infraestrutura base com Terraform
- Implementar Lambda de autenticação
- Configurar API Gateway
- Adaptar aplicação para execução em Kubernetes (EKS)
- Definir estratégia de observabilidade

---

## Observação final

Esta decisão prioriza entrega eficiente e aderência ao desafio proposto, aceitando de forma consciente os trade-offs relacionados à complexidade, custo e vendor lock-in.