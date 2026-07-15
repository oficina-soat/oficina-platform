# ADR-013 - Frontend operacional Angular

## Status

**Aceito**

## Contexto

A plataforma possui APIs independentes para autenticação, atendimento, execução e faturamento, mas ainda não possui interface para o uso cotidiano de pessoas com os papéis `administrativo`, `recepcionista` e `mecanico`.

O frontend deve começar pequeno, permitir evolução incremental e seguir guardrails equivalentes aos backends. A interface não é um novo domínio: regras, autorização, cálculos, estados válidos, Saga, estoque e pagamentos continuam pertencendo aos serviços.

## Decisão

Será criado o repositório independente `oficina-ui` com as seguintes direções:

- SPA na última versão estável do Angular disponível no scaffold, inicialmente Angular 22;
- TypeScript estrito, standalone components, lazy loading e Reactive Forms;
- organização por feature com `presentation`, `application` e `infrastructure`;
- Signals e serviços de aplicação no MVP, sem NgRx;
- ausência de SSR e BFF no primeiro incremento;
- hospedagem estática em S3 privado com CloudFront e Origin Access Control;
- infraestrutura declarada no `oficina-infra` e pipeline independente no `oficina-ui`;
- escopo inicial limitado a login, atendimento e fila do mecânico;
- portal do cliente, financeiro, estoque, administração avançada, tempo real e BFF tratados como evoluções posteriores.

## Fronteira de responsabilidade

O frontend pode validar forma e usabilidade, coordenar chamadas, manter estado efêmero de tela, formatar valores e apresentar permissões informadas pelas APIs.

O frontend não pode:

- calcular orçamento, desconto ou pagamento;
- decidir transições da Ordem de Serviço ou da execução;
- inferir disponibilidade ou compensação de estoque;
- implementar autorização definitiva por papel;
- reproduzir Saga, idempotência de negócio ou publicação de eventos;
- converter uma rejeição do backend em sucesso;
- habilitar uma operação por regras reconstruídas a partir de múltiplas respostas.

Quando uma tela precisar conhecer ações disponíveis, o contrato do backend deve fornecer estado ou ações permitidas. O serviço deve revalidar qualquer comando recebido, independentemente do comportamento da UI.

## Estrutura de dependências

```text
presentation -> application <- infrastructure
```

- `presentation`: páginas, componentes, formulários e navegação;
- `application`: coordenação dos fluxos da interface e ports, sem decisões de negócio;
- `infrastructure`: `HttpClient`, DTOs, mappers, autenticação e configuração externa;
- `core`: capacidades transversais da aplicação;
- `shared/ui`: componentes visuais sem semântica de negócio.

As fronteiras devem ser protegidas por testes arquiteturais e lint. Componentes não chamam `HttpClient`; DTOs externos não se tornam modelos globais; features não importam detalhes internos de outras features.

## Segurança da sessão

O MVP mantém o token apenas durante a sessão da aplicação, preferencialmente em memória. Guards e ocultação de controles servem à experiência, não à segurança. APIs e authorizers continuam responsáveis pela autorização.

Persistência mais longa de sessão exige nova avaliação. Um BFF com cookie `HttpOnly`, `Secure` e `SameSite` poderá ser considerado se o benefício justificar o custo operacional.

## Hospedagem

O build Angular será armazenado em bucket S3 privado e servido por CloudFront. O bucket não terá website público. O CloudFront fornecerá HTTPS, cache, fallback de rotas da SPA e headers de segurança.

O domínio padrão do CloudFront é suficiente inicialmente. Domínio próprio, Route 53 e WAF não são pré-requisitos do MVP.

## Consequências

### Positivas

- baixo custo e ausência de servidor dedicado;
- familiaridade com Angular no ambiente de trabalho do usuário;
- deploy independente e compatível com a governança multi-repositório;
- fronteira explícita que evita duplicação de regras dos backends;
- evolução incremental sem antecipar infraestrutura de BFF ou SSR.

### Negativas

- token presente no processo do navegador durante a sessão;
- possíveis evoluções nas APIs para filtros, consultas agregadas ou ações permitidas;
- necessidade de testes arquiteturais específicos para evitar erosão das fronteiras;
- refresh da página pode exigir nova autenticação no desenho inicial em memória.

## Referências

- [Roadmap do frontend operacional](../docs/frontend/roadmap.md)
- [Governança Multi-Repositório](ADR-007%20-%20Governança%20Multi-Repositório%20e%20Plataforma%20Compartilhada.md)
- [Estratégia de CI/CD](ADR-012%20-%20Estratégia%20de%20CI%20CD%20e%20Deploy%20Independente.md)
- [Contrato de APIs REST](../contracts/Contrato%20de%20APIs%20REST.md)
- [Rotas públicas do API Gateway](../docs/infrastructure/api-gateway-public-routes.md)
