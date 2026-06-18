# ADR-007 - Governança Multi-Repositório e Plataforma Compartilhada

## Status

**Aceito**

---

## Contexto

A aplicação da oficina está sendo evoluída para uma arquitetura baseada em microsserviços, conforme os requisitos da Fase 4 do projeto.

Entre os requisitos obrigatórios estão:

* separação da solução em múltiplos microsserviços independentes
* repositórios independentes por serviço
* bancos de dados independentes
* comunicação síncrona e assíncrona entre serviços
* implantação automatizada em Kubernetes
* pipelines independentes de CI/CD
* utilização de observabilidade distribuída

Além disso, a evolução da arquitetura introduz uma quantidade significativa de artefatos compartilhados, tais como:

* ADRs
* documentação arquitetural
* contratos OpenAPI
* contratos de eventos
* diagramas de arquitetura
* templates de projetos
* componentes de infraestrutura compartilhada
* padrões de observabilidade
* configurações reutilizáveis de Kubernetes

Sem uma estratégia clara de organização, esses artefatos tenderiam a ser duplicados entre os repositórios dos microsserviços, aumentando a complexidade de manutenção e dificultando a rastreabilidade das decisões arquiteturais.

---

## Problema

Definir uma estratégia de organização dos repositórios que:

* mantenha a independência dos microsserviços
* reduza duplicação de artefatos compartilhados
* facilite a manutenção da documentação arquitetural
* simplifique a compreensão da arquitetura completa do sistema
* permita evolução coordenada dos contratos e padrões técnicos

---

## Opções consideradas

### 1. Apenas repositórios de microsserviços

Cada microsserviço mantém integralmente:

* documentação
* contratos
* templates
* infraestrutura
* configurações compartilhadas

#### Vantagens

* máxima independência entre repositórios

#### Desvantagens

* duplicação de artefatos
* dificuldade de governança
* maior risco de divergência entre contratos e implementações

---

### 2. Repositório central apenas para documentação

Criar um repositório central contendo apenas:

* ADRs
* diagramas
* documentação

#### Vantagens

* centralização parcial do conhecimento

#### Desvantagens

* contratos e infraestrutura continuam dispersos
* baixa reutilização de componentes

---

### 3. Plataforma compartilhada com governança centralizada

Criar um repositório central responsável por concentrar os artefatos transversais da solução, mantendo os microsserviços em repositórios independentes.

#### Vantagens

* centralização dos contratos
* redução de duplicação
* maior consistência arquitetural
* melhor rastreabilidade das decisões
* simplificação da avaliação e manutenção da solução

#### Desvantagens

* necessidade de governança sobre os artefatos compartilhados
* risco de crescimento excessivo do repositório caso não haja critérios claros de utilização

---

## Decisão

Foi decidido utilizar um modelo de **governança multi-repositório com plataforma compartilhada**, adotando o repositório **oficina-platform** como repositório central de arquitetura, contratos, documentação, templates e infraestrutura compartilhada.

Os microsserviços permanecerão em repositórios independentes e continuarão sendo responsáveis por seu próprio ciclo de vida.

---

## Estrutura Definida

### Repositório Central

O repositório `oficina-platform` será responsável por armazenar:

* ADRs
* documentação arquitetural
* diagramas
* contratos OpenAPI
* contratos de eventos
* templates de projetos
* padrões de observabilidade
* componentes de infraestrutura compartilhada
* configurações base de Kubernetes

Estrutura prevista:

```text
oficina-platform
├── adrs
├── architecture
├── contracts
├── docs
├── templates
├── infra
│   ├── aws
│   ├── databases
│   ├── messaging
│   ├── kubernetes
│   └── observability
└── ci
```

### Microsserviços

Cada microsserviço possuirá repositório próprio contendo:

* código-fonte
* Dockerfile
* pipeline CI/CD
* manifestos específicos de implantação
* documentação do serviço
* testes
* banco de dados sob sua responsabilidade

Exemplos:

```text
oficina-os-service
oficina-billing-service
oficina-execution-service
```

---

## Convenção de Nomenclatura

Será adotado o padrão:

```text
oficina-<nome-do-servico>
```

Exemplos:

```text
oficina-os-service
oficina-billing-service
oficina-execution-service
```

Artefatos compartilhados permanecerão no repositório:

```text
oficina-platform
```

---

## Justificativa

A decisão foi baseada nos seguintes fatores:

* preserva a independência dos microsserviços
* reduz duplicação de documentação e contratos
* facilita a governança arquitetural
* melhora a rastreabilidade das decisões
* simplifica a manutenção dos padrões compartilhados
* facilita a compreensão da solução completa durante a avaliação do projeto

Além disso, o modelo adotado se aproxima de práticas utilizadas em iniciativas de Platform Engineering, nas quais equipes compartilham padrões e infraestrutura sem comprometer a autonomia dos serviços.

---

## Consequências

### Positivas

* Organização centralizada dos artefatos compartilhados
* Maior consistência entre serviços
* Menor duplicação de documentação
* Facilidade para evolução dos contratos
* Melhor rastreabilidade arquitetural
* Simplificação da manutenção dos padrões comuns

---

### Negativas

* Necessidade de governança do repositório central
* Possível aumento de acoplamento organizacional
* Necessidade de sincronização entre contratos e implementações

---

## Limites da Plataforma Compartilhada

O repositório `oficina-platform` não deverá conter:

* lógica de negócio dos microsserviços
* código-fonte das aplicações
* bancos de dados dos serviços
* implementações específicas dos domínios

Esses elementos permanecem sob responsabilidade exclusiva dos respectivos microsserviços.

---

## Impacto na Arquitetura

A arquitetura passa a ser organizada em duas camadas complementares:

### Camada de Plataforma

Responsável por:

* governança arquitetural
* contratos
* documentação
* infraestrutura compartilhada
* padrões técnicos

### Camada de Serviços

Responsável por:

* implementação dos domínios
* persistência dos dados
* APIs
* eventos
* implantação independente

Essa separação busca equilibrar padronização e autonomia.

---

## Próximos Passos

* Definir contratos OpenAPI dos microsserviços
* Definir contratos de eventos de domínio
* Definir estratégia de comunicação entre serviços
* Definir estratégia de Saga Pattern
* Definir estratégia de persistência por microsserviço
* Criar templates base para novos serviços
* Estruturar os componentes compartilhados de infraestrutura

---

## Observação Final

A adoção do repositório `oficina-platform` tem como objetivo centralizar artefatos compartilhados e decisões arquiteturais sem comprometer a independência dos microsserviços, promovendo uma arquitetura mais organizada, rastreável e aderente aos requisitos da Fase 4.
