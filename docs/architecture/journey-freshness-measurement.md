# Medição de atualização da jornada operacional

## Objetivo

Medir a defasagem entre comandos aceitos pelo `oficina-execution-service` e a atualização do estado global e das capabilities mantidas pelo `oficina-os-service`. Esta medição atende ao item `[D-JOURNEY-FRESHNESS-MEASURE-001]` do [roadmap](../../ROADMAP.md) e fornece evidência para a ADR subsequente; ela não escolhe SSE nem autoriza implementação.

## Contexto observado

Na tela de atendimento, o Execution Service é a autoridade dos comandos de diagnóstico e reparo. O OS Service recebe os eventos correspondentes por SNS/SQS, atualiza a Saga e passa a devolver as capabilities globais. Até essa convergência, a resposta imediata do comando técnico e a leitura global podem divergir legitimamente.

A implementação implantada executa publicação da Outbox e consumo sequencial de todas as filas no mesmo worker. Cada leitura SQS vazia pode fazer long polling por até dez segundos. Assim, o intervalo configurado de cinco segundos não representa o limite real do ciclo: filas anteriores sem mensagem prolongam a próxima passagem do publicador e dos consumidores.

## Método

A medição foi realizada em 18/07/2026 no `lab`, sobre uma jornada operacional real conduzida pela UI. Foram correlacionados, por `eventId` e `correlationId`, os logs estruturados dos serviços Execution `1.4.2` e OS `1.10.3`.

Foram usados quatro marcos em UTC:

1. término HTTP do comando, quando o usuário já recebeu `200`;
2. registro transacional do evento como `PENDING` na Outbox;
3. publicação como `PUBLISHED` no tópico;
4. consumo e transição da Saga no OS Service.

Os identificadores completos não são necessários para reproduzir a conclusão e não são registrados nesta evidência. A amostra contém uma OS sentinela, uma iniciação e uma conclusão de diagnóstico. Ela demonstra ordem de grandeza e causa técnica, mas não constitui teste de carga nem distribuição estatística suficiente para um SLO.

## Resultados

| Transição | duração HTTP | resposta → publicação | publicação → consumo OS | resposta → convergência OS |
| --- | ---: | ---: | ---: | ---: |
| `diagnosticoIniciado` | 182 ms | 43,365 s | 13,826 s | 57,192 s |
| `diagnosticoFinalizado` | 195 ms | 58,178 s | 12,272 s | 70,450 s |
| Média observada | 189 ms | 50,772 s | 13,049 s | 63,821 s |

O comando foi rápido nos dois casos. Entre 76% e 83% da defasagem total ocorreu depois da resposta HTTP e antes da publicação da Outbox. O transporte e consumo acrescentaram aproximadamente doze a quatorze segundos.

O log `domain event consumed` é emitido após a persistência da transição pelo gateway do OS Service; portanto, ele foi adotado como limite de convergência do estado canônico. Não havia uma sondagem HTTP sincronizada imediatamente após esse marco, logo esta rodada não atribui latência adicional à leitura pelo API Gateway.

## Amostra de controle após as correções funcionais

Antes de alterar os workers, a [homologação ponta a ponta das fronteiras](../delivery/mechanic-workspace-lab-evidence.md#homologação-ponta-a-ponta-das-fronteiras) repetiu o início de diagnóstico com Execution `1.4.2`, OS `1.10.4` e Billing `1.6.1`. A resposta do comando até a leitura do estado `EM_DIAGNOSTICO` no OS levou `56,454 s`.

Essa única amostra não substitui a linha de base nem possui tamanho para percentis. Ela funciona como controle: ficou apenas `0,738 s` abaixo dos `57,192 s` anteriores e confirma que as correções de fronteira, idempotência financeira e resolução da OS nos eventos de pagamento não reduziram incidentalmente o atraso dos workers. A comparação estatística permanece reservada à remedição com pelo menos 30 amostras por transição.

## Interpretação

A medição confirma uma necessidade operacional de atualização mais assertiva, mas não demonstra que SSE seja a primeira correção. Um stream emitido pelo OS Service reduziria a espera entre convergência e atualização visual, porém continuaria notificando somente depois dos 57–70 segundos observados.

A ADR deve avaliar nesta ordem:

1. separar o publicador da Outbox do loop de consumo;
2. evitar long polling sequencial de várias filas no mesmo worker, usando consumidores independentes ou paralelos com limites explícitos;
3. definir e medir uma meta de comando até convergência após essa correção;
4. somente então comparar atualização manual, polling limitado, SSE e WebSocket para o trecho entre convergência e navegador.

## Restrição da borda AWS

O ambiente usa API Gateway HTTP API, cujo timeout máximo de integração é trinta segundos e não pode ser ampliado. A documentação AWS informa que response streaming é suportado apenas por REST APIs. Portanto, uma eventual decisão por SSE exigirá uma borda regional de REST API com integração proxy em modo `STREAM`, ou outra exposição explicitamente aprovada; adicionar apenas uma rota ao HTTP API atual não atende ao requisito.

Referências oficiais:

- [Response streaming no API Gateway](https://docs.aws.amazon.com/apigateway/latest/developerguide/response-transfer-mode.html)
- [Quotas do API Gateway HTTP API](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-quotas.html)

## Conclusão e gatilho da ADR

O item de medição está concluído e desbloqueia a ADR. A evidência atende ao gatilho de reavaliação porque duas ações diretamente observadas pelo operador mantiveram snapshots globais divergentes por quase um minuto ou mais.

As implementações continuam bloqueadas: a ADR deve definir uma meta mensurável e decidir se o escopo termina na correção dos workers ou também inclui projeção versionada e SSE. Caso escolha SSE, o stream deve ser apenas um mecanismo de invalidação; o snapshot persistido do OS Service permanece a fonte da verdade.

A decomposição das correções de mensageria, os critérios de resiliência e o método de comparação posterior estão no [plano de redução da defasagem da jornada](journey-freshness-remediation-plan.md).
