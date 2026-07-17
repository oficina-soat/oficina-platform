# Evidência da administração de usuários no lab

Data da homologação: 2026-07-17  
Ambiente: `lab`, região `us-east-1`  
Correlação: `users-admin-20260717T181657Z`

## Escopo

A rodada validou o percurso administrativo de um único usuário sentinela entre a UI, o serviço de OS e o Auth. CPF, senha, token de ativação e JWT não foram registrados nesta evidência.

O ambiente utilizou o `oficina-os-service` `1.9.1`, o Auth `1.3.1` e as rotas administrativas publicadas pelo [deploy do Auth](https://github.com/oficina-soat/oficina-auth-lambda/actions/runs/29601025343) e pelo [deploy da infraestrutura](https://github.com/oficina-soat/oficina-infra/actions/runs/29602984602).

## Resultado

| Verificação | Resultado |
| --- | --- |
| Criação sem credencial no payload operacional | HTTP `201` |
| Filtro remoto por nome | usuário localizado |
| Filtro remoto por documento | usuário localizado |
| Filtro remoto por estado e papel | usuário localizado |
| Estado inicial da credencial | `NAO_ATIVADA` |
| Ativação da credencial | HTTP `204` |
| Login após ativação | HTTP `200` |
| Login após bloqueio | HTTP `401` |
| Login após reativação | HTTP `200` |
| Login após inativação | HTTP `401` |

As ações retornadas pelo backend também acompanharam cada estado:

- usuário ativo: `ATUALIZAR_DADOS`, `BLOQUEAR` e `INATIVAR`;
- usuário bloqueado: `ATUALIZAR_DADOS`, `REATIVAR` e `INATIVAR`;
- usuário reativado: `ATUALIZAR_DADOS`, `BLOQUEAR` e `INATIVAR`.

## Conclusão

O fluxo foi aprovado ponta a ponta. O OS permaneceu como autoridade do cadastro e das ações operacionais, enquanto o Auth permaneceu como autoridade da credencial. A UI pode apresentar somente as ações canônicas devolvidas por cada backend, sem reconstruir regras de negócio no navegador. O sentinela terminou inativo.
