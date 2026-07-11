# Runbooks Operacionais Mínimos

## Objetivo

Definir os procedimentos mínimos para diagnosticar, conter e registrar incidentes operacionais da Fase 4.

Este documento complementa o [Padrão de Observabilidade Distribuída](observability.md), o [Padrão Outbox por Serviço](../architecture/outbox-pattern.md), os [Fluxos da Saga da Ordem de Serviço](../architecture/saga-flows.md), o [Checklist de Deploy Independente](../delivery/independent-deploy-checklist.md), o [Escopo do Repositório Unificado de Infraestrutura](../infrastructure/infrastructure-repository-scope.md), os [Nomes de runtime, secrets e infraestrutura](../infrastructure/infra-runtime-naming.md), o [Contrato de Erros REST](../../contracts/error-model.md), o [Contrato de Tópicos de Mensageria](../../contracts/Contrato%20de%20Tópicos%20de%20Mensageria.md) e o [Checklist Final de Entrega da Fase 4](../delivery/phase-4-delivery-checklist.md).

## Escopo

Runbooks cobertos:

| Runbook | Sinal principal | Serviço dono da primeira análise |
|---|---|---|
| Serviço indisponível | readiness falhando, pod reiniciando ou rollout incompleto | Serviço afetado |
| Erro HTTP elevado ou latência elevada | aumento de `5xx` ou p95 acima do limite operacional | Serviço afetado |
| Outbox parada ou com falha | `outbox.oldest.pending.age`, `outbox.pending.count` ou `outbox.failed.count` | Serviço produtor |
| DLQ recebendo mensagens | `messaging.dlq.count` ou mensagens visíveis em DLQ | Serviço consumidor |
| Saga em `FALHA_MANUAL` | `saga.instances.failed.count` ou estado persistido da Saga | `oficina-os-service` |
| Pagamento indisponível | falhas recorrentes na integração financeira | `oficina-billing-service` |
| Banco indisponível | readiness falhando por PostgreSQL ou DynamoDB | Serviço dono do banco |
| Rollback de deploy | rollout falho ou regressão pós-deploy | Serviço alterado |

Estes runbooks não substituem a criação remota de dashboards e alertas no New Relic. Quando New Relic, AWS, EKS ou GitHub exigirem credenciais administrativas, a execução remota deve ser registrada como evidência externa no [Checklist Final de Entrega da Fase 4](../delivery/phase-4-delivery-checklist.md).

## Coleta inicial

Antes de atuar em qualquer incidente:

- [ ] identificar serviço, ambiente, versão e janela de início;
- [ ] coletar `correlationId`, `traceId`, `eventId`, `aggregateId`, `ordemServicoId` ou `sagaId` quando disponíveis;
- [ ] confirmar se houve deploy recente usando o [Checklist de Deploy Independente](../delivery/independent-deploy-checklist.md);
- [ ] verificar se a falha afeta um serviço, uma rota, um consumidor, uma fila ou o fluxo completo da Saga;
- [ ] confirmar se o incidente exige contenção imediata, rollback, reprocessamento ou apenas acompanhamento.

Comandos operacionais típicos no ambiente `lab`:

```bash
aws sts get-caller-identity
aws eks update-kubeconfig --region us-east-1 --name eks-lab
kubectl get deployments,pods,services -n <namespace>
kubectl get events -n <namespace> --sort-by=.lastTimestamp
```

Não registre tokens, JWTs, secrets, dados de cartão ou payloads sensíveis em evidências.

## Serviço indisponível

Use quando readiness falhar, pods reiniciarem continuamente, rollout ficar preso ou uma rota de negócio parar de responder.

### Diagnóstico

- [ ] confirmar rollout: `kubectl rollout status deployment/<servico> -n <namespace>`;
- [ ] listar pods do serviço: `kubectl get pods -n <namespace> -l app=<servico>`;
- [ ] inspecionar pod afetado: `kubectl describe pod <pod> -n <namespace>`;
- [ ] verificar logs recentes: `kubectl logs deployment/<servico> -n <namespace> --since=30m`;
- [ ] conferir probes `/q/health/live` e `/q/health/ready`;
- [ ] verificar se a imagem, variáveis e secrets do `Deployment` batem com os nomes canônicos em [Nomes de runtime, secrets e infraestrutura](../infrastructure/infra-runtime-naming.md).

### Contenção

- [ ] se a falha começou após deploy, seguir o runbook [Rollback de deploy](#rollback-de-deploy);
- [ ] se a causa for secret ou ConfigMap ausente, corrigir no `oficina-infra` e reaplicar apenas o recurso afetado;
- [ ] se a causa for dependência indisponível, seguir o runbook de banco, mensageria ou pagamento aplicável;
- [ ] não reiniciar todos os serviços se apenas um `Deployment` estiver degradado.

### Encerramento

- [ ] confirmar readiness estável;
- [ ] executar smoke test de rota de negócio;
- [ ] registrar versão, causa provável, ação tomada e evidência.

## Erro HTTP elevado ou latência elevada

Use quando respostas `5xx`, erros funcionais inesperados ou p95 de latência aumentarem de forma sustentada.

### Diagnóstico

- [ ] filtrar logs por `service.name`, `deployment.environment=lab`, rota e `correlationId`;
- [ ] separar erro de cliente esperado de erro interno conforme o [Contrato de Erros REST](../../contracts/error-model.md);
- [ ] verificar se a latência está em HTTP, banco, mensageria, integração Mercado Pago ou dependência AWS;
- [ ] conferir traces por rota quando New Relic estiver disponível;
- [ ] comparar a versão atual com a versão anterior estável do serviço.

### Contenção

- [ ] para regressão recém-publicada, seguir [Rollback de deploy](#rollback-de-deploy);
- [ ] para erro concentrado em dependência externa, seguir o runbook da dependência;
- [ ] para erro funcional reproduzível, abrir correção no repositório do serviço dono;
- [ ] preservar `correlationId` e exemplos mínimos sem dados sensíveis.

### Encerramento

- [ ] confirmar redução de `5xx` e latência;
- [ ] confirmar smoke test da rota afetada;
- [ ] registrar erro, rota, versão, `correlationId` e ação tomada.

## Outbox parada ou com falha

Use quando eventos ficarem `PENDING` além do SLA, `outbox.pending.count` crescer continuamente ou houver evento `FAILED`.

### Diagnóstico

- [ ] identificar serviço produtor, `eventType`, tópico e `aggregateId`;
- [ ] confirmar se a falha é de publicação, permissão, tópico inexistente, schema inválido ou indisponibilidade do broker;
- [ ] consultar logs do publicador por `eventId` e `correlationId`;
- [ ] verificar métricas `outbox.oldest.pending.age`, `outbox.pending.count` e `outbox.failed.count`;
- [ ] para PostgreSQL, consultar somente o database do serviço dono;
- [ ] para DynamoDB, consultar somente tabelas do `oficina-execution-service`.

### Contenção

- [ ] se o tópico ou permissão estiver ausente, corrigir no `oficina-infra` conforme [Escopo do Repositório Unificado de Infraestrutura](../infrastructure/infrastructure-repository-scope.md);
- [ ] se o evento estiver inválido, corrigir o produtor e manter o mesmo `eventId` para reprocessamento;
- [ ] se a falha for temporária, aguardar retentativas com backoff conforme [Padrão Outbox por Serviço](../architecture/outbox-pattern.md);
- [ ] não publicar manualmente evento novo para substituir o mesmo fato de negócio sem preservar idempotência.

### Encerramento

- [ ] confirmar evento `PUBLISHED` ou decisão explícita para `FAILED`;
- [ ] confirmar consumidor recebeu ou receberá o evento pelo tópico canônico;
- [ ] registrar `eventId`, `eventType`, tópico, causa e ação.

## DLQ recebendo mensagens

Use quando uma fila de erro receber mensagens ou consumidores rejeitarem eventos.

### Diagnóstico

- [ ] identificar tópico de origem, fila consumidora, DLQ, serviço consumidor e `eventType`;
- [ ] inspecionar atributos da mensagem sem expor payload sensível;
- [ ] coletar `eventId`, `eventVersion`, `aggregateId` e `correlationId`;
- [ ] verificar logs do consumidor no serviço dono;
- [ ] confirmar se o schema do evento está compatível com os [schemas JSON de eventos](../../contracts/events/schemas/), quando presentes;
- [ ] distinguir falha transitória de bug de consumidor ou evento incompatível.

### Contenção

- [ ] corrigir consumidor quando o erro for de parsing, idempotência ou regra local;
- [ ] corrigir produtor e contrato quando o evento publicado divergir do contrato;
- [ ] redrive só deve ocorrer após correção da causa e deve preservar `eventId`;
- [ ] não mover mensagem para outra fila de serviço sem decisão explícita de ownership.

### Encerramento

- [ ] confirmar que a DLQ parou de crescer;
- [ ] confirmar reprocessamento idempotente ou descarte documentado;
- [ ] registrar tópico, fila, `eventId`, consumidor e ação tomada.

## Saga em `FALHA_MANUAL`

Use quando uma Saga não puder avançar nem compensar automaticamente.

### Diagnóstico

- [ ] localizar `sagaId`, `ordemServicoId`, estado atual e última etapa concluída;
- [ ] conferir histórico da OS e eventos recebidos pelo `oficina-os-service`;
- [ ] verificar se há evento faltante, duplicado, inválido ou preso em Outbox/DLQ;
- [ ] comparar a etapa com os [Fluxos da Saga da Ordem de Serviço](../architecture/saga-flows.md);
- [ ] verificar se pagamento, execução ou estoque exige runbook específico.

### Contenção

- [ ] bloquear avanço para `ENTREGUE` enquanto pagamento ou execução estiverem inconsistentes;
- [ ] executar compensação idempotente somente quando prevista no fluxo;
- [ ] se houver evento faltante por Outbox ou DLQ, resolver primeiro a falha de mensageria;
- [ ] não alterar manualmente o estado global da OS sem registrar causa, evidência e decisão operacional.

### Encerramento

- [ ] confirmar Saga em `FINALIZADA_COM_SUCESSO`, `COMPENSADA` ou falha manual documentada;
- [ ] confirmar eventos finais esperados, como `sagaCompensada` ou `sagaFinalizadaComSucesso`;
- [ ] registrar `sagaId`, `ordemServicoId`, causa, compensação e evidências.

## Pagamento indisponível

Use quando o `oficina-billing-service` falhar de forma recorrente ao chamar Mercado Pago ou outra dependência financeira configurada.

### Diagnóstico

- [ ] verificar status do `oficina-billing-service`;
- [ ] filtrar logs por `pagamentoId`, `ordemServicoId`, `correlationId` e provedor;
- [ ] verificar métricas `payment.provider.requests.count`, `payment.provider.request.duration`, `payment.provider.failures.count` e `payment.provider.unavailable.count` para `provider=mercado-pago`;
- [ ] distinguir erro de configuração, indisponibilidade externa, timeout, credencial ausente ou recusa de negócio;
- [ ] confirmar se o serviço está publicando `pagamentoSolicitado`, `pagamentoConfirmado` ou `pagamentoRecusado` conforme o contrato.

### Contenção

- [ ] para indisponibilidade externa, manter pagamento em estado pendente ou falha manual conforme regra do serviço;
- [ ] para credencial ausente ou inválida, corrigir secret fora do repositório e redeployar apenas o serviço afetado quando necessário;
- [ ] para regressão recém-publicada, seguir [Rollback de deploy](#rollback-de-deploy);
- [ ] não marcar pagamento como confirmado sem confirmação válida do fluxo financeiro.

### Encerramento

- [ ] confirmar retomada da integração financeira;
- [ ] confirmar estado do pagamento e evento final;
- [ ] registrar provedor, erro, `pagamentoId`, ação e evidência.

## Banco indisponível

Use quando readiness ou operações falharem por PostgreSQL ou DynamoDB.

### Diagnóstico

- [ ] identificar banco afetado: `oficina_os`, `oficina_billing` ou tabelas `oficina-execution-lab-*`;
- [ ] confirmar se apenas um serviço foi afetado;
- [ ] verificar readiness do serviço;
- [ ] verificar secrets, endpoint, permissões e variáveis de conexão;
- [ ] para PostgreSQL, confirmar que o serviço não acessa database de outro serviço;
- [ ] para DynamoDB, confirmar `OFICINA_DYNAMODB_TABLE_PREFIX=oficina-execution-lab` e permissões IAM do runtime.

### Contenção

- [ ] se a infraestrutura estiver ausente, corrigir no `oficina-infra`;
- [ ] se a migration falhou, corrigir no repositório do serviço dono;
- [ ] se a falha for credencial, rotacionar ou corrigir secret fora do Git;
- [ ] não compartilhar usuário, database ou tabela entre microsserviços para contornar incidente.

### Encerramento

- [ ] confirmar health ready do serviço;
- [ ] executar smoke test de leitura e escrita quando seguro;
- [ ] registrar recurso afetado, causa e correção.

## Rollback de deploy

Use quando um rollout falhar ou uma regressão for detectada após publicar nova imagem.

### Diagnóstico

- [ ] identificar serviço, versão anterior, versão nova, release e digest da imagem;
- [ ] verificar workflow, rollout e logs do pod novo;
- [ ] confirmar se a regressão é de aplicação, configuração, imagem, secret ou infraestrutura;
- [ ] avaliar se há mudança incompatível de contrato ou persistência.

### Contenção

- [ ] pausar novos deploys do mesmo serviço;
- [ ] executar rollback do `Deployment` afetado ou redeploy da última imagem estável;
- [ ] confirmar `kubectl rollout status deployment/<servico> -n <namespace>`;
- [ ] validar smoke test do serviço;
- [ ] verificar Outbox, DLQ e Saga após o rollback quando a mudança envolveu eventos.

### Encerramento

- [ ] registrar workflow, release, imagem revertida, causa provável e evidência;
- [ ] abrir correção no repositório dono;
- [ ] atualizar o [Checklist Final de Entrega da Fase 4](../delivery/phase-4-delivery-checklist.md) quando o rollback fizer parte de evidência ou limitação da entrega.

## Escalação

Escalar quando:

- o incidente afeta mais de um microsserviço;
- há risco de perda de evento, duplicidade de pagamento ou entrega indevida de OS;
- Saga permanece em `FALHA_MANUAL` sem compensação clara;
- DLQ ou Outbox continua crescendo após contenção;
- a correção exige alteração de contrato, ADR, ownership ou infraestrutura compartilhada.

Mudanças em contrato ou arquitetura devem ser registradas primeiro no `oficina-platform`. Mudanças executáveis de infraestrutura devem ir para `oficina-infra`. Mudanças de domínio devem ir para o microsserviço dono.

## Evidências

Para incidentes usados como evidência final ou de homologação, registrar:

| Evidência | Conteúdo mínimo |
|---|---|
| Janela | Início, fim e ambiente. |
| Escopo | Serviço, rota, tópico, fila, banco ou Saga afetada. |
| Identificadores | `correlationId`, `traceId`, `eventId`, `aggregateId`, `ordemServicoId` ou `sagaId`. |
| Causa | Hipótese principal e evidência. |
| Ação | Contenção, correção, rollback ou reprocessamento. |
| Resultado | Métrica ou validação que confirma recuperação. |

O [Checklist Final de Entrega da Fase 4](../delivery/phase-4-delivery-checklist.md) deve concentrar links ou identificadores das evidências finais.
