# Medição de atualização do dashboard operacional

## Objetivo

Quantificar latência, volume, custo direto e pressão nos backends antes de decidir se a atualização do [dashboard operacional](dashboard-operational-discovery.md) deve continuar manual, adotar polling ou evoluir para SSE/WebSocket. Esta medição atende ao item `[UI-FUT-REALTIME-MEASURE-001]` do [roadmap do frontend](roadmap.md) e não constitui uma decisão arquitetural.

## Estado implantado em 17/07/2026

A SPA não executa polling automático. O dashboard consulta seus blocos em paralelo ao abrir a página e novamente apenas quando o operador aciona **Atualizar**. O único temporizador existente na aplicação expira a sessão; ele não consulta APIs.

As cinco respostas canônicas informam `refreshAfterSeconds: 30`, mas a UI deliberadamente não consome essa sugestão. Portanto, o custo recorrente atual é zero enquanto a página permanece ociosa. Cada carga de um administrador gera cinco requisições; mecânico gera duas e recepcionista, três.

## Método

A medição foi feita contra o `lab` público em `us-east-1`, com identidade administrativa sintética, dez amostras sequenciais por endpoint e as mesmas integrações públicas usadas pela UI: API Gateway para todos os blocos, NLB/pods para os três microsserviços e Lambda para Auth. Foram coletados status HTTP, tempo total observado pelo cliente e bytes do corpo. A correlação `dashboard-polling-measure-20260717T213123Z` identifica a rodada nos logs sem registrar JWT ou dados pessoais.

A amostra é intencionalmente pequena e representa o laboratório, não um teste de carga ou um SLO de produção. Os percentis servem para identificar ordem de grandeza e caudas de latência; uma decisão de escala exige uma janela maior e concorrência controlada.

## Resultado observado

Todas as 50 requisições retornaram `200`.

| Bloco | média | p50 | p95 | máximo | resposta |
| --- | ---: | ---: | ---: | ---: | ---: |
| Execução | 1.148 ms | 549 ms | 2.794 ms | 3.843 ms | 2.264 bytes |
| Faturamento | 1.033 ms | 501 ms | 2.976 ms | 2.994 ms | 1.693 bytes |
| Ordens de serviço | 902 ms | 515 ms | 1.949 ms | 2.931 ms | 1.524 bytes |
| Usuários | 823 ms | 457 ms | 577 ms | 3.881 ms | 263 bytes |
| Credenciais | 1.109 ms | 513 ms | 2.909 ms | 3.941 ms | 1.109 bytes |

Como a UI consulta os blocos em paralelo, o tempo percebido tende a ser limitado pelo bloco mais lento, não pela soma. A mediana próxima de meio segundo é adequada à atualização manual, mas as caudas de aproximadamente 3 a 4 segundos tornariam um polling de 30 segundos perceptível em redes ou pods sob contenção.

## Projeção do polling de 30 segundos

Premissas: jornada de 8 horas, 22 dias úteis por mês, página continuamente visível, respostas com os tamanhos medidos e nenhuma atualização extra manual.

| Papel | rotas por ciclo | requisições/dia | requisições/mês | resposta/mês por sessão |
| --- | ---: | ---: | ---: | ---: |
| Administrativo | 5 | 4.800 | 105.600 | 144,7 MB |
| Recepcionista | 3 | 2.880 | 63.360 | 68,0 MB |
| Mecânico | 2 | 1.920 | 42.240 | 80,0 MB |

Para referência, 100 sessões administrativas contínuas produziriam aproximadamente 10,56 milhões de chamadas e 14,5 GB de corpos por mês. Ao preço publicado para os primeiros 300 milhões de chamadas de HTTP API em `us-east-1`, isso representa cerca de **US$ 10,56/mês somente em requisições do API Gateway**, antes de transferência, logs, bancos e capacidade computacional. O valor deve ser recalculado na [página oficial de preços do API Gateway](https://aws.amazon.com/api-gateway/pricing/) na data de uma eventual decisão.

O custo direto do gateway é pequeno no porte atual. O principal risco está no trabalho repetido a jusante.

## Impacto operacional

Os endpoints atuais produzem o snapshot no momento da chamada e percorrem coleções completas:

- OS lista todas as ordens, calcula contagens em memória e consulta histórico para até cinco atenções; o bloco de usuários também lista todos os usuários;
- Execution lista todas as execuções e toda a fila;
- Billing carrega todos os orçamentos e pagamentos;
- Auth carrega todas as credenciais e consulta o estado de ativação de cada usuário.

Assim, polling de 30 segundos multiplica consultas e processamento aproximadamente por sessão aberta e cresce com o total de registros. O limite de cinco itens reduz apenas a resposta; não limita o trabalho de leitura. Também aumenta logs, traces, correlações e ruído de alertas, podendo esconder chamadas operacionais relevantes.

A atualização automática apenas quando `document.visibilityState === "visible"`, prevista no discovery, reduziria abas em segundo plano, mas não corrige o custo de varredura das sessões ativas. Cache, projeções incrementais ou agregações persistidas devem ser avaliados antes de polling em escala.

## Conclusão da medição

Não há evidência operacional que justifique SSE ou WebSocket neste momento: a UI já entrega atualização inicial e manual, os dados aceitam consistência explícita por bloco e nenhum fluxo implantado exige reação subsegundo.

Também não é recomendável habilitar agora o intervalo de 30 segundos já retornado pelos contratos. Embora o custo direto estimado seja baixo no laboratório, os endpoints fazem leituras proporcionais ao volume total e exibiram caudas de latência próximas de quatro segundos.

A próxima decisão deve usar como linha de base:

1. manter atualização manual como comportamento atual;
2. medir uso real do botão, idade dos snapshots e necessidade declarada pelos operadores;
3. otimizar ou materializar as agregações antes de qualquer polling recorrente;
4. abrir ADR comparando polling, SSE e WebSocket somente se houver requisito mensurável de defasagem que a atualização manual não atenda.

Gatilho sugerido para reavaliação: operação precisar de atualização automática com defasagem máxima definida, ou uso manual sustentado indicar mais de uma atualização por minuto por sessão durante uma janela representativa.

Esta conclusão permanece válida para o dashboard. A medição posterior da [atualização da jornada operacional](../architecture/journey-freshness-measurement.md) avaliou outro fluxo e encontrou defasagem de 57 a 70 segundos após comandos de diagnóstico, desbloqueando a ADR canônica de assertividade da jornada sem alterar retrospectivamente o resultado deste experimento.
