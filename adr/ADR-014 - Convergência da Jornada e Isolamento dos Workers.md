# ADR-014 - Convergência da jornada e isolamento dos workers

## Status

**Aceito**

## Contexto

A [medição de atualização da jornada](../docs/architecture/journey-freshness-measurement.md) mostrou que comandos do Execution responderam em menos de 200 ms, mas o estado canônico no OS Service convergiu somente após `57,192–70,450 s`. Entre 76% e 83% desse atraso ocorreu antes da publicação da Outbox; outros 12 a 14 segundos decorreram entre publicação, recebimento SQS e persistência.

Execution e Billing executavam publicação da Outbox e varredura sequencial das filas no mesmo worker. O OS já separava publicação e consumo, porém ainda percorria suas filas sequencialmente. Como cada fila vazia pode manter um long polling, a posição da fila e a duração do ciclo atrasavam trabalho independente.

O snapshot persistido pelo OS Service continua sendo a fonte da verdade da jornada. Polling do frontend, SSE e WebSocket atuariam somente após essa convergência e não corrigiriam a causa medida.

## Opções consideradas

### 1. Isolar publicadores e consumidores por fila

Executar a publicação da Outbox em worker exclusivo e manter um loop supervisionado e independente para cada fila SQS, com concorrência limitada.

Essa opção ataca os dois trechos dominantes, preserva a comunicação assíncrona definida na [ADR-008](ADR-008%20-%20Estratégia%20de%20Comunicação%20entre%20Microsserviços.md) e não transfere regras para o frontend.

### 2. Polling limitado pelo frontend

Atualizar periodicamente o snapshot canônico depois de um comando. Reduz a espera posterior à convergência, mas continuaria consultando um estado defasado durante o atraso dos workers e aumentaria leituras nas APIs.

### 3. Projeção versionada com SSE

Publicar invalidações de uma projeção versionada e recarregar o snapshot canônico. Melhora a atualização após a convergência, mas exige fan-out entre réplicas e uma borda AWS compatível com response streaming; o HTTP API atual não oferece essa capacidade.

### 4. WebSocket

Manter conexões bidirecionais e gerenciar sessões, reconexão e fan-out. Não há requisito de comandos bidirecionais em tempo real que justifique essa complexidade antes da correção da mensageria.

### 5. Coordenação síncrona entre serviços

Fazer o comando aguardar a propagação entre serviços. Reduz a divergência percebida, porém introduz acoplamento temporal e falhas em cascata, contrariando a estratégia assíncrona da plataforma.

## Decisão

A primeira remediação será a opção 1. Polling, SSE e WebSocket ficam condicionados à nova medição; coordenação síncrona entre domínios não será usada para mascarar atraso da mensageria.

### Meta de convergência

Em uma janela sem backlog preexistente, a latência entre o término da resposta HTTP do comando e a persistência observável do estado canônico no OS Service deve atingir:

- `p95` menor ou igual a `5 s`;
- nenhuma amostra acima de `10 s`;
- no mínimo 30 amostras para cada transição de início e conclusão de diagnóstico.

A homologação também deve percorrer recusa e retomada do diagnóstico, reparo, pagamento e entrega. A meta somente é considerada atingida sem perda de eventos, efeito de negócio duplicado, crescimento de DLQ ou saturação relevante de CPU, conexões, banco ou APIs AWS.

### Publicação da Outbox

Cada serviço manterá um worker exclusivo de publicação, sem compartilhar executor ou ciclo com consumidores. A seleção de itens publicáveis continuará limitada por batch e por backoff.

Entre réplicas, cada item será adquirido por claim atômico com lease. O claim deve:

- preservar os estados canônicos `PENDING`, `PUBLISHED` e `FAILED`;
- identificar o proprietário e a validade do lease sem alterar o `eventId`;
- permitir recuperação após expiração do lease ou encerramento da réplica;
- aceitar conclusão somente pelo proprietário do claim vigente;
- impedir duas publicações deliberadas do mesmo item enquanto o lease estiver válido;
- continuar compatível com entrega at-least-once, pois falha após publicar e antes de confirmar ainda pode gerar nova tentativa.

PostgreSQL deve realizar a aquisição por atualização transacional/condicional, sem manter transação aberta durante a chamada SNS. DynamoDB deve usar expressão condicional equivalente. O tempo do lease, o batch, o intervalo e o backoff serão configuração externa com limites seguros.

### Consumo das filas

Cada fila terá um loop de long polling independente e supervisionado por pod. O paralelismo inicial ocorre entre filas; quantidade de mensagens recebidas, chamadas em voo e recursos usados devem possuir limites explícitos. Uma fila vazia, lenta ou inválida não pode atrasar o publicador nem outra fila.

A mensagem só será confirmada depois da persistência idempotente. Evento duplicado ou fora de ordem deve seguir as regras atuais de deduplicação e progressão de estado. Falhas retentáveis permanecem disponíveis para retry e DLQ, e o encerramento deve aguardar trabalho já iniciado dentro de um prazo configurável.

### Observabilidade e comparação

Os serviços devem preservar `eventId`, `correlationId`, `aggregateId` e timestamps suficientes para decompor:

1. comando até criação `PENDING`;
2. idade até claim e publicação;
3. publicação até recebimento SQS;
4. recebimento até persistência;
5. resposta HTTP até convergência no OS.

Métricas devem expor backlog, idade do item mais antigo e progresso por publicador e por fila, sem JWT, capability, e-mail, CPF ou demais dados pessoais. A [nova medição](../docs/architecture/journey-freshness-remeasurement.md) comparou média, p50, p95 e máximo de cada trecho diretamente com a linha de base. O resultado atingiu p95 inferior a `457 ms`, máximo inferior a `478 ms` e redução média superior a 99%, sem perda, duplicação observável, crescimento de DLQ ou saturação relevante.

## Fonte da verdade e atualização do frontend

O snapshot persistido pelo OS Service permanece a fonte da verdade. O frontend pode recarregá-lo manualmente durante esta remediação e não pode inferir capabilities ou reconstruir a Saga.

Depois da nova medição, o trecho entre convergência e navegador será reavaliado. Se ainda justificar atualização automática, uma decisão complementar escolherá polling limitado, SSE ou WebSocket e contratará a projeção/invalidação necessária. Uma eventual SSE usará invalidação versionada, não eventos de domínio como estado de tela, e exigirá borda AWS compatível com streaming.

## Consequências

### Positivas

- remove long polling sequencial do caminho de publicação e das demais filas;
- torna o atraso mensurável por trecho e worker;
- mantém fonte da verdade, contratos de eventos, retries, DLQ e idempotência;
- fornece critério objetivo e exigente para decidir se o frontend ainda precisa de canal automático.

### Negativas

- aumenta o número de unidades de execução e chamadas simultâneas por pod;
- exige controle explícito de threads, conexões, leases e encerramento;
- requer migrações compatíveis para armazenar o claim da Outbox;
- não garante exactly-once após falha entre publicação SNS e confirmação local.

## Referências

- [Plano de redução da defasagem](../docs/architecture/journey-freshness-remediation-plan.md)
- [Medição da atualização da jornada](../docs/architecture/journey-freshness-measurement.md)
- [Nova medição após o isolamento dos workers](../docs/architecture/journey-freshness-remeasurement.md)
- [Contrato de tópicos de mensageria](../contracts/Contrato%20de%20Tópicos%20de%20Mensageria.md)
- [Contrato de idempotência](../contracts/idempotency.md)
- [Frontend operacional Angular](ADR-013%20-%20Frontend%20Operacional%20Angular.md)
