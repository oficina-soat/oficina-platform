# usuarioAdicionado

## Descrição

Indica que um usuário operacional foi criado no `oficina-os-service` e deve ser projetado no store próprio de autenticação.

## Emissor

```text
oficina-os-service
```

## Tópico canônico

```text
oficina.os.usuario-adicionado
```

## Consumidor

```text
oficina-auth-sync-lambda
```

## Versão

```text
1
```

## Payload

O payload contém o snapshot operacional completo, sem senha, hash, token ou outra credencial:

- `usuarioId` e `pessoaId` canônicos do `oficina-os-service`;
- `nome` e CPF em `documento`;
- `status` entre `ATIVO`, `INATIVO` e `BLOQUEADO`;
- um ou mais `papeis` entre `administrativo`, `mecanico` e `recepcionista`;
- `atualizadoEm` em ISO-8601.

O consumidor deve processar o evento de forma idempotente por `eventId` e não aplicar o snapshot quando já tiver processado, para o mesmo `aggregateId`, um evento com `occurredAt` igual ou posterior. Um usuário criado como `ATIVO` ainda não pode autenticar enquanto não concluir a ativação de credencial diretamente no `oficina-auth-lambda`.

## Contratos relacionados

- [Schema JSON do evento](schemas/usuarioAdicionado.schema.json)
- [Contrato de APIs REST](../Contrato%20de%20APIs%20REST.md)
- [Contrato de Tópicos de Mensageria](../Contrato%20de%20Tópicos%20de%20Mensageria.md)
- [OpenAPI do oficina-os-service](../openapi/oficina-os-service.yaml)
- [OpenAPI do oficina-auth-lambda](../openapi/oficina-auth-lambda.yaml)
