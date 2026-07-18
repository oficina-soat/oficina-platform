# Evidência do atendimento mecânico unificado no lab

## Resultado

O atendimento mecânico unificado foi implantado e homologado em 2026-07-18 no `lab`. A validação usou a UI real, sem mocks, e comprovou na rota de detalhe da execução a composição técnica da OS e os comandos autorizados pelos dois backends.

O endpoint implantado respondeu HTTP `200` em `/health`, publicou a revisão da UI na configuração de runtime e apontou as integrações para `/api/v1` do mesmo API Gateway.

| Componente | Revisão homologada | Evidência de deploy |
|---|---|---|
| UI | [`240cbf28621ba496436ab19272b90eeb3e76b32d`](https://github.com/oficina-soat/oficina-ui/commit/240cbf28621ba496436ab19272b90eeb3e76b32d) | [Run `29638182245`](https://github.com/oficina-soat/oficina-ui/actions/runs/29638182245), concluído com sucesso |
| OS Service `1.10.3` | [`76bd015bf701addc075c65228e405f2e551e271d`](https://github.com/oficina-soat/oficina-os-service/commit/76bd015bf701addc075c65228e405f2e551e271d) | [Run `29638179296`](https://github.com/oficina-soat/oficina-os-service/actions/runs/29638179296), concluído com sucesso |
| Execution Service `1.4.2` | [`5367c7aa2933e191fcc639354dedc16635dbc07c`](https://github.com/oficina-soat/oficina-execution-service/commit/5367c7aa2933e191fcc639354dedc16635dbc07c) | [Run `29619112305`](https://github.com/oficina-soat/oficina-execution-service/actions/runs/29619112305), concluído com sucesso |
| Infraestrutura | [`73373c6f0d12cb5abbdfbd5d0406b4b97279f187`](https://github.com/oficina-soat/oficina-infra/commit/73373c6f0d12cb5abbdfbd5d0406b4b97279f187) | [Retomada `29637437878`](https://github.com/oficina-soat/oficina-infra/actions/runs/29637437878), concluída com sucesso |

## Cenário homologado

A OS sintética `f0186c19-d912-4b16-8f8c-44543816e789` foi aberta duas vezes com a mesma chave de idempotência. As duas requisições retornaram HTTP `201` e o mesmo identificador; o consumo de `ordemDeServicoCriada` associou exatamente uma execução, `c53eab2d-7f7d-4bac-964b-5e051f2bf25f`.

| Etapa na mesma tela | Resultado observado |
|---|---|
| Entrada pela fila do mecânico | Navegação para `/execucoes/c53eab2d-7f7d-4bac-964b-5e051f2bf25f`, com a seção “Composição técnica da OS” e o comando `INICIAR_DIAGNOSTICO`. |
| Início do diagnóstico | Comando da Execution aceito; a OS convergiu para `EM_DIAGNOSTICO` e passou a autorizar a inclusão de itens. |
| Composição técnica | Um serviço e uma peça foram incluídos pela UI conforme as capabilities retornadas pelo OS Service. O orçamento resultante totalizou `180,00`. |
| Conclusão do diagnóstico | Comando da Execution aceito; a OS convergiu para `AGUARDANDO_APROVACAO` e a execução para `DIAGNOSTICO_CONCLUIDO`. |
| Liberação do reparo | A aprovação autenticada pelo endpoint canônico do Billing foi aceita; a OS convergiu para `EM_EXECUCAO` e a execução para `EM_REPARO`, expondo somente `CONCLUIR_REPARO`. |
| Conclusão do reparo | O comando foi executado na mesma rota de atendimento. A OS terminou em `FINALIZADA`, a execução em `REPARO_CONCLUIDO` e a composição preservou uma peça e um serviço. |

A aprovação autenticada foi usada apenas para liberar a etapa de reparo desta homologação. A jornada pública por e-mail continua pertencendo à homologação ponta a ponta prevista no [roadmap](../../ROADMAP.md#correção-das-fronteiras-operacionais-da-os).

## Auditoria de associações

O monitor operacional criado em `oficina-infra/scripts/manual/reconcile-os-executions.sh` comparou as OS não entregues com as execuções do ambiente. Permaneceram quatro registros históricos sem associação:

| OS | Estado observado |
|---|---|
| `2b2276e8-fa72-4f4c-a3b0-2c5b1bf427ef` | `EM_DIAGNOSTICO` |
| `f05dd17b-daae-4658-af7c-363dd6e6fdfb` | `AGUARDANDO_APROVACAO` |
| `6b2276e8-fa72-4f4c-a3b0-2c5b1bf427ef` | `EM_EXECUCAO` |
| `7b2276e8-fa72-4f4c-a3b0-2c5b1bf427ef` | `FINALIZADA` |

O modo de reconciliação foi executado e recusou corretamente a criação automática para os quatro estados avançados. Nenhum estado de negócio foi alterado. O script somente cria de forma idempotente uma execução em `CRIADA` quando a OS divergente ainda está em `RECEBIDA`; demais estados exigem uma política explícita de reconciliação.

### Reconciliação dos registros históricos

Em 18/07/2026, a política de backfill compatível foi aprovada e aplicada aos quatro registros. O estado atual de cada OS foi confirmado por consulta somente leitura no PostgreSQL antes da gravação. A tabela de execuções ainda não possuía associação para nenhum dos quatro identificadores.

| Estado da OS | Estado materializado na execução | Resultado |
|---|---|---|
| `EM_DIAGNOSTICO` | `EM_DIAGNOSTICO` | Snapshot e histórico criados |
| `AGUARDANDO_APROVACAO` | `DIAGNOSTICO_CONCLUIDO` | Snapshot e histórico criados |
| `EM_EXECUCAO` | `EM_REPARO` | Snapshot e histórico criados |
| `FINALIZADA` | `REPARO_CONCLUIDO` | Snapshot e histórico criados |

Cada reparação usou identificadores determinísticos e uma transação condicional no DynamoDB para criar o snapshot e um único histórico auditável. Nenhum comando de domínio foi executado, nenhuma Outbox foi criada e nenhum evento retroativo foi publicado. A correlação técnica `os-execution-reconciliation-backfill` identificou oito itens na tabela de execuções — snapshot e histórico de cada OS — e zero item na Outbox.

Após o backfill, o [monitor operacional](../../../oficina-infra/docs/os-execution-reconciliation.md) foi executado novamente pelas APIs públicas e retornou `Nenhuma OS operacional sem execucao associada.`. A execução usou um JWT de manutenção com validade de cinco minutos, mantido somente em memória e não registrado na evidência.

A recuperação point-in-time da tabela `oficina-execution-lab-execucoes` estava desabilitada na data da operação. Essa condição era preexistente; a segurança desta rodada dependeu das transações condicionais e da verificação prévia de ausência. A habilitação de PITR deve ser tratada separadamente na infraestrutura, sem invalidar o resultado funcional da reconciliação.

## Anomalia encontrada

Durante a indisponibilidade SMTP, a retentativa de `diagnosticoFinalizado` recriou o orçamento da OS sintética antes de concluir a notificação. Foram observados cinco orçamentos para a mesma OS: um `APROVADO` e quatro `GERADO`. A mensagem original de autorização não chegou ao MailHog.

O redeploy da Notification Lambda foi reaplicado pelo [run `29611520320`](https://github.com/oficina-soat/oficina-auth-lambda/actions/runs/29611520320). Depois disso, uma notificação sintética independente retornou HTTP `204` e foi recebida no MailHog, comprovando a restauração do transporte; ela não reprocessou com segurança o evento original. A correção da duplicação foi registrada como tarefa anterior à homologação ponta a ponta no [roadmap](../../ROADMAP.md#correção-das-fronteiras-operacionais-da-os).

A correção foi concluída localmente no Billing `1.6.1`. O `eventId` de `diagnosticoFinalizado` agora deriva identificadores determinísticos para o orçamento e para `orcamentoGerado`. Se a notificação falhar, a mensagem continua retentável, mas reutiliza o orçamento `GERADO` e a mesma Outbox; se o orçamento já tiver sido aprovado ou recusado, a retentativa não regride seu estado nem envia nova solicitação. A regressão automatizada cobre falha seguida de sucesso, orçamento decidido entre tentativas e persistência idempotente no PostgreSQL. A comprovação remota pertence à homologação ponta a ponta ainda aberta.

## Segurança da evidência

JWT, credenciais, links de aprovação, e-mail, CPF e demais dados pessoais não foram persistidos. A evidência registra somente identificadores técnicos sintéticos, estados, capabilities, revisões e resultados HTTP necessários à rastreabilidade.
