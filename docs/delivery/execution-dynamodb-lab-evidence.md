# Evidência DynamoDB do Serviço de Execução no Lab

## Escopo

Este documento registra a validação remota de `[B2-EXEC-DDB-REM-001]` no ambiente `lab`, conforme o [Padrão DynamoDB do oficina-execution-service](../infrastructure/dynamodb-execution-service.md) e o [Checklist final de entrega](phase-4-delivery-checklist.md).

As consultas e os fluxos de negócio foram executados por pods temporários dentro do cluster, usando o runtime AWS disponível no EKS. Nenhuma credencial AWS foi exibida ou registrada, e todos os pods auxiliares foram removidos ao final.

## Imagem e configuração do runtime

O Deployment estava saudável com uma réplica da imagem `oficina-execution-service:1.0.16` e apresentava:

- profile Quarkus `prod` e ambiente lógico `lab` ativos;
- SDK Amazon DynamoDB instalado no runtime;
- `OFICINA_DYNAMODB_TABLE_PREFIX=oficina-execution-lab`;
- as cinco variáveis com os nomes materializados das tabelas canônicas;
- ausência de endpoint DynamoDB local e de configuração de store em memória.

As chamadas reais do serviço às tabelas foram aprovadas pela identidade AWS do runtime, sem `AccessDenied` ou credencial estática injetada no Deployment.

## Tabelas canônicas

As cinco tabelas estavam `ACTIVE` e configuradas com cobrança `PAY_PER_REQUEST`:

| Tabela | Stream | Itens após o fluxo |
|---|---|---:|
| `oficina-execution-lab-catalogo` | Desabilitado | `6` |
| `oficina-execution-lab-estoque` | `NEW_AND_OLD_IMAGES` | `3` |
| `oficina-execution-lab-execucoes` | `NEW_AND_OLD_IMAGES` | `3` |
| `oficina-execution-lab-outbox` | `NEW_AND_OLD_IMAGES` | `2` |
| `oficina-execution-lab-idempotencia` | Desabilitado | `5` |

As quantidades acima foram obtidas por `Scan` e conferidas com os itens retornados. O `ItemCount` descritivo do DynamoDB permaneceu atrasado, como esperado para essa métrica aproximada.

## Fluxos reais e registros sentinela

As tabelas estavam inicialmente vazias. Foram executados endpoints reais do Service Kubernetes com `X-Idempotency-Key` individuais e `X-Correlation-Id=b2-exec-ddb-rem-001-20260713` para criar peça, serviço, entrada de estoque, execução e início de diagnóstico.

| Categoria | Evidência |
|---|---|
| Peça | `pecaId=74761ec8-3b80-4710-8ba8-d4864a0542f7`, código `EVID-DDB-20260713`, armazenada como `PECA#<pecaId>/METADATA`. |
| Serviço | `servicoId=5fbb4709-cd38-4f03-b238-9657636823aa`, nome `Inspeção DynamoDB`. |
| Estoque | Saldo da peça com `quantidadeDisponivel=12` e `quantidadeReservada=0`. |
| Movimento | `movimentoId=660efd98-f27e-40ce-9bf2-6c06e0ca76a2`, tipo `ENTRADA`, associado à peça e ao `correlationId`. |
| Execução | `execucaoId=a265dde4-92c8-468f-b34e-ae033598eee2`, OS `48f2a5be-b4ee-4ae5-b8b5-5b209b5063cd`, prioridade `10` e status `EM_DIAGNOSTICO`. |
| Histórico operacional | Dois itens `EXECUCAO_HISTORICO`, correspondentes à criação e ao início do diagnóstico. |
| Outbox de estoque | Evento `estoqueAcrescentado`, `eventId=8c242bf0-d6ac-46ac-98f4-1952b244cd18`, persistido como `PENDING`. |
| Outbox de diagnóstico | Evento `diagnosticoIniciado`, `eventId=96ee0d7a-f40f-4d5a-b00f-be9e5877ff97`, persistido como `PENDING`. |
| Idempotência | Cinco registros `REQUEST` com `processingStatus=COMPLETED`, um para cada operação mutável. |

Os logs estruturados registraram HTTP `201` ou `200` para os cinco comandos e a criação dos dois eventos da Outbox com o mesmo `correlationId`. A publicação SNS/SQS dos itens `PENDING` pertence à validação integrada de `[B2-MSG-REM-001]`; neste item, sua presença comprova a persistência da Outbox no DynamoDB canônico.

## Persistência após restart

O pod `oficina-execution-service-5895dcd7bb-jq8l8`, UID `fba92a73-6407-448f-9cd1-d3b07875cfef`, foi excluído de forma controlada. O Deployment criou `oficina-execution-service-5895dcd7bb-cnrzl`, UID `a7f9f794-fe39-475d-a48c-f6724df6a2af`, usando a mesma imagem `1.0.16`.

Após o novo pod ficar pronto:

- a API retornou a mesma peça sentinela;
- a API retornou o mesmo saldo `12/0`;
- a API retornou a mesma execução em `EM_DIAGNOSTICO`;
- os novos `Scan` mantiveram exatamente `6`, `3`, `3`, `2` e `5` itens nas cinco tabelas;
- os registros sentinela de catálogo, estoque, execução, histórico, Outbox e idempotência permaneceram idênticos.

Com o uso das tabelas AWS reais, a ausência de fallback local e a preservação após restart comprovados, `[B2-EXEC-DDB-REM-001]` está concluído.
