# usuarioExcluido

## Descrição

Indica que um usuário operacional foi excluído logicamente no `oficina-os-service`.

## Emissor

```text
oficina-os-service
```

## Tópico canônico

```text
oficina.os.usuario-excluido
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

O payload contém o snapshot operacional completo após a exclusão lógica e fixa `status=INATIVO`. O consumidor preserva a credencial para auditoria e eventual reativação, mas deve impedir autenticação enquanto o usuário permanecer inativo.

Repetir `DELETE` sobre um usuário já inativo não cria um novo fato de domínio e, portanto, não deve publicar outro evento. O processamento do evento deve ser idempotente por `eventId`, e eventos anteriores à exclusão não podem reativar a projeção caso sejam entregues depois por outra fila.

## Contratos relacionados

- [Schema JSON do evento](schemas/usuarioExcluido.schema.json)
- [Contrato de APIs REST](../Contrato%20de%20APIs%20REST.md)
- [Contrato de Tópicos de Mensageria](../Contrato%20de%20Tópicos%20de%20Mensageria.md)
- [OpenAPI do oficina-os-service](../openapi/oficina-os-service.yaml)
- [OpenAPI do oficina-auth-lambda](../openapi/oficina-auth-lambda.yaml)
