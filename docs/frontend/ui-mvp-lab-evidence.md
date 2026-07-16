# Homologação da UI no lab

Data de início: 2026-07-16  
Tarefa: `[UI-MVP-REM-001]`  
Estado: parcial

## Publicação validada

O workflow [Deploy UI Lab 29505861890](https://github.com/oficina-soat/oficina-ui/actions/runs/29505861890) publicou no EKS a revisão `3dbf8a7ae02bb26704683e41243ad20684b6052c`. O artefato usado pela imagem foi produzido pelos gates do mesmo workflow, sem recompilação durante o deploy.

Os três jobs terminaram com sucesso:

- build, testes, cobertura, arquitetura, segurança e auditoria;
- E2E isolado, navegação por teclado e acessibilidade automatizada;
- infraestrutura opcional, imagem rastreável e rollout do workload.

Os metadados servidos pelo workload confirmaram o run `29505861890`, a revisão implantada e o instante `2026-07-16T14:20:52Z`.

## Acesso e configuração

URL validada: `https://ucye9d6rka.execute-api.us-east-1.amazonaws.com`

| Verificação | Resultado |
| --- | --- |
| `GET /` | `200`, HTML da Oficina SOAT servido pelo Nginx |
| `GET /healthz` | `200`, corpo `ok` |
| `GET /session` | `200`, mesmo `index.html` da raiz; recarga de rota Angular preservada |
| `GET /main-HAUQ3J5H.js` | `200`, `application/javascript` |
| `GET /config/runtime-config.json` | `200`, JSON válido com endpoints canônicos de API e autenticação |
| `GET /deploy-metadata.json` | `200`, revisão e run correspondentes ao deploy |

A configuração efetiva aponta `apiBaseUrl` para `/api/v1` no API Gateway e `authBaseUrl` para a raiz do mesmo gateway. Ela não contém credenciais nem configuração secreta.

## Segurança e operação

As respostas públicas apresentaram CSP restritiva, HSTS, `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `frame-ancestors 'none'`, políticas de abertura e recursos cross-origin, política de referência e bloqueio de câmera, geolocalização, microfone, pagamento e USB.

O rollout foi aguardado pelo pipeline e terminou em sucesso. A tentativa adicional de consultar o endpoint privado do EKS a partir da estação local não resolveu o DNS privado do cluster; a publicação permanece comprovada pelo job de rollout e pelas respostas do workload através de API Gateway, VPC Link e NLB.

## Validações restantes

Para concluir `[UI-MVP-REM-001]`, ainda é necessário executar na UI publicada, sem mocks:

- atendimento com papel real de recepção ou administração: cliente, veículo e ordem de serviço;
- fila e execução com papel real de mecânico, usando somente ações permitidas pelo backend;
- orçamento e pagamento com papel real autorizado;
- navegação manual por teclado e verificação responsiva durante esses fluxos;
- emissão controlada de telemetria e busca pelo mesmo `correlationId` no coletor configurado.

Nenhuma credencial, CPF, JWT, token, payload financeiro ou dado pessoal deve ser incluído nas evidências. IDs técnicos podem ser registrados apenas quando forem necessários para correlação e não identificarem uma pessoa.
