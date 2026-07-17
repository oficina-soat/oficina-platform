# Contrato do dashboard operacional

## Objetivo

Contratar snapshots de leitura pequenos e acionáveis para o [dashboard operacional da UI](../docs/frontend/dashboard-operational-discovery.md), preservando cada serviço como autoridade dos próprios dados. O Angular apresenta os agregados recebidos e não conta páginas, combina estados, ordena prioridades nem reconstrói pendências.

As rotas deste documento e das especificações OpenAPI são contrato alvo. Elas passam a integrar o runtime e a lista de rotas públicas somente após `[UI-FUT-DASHBOARD-BACKEND-001]`.

## Decisões

- A primeira versão usa consultas por domínio, sem criar uma API de leitura dedicada.
- Cada resposta é um snapshot atual. `dataAsOf` define seu limite temporal; intervalos históricos e séries ficam fora desta versão.
- `generatedAt` informa quando a resposta foi produzida.
- `refreshAfterSeconds` é opcional. Quando ausente, o cliente oferece apenas atualização manual.
- Cada fila possui no máximo cinco itens, já selecionados e ordenados pelo backend.
- Falhas são independentes: a indisponibilidade de um serviço não invalida blocos obtidos de outras autoridades.
- Os endpoints são somente leitura, não recebem chave de idempotência e continuam propagando `Authorization` e `X-Correlation-Id`.

## Rotas e autoridades

| Autoridade | Rota | Papéis | Conteúdo |
| --- | --- | --- | --- |
| OS Service | `GET /api/v1/dashboard/ordens-servico` | `administrativo`, `mecanico`, `recepcionista` | contagens por estado e OS que exigem atenção |
| OS Service | `GET /api/v1/dashboard/usuarios` | `administrativo` | contagens por estado operacional e usuários que exigem atenção |
| Execution Service | `GET /api/v1/dashboard/execucao` | `administrativo`, `mecanico` | carga por estado, fila canônica e alertas canônicos de estoque |
| Billing Service | `GET /api/v1/dashboard/faturamento` | `administrativo`, `recepcionista` | contagens e atenções de orçamento e pagamento |
| Auth Lambda | `GET /auth/dashboard/credenciais` | `administrativo` | contagens e atenções sanitizadas de credenciais |

Os caminhos são distintos porque os três microsserviços compartilham `/api/v1` no mesmo API Gateway. Uma rota genérica como `/api/v1/dashboard` não identifica a integração responsável.

## Metadados comuns

Todas as respostas incluem:

```json
{
  "generatedAt": "2026-07-17T18:30:05Z",
  "dataAsOf": "2026-07-17T18:30:00Z",
  "refreshAfterSeconds": 30
}
```

`dataAsOf` não implica consistência transacional entre serviços. A UI apresenta a referência temporal em cada bloco e sinaliza dado defasado sem descartar silenciosamente a última resposta válida.

## Ordens de serviço

A resposta contém `contagensPorEstado` para os valores canônicos de `EstadoOrdemServico` e `atencoes` limitada a cinco OS. Cada atenção informa `ordemServicoId`, `estado`, `descricaoProblema`, `entrouNoEstadoEm` e `acoesPermitidas`.

O backend seleciona e ordena as atenções. A UI não calcula tempo de espera, urgência nem próximo estado.

## Usuários e credenciais

O OS retorna apenas dados operacionais em `/dashboard/usuarios`: contagens por `StatusUsuario` e até cinco cadastros com identificador, nome, estado, atualização e ações permitidas.

O Auth retorna separadamente contagens por `StatusCredencial` e até cinco credenciais que exigem atenção. O contrato admite somente identificador do usuário, estado, expiração aplicável, atualização e ações permitidas. CPF, senha, hash, token e JWT são proibidos.

A UI pode apresentar os dois blocos lado a lado, mas não realiza join obrigatório nem transforma a falha de uma autoridade em falha da outra.

## Execução e estoque

O Execution Service retorna contagens por `StatusExecucao`, `totalFila`, até cinco `proximasExecucoes` na ordem canônica e até cinco `estoqueAtencoes`.

Cada atenção de estoque informa saldo e `limiteReposicao` já aplicado pelo backend. Enquanto o serviço não possuir uma política canônica para esse limite, a lista deve ser vazia; o cliente não define um valor próprio.

## Faturamento

O Billing Service retorna contagens separadas por `StatusOrcamento` e `StatusPagamento`. Cada item de atenção discrimina `ORCAMENTO` ou `PAGAMENTO`, preserva os estados e ações do recurso correspondente e inclui OS, referência, valor e atualização.

O backend seleciona pendências e valores. O cliente não soma resultados paginados, não concilia orçamento e pagamento e não interpreta o estado da OS como situação financeira.

## Erros e indisponibilidade parcial

Cada rota usa o [modelo canônico de erros REST](error-model.md):

- `401` para autenticação ausente ou inválida;
- `403` para papel insuficiente;
- `500` para falha não tratada;
- `503` quando o serviço não consegue produzir seu snapshot.

Uma resposta `200` representa um bloco completo segundo a autoridade consultada. A composição parcial acontece na UI entre respostas independentes; o backend não devolve sucesso com contagens inventadas ou silenciosamente incompletas.

## Compatibilidade e evolução

Novos campos opcionais e novos itens de atenção podem ser acrescentados de forma compatível. Mudanças de significado, remoção de estados, alteração de autoridade ou introdução de snapshot transversal exigem revisão do contrato e, para uma API de leitura dedicada, decisão arquitetural explícita.

As estruturas executáveis completas permanecem nas especificações:

- [OpenAPI do OS Service](openapi/oficina-os-service.yaml);
- [OpenAPI do Execution Service](openapi/oficina-execution-service.yaml);
- [OpenAPI do Billing Service](openapi/oficina-billing-service.yaml);
- [OpenAPI do Auth Lambda](openapi/oficina-auth-lambda.yaml).
