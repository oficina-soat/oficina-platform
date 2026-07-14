# Evidência da integração remota de usuários da autenticação

Data da homologação: 2026-07-14  
Ambiente: `lab`, região `us-east-1`

## Publicação

- `oficina-os-service` `1.2.4` operando no EKS e registrando os eventos de usuário na Outbox.
- `oficina-auth-lambda` `1.1.4` publicado pelo [run 29346396839](https://github.com/oficina-soat/oficina-auth-lambda/actions/runs/29346396839).
- `auth-lambda`, `auth-sync-lambda` e `notificacao-lambda` foram atualizadas com sucesso, e os pacotes imutáveis `1.1.4` foram anexados à GitHub Release.
- A função `oficina-auth-sync-lambda-lab` ficou ativa com os três event source mappings habilitados para inclusão, atualização e exclusão de usuários.

## Cenário homologado

O usuário sintético `400f359d-def8-448c-bf77-5af8d34f0172`, CPF de teste `16899535009`, foi criado pelo CRUD do serviço de OS sem senha no payload ou no evento. A projeção assíncrona criou o cadastro correspondente no PostgreSQL da autenticação.

Foram comprovados:

1. solicitação administrativa de token de ativação;
2. ativação com senha nova e rejeição HTTP `400` ao reutilizar o mesmo token;
3. autenticação bem-sucedida com emissão de JWT;
4. bloqueio operacional, seguido de autenticação rejeitada com HTTP `401`;
5. reativação com mudança de nome e papéis, preservando a senha e voltando a emitir JWT;
6. inativação final, seguida de autenticação rejeitada com HTTP `401`.

O evento de reativação foi registrado na Outbox às `15:55:28Z`, publicado às `15:57:11Z` e consumido pela Lambda na mesma hora. Isso explica a ultrapassagem da janela inicial de polling de 60 segundos e comprova entrega eventual, sem perda do evento. A inativação final foi observada na 11ª tentativa do polling.

## Idempotência, ordenação e falha controlada

- A projeção grava `eventId` em `auth_consumed_event`, ignora eventos já consumidos e compara `atualizadoEm` com `last_event_at` para impedir regressão por snapshots fora de ordem.
- Inclusão, bloqueio, reativação e inativação não acrescentaram mensagens às DLQs durante o caminho homologado.
- Duas mensagens diagnósticas produzidas antes das correções permaneceram na DLQ de inclusão como evidência da falha controlada: cada uma foi recebida seis vezes antes do redrive. Elas não pertencem ao caminho feliz e não foram apagadas automaticamente para preservar a evidência.

## Correções encontradas pela homologação

- [PR 49](https://github.com/oficina-soat/oficina-auth-lambda/pull/49): datasource da Lambda de sincronização, decoder compatível com runtime nativo e logging da causa completa.
- [PR 50](https://github.com/oficina-soat/oficina-auth-lambda/pull/50): serialização do bootstrap compartilhado, eliminando corrida entre Jobs e Secrets Kubernetes temporários.
- [PR 51](https://github.com/oficina-soat/oficina-auth-lambda/pull/51): alinhamento do issuer usado para emitir e validar JWT e proteção do filtro de correlação em respostas antecipadas.
- [PR 52](https://github.com/oficina-soat/oficina-auth-lambda/pull/52): resposta de ativação tipada para serialização estática no executável nativo.

## Resultado

A integração remota foi aprovada: o serviço de OS permanece dono do cadastro operacional, o store de autenticação mantém uma projeção assíncrona sem transportar senha, e somente usuários ativos com credencial ativada recebem JWT.
