# usuarioAtualizado

## Descrição

Indica que nome, CPF, status ou papéis de um usuário operacional foram atualizados no `oficina-os-service`.

## Emissor

```text
oficina-os-service
```

## Tópico canônico

```text
oficina.os.usuario-atualizado
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

O payload contém o snapshot operacional completo após a atualização, sem qualquer credencial. O `oficina-auth-sync-lambda` deve substituir a projeção de CPF, nome, status e papéis pelo conteúdo recebido e preservar a credencial já ativada.

Os estados `INATIVO` e `BLOQUEADO` impedem autenticação assim que o evento for aplicado. O processamento deve ser idempotente por `eventId`; um snapshot com `occurredAt` igual ou anterior ao último evento aplicado para o mesmo `aggregateId` não pode sobrescrever a projeção.

## Contratos relacionados

- [Schema JSON do evento](schemas/usuarioAtualizado.schema.json)
- [Contrato de APIs REST](../Contrato%20de%20APIs%20REST.md)
- [Contrato de Tópicos de Mensageria](../Contrato%20de%20Tópicos%20de%20Mensageria.md)
- [OpenAPI do oficina-os-service](../openapi/oficina-os-service.yaml)
- [OpenAPI do oficina-auth-lambda](../openapi/oficina-auth-lambda.yaml)
