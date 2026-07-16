# Auditoria da administração de usuários

Data: 2026-07-16  
Tarefa: `[UI-FUT-USERS-CONTRACT-001]`

## Objetivo

Definir os contratos necessários para administrar usuários operacionais sem colocar autorização, transições de estado ou regras de credencial no Angular. O `oficina-os-service` continua responsável pelo cadastro operacional e o `oficina-auth-lambda` pela credencial.

## Estado auditado

O contrato do OS já oferece criação, paginação, detalhe, atualização integral e inativação lógica. Os estados são `ATIVO`, `INATIVO` e `BLOQUEADO`, e os papéis são `administrativo`, `mecanico` e `recepcionista`. Todas as operações exigem `administrativo` no backend.

O Auth já oferece geração administrativa do token de ativação e conclusão pública da ativação. A UI possui essa tela, mas exige que o administrador copie manualmente o UUID do usuário e não consegue consultar o estado da credencial.

As divergências encontradas antes da implementação eram:

- a OpenAPI declara filtros `nome`, `documento` e `email`, mas o resource aceita apenas `page` e `size`;
- o modelo operacional não possui e-mail, portanto o filtro `email` não tem fonte de dados;
- a resposta não informa ações permitidas, obrigando um cliente a inferir comandos pelo estado;
- bloqueio e reativação dependem hoje de `PUT` com a representação completa, apesar de serem comandos operacionais distintos;
- a listagem não filtra por `status` ou `papel`;
- nenhum contrato informa se a credencial está ausente, com ativação pendente ou ativa.

## Contrato alvo

### Cadastro operacional — OS Service

`GET /usuarios` deve aceitar paginação e os filtros remotos:

- `nome`: trecho sem distinção de caixa;
- `documento`: CPF exato;
- `status`: valor canônico;
- `papel`: papel canônico.

O filtro `email` deve ser removido enquanto e-mail não fizer parte do modelo operacional. Os filtros são aplicados no backend antes da paginação.

`Usuario` deve incluir `acoesPermitidas`, calculado pelo backend:

- `BLOQUEAR`;
- `REATIVAR`;
- `INATIVAR`;
- `ATUALIZAR_DADOS`.

Devem existir comandos idempotentes explícitos:

- `POST /usuarios/{usuarioId}/bloqueio`;
- `POST /usuarios/{usuarioId}/reativacao`;
- `DELETE /usuarios/{usuarioId}` para inativação, preservado por compatibilidade.

O `PUT` permanece responsável apenas por nome, documento e papéis. O cliente não escolhe diretamente o próximo status. Cada comando revalida autorização e estado no OS Service e publica o snapshot atualizado pela Outbox.

### Credencial — Auth Lambda

`GET /auth/usuarios/{usuarioId}/credencial` deve retornar somente metadados administrativos:

- `status`: `NAO_ATIVADA`, `ATIVACAO_PENDENTE` ou `ATIVA`;
- `expiresAt`, apenas quando houver ativação pendente;
- `acoesPermitidas`, inicialmente `SOLICITAR_ATIVACAO` quando aplicável.

Senha, hash e token nunca integram consultas. O comando existente `POST /auth/usuarios/{usuarioId}/ativacao` permanece como única forma de gerar o segredo de uso único.

### Composição na UI

A feature administrativa consulta o OS para lista e detalhe. O estado da credencial é consultado no Auth apenas ao abrir o detalhe, tolerando indisponibilidade parcial e a consistência eventual da projeção. A UI pode combinar os dois modelos para apresentação, mas renderiza comandos exclusivamente a partir de `acoesPermitidas` de cada autoridade.

CPF completo fica restrito às telas administrativas e nunca entra em telemetria. Tokens de ativação aparecem uma única vez, não são persistidos no navegador e mantêm o tratamento já implementado.

## Sequência executável

1. Evoluir OpenAPI, entidades de resposta e testes de contrato do OS.
2. Implementar filtros antes da paginação e comandos explícitos de bloqueio e reativação.
3. Evoluir OpenAPI, consulta sanitizada e testes do Auth.
4. Sincronizar os contratos na UI e criar a feature `administration/users` isolada de `auth`.
5. Implementar lista, detalhe, edição e confirmações acessíveis usando apenas ações canônicas.
6. Cobrir autorização visual, indisponibilidade parcial, consistência eventual, idempotência e E2E.
7. Homologar criação, ativação, bloqueio, reativação e inativação no `lab` com dados sentinela.

## Observação operacional

Na homologação do MVP, a projeção de um novo usuário no Auth levou cerca de 90 segundos. A inspeção comprovou que o atraso ocorreu antes do Auth: o OS registrou os eventos imediatamente, mas levou entre 71 e 95 segundos para publicá-los. A correção separou publisher e consumidores em executores independentes, com teste que garante que falha ou bloqueio de um fluxo não impede o outro.

A DLQ de `usuarioAdicionado` continha duas mensagens históricas de 14/07, ambas com envelope e payload estruturalmente completos e sem `correlationId`, pois antecedem o contrato atual. A primeira coincide com falhas de inicialização da versão antiga do Auth Sync por datasource inativo. A segunda foi rejeitada pela versão `1.1.1` com `IllegalArgumentException`, mas o log antigo não preservou causa suficiente para detalhamento. Nenhuma nova mensagem entrou na DLQ durante a homologação atual. Em 16/07, uma tarefa controlada de redrive moveu as duas mensagens para a fila de origem a uma mensagem por segundo. A tarefa terminou como `COMPLETED`, origem e DLQ ficaram vazias e as duas invocações da Auth Sync terminaram sem erro.

## Fora do escopo

- recuperação ou troca de senha;
- armazenamento de CPF, senha ou token no frontend;
- decisão de ações a partir do estado no Angular;
- cadastro de e-mail sem evolução explícita do domínio;
- exclusão física de Pessoa ou Usuário;
- agregação entre bancos ou serviços no navegador.
