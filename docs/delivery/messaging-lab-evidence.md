# Evidência de Mensageria SNS/SQS no Lab

## Escopo

Este documento registra a validação remota de `[B2-MSG-REM-001]` no ambiente `lab`, cobrindo runtime EKS, publicação pela Outbox, entrega SNS/SQS, persistência nos consumidores, correlação, caminho feliz e redrive para DLQ.

Nenhuma credencial, conteúdo de Secret ou corpo com dado sensível foi registrado. Os pods auxiliares usados para consultas foram temporários e removidos automaticamente.

## Runtime e deploy

Em 14/07/2026, os workflows independentes concluíram com sucesso:

- [`oficina-os-service` — run 29329203719](https://github.com/oficina-soat/oficina-os-service/actions/runs/29329203719), implantando a imagem `1.2.4`;
- [`oficina-execution-service` — run 29329221240](https://github.com/oficina-soat/oficina-execution-service/actions/runs/29329221240), implantando a imagem `1.0.17`;
- `oficina-billing-service` permaneceu saudável na imagem `1.1.2`.

Os três Deployments ficaram com uma réplica pronta. O cluster apresentava somente o managed node group `eks-lab-ng-20260714092902417300000007`, em estado `ACTIVE`, sem problemas de saúde, com tamanho desejado `1` e `nodeRole=arn:aws:iam::732369935902:role/LabRole`.

As oito managed policies locais de mensageria e runtime DynamoDB possuem sufixos derivados de conteúdo e `DefaultVersionId=v1`. Isso confirma a substituição content-addressed introduzida por `af4399c`, sem atualização por `iam:CreatePolicyVersion`. Os logs de startup e processamento não apresentaram negação IAM.

## Caminho feliz

A Ordem de Serviço sentinela `020fe4fd-e941-468a-abdf-40a05c7c8401` gerou o evento:

| Campo | Valor |
|---|---|
| `eventId` | `ff3631a6-52c6-43ec-81fd-3e843fcc82e4` |
| `eventType` | `ordemDeServicoCriada` |
| `producer` | `oficina-os-service` |
| tópico | `oficina.os.ordem-de-servico-criada` |
| `correlationId` da requisição produtora | `b2-msg-rem-001-20260714111604` |

Após o deploy da correção de inicialização do worker, o OS publicou o registro pendente da Outbox com `messageStatus=PUBLISHED`. Billing e Execution consumiram e reconheceram a mensagem com `messageStatus=CONSUMED` e `ACKED`. Nos consumidores, o `eventId` também é usado como `correlationId` estável do processamento assíncrono.

A persistência foi comprovada por duas leituras independentes:

- o PostgreSQL `oficina_billing` contém o evento em `billing_consumed_event`, com os mesmos `eventId`, `eventType`, `aggregateId` e `producer`;
- `GET /api/v1/ordens-servico/020fe4fd-e941-468a-abdf-40a05c7c8401/execucao` retornou HTTP `200` e a projeção DynamoDB `64254567-6b39-4b60-b70a-7e23b4eaa218`, com estado `CRIADA`.

Após o ACK, as filas `oficina-os-ordem-de-servico-criada-oficina-billing-service` e `oficina-os-ordem-de-servico-criada-oficina-execution-service` apresentaram zero mensagens disponíveis, em processamento ou atrasadas. A DLQ compartilhada `oficina-os-ordem-de-servico-criada-dlq` também permaneceu zerada. Ambas as filas de origem possuem `maxReceiveCount=5` e criptografia gerenciada pelo SQS.

## Falha controlada e DLQ

Uma mensagem sentinela incompatível com o estado local da Saga foi processada pela fila `oficina-billing-orcamento-gerado-oficina-os-service`. O OS registrou as tentativas com `NotFoundException`, sem reconhecer nem remover a mensagem.

Após as retentativas, a fila de origem ficou vazia e `oficina-billing-orcamento-gerado-dlq` passou a conter uma mensagem. A leitura não destrutiva da DLQ confirmou:

| Campo | Valor |
|---|---|
| `messageId` | `16ba90bf-3465-4d9a-b336-679b1ee521c1` |
| `ApproximateReceiveCount` | `6` |
| `eventId` | `ce4956a7-9334-4514-84bc-00c06e24aef9` |
| `eventType` | `orcamentoGerado` |
| `producer` | `oficina-billing-service` |

O resultado comprova que uma falha de negócio não reconhecida é retentada e redirecionada depois do limite configurado, enquanto a DLQ do caminho feliz permanece vazia.

## Conclusão

O fluxo real Outbox → SNS → SQS → consumidores persistentes foi comprovado sem fallback local e sem negações IAM. O caminho feliz deixou as filas e sua DLQ vazias, e a falha controlada produziu a evidência esperada de redrive. Com isso, `[B2-MSG-REM-001]` está concluído.
