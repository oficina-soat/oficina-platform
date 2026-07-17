# Plano de Decomposição do oficina-app

## Objetivo

Definir como o código existente do `oficina-app` deve ser decomposto nos microsserviços da arquitetura distribuída:

- `oficina-os-service`;
- `oficina-billing-service`;
- `oficina-execution-service`.

Este plano deve orientar agentes e desenvolvedores durante a criação dos novos repositórios, preservando o máximo possível da estrutura original em Clean Architecture e evitando acoplamento runtime entre microsserviços.

## Premissas

- Os novos repositórios dos microsserviços existem apenas com `README.md` placeholder.
- O `oficina-app` será usado como origem de migração de código e referência funcional, mas não será mantido como backend monolítico.
- Não há consumidores externos ou front-end que precisem ser migrados durante esta decomposição.
- Não há necessidade de preservar histórico ou dados existentes de ambiente.
- A massa inicial deve reaproveitar os dados do seed atual do `oficina-app`, pois eles já são conhecidos e funcionais.
- `Pessoa` e `Usuario` pertencem ao `oficina-os-service`.
- Não deve ser criada biblioteca `common` compartilhada entre microsserviços.
- Compartilhamento entre serviços deve ocorrer por contratos, não por código Java comum.

## Estratégia Geral

Cada microsserviço deve manter uma estrutura inspirada na Clean Architecture já existente no `oficina-app`:

```text
src/main/java/br/com/oficina/<dominio>/
  core/
    entities/
    exceptions/
    interfaces/
    usecases/
  interfaces/
    controllers/
    presenters/
  framework/
    db/
    messaging/
    web/
```

A nomenclatura interna pode ser ajustada por serviço, mas as responsabilidades, rotas, eventos e bancos devem seguir os contratos deste repositório.

## Decisão Sobre common

Não criar módulo, pacote ou biblioteca compartilhada `common` entre os microsserviços.

Motivos:

- evita acoplamento entre repositórios independentes;
- evita versionamento cruzado de bibliotecas internas;
- impede vazamento de regras de domínio entre serviços;
- mantém cada serviço autônomo para build, deploy, testes e evolução.

O compartilhamento permitido deve ficar neste repositório, por meio de:

- contratos OpenAPI;
- schemas JSON de eventos;
- contrato de erros REST;
- contrato de idempotência;
- padrões de observabilidade;
- templates futuros de microsserviço.

Código pequeno e estável, como paginação, filtros de `correlationId`, mappers de erro e configurações de observabilidade, pode ser copiado seletivamente para cada microsserviço. Caso a repetição se torne relevante, ela deve virar template em [templates/quarkus-service/](../../templates/quarkus-service/), não dependência runtime compartilhada.

## Mapeamento por Módulo do oficina-app

| Origem no `oficina-app` | Destino | Ação |
|---|---|---|
| `br.com.oficina.atendimento.core.entities.cliente` | `oficina-os-service` | Migrar como domínio de cliente, ajustando IDs para UUID quando necessário. |
| `br.com.oficina.atendimento.core.entities.veiculo` | `oficina-os-service` | Migrar como domínio de veículo. |
| `br.com.oficina.atendimento.core.entities.ordem_de_servico` | `oficina-os-service` | Migrar como agregado central da OS, mantendo estados e histórico coerentes com [Contrato de Estados da Ordem de Serviço](../../contracts/Contrato%20de%20Estados%20da%20Ordem%20de%20Serviço.md). |
| `br.com.oficina.atendimento.core.usecases.cliente` | `oficina-os-service` | Migrar e alinhar com rotas `/api/v1/clientes`. |
| `br.com.oficina.atendimento.core.usecases.veiculo` | `oficina-os-service` | Migrar e alinhar com rotas `/api/v1/clientes/{clienteId}/veiculos` e `/api/v1/veiculos/{veiculoId}`. |
| `br.com.oficina.atendimento.core.usecases.ordem_de_servico` | `oficina-os-service` | Migrar apenas regras de OS, estado global, histórico e orquestração. Separar a execução técnica e o financeiro para os serviços participantes. |
| `br.com.oficina.atendimento.framework.db` | `oficina-os-service` | Migrar entidades/adapters relacionais para PostgreSQL database `oficina_os`. |
| `br.com.oficina.atendimento.framework.web` | `oficina-os-service` | Migrar recursos REST compatíveis com [OpenAPI do oficina-os-service](../../contracts/openapi/oficina-os-service.yaml). |
| `br.com.oficina.atendimento.interfaces` | `oficina-os-service` | Migrar controllers e presenters necessários para OS, cliente e veículo. |
| `br.com.oficina.common.core.entities.Pessoa` e relacionados | `oficina-os-service` | Migrar para o domínio de OS/atendimento. |
| `br.com.oficina.common.core.entities.Usuario` e relacionados | `oficina-os-service` | Migrar para o domínio de OS/atendimento, preservando papéis operacionais do seed. |
| `br.com.oficina.common.framework.db.pessoa` | `oficina-os-service` | Migrar para persistência relacional em `oficina_os`. |
| `br.com.oficina.common.framework.db.usuario` | `oficina-os-service` | Migrar para persistência relacional em `oficina_os`. |
| `br.com.oficina.common.framework.web.pessoa` | `oficina-os-service` | Migrar se as APIs forem mantidas internamente no OS Service; caso contrário, manter apenas como referência para dados operacionais. |
| `br.com.oficina.common.framework.web.usuario` | `oficina-os-service` | CRUD REST agregado materializado em `/api/v1/usuarios`, com UUID, autorização administrativa, status e papéis canônicos, sem as rotas redundantes `/usuarios/completos` do legado. A integração com o `oficina-auth-lambda` ocorre por eventos e pelo consumidor serverless `oficina-auth-sync-lambda`. |
| `br.com.oficina.common.framework.observability` | Todos os serviços | Copiar seletivamente para cada serviço ou reaproveitar no template futuro. Não criar dependência compartilhada. |
| `br.com.oficina.common.web` | Todos os serviços, se necessário | Copiar apenas constantes ou helpers realmente usados. Evitar pacote comum entre repositórios. |
| `br.com.oficina.gestao_de_pecas.core.entities.catalogo` | `oficina-execution-service` | Migrar como catálogo técnico de peças e serviços. |
| `br.com.oficina.gestao_de_pecas.core.entities.estoque` | `oficina-execution-service` | Migrar como domínio de estoque e movimentos. |
| `br.com.oficina.gestao_de_pecas.core.usecases` | `oficina-execution-service` | Migrar e expandir para diagnóstico, execução e reparo conforme contratos. |
| `br.com.oficina.gestao_de_pecas.framework.db` | `oficina-execution-service` | Reimplementar para Amazon DynamoDB. Não migrar Panache/PostgreSQL diretamente. |
| `br.com.oficina.gestao_de_pecas.framework.web` | `oficina-execution-service` | Migrar recursos REST e alinhar com [OpenAPI do oficina-execution-service](../../contracts/openapi/oficina-execution-service.yaml). |
| `br.com.oficina.gestao_de_pecas.interfaces` | `oficina-execution-service` | Migrar controllers e presenters de catálogo e estoque. |
| Módulo financeiro inexistente no `oficina-app` | `oficina-billing-service` | Criar implementação nova orientada por contratos de orçamento, aprovação, recusa e pagamento. |

## Mapeamento por Microsserviço

### oficina-os-service

Responsabilidades migradas ou criadas:

- Pessoa;
- Usuário;
- papéis operacionais;
- Cliente;
- Veículo;
- Ordem de Serviço;
- item de peça da OS como snapshot;
- item de serviço da OS como snapshot;
- histórico de estados;
- estado global da OS;
- orquestração da Saga.

Banco:

```text
Amazon RDS for PostgreSQL
database: oficina_os
usuario: oficina_os_user
```

Eventos produzidos:

- `ordemDeServicoCriada`;
- `pecaIncluidaNaOrdemDeServico`;
- `servicoIncluidoNaOrdemDeServico`;
- `ordemDeServicoFinalizada`;
- `ordemDeServicoEntregue`;
- `sagaCompensada`;
- `sagaFinalizadaComSucesso`.

Eventos consumidos:

- `diagnosticoIniciado`;
- `diagnosticoFinalizado`;
- `orcamentoGerado`;
- `orcamentoAprovado`;
- `orcamentoRecusado`;
- `execucaoIniciada`;
- `execucaoFinalizada`;
- `pagamentoSolicitado`;
- `pagamentoConfirmado`;
- `pagamentoRecusado`.

### oficina-execution-service

Responsabilidades migradas ou criadas:

- catálogo técnico de peças;
- catálogo técnico de serviços;
- saldo de estoque;
- movimentos de estoque;
- diagnóstico;
- execução;
- reparo;
- histórico operacional.

Banco:

```text
Amazon DynamoDB
tabelas próprias do oficina-execution-service
```

Observação: os adapters PostgreSQL/Panache atuais do módulo `gestao_de_pecas` devem ser tratados como referência de comportamento, não como código a mover diretamente. A persistência deve ser reimplementada para DynamoDB.

Eventos produzidos:

- `diagnosticoIniciado`;
- `diagnosticoFinalizado`;
- `execucaoIniciada`;
- `execucaoFinalizada`;
- `estoqueAcrescentado`;
- `estoqueBaixado`.

Eventos consumidos:

- `ordemDeServicoCriada`;
- `pecaIncluidaNaOrdemDeServico`;
- `servicoIncluidoNaOrdemDeServico`;
- `orcamentoAprovado`;
- `ordemDeServicoFinalizada`;
- `sagaCompensada`;
- `sagaFinalizadaComSucesso`.

### oficina-billing-service

Responsabilidades criadas:

- orçamento;
- itens financeiros do orçamento;
- aprovação de orçamento;
- recusa de orçamento;
- pagamento;
- confirmação, recusa e cancelamento de pagamento;
- integração com provedor financeiro quando aplicável.

Banco:

```text
Amazon RDS for PostgreSQL
database: oficina_billing
usuario: oficina_billing_user
```

Origem de código:

- não há módulo financeiro equivalente no `oficina-app`;
- criar implementação nova a partir do [Contrato de APIs REST](../../contracts/Contrato%20de%20APIs%20REST.md), [OpenAPI do oficina-billing-service](../../contracts/openapi/oficina-billing-service.yaml), eventos e ownership.

Eventos produzidos:

- `orcamentoGerado`;
- `orcamentoAprovado`;
- `orcamentoRecusado`;
- `pagamentoSolicitado`;
- `pagamentoConfirmado`;
- `pagamentoRecusado`.

Eventos consumidos:

- `ordemDeServicoCriada`;
- `pecaIncluidaNaOrdemDeServico`;
- `servicoIncluidoNaOrdemDeServico`;
- `diagnosticoFinalizado`;
- `execucaoFinalizada`;
- `ordemDeServicoFinalizada`;
- `ordemDeServicoEntregue`;
- `estoqueAcrescentado`;
- `estoqueBaixado`;
- `sagaCompensada`;
- `sagaFinalizadaComSucesso`.

## Estratégia de Dados

Não haverá migração histórica de dados.

A estratégia oficial é usar seed limpo por microsserviço, com o `import.sql` atual do `oficina-app` como referência funcional.

### Seed do oficina-os-service

Origem no seed atual:

- `pessoa`;
- `papel`;
- `usuario`;
- `usuario_papel`;
- `cliente`;
- `veiculo`;
- `ordem_de_servico`;
- `estado_ordem_servico`;
- `os_item_peca`;
- `os_item_servico`.

Regras:

- preservar os nomes de pessoas, papéis, usuários, clientes e emails do seed atual;
- preservar os UUIDs das ordens de serviço já existentes para facilitar testes e rastreabilidade;
- ajustar timestamps para ISO-8601 nos contratos e manter formato compatível com PostgreSQL nas migrations;
- manter `RECEBIDA`, `EM_DIAGNOSTICO`, `AGUARDANDO_APROVACAO`, `EM_EXECUCAO` e `FINALIZADA` como massa inicial, pois cobrem diferentes pontos do fluxo;
- armazenar itens da OS como snapshots, incluindo identificador de catálogo, nome, quantidade, valor unitário e valor total quando esses campos estiverem disponíveis.

O `oficina-auth-lambda` mantém um store PostgreSQL próprio para autenticação. O `oficina-auth-sync-lambda` projeta nesse store os snapshots sem credenciais publicados pelo `oficina-os-service`; senha, token de ativação e JWT permanecem exclusivos da autenticação serverless. O caminho de login não consulta o serviço nem o database `oficina_os`. Os contratos estão no [OpenAPI do oficina-auth-lambda](../../contracts/openapi/oficina-auth-lambda.yaml), nos eventos [usuarioAdicionado](../../contracts/events/usuarioAdicionado.md), [usuarioAtualizado](../../contracts/events/usuarioAtualizado.md) e [usuarioExcluido](../../contracts/events/usuarioExcluido.md), e na [ADR-003 - Serverless para Autenticação e Notificações](../../adr/ADR-003%20-%20Serverless%20para%20Autenticação%20e%20Notificações.md).

### Seed do oficina-execution-service

Origem no seed atual:

- `peca`;
- `servico`;
- `estoque_saldo`;
- movimentos de estoque quando forem criados.

Regras:

- reaproveitar as peças `Volante`, `Pneu` e `Tapete`;
- reaproveitar o serviço `Troca de óleo`;
- reaproveitar o saldo de estoque da peça `Volante` com quantidade `50.000`;
- criar registros DynamoDB equivalentes ao domínio do serviço, sem depender das tabelas relacionais antigas;
- quando necessário, criar movimentos iniciais de estoque para explicar o saldo inicial.

### Seed do oficina-billing-service

Origem no seed atual:

- não há tabelas financeiras equivalentes.

Regras:

- iniciar sem dados financeiros históricos;
- opcionalmente criar dados demonstrativos de orçamento e pagamento apenas quando os contratos do `oficina-billing-service` estiverem implementados;
- qualquer dado demonstrativo deve referenciar ordens de serviço do seed do `oficina-os-service` por UUID.

## Estratégia de Descarte do oficina-app

Durante a decomposição:

- usar `oficina-app` como fonte de código, testes e seed;
- não adicionar novas responsabilidades ao `oficina-app`;
- não adaptar o `oficina-app` para coexistência com os microsserviços;
- não implementar dupla escrita;
- não criar rotas de compatibilidade.

Após a migração dos componentes relevantes:

- manter `oficina-app` apenas como referência histórica;
- considerar removidos do caminho de evolução os pacotes já migrados;
- evoluir apenas os repositórios dos microsserviços e este repositório de governança.

## Ordem Recomendada de Execução

1. Criar a estrutura base Quarkus de cada microsserviço preservando Clean Architecture.
2. Migrar `oficina-os-service` com Pessoa, Usuário, Cliente, Veículo, OS, estados e histórico.
3. Criar seed PostgreSQL do `oficina-os-service` a partir do `import.sql` atual.
4. Migrar `oficina-execution-service` com catálogo de peças, catálogo de serviços e estoque.
5. Criar seed DynamoDB do `oficina-execution-service` a partir dos dados atuais de peças, serviços e estoque.
6. Criar `oficina-billing-service` orientado por contratos, sem dependência de código legado financeiro.
7. Implementar eventos e Outbox nos serviços produtores.
8. Implementar consumidores idempotentes conforme o [Contrato de Idempotência](../../contracts/idempotency.md).
9. Implementar observabilidade, logs estruturados e propagação de `correlationId` em cada serviço.
10. Remover dependência operacional do `oficina-app`.

## Critérios de Pronto

- Cada pacote relevante do `oficina-app` possui destino explícito neste plano.
- Os três microsserviços preservam independência de build, deploy e banco.
- Não existe biblioteca `common` compartilhada entre os microsserviços.
- Pessoa e Usuário estão sob ownership do `oficina-os-service`.
- O CRUD REST de usuários operacionais está materializado no `oficina-os-service`; a sincronização assíncrona e a ativação segura de credenciais estão materializadas no `oficina-auth-lambda`.
- O seed dos microsserviços usa os dados funcionais do `import.sql` atual como referência.
- `oficina-billing-service` nasce de contratos, não de código legado inexistente.
- Rotas, eventos, tópicos e bancos permanecem coerentes com [Matriz de Ownership por Microsserviço](service-ownership.md), [Contrato de APIs REST](../../contracts/Contrato%20de%20APIs%20REST.md), [Contrato de Eventos de Domínio](../../contracts/Contrato%20de%20Eventos%20de%20Domínio.md) e [Contrato de Tópicos de Mensageria](../../contracts/Contrato%20de%20Tópicos%20de%20Mensageria.md).
- O `oficina-app` fica apenas como referência após a decomposição.

## Referências

- [ROADMAP.md](../../ROADMAP.md)
- [Matriz de Ownership por Microsserviço](service-ownership.md)
- [Contrato de APIs REST](../../contracts/Contrato%20de%20APIs%20REST.md)
- [Contrato de Estados da Ordem de Serviço](../../contracts/Contrato%20de%20Estados%20da%20Ordem%20de%20Serviço.md)
- [Contrato de Eventos de Domínio](../../contracts/Contrato%20de%20Eventos%20de%20Domínio.md)
- [Contrato de Tópicos de Mensageria](../../contracts/Contrato%20de%20Tópicos%20de%20Mensageria.md)
- [OpenAPI do oficina-os-service](../../contracts/openapi/oficina-os-service.yaml)
- [OpenAPI do oficina-billing-service](../../contracts/openapi/oficina-billing-service.yaml)
- [OpenAPI do oficina-execution-service](../../contracts/openapi/oficina-execution-service.yaml)
- [OpenAPI do oficina-auth-lambda](../../contracts/openapi/oficina-auth-lambda.yaml)
- `../oficina-app/src/main/resources/import.sql`
