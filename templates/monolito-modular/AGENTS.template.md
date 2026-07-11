# AGENTS.md

## Contexto

Este repositório implementa `{{APP_NAME}}` como um monólito modular.

Stack padrão:

- Java {{JAVA_VERSION}}
- {{FRAMEWORK}}
- Maven Wrapper ou build equivalente do repositório
- API HTTP, JSON, persistência reativa, autenticação/autorização e observabilidade conforme extensões oficiais do framework

O código principal deve ficar em `src/main/java/{{BASE_PACKAGE_PATH}}`, com testes em `src/test/java/{{BASE_PACKAGE_PATH}}`.

Módulos esperados:

- `{{MODULES}}`

Cada módulo de negócio deve preservar a estrutura:

- `{{BASE_PACKAGE}}.<modulo>.core`
- `{{BASE_PACKAGE}}.<modulo>.interfaces`
- `{{BASE_PACKAGE}}.<modulo>.framework`

## Diretrizes gerais

- Preserve a arquitetura de monólito modular com fronteiras explícitas entre `core`, `interfaces` e `framework`.
- Mantenha regras de negócio no `core`.
- Mantenha HTTP, CDI, persistência, clientes externos, segurança, JWT, transações, sessões e detalhes do framework fora do `core`.
- Prefira mudanças pequenas, objetivas e compatíveis com o padrão existente.
- Evite dependências novas quando uma regra puder ser implementada com a stack já disponível.
- Ao criar novo fluxo, siga primeiro o fluxo de uma funcionalidade equivalente já existente.

## Layout obrigatório

### `core`

Use `core` para código de domínio puro:

- `core.entities`: entidades, value objects, enums e factories de domínio;
- `core.exceptions`: exceções de negócio;
- `core.interfaces.gateway`: contratos de persistência e integrações;
- `core.interfaces.presenter`: contratos de saída dos use cases;
- `core.interfaces.presenter.dto`: DTOs usados pelos presenters;
- `core.interfaces.sender`: contratos de envio/eventos/notificações, quando houver;
- `core.usecases.<subdominio>`: casos de uso e serviços de domínio.

Regras:

- não usar Quarkus, Spring, JAX-RS, CDI, JPA, Panache, Mutiny, JWT, HTTP client ou annotations de framework;
- expor assinaturas assíncronas com `CompletableFuture`;
- gateways e presenters são interfaces do domínio;
- detalhes de banco, HTTP e serialização ficam fora.

### `interfaces`

Use `interfaces` para adaptação entre entrada/saída e domínio:

- `interfaces.controllers`: controllers puros que recebem requests, montam commands e chamam use cases;
- `interfaces.presenters`: adapters concretos de presenter;
- `interfaces.presenters.view_model`: modelos devolvidos pela borda HTTP.

Regras para controllers:

- classe pública sem escopo CDI;
- dependências via construtor;
- métodos públicos de instância retornam `CompletableFuture`;
- requests como `record`, preferencialmente internos ao controller e com sufixo `Request`;
- conversões simples de entrada podem acontecer aqui, por exemplo parsing de IDs, value objects e defaults;
- não declarar `@Path`, `@GET`, `@POST`, `@Inject`, `@ApplicationScoped`, `@WithTransaction`, `@WithSession` ou `Uni`;
- não conter regra de negócio que pertença ao use case ou entidade.

Regras para presenters:

- adapters com sufixo `PresenterAdapter`;
- implementam presenter do `core` quando houver contrato;
- armazenam o resultado da request em campo privado;
- expõem `viewModel()` ou `viewModels()`;
- devem ser produzidos como `@RequestScoped` na configuração CDI, não anotados diretamente salvo padrão local explícito.

### `framework`

Use `framework` para detalhes técnicos:

- `framework.web`: resources HTTP, exception mappers e classes de configuração CDI;
- `framework.db`: entities Panache/JPA e adapters de persistência;
- `framework.service`: clientes externos e adapters de integração;
- `framework.security`: JWT, tokens, autorização e criptografia;
- `framework.dispatcher`: envio de mensagens, e-mail, eventos ou notificações.

Regras para resources:

- classe em `framework.web` com sufixo `Resource`;
- declarar `@Path` no nível da classe;
- usar anotações HTTP, `@RolesAllowed`, `@Consumes`, `@Produces`, `@WithSession` e `@WithTransaction` apenas aqui;
- injetar controller, presenter e helpers de framework;
- retornar `Uni`;
- adaptar `CompletableFuture` com `Uni.createFrom().completionStage(...)`;
- não colocar regra de negócio no resource.

Regras para adapters:

- adapters de banco/integração implementam gateways do `core`;
- classes de persistência usam sufixo `DataSourceAdapter`;
- ficam em `framework.db` ou `framework.service`;
- são `@ApplicationScoped`;
- convertem entre entity/framework e domínio dentro do adapter;
- expõem `CompletableFuture` para o domínio, convertendo `Uni` com `.subscribeAsCompletionStage()`.

Regras para configuração:

- classes de composição ficam em `framework.web` com sufixo `Configuration`;
- são `@ApplicationScoped`;
- usam métodos `@Produces` para criar controllers e presenters;
- instanciam use cases explicitamente;
- presenters stateful devem ser `@RequestScoped`.

## Padrão de classes

### Use case

```java
public class AdicionarItemUseCase {
    private final ItemGateway itemGateway;

    public AdicionarItemUseCase(ItemGateway itemGateway) {
        this.itemGateway = itemGateway;
    }

    public CompletableFuture<Void> executar(Command command) {
        var item = new Item(command.nome());
        return itemGateway.adicionar(item).thenApply(ignored -> null);
    }

    public record Command(String nome) {
    }
}
```

### Controller

```java
public class ItemController {
    private final AdicionarItemUseCase adicionarItemUseCase;

    public ItemController(AdicionarItemUseCase adicionarItemUseCase) {
        this.adicionarItemUseCase = adicionarItemUseCase;
    }

    public CompletableFuture<Void> adicionar(ItemRequest request) {
        var command = new AdicionarItemUseCase.Command(request.nome());
        return adicionarItemUseCase.executar(command);
    }

    public record ItemRequest(String nome) {
    }
}
```

### Resource

```java
@Path("/itens")
public class ItemResource {

    @Inject ItemController itemController;

    @WithTransaction
    @POST
    @Consumes(MediaType.APPLICATION_JSON)
    @RolesAllowed("administrativo")
    public Uni<Void> create(ItemController.ItemRequest request) {
        return Uni.createFrom().completionStage(itemController.adicionar(request));
    }
}
```

### Presenter

```java
public class ItemPresenterAdapter implements ItemPresenter {
    private ItemViewModel viewModel;

    @Override
    public void present(ItemDTO itemDTO) {
        this.viewModel = new ItemViewModel(itemDTO.id(), itemDTO.nome());
    }

    public ItemViewModel viewModel() {
        return viewModel;
    }
}
```

### Configuração CDI

```java
@ApplicationScoped
public class ItemConfiguration {

    @Produces ItemController itemController(ItemGateway itemGateway) {
        return new ItemController(new AdicionarItemUseCase(itemGateway));
    }

    @Produces @RequestScoped ItemPresenterAdapter itemPresenter() {
        return new ItemPresenterAdapter();
    }
}
```

## Constraints em testes

Mantenha um teste estrutural em `src/test/java/{{BASE_PACKAGE_PATH}}/architecture/ArchitectureConstraintsTest.java`.

Esse teste deve validar pelo menos:

- layout por módulo e camadas;
- isolamento do `core`;
- pureza da camada `interfaces`;
- assinatura dos controllers;
- assinatura dos use cases;
- padrão dos resources;
- padrão dos adapters.

Use o template `docs/templates/monolito-modular/ArchitectureConstraintsTest.template.java` como base.

## Validação

Antes de encerrar alterações, execute a validação compatível com o impacto:

- `{{BUILD_COMMAND}}`
- `{{FULL_VALIDATION_COMMAND}}` quando a mudança afetar integração, configuração, persistência, segurança ou contrato HTTP

Se alguma validação não puder ser executada, registre isso claramente na resposta final.

## Commits

Quando houver alterações no repositório, crie commit ao final do trabalho.

Use mensagens em português seguindo Conventional Commits:

- `feat: adiciona consulta detalhada de item`
- `fix: corrige validacao do token`
- `test: adiciona constraints arquiteturais`
- `chore: atualiza regras de agentes`
