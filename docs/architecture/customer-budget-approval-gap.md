# Lacuna de aprovação do orçamento pelo cliente

## Objetivo

Registrar a diferença entre o fluxo de aprovação da Fase 3 e a implementação distribuída atual, preservando os requisitos de segurança e de negócio antes da correção.

## Comportamento existente na Fase 3

O `oficina-app` enviava ao e-mail do cliente três links vinculados à Ordem de Serviço:

- acompanhamento;
- aprovação do orçamento;
- recusa do orçamento.

O fluxo usava tokens de ação aleatórios de 256 bits. Somente o hash SHA-256 era persistido, com vínculo à ação, à Ordem de Serviço e ao e-mail, validade de 24 horas e registro de consumo. Aprovação e recusa exigiam confirmação por `POST`, bloqueavam reutilização e validavam simultaneamente token, ação e Ordem de Serviço.

As referências preservadas no repositório legado são:

- `MagicLinkService` e `ActionTokenService`, responsáveis pela geração e pela segurança dos tokens;
- `OrdemDeServicoMagicLinkResource`, responsável pelas páginas públicas de acompanhamento, confirmação e resultado;
- `OrcamentoSenderNotificacaoAdapter`, responsável por incluir os links na notificação do orçamento;
- `OrdemDeServicoMagicLinkResourceIT` e `MagicLinkServiceIT`, responsáveis pela cobertura integrada.

## Divergência na Fase 4

A decomposição preservou o `oficina-notificacao-lambda`, o e-mail do cliente no OS Service, o orçamento no Billing Service e os eventos `orcamentoGerado`, `orcamentoAprovado` e `orcamentoRecusado`. Entretanto, não foram migrados:

- a emissão dos tokens de acompanhamento, aprovação e recusa;
- a persistência segura, a expiração e o consumo único;
- as páginas e rotas públicas associadas aos links;
- a composição e o envio automático da notificação do orçamento ao cliente.

Além disso, o OS Service atualmente oferece `INICIAR_EXECUCAO` diretamente em `AGUARDANDO_APROVACAO`. Isso permite contornar a decisão do cliente e contradiz a [Saga da Ordem de Serviço](../../contracts/saga/oficina-os-saga-v1.md), que libera a execução somente após `orcamentoAprovado`.

## Invariantes da correção

- Finalizar o diagnóstico solicita a geração do orçamento; não inicia a execução.
- Gerar o orçamento emite a solicitação de autorização ao contato canônico do cliente.
- Aprovação e recusa públicas usam tokens opacos, vinculados à ação e à OS, armazenados somente como hash, com expiração e consumo único.
- O token nunca aparece em logs, eventos, telemetria ou respostas administrativas.
- A decisão revalida o estado canônico do orçamento no Billing Service e publica o evento correspondente de forma idempotente.
- Somente `orcamentoAprovado` pode liberar o início da execução; o OS Service e a UI não oferecem um atalho manual enquanto aguardam aprovação.
- A recusa retorna a OS ao diagnóstico pelo fluxo canônico já definido.
- A Lambda de notificações permanece responsável pelo envio, sem absorver regras de orçamento ou transição de estado.

## Escopo de entrega

A correção exige definir formalmente o ownership do token e das rotas públicas, evoluir contratos e infraestrutura, implementar o envio e as decisões, remover o bypass atual e homologar o caminho aprovado, recusado, expirado, reutilizado e indisponível no `lab`.
