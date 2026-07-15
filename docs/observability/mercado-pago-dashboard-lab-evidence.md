# Evidência do Dashboard Mercado Pago no Lab

## Resultado

Em 2026-07-15, o dashboard `Oficina SOAT - Mercado Pago Lab` foi criado via NerdGraph na conta `8254132`.

| Campo | Valor |
|---|---|
| GUID | `ODI1NDEzMnxWSVp8REFTSEJPQVJEfGRhOjEyODg3MzE0` |
| Página | `Mercado Pago` |
| Widgets totais | `11` |
| Widgets com NRQL | `10` |

Os painéis cobrem:

- estado de habilitação da integração;
- volume de chamadas por método e desfecho;
- percentuais de sucesso, recusa, pendência e erro;
- status retornados pelo provedor;
- latência p95 e p99;
- valor financeiro por método, desfecho e moeda;
- indisponibilidade e falhas por motivo;
- logs por `correlationId`;
- traces da integração financeira.

As dez consultas foram executadas via NerdGraph sem erro antes da criação. Nove retornaram dados reais da cobrança sandbox e das falhas controladas registradas na [Evidência das Métricas do Mercado Pago no Lab](payment-provider-metrics-lab-evidence.md). A consulta de traces permaneceu válida, mas sem linha correspondente na janela atual; ela continuará disponível para spans externos futuros.

Após a mutation, a entidade foi relida pelo GUID e confirmou a página, os `11` widgets e seus títulos. O template canônico está em [Dashboard Mercado Pago](new-relic-dashboard-mercado-pago.json).
