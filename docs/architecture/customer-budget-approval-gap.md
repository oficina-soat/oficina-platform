# Aprovação do orçamento pelo cliente

## Status

Implementado e homologado nos serviços, na UI e na infraestrutura. As jornadas e versões validadas estão registradas na [evidência de aprovação do orçamento no lab](../delivery/customer-budget-approval-lab-evidence.md).

## Objetivo

Registrar a restauração do fluxo de autorização do cliente na arquitetura distribuída e preservar seus requisitos de segurança e de negócio.

## Comportamento de referência

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

## Divergência identificada durante a decomposição

A decomposição preservou o `oficina-notificacao-lambda`, o e-mail do cliente no OS Service, o orçamento no Billing Service e os eventos `orcamentoGerado`, `orcamentoAprovado` e `orcamentoRecusado`. Na primeira versão distribuída, ainda não haviam sido migrados:

- a emissão dos tokens de acompanhamento, aprovação e recusa;
- a persistência segura, a expiração e o consumo único;
- as páginas e rotas públicas associadas aos links;
- a composição e o envio automático da notificação do orçamento ao cliente.

O OS Service também oferecia `INICIAR_EXECUCAO` diretamente em `AGUARDANDO_APROVACAO`, permitindo contornar a decisão do cliente. Esse bypass foi removido: a [Saga da Ordem de Serviço](../../contracts/saga/oficina-os-saga-v1.md) libera a execução somente após `orcamentoAprovado`.

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

## Compatibilidade preservada

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

## Estado implementado

A implementação materializa os contratos definidos e remove o bypass operacional. O Billing gera e persiste os tokens, compõe a solicitação de notificação e publica a decisão pela Outbox; a Lambda entrega a mensagem; OS Service e UI não expõem `INICIAR_EXECUCAO` enquanto aguardam o cliente. Os eventos financeiros usam a Ordem de Serviço como `aggregateId` e preservam `orcamentoId` no payload, permitindo a correlação correta da Saga.

A homologação no `lab` comprovou os caminhos aprovado e recusado, o bloqueio da transição direta e o consumo único real. Expiração, concorrência, ação incompatível e indisponibilidade permanecem cobertas por testes automatizados para evitar mutações artificiais de relógio, banco ou configuração durante a validação ponta a ponta. O registro está na [evidência de aprovação do orçamento no lab](../delivery/customer-budget-approval-lab-evidence.md).
