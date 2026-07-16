# Evidência do banco exclusivo de autenticação no lab

## Escopo

Em 16 de julho de 2026, a tarefa `D-AUTH-DB-REM-001` homologou a troca das
Lambdas de autenticação para o database exclusivo `oficina_auth`, preservando o
database legado `app`. Nenhum token, senha ou valor de secret foi registrado.

## Configuração implantada

- o workflow [`Deploy Lambda Lab`](https://github.com/oficina-soat/oficina-auth-lambda/actions/runs/29494266528)
  publicou a versão `1.2.0` com sucesso;
- `oficina-auth-lambda-lab` e `oficina-auth-sync-lambda-lab` estavam `Active`,
  com atualização `Successful`;
- as duas funções usavam o endpoint RDS com database `oficina_auth` e username
  `oficina_auth_user`;
- o secret canônico `oficina/lab/database/oficina-auth-lambda` existia como um
  JSON com as chaves `engine`, `host`, `port`, `database`, `dbname`, `username`,
  `password` e `sslmode`;
- os três event source mappings de `usuarioAdicionado`, `usuarioAtualizado` e
  `usuarioExcluido` estavam habilitados para a `oficina-auth-sync-lambda-lab`.

## Homologação funcional

| Cenário | Resultado |
|---|---|
| Login administrativo migrado | `200`, com JWT emitido pelo issuer canônico |
| Senha administrativa inválida | `401`, com motivo canônico `Senha inválida` |
| Criação de usuário sentinela no OS | `201`, sem senha ou token no payload operacional |
| Projeção assíncrona no banco de autenticação | usuário localizado pela rota de ativação |
| Ativação da credencial | `204` |
| Login após ativação | `200` |
| Reprocessamento do mesmo `eventId` | resposta sem falhas parciais, comprovando deduplicação |
| Inativação operacional | `204`; repetição também retornou `204` |
| Propagação da inativação | login passou a retornar `401` |

Os dois usuários criados durante esta execução foram inativados logicamente ao
final. A validação respeitou a consistência eventual e não registrou dados
pessoais ou financeiros reais.

## Rollback

O ensaio de rollback foi não disruptivo: a configuração ativa não foi revertida
depois da homologação bem-sucedida. Foram confirmados os artefatos imutáveis da
[release `v1.1.4`](https://github.com/oficina-soat/oficina-auth-lambda/releases/tag/v1.1.4)
e os seis secrets legados separados de conexão com `app`. O procedimento correto
é executar a revisão de deploy anterior com `DB_NAME=app`; a revisão atual espera
o novo secret JSON e não deve receber o prefixo legado como se fosse um secret
único. A origem não foi removida, portanto o retorno não depende de restore.

O procedimento operacional completo está em [Migração para o banco exclusivo de
autenticação](https://github.com/oficina-soat/oficina-auth-lambda/blob/develop/docs/auth-database-migration.md).
