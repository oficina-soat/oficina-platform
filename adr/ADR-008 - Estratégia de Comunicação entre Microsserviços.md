# ADR-008 - Estratégia de Comunicação entre Microsserviços

## Status

**Aceito**

---

## Contexto

A evolução da aplicação para uma arquitetura baseada em microsserviços exige a definição de mecanismos de comunicação que garantam autonomia dos serviços, baixo acoplamento e suporte a transações distribuídas.

Os requisitos da Fase 4 estabelecem que a solução deve utilizar:

* APIs RESTful síncronas quando necessário;
* Mensageria assíncrona para eventos e integração desacoplada;
* Microsserviços independentes;
* Bancos de dados independentes;
* Saga Pattern para coordenação de processos distribuídos;
* Observabilidade distribuída.

Além disso, nenhum microsserviço pode acessar diretamente o banco de dados de outro serviço.

A solução já adota a plataforma AWS como ambiente principal de execução, conforme definido na [ADR-001](ADR-001%20-%20Escolha%20da%20Plataforma%20de%20Nuvem.md).

---

## Problema

Definir uma estratégia de comunicação que:

* preserve a autonomia dos microsserviços;
* reduza o acoplamento entre componentes;
* suporte transações distribuídas;
* permita rastreamento dos fluxos de negócio;
* facilite a implementação do Saga Pattern;
* mantenha baixo custo operacional;
* possua integração simples com o ecossistema Quarkus.

---

## Opções consideradas

### 1. Comunicação exclusivamente via REST

Toda interação entre microsserviços ocorre através de chamadas HTTP síncronas.

#### Vantagens

* Simplicidade de implementação;
* Facilidade de depuração;
* Menor curva de aprendizado.

#### Desvantagens

* Alto acoplamento temporal;
* Menor resiliência;
* Maior risco de indisponibilidade em cascata;
* Pouco adequada para fluxos distribuídos complexos.

---

### 2. Comunicação exclusivamente baseada em eventos

Toda comunicação ocorre por meio de mensageria assíncrona.

#### Vantagens

* Baixo acoplamento;
* Alta escalabilidade;
* Maior resiliência.

#### Desvantagens

* Complexidade operacional;
* Maior dificuldade para consultas síncronas;
* Curva de aprendizado superior.

---

### 3. Comunicação híbrida (REST + Eventos)

Utilizar REST para interações síncronas e mensageria para eventos de domínio e integração assíncrona.

#### Vantagens

* Equilíbrio entre simplicidade e desacoplamento;
* Melhor aderência aos requisitos do projeto;
* Facilita implementação do Saga Pattern;
* Maior flexibilidade arquitetural;
* Redução de falhas em cascata.

#### Desvantagens

* Necessidade de manter dois modelos de comunicação;
* Maior governança sobre contratos e eventos.

---

### 4. RabbitMQ

Broker tradicional baseado em filas.

#### Vantagens

* Ampla adoção;
* Bom suporte a roteamento;
* Facilidade de entendimento.

#### Desvantagens

* Necessidade de administrar infraestrutura dedicada;
* Custo operacional superior ao modelo serverless adotado na AWS.

---

### 5. Apache Kafka

Plataforma de streaming distribuído.

#### Vantagens

* Alto desempenho;
* Retenção de eventos;
* Excelente suporte para múltiplos consumidores.

#### Desvantagens

* Complexidade elevada para o contexto do projeto;
* Custo operacional superior;
* Requisitos de infraestrutura mais complexos.

---

### 6. AWS SNS + SQS

Mensageria gerenciada baseada em tópicos e filas.

#### Vantagens

* Integração nativa com AWS;
* Modelo pay-per-use;
* Baixo custo operacional;
* Suporte nativo a DLQ;
* Escalabilidade automática;
* Integração com Quarkus através de extensões específicas.

#### Desvantagens

* Dependência da plataforma AWS;
* Menor portabilidade quando comparado a soluções independentes de nuvem.

---

## Decisão

Foi decidido adotar uma estratégia de comunicação híbrida composta por:

* APIs REST para comunicação síncrona;
* AWS SNS e AWS SQS para comunicação assíncrona baseada em eventos.

---

## Estratégia Definida

### Comunicação Síncrona

A comunicação REST será utilizada apenas quando houver necessidade de resposta imediata.

Casos típicos:

* consultas de informações;
* comandos que exigem retorno instantâneo;
* integrações externas;
* verificações de disponibilidade.

Todos os contratos REST deverão ser documentados através de OpenAPI.

Estrutura prevista:

```text
contracts/openapi
```

---

### Comunicação Assíncrona

A comunicação baseada em eventos será utilizada para:

* integração entre microsserviços;
* propagação de eventos de domínio;
* coordenação da Saga;
* notificações internas;
* processamento desacoplado.

Todos os eventos deverão possuir contrato versionado.

Estrutura prevista:

```text
contracts/events
```

---

### Infraestrutura de Mensageria

Será adotado o seguinte modelo:

```text
Produtor
    ↓
 SNS Topic
    ↓
 SQS Queue
    ↓
 Consumidor
```

Cada microsserviço será responsável por consumir apenas os eventos relevantes ao seu domínio.

---

## Contratos de Comunicação

### APIs

Todos os contratos REST serão mantidos no repositório:

```text
oficina-platform/contracts/openapi
```

---

### Eventos

Todos os eventos deverão possuir:

* identificador único;
* tipo do evento;
* data de ocorrência;
* versão do contrato;
* payload de domínio.

Exemplo:

```json
{
  "eventId": "uuid",
  "eventType": "OrcamentoAprovado",
  "version": "1.0",
  "timestamp": "2026-06-18T10:00:00Z",
  "osId": "uuid"
}
```

---

## Regras Arquiteturais

Os microsserviços deverão seguir obrigatoriamente as seguintes regras:

* Nenhum serviço acessa diretamente o banco de outro serviço;
* Toda integração ocorre por REST ou eventos;
* Contratos devem ser versionados;
* Eventos devem ser considerados imutáveis;
* Eventos não substituem consultas REST;
* APIs não substituem eventos de domínio.

---

## Justificativa

A decisão foi baseada nos seguintes fatores:

* Atendimento integral aos requisitos da Fase 4;
* Melhor equilíbrio entre simplicidade e desacoplamento;
* Facilidade de implementação da Saga;
* Baixo custo operacional;
* Integração nativa com a AWS;
* Integração simplificada com Quarkus através das extensões Amazon SNS e Amazon SQS;
* Redução do esforço de administração de infraestrutura.

Além disso, a utilização de SNS e SQS permite aproveitar o modelo serverless já adotado em outras partes da arquitetura.

---

## Consequências

### Positivas

* Redução de acoplamento entre microsserviços;
* Melhor tolerância a falhas;
* Escalabilidade independente;
* Facilidade para evolução dos serviços;
* Menor custo operacional;
* Maior aderência ao modelo distribuído.

---

### Negativas

* Necessidade de gerenciar contratos de eventos;
* Maior complexidade de rastreamento de fluxos;
* Dependência dos serviços de mensageria da AWS;
* Possibilidade de consistência eventual entre serviços.

---

## Considerações sobre Vendor Lock-in

A utilização de SNS e SQS aumenta o acoplamento à AWS.

Entretanto:

* a plataforma AWS já foi definida como padrão arquitetural na [ADR-001](ADR-001%20-%20Escolha%20da%20Plataforma%20de%20Nuvem.md);
* os benefícios operacionais superam os riscos para o contexto atual do projeto;
* os contratos de eventos permanecerão independentes da tecnologia utilizada.

Caso necessário, a camada de mensageria poderá ser substituída futuramente por RabbitMQ ou Kafka sem alterações significativas nas regras de negócio.

---

## Impacto na Arquitetura

A arquitetura passa a adotar dois modelos complementares de comunicação:

### Comunicação Síncrona

```text
Microsserviço
      ↓
 REST API
      ↓
Microsserviço
```

### Comunicação Assíncrona

```text
Microsserviço
      ↓
 SNS
      ↓
 SQS
      ↓
Microsserviço
```

Essa combinação fornece equilíbrio entre simplicidade operacional e desacoplamento arquitetural.

---

## Relação com ADRs Existentes

### [ADR-004 - Padrões de Comunicação](ADR-004%20-%20Padrões%20de%20comunicação.md)

**Status: Substituído por esta ADR**

A [ADR-004](ADR-004%20-%20Padrões%20de%20comunicação.md) foi criada em um contexto anterior à adoção da arquitetura de microsserviços da Fase 4.

Esta ADR amplia e substitui a estratégia anterior, incorporando:

* comunicação híbrida;
* eventos de domínio;
* mensageria;
* contratos versionados;
* restrições de acesso a dados;
* suporte ao Saga Pattern.

---

## Próximos Passos

* Definir contratos OpenAPI dos microsserviços;
* Definir catálogo de eventos de domínio;
* Definir convenção de versionamento de eventos;
* Criar tópicos SNS e filas SQS da solução;
* Implementar DLQs;
* Integrar observabilidade aos fluxos distribuídos;
* Implementar a estratégia de Saga definida na [ADR-009](ADR-009%20-%20Estratégia%20de%20Saga%20Pattern.md).

---

## Observação Final

A estratégia híbrida baseada em REST, SNS e SQS busca equilibrar simplicidade, custo, resiliência e desacoplamento, fornecendo uma base adequada para a evolução da arquitetura distribuída da oficina e para a implementação segura dos fluxos transacionais da Fase 4.
