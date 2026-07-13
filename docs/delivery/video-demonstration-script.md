# Roteiro do Vídeo de Demonstração da Fase 4

## Objetivo

Orientar a gravação do vídeo final de até 15 minutos exigido pelo [Enunciado da Fase 4](Enunciado%20Fase%204.md), cobrindo arquitetura distribuída, fluxo completo da Ordem de Serviço, Saga com compensação, CI/CD independente, Kubernetes, qualidade, Mercado Pago e rastreamento no New Relic.

Este roteiro complementa o [Checklist Final de Entrega da Fase 4](phase-4-delivery-checklist.md), o [Diagrama Geral da Arquitetura Final](../architecture/architecture-diagram.md), os [Fluxos da Saga da Ordem de Serviço](../architecture/saga-flows.md), o [Checklist de Deploy Independente](independent-deploy-checklist.md), o [Padrão de Observabilidade Distribuída](../observability/observability.md) e o [Relatório do E2E no ambiente lab](../observability/d-nr-rem-005-e2e-lab-report.md).

## Formato e Limite

- duração planejada: `14min30s`;
- margem para transições ou espera: `30s`;
- duração máxima absoluta: `15min00s`;
- ambiente demonstrado: `lab`;
- arquitetura: Saga orquestrada pelo `oficina-os-service`;
- API: chamadas reais pela superfície prevista no API Gateway;
- observabilidade: dashboards e consultas reais na conta New Relic do ambiente;
- deploy: execução real ou run concluído e verificável do pipeline de um microsserviço.

Não acelerar o vídeo a ponto de tornar respostas, nomes ou evidências ilegíveis. Se o ensaio exceder `14min30s`, reduzir explicações, não remover evidências obrigatórias.

## Pré-condições da Gravação

### Ambiente

- [ ] os Deployments `oficina-os-service`, `oficina-billing-service` e `oficina-execution-service` estão `Available` no `eks-lab`;
- [ ] o New Relic OpenTelemetry Collector está saudável;
- [ ] a API pública e `POST /auth/token` respondem;
- [ ] PostgreSQL, DynamoDB, SNS/SQS e secrets de runtime estão disponíveis;
- [ ] a integração Mercado Pago sandbox está habilitada com credencial válida;
- [ ] existe um workflow bem-sucedido recente que publicou imagem e concluiu rollout de pelo menos um microsserviço;
- [ ] os projetos SonarCloud exibem Quality Gate e cobertura da revisão usada no deploy;
- [ ] os dashboards `Microsserviços Lab` e `Saga e Ordem de Serviço Lab` recebem dados recentes.

### Massa e identificadores

Preparar duas massas independentes e identificadores novos:

```text
video-happy-<UTC_TIMESTAMP>
video-compensated-<UTC_TIMESTAMP>
```

Usar cada valor como `X-Correlation-Id` em todas as chamadas do respectivo cenário. Preparar também chaves `X-Idempotency-Key` únicas e determinísticas por operação. Não reutilizar IDs do [relatório histórico de E2E](../observability/d-nr-rem-005-e2e-lab-report.md) como se fossem evidência da gravação atual.

### Telas abertas antes de gravar

1. diagrama geral renderizado;
2. run bem-sucedido do GitHub Actions do serviço escolhido para deploy;
3. API client com as requisições ordenadas em pastas `Caminho feliz` e `Falha compensada`;
4. consulta final da OS e de seu histórico;
5. dashboard operacional e dashboard da Saga no New Relic;
6. SonarCloud com Quality Gate e cobertura;
7. OpenAPI canônica ou Swagger temporário do serviço.

Ocultar notificações, favoritos pessoais, e-mail, account IDs desnecessários e outras informações fora do escopo.

### Segurança da gravação

- nunca exibir senha, access token do Mercado Pago, JWT, chaves AWS, license key do New Relic ou conteúdo de secrets Kubernetes;
- manter o JWT apenas em variável protegida do API client;
- não abrir headers de autenticação durante a gravação;
- usar dados fictícios válidos, sem CPF, e-mail ou informações pessoais reais;
- revisar o vídeo antes do upload e cortar qualquer frame que exponha credencial.

## Linha do Tempo

| Intervalo | Duração | Demonstração |
|---|---:|---|
| `00:00–00:40` | `0:40` | Abertura e objetivo. |
| `00:40–01:40` | `1:00` | Arquitetura e ownership. |
| `01:40–03:10` | `1:30` | CI/CD, qualidade e deploy Kubernetes. |
| `03:10–06:50` | `3:40` | Caminho feliz da OS e Saga. |
| `06:50–09:10` | `2:20` | Falha de estoque e compensação. |
| `09:10–11:50` | `2:40` | Logs, eventos, métricas e traces correlacionados. |
| `11:50–12:50` | `1:00` | Mercado Pago sandbox e métricas financeiras. |
| `12:50–13:50` | `1:00` | Testes, cobertura, Quality Gate e OpenAPI. |
| `13:50–14:30` | `0:40` | Encerramento. |

## Roteiro Detalhado

### 00:00–00:40 — Abertura

Mostrar o título da entrega e informar:

> Esta é a plataforma distribuída da oficina mecânica da Fase 4. A demonstração mostrará uma Ordem de Serviço passando pelos três microsserviços, uma falha compensada pela Saga, deploy independente em Kubernetes e correlação ponta a ponta no New Relic.

Não gastar tempo apresentando integrantes; os nomes e identificações pertencem ao PDF final.

### 00:40–01:40 — Arquitetura e ownership

Mostrar o [Diagrama Geral da Arquitetura Final](../architecture/architecture-diagram.md) e apontar:

- `oficina-os-service`: dono da OS e orquestrador da Saga, com PostgreSQL `oficina_os`;
- `oficina-billing-service`: dono de orçamento, pagamento e Mercado Pago, com PostgreSQL `oficina_billing`;
- `oficina-execution-service`: dono de diagnóstico, execução e estoque, com DynamoDB;
- REST para comandos síncronos e SNS/SQS para eventos assíncronos via Outbox;
- imagens no ECR e workloads no EKS;
- New Relic OpenTelemetry Collector recebendo logs, métricas e traces.

Fala sugerida:

> Escolhemos Saga orquestrada porque o serviço de OS já é a autoridade do estado global. Cada serviço mantém seu próprio banco e nenhum acessa diretamente a persistência de outro domínio.

### 01:40–03:10 — CI/CD e deploy independente

Mostrar um run bem-sucedido e recente de `.github/workflows/service-ci.yml` de um microsserviço. Expandir apenas o suficiente para comprovar:

1. build e testes;
2. relatório JaCoCo e Quality Gate SonarCloud;
3. publicação da imagem versionada no ECR;
4. atualização somente do Deployment do serviço;
5. `kubectl rollout status` concluído.

Mostrar a versão do `pom.xml`, a tag/release correspondente e o Deployment usando a mesma imagem. Se usar terminal, limitar a saída a comandos seguros:

```bash
kubectl get deployment oficina-os-service -n default
kubectl get pods -n default -l app=oficina-os-service
kubectl rollout status deployment/oficina-os-service -n default --timeout=30s
```

Não executar um deploy longo durante a gravação. Um run concluído é aceito desde que a URL, o commit, a versão e o rollout sejam legíveis e correspondam ao ambiente demonstrado.

### 03:10–06:50 — Caminho feliz da OS

No API client, manter visíveis status HTTP, IDs retornados e o `X-Correlation-Id`. Executar, em sequência compacta:

1. autenticar sem mostrar credenciais;
2. criar cliente e veículo fictícios;
3. abrir a OS;
4. criar a execução e iniciar/concluir diagnóstico;
5. gerar e aprovar o orçamento;
6. iniciar e concluir o reparo;
7. registrar pagamento PIX sandbox pelo `POST /api/v1/pagamentos` real;
8. aguardar o desfecho financeiro previsto pelo fluxo integrado, sem confirmar manualmente um pagamento que deveria vir do provedor;
9. entregar o veículo;
10. consultar a OS e seu histórico.

Mostrar a OS final em `ENTREGUE` e resumir os eventos esperados:

```text
ordemDeServicoCriada
diagnosticoFinalizado
orcamentoGerado
orcamentoAprovado
execucaoFinalizada
pagamentoConfirmado
ordemDeServicoEntregue
sagaFinalizadaComSucesso
```

Fala sugerida:

> Os comandos REST usam idempotência e cada confirmação de domínio é persistida na Outbox antes da publicação. O serviço de OS avança o estado global ao consumir os eventos dos demais serviços.

Se a confirmação sandbox for assíncrona, usar polling curto e mostrar o status retornado. Não substituir a integração real pelo endpoint manual de confirmação apenas para acelerar a gravação.

### 06:50–09:10 — Falha compensada

Usar outra OS e outro `correlationId`. Avançar até `EM_EXECUCAO` e então:

1. criar ou selecionar uma peça com saldo insuficiente;
2. tentar reservar estoque;
3. mostrar o `409` esperado e a mensagem categorizada, sem stack trace;
4. cancelar a execução ou acionar a compensação prevista;
5. consultar a execução final em `CANCELADA`;
6. comprovar o evento `sagaCompensada` no New Relic usando o mesmo `correlationId`.

Fala sugerida:

> Esta é uma falha de negócio tratável antes da conclusão técnica. O orquestrador impede o avanço, executa compensações idempotentes e publica `sagaCompensada`; ele não inventa um evento de sucesso.

Não afirmar que a OS terminou em um estado específico sem mostrar a resposta real. A evidência normativa da compensação é o conjunto formado pelo erro esperado, execução cancelada e evento `sagaCompensada` correlacionado.

### 09:10–11:50 — Observabilidade e rastreamento distribuído

No dashboard `Saga e Ordem de Serviço Lab`, filtrar pelos dois `correlationId` da gravação. Mostrar:

- logs dos três serviços;
- eventos por `domainEventType` ou `event.type`;
- `sagaFinalizadaComSucesso` no caminho feliz;
- `sagaCompensada` na falha;
- spans dos serviços participantes e o mesmo `traceId` quando pertencentes ao mesmo trace;
- métricas de HTTP, persistência, Outbox e mensageria.

Consultas NRQL de apoio:

```nrql
FROM Log SELECT count(*)
WHERE correlationId IN ('<HAPPY_CORRELATION_ID>', '<COMPENSATED_CORRELATION_ID>')
SINCE 30 minutes ago
FACET service.name, correlationId
```

```nrql
FROM Log SELECT count(*)
WHERE correlationId IN ('<HAPPY_CORRELATION_ID>', '<COMPENSATED_CORRELATION_ID>')
  AND message = 'outbox event registered'
SINCE 30 minutes ago
FACET service.name, domainEventType
```

```nrql
FROM Span SELECT count(*)
WHERE service.namespace = 'oficina'
  AND correlationId IN ('<HAPPY_CORRELATION_ID>', '<COMPENSATED_CORRELATION_ID>')
SINCE 30 minutes ago
FACET service.name, traceId
```

Se `correlationId` não estiver presente no evento `Span`, partir de um log correlacionado e consultar o `traceId` exibido:

```nrql
FROM Span SELECT * WHERE traceId = '<TRACE_ID>' SINCE 30 minutes ago
```

Mostrar também, sem percorrer todos os gráficos, pelo menos uma consulta ou widget de:

- `persistence.operations.count` por serviço/banco/resultado;
- `outbox.pending.count` ou falhas de Outbox;
- consumo SQS por fila e DLQ;
- retries ou conflitos de idempotência.

### 11:50–12:50 — Mercado Pago sandbox

No pagamento criado durante o caminho feliz, mostrar apenas dados seguros:

- método PIX e ambiente sandbox;
- status e referência externa não secreta;
- `correlationId` da cobrança;
- evento financeiro correspondente.

No dashboard operacional do Billing, mostrar as métricas `payment.provider.*`:

- chamadas por método, desfecho e status do provedor;
- latência da chamada;
- valor por desfecho em BRL;
- falhas ou indisponibilidade, ainda que o valor atual seja zero.

Não mostrar access token, payload sensível, CPF, e-mail real ou QR Code que possa ser reutilizado fora do sandbox.

### 12:50–13:50 — Qualidade e contrato

Mostrar rapidamente:

1. cenário BDD do `oficina-os-service` com caminho feliz e compensação;
2. cobertura acima de 80% e Quality Gate aprovado nos três projetos SonarCloud;
3. OpenAPI/Swagger de um serviço e as OpenAPI canônicas dos outros dois.

Fala sugerida:

> Cada microsserviço possui testes unitários e de integração, cobertura mínima de 80%, análise SonarCloud e contrato OpenAPI versionado. O OS também executa o fluxo completo em BDD.

Os endpoints `/q/swagger-ui`, `/q/openapi`, `/q/metrics` e `/q/health` não devem ser apresentados como rotas públicas permanentes. Para a demonstração, usar arquivo canônico, port-forward controlado ou exceção temporária documentada.

### 13:50–14:30 — Encerramento

Voltar ao diagrama e concluir:

> A solução separa ownership e persistência entre três microsserviços, coordena consistência com Saga orquestrada e compensações idempotentes, automatiza qualidade e deploy por serviço e mantém o fluxo rastreável por `correlationId` no New Relic.

Exibir por poucos segundos os links dos repositórios que também constarão no PDF. Não iniciar nova demonstração durante o encerramento.

## Plano de Contingência

| Situação | Conduta durante a gravação |
|---|---|
| Workflow demora mais que o esperado | Mostrar run concluído, commit, versão, imagem e rollout correspondentes. |
| Evento demora a chegar | Fazer polling por poucos segundos e usar o mesmo `correlationId`; não trocar silenciosamente de massa. |
| New Relic ainda não ingeriu o sinal | Aguardar a janela de ingestão antes de gravar novamente; não usar print antigo como se fosse tráfego atual. |
| Mercado Pago sandbox indisponível | Interromper a gravação final e reagendar; não simular confirmação manual. |
| Falha inesperada do ambiente | Registrar o diagnóstico fora da gravação e reiniciar após estabilizar o `lab`. |
| Tempo acima de 15 minutos | Cortar navegação e explicações repetidas; preservar as evidências obrigatórias. |

## Critérios de Aceite da Gravação

Antes do upload, assistir ao arquivo final e confirmar:

- [ ] duração menor ou igual a `15min00s`;
- [ ] fluxo feliz termina em OS `ENTREGUE` e mostra `sagaFinalizadaComSucesso`;
- [ ] falha tratável mostra erro esperado, compensação e `sagaCompensada`;
- [ ] os três microsserviços aparecem no fluxo ou nas evidências correlacionadas;
- [ ] deploy automatizado comprova testes, imagem versionada e rollout Kubernetes;
- [ ] cobrança PIX usa Mercado Pago sandbox real;
- [ ] logs, eventos e traces usam os `correlationId` gerados para a gravação;
- [ ] métricas operacionais e financeiras aparecem no New Relic;
- [ ] cobertura, Quality Gate e OpenAPI são legíveis;
- [ ] nomes de serviços, eventos, bancos e tecnologias coincidem com os contratos;
- [ ] nenhuma credencial ou dado pessoal real aparece em áudio ou vídeo;
- [ ] o link publicado foi registrado no [Checklist Final de Entrega da Fase 4](phase-4-delivery-checklist.md).

O upload e o registro das evidências finais pertencem aos itens remotos `[D-VIDEO-EVID-001]` e `[D-DELIVERY-EVID-001]` do [ROADMAP](../../ROADMAP.md); preparar este roteiro não os conclui automaticamente.
