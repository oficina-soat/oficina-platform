# ADR-012 - Estratégia de CI/CD e Deploy Independente

## Status

**Aceito**

---

## Contexto

A arquitetura da aplicação foi evoluída para um modelo baseado em microsserviços independentes.

Os requisitos do projeto estabelecem que cada microsserviço deve possuir:

* repositório próprio;
* pipeline independente de CI/CD;
* testes automatizados;
* validação de qualidade de código;
* deploy automatizado em Kubernetes;
* proteção da branch principal com Pull Request obrigatório e verificações automáticas.

Além disso, as ADRs anteriores definiram:

* AWS como plataforma principal da solução ([ADR-001](ADR-001%20-%20Escolha%20da%20Plataforma%20de%20Nuvem.md));
* governança multi-repositório ([ADR-007](ADR-007%20-%20Governança%20Multi-Repositório%20e%20Plataforma%20Compartilhada.md));
* comunicação entre microsserviços ([ADR-008](ADR-008%20-%20Estratégia%20de%20Comunicação%20entre%20Microsserviços.md));
* Saga Pattern ([ADR-009](ADR-009%20-%20Estratégia%20de%20Saga%20Pattern.md));
* divisão dos microsserviços ([ADR-010](ADR-010%20-%20Estratégia%20de%20Divisão%20dos%20Microsserviços.md));
* persistência distribuída ([ADR-011](ADR-011%20-%20Estratégia%20de%20Persistência%20Poliglota%20por%20Microsserviço.md)).

Torna-se necessário definir uma estratégia padronizada de integração contínua e entrega contínua para todos os serviços da solução.

---

## Problema

Definir uma estratégia de CI/CD que:

* atenda aos requisitos obrigatórios do projeto;
* permita deploy independente por microsserviço;
* reduza esforço operacional;
* mantenha baixo custo;
* garanta qualidade mínima do código;
* facilite a manutenção dos pipelines;
* seja compatível com a infraestrutura AWS adotada.

---

## Opções consideradas

### 1. Pipeline único para toda a solução

Um único pipeline responsável por todos os microsserviços.

#### Vantagens

* Administração centralizada;
* Menor quantidade de pipelines.

#### Desvantagens

* Viola a independência dos microsserviços;
* Aumenta acoplamento entre serviços;
* Dificulta deploys independentes;
* Contraria os requisitos do projeto.

---

### 2. Pipelines independentes por microsserviço

Cada serviço possui seu próprio pipeline.

#### Vantagens

* Independência de implantação;
* Escalabilidade organizacional;
* Melhor isolamento entre serviços;
* Aderência aos requisitos do projeto.

#### Desvantagens

* Maior quantidade de pipelines;
* Necessidade de padronização entre repositórios.

---

### 3. SonarQube Self-Hosted

Hospedar internamente a plataforma de análise de qualidade.

#### Vantagens

* Controle total da solução;
* Independência de serviços externos.

#### Desvantagens

* Necessidade de infraestrutura adicional;
* Custos operacionais maiores;
* Maior esforço de manutenção.

---

### 4. SonarCloud

Utilizar serviço gerenciado para análise de qualidade.

#### Vantagens

* Sem infraestrutura adicional;
* Integração nativa com GitHub Actions;
* Menor custo operacional;
* Facilidade de configuração.

#### Desvantagens

* Dependência de serviço externo;
* Menor controle sobre a plataforma.

---

## Decisão

Foi decidido adotar:

* GitHub Actions como plataforma de CI/CD;
* pipelines independentes para cada microsserviço;
* SonarCloud para análise de qualidade;
* Amazon ECR para armazenamento de imagens Docker;
* Amazon EKS para execução dos microsserviços;
* deploy automático após aprovação e merge na branch principal.

---

## Estratégia Definida

Cada microsserviço possuirá seu próprio pipeline.

Exemplos:

```text id="wygaj4"
oficina-os-service
oficina-billing-service
oficina-execution-service
```

Todos os pipelines seguirão o mesmo padrão arquitetural.

---

## Fluxo de Integração Contínua

A cada Pull Request:

```text id="8vsg7x"
Pull Request
      ↓
Build
      ↓
Testes Unitários
      ↓
Cobertura de Código
      ↓
Análise SonarCloud
      ↓
Quality Gate
```

O merge somente poderá ocorrer após aprovação das verificações obrigatórias.

---

## Fluxo de Entrega Contínua

Após merge na branch principal:

```text id="9l9y3p"
Merge na main
        ↓
Build Docker
        ↓
Push para Amazon ECR
        ↓
Deploy no Amazon EKS
```

Cada microsserviço poderá ser implantado sem necessidade de deploy dos demais.

---

## Estrutura dos Pipelines

Todos os pipelines deverão conter as seguintes etapas mínimas:

### Build

Responsável por:

* compilação da aplicação;
* validação das dependências;
* geração dos artefatos.

---

### Testes

Responsável por:

* execução de testes unitários;
* validação das regras de negócio;
* geração dos relatórios de cobertura.

---

### Qualidade

Responsável por:

* análise estática;
* identificação de vulnerabilidades;
* validação do Quality Gate.

Ferramenta:

```text id="p2lkg2"
SonarCloud
```

---

### Containerização

Responsável por:

* construção da imagem Docker;
* versionamento da imagem;
* publicação no Amazon ECR.

---

### Deploy

Responsável por:

* atualização dos manifests Kubernetes;
* implantação no Amazon EKS;
* validação básica do rollout.

---

## Estratégia de Ambientes

Será adotado um ambiente principal para execução da solução.

Fluxo:

```text id="ryg50h"
main
  ↓
Deploy Automático
  ↓
Amazon EKS
```

A criação de ambientes adicionais não faz parte do escopo atual.

Essa decisão reduz:

* custo operacional;
* complexidade de infraestrutura;
* tempo de manutenção.

---

## Proteção de Repositórios

Todos os repositórios deverão possuir:

* branch `main` protegida;
* Pull Request obrigatório;
* aprovação obrigatória para merge;
* execução automática dos pipelines;
* bloqueio de merge em caso de falha.

---

## Padronização

Os templates de pipeline serão mantidos no repositório:

```text id="8k8qpd"
oficina-platform
```

Objetivos:

* reduzir duplicação;
* facilitar manutenção;
* garantir consistência entre os serviços.

---

## Justificativa

A decisão foi baseada nos seguintes fatores:

* atendimento integral aos requisitos do projeto;
* independência dos microsserviços;
* baixo custo operacional;
* simplicidade de manutenção;
* aproveitamento da integração entre GitHub e AWS;
* redução do esforço de administração da infraestrutura.

Além disso:

* GitHub Actions já faz parte do ecossistema utilizado pelo projeto;
* SonarCloud elimina a necessidade de hospedar um SonarQube próprio;
* Amazon ECR integra-se naturalmente ao Amazon EKS;
* pipelines independentes reforçam a autonomia dos microsserviços.

---

## Consequências

### Positivas

* Deploy independente por serviço;
* Maior autonomia dos microsserviços;
* Redução de acoplamento operacional;
* Melhor rastreabilidade das entregas;
* Menor custo de manutenção;
* Aderência aos requisitos do projeto.

---

### Negativas

* Maior quantidade de pipelines para administrar;
* Dependência de serviços externos;
* Necessidade de manter padronização entre repositórios.

---

## Impacto na Arquitetura

A arquitetura passa a possuir uma cadeia completa de entrega contínua:

```text id="x8xshn"
GitHub
    ↓
GitHub Actions
    ↓
SonarCloud
    ↓
Amazon ECR
    ↓
Amazon EKS
```

Cada microsserviço percorre esse fluxo de forma independente.

---

## Relação com ADRs Existentes

### [ADR-007 - Governança Multi-Repositório](ADR-007%20-%20Governança%20Multi-Repositório%20e%20Plataforma%20Compartilhada.md)

Complementa esta ADR ao definir a organização dos repositórios.

### [ADR-010 - Estratégia de Divisão dos Microsserviços](ADR-010%20-%20Estratégia%20de%20Divisão%20dos%20Microsserviços.md)

Define os serviços que possuirão pipelines independentes.

### [ADR-011 - Estratégia de Persistência Poliglota por Microsserviço](ADR-011%20-%20Estratégia%20de%20Persistência%20Poliglota%20por%20Microsserviço.md)

Define os componentes de persistência que serão implantados e utilizados pelos microsserviços.

---

## Próximos Passos

* Aplicar o template padrão de GitHub Actions nos repositórios dos microsserviços;
* Configurar SonarCloud para os repositórios;
* Configurar Amazon ECR;
* Configurar deploy automatizado para o Amazon EKS;
* Implementar políticas de proteção da branch principal;
* Criar documentação operacional dos pipelines.

---

## Observação Final

A estratégia adotada busca equilibrar independência, qualidade, automação e baixo custo operacional, garantindo que cada microsserviço possa evoluir e ser implantado de forma autônoma, mantendo aderência aos requisitos do projeto e às decisões arquiteturais previamente estabelecidas.
