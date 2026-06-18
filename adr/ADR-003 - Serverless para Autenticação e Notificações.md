### Status

Aprovado

---

### Contexto

A aplicação backend em Quarkus já está consolidada na Amazon Web Services, utilizando Amazon RDS PostgreSQL como banco de dados principal.

A diretoria definiu como diretriz a adoção de componentes serverless para fluxos específicos, com foco em:

- redução de custo para cargas intermitentes
- melhoria de escalabilidade
- isolamento de responsabilidades
- aumento de segurança em pontos de entrada do sistema

Essa diretriz se aplica explicitamente aos fluxos de:

- autenticação de clientes
- envio de notificações

Esses fluxos apresentam características de execução sob demanda, com variação de carga e baixo acoplamento com o domínio principal, o que os torna candidatos naturais para externalização.

Atualmente, essas responsabilidades estariam acopladas ao backend principal, aumentando a superfície de exposição e a necessidade de escalabilidade global da aplicação.

---

### Decisão

Será adotado AWS Lambda integrado ao Amazon API Gateway para implementação dos fluxos serverless de autenticação e notificações.

A configuração inicial será enxuta, priorizando baixo custo e simplicidade operacional:

- gateway: Amazon API Gateway (HTTP API)
- funções: AWS Lambda separadas por responsabilidade (autenticação e notificações)
- runtime: Quarkus em modo nativo (GraalVM), visando baixo cold start
- integração com banco: acesso ao PostgreSQL no RDS (quando necessário)
- autenticação: geração de JWT própria
- timeout das funções: curto, focado em execução rápida
- memória das funções: configuração mínima inicial com ajuste baseado em métricas
- deploy: pipelines independentes da aplicação principal

**Lambda de autenticação será responsável por:**

- validar o CPF
- consultar existência e status do cliente
- gerar e retornar token JWT

**Lambda de notificações será responsável por:**

- processar eventos de negócio
- disparar notificações (ex: integração futura com e-mail, SMS ou outros canais)
- operar de forma assíncrona sempre que possível

**O API Gateway será responsável por:**

- expor endpoint público de autenticação
- centralizar entrada de requisições externas
- proteger rotas da aplicação principal via validação de token

---

### Consequências

#### Positivas

- aderência direta à diretriz de uso de serverless
- custo proporcional ao uso, adequado para cargas intermitentes
- isolamento de autenticação e notificações do backend principal
- escalabilidade independente por tipo de fluxo
- redução do impacto de cold start com uso de Quarkus nativo
- melhoria na segurança ao separar o ponto de entrada

#### Negativas

- maior dependência de serviços específicos da AWS
- aumento da complexidade de deploy e versionamento (múltiplas funções)
- necessidade de padronizar observabilidade entre componentes distintos
- necessidade de definir estratégia de comunicação para notificações (eventos, filas, etc.)

---

### Mitigações

- utilizar Quarkus nativo para reduzir impacto de cold start
- iniciar com configuração mínima de memória e ajustar com base em métricas
- padronizar logs, métricas e tracing desde o início
- definir padrão de eventos para desacoplar notificações do domínio
- evitar uso excessivo de integrações proprietárias além do necessário
- monitorar continuamente latência e custo das funções
- manter lógica de negócio desacoplada para facilitar evolução futura