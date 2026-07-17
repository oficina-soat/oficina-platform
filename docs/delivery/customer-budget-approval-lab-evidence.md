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
