# ADR-011 - Estratégia de Persistência Poliglota por Microsserviço

## Status

**Aceito**

---

## Contexto

A arquitetura da aplicação foi evoluída para um modelo baseado em microsserviços independentes.

As ADRs anteriores estabeleceram:

* Governança multi-repositório ([ADR-007](ADR-007%20-%20Governança%20Multi-Repositório%20e%20Plataforma%20Compartilhada.md));
* Estratégia de comunicação entre microsserviços ([ADR-008](ADR-008%20-%20Estratégia%20de%20Comunicação%20entre%20Microsserviços.md));
* Utilização de Saga Pattern para coordenação transacional ([ADR-009](ADR-009%20-%20Estratégia%20de%20Saga%20Pattern.md));
* Divisão da solução em microsserviços independentes ([ADR-010](ADR-010%20-%20Estratégia%20de%20Divisão%20dos%20Microsserviços.md));
* Utilização da AWS como plataforma principal da solução ([ADR-001](ADR-001%20-%20Escolha%20da%20Plataforma%20de%20Nuvem.md)).

Além disso, os requisitos da Fase 4 estabelecem que:

* cada microsserviço deve possuir banco de dados próprio;
* nenhum serviço pode acessar diretamente o banco de outro serviço;
* deve existir pelo menos um banco relacional;
* deve existir pelo menos um banco não relacional.

A solução atual já utiliza Amazon RDS for PostgreSQL como banco de dados gerenciado, reduzindo riscos de migração e aproveitando a experiência acumulada pela equipe.

Dessa forma, torna-se necessário definir uma estratégia de persistência adequada para cada domínio da aplicação.

---

## Problema

Definir uma estratégia de persistência que:

* atenda aos requisitos obrigatórios da Fase 4;
* preserve a independência dos microsserviços;
* reduza acoplamento entre domínios;
* permita evolução independente dos modelos de dados;
* mantenha baixo custo operacional;
* aproveite os serviços já adotados na AWS;
* mantenha o escopo compatível com a entrega da Fase 4.

---

## Opções consideradas

### 1. Banco de dados único compartilhado

Todos os microsserviços utilizam o mesmo banco de dados.

#### Vantagens

* Simplicidade inicial;
* Menor quantidade de infraestrutura.

#### Desvantagens

* Viola os princípios de microsserviços;
* Forte acoplamento entre serviços;
* Baixa autonomia;
* Dificulta evolução independente.

---

### 2. Bancos independentes utilizando apenas PostgreSQL

Cada microsserviço possui seu próprio banco PostgreSQL.

#### Vantagens

* Forte consistência;
* Simplicidade operacional;
* Tecnologia já conhecida pela equipe.

#### Desvantagens

* Não atende plenamente à persistência poliglota;
* Não explora características específicas de bancos NoSQL;
* Não atende ao requisito de utilização de banco não relacional.

---

### 3. Persistência poliglota por domínio

Cada microsserviço utiliza a tecnologia de persistência mais adequada ao seu contexto.

#### Vantagens

* Melhor aderência ao domínio;
* Independência tecnológica;
* Escalabilidade específica por serviço;
* Atendimento integral aos requisitos da Fase 4.

#### Desvantagens

* Maior diversidade tecnológica;
* Necessidade de conhecimento em múltiplas tecnologias.

---

## Decisão

Foi decidido adotar uma estratégia de **persistência poliglota por microsserviço**, utilizando:

* Amazon RDS for PostgreSQL para o OS Service;
* Amazon RDS for PostgreSQL para o Billing Service;
* Amazon DynamoDB para o Execution Service.

Cada serviço será proprietário exclusivo dos seus dados.

---

## Estratégia Definida

### oficina-os-service

Tecnologia:

```text
Amazon RDS for PostgreSQL
```

Responsável por armazenar:

* clientes;
* veículos;
* peças;
* serviços;
* ordens de serviço;
* itens da ordem de serviço;
* histórico de estados;
* dados da Saga.

Motivos:

* forte relacionamento entre entidades;
* necessidade de consistência transacional;
* manutenção do estado global da ordem de serviço;
* rastreabilidade e auditoria do processo de negócio.

Nesta fase, os cadastros de clientes, veículos, peças e serviços permanecerão neste microsserviço para evitar decomposição excessiva da solução.

---

### oficina-billing-service

Tecnologia:

```text
Amazon RDS for PostgreSQL
```

Responsável por armazenar:

* orçamentos;
* aprovações;
* pagamentos;
* integrações financeiras;
* histórico financeiro da ordem de serviço.

Motivos:

* necessidade de integridade transacional;
* consistência financeira;
* rastreabilidade das operações monetárias.

---

### oficina-execution-service

Tecnologia:

```text
Amazon DynamoDB
```

Responsável por armazenar:

* fila de execução;
* diagnósticos;
* registros operacionais;
* andamento dos reparos;
* execução de serviços;
* consumo de peças durante a execução;
* histórico operacional da execução.

Motivos:

* modelo flexível de dados;
* escalabilidade automática;
* arquitetura serverless;
* baixo custo operacional;
* cobrança baseada em utilização;
* integração nativa com AWS.

---

## Propriedade dos Dados

Cada microsserviço será proprietário exclusivo do seu banco.

Regra obrigatória:

```text
Um serviço nunca acessa diretamente o banco de outro serviço.
```

Toda integração deverá ocorrer através de:

* APIs REST;
* eventos de domínio.

Conforme definido na [ADR-008](ADR-008%20-%20Estratégia%20de%20Comunicação%20entre%20Microsserviços.md).

---

## Consistência dos Dados

Não serão utilizadas transações distribuídas.

A consistência entre serviços será mantida através de:

* Saga Pattern;
* eventos de domínio;
* compensações;
* consistência eventual.

Conforme definido na [ADR-009](ADR-009%20-%20Estratégia%20de%20Saga%20Pattern.md).

---

## Estratégia de Migração

Cada microsserviço deverá gerenciar suas próprias migrações.

Exemplos:

```text
Flyway
Liquibase
```

As migrações serão independentes entre serviços.

Nenhum microsserviço poderá alterar estruturas pertencentes a outro domínio.

Para os serviços baseados em PostgreSQL, as migrações serão executadas sobre instâncias independentes do Amazon RDS.

---

## Estratégia de Backup

Cada banco deverá possuir política de backup independente.

### Amazon RDS for PostgreSQL

Responsável por:

* backup transacional;
* recuperação de histórico;
* retenção operacional;
* recuperação automática conforme políticas configuradas no RDS.

### Amazon DynamoDB

Responsável por:

* snapshots;
* recuperação pontual (Point-in-Time Recovery);
* retenção operacional.

---

## Justificativa

A decisão foi baseada nos seguintes fatores:

* atendimento integral aos requisitos da Fase 4;
* independência dos microsserviços;
* aderência ao domínio de negócio;
* baixo custo operacional;
* aproveitamento dos serviços gerenciados da AWS;
* facilidade de evolução futura.

Além disso:

* o Amazon RDS for PostgreSQL já faz parte da arquitetura da solução e reduz riscos de migração;
* PostgreSQL permanece nos domínios que exigem forte consistência transacional;
* Amazon DynamoDB atende ao requisito de banco não relacional com baixo custo operacional;
* DynamoDB elimina a necessidade de administrar infraestrutura dedicada para o banco NoSQL;
* a concentração dos cadastros de clientes, veículos, peças e serviços no OS Service reduz a complexidade da solução sem comprometer os objetivos da Fase 4.

---

## Consequências

### Positivas

* Independência dos serviços;
* Evolução independente dos modelos de dados;
* Melhor aderência tecnológica por domínio;
* Redução de acoplamento;
* Escalabilidade específica por serviço;
* Atendimento aos requisitos da Fase 4;
* Escopo compatível com o prazo do projeto;
* Redução do esforço operacional através de serviços gerenciados.

---

### Negativas

* Maior diversidade tecnológica;
* Necessidade de monitorar múltiplas tecnologias;
* Curva de aprendizado adicional para DynamoDB;
* Clientes, veículos, peças e serviços permanecem agrupados no OS Service;
* Dependência adicional dos serviços gerenciados da AWS.

---

## Evolução Futura

A arquitetura permite que alguns domínios sejam extraídos futuramente para microsserviços próprios, caso haja necessidade de maior autonomia.

Possíveis evoluções:

```text
oficina-customer-service
oficina-vehicle-service
oficina-catalog-service
```

Essa decomposição não faz parte do escopo atual da Fase 4.

---

## Impacto na Arquitetura

A arquitetura passa a possuir persistência distribuída:

```text
OS Service
    ↓
Amazon RDS for PostgreSQL

Billing Service
    ↓
Amazon RDS for PostgreSQL

Execution Service
    ↓
Amazon DynamoDB
```

Os dados passam a ser distribuídos entre domínios independentes, eliminando dependências diretas entre serviços.

---

## Relação com ADRs Existentes

### [ADR-002 - Estratégia de Banco de Dados](ADR-002%20-%20Estratégia%20de%20Banco%20de%20Dados.md)

**Status: Substituída por esta ADR**

A [ADR-002](ADR-002%20-%20Estratégia%20de%20Banco%20de%20Dados.md) foi criada em um contexto anterior à adoção de microsserviços.

A nova arquitetura exige:

* bancos independentes;
* ownership dos dados;
* persistência poliglota;
* consistência distribuída.

Essas decisões passam a ser formalizadas nesta ADR.

### [ADR-008 - Estratégia de Comunicação entre Microsserviços](ADR-008%20-%20Estratégia%20de%20Comunicação%20entre%20Microsserviços.md)

Complementa esta ADR ao definir os mecanismos de integração entre serviços.

### [ADR-009 - Estratégia de Saga Pattern](ADR-009%20-%20Estratégia%20de%20Saga%20Pattern.md)

Complementa esta ADR ao definir como a consistência distribuída será mantida.

### [ADR-010 - Estratégia de Divisão dos Microsserviços](ADR-010%20-%20Estratégia%20de%20Divisão%20dos%20Microsserviços.md)

Fornece os limites dos domínios que orientam a estratégia de persistência.

---

## Próximos Passos

* Provisionar os bancos dos microsserviços;
* Definir os modelos de dados de cada domínio;
* Configurar estratégias de migração;
* Definir políticas de backup;
* Integrar observabilidade dos bancos;
* Implementar persistência da Saga no OS Service.

---

## Observação Final

A estratégia de persistência poliglota busca equilibrar independência, baixo custo, aderência ao domínio e requisitos da Fase 4, permitindo que cada microsserviço evolua de forma autônoma sem comprometer a consistência global do processo de negócio, mantendo ao mesmo tempo um escopo viável para a entrega do projeto e aproveitando os serviços gerenciados já adotados na AWS.
