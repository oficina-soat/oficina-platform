# ADR-006 - Criação do Repositório Central de Plataforma

## Status

**Aceito**

---

## Contexto

A Fase 4 exige a evolução da aplicação para uma arquitetura baseada em microsserviços independentes, com comunicação distribuída, bancos de dados isolados, automação de deploy, observabilidade e coordenação transacional utilizando Saga Pattern.

Os requisitos estabelecem que cada microsserviço possua:

* repositório próprio;
* infraestrutura própria;
* banco de dados próprio;
* pipeline de CI/CD próprio;
* documentação própria.

Além disso, a solução deve manter artefatos compartilhados que transcendem os limites de um único serviço, tais como:

* decisões arquiteturais;
* contratos de APIs;
* contratos de eventos;
* definição do Saga Pattern;
* diagramas da solução;
* padrões de observabilidade;
* padrões de integração;
* documentação de entrega.

Sem uma estratégia centralizada, essas definições tendem a ficar distribuídas entre os diversos repositórios dos microsserviços, aumentando o risco de inconsistências e dificultando a evolução da plataforma.

---

## Problema

Definir uma estrutura para armazenar e governar artefatos arquiteturais compartilhados sem criar dependência operacional entre os microsserviços.

A solução deve:

* servir como fonte oficial das decisões arquiteturais;
* centralizar contratos entre serviços;
* documentar fluxos distribuídos;
* facilitar a evolução do Saga Pattern;
* simplificar a produção dos artefatos exigidos na entrega da fase.

---

## Opções consideradas

### 1. Documentação distribuída nos microsserviços

Cada microsserviço mantém seus próprios contratos, diagramas e decisões arquiteturais.

#### Vantagens

* Menor quantidade de repositórios.
* Documentação próxima da implementação.

#### Desvantagens

* Duplicação de informações.
* Maior risco de divergência entre serviços.
* Dificuldade para visualizar a arquitetura completa.
* Evolução mais complexa dos contratos compartilhados.

### 2. Repositório central de plataforma

Criar um repositório dedicado para armazenar artefatos compartilhados da solução.

#### Vantagens

* Fonte única de verdade para a arquitetura.
* Melhor rastreabilidade das decisões.
* Contratos compartilhados centralizados.
* Facilidade para evolução da plataforma.

#### Desvantagens

* Necessidade de manter um repositório adicional.
* Exige disciplina para manter documentação atualizada.

---

## Decisão

Foi decidido criar um repositório central denominado:

**oficina-platform**

Este repositório será responsável por armazenar toda documentação compartilhada da plataforma e servir como fonte oficial para decisões arquiteturais, contratos e padrões utilizados pelos microsserviços.

Os microsserviços continuarão mantendo apenas a documentação específica de suas responsabilidades internas.

---

## Justificativa

A arquitetura distribuída introduz diversos elementos compartilhados que não pertencem exclusivamente a um único serviço.

Entre eles:

* eventos de domínio;
* contratos REST;
* fluxos de Saga;
* convenções de observabilidade;
* diagramas arquiteturais;
* padrões de integração.

Centralizar esses artefatos reduz inconsistências, melhora a governança da solução e simplifica a manutenção da documentação exigida pela entrega.

Além disso, a separação permite que os microsserviços permaneçam focados exclusivamente em sua implementação e operação.

---

## Estrutura inicial do repositório

```text
oficina-platform
│
├── README.md
│
├── adr/
│   ├── ADR-001.md
│   ├── ADR-002.md
│   └── ...
│
├── rfc/
│
├── contracts/
│   │
│   ├── services/
│   │   ├── os-service.md
│   │   ├── billing-service.md
│   │   └── execution-service.md
│   │
│   ├── events/
│   │   ├── os-created.md
│   │   ├── budget-generated.md
│   │   ├── budget-approved.md
│   │   ├── payment-confirmed.md
│   │   └── service-completed.md
│   │
│   └── saga/
│       └── service-interactions.md
│
├── architecture/
│   │
│   ├── diagrams/
│   ├── saga/
│   ├── messaging/
│   ├── databases/
│   └── observability/
│
├── standards/
│   │
│   ├── ci-cd/
│   ├── git/
│   ├── kubernetes/
│   ├── naming/
│   └── api-guidelines/
│
└── delivery/
    ├── evidence-checklist.md
    └── final-documentation.md
```

---

## Responsabilidades do repositório

### Arquitetura

* Diagramas de contexto.
* Diagramas de componentes.
* Diagramas de microsserviços.
* Diagramas de banco de dados.
* Diagramas de comunicação.

### Contratos de serviços

* APIs REST públicas.
* Responsabilidades dos microsserviços.
* Dependências entre serviços.
* Estratégias de versionamento.

### Contratos de eventos

* Eventos publicados.
* Eventos consumidos.
* Estrutura dos payloads.
* Regras de compatibilidade.

### Saga Pattern

* Fluxos transacionais distribuídos.
* Estratégia adotada (orquestração ou coreografia).
* Eventos envolvidos.
* Operações compensatórias.
* Cenários de falha.

### Observabilidade

* Convenções de logs.
* Correlação distribuída.
* Métricas obrigatórias.
* Dashboards de referência.
* Estratégias de monitoramento.

### Governança

* ADRs.
* RFCs.
* Padrões de nomenclatura.
* Convenções de desenvolvimento.
* Padrões de CI/CD.

---

## Consequências

### Positivas

* Fonte única de verdade para a arquitetura.
* Melhor rastreabilidade das decisões.
* Redução de inconsistências entre microsserviços.
* Facilidade para manutenção dos contratos.
* Melhor visibilidade da arquitetura distribuída.
* Simplificação da documentação final da fase.

### Negativas

* Necessidade de manter um repositório adicional.
* Exige governança para evitar documentação desatualizada.
* Introduz um processo formal para mudanças arquiteturais.

---

## Impacto na arquitetura

A solução passa a possuir um repositório central de governança arquitetural separado dos microsserviços.

O repositório não contém código executável, pipelines de deploy ou componentes de negócio.

Sua responsabilidade é atuar como repositório oficial para:

* contratos;
* padrões;
* decisões arquiteturais;
* documentação da plataforma.

Os microsserviços passam a referenciar os artefatos definidos no `oficina-platform` como fonte oficial de especificação.

---

## Próximos passos

* Criar o repositório `oficina-platform`.
* Migrar os ADRs existentes para o novo repositório.
* Definir os contratos iniciais dos microsserviços.
* Definir os eventos da plataforma.
* Documentar a estratégia de Saga Pattern.
* Criar os diagramas iniciais da arquitetura distribuída.
* Definir os padrões de observabilidade e integração.

---

## Observação final

O repositório `oficina-platform` não substitui os repositórios dos microsserviços exigidos pela Fase 4.

Seu objetivo é centralizar a governança da plataforma, fornecendo uma visão unificada da arquitetura e servindo como fonte oficial para contratos, padrões e decisões compartilhadas.
