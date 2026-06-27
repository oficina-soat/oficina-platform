# ADR-010 - Estratégia de Divisão dos Microsserviços

## Status

**Aceito**

---

## Contexto

A aplicação da oficina está sendo evoluída para uma arquitetura baseada em microsserviços, conforme os requisitos da Fase 4 do projeto.

O desafio exige a separação da solução em, no mínimo, três microsserviços independentes, cada um com:

* repositório próprio;
* infraestrutura própria;
* banco de dados próprio;
* pipeline independente de CI/CD;
* documentação própria;
* deploy automatizado em Kubernetes.

Além disso, a aplicação deve suportar comunicação entre microsserviços, mensageria assíncrona, Saga Pattern e observabilidade distribuída.

Antes de definir bancos de dados, contratos, eventos e pipelines, é necessário estabelecer os limites funcionais dos microsserviços.

---

## Problema

Definir uma divisão de microsserviços que:

* atenda aos requisitos obrigatórios da Fase 4;
* represente adequadamente os domínios da oficina;
* reduza acoplamento entre serviços;
* permita persistência independente;
* facilite a implementação da Saga;
* mantenha escopo viável para entrega do projeto.

---

## Opções consideradas

### 1. Separação técnica por camadas

Dividir a aplicação em serviços como:

* cadastro-service;
* ordem-service;
* pagamento-service;
* notificacao-service.

#### Vantagens

* Separação simples de entender inicialmente;
* Facilidade para reaproveitar partes da aplicação atual.

#### Desvantagens

* Baixa aderência a bounded contexts;
* Risco de acoplamento entre serviços;
* Fluxos de negócio espalhados;
* Menor clareza para implementação da Saga.

---

### 2. Separação granular por funcionalidades

Criar serviços pequenos e especializados, como:

* cliente-service;
* veiculo-service;
* ordem-service;
* orcamento-service;
* pagamento-service;
* execucao-service;
* estoque-service;
* notificacao-service.

#### Vantagens

* Alta especialização;
* Maior independência conceitual.

#### Desvantagens

* Excesso de repositórios;
* Maior complexidade de integração;
* Maior esforço de CI/CD e infraestrutura;
* Escopo elevado para o prazo da Fase 4.

---

### 3. Separação por capacidades principais do negócio

Dividir a solução em três microsserviços principais:

* OS Service;
* Billing Service;
* Execution Service.

#### Vantagens

* Aderência direta ao enunciado da Fase 4;
* Boa separação de responsabilidades;
* Escopo viável;
* Facilita a implementação da Saga;
* Permite bancos independentes;
* Reduz complexidade operacional.

#### Desvantagens

* Alguns subdomínios permanecem agrupados;
* Pode exigir nova decomposição em evoluções futuras.

---

## Decisão

Foi decidido dividir a aplicação em três microsserviços principais:

* **oficina-os-service**
* **oficina-billing-service**
* **oficina-execution-service**

Essa divisão será utilizada como base para as próximas decisões de persistência, contratos, eventos, CI/CD, infraestrutura e observabilidade.

---

## Estratégia Definida

### oficina-os-service

Responsável pelo ciclo de vida da Ordem de Serviço.

Responsabilidades principais:

* cadastro de clientes;
* cadastro de veículos;
* abertura de ordem de serviço;
* consulta de ordem de serviço;
* inclusão de peças e serviços na ordem de serviço com snapshot dos dados selecionados;
* atualização de status;
* manutenção do histórico de estados;
* controle do estado global da OS;
* coordenação da Saga, conforme definido na [ADR-009](ADR-009%20-%20Estratégia%20de%20Saga%20Pattern.md).

Este serviço representa o núcleo do fluxo de negócio.

---

### oficina-billing-service

Responsável por orçamento, aprovação e pagamento.

Responsabilidades principais:

* geração de orçamento;
* registro da aprovação ou rejeição do orçamento;
* controle do estado financeiro associado à OS;
* integração com Mercado Pago;
* confirmação de pagamento;
* emissão de eventos relacionados a orçamento e pagamento.

Este serviço concentra as regras financeiras do processo.

---

### oficina-execution-service

Responsável pela execução operacional da ordem de serviço.

Responsabilidades principais:

* catálogo técnico de serviços;
* catálogo técnico de peças;
* controle de estoque de peças;
* gerenciamento da fila de execução;
* registro de diagnóstico;
* registro do andamento dos reparos;
* atualização do estado da execução;
* comunicação de conclusão da execução;
* emissão de eventos operacionais.

Este serviço concentra as atividades de diagnóstico, produção e reparo.

---

## Limites entre os Serviços

Cada microsserviço será dono exclusivo dos seus dados.

Nenhum serviço poderá acessar diretamente o banco de dados de outro serviço.

A comunicação entre serviços deverá ocorrer exclusivamente por:

* APIs REST, quando houver necessidade de comunicação síncrona;
* eventos assíncronos via mensageria, conforme definido na [ADR-008](ADR-008%20-%20Estratégia%20de%20Comunicação%20entre%20Microsserviços.md).

---

## Relação com a Saga

A divisão dos microsserviços foi definida considerando o fluxo principal da Saga:

```text
Criar OS
    ↓
Gerar orçamento
    ↓
Aguardar aprovação
    ↓
Confirmar pagamento
    ↓
Iniciar execução
    ↓
Finalizar execução
    ↓
Encerrar OS
```

O `oficina-os-service` coordenará a Saga.

O `oficina-billing-service` participará das etapas financeiras.

O `oficina-execution-service` participará das etapas operacionais.

---

## Justificativa

A decisão foi baseada nos seguintes fatores:

* atende ao requisito mínimo de três microsserviços independentes;
* mantém a solução aderente ao domínio da oficina;
* evita decomposição excessiva;
* facilita a implementação e demonstração do Saga Pattern;
* permite bancos independentes por serviço;
* reduz o esforço operacional da entrega;
* mantém clareza para a avaliação da arquitetura.

Além disso, a divisão proposta segue as capacidades principais do negócio: gestão da OS, cobrança e execução.

---

## Consequências

### Positivas

* Separação clara de responsabilidades;
* Melhor aderência ao modelo de microsserviços;
* Facilita testes independentes;
* Permite CI/CD independente;
* Permite persistência independente;
* Facilita documentação e demonstração da solução.

---

### Negativas

* Alguns domínios auxiliares não terão microsserviço próprio neste momento;
* Pode haver necessidade futura de separar novos serviços;
* O OS Service concentrará maior responsabilidade por coordenar o fluxo global.

---

## Impacto na Arquitetura

A arquitetura passa a ser composta inicialmente pelos seguintes microsserviços:

```text
oficina-os-service
    ↓
oficina-billing-service
    ↓
oficina-execution-service
```

A comunicação entre eles seguirá a estratégia definida na [ADR-008](ADR-008%20-%20Estratégia%20de%20Comunicação%20entre%20Microsserviços.md).

A coordenação transacional seguirá a estratégia definida na [ADR-009](ADR-009%20-%20Estratégia%20de%20Saga%20Pattern.md).

A persistência será definida em ADR específica posterior.

## Estado de Implementação

Os repositórios independentes previstos por esta ADR foram criados na suíte:

```text
../oficina-os-service
../oficina-billing-service
../oficina-execution-service
```

Esses repositórios devem continuar seguindo os contratos, ADRs e padrões definidos no `oficina-platform`.

---

## Relação com ADRs Existentes

### [ADR-007 - Governança Multi-Repositório e Plataforma Compartilhada](ADR-007%20-%20Governança%20Multi-Repositório%20e%20Plataforma%20Compartilhada.md)

Esta ADR complementa a [ADR-007](ADR-007%20-%20Governança%20Multi-Repositório%20e%20Plataforma%20Compartilhada.md), pois define quais repositórios de microsserviços serão criados inicialmente.

### [ADR-008 - Estratégia de Comunicação entre Microsserviços](ADR-008%20-%20Estratégia%20de%20Comunicação%20entre%20Microsserviços.md)

Esta ADR complementa a [ADR-008](ADR-008%20-%20Estratégia%20de%20Comunicação%20entre%20Microsserviços.md), pois define os serviços que utilizarão comunicação REST e mensageria.

### [ADR-009 - Estratégia de Saga Pattern](ADR-009%20-%20Estratégia%20de%20Saga%20Pattern.md)

Esta ADR complementa a [ADR-009](ADR-009%20-%20Estratégia%20de%20Saga%20Pattern.md), pois define os participantes da Saga.

---

## Próximos Passos

* Evoluir a estrutura base dos repositórios dos microsserviços;
* Definir os contratos OpenAPI de cada serviço;
* Definir os eventos de domínio entre os serviços;
* Definir a estratégia de persistência de cada microsserviço;
* Definir os pipelines independentes de CI/CD;
* Definir os manifestos Kubernetes específicos de cada serviço.

---

## Observação Final

A divisão em `oficina-os-service`, `oficina-billing-service` e `oficina-execution-service` busca equilibrar aderência ao domínio, simplicidade de entrega e independência arquitetural, atendendo aos requisitos da Fase 4 sem introduzir decomposição excessiva para o escopo atual do projeto.
