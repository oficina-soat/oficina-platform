# oficina-platform
Seu objetivo é centralizar a governança da plataforma, fornecendo uma visão unificada da arquitetura e servindo como fonte oficial para contratos, padrões e decisões compartilhadas.

## Repositórios da plataforma

Os microsserviços canônicos da plataforma possuem repositórios independentes na mesma suíte:

| Repositório | Responsabilidade |
| --- | --- |
| `../oficina-os-service` | Gestão da Ordem de Serviço, cadastros principais e orquestração da Saga. |
| `../oficina-billing-service` | Cobrança, pagamentos e integrações financeiras. |
| `../oficina-execution-service` | Catálogo técnico de peças e serviços, diagnóstico, execução, estoque operacional e finalização do serviço. |

Os repositórios remotos verificados seguem a organização `oficina-soat` no GitHub:

- `git@github.com:oficina-soat/oficina-os-service.git`
- `git@github.com:oficina-soat/oficina-billing-service.git`
- `git@github.com:oficina-soat/oficina-execution-service.git`

Este repositório continua sendo a fonte normativa para ADRs, contratos, OpenAPI, eventos, padrões e artefatos compartilhados. Código de aplicação, pipelines específicos e manifestos próprios permanecem nos repositórios dos microsserviços.

## Roadmap

O planejamento incremental da plataforma, incluindo lacunas restantes e backlog orientado a agentes, está documentado em [ROADMAP.md](ROADMAP.md).

## Documentação

A documentação normativa está organizada por tema em [docs/](docs/README.md):

- [Arquitetura](docs/README.md#arquitetura)
- [Infraestrutura](docs/README.md#infraestrutura)
- [Observabilidade](docs/README.md#observabilidade)
- [Entrega e Validação](docs/README.md#entrega-e-validação)

## Scripts manuais

- [generate-bearer-token.sh](scripts/manual/generate-bearer-token.sh): gera um header `Authorization: Bearer ...` chamando `POST /auth/token` da `auth-lambda` do ambiente `lab`.

Exemplo sem expor a senha no histórico do shell:

```bash
AUTH_PASSWORD_FILE=/tmp/oficina-auth-password \
  scripts/manual/generate-bearer-token.sh
```

Para obter apenas o token, use:

```bash
AUTH_PASSWORD_FILE=/tmp/oficina-auth-password \
  scripts/manual/generate-bearer-token.sh --raw
```
