# ordemDeServicoCriada

## Descrição

Indica que uma nova Ordem de Serviço foi aberta.

## Emissor

```text
oficina-os-service
```

## Tópico canônico

```text
oficina.os.ordem-de-servico-criada
```

## Consumidores potenciais

```text
oficina-billing-service
oficina-execution-service
```

## Contato para aprovação

Novos eventos incluem `clienteEmail` como dado opcional e aditivo da versão 1. O Billing usa esse contato exclusivamente para projetar o destinatário da solicitação de aprovação do orçamento. O campo não pode ser promovido a label de métrica, atributo de trace ou campo de log.
