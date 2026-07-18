# Roadmap da Oficina SOAT

## Objetivo

Este arquivo é a fila operacional da plataforma. Ele contém somente trabalho ainda aberto, na ordem em que deve ser executado. Decisões arquiteturais, especificações, critérios permanentes e evidências de tarefas concluídas pertencem às ADRs, aos contratos e à documentação temática.

O histórico consolidado das entregas removidas deste backlog está no [Histórico do roadmap](docs/delivery/roadmap-history.md).

## Como interpretar

| Elemento | Significado |
|---|---|
| Ordem das seções e dos itens | Prioridade de execução |
| `[ ]` | Tarefa aberta |
| `[x]` | Tarefa concluída; deve ser transferida para o histórico na sanitização seguinte |
| `IMPL` | Implementação ou validação local |
| `REM` | Homologação ou validação remota |
| `EVID` | Registro de evidência externa ou material final |
| `FUT` | Candidata fora da sequência ativa; exige promoção explícita |

Quando o usuário solicitar a “próxima tarefa”, deve ser executado o primeiro item aberto da [Sequência ativa](#sequência-ativa). Itens futuros e de encerramento não antecipam essa ordem sem solicitação explícita.

## Referências canônicas

| Assunto | Fonte |
|---|---|
| Decisões arquiteturais | [ADRs](adr/) |
| Arquitetura e ownership | [Documentação de arquitetura](docs/architecture/) |
| APIs, eventos, tópicos, erros, idempotência e Saga | [Contratos](contracts/) |
| Infraestrutura, ambientes e nomes de runtime | [Documentação de infraestrutura](docs/infrastructure/) |
| Observabilidade e runbooks | [Documentação de observabilidade](docs/observability/) |
| Qualidade, deploy e entrega | [Documentação de entrega](docs/delivery/) |

## Sequência ativa

### Correção das fronteiras operacionais da OS

- [x] `[D-MECHANIC-WORKSPACE-REM-001]` Implantar e homologar no `lab` o atendimento mecânico unificado, comprovando inclusão de itens e comandos de diagnóstico/reparo na mesma tela, sempre conforme as capabilities de OS e Execution. Concluído com a [homologação do atendimento mecânico unificado](docs/delivery/mechanic-workspace-lab-evidence.md), incluindo uma peça, um serviço, diagnóstico e reparo pela UI real.
- [ ] `[D-MECHANIC-WORKSPACE-RECON-001]` Detectar e reconciliar no `lab` OS operacionais sem execução associada, preservando criação idempotente e registrando evidência sem alterar estados de negócio; manter monitoramento para novas divergências. A detecção e o monitor seguro estão concluídos; quatro OS históricas em estados avançados aguardam definição explícita da política de reconciliação, conforme a [evidência do lab](docs/delivery/mechanic-workspace-lab-evidence.md#auditoria-de-associações).
- [x] `[D-MECHANIC-WORKSPACE-IMPL-001]` Unificar no detalhe acessado pela fila do mecânico a composição técnica da OS e os comandos de diagnóstico/reparo, sem transferir regras entre serviços nem inferir ações no Angular. Concluído localmente no `oficina-ui`: o atendimento reúne composição e execução, mantendo as capabilities de cada backend como única autoridade.
- [x] `[D-FLOW-AUTHORITY-IMPL-004]` Manter na fila do mecânico todas as execuções com ação operacional disponível (`CRIADA`, `EM_DIAGNOSTICO` e `EM_REPARO`) e retirar estados sem ação manual. Concluído localmente no contrato, Execution Service e UI, com regressão automatizada das transições.
- [x] `[D-FLOW-AUTHORITY-IMPL-001]` Remover da UI e do OS Service as transições diretas de diagnóstico e finalização que contornavam Execution, Billing e a Saga; liberar entrega somente após pagamento confirmado. Concluído localmente com ações derivadas também pelo estado da Saga e rejeição dos atalhos no backend.
- [x] `[D-FLOW-AUTHORITY-IMPL-002]` Fazer o Execution retomar o diagnóstico após `orcamentoRecusado`, iniciar reparo apenas pelo evento `orcamentoAprovado` e cancelar somente por compensação da Saga. Concluído localmente nos contratos, consumidor, rotas públicas e UI.
- [x] `[D-FLOW-AUTHORITY-IMPL-003]` Corrigir o consumo dos eventos aninhados de peças e serviços e preservar mensagens falhas como retentáveis. Concluído localmente conforme os JSON Schemas canônicos e com teste de regressão da idempotência.
- [ ] `[D-APPROVAL-RETRY-IMPL-001]` Impedir que retentativas de `diagnosticoFinalizado` após falha de notificação recriem o orçamento; preservar a retentativa de entrega, garantir um único efeito financeiro por evento e cobrir a regressão observada na [homologação do atendimento mecânico](docs/delivery/mechanic-workspace-lab-evidence.md#anomalia-encontrada).
- [ ] `[D-FLOW-AUTHORITY-REM-001]` Implantar OS, Execution, infraestrutura e UI e homologar no `lab` a jornada diagnóstico → orçamento → e-mail → aprovação/recusa → reparo → pagamento → entrega, incluindo rejeição dos atalhos removidos.

### Restauração da autorização do orçamento pelo cliente

Contexto e invariantes estão consolidados na [Lacuna de aprovação do orçamento pelo cliente](docs/architecture/customer-budget-approval-gap.md).

- [x] `[D-APPROVAL-IMPL-001]` Definir e contratar o ownership distribuído dos tokens e das rotas públicas de acompanhamento, aprovação e recusa, preservando hash SHA-256, expiração, consumo único, vínculo entre ação e OS, idempotência, erros canônicos e ausência de tokens em logs, eventos e telemetria. Concluído com ownership no Billing, Notification restrita à entrega e compatibilidade explícita com as capabilities do sistema de referência.
- [x] `[D-APPROVAL-IMPL-002]` Implementar a emissão dos links após `orcamentoGerado`, a persistência segura dos tokens e o envio da solicitação ao e-mail canônico do cliente por meio do `oficina-notificacao-lambda`, sem transferir regras de orçamento para a Lambda. Concluído com projeção aditiva do contato canônico no Billing, tokens CSPRNG de 256 bits, persistência exclusiva do hash SHA-256, validade de 24 horas, invalidação de emissões anteriores e composição da mensagem mantida fora da Lambda.
- [x] `[D-APPROVAL-IMPL-003]` Implementar as páginas e decisões públicas de acompanhar, aprovar e recusar; revalidar o orçamento no Billing Service e publicar `orcamentoAprovado` ou `orcamentoRecusado` de forma idempotente. Concluído no Billing com páginas HTML públicas independentes de sessão, validação do hash do token, vínculo com OS e ação, expiração, consumo atômico de uso único e decisão pelos casos de uso canônicos com Outbox.
- [x] `[D-APPROVAL-IMPL-004]` Remover `INICIAR_EXECUCAO` das ações da OS em `AGUARDANDO_APROVACAO` e impedir a transição direta no backend, na OpenAPI e na UI; liberar a execução exclusivamente pelo evento `orcamentoAprovado`. Concluído com rejeição da transição operacional direta, remoção da capability nos contratos e na UI e preservação do avanço orientado por `orcamentoAprovado` seguido de `execucaoIniciada`.
- [x] `[D-APPROVAL-TEST-001]` Cobrir contratos, autorização, expiração, reutilização, concorrência, idempotência, indisponibilidade de notificação e fluxos E2E aprovado e recusado; homologar no `lab` sem expor tokens ou dados pessoais nas evidências. Concluído com cobertura automatizada dos cenários de segurança e falha e [homologação no lab](docs/delivery/customer-budget-approval-lab-evidence.md) das jornadas aprovada e recusada, bloqueio do atalho operacional e consumo único real.

## Candidatas futuras

Estes itens não pertencem à sequência ativa. A promoção deve mover o item para a posição desejada na seção anterior e substituir o prefixo `FUT` por um identificador do épico correspondente.

### Diagramas dos fluxos operacionais

Os diagramas devem ser escritos em Mermaid e publicados nos READMEs canônicos dos repositórios que possuem cada responsabilidade. Visões ponta a ponta pertencem ao `oficina-platform`; cada serviço deve manter somente seu recorte, com links para a visão canônica, evitando duplicação de regras e divergência entre estados, APIs e eventos.

- [ ] `[FUT-DIAG-FLOW-001]` Documentar no README do `oficina-platform`, com `stateDiagram-v2`, a visão resumida do ciclo de vida da OS, incluindo estados principais, transições válidas, retomada do diagnóstico, recusa e cancelamento; manter coerência com os contratos de estados, APIs, eventos e Saga.
- [ ] `[FUT-DIAG-FLOW-002]` Documentar no README do `oficina-os-service` o fluxo de recepção e diagnóstico, cobrindo criação da OS, cliente e veículo, início do diagnóstico, inclusão de peças e serviços e conclusão do diagnóstico; usar `flowchart` para decisões e `sequenceDiagram` quando houver colaboração com outros serviços.
- [ ] `[FUT-DIAG-FLOW-003]` Documentar a geração do orçamento e a aprovação pelo cliente: manter a sequência ponta a ponta no README do `oficina-platform`, o ownership financeiro e o consumo único dos links no `oficina-billing-service` e somente o recorte de entrega da notificação no `oficina-auth-lambda`; incluir aprovação, recusa, expiração, reutilização inválida e retomada do diagnóstico.
- [ ] `[FUT-DIAG-FLOW-004]` Documentar o fluxo da aprovação até a execução e conclusão do reparo, com visão ponta a ponta no README do `oficina-platform` e recortes de orquestração e execução nos READMEs de `oficina-os-service` e `oficina-execution-service`.
- [ ] `[FUT-DIAG-FLOW-005]` Documentar o fluxo de pagamento e entrega, incluindo solicitação, integração com Mercado Pago, webhook, confirmação, falha, indisponibilidade, retentativa, finalização da OS e entrega do veículo; manter a visão ponta a ponta no `oficina-platform` e o recorte financeiro no `oficina-billing-service`.
- [ ] `[FUT-DIAG-FLOW-006]` Documentar a Saga assíncrona da OS com `sequenceDiagram`, identificando orquestrador, produtores, consumidores, tópicos, correlação, Outbox, retentativas e compensações; manter a visão canônica no `oficina-platform` e, nos três serviços, apenas os eventos produzidos e consumidos por cada um.
- [ ] `[FUT-DIAG-FLOW-007]` Documentar autenticação e autorização, da credencial até a emissão e validação do JWT, grupos, audiences e restauração da sessão operacional; manter a sequência ponta a ponta no README do `oficina-platform` e os recortes técnicos nos READMEs de `oficina-auth-lambda` e `oficina-ui`, sem introduzir regra de negócio no frontend.
- [ ] `[FUT-DIAG-FLOW-008]` Documentar a ativação de usuário, incluindo emissão, entrega, validação, expiração e uso único do token; manter a visão ponta a ponta no `oficina-platform` e os recortes de implementação em `oficina-auth-lambda` e `oficina-ui`.
- [ ] `[FUT-DIAG-FLOW-009]` Documentar no README do `oficina-infra` o fluxo operacional de build e deploy do `lab`, cobrindo GitHub Actions, publicação de artefatos e imagens, ECR, EKS, Lambdas, API Gateway, retomada e suspensão do ambiente, sem misturar a hospedagem opcional da UI aos requisitos de infraestrutura principal.
- [ ] `[FUT-DIAG-FLOW-010]` Executar revisão anti-divergência de todos os diagramas, validar a renderização Mermaid, links entre as visões canônicas e os recortes por repositório e correspondência com estados, APIs, eventos, tópicos, ownership e recursos de infraestrutura vigentes.

## Extensões opcionais

Extensões não integram os requisitos obrigatórios nem a sequência ativa. A hospedagem AWS do frontend operacional é acompanhada no [roadmap do frontend](docs/frontend/roadmap.md#trilha-extra--hospedagem-opcional-na-aws) e, conforme a [ADR-013](adr/ADR-013%20-%20Frontend%20Operacional%20Angular.md#isolamento-da-infraestrutura-opcional), deve possuir composição, state e pipeline isolados da infraestrutura principal.

## Encerramento final

Estes itens permanecem deliberadamente no fim e só devem ser executados quando os materiais finais estiverem disponíveis.

- [ ] `[D-DELIVERY-EVID-001]` Registrar data da entrega, participantes, links dos repositórios e link do vídeo no [Checklist final de entrega](docs/delivery/phase-4-delivery-checklist.md) ou no documento de entrega.
- [ ] `[D-VIDEO-EVID-001]` Registrar as evidências finais do vídeo de demonstração após a gravação e a homologação do ambiente.
