# Homologação da UI no lab

Data de início: 2026-07-16  
Tarefa: `[UI-MVP-REM-001]`  
Estado: concluído

## Publicação validada

O workflow [Deploy UI Lab 29505861890](https://github.com/oficina-soat/oficina-ui/actions/runs/29505861890) publicou no EKS a revisão `3dbf8a7ae02bb26704683e41243ad20684b6052c`. O artefato usado pela imagem foi produzido pelos gates do mesmo workflow, sem recompilação durante o deploy.

Os três jobs terminaram com sucesso:

- build, testes, cobertura, arquitetura, segurança e auditoria;
- E2E isolado, navegação por teclado e acessibilidade automatizada;
- infraestrutura opcional, imagem rastreável e rollout do workload.

Os metadados servidos pelo workload confirmaram o run `29505861890`, a revisão implantada e o instante `2026-07-16T14:20:52Z`.

## Acesso e configuração

URL validada: `https://ucye9d6rka.execute-api.us-east-1.amazonaws.com`

| Verificação | Resultado |
| --- | --- |
| `GET /` | `200`, HTML da Oficina SOAT servido pelo Nginx |
| `GET /healthz` | `200`, corpo `ok` |
| `GET /session` | `200`, mesmo `index.html` da raiz; recarga de rota Angular preservada |
| `GET /main-HAUQ3J5H.js` | `200`, `application/javascript` |
| `GET /config/runtime-config.json` | `200`, JSON válido com endpoints canônicos de API e autenticação |
| `GET /deploy-metadata.json` | `200`, revisão e run correspondentes ao deploy |

A configuração efetiva aponta `apiBaseUrl` para `/api/v1` no API Gateway e `authBaseUrl` para a raiz do mesmo gateway. Ela não contém credenciais nem configuração secreta.

## Segurança e operação

As respostas públicas apresentaram CSP restritiva, HSTS, `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `frame-ancestors 'none'`, políticas de abertura e recursos cross-origin, política de referência e bloqueio de câmera, geolocalização, microfone, pagamento e USB.

O rollout foi aguardado pelo pipeline e terminou em sucesso. A tentativa adicional de consultar o endpoint privado do EKS a partir da estação local não resolveu o DNS privado do cluster; a publicação permanece comprovada pelo job de rollout e pelas respostas do workload através de API Gateway, VPC Link e NLB.

## Composição técnica validada

Em 2026-07-16, as rotas públicas de inclusão de serviço e peça foram acrescentadas ao API Gateway pelo state canônico do `oficina-infra`. O plano e o apply apresentaram exclusivamente quatro criações — duas rotas e duas integrações — sem alteração ou destruição de recursos.

Uma OS técnica já existente, sem dados pessoais na evidência, recebeu um serviço de `R$ 150,00` e duas unidades de uma peça de `R$ 50,00`. Serviço e peça retornaram `200` tanto na primeira requisição quanto no retry com a mesma chave e o mesmo payload. A reutilização da chave da peça com quantidade diferente retornou `409`. A leitura seguinte apresentou total técnico de `R$ 250,00`; o saldo permaneceu com 50 unidades disponíveis, nenhuma reservada e nenhum movimento, comprovando que a mera composição não antecipa decisão de estoque.

A UI efetivamente publicada foi exercitada em Chromium, sem interceptação ou mock. O login real abriu a visão operacional, o detalhe exibiu os dois snapshots, os formulários de inclusão apareceram somente porque a API informou `INCLUIR_SERVICO` e `INCLUIR_PECA`, e a página não apresentou violações automatizáveis WCAG 2.1 A/AA. Em viewport de `375 x 667`, o menu foi aberto por teclado e a navegação permaneceu acessível.

Como a primeira OS encontrada possuía estados incompatíveis entre OS e Execution, uma nova jornada sentinela foi criada. A Execution começou em `CRIADA`, avançou por diagnóstico e reparo e terminou em `REPARO_CONCLUIDO`. O Billing consumiu, nessa ordem, `ordemDeServicoCriada`, `pecaIncluidaNaOrdemDeServico`, `servicoIncluidoNaOrdemDeServico`, `diagnosticoFinalizado` e `execucaoFinalizada`. O orçamento derivado totalizou `R$ 250,00`, foi aprovado e o pagamento PIX de mesmo valor foi confirmado. As consultas e comandos usaram `ui-mvp-rem-20260716` como correlação operacional; os logs estruturados preservaram também `eventId`, `aggregateId`, produtor, consumidor e status de acknowledgment.

O saldo da peça permaneceu com 50 unidades disponíveis, nenhuma reservada e nenhum movimento durante a composição. Isso comprova o comportamento contratado para este incremento: inclusão e orçamento não antecipam reserva ou consumo; decisões de estoque permanecem exclusivamente no Execution.

Durante a repetição exploratória do pagamento, uma segunda chave idempotente para o mesmo orçamento encontrou a restrição `uk_pagamento_orcamento` e retornou `500`. O pagamento original permaneceu íntegro e foi consultado normalmente. Esse comportamento deve ser corrigido no Billing para retornar conflito canônico ou a representação já existente, sem expor erro de persistência.

## Telemetria do navegador

A stack opcional da UI passou a oferecer `POST /ui/telemetry` por API Gateway e Lambda, com retenção de sete dias no log group `/aws/lambda/oficina-ui-telemetry-lab`. O coletor limita o corpo a 4 KiB, valida o envelope e reconstrói somente campos allowlist antes de registrar o evento; não aceita URL, rota, payload, mensagem, stack, CPF, JWT ou valores financeiros.

O endpoint respondeu `202` a um envelope sentinela e foi ativado na configuração runtime do workload. Uma nova execução em Chromium contra a UI publicada registrou `navigation`, `largest_contentful_paint` e `cumulative_layout_shift` com ambiente e revisão implantada. A inspeção do stream confirmou somente os campos allowlist e ausência das credenciais usadas no login. O workflow de deploy agora obtém esse endpoint do output Terraform quando `UI_OBSERVABILITY_ENDPOINT` não for informado.

## Homologação final com mecânico

Em 2026-07-16, a UI publicada foi exercitada sem mocks com uma credencial sentinela que possuía exclusivamente o papel `mecanico`. O guard liberou a fila e a execução e manteve indisponíveis as rotas administrativas. Pela interface real, o mecânico iniciou e concluiu diagnóstico e reparo usando somente ações oferecidas pelo backend. A credencial temporária foi inativada ao final.

A OS sentinela recebeu um serviço e duas unidades de uma peça durante `EM_DIAGNOSTICO`. Após a conclusão do diagnóstico, o Billing criou automaticamente um único orçamento de `R$ 250,00`, sem chamada manual a `POST /orcamentos`. O orçamento foi aprovado, o pagamento criado pelo fluxo assíncrono foi confirmado pela ação canônica e uma segunda tentativa com outra chave idempotente retornou `409` com `DUPLICATE_RESOURCE`.

A correlação `ui-mvp-final-1784235042529` apareceu nos três runtimes: 25 registros no OS, 19 no Execution e 71 no Billing. O mesmo evento `ordemDeServicoCriada`, identificado por `e82341fb-5635-49b2-92ed-4278b6c2871f`, foi registrado como `PENDING` na Outbox do OS e `CONSUMED` no Billing com a correlação preservada. A sincronização inicial da credencial OS → Auth levou cerca de 90 segundos nesta execução; o event source mapping permaneceu habilitado e a credencial foi materializada, mas a latência deve ser acompanhada operacionalmente.

Com essa jornada, `[UI-MVP-REM-001]` está concluída. Nenhuma credencial, CPF, JWT, token, payload financeiro ou dado pessoal foi incluído nas evidências; somente IDs técnicos necessários à correlação foram registrados.
