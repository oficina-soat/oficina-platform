# Template de regras para monolito modular

Este diretório contém artefatos reutilizáveis para aplicar em outros repositórios o mesmo estilo arquitetural usado no `oficina-app`.

Origem: `oficina-app` no commit `da88d26c9edb971e493b680080e1b19cc99be68b`, copiado para este repositório como referência canônica da plataforma. Os arquivos permanecem com placeholders para serem customizados no repositório consumidor.

## Arquivos

- `AGENTS.template.md`: instruções para agentes seguirem o padrão de arquitetura, implementação, validação e versionamento.
- `ArchitectureConstraintsTest.template.java`: teste JUnit sem dependências extras para travar layout de pacotes e estrutura das classes principais.
- `src/test/java/br/com/oficina/architecture/ArchitectureConstraintsTest.java`: versão viva aplicada no repositório de origem.

## Como usar em outro repositório

1. Copie `AGENTS.template.md` para `AGENTS.md` no outro repositório.
2. Substitua os placeholders:
   - `{{APP_NAME}}`
   - `{{BASE_PACKAGE}}`
   - `{{BASE_PACKAGE_PATH}}`, por exemplo `br/com/oficina`
   - `{{BASE_PACKAGE_REGEX}}`, por exemplo `br\\.com\\.oficina`
   - `{{MODULES}}`
   - `{{JAVA_VERSION}}`
   - `{{FRAMEWORK}}`
   - `{{BUILD_COMMAND}}`
   - `{{FULL_VALIDATION_COMMAND}}`
3. Copie `ArchitectureConstraintsTest.template.java` para `src/test/java/<base-package>/architecture/ArchitectureConstraintsTest.java`.
4. Ajuste a linha `package`, `BASE_PACKAGE`, exceções legadas e pacotes compartilhados permitidos.
5. Rode `{{BUILD_COMMAND}}` e corrija as violações apontadas antes de evoluir features.

## Regras que devem virar teste

Estas regras devem falhar no build, não ficar apenas como documentação:

- todo módulo de negócio deve ter as camadas `core`, `interfaces` e `framework`;
- `core` não importa Quarkus, Mutiny, JAX-RS, CDI, JPA, MicroProfile nem classes de `framework`;
- controllers ficam em `.interfaces.controllers`, são classes puras, não têm anotações HTTP/CDI e seus métodos públicos de instância retornam `CompletableFuture`;
- use cases ficam em `.core.usecases`, expõem método principal `executar(...)`, retornam `CompletableFuture` e usam `record Command` quando recebem comando;
- resources ficam em `.framework.web`, declaram `@Path`, adaptam `CompletableFuture` para `Uni` e concentram anotações HTTP, sessão, transação e autorização;
- adapters de persistência/integração ficam em `framework`, implementam gateways do `core`, são `@ApplicationScoped` e convertem `Uni` para `CompletionStage` na saída;
- presenters ficam em `interfaces.presenters`, guardam estado da request, expõem `viewModel()` ou `viewModels()` e são produzidos como `@RequestScoped` na configuração CDI.

## Exceções

Em repositórios novos, prefira lista de exceções vazia. Se um legado precisar violar uma regra, coloque a exceção nominalmente no teste, com caminho completo do arquivo. Isso torna a dívida explícita e impede que o desvio se espalhe.

## Quando usar ArchUnit

O template usa apenas JUnit e leitura de fontes para não adicionar dependência. Se o projeto já usa ArchUnit, as mesmas regras podem ser migradas para ArchUnit, mas mantenha o mesmo nível de rigor: a falha precisa dizer exatamente qual arquivo ou classe saiu do padrão.
