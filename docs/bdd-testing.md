# Padrão BDD, Cobertura e Qualidade

## Objetivo

Definir o padrão mínimo de testes BDD, cobertura e qualidade para os repositórios `oficina-os-service`, `oficina-billing-service` e `oficina-execution-service`.

Este padrão complementa a [ADR-012 - Estratégia de CI/CD e Deploy Independente](../adr/ADR-012%20-%20Estratégia%20de%20CI%20CD%20e%20Deploy%20Independente.md), o [Template Quarkus de Microsserviço](../templates/quarkus-service/README.md), o [Template GitHub Actions para Microsserviços](../templates/github-actions/README.md), os [Fluxos da Saga da Ordem de Serviço](saga-flows.md), o [Contrato de Saga do oficina-os-service](../contracts/saga/oficina-os-saga-v1.md), o [Contrato de APIs REST](../contracts/Contrato%20de%20APIs%20REST.md), o [Contrato de Eventos de Domínio](../contracts/Contrato%20de%20Eventos%20de%20Domínio.md), o [Contrato de Erros REST](../contracts/error-model.md) e o [Contrato de Idempotência](../contracts/idempotency.md).

## Decisão

Os microsserviços devem usar:

- JUnit 5 e Quarkus Test para testes unitários, de integração e de contrato;
- Cucumber JVM com JUnit Platform para BDD;
- JaCoCo para cobertura mínima obrigatória de 80%;
- SonarCloud como Quality Gate obrigatório no CI.

O Cucumber deve usar a mesma versão em todas as dependências `io.cucumber`. O [template Maven](../templates/quarkus-service/pom.xml) define essa versão por `cucumber.version`.

## Estrutura por repositório

Cada microsserviço deve manter a estrutura mínima:

```text
src/test/java/br/com/oficina/<dominio>/
  unit/
  integration/
  contract/
  bdd/
src/test/resources/features/
```

Regras:

- testes unitários devem validar entidades, serviços de domínio, use cases, validadores e políticas de estado;
- testes de integração devem validar controllers, persistência, idempotência, Outbox, producers e consumers;
- testes de contrato devem validar rotas contra OpenAPI, eventos contra JSON Schema e erros contra o modelo padronizado;
- cenários BDD devem ficar em `src/test/resources/features/` e os steps em `src/test/java/.../bdd/`;
- cenários BDD que dependem de mais de um serviço devem usar ambiente de integração local ou ambiente `lab`, sem acessar diretamente banco de outro microsserviço.

## Cenário BDD obrigatório

Deve existir pelo menos um fluxo completo automatizado da Ordem de Serviço atravessando os três microsserviços.

O cenário feliz mínimo deve cobrir:

| Etapa | Serviço principal | Evidência esperada |
|---:|---|---|
| 1 | `oficina-os-service` | OS criada e evento `ordemDeServicoCriada` registrado. |
| 2 | `oficina-execution-service` | Diagnóstico iniciado e finalizado com eventos `diagnosticoIniciado` e `diagnosticoFinalizado`. |
| 3 | `oficina-billing-service` | Orçamento gerado e aprovado com eventos `orcamentoGerado` e `orcamentoAprovado`. |
| 4 | `oficina-execution-service` | Execução iniciada, finalizada e estoque baixado quando aplicável. |
| 5 | `oficina-billing-service` | Pagamento solicitado e confirmado. |
| 6 | `oficina-os-service` | OS entregue e Saga encerrada com `sagaFinalizadaComSucesso`. |

Também deve existir pelo menos um cenário de falha compensada. A opção canônica inicial é falha de estoque ou execução antes de `execucaoFinalizada`, resultando em `sagaCompensada`, conforme [Fluxos da Saga da Ordem de Serviço](saga-flows.md).

## Exemplo de feature

```gherkin
Feature: Saga da Ordem de Serviço

  Scenario: finalizar uma ordem de serviço com pagamento confirmado
    Given existe uma ordem de serviço recebida
    When o diagnóstico é concluído com itens de orçamento
    And o cliente aprova o orçamento
    And a execução técnica é finalizada
    And o pagamento é confirmado
    And o veículo é entregue
    Then a saga deve finalizar com sucesso
    And o evento sagaFinalizadaComSucesso deve ser publicado
```

Os steps devem validar os estados, eventos e respostas HTTP usando os contratos canônicos. Asserções baseadas apenas em status code não são suficientes.

## Cobertura mínima

Cada microsserviço deve falhar o build quando a cobertura de instruções do bundle ficar abaixo de 80%.

O relatório JaCoCo deve ser gerado em:

```text
target/jacoco-report/
```

O README de cada microsserviço deve registrar uma evidência de cobertura, como link para o artefato do GitHub Actions, badge ou captura anexada à entrega final. O checklist final da Fase 4 deve consolidar esses links quando for criado.

## CI/CD

O workflow padrão deve executar:

```bash
./mvnw -B verify -P"${MAVEN_PROFILE}" -DskipITs=false -DfailIfNoTests=false
```

O pipeline deve falhar quando:

- testes unitários, de integração, contrato ou BDD falharem;
- cobertura JaCoCo ficar abaixo de 80%;
- `SONAR_TOKEN`, `SONAR_ORGANIZATION` ou `SONAR_PROJECT_KEY` não estiverem configurados;
- o Quality Gate do SonarCloud não for aprovado.

## Critérios de pronto

Um microsserviço atende a este padrão quando:

- possui testes unitários, integração e contrato para seus fluxos críticos;
- participa do cenário BDD completo da OS ou possui os steps necessários para o cenário distribuído;
- mantém cobertura JaCoCo mínima de 80%;
- publica evidência de cobertura no README ou no artefato de CI;
- executa Quality Gate SonarCloud obrigatório;
- valida contratos OpenAPI, schemas JSON de eventos, erro padronizado, idempotência e Saga quando aplicável.
