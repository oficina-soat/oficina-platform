# Evidência das Métricas do Mercado Pago no Lab

## Objetivo

Registrar a conclusão de `[D-OBS-MP-COLLECT-IMPL-001]`, comprovando a exposição, a coleta e a ingestão das seis famílias de métricas do provedor financeiro definidas no [Padrão de Observabilidade Distribuída](observability.md).

## Ambiente validado

| Componente | Estado validado em 2026-07-15 |
|---|---|
| `oficina-billing-service` | Deployment `1/1`, imagem `oficina-billing-service:1.1.5` |
| New Relic OpenTelemetry Collector | Deployment, DaemonSet e `kube-state-metrics` disponíveis, sem erro de scrape dos microsserviços |
| Configuração do collector | `cumulativetodelta.initial_value=keep` aplicada pelo run `29408706593` do `oficina-infra` |
| Integração financeira | `payment_provider_enabled=1`, com `provider=mercado-pago`, `service=oficina-billing-service` e `environment=lab` |

O endpoint `/q/metrics`, consultado de dentro do cluster por um pod temporário removido automaticamente, expôs as seis famílias esperadas:

- `payment_provider_enabled`;
- `payment_provider_requests_count_total`;
- `payment_provider_request_duration_seconds`;
- `payment_provider_amount_BRL`;
- `payment_provider_failures_count_total`;
- `payment_provider_unavailable_count_total`.

## Cenários funcionais

Uma cobrança PIX sandbox real foi executada pelo endpoint público `POST /api/v1/pagamentos` e retornou HTTP `201`:

| Campo | Valor |
|---|---|
| `pagamentoId` | `af574325-5cd8-469f-b1d3-194570f2809e` |
| `transacaoExternaId` | `1348688115` |
| Valor | `220.00 BRL` |
| Status local | `CRIADO` |
| Provedor | `mercado-pago` |
| `correlationId` | `d-obs-mp-success-20260715T110159Z-pagamento` |

Também foram executadas duas falhas controladas:

1. uma cobrança de valor zero recebeu HTTP `400` do sandbox e foi convertida pelo Billing em HTTP `502/DEPENDENCY_FAILURE`, materializando `reason=provider_http_error`;
2. a URL do provedor foi temporariamente sobrescrita no Deployment para uma porta local fechada, produzindo HTTP `502/DEPENDENCY_FAILURE` com `reason=communication` e materializando a família de indisponibilidade.

A sobrescrita temporária foi removida ao final. O rollout restaurado concluiu com `1/1` réplica, imagem `1.1.5` e nenhuma variável explícita `OFICINA_MERCADO_PAGO_API_URL`, preservando a configuração canônica do Secret.

## Ingestão no New Relic

Consultas NerdGraph na conta `8254132` retornaram HTTP `200`, sem erros, e confirmaram no inventário `Metric` todas as famílias. Os resultados representativos foram:

| Família | Labels e resultado observados |
|---|---|
| `payment_provider_enabled` | `mercado-pago`, `oficina-billing-service`, `lab`, valor `1` |
| `payment_provider_requests_count_total` | `PIX`; `pending/pending=1`; `failure/none=2` |
| `payment_provider_request_duration_seconds` | `PIX`; séries para `pending` e `failure` |
| `payment_provider_amount_BRL` | `PIX`; `currency=BRL`; séries para `pending` e `failure` |
| `payment_provider_failures_count_total` | `provider_http_error=1`; `communication=1` |
| `payment_provider_unavailable_count_total` | `communication=1` |

Não foram observadas labels de alta cardinalidade como `pagamentoId`, `ordemServicoId`, `transacaoExternaId`, CPF, e-mail ou `correlationId`. Esses identificadores permaneceram restritos a logs e traces, conforme o padrão normativo.

Com essa evidência, a emissão, o scrape, a conversão cumulativa para delta e a ingestão das métricas `payment_provider_*` estão comprovados. A criação da visão específica permanece no item remoto `[D-NR-REM-006]` do [Roadmap](../../ROADMAP.md).
