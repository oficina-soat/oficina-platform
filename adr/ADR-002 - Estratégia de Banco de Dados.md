# ADR-002 - Estratégia de Banco de Dados

**Substituído por [ADR-011](ADR-011%20-%20Estratégia%20de%20Persistência%20Poliglota%20por%20Microsserviço.md)**

---

## Observação

Esta ADR foi criada em um contexto anterior à adoção da arquitetura baseada em microsserviços.

Na arquitetura original, a estratégia de persistência considerava uma visão centralizada do banco de dados da aplicação, adequada ao modelo então adotado.

Com a evolução da solução para a Fase 4, tornou-se necessário redefinir a estratégia de persistência para atender aos requisitos de:

* bancos de dados independentes por microsserviço;
* propriedade exclusiva dos dados por domínio;
* proibição de acesso direto entre bancos de diferentes serviços;
* utilização de persistência poliglota;
* coexistência de bancos relacionais e não relacionais;
* consistência distribuída suportada por Saga Pattern.

Essas decisões foram consolidadas e detalhadas na [ADR-011 - Estratégia de Persistência Poliglota por Microsserviço](ADR-011%20-%20Estratégia%20de%20Persistência%20Poliglota%20por%20Microsserviço.md), que passa a substituir integralmente esta ADR.

## Contexto

A aplicação atualmente utiliza PostgreSQL executando dentro do cluster Kubernetes. Essa abordagem atendeu bem no início do projeto, porém traz aumento de complexidade operacional à medida que o sistema evolui.

A diretoria definiu diretrizes para adoção de serviços gerenciados em componentes críticos, com foco em:

- aumento de confiabilidade e disponibilidade
- redução de esforço operacional
- melhoria de segurança e governança
- padronização da infraestrutura em nuvem

Além disso, a aplicação já está consolidada sobre PostgreSQL, com modelagem, queries e comportamento transacional definidos.

---

## Decisão

Será adotado **PostgreSQL gerenciado utilizando o Amazon RDS**, substituindo o banco atualmente executado no Kubernetes.

A configuração inicial será enxuta, priorizando baixo custo e simplicidade operacional:

- engine: PostgreSQL
- instância: `db.t4g.micro` ou `db.t4g.small`
- storage: 20 GB
- tipo de storage: gp3
- alta disponibilidade: Single-AZ
- backup automático: retenção de 7 dias
- autenticação: usuário e senha (sem IAM DB Auth)
- monitoramento: métricas padrão do RDS disponíveis na AWS e painéis operacionais dos microsserviços no New Relic, conforme o [Padrão de Observabilidade Distribuída](../docs/observability.md)

Não será utilizado autoscaling de storage neste momento, mantendo controle explícito sobre crescimento de custos.

---

## Consequências

### Positivas

- redução significativa da complexidade operacional
- eliminação da necessidade de gerenciar backup, failover e manutenção manual
- melhoria na disponibilidade e confiabilidade do banco
- melhor integração com segurança e rede da nuvem
- manutenção de compatibilidade total com a aplicação existente
- alinhamento com as diretrizes da diretoria

---

### Negativas

- aumento de custo direto em relação ao banco self-hosted
- dependência do provedor de nuvem
- menor controle sobre configurações de baixo nível

---

### Mitigações

- iniciar com instâncias pequenas para controle de custo
- utilizar storage gp3, que apresenta melhor custo-benefício
- monitorar continuamente uso de CPU, conexões e I/O para ajuste fino
- evitar uso de funcionalidades específicas do provedor que aumentem lock-in
- manter uso de PostgreSQL padrão para facilitar portabilidade futura
- avaliar uso de reserved instances apenas após estabilização do ambiente
