# Auditoria da composição técnica da Ordem de Serviço

## Objetivo

Definir o menor incremento que permita selecionar serviços e peças na interface operacional sem mover regras de negócio para o Angular nem alterar o ownership estabelecido na [matriz dos microsserviços](../architecture/service-ownership.md).

## Estado encontrado

- O `oficina-execution-service` já é dono dos catálogos de serviços e peças e oferece consultas paginadas por nome; peças também aceitam código.
- O [contrato de estados](../../contracts/Contrato%20de%20Estados%20da%20Ordem%20de%20Serviço.md) permite incluir itens somente em `EM_DIAGNOSTICO`.
- O `oficina-os-service` é dono dos snapshots de itens, mas sua implementação canônica persiste apenas os dados básicos da OS e não expõe comandos de inclusão.
- O domínio preservado do `oficina-app` possui casos de uso separados para incluir peça e serviço. Eles consultam o catálogo e adicionam o snapshot à OS; não há operação de alteração ou remoção.
- Os eventos `pecaIncluidaNaOrdemDeServico` e `servicoIncluidoNaOrdemDeServico`, seus schemas, tópicos e consumidores em Billing e Execution já existem.
- O Billing projeta os snapshots recebidos e gera o orçamento após `diagnosticoFinalizado`. O Execution valida referências de catálogo e controla o estoque em seu próprio fluxo.

## Decisão do incremento

O primeiro incremento mantém a arquitetura e os eventos existentes:

1. A UI consulta no Execution apenas itens ativos e envia ao OS Service o identificador de catálogo e a quantidade.
2. O OS Service consulta o item canônico no Execution, rejeita item inexistente ou inativo e cria o snapshot com nome e valor atuais. A UI não envia preço nem calcula total.
3. O OS Service aceita inclusão somente em `EM_DIAGNOSTICO`, exige `Idempotency-Key`, persiste o snapshot e o evento correspondente na mesma transação e devolve a composição atualizada.
4. A leitura da OS inclui peças, serviços e `acoesPermitidas`. `INCLUIR_PECA` e `INCLUIR_SERVICO` aparecem somente quando o backend aceitar os comandos.
5. Billing e Execution continuam consumindo os eventos de inclusão versão 1. Estoque, reserva, consumo e compensação permanecem sob autoridade do Execution e não são inferidos na UI.

Alteração e remoção de itens não pertencem a este incremento. O domínio de referência não oferece essas operações e implementá-las exigiria definir eventos, atualização das projeções financeiras e comportamento após orçamento recusado. Essa evolução deve começar por discovery e contrato próprios se for priorizada.

## Contratos resultantes

- `GET /api/v1/servicos?ativo=true` e `GET /api/v1/pecas?ativo=true` no Execution.
- `POST /api/v1/ordens-servico/{ordemServicoId}/servicos` no OS Service.
- `POST /api/v1/ordens-servico/{ordemServicoId}/pecas` no OS Service.
- composição em `GET /api/v1/ordens-servico/{ordemServicoId}`.

Os detalhes executáveis estão nas OpenAPI do [Execution](../../contracts/openapi/oficina-execution-service.yaml) e do [OS Service](../../contracts/openapi/oficina-os-service.yaml). O modelo de erro e a semântica de reuso da chave seguem, respectivamente, o [contrato de erros](../../contracts/error-model.md) e o [contrato de idempotência](../../contracts/idempotency.md).

## Critérios para implementação

- IDs de catálogo usam UUID e quantidade deve ser positiva.
- Preço, nome, atividade do catálogo e estado válido são revalidados no backend.
- Falha ao consultar o catálogo não pode produzir snapshot ou evento parcial.
- Persistência do snapshot e Outbox é atômica no OS Service.
- Retry com a mesma chave e payload devolve o mesmo resultado; payload diferente gera conflito.
- Nenhum serviço acessa o banco de outro serviço.
- `X-Correlation-Id` é propagado na consulta síncrona e nos eventos.
