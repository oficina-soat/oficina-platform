# Aprovação do orçamento pelo cliente

## Status

Ownership e contrato alvo definidos. Implementação pendente conforme o [roadmap](../../ROADMAP.md#restauração-da-autorização-do-orçamento-pelo-cliente).

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

## Ownership definido

| Responsável | Atribuições |
|---|---|
| `oficina-billing-service` | Gerar os tokens de capacidade; persistir somente seus hashes; validar expiração, ação, OS e uso único; apresentar as páginas públicas; registrar aprovação ou recusa; publicar o evento financeiro pela Outbox. |
| `oficina-notificacao-lambda` | Entregar o e-mail já composto ao endereço informado, sem persistir token, consultar orçamento ou decidir transições. |
| `oficina-os-service` | Manter o cliente e seu contato canônico, fornecer os dados necessários por contrato e atualizar o estado global somente pelos eventos financeiros. |
| `oficina-ui` | Exibir o estado financeiro e as ações administrativas autenticadas retornadas pelas APIs, sem substituir os links públicos nem inferir transições. |
| `oficina-infra` | Expor as rotas públicas do Billing sem authorizer e configurar a integração privada e os parâmetros de runtime necessários. |

O token é uma credencial de capacidade restrita a uma ação e não uma credencial de sessão. Auth Lambda e Notification Lambda não se tornam autoridades do orçamento.

## Compatibilidade com a Fase 3

O contrato preserva:

- três links independentes para acompanhar, aprovar e recusar;
- token aleatório de 32 bytes gerado com CSPRNG e codificado em Base64 URL-safe sem padding;
- persistência exclusiva do hash SHA-256;
- vínculo com ação, Ordem de Serviço, orçamento e e-mail destinatário;
- expiração padrão de 24 horas;
- consumo único e serializado para aprovação e recusa;
- página de confirmação carregada por `GET` e decisão efetivada somente por `POST`;
- resposta HTML segura para acompanhamento, confirmação, sucesso e erro.

As rotas públicas ficam sob `/api/v1/ordens-servico/{ordemServicoId}` e mantêm os sufixos históricos `acompanhar-link`, `aprovar-link` e `recusar-link`. Elas não exigem JWT. O token nunca é aceito em header de autenticação, cookie ou log; é recebido como `actionToken` e deve ser mascarado antes da telemetria.

O uso único é a proteção idempotente da decisão pública: o lock da linha e a Outbox garantem no máximo um evento financeiro. Uma repetição não executa novamente a ação e recebe a mesma página genérica de link inválido, expirado ou já utilizado, sem revelar qual condição ocorreu. As APIs administrativas autenticadas continuam usando `X-Idempotency-Key` normalmente.

## Escopo de entrega

A implementação deve materializar os contratos definidos, remover o bypass atual e homologar os caminhos aprovado, recusado, expirado, reutilizado e indisponível no `lab`.
