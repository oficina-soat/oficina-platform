# Discovery do dashboard operacional

Data: 2026-07-17  
Tarefa: `[UI-FUT-DASHBOARD-DISCOVERY-001]`

## Objetivo

Definir uma visão inicial, simples e acionável da operação da oficina. O dashboard deve ajudar cada perfil a decidir onde atuar, sem transformar o Angular em fonte de métricas, regras de prioridade, interpretação de estados ou agregações entre serviços.

Esta visão é diferente dos [dashboards técnicos do New Relic](../observability/new-relic-dashboards.md): a UI acompanha trabalho de negócio; o New Relic continua responsável por disponibilidade, latência, erros, logs, traces, infraestrutura e alertas técnicos.

## Estado atual

A rota `/session` consulta diretamente as primeiras páginas de clientes e ordens de serviço. Ela apresenta os totais informados pelas paginações e três ordens sob o título “Ordens recentes”. Esse MVP oferece atalhos úteis, mas possui limitações:

- a ordem da listagem não está contratada como recência;
- total de clientes não indica uma decisão operacional;
- não existem contagens canônicas por estado;
- execução, faturamento e estoque não participam da visão;
- cada novo indicador baseado em listagens exigiria múltiplas consultas e agregação no navegador;
- todos os papéis recebem a mesma visão, ainda que tenham responsabilidades diferentes.

Portanto, a implementação existente deve ser substituída gradualmente por consultas de leitura próprias. Ela não deve ser ampliada com novos cálculos no frontend.

## Personas e decisões

| Persona | Decisão apoiada pelo dashboard | Destino acionável |
| --- | --- | --- |
| Recepcionista | Qual OS precisa de atendimento, autorização, entrega ou regularização de pagamento? | lista ou detalhe da OS; faturamento |
| Mecânico | Qual execução deve ser iniciada ou continuada e quais itens de estoque exigem atenção? | fila, execução e estoque |
| Administrativo | Onde está o acúmulo operacional e quais usuários, pagamentos ou estoques precisam de intervenção? | OS, faturamento, estoque e usuários |

Um usuário com mais de um papel recebe a união dos blocos autorizados pelo backend. A ocultação visual segue os papéis da sessão, mas cada consulta continua revalidando autorização no serviço responsável.

## Escopo funcional inicial

### Atendimento e ordens de serviço

- quantidade atual por estado canônico da OS;
- fila de atenção com as OS mais antigas em `RECEBIDA`, `AGUARDANDO_APROVACAO` e `FINALIZADA`;
- data da entrada no estado atual e ação canônica disponível, quando aplicável;
- link para a lista já filtrada ou para o detalhe.

`FINALIZADA` significa apenas o estado canônico. O texto de apresentação pode indicar “pronta para entrega”, mas a API não deve criar um estado paralelo. A prioridade e a ordenação da fila são devolvidas pelo backend; a UI não calcula urgência por tempo.

### Execução

- total da fila de execução;
- contagens por `CRIADA`, `EM_DIAGNOSTICO`, `DIAGNOSTICO_CONCLUIDO`, `EM_REPARO` e `REPARO_CONCLUIDO`;
- próximos itens da fila na ordem canônica já calculada pelo Execution Service;
- link para a fila ou execução correspondente.

Execuções canceladas podem aparecer em filtros históricos, mas não integram a carga de trabalho ativa.

### Faturamento

- orçamentos aguardando decisão do cliente;
- pagamentos criados aguardando desfecho;
- pagamentos recusados que ainda exigem tratamento operacional;
- itens de atenção com OS, valor, estado, atualização e ações canônicas;
- link para o faturamento da OS.

Valores monetários são agregados somente se o Billing Service os devolver prontos. O Angular não soma páginas, não concilia orçamento com pagamento e não infere pendência financeira pelo estado da OS.

### Estoque

- itens sinalizados pelo Execution Service como necessitando reposição;
- saldo atual, limite aplicado pelo backend e instante da leitura;
- reservas que exijam tratamento, caso o backend passe a expor esse conceito;
- link para o item ou para a tela de estoque.

O conceito de estoque baixo e seu limite pertencem ao backend. Enquanto não houver contrato canônico, o dashboard não exibe esse indicador.

### Administração de usuários

- credenciais ainda não ativadas ou com ativação pendente;
- usuários bloqueados;
- itens com ações canônicas devolvidas por OS e Auth;
- link para o detalhe administrativo.

Esse bloco é exclusivo do papel `administrativo` e não transporta CPF, senha, hash, token ou JWT.

## Modelo de apresentação

A primeira versão deve usar componentes simples:

1. cards de contagem que funcionem como links para a lista correspondente;
2. uma fila “Precisa de atenção”, com no máximo cinco itens por domínio;
3. indicação do horário de referência de cada bloco;
4. atualização manual e estados independentes de carregamento, vazio, indisponibilidade e dado defasado.

Gráficos e séries históricas ficam fora do primeiro incremento. Um número atual e uma fila acionável oferecem mais valor operacional com menor custo e menor risco de interpretação indevida.

## Atualização e consistência

- cada resposta informa `generatedAt` e, quando houver projeção, `dataAsOf`;
- a UI carrega os blocos em paralelo e preserva os blocos saudáveis quando uma autoridade falhar;
- o backend pode informar `refreshAfterSeconds`; na ausência desse campo, existe apenas atualização manual;
- atualização automática ocorre somente com a página visível e nunca executa comandos;
- uma resposta antiga continua visível com indicação de defasagem, sem ser misturada silenciosamente a dados mais novos;
- todas as consultas propagam `Authorization` e `X-Correlation-Id`.

A consistência é explícita por bloco. Não é necessário produzir um snapshot transacional entre OS, Billing, Execution e Auth para a visão inicial.

## Limites e segurança

- os cards retornam contagens já agregadas, nunca todas as entidades para contagem local;
- cada fila retorna no máximo cinco itens e um link/filtro para continuidade;
- paginação, ordenação, prioridade, agrupamento e interpretação de estados pertencem ao backend;
- nenhum bloco expõe CPF completo, credenciais, tokens, dados do provedor de pagamento ou detalhes técnicos de observabilidade;
- o dashboard não substitui telas de detalhe nem permite comandos destrutivos diretamente no primeiro incremento;
- dados históricos, metas, produtividade individual, SLA e previsão de receita ficam fora do escopo até existirem regras e contratos explícitos;
- não são feitos joins no navegador entre respostas de autoridades distintas.

## Fronteiras de contrato

A etapa de contrato deve escolher entre consultas agregadas em cada backend e uma API de leitura dedicada. Para o primeiro incremento, recomenda-se manter a autoridade distribuída e criar consultas pequenas por domínio, porque isso evita um novo componente operacional e preserva os limites atuais:

- OS Service: resumo e fila de atenção das ordens;
- Execution Service: resumo da execução e alertas canônicos de estoque;
- Billing Service: resumo e itens de atenção financeira;
- OS Service e Auth: resumos administrativos separados, compostos apenas para apresentação.

Uma API de leitura dedicada só se justifica se a necessidade futura exigir snapshot transversal, histórico consolidado ou escala de consultas que não possa ser atendida pelos serviços donos. Essa decisão, se necessária, exige ADR antes da implementação.

## Critérios de aceite para as próximas etapas

Os formatos executáveis foram definidos posteriormente no [contrato do dashboard operacional](../../contracts/dashboard-operational.md).

- os contratos expõem contagens, itens acionáveis, timestamps e links/filtros sem exigir cálculo de domínio no Angular;
- cada indicador possui autoridade e papéis permitidos explícitos;
- indisponibilidade parcial não apaga os demais blocos;
- os resultados vazio, parcial, defasado e não autorizado são distinguíveis;
- a UI mostra somente blocos e ações permitidos pela sessão e confirmados pelo backend;
- testes garantem que nenhuma listagem completa seja usada para reconstruir agregados.

## Fora do escopo

- telemetria técnica já coberta pelo New Relic;
- BI, séries históricas, metas e comparações de desempenho;
- cálculo de SLA, prioridade, estoque mínimo, receita ou produtividade no frontend;
- comandos operacionais diretamente nos cards;
- agregação transversal persistida sem decisão arquitetural específica.
