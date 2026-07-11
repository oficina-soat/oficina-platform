# AGENTS.md

## Contexto

Este repositório é a fonte oficial de governança da plataforma da oficina mecânica. Ele concentra decisões arquiteturais, contratos, padrões e artefatos compartilhados que direcionam a evolução dos microsserviços e dos repositórios de infraestrutura.

Stack e escopo atual do projeto:

- ADRs em [adr/](adr/)
- contratos REST, eventos, mensageria e estados em [contracts/](contracts/)
- especificações OpenAPI em [contracts/openapi/](contracts/openapi/)
- roadmap incremental em [ROADMAP.md](ROADMAP.md)
- documentação geral em [README.md](README.md)

Os microsserviços definidos para a plataforma são:

- `oficina-os-service`
- `oficina-billing-service`
- `oficina-execution-service`

A direção da plataforma é que cada microsserviço tenha seu próprio repositório independente, seguindo a governança, os contratos e os padrões definidos aqui. Ao criar ou evoluir esses repositórios, use os nomes dos microsserviços acima como referência canônica.

O padrão reutilizável de regras arquiteturais e constraints estruturais copiado do `oficina-app` fica em [Template de regras para monolito modular](templates/monolito-modular/README.md). Use esse template como referência base para orientar `AGENTS.md` e testes estruturais de arquitetura dos microsserviços, substituindo placeholders por valores do serviço consumidor antes de aplicar.

Este repositório faz parte de uma suíte maior. Alguns repositórios irmãos existentes ainda podem servir como referência, mesmo que parte deles deixe de ser usada conforme os novos microsserviços forem criados. Assuma que, quando presentes na mesma raiz deste diretório, os repositórios irmãos relevantes são:

- `../oficina-app`
- `../oficina-auth-lambda`
- `../oficina-infra-db`
- `../oficina-infra-k8s`
- `../oficina-infra`

Quando esses repositórios estiverem disponíveis, eles devem ser consultados para manter consistência de nomes, contratos e integrações compartilhadas da suíte, especialmente:

- nomes de environments
- nomes de secrets
- nomes de variáveis de ambiente
- rotas expostas publicamente
- contratos REST e OpenAPI
- nomes de eventos, tópicos e produtores
- issuer, audience e JWKS usados na autenticação
- padrões de banco de dados, Kubernetes, CI/CD e deploy

Durante a decomposição e consolidação da Fase 4, trate `../oficina-app`, `../oficina-infra-db` e `../oficina-infra-k8s` como fontes de consulta e cópia controlada. Não adapte esses repositórios diretamente nesse fluxo; copie os artefatos necessários e faça as mudanças nos destinos canônicos:

- código de domínio do `oficina-app` deve ser adaptado nos repositórios dos microsserviços;
- artefatos de infraestrutura de `oficina-infra-db` e `oficina-infra-k8s` devem ser adaptados em `../oficina-infra`.

O `../oficina-auth-lambda` é exceção: quando a mudança pertencer aos fluxos de autenticação ou notificações, faça o ajuste diretamente nesse repositório, preservando os nomes e contratos compartilhados documentados aqui.

## Diretrizes Gerais

- Trate este repositório como fonte normativa da plataforma. Mudanças em ADRs, contratos e padrões devem reduzir ambiguidade para implementação em outros repositórios.
- Preserve a estrutura já usada no projeto: decisões em [adr/](adr/), contratos em [contracts/](contracts/), eventos individuais em [contracts/events/](contracts/events/) e OpenAPI por microsserviço em [contracts/openapi/](contracts/openapi/).
- Use o [ROADMAP.md](ROADMAP.md) como referência de prioridade e critério de pronto para novas alterações.
- Quando o usuário solicitar a "próxima tarefa", interprete sempre como o próximo item aberto no [ROADMAP.md](ROADMAP.md), mesmo que a mensagem inclua outro arquivo como contexto operacional ou referência complementar.
- Prefira mudanças pequenas, objetivas e compatíveis com os contratos já existentes.
- Evite criar novos padrões, diretórios, microsserviços, tópicos ou formatos de contrato sem necessidade clara.
- Ao alterar uma decisão compartilhada, atualize todos os artefatos afetados no mesmo escopo da mudança.
- Quando houver divergência entre documentação conceitual e contratos implementáveis, explicite a decisão e normalize os artefatos relacionados.
- Quando houver dúvida sobre nomes que precisam ser iguais entre plataforma, aplicação, autenticação, banco e infraestrutura, consulte os repositórios irmãos antes de definir novos valores.
- Ao consultar `oficina-app`, `oficina-infra-db` ou `oficina-infra-k8s`, use-os apenas como referência ou origem de cópia; registre e aplique adaptações nos destinos canônicos definidos no [Plano de migração para o repositório unificado de infraestrutura](docs/infrastructure/infrastructure-migration-plan.md) e no [Plano de Decomposição do oficina-app](docs/architecture/oficina-app-decomposition.md).
- Quando houver ponto de decisão não tomado, incerto ou ambíguo que possa mudar arquitetura, contrato, ownership, nome canônico, prioridade, compatibilidade, infraestrutura, segurança ou operação, consulte o usuário antes de decidir. A consulta deve apresentar as opções possíveis, a recomendação quando houver, e explicar objetivamente como cada opção influencia a decisão, os artefatos afetados e os riscos de divergência.
- Em arquivos Markdown, use links relativos sempre que citar artefatos do próprio repositório, como ADRs, contratos, OpenAPI, schemas, templates, documentos em `docs/` e itens do roadmap. Prefira texto descritivo com link, por exemplo `[Contrato de APIs REST](contracts/Contrato%20de%20APIs%20REST.md)`, em vez de apenas citar o caminho em texto solto.
- Ao criar ou alterar um artefato Markdown, inclua links para os documentos diretamente relacionados sempre que isso ajudar um agente a navegar pela decisão sem procurar manualmente. Preserve caminhos em monospace apenas quando o caminho for valor técnico, comando, exemplo de estrutura ou parte de um contrato.
- Em textos Markdown em português, use acentuação correta e revise termos comuns sem acento antes de encerrar a alteração. Preserve sem acento identificadores técnicos, nomes de campos, rotas, tópicos, eventos, variáveis, comandos, trechos de código e valores canônicos quando essa for a forma contratada.

## Implementação

- Mantenha AWS como plataforma de nuvem definida, salvo nova ADR explícita.
- Preserve a governança multi-repositório: este repositório define padrões e contratos, mas não deve absorver código de aplicação, Lambda, banco ou infraestrutura executável.
- Preserve a regra de destino da migração: `oficina-app`, `oficina-infra-db` e `oficina-infra-k8s` não devem receber adaptações da Fase 4 diretamente; `oficina-auth-lambda` pode receber ajustes diretos quando a mudança for do seu próprio componente serverless.
- Preserve a divisão atual dos microsserviços entre `oficina-os-service`, `oficina-billing-service` e `oficina-execution-service`.
- Preserve a estratégia de comunicação híbrida: REST para integrações síncronas e mensageria assíncrona para eventos de domínio.
- Preserve a Saga Pattern orquestrada pelo `oficina-os-service`, salvo mudança arquitetural documentada por ADR.
- Preserve persistência poliglota por microsserviço conforme ADRs e padrões existentes.
- Ao mexer em contratos REST, mantenha coerência entre [Contrato de APIs REST](contracts/Contrato%20de%20APIs%20REST.md) e os arquivos em [contracts/openapi/](contracts/openapi/).
- Ao mexer em eventos, mantenha coerência entre [Contrato de Eventos de Domínio](contracts/Contrato%20de%20Eventos%20de%20Domínio.md), [contracts/events/](contracts/events/), [Contrato de Tópicos de Mensageria](contracts/Contrato%20de%20Tópicos%20de%20Mensageria.md) e eventuais schemas JSON.
- Ao mexer em estados de Ordem de Serviço, mantenha coerência com os fluxos REST, eventos e Saga.
- Ao criar contratos OpenAPI, inclua endpoints, schemas de request e response, códigos HTTP esperados, erros padronizados, autenticação e exemplos mínimos.
- Ao criar schemas de eventos, use o envelope padrão de mensageria com `eventId`, `eventType`, `eventVersion`, `occurredAt`, `producer`, `aggregateId` e `payload`.
- Não altere nomes de eventos, tópicos, produtores, rotas ou estados sem atualizar os documentos correlatos.
- Se houver erro simples, warning simples ou ajuste mecânico evidente no escopo da tarefa, resolva junto em vez de deixar pendência.

## Prioridades

Siga a priorização do [ROADMAP.md](ROADMAP.md) para orientar alterações incrementais.

Prioridade atual recomendada:

1. Contratos implementáveis:
   - normalizar eventos e tópicos;
   - criar tabela canônica `evento -> tópico -> produtor -> consumidores`;
   - criar schemas JSON dos eventos fundamentais;
   - manter OpenAPI dos três microsserviços;
   - criar contrato de erros REST;
   - criar contrato de idempotência.
2. Blueprint dos microsserviços:
   - criar matriz de ownership por serviço;
   - criar template Quarkus de microsserviço;
   - criar pipeline padrão de CI/CD;
   - criar manifests Kubernetes base;
   - criar documentação local padrão.
3. Saga e integração distribuída:
   - detalhar fluxo principal da Ordem de Serviço;
   - documentar compensações, timeouts, retentativas e cenários de erro;
   - definir contratos de comandos e eventos usados pela Saga.
4. Operação e entrega:
   - documentar observabilidade;
   - definir logs estruturados, métricas, traces e `correlationId`;
   - criar runbooks, checklist de release e checklist de revisão de contratos.

## Validação

Antes de encerrar uma alteração, execute a validação compatível com o impacto da mudança.

Para mudanças em Markdown:

```bash
find . -path ./.git -prune -o -name '*.md' -print
```

Para mudanças em OpenAPI YAML:

```bash
find contracts/openapi -name '*.yaml' -print
```

Para mudanças em YAML, use `yq` como ferramenta padrão de parse e validação sintática:

```bash
find . -path ./.git -prune -o \( -name '*.yaml' -o -name '*.yml' \) -print0 | xargs -0 yq e '.' >/dev/null
```

Para mudanças em JSON Schema:

```bash
find contracts/events -name '*.schema.json' -print
```

Use validações adicionais quando houver ferramentas disponíveis no repositório ou quando a mudança afetar contratos executáveis, exemplos JSON, OpenAPI, schemas de eventos, templates, CI/CD ou Kubernetes.

Ferramentas complementares recomendadas estão documentadas em [Ferramentas de validação local](docs/delivery/validation-tooling.md). Quando estiverem disponíveis, execute as validações proporcionais ao escopo:

- alterações em GitHub Actions: `actionlint`;
- alterações em scripts shell: `bash -n`, `shellcheck` e `shfmt -d`;
- alterações em Terraform: `terraform fmt -check -recursive`, `terraform validate` ou o script equivalente do repositório, e `tflint`;
- alterações em Dockerfile: `hadolint Dockerfile`;
- alterações em Kubernetes ou Kustomize: `kubectl kustomize`, validação YAML com `yq` e `kubeconform -strict -summary`;
- investigação de CI/CD remoto: prefira `gh` autenticado para consultar runs, jobs e logs antes de inferir a causa.

Se uma ferramenta complementar esperada não estiver instalada, registre isso na resposta final e execute a melhor validação equivalente disponível.

Para alterações publicáveis em repositórios de microsserviço, execute validação compatível com o SonarCloud antes de criar commit. O objetivo é antecipar localmente falhas de cobertura, duplicação e, quando o contexto analisado permitir consulta, reprovação de Quality Gate que bloquearia o `service-ci-validate`.

Validação mínima obrigatória antes do commit em microsserviços:

```bash
MAVEN_PROFILE="${MAVEN_PROFILE:-postgresql}"
./mvnw -B clean verify -P"${MAVEN_PROFILE}" -DskipITs=false -DfailIfNoTests=false
test -s target/jacoco-report/jacoco.xml
```

Para `oficina-execution-service`, use `MAVEN_PROFILE=dynamodb`.

Quando `SONAR_TOKEN` estiver disponível no ambiente local, execute também a análise SonarCloud antes do commit. Para evitar contaminar a análise da `main`, informe explicitamente a branch local:

```bash
SERVICE_NAME="${SERVICE_NAME:-$(basename "$(git rev-parse --show-toplevel)")}"
MAVEN_PROFILE="${MAVEN_PROFILE:-postgresql}"
SONAR_BRANCH="${SONAR_BRANCH:-$(git rev-parse --abbrev-ref HEAD)}"
./mvnw -B org.sonarsource.scanner.maven:sonar-maven-plugin:sonar \
  -P"${MAVEN_PROFILE}" \
  -DskipTests=true \
  -Dsonar.organization=oficina-soat \
  -Dsonar.projectKey="${SERVICE_NAME}" \
  -Dsonar.branch.name="${SONAR_BRANCH}" \
  -Dsonar.coverage.jacoco.xmlReportPaths=target/jacoco-report/jacoco.xml \
  -Dsonar.issue.ignore.multicriteria=postgresqlVarchar,postgresqlDuplicatedLiterals \
  -Dsonar.issue.ignore.multicriteria.postgresqlVarchar.ruleKey=plsql:VarcharUsageCheck \
  -Dsonar.issue.ignore.multicriteria.postgresqlVarchar.resourceKey=**/src/main/resources/db/migration/*.sql \
  -Dsonar.issue.ignore.multicriteria.postgresqlDuplicatedLiterals.ruleKey=plsql:S1192 \
  -Dsonar.issue.ignore.multicriteria.postgresqlDuplicatedLiterals.resourceKey=**/src/main/resources/db/migration/*.sql
```

Use `-Dsonar.qualitygate.wait=true -Dsonar.qualitygate.timeout=300` somente quando a análise local estiver em um contexto em que o SonarCloud exponha Quality Gate para a branch analisada, como `main`, uma branch longa com Quality Gate habilitado, ou análise de PR real com os parâmetros `sonar.pullrequest.*`. Branches locais curtas, como `develop`, podem aceitar upload da análise e ainda assim retornar 403 ao consultar o Quality Gate. Nesse caso, não trate a análise local como aprovação do Quality Gate; registre a limitação e mantenha o `service-ci-validate` remoto como evidência definitiva.

Se `SONAR_TOKEN` não estiver disponível, não invente aprovação do SonarCloud: registre na resposta final que a validação remota do Quality Gate não pôde ser executada localmente e que o `clean verify` com JaCoCo foi a validação equivalente disponível.

Antes de criar commit, execute uma revisão anti-divergência proporcional ao escopo da alteração. O objetivo é garantir que a mudança não introduziu divergência nova em relação ao estado anterior sem também resolvê-la no mesmo commit.

Regras para a revisão anti-divergência:

- compare os arquivos alterados com seus artefatos correlatos antes do stage final;
- ao alterar Markdown que referencia contratos, confirme se OpenAPI, schemas JSON, ADRs, README ou ROADMAP precisam ser atualizados;
- ao alterar OpenAPI, confirme coerência com o contrato REST, modelo de erros, idempotência, rotas e nomes de schemas;
- ao alterar eventos, confirme coerência entre Markdown individual, schema JSON, tabela canônica de eventos, tópicos, produtores e consumidores;
- ao alterar tópicos, produtores, consumidores, rotas, estados, nomes de banco, secrets, variáveis ou recursos de infraestrutura, procure o mesmo nome nos documentos relacionados com `rg` e normalize as ocorrências no mesmo escopo;
- quando houver script, parser ou ferramenta disponível para validar a relação entre artefatos, execute antes do commit;
- se uma divergência pré-existente for encontrada fora do escopo, registre na resposta final ou atualize o ROADMAP, mas não deixe uma divergência nova criada pela tarefa sem correção.

Checklist mínimo de revisão antes da resposta final:

- confirmar se o artefato criado está no diretório correto;
- confirmar se nomes de serviços, eventos, tópicos e rotas batem com os contratos relacionados;
- confirmar se mudanças em um contrato exigem atualização de OpenAPI, schema, ADR ou roadmap;
- confirmar se o [README.md](README.md) ou o [ROADMAP.md](ROADMAP.md) precisam ser atualizados;
- confirmar se algum ponto de decisão incerto, ambíguo ou ainda não tomado exige consulta ao usuário antes de concluir;
- confirmar se links Markdown foram usados para documentos relacionados sempre que possível;
- confirmar se a revisão anti-divergência foi executada antes do commit;
- registrar claramente qualquer validação que não pôde ser executada.

## Versionamento e Build

Este projeto depende de versionamento explícito dos contratos e decisões para manter governança entre repositórios.

- Preserve compatibilidade com contratos já publicados, salvo alteração deliberada e documentada.
- Mudanças incompatíveis em eventos devem incrementar `eventVersion` ou documentar a estratégia de migração.
- Mudanças incompatíveis em APIs devem preservar versionamento por URI, atualmente `/api/v1`, ou documentar nova versão.
- Ao fazer alterações relevantes em repositórios de microsserviço, verifique o `project.version` no `pom.xml` antes do commit e registre a decisão na revisão final.
- Trate como mudança publicável qualquer alteração em código Java, `pom.xml`, `Dockerfile`, configuração runtime, resources, migrations, testes que alterem o artefato validado, dependências, observabilidade, segurança, mensageria ou scripts usados pelo build da imagem.
- Toda mudança publicável candidata a merge em `main`, publicação de imagem, release ou deploy deve incrementar `project.version` no mesmo commit ou PR. Use SemVer fechado `MAJOR.MINOR.PATCH`, sem sufixo `SNAPSHOT`; prefira patch para correções compatíveis, minor para funcionalidades compatíveis e major apenas quando houver quebra deliberada acompanhada dos contratos ou ADRs necessários.
- Antes de considerar uma mudança de microsserviço pronta, compare `project.version` com a base do PR ou com o commit anterior da `main`; se a versão não aumentou para uma versão ainda não publicada como tag `v<project.version>` e imagem `<project.version>`, ajuste o `pom.xml` antes de concluir. Não reutilize versão já publicada para novo build, release ou rollout.
- Ao identificar necessidade de alterar decisões arquiteturais, sugira a mudança e aguarde avaliação do usuário antes de criar ou alterar ADRs.
- Ao alterar padrões que impactem microsserviços ou infraestrutura, confirme se templates, contratos e documentação precisam ser atualizados.
- Não introduza mudanças que exijam intervenção manual implícita sem registrar isso no repositório.

## Commits

Sempre que houver alteração relevante no repositório como resultado da tarefa, crie um commit local ao final do trabalho para avaliação do usuário.

Considere alteração relevante toda mudança de documentação, contrato, ADR, template, instrução, workflow ou arquivo de projeto feita como resultado da tarefa.

Não deixe alterações relevantes sem commit, salvo quando o usuário pedir explicitamente para não commitar ou quando houver impedimento técnico que precise ser relatado.

Não faça `git push`, salvo se o usuário pedir explicitamente.

Antes de criar o commit:

- adicione ao Git todos os arquivos novos criados no escopo da tarefa com `git add <arquivos-da-tarefa>`
- faça stage dos arquivos alterados que pertencem à tarefa
- não inclua arquivos locais ou não relacionados, como metadados de IDE
- verifique `git status --short` antes de fazer stage
- use `git diff -- <arquivo>` para revisar o conteúdo que será commitado quando houver mudanças pré-existentes no repositório
- execute a revisão anti-divergência descrita em [Validação](#validação) e resolva divergências novas antes do commit
- em repositórios de microsserviço com mudança publicável, execute a validação SonarCloud pré-commit descrita em [Validação](#validação), ou registre explicitamente a ausência de `SONAR_TOKEN` e a validação local equivalente executada
- revise o diff staged com `git diff --cached` quando a tarefa alterar mais de um arquivo ou quando houver risco de inconsistência entre contratos

Ao criar o commit, use mensagens em português seguindo Conventional Commits:

```bash
git add <arquivos-da-tarefa>
git commit -m "<tipo>: <resumo>"
```

Exemplos válidos:

- `docs: adiciona orientações para agentes do repositório`
- `docs: normaliza contratos de eventos e tópicos`
- `docs: adiciona contrato de idempotência`
- `chore: adiciona template base de microsserviço`

Prefira mensagens curtas, objetivas e diretamente relacionadas à alteração.

## Restrições Práticas

- Não transforme este repositório em implementação de microsserviço.
- Não mova para este repositório responsabilidades que pertencem à aplicação, autenticação, banco ou infraestrutura Kubernetes.
- Não altere diretamente `oficina-app`, `oficina-infra-db` ou `oficina-infra-k8s` para adaptar a Fase 4; use-os como fonte e aplique as alterações nos repositórios de destino. Para `oficina-auth-lambda`, ajustes diretos são permitidos quando forem necessários ao próprio componente.
- Não altere silenciosamente contratos compartilhados com `oficina-app`, `oficina-auth-lambda`, `oficina-infra-db` ou `oficina-infra-k8s`.
- Não crie novos microsserviços fora da divisão atual sem ADR e atualização dos contratos relacionados.
- Não troque soluções já adotadas por alternativas mais complexas sem justificativa técnica clara.
- Não ignore divergências simples entre Markdown, OpenAPI, eventos, tópicos e schemas quando estiverem no escopo da tarefa.
- Não inclua arquivos locais de IDE, caches ou artefatos gerados que não sejam parte explícita da mudança.
