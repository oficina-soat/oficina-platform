# ADR-009 - Estratégia de Saga Pattern

## Status

**Aceito**

---

## Contexto

A evolução da aplicação para uma arquitetura baseada em microsserviços introduz o desafio de manter consistência entre operações distribuídas executadas por serviços independentes.

Os requisitos da Fase 4 estabelecem a necessidade de utilização do Saga Pattern para coordenar processos distribuídos, garantindo tratamento adequado de falhas e execução de ações compensatórias quando necessário.

Entre os principais fluxos de negócio da oficina estão:

* abertura de ordem de serviço;
* geração de orçamento;
* aprovação ou rejeição do orçamento;
* execução dos serviços;
* encerramento da ordem de serviço.

Essas operações passam a ser executadas por microsserviços independentes, cada um responsável por seu próprio banco de dados e regras de negócio.

Nesse cenário, não é possível utilizar transações distribuídas tradicionais (2PC), sendo necessária a adoção de um mecanismo compatível com arquiteturas distribuídas.

---

## Problema

Definir uma estratégia de coordenação transacional que:

* mantenha consistência entre microsserviços;
* permita compensação em caso de falha;
* reduza acoplamento técnico;
* facilite observabilidade dos fluxos;
* seja compatível com a arquitetura definida para a Fase 4;
* simplifique testes e demonstrações da solução.

---

## Opções consideradas

### 1. Transações Distribuídas (2PC)

Utilizar coordenação transacional tradicional entre serviços.

#### Vantagens

* Forte consistência transacional;
* Modelo conhecido em sistemas monolíticos.

#### Desvantagens

* Elevado acoplamento;
* Baixa escalabilidade;
* Incompatibilidade com a arquitetura proposta;
* Complexidade operacional elevada.

---

### 2. Saga Coreografada

Cada microsserviço reage a eventos produzidos por outros serviços.

#### Vantagens

* Menor acoplamento central;
* Arquitetura altamente distribuída;
* Boa escalabilidade.

#### Desvantagens

* Fluxo de negócio distribuído entre múltiplos serviços;
* Maior dificuldade de rastreamento;
* Compensações dispersas;
* Maior complexidade de manutenção e testes.

---

### 3. Saga Orquestrada

Um coordenador central controla o fluxo da transação distribuída e aciona os microsserviços participantes.

#### Vantagens

* Fluxo explícito e centralizado;
* Facilidade de observabilidade;
* Simplificação das compensações;
* Maior facilidade para testes e depuração;
* Melhor compreensão do processo de negócio.

#### Desvantagens

* Introdução de um componente coordenador;
* Possível concentração de responsabilidades.

---

## Decisão

Foi decidido utilizar o padrão **Saga Orquestrada** para coordenar os processos distribuídos da aplicação.

O coordenador da Saga será implementado dentro do **OS Service**, responsável pelo ciclo de vida da Ordem de Serviço.

Não será criado um microsserviço dedicado exclusivamente à orquestração.

---

## Estratégia Definida

O OS Service atuará como agregado raiz do processo de negócio e será responsável por:

* iniciar a Saga;
* acompanhar o estado da execução;
* enviar comandos para os serviços participantes;
* receber eventos de conclusão;
* executar ações compensatórias quando necessário;
* encerrar a Saga com sucesso ou falha.

Estrutura conceitual:

```text
OS Service
├── API
├── Persistência
├── Gestão da Ordem de Serviço
└── Saga Coordinator
```

---

## Fluxo Principal

O fluxo principal da Ordem de Serviço será executado conforme a sequência abaixo:

```text
Criar OS
        ↓
Diagnóstico
        ↓
Gerar orçamento
        ↓
Aguardar aprovação
        ↓
Iniciar execução
        ↓
Finalizar execução
        ↓
Confirmar pagamento
        ↓
Entregar veículo
```

O fluxo detalhado, incluindo compensações, timeouts, retentativas e testes de contrato, está definido em [Fluxos da Saga da Ordem de Serviço](../docs/architecture/saga-flows.md) e no [Contrato de Saga do oficina-os-service](../contracts/saga/oficina-os-saga-v1.md).

Participantes:

```text
OS Service
Billing Service
Execution Service
```

---

## Fluxo de Coordenação

Fluxo simplificado:

```text
OS Service
        ↓
Solicita geração de orçamento
        ↓
Billing Service
        ↓
Evento: orçamento gerado
        ↓
OS Service
        ↓
Aguardar aprovação
        ↓
Evento: orçamento aprovado
        ↓
OS Service
        ↓
Solicita execução
        ↓
Execution Service
        ↓
Evento: execução concluída
        ↓
OS Service
        ↓
Encerrar ordem de serviço
```

---

## Estratégia de Compensação

Cada etapa da Saga deverá possuir uma ação compensatória correspondente.

Exemplos:

| Etapa             | Compensação         |
| ----------------- | ------------------- |
| Criar OS          | Cancelar OS         |
| Gerar orçamento   | Invalidar orçamento |
| Aprovar orçamento | Reverter aprovação  |
| Iniciar execução  | Cancelar execução   |
| Encerrar OS       | Reabrir OS          |

As compensações serão executadas pelo coordenador da Saga em ordem inversa à execução original.

---

## Persistência do Estado da Saga

O estado da execução da Saga deverá ser persistido.

Informações mínimas:

* identificador da Saga;
* identificador da OS;
* estado atual;
* etapa corrente;
* data de criação;
* data de atualização;
* histórico de transições.

Objetivos:

* recuperação após falhas;
* rastreabilidade;
* observabilidade;
* auditoria.

---

## Integração com a Estratégia de Comunicação

Esta ADR complementa a [ADR-008](ADR-008%20-%20Estratégia%20de%20Comunicação%20entre%20Microsserviços.md).

A coordenação da Saga utilizará:

### Comunicação Síncrona

Utilizada quando houver necessidade de resposta imediata.

Exemplos:

* consultas;
* validações;
* operações de leitura.

### Comunicação Assíncrona

Utilizada para:

* eventos de domínio;
* confirmação de etapas;
* notificações de conclusão;
* compensações.

Infraestrutura utilizada:

```text
SNS
 ↓
SQS
 ↓
Consumidores
```

---

## Regras Arquiteturais

Os microsserviços participantes deverão seguir obrigatoriamente as seguintes regras:

* Cada serviço controla apenas seus próprios dados;
* Nenhum serviço acessa diretamente o banco de outro serviço;
* Eventos devem ser idempotentes;
* Operações compensatórias devem ser idempotentes;
* Falhas devem gerar eventos rastreáveis;
* O coordenador da Saga é a única autoridade sobre o estado global do processo.

---

## Justificativa

A decisão foi baseada nos seguintes fatores:

* Atendimento direto aos requisitos da Fase 4;
* Facilidade de demonstração da solução;
* Melhor rastreabilidade dos fluxos distribuídos;
* Simplificação da implementação das compensações;
* Redução da complexidade operacional quando comparada à coreografia;
* Melhor integração com observabilidade distribuída.

Além disso, a Ordem de Serviço representa o agregado central do domínio, tornando o OS Service o local mais adequado para coordenar o processo de negócio completo.

---

## Consequências

### Positivas

* Fluxo de negócio claramente definido;
* Facilidade de monitoramento;
* Implementação simplificada das compensações;
* Melhor experiência de depuração;
* Maior previsibilidade operacional;
* Facilidade para testes BDD.

---

### Negativas

* Maior responsabilidade atribuída ao OS Service;
* Necessidade de persistência do estado da Saga;
* Possível aumento da complexidade interna do OS Service.

---

## Impacto na Arquitetura

A arquitetura passa a incluir explicitamente um coordenador de Saga dentro do OS Service.

Estrutura conceitual:

```text
                OS Service
                      │
             Saga Coordinator
              │           │
              │           │
      Billing Service   Execution Service
```

O coordenador será responsável pela visão global do processo, enquanto cada microsserviço permanecerá responsável apenas por suas regras de negócio e persistência local.

---

## Relação com ADRs Existentes

### [ADR-008 - Estratégia de Comunicação entre Microsserviços](ADR-008%20-%20Estratégia%20de%20Comunicação%20entre%20Microsserviços.md)

Esta ADR complementa a [ADR-008](ADR-008%20-%20Estratégia%20de%20Comunicação%20entre%20Microsserviços.md).

A [ADR-008](ADR-008%20-%20Estratégia%20de%20Comunicação%20entre%20Microsserviços.md) define os mecanismos de comunicação.

A ADR-009 define como esses mecanismos serão utilizados para coordenar transações distribuídas e compensações.

---

## Próximos Passos

* Definir estados da Saga;
* Definir eventos de domínio utilizados pela coordenação;
* Criar contratos dos eventos de compensação;
* Implementar persistência do estado da Saga;
* Integrar observabilidade distribuída ao fluxo da Saga;
* Criar cenários BDD para sucesso e falha;
* Implementar mecanismos de retry e tratamento de falhas.

---

## Observação Final

A adoção de uma Saga Orquestrada coordenada pelo OS Service busca equilibrar simplicidade, rastreabilidade e consistência, fornecendo uma solução adequada para os fluxos distribuídos da oficina e para os requisitos da Fase 4 sem introduzir um microsserviço adicional exclusivamente para orquestração.
