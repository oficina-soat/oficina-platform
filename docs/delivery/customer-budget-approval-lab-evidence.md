# Evidência de aprovação do orçamento no lab

## Resultado

Homologação concluída em 2026-07-17 com a correlação `approval-lab-20260717T164726Z`, usando Billing `1.5.2`, Execution `1.3.2` e OS Service `1.9.1`.

| Cenário | Resultado observado |
|---|---|
| Entrega da autorização | Mensagem recebida no MailHog interno, sem registrar o token na evidência. |
| Atalho operacional | Transição direta de `AGUARDANDO_APROVACAO` para `EM_EXECUCAO` rejeitada com HTTP `409`. |
| Aprovação pública | Decisão aceita com HTTP `200`; OS convergiu de `AGUARDANDO_APROVACAO` para `EM_EXECUCAO`. |
| Reuso após aprovação | Segunda decisão com o mesmo token rejeitada com HTTP `409`. |
| Recusa pública | Decisão aceita com HTTP `200`; OS convergiu de `AGUARDANDO_APROVACAO` para `EM_DIAGNOSTICO`. |
| Reuso após recusa | Segunda decisão com o mesmo token rejeitada com HTTP `409`. |

O fluxo aprovado publicou `orcamentoAprovado` correlacionado pela Ordem de Serviço, foi consumido pelo OS Service e pelo Execution Service e resultou em `execucaoIniciada`. O fluxo recusado preservou a Saga ativa para revisão do diagnóstico.

## Cobertura complementar

Tokens inválidos, expirados ou vinculados a outra ação, concorrência, indisponibilidade da notificação e idempotência permanecem cobertos pelos testes automatizados dos serviços. A homologação não alterou relógio, banco ou configuração do ambiente para fabricar expiração ou indisponibilidade; o teste no `lab` concentrou-se nas duas jornadas ponta a ponta e no consumo único real.

Nenhum token, JWT, e-mail, CPF ou outro dado pessoal foi persistido nesta evidência.

## Retomada do link único e reenvio

Em 2026-07-19, a jornada `payment-orders-v1105-20260719T220931Z`, já com Billing `1.10.5`, criou a OS `ad626917-8b44-4702-818e-8f5db883d473` e o orçamento `9e4d8509-113a-3631-9c51-ff00d4f5b8fd`. O comando autenticado de reenvio retornou HTTP `204` e o MailHog recebeu duas mensagens da mesma OS, sem recriar o orçamento.

A mensagem mais recente continha exatamente um link público para `/orcamento-link`. A página aberta sem sessão apresentou os dados do orçamento e os botões **Aprovar** e **Recusar** no mesmo documento; a decisão por `POST` retornou **Decisão registrada**, o orçamento convergiu para `APROVADO` e a execução avançou para `EM_REPARO`.

A verificação de infraestrutura confirmou que a opção **E-mails do lab** da UI, o port-forward e a Lambda de notificação referenciam o mesmo MailHog e o mesmo endpoint SMTP. Tokens, links, JWT, e-mail e conteúdo da mensagem não foram persistidos na evidência.

Esta retomada comprova emissão com link único, apresentação completa, aprovação, reenvio e convergência do MailHog. A tarefa coordenada permanece aberta somente para repetir no formato unificado a recusa, o consumo único e a invalidação efetiva do link anterior após o reenvio.
