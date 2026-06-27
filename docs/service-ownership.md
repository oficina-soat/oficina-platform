# Matriz de Ownership por Microsserviço

## Objetivo

Consolidar, em um único artefato operacional, a responsabilidade de cada microsserviço da plataforma.

Esta matriz deve ser usada por agentes e desenvolvedores para decidir onde implementar regras, APIs, eventos, persistência, jobs, integrações e validações sem reinterpretar todas as ADRs e contratos.

---

## Regras Gerais

- Cada microsserviço é dono exclusivo dos seus dados.
- Nenhum microsserviço pode acessar diretamente o banco de outro microsserviço.
- Integrações entre microsserviços devem ocorrer apenas por APIs REST ou eventos de domínio.
- Eventos devem ser publicados após persistência local bem-sucedida, usando Outbox.
- Chamadas com efeito colateral devem seguir `contracts/idempotency.md`.
- Respostas de erro REST devem seguir `contracts/error-model.md`.
- O `oficina-os-service` é a autoridade sobre o estado global da Ordem de Serviço e a orquestração da Saga.
- O `oficina-execution-service` é a autoridade sobre catálogo técnico de peças e serviços, estoque e execução operacional.
- O `oficina-billing-service` é a autoridade sobre orçamento, aprovação, recusa, pagamento e integrações financeiras.

---

## Resumo Executivo

| Serviço | Dono de | Banco | Papel na Saga |
|---|---|---|---|
| `oficina-os-service` | Clientes, veículos, Ordem de Serviço, itens da OS, histórico de estados e estado da Saga | PostgreSQL database `oficina_os` | Orquestrador |
| `oficina-billing-service` | Orçamentos, aprovações, recusas, pagamentos e integração financeira | PostgreSQL database `oficina_billing` | Participante financeiro |
| `oficina-execution-service` | Catálogo técnico de peças e serviços, estoque, diagnóstico, execução e reparo | Amazon DynamoDB | Participante operacional |

---

## oficina-os-service

### Ownership

| Dimensão | Responsabilidade |
|---|---|
| Entidades próprias | Cliente, Veículo, Ordem de Serviço, item de peça da OS, item de serviço da OS, histórico de estados, estado da Saga. |
| Banco de dados | Amazon RDS for PostgreSQL, database `oficina_os`, usuário `oficina_os_user`. |
| APIs REST | `/api/v1/clientes`, `/api/v1/clientes/{clienteId}`, `/api/v1/clientes/{clienteId}/veiculos`, `/api/v1/veiculos/{veiculoId}`, `/api/v1/ordens-servico`, `/api/v1/ordens-servico/{ordemServicoId}`, `/api/v1/ordens-servico/{ordemServicoId}/historico`, `/api/v1/ordens-servico/{ordemServicoId}/estado`, `/api/v1/ordens-servico/{ordemServicoId}/cancelamento`. |
| Eventos produzidos | `ordemDeServicoCriada`, `pecaIncluidaNaOrdemDeServico`, `servicoIncluidoNaOrdemDeServico`, `ordemDeServicoFinalizada`, `ordemDeServicoEntregue`, `sagaCompensada`, `sagaFinalizadaComSucesso`. |
| Eventos consumidos | `diagnosticoIniciado`, `diagnosticoFinalizado`, `orcamentoGerado`, `orcamentoAprovado`, `orcamentoRecusado`, `execucaoIniciada`, `execucaoFinalizada`, `pagamentoSolicitado`, `pagamentoConfirmado`, `pagamentoRecusado`. |
| Outbox/jobs | Outbox dos eventos de OS e Saga; jobs de publicação de eventos; controle de timeout, retentativas e compensações da Saga quando detalhados nos fluxos de Saga. |
| Integrações síncronas | Pode consultar `oficina-billing-service` e `oficina-execution-service` quando houver necessidade imediata de validação ou composição de resposta, respeitando os contratos REST. |
| Regras principais | Abrir OS, controlar estado global da OS, registrar histórico, incluir itens na OS, manter snapshots dos itens escolhidos, orquestrar a Saga e decidir transições globais. |

### Limites

O `oficina-os-service` não deve:

- ser dono do catálogo técnico de peças ou serviços;
- controlar saldo, reserva, consumo ou estorno de estoque;
- calcular ou confirmar pagamentos;
- acessar `oficina_billing` ou tabelas/tópicos internos do `oficina-billing-service`;
- acessar tabelas DynamoDB do `oficina-execution-service`;
- alterar diretamente o estado financeiro ou operacional dos serviços participantes.

### Observação Sobre Itens da OS

O catálogo técnico pertence ao `oficina-execution-service`.

Quando uma peça ou serviço é incluído em uma Ordem de Serviço, o `oficina-os-service` deve persistir o item da OS com os identificadores e snapshots necessários para auditoria, como nome, quantidade, valor usado no momento e demais campos estabilizados nos contratos.

---

## oficina-billing-service

### Ownership

| Dimensão | Responsabilidade |
|---|---|
| Entidades próprias | Orçamento, item financeiro do orçamento, aprovação de orçamento, recusa de orçamento, pagamento, status financeiro, histórico financeiro da OS, dados de integração financeira. |
| Banco de dados | Amazon RDS for PostgreSQL, database `oficina_billing`, usuário `oficina_billing_user`. |
| APIs REST | `/api/v1/orcamentos`, `/api/v1/orcamentos/{orcamentoId}`, `/api/v1/ordens-servico/{ordemServicoId}/orcamentos`, `/api/v1/orcamentos/{orcamentoId}/aprovacao`, `/api/v1/orcamentos/{orcamentoId}/recusa`, `/api/v1/pagamentos`, `/api/v1/pagamentos/{pagamentoId}`, `/api/v1/ordens-servico/{ordemServicoId}/pagamentos`, `/api/v1/pagamentos/{pagamentoId}/confirmacao`, `/api/v1/pagamentos/{pagamentoId}/recusa`, `/api/v1/pagamentos/{pagamentoId}/cancelamento`. |
| Eventos produzidos | `orcamentoGerado`, `orcamentoAprovado`, `orcamentoRecusado`, `pagamentoSolicitado`, `pagamentoConfirmado`, `pagamentoRecusado`. |
| Eventos consumidos | `ordemDeServicoCriada`, `pecaIncluidaNaOrdemDeServico`, `servicoIncluidoNaOrdemDeServico`, `diagnosticoFinalizado`, `execucaoFinalizada`, `ordemDeServicoFinalizada`, `ordemDeServicoEntregue`, `estoqueAcrescentado`, `estoqueBaixado`, `sagaCompensada`, `sagaFinalizadaComSucesso`. |
| Outbox/jobs | Outbox dos eventos financeiros; jobs de publicação de eventos; jobs de consulta ou conciliação com provedor financeiro quando aplicável. |
| Integrações externas | Mercado Pago ou provedor financeiro equivalente definido para pagamentos. |
| Integrações síncronas | Pode consultar `oficina-os-service` para obter dados necessários da OS e seus itens quando não houver projeção local suficiente. |
| Regras principais | Gerar orçamento, registrar aprovação/recusa, registrar pagamento, confirmar/recusar/cancelar pagamento, manter consistência financeira e publicar eventos financeiros. |

### Limites

O `oficina-billing-service` não deve:

- ser dono de cliente, veículo ou Ordem de Serviço;
- alterar diretamente o estado global da OS;
- ser dono do catálogo técnico de peças e serviços;
- reservar, consumir ou estornar estoque;
- executar diagnóstico ou reparo;
- acessar `oficina_os` ou tabelas DynamoDB do `oficina-execution-service`;
- recalcular itens técnicos fora dos dados da OS, projeções ou contratos de integração.

---

## oficina-execution-service

### Ownership

| Dimensão | Responsabilidade |
|---|---|
| Entidades próprias | Serviço técnico, peça, saldo de estoque, movimento de estoque, execução, diagnóstico, reparo, histórico operacional. |
| Banco de dados | Amazon DynamoDB, com tabelas de catálogo técnico, estoque, execução e histórico operacional a serem detalhadas no padrão DynamoDB. |
| APIs REST | `/api/v1/servicos`, `/api/v1/servicos/{servicoId}`, `/api/v1/pecas`, `/api/v1/pecas/{pecaId}`, `/api/v1/estoques/pecas/{pecaId}/saldo`, `/api/v1/estoques/movimentos`, `/api/v1/estoques/movimentos/entrada`, `/api/v1/estoques/movimentos/reserva`, `/api/v1/estoques/movimentos/consumo`, `/api/v1/estoques/movimentos/estorno`, `/api/v1/execucoes`, `/api/v1/execucoes/{execucaoId}`, `/api/v1/ordens-servico/{ordemServicoId}/execucao`, `/api/v1/execucoes/{execucaoId}/diagnostico/inicio`, `/api/v1/execucoes/{execucaoId}/diagnostico/conclusao`, `/api/v1/execucoes/{execucaoId}/reparo/inicio`, `/api/v1/execucoes/{execucaoId}/reparo/conclusao`, `/api/v1/execucoes/{execucaoId}/cancelamento`. |
| Eventos produzidos | `diagnosticoIniciado`, `diagnosticoFinalizado`, `execucaoIniciada`, `execucaoFinalizada`, `estoqueAcrescentado`, `estoqueBaixado`. |
| Eventos consumidos | `ordemDeServicoCriada`, `pecaIncluidaNaOrdemDeServico`, `servicoIncluidoNaOrdemDeServico`, `orcamentoAprovado`, `ordemDeServicoFinalizada`, `sagaCompensada`, `sagaFinalizadaComSucesso`. |
| Outbox/jobs | Outbox dos eventos operacionais e de estoque; jobs de publicação de eventos; jobs de processamento operacional quando necessários para filas de execução ou retentativas. |
| Integrações síncronas | Pode consultar `oficina-os-service` quando precisar validar ou obter contexto da OS não presente em evento/projeção local. |
| Regras principais | Manter catálogo técnico, validar peças e serviços ativos, controlar disponibilidade de estoque, registrar diagnóstico, iniciar/finalizar execução, iniciar/finalizar reparo, cancelar execução e publicar eventos operacionais. |

### Limites

O `oficina-execution-service` não deve:

- ser dono de cliente, veículo ou estado global da OS;
- aprovar ou recusar orçamento;
- registrar ou confirmar pagamentos;
- alterar diretamente o estado global da OS;
- acessar `oficina_os` ou `oficina_billing`;
- calcular o resultado financeiro final da OS.

---

## Ownership por Entidade

| Entidade ou conceito | Serviço dono | Observação |
|---|---|---|
| Cliente | `oficina-os-service` | Usado na abertura e consulta da OS. |
| Veículo | `oficina-os-service` | Associado ao cliente e à OS. |
| Ordem de Serviço | `oficina-os-service` | Agregado central do fluxo. |
| Estado da OS | `oficina-os-service` | Autoridade sobre o estado global. |
| Histórico da OS | `oficina-os-service` | Histórico de transições da OS. |
| Item de peça da OS | `oficina-os-service` | Snapshot do item selecionado para a OS; catálogo pertence ao Execution. |
| Item de serviço da OS | `oficina-os-service` | Snapshot do item selecionado para a OS; catálogo pertence ao Execution. |
| Serviço técnico | `oficina-execution-service` | Catálogo técnico usado em execução e composição da OS. |
| Peça | `oficina-execution-service` | Catálogo técnico e referência de estoque. |
| Estoque | `oficina-execution-service` | Saldo, reserva, consumo, entrada e estorno. |
| Diagnóstico | `oficina-execution-service` | Resultado técnico da avaliação. |
| Execução/Reparo | `oficina-execution-service` | Fluxo operacional da oficina. |
| Orçamento | `oficina-billing-service` | Documento financeiro da OS. |
| Aprovação/recusa de orçamento | `oficina-billing-service` | Decisão financeira do orçamento. |
| Pagamento | `oficina-billing-service` | Registro e status financeiro. |
| Integração Mercado Pago | `oficina-billing-service` | Integração externa financeira. |
| Saga | `oficina-os-service` | Orquestração e estado global do processo distribuído. |

---

## Ownership por Banco

| Serviço | Tecnologia | Unidade canônica | Restrições |
|---|---|---|---|
| `oficina-os-service` | Amazon RDS for PostgreSQL | `oficina_os` | Somente `oficina-os-service` pode acessar. |
| `oficina-billing-service` | Amazon RDS for PostgreSQL | `oficina_billing` | Somente `oficina-billing-service` pode acessar. |
| `oficina-execution-service` | Amazon DynamoDB | Tabelas próprias do serviço | Somente `oficina-execution-service` pode acessar. |

---

## Ownership por Evento

| Evento | Produtor dono | Consumidores |
|---|---|---|
| `ordemDeServicoCriada` | `oficina-os-service` | `oficina-billing-service`, `oficina-execution-service` |
| `diagnosticoIniciado` | `oficina-execution-service` | `oficina-os-service` |
| `pecaIncluidaNaOrdemDeServico` | `oficina-os-service` | `oficina-billing-service`, `oficina-execution-service` |
| `servicoIncluidoNaOrdemDeServico` | `oficina-os-service` | `oficina-billing-service`, `oficina-execution-service` |
| `diagnosticoFinalizado` | `oficina-execution-service` | `oficina-os-service`, `oficina-billing-service` |
| `orcamentoGerado` | `oficina-billing-service` | `oficina-os-service` |
| `orcamentoAprovado` | `oficina-billing-service` | `oficina-os-service`, `oficina-execution-service` |
| `orcamentoRecusado` | `oficina-billing-service` | `oficina-os-service` |
| `execucaoIniciada` | `oficina-execution-service` | `oficina-os-service` |
| `execucaoFinalizada` | `oficina-execution-service` | `oficina-os-service`, `oficina-billing-service` |
| `ordemDeServicoFinalizada` | `oficina-os-service` | `oficina-billing-service`, `oficina-execution-service` |
| `ordemDeServicoEntregue` | `oficina-os-service` | `oficina-billing-service` |
| `pagamentoSolicitado` | `oficina-billing-service` | `oficina-os-service` |
| `pagamentoConfirmado` | `oficina-billing-service` | `oficina-os-service` |
| `pagamentoRecusado` | `oficina-billing-service` | `oficina-os-service` |
| `estoqueAcrescentado` | `oficina-execution-service` | `oficina-billing-service` |
| `estoqueBaixado` | `oficina-execution-service` | `oficina-billing-service` |
| `sagaCompensada` | `oficina-os-service` | `oficina-billing-service`, `oficina-execution-service` |
| `sagaFinalizadaComSucesso` | `oficina-os-service` | `oficina-billing-service`, `oficina-execution-service` |

---

## Decisão Sobre Catálogo de Peças e Serviços

O catálogo técnico de peças e serviços pertence ao `oficina-execution-service`.

Critérios usados:

- peças têm relação direta com estoque, disponibilidade, reserva, consumo e estorno;
- serviços têm relação direta com diagnóstico, execução e reparo;
- o `oficina-os-service` já concentra estado global da OS e orquestração da Saga, portanto não deve acumular catálogo operacional;
- o `oficina-billing-service` deve orçar com base nos itens da OS, por consulta ou projeção, sem ser dono do catálogo;
- a OS deve manter snapshots dos itens incluídos para preservar histórico e auditoria.

---

## Referências

- `adr/ADR-010 - Estratégia de Divisão dos Microsserviços.md`
- `adr/ADR-011 - Estratégia de Persistência Poliglota por Microsserviço.md`
- `adr/ADR-009 - Estratégia de Saga Pattern.md`
- `contracts/Contrato de APIs REST.md`
- `contracts/Contrato de Eventos de Domínio.md`
- `contracts/Contrato de Tópicos de Mensageria.md`
- `contracts/openapi/`

