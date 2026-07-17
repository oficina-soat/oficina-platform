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

### Restauração da autorização do orçamento pelo cliente

Contexto e invariantes estão consolidados na [Lacuna de aprovação do orçamento pelo cliente](docs/architecture/customer-budget-approval-gap.md).

- [x] `[D-APPROVAL-IMPL-001]` Definir e contratar o ownership distribuído dos tokens e das rotas públicas de acompanhamento, aprovação e recusa, preservando hash SHA-256, expiração, consumo único, vínculo entre ação e OS, idempotência, erros canônicos e ausência de tokens em logs, eventos e telemetria. Concluído com ownership no Billing, Notification restrita à entrega e compatibilidade explícita com as capabilities da Fase 3.
- [x] `[D-APPROVAL-IMPL-002]` Implementar a emissão dos links após `orcamentoGerado`, a persistência segura dos tokens e o envio da solicitação ao e-mail canônico do cliente por meio do `oficina-notificacao-lambda`, sem transferir regras de orçamento para a Lambda. Concluído com projeção aditiva do contato canônico no Billing, tokens CSPRNG de 256 bits, persistência exclusiva do hash SHA-256, validade de 24 horas, invalidação de emissões anteriores e composição da mensagem mantida fora da Lambda.
- [x] `[D-APPROVAL-IMPL-003]` Implementar as páginas e decisões públicas de acompanhar, aprovar e recusar; revalidar o orçamento no Billing Service e publicar `orcamentoAprovado` ou `orcamentoRecusado` de forma idempotente. Concluído no Billing com páginas HTML públicas independentes de sessão, validação do hash do token, vínculo com OS e ação, expiração, consumo atômico de uso único e decisão pelos casos de uso canônicos com Outbox.
- [ ] `[D-APPROVAL-IMPL-004]` Remover `INICIAR_EXECUCAO` das ações da OS em `AGUARDANDO_APROVACAO` e impedir a transição direta no backend, na OpenAPI e na UI; liberar a execução exclusivamente pelo evento `orcamentoAprovado`.
- [ ] `[D-APPROVAL-TEST-001]` Cobrir contratos, autorização, expiração, reutilização, concorrência, idempotência, indisponibilidade de notificação e fluxos E2E aprovado e recusado; homologar no `lab` sem expor tokens ou dados pessoais nas evidências.

## Candidatas futuras

Estes itens não pertencem à sequência ativa. A promoção deve mover o item para a posição desejada na seção anterior e substituir o prefixo `FUT` por um identificador do épico correspondente.

Não há candidatas futuras no momento.

## Extensões opcionais

Extensões não integram os requisitos obrigatórios nem a sequência ativa. A hospedagem AWS do frontend operacional é acompanhada no [roadmap do frontend](docs/frontend/roadmap.md#trilha-extra--hospedagem-opcional-na-aws) e, conforme a [ADR-013](adr/ADR-013%20-%20Frontend%20Operacional%20Angular.md#isolamento-da-infraestrutura-opcional), deve possuir composição, state e pipeline isolados da infraestrutura principal.

## Encerramento final

Estes itens permanecem deliberadamente no fim e só devem ser executados quando os materiais finais estiverem disponíveis.

- [ ] `[D-DELIVERY-EVID-001]` Registrar data da entrega, participantes, links dos repositórios e link do vídeo no [Checklist final de entrega](docs/delivery/phase-4-delivery-checklist.md) ou no documento de entrega.
- [ ] `[D-VIDEO-EVID-001]` Registrar as evidências finais do vídeo de demonstração após a gravação e a homologação do ambiente.
