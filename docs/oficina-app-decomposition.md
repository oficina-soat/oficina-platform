# Plano de Decomposicao do oficina-app

## Objetivo

Definir como o codigo existente do `oficina-app` deve ser decomposto nos microsservicos da Fase 4:

- `oficina-os-service`;
- `oficina-billing-service`;
- `oficina-execution-service`.

Este plano deve orientar agentes e desenvolvedores durante a criacao dos novos repositorios, preservando o maximo possivel da estrutura original em Clean Architecture e evitando acoplamento runtime entre microsservicos.

## Premissas

- Os novos repositorios dos microsservicos existem apenas com `README.md` placeholder.
- O `oficina-app` sera usado como origem de migracao de codigo e referencia funcional, mas nao sera mantido como backend monolitico da Fase 4.
- Nao ha consumidores externos ou front-end que precisem ser migrados durante esta decomposicao.
- Nao ha necessidade de preservar historico ou dados existentes de ambiente.
- A massa inicial deve reaproveitar os dados do seed atual do `oficina-app`, pois eles ja sao conhecidos e funcionais.
- `Pessoa` e `Usuario` pertencem ao `oficina-os-service`.
- Nao deve ser criada biblioteca `common` compartilhada entre microsservicos.
- Compartilhamento entre servicos deve ocorrer por contratos, nao por codigo Java comum.

## Estrategia Geral

Cada microsservico deve manter uma estrutura inspirada na Clean Architecture ja existente no `oficina-app`:

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

A nomenclatura interna pode ser ajustada por servico, mas as responsabilidades, rotas, eventos e bancos devem seguir os contratos deste repositorio.

## Decisao Sobre common

Nao criar modulo, pacote ou biblioteca compartilhada `common` entre os microsservicos.

Motivos:

- evita acoplamento entre repositorios independentes;
- evita versionamento cruzado de bibliotecas internas;
- impede vazamento de regras de dominio entre servicos;
- mantem cada servico autonomo para build, deploy, testes e evolucao.

O compartilhamento permitido deve ficar neste repositorio, por meio de:

- contratos OpenAPI;
- schemas JSON de eventos;
- contrato de erros REST;
- contrato de idempotencia;
- padroes de observabilidade;
- templates futuros de microsservico.

Codigo pequeno e estavel, como paginacao, filtros de `correlationId`, mappers de erro e configuracoes de observabilidade, pode ser copiado seletivamente para cada microsservico. Caso a repeticao se torne relevante, ela deve virar template em `templates/quarkus-service/`, nao dependencia runtime compartilhada.

## Mapeamento por Modulo do oficina-app

| Origem no `oficina-app` | Destino | Acao |
|---|---|---|
| `br.com.oficina.atendimento.core.entities.cliente` | `oficina-os-service` | Migrar como dominio de cliente, ajustando IDs para UUID quando necessario. |
| `br.com.oficina.atendimento.core.entities.veiculo` | `oficina-os-service` | Migrar como dominio de veiculo. |
| `br.com.oficina.atendimento.core.entities.ordem_de_servico` | `oficina-os-service` | Migrar como agregado central da OS, mantendo estados e historico coerentes com `contracts/Contrato de Estados da Ordem de Serviço.md`. |
| `br.com.oficina.atendimento.core.usecases.cliente` | `oficina-os-service` | Migrar e alinhar com rotas `/api/v1/clientes`. |
| `br.com.oficina.atendimento.core.usecases.veiculo` | `oficina-os-service` | Migrar e alinhar com rotas `/api/v1/clientes/{clienteId}/veiculos` e `/api/v1/veiculos/{veiculoId}`. |
| `br.com.oficina.atendimento.core.usecases.ordem_de_servico` | `oficina-os-service` | Migrar apenas regras de OS, estado global, historico e orquestracao. Separar a execucao tecnica e o financeiro para os servicos participantes. |
| `br.com.oficina.atendimento.framework.db` | `oficina-os-service` | Migrar entidades/adapters relacionais para PostgreSQL database `oficina_os`. |
| `br.com.oficina.atendimento.framework.web` | `oficina-os-service` | Migrar recursos REST compativeis com `contracts/openapi/oficina-os-service.yaml`. |
| `br.com.oficina.atendimento.interfaces` | `oficina-os-service` | Migrar controllers e presenters necessarios para OS, cliente e veiculo. |
| `br.com.oficina.common.core.entities.Pessoa` e relacionados | `oficina-os-service` | Migrar para o dominio de OS/atendimento. |
| `br.com.oficina.common.core.entities.Usuario` e relacionados | `oficina-os-service` | Migrar para o dominio de OS/atendimento, preservando papeis operacionais do seed. |
| `br.com.oficina.common.framework.db.pessoa` | `oficina-os-service` | Migrar para persistencia relacional em `oficina_os`. |
| `br.com.oficina.common.framework.db.usuario` | `oficina-os-service` | Migrar para persistencia relacional em `oficina_os`. |
| `br.com.oficina.common.framework.web.pessoa` | `oficina-os-service` | Migrar se as APIs forem mantidas internamente no OS Service; caso contrario, manter apenas como referencia para dados operacionais. |
| `br.com.oficina.common.framework.web.usuario` | `oficina-os-service` | Migrar se as APIs forem mantidas internamente no OS Service; caso contrario, manter apenas como referencia para autenticacao/autorizacao local. |
| `br.com.oficina.common.framework.observability` | Todos os servicos | Copiar seletivamente para cada servico ou reaproveitar no template futuro. Nao criar dependencia compartilhada. |
| `br.com.oficina.common.web` | Todos os servicos, se necessario | Copiar apenas constantes ou helpers realmente usados. Evitar pacote comum entre repositorios. |
| `br.com.oficina.gestao_de_pecas.core.entities.catalogo` | `oficina-execution-service` | Migrar como catalogo tecnico de pecas e servicos. |
| `br.com.oficina.gestao_de_pecas.core.entities.estoque` | `oficina-execution-service` | Migrar como dominio de estoque e movimentos. |
| `br.com.oficina.gestao_de_pecas.core.usecases` | `oficina-execution-service` | Migrar e expandir para diagnostico, execucao e reparo conforme contratos. |
| `br.com.oficina.gestao_de_pecas.framework.db` | `oficina-execution-service` | Reimplementar para Amazon DynamoDB. Nao migrar Panache/PostgreSQL diretamente. |
| `br.com.oficina.gestao_de_pecas.framework.web` | `oficina-execution-service` | Migrar recursos REST e alinhar com `contracts/openapi/oficina-execution-service.yaml`. |
| `br.com.oficina.gestao_de_pecas.interfaces` | `oficina-execution-service` | Migrar controllers e presenters de catalogo e estoque. |
| Modulo financeiro inexistente no `oficina-app` | `oficina-billing-service` | Criar implementacao nova orientada por contratos de orcamento, aprovacao, recusa e pagamento. |

## Mapeamento por Microsservico

### oficina-os-service

Responsabilidades migradas ou criadas:

- Pessoa;
- Usuario;
- papeis operacionais;
- Cliente;
- Veiculo;
- Ordem de Servico;
- item de peca da OS como snapshot;
- item de servico da OS como snapshot;
- historico de estados;
- estado global da OS;
- orquestracao da Saga.

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

- catalogo tecnico de pecas;
- catalogo tecnico de servicos;
- saldo de estoque;
- movimentos de estoque;
- diagnostico;
- execucao;
- reparo;
- historico operacional.

Banco:

```text
Amazon DynamoDB
tabelas proprias do oficina-execution-service
```

Observacao: os adapters PostgreSQL/Panache atuais do modulo `gestao_de_pecas` devem ser tratados como referencia de comportamento, nao como codigo a mover diretamente. A persistencia deve ser reimplementada para DynamoDB.

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

- orcamento;
- itens financeiros do orcamento;
- aprovacao de orcamento;
- recusa de orcamento;
- pagamento;
- confirmacao, recusa e cancelamento de pagamento;
- integracao com provedor financeiro quando aplicavel.

Banco:

```text
Amazon RDS for PostgreSQL
database: oficina_billing
usuario: oficina_billing_user
```

Origem de codigo:

- nao ha modulo financeiro equivalente no `oficina-app`;
- criar implementacao nova a partir de `contracts/Contrato de APIs REST.md`, `contracts/openapi/oficina-billing-service.yaml`, eventos e ownership.

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

## Estrategia de Dados

Nao havera migracao historica de dados.

A estrategia oficial para a Fase 4 e seed limpo por microsservico, usando o `import.sql` atual do `oficina-app` como referencia funcional.

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

- preservar os nomes de pessoas, papeis, usuarios, clientes e emails do seed atual;
- preservar os UUIDs das ordens de servico ja existentes para facilitar testes e rastreabilidade;
- ajustar timestamps para ISO-8601 nos contratos e manter formato compativel com PostgreSQL nas migrations;
- manter `RECEBIDA`, `EM_DIAGNOSTICO`, `AGUARDANDO_APROVACAO`, `EM_EXECUCAO` e `FINALIZADA` como massa inicial, pois cobrem diferentes pontos do fluxo;
- armazenar itens da OS como snapshots, incluindo identificador de catalogo, nome, quantidade, valor unitario e valor total quando esses campos estiverem disponiveis.

### Seed do oficina-execution-service

Origem no seed atual:

- `peca`;
- `servico`;
- `estoque_saldo`;
- movimentos de estoque quando forem criados.

Regras:

- reaproveitar as pecas `Volante`, `Pneu` e `Tapete`;
- reaproveitar o servico `Troca de oleo`;
- reaproveitar o saldo de estoque da peca `Volante` com quantidade `50.000`;
- criar registros DynamoDB equivalentes ao dominio do servico, sem depender das tabelas relacionais antigas;
- quando necessario, criar movimentos iniciais de estoque para explicar o saldo inicial.

### Seed do oficina-billing-service

Origem no seed atual:

- nao ha tabelas financeiras equivalentes.

Regras:

- iniciar sem dados financeiros historicos;
- opcionalmente criar dados demonstrativos de orcamento e pagamento apenas quando os contratos do `oficina-billing-service` estiverem implementados;
- qualquer dado demonstrativo deve referenciar ordens de servico do seed do `oficina-os-service` por UUID.

## Estrategia de Descarte do oficina-app

Durante a decomposicao:

- usar `oficina-app` como fonte de codigo, testes e seed;
- nao adicionar novas responsabilidades ao `oficina-app`;
- nao adaptar o `oficina-app` para coexistencia com os microsservicos;
- nao implementar dupla escrita;
- nao criar rotas de compatibilidade.

Apos a migracao dos componentes relevantes:

- manter `oficina-app` apenas como referencia historica;
- considerar removidos do caminho de evolucao os pacotes ja migrados;
- evoluir apenas os repositorios dos microsservicos e este repositorio de governanca.

## Ordem Recomendada de Execucao

1. Criar a estrutura base Quarkus de cada microsservico preservando Clean Architecture.
2. Migrar `oficina-os-service` com Pessoa, Usuario, Cliente, Veiculo, OS, estados e historico.
3. Criar seed PostgreSQL do `oficina-os-service` a partir do `import.sql` atual.
4. Migrar `oficina-execution-service` com catalogo de pecas, catalogo de servicos e estoque.
5. Criar seed DynamoDB do `oficina-execution-service` a partir dos dados atuais de pecas, servicos e estoque.
6. Criar `oficina-billing-service` orientado por contratos, sem dependencia de codigo legado financeiro.
7. Implementar eventos e Outbox nos servicos produtores.
8. Implementar consumidores idempotentes conforme `contracts/idempotency.md`.
9. Implementar observabilidade, logs estruturados e propagacao de `correlationId` em cada servico.
10. Remover dependencia operacional do `oficina-app`.

## Criterios de Pronto

- Cada pacote relevante do `oficina-app` possui destino explicito neste plano.
- Os tres microsservicos preservam independencia de build, deploy e banco.
- Nao existe biblioteca `common` compartilhada entre os microsservicos.
- Pessoa e Usuario estao sob ownership do `oficina-os-service`.
- O seed da Fase 4 usa os dados funcionais do `import.sql` atual como referencia.
- `oficina-billing-service` nasce de contratos, nao de codigo legado inexistente.
- Rotas, eventos, topicos e bancos permanecem coerentes com `docs/service-ownership.md`, `contracts/Contrato de APIs REST.md`, `contracts/Contrato de Eventos de Domínio.md` e `contracts/Contrato de Tópicos de Mensageria.md`.
- O `oficina-app` fica apenas como referencia apos a decomposicao.

## Referencias

- `ROADMAP.md`
- `docs/service-ownership.md`
- `contracts/Contrato de APIs REST.md`
- `contracts/Contrato de Estados da Ordem de Serviço.md`
- `contracts/Contrato de Eventos de Domínio.md`
- `contracts/Contrato de Tópicos de Mensageria.md`
- `contracts/openapi/oficina-os-service.yaml`
- `contracts/openapi/oficina-billing-service.yaml`
- `contracts/openapi/oficina-execution-service.yaml`
- `../oficina-app/src/main/resources/import.sql`
