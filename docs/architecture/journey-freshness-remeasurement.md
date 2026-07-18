# Nova medição da atualização da jornada operacional

## Objetivo

Comparar a convergência da jornada após o isolamento dos publicadores da Outbox e dos consumidores por fila com a [linha de base anterior](journey-freshness-measurement.md). Esta evidência conclui o item `[D-JOURNEY-FRESHNESS-REMEASURE-001]` do [roadmap](../../ROADMAP.md) e verifica a meta definida na [ADR-014](../../adr/ADR-014%20-%20Convergência%20da%20Jornada%20e%20Isolamento%20dos%20Workers.md).

## Ambiente e condições

A rodada ocorreu em 18/07/2026 no `lab`, região AWS `us-east-1`, com uma réplica saudável e sem reinício de cada serviço:

| Serviço | Versão |
|---|---:|
| `oficina-execution-service` | `1.5.0` |
| `oficina-os-service` | `1.11.0` |
| `oficina-billing-service` | `1.7.2` |

Cada fila possuía um consumidor independente de thread única por pod, o publicador usava worker próprio e o intervalo externo padrão era `250 ms`. Antes da primeira amostra, as 32 filas ativas estavam sem mensagens visíveis, em voo ou atrasadas. As 22 DLQs continham 45 mensagens históricas conhecidas.

A execução usou o identificador `freshness-remeasure-20260718T200849Z`, dados exclusivamente sintéticos e 30 Ordens de Serviço independentes, processadas de forma sequencial para não criar backlog artificial. Cada OS percorreu início e conclusão de diagnóstico com um serviço incluído. A trigésima OS foi estendida pela jornada com recusa, retomada do diagnóstico, nova conclusão, aprovação, reparo, pagamento e entrega.

## Método

Foram preservados os mesmos limites da medição anterior:

1. registro transacional como `PENDING` na Outbox do Execution;
2. término HTTP do comando, quando o operador já recebeu `200`;
3. publicação como `PUBLISHED`;
4. log `domain event consumed` do OS, emitido após a persistência da transição;
5. ACK da mensagem pelo consumidor do OS.

Os marcos foram correlacionados por `eventId`. O `correlationId` identificou a rodada e a amostra, mas não foi usado sozinho para atribuir eventos, pois a Saga preserva a correlação original quando retoma uma jornada. A média usa todas as observações, o p50 é a mediana e o p95 usa o elemento de posição `ceil(0,95 × n)`, com `n = 30` por transição.

## Resultados de diagnóstico

Todos os valores abaixo estão em milissegundos.

### `diagnosticoIniciado`

| Trecho | média | p50 | p95 | máximo |
|---|---:|---:|---:|---:|
| duração HTTP | 73,833 | 54,500 | 141,000 | 148,000 |
| `PENDING` → resposta HTTP | 14,518 | 11,084 | 53,886 | 72,838 |
| resposta HTTP → publicação | 212,693 | 225,716 | 320,026 | 349,694 |
| publicação → persistência no OS | 86,982 | 55,831 | 295,808 | 315,929 |
| resposta HTTP → convergência no OS | 299,675 | 314,489 | 456,893 | 477,285 |
| `PENDING` → convergência no OS | 314,193 | 330,570 | 471,649 | 488,598 |

### `diagnosticoFinalizado`

| Trecho | média | p50 | p95 | máximo |
|---|---:|---:|---:|---:|
| duração HTTP | 56,067 | 53,000 | 83,000 | 96,000 |
| `PENDING` → resposta HTTP | 10,879 | 10,547 | 13,911 | 15,298 |
| resposta HTTP → publicação | 165,284 | 147,365 | 301,148 | 324,599 |
| publicação → persistência no OS | 77,405 | 55,995 | 194,757 | 311,749 |
| resposta HTTP → convergência no OS | 242,689 | 201,928 | 420,999 | 441,314 |
| `PENDING` → convergência no OS | 253,568 | 211,703 | 431,151 | 451,428 |

As 60 amostras ficaram abaixo de `5 s` e de `10 s`. Os maiores tempos entre resposta e convergência foram `477,285 ms` no início e `441,314 ms` na conclusão do diagnóstico.

## Comparação direta com a linha de base

| Transição | linha de base: resposta → OS | nova média | novo p95 | novo máximo | redução da média |
|---|---:|---:|---:|---:|---:|
| `diagnosticoIniciado` | 57,192 s | 0,300 s | 0,457 s | 0,477 s | 99,476% |
| `diagnosticoFinalizado` | 70,450 s | 0,243 s | 0,421 s | 0,441 s | 99,656% |

Na linha de base, resposta até publicação consumia `43,365–58,178 s` e publicação até persistência consumia `12,272–13,826 s`. Na nova rodada, as médias desses trechos foram, respectivamente, `165–213 ms` e `77–87 ms`.

A espera até publicação ainda representa a maior parcela relativa da nova latência — 71,0% no início e 68,1% na conclusão —, mas seu valor absoluto máximo ficou abaixo de `350 ms`. Não restou um gargalo de mensageria que se aproxime da meta operacional.

## Extensão da jornada com Billing

A última OS percorreu as fronteiras do Billing e terminou em `ENTREGUE`. Os tempos foram derivados dos logs estruturados; o último valor foi delimitado pela primeira leitura HTTP que observou o estado final.

| Transição observada | resposta do comando → efeito observado |
|---|---:|
| recusa → persistência no OS | 214,602 ms |
| recusa → persistência no Execution | 243,300 ms |
| nova conclusão do diagnóstico → persistência no OS | 459,075 ms |
| aprovação → persistência no OS | 285,101 ms |
| aprovação → persistência no Execution | 495,940 ms |
| aprovação → consumo de `execucaoIniciada` no OS | 835,069 ms |
| fim do reparo → consumo de `execucaoFinalizada` no OS | 320,984 ms |
| fim do reparo → registro da Outbox de pagamento | 1.409,572 ms |
| confirmação do pagamento → persistência no OS | 200,572 ms |
| entrega → primeira leitura da OS como `ENTREGUE` | 426,739 ms |

Os dois eventos concorrentes de finalização foram consumidos e confirmados sem erro. A métrica do provedor passou de uma para duas solicitações bem-sucedidas durante a extensão, comprovando uma única nova chamada para o pagamento; a API retornou um único pagamento para a OS.

## Integridade e saúde após a rodada

- 60 eventos de diagnóstico possuíam `eventId` único;
- cada evento teve exatamente um `PENDING` e um `PUBLISHED` no Execution, além de um `CONSUMED` e um `ACKED` no OS;
- não houve `WARN` ou `ERROR` correlacionado à execução nos três serviços;
- todas as Outboxes terminaram com backlog e idade do item mais antigo iguais a zero;
- as 32 filas ativas terminaram zeradas;
- as DLQs permaneceram com as mesmas 45 mensagens históricas, sem itens em voo ou atrasados;
- os três pods permaneceram prontos, sem reinício, e a amostra final de CPU ficou abaixo de 8% por processo.

Esses sinais não substituem monitoramento contínuo de capacidade, mas descartam perda, duplicação observável, crescimento de DLQ ou saturação relevante durante a janela medida.

## Conclusão

A remediação atingiu a meta da ADR-014 com ampla margem: p95 de `456,893 ms` e `420,999 ms`, contra o limite de `5 s`, e máximos inferiores a `478 ms`, contra o limite de `10 s`. A comparação mostra reduções médias de 99,476% e 99,656% no trecho resposta HTTP até convergência canônica.

O item de remedição estatística está concluído. Esta evidência desbloqueia a reavaliação do trecho convergência → navegador, que deve decidir entre atualização manual, polling limitado, SSE ou WebSocket sem atribuir ao canal visual o atraso de mensageria já removido.
