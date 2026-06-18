# ADR-005 - Reavaliação do HPA

## Status

**Aceito**

---

## Contexto

No cenário atual, a aplicação já utiliza HPA. Para a nova etapa, a principal questão não é substituir o HPA por completo, mas decidir se ele continua sendo a base do escalonamento da aplicação principal e como deve ser complementado para o novo desenho em EKS, com observabilidade e controle de custos.

---

## Decisão

A aplicação principal continuará utilizando Horizontal Pod Autoscaler como mecanismo padrão de escalabilidade horizontal no Kubernetes.
O HPA será mantido como a solução principal para escalar os pods da aplicação Quarkus, com base em métricas de CPU e memória, e com configuração conservadora para evitar oscilações excessivas.
Além disso, a estratégia de autoscaling deverá ser tratada em dois níveis:

1. escalonamento da aplicação com HPA
2. escalonamento da capacidade do cluster com solução própria de nós, preferencialmente Karpenter no EKS, ou Cluster Autoscaler quando houver necessidade de uma abordagem mais tradicional

Essa combinação é aderente ao requisito de Kubernetes com escalabilidade e evita concentrar toda a elasticidade apenas no nível de infraestrutura. O HPA é o mecanismo nativo do Kubernetes para aumentar ou reduzir réplicas de workloads, enquanto Karpenter e Cluster Autoscaler tratam da oferta de nós para acomodar esses pods.

## Justificativa

Manter o HPA faz sentido por cinco motivos.
Primeiro, ele atende diretamente ao requisito do projeto de manter a aplicação principal em Kubernetes com escalabilidade.
Segundo, ele é o mecanismo nativo e mais simples de justificar arquiteturalmente para escalar Deployments no Kubernetes. O próprio Kubernetes define o HPA como o recurso responsável por ajustar automaticamente a capacidade de workloads como Deployments e StatefulSets.
Terceiro, ele funciona bem para a natureza da aplicação principal, que tende a ser orientada a APIs e operações síncronas. Nesses casos, CPU e memória costumam ser métricas iniciais adequadas para o primeiro nível de escalonamento.
Quarto, manter HPA reduz risco de implementação e facilita a defesa da arquitetura, porque ele já está em uso e exige menos mudança estrutural do que migrar toda a estratégia para uma alternativa externa.
Quinto, ele pode ser expandido no futuro para métricas customizadas, sem precisar abandonar a abordagem atual. O HPA suporta métricas de recursos e também pode trabalhar com outras métricas expostas ao cluster.

## Recomendações de configuração

Para este projeto, a recomendação é não usar uma configuração agressiva logo de início. O melhor caminho é uma configuração previsível, fácil de explicar e com baixo risco de efeito sanfona.
Configuração inicial sugerida para a aplicação principal:

- minReplicas: 2
- maxReplicas: 6
- métricas:
    - CPU averageUtilization: 60% a 70%
    - memória averageUtilization: 70% a 80%
- scaleUp mais rápido que scaleDown
- stabilizationWindowSeconds no scaleDown para evitar redução imediata após picos
- readinessProbe e livenessProbe bem ajustados
- requests e limits obrigatórios e realistas, porque o HPA depende dessas referências para escalar corretamente em métricas de utilização

Uma sugestão prática de comportamento:

- scaleUp:
    - estabilização baixa, por exemplo 0 a 30 segundos
    - crescimento em passos moderados
- scaleDown:
    - estabilização maior, por exemplo 300 segundos
    - redução gradual

Essa linha é coerente com a própria recomendação do Kubernetes de usar comportamento configurável para controlar reação a picos e evitar flapping.
Em termos arquiteturais, também vale registrar três cuidados operacionais:

1. HPA sem requests/limits bem definidos tende a produzir decisões ruins.
2. HPA sozinho não resolve falta de nós no cluster.
3. HPA baseado só em CPU pode ser insuficiente se o gargalo real estiver em fila, I/O, conexões ou throughput externo.

Por isso, para EKS, a recomendação é complementar o HPA com autoscaling de nós. A AWS trata Karpenter e Cluster Autoscaler como abordagens válidas para esse problema e recomenda Karpenter especialmente para workloads com necessidade variável de capacidade.

---

## Consequências

### Positivas

- reaproveita o que já está funcionando hoje
- atende diretamente ao requisito de Kubernetes com escalabilidade
- mantém a arquitetura simples o suficiente para implementação e apresentação
- permite evolução gradual para métricas mais ricas
- combina bem com observabilidade via Datadog ou outra ferramenta equivalente

### Negativas

- exige tuning de requests, limits e probes
- pode escalar mal se as métricas escolhidas não refletirem o gargalo real
- depende de uma estratégia adicional para escalar nós do cluster
- pode não ser suficiente sozinho para workloads assíncronos ou orientados a fila
