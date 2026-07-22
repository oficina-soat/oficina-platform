# Evidência de homologação da decisão de orçamento no ambiente lab

Homologação executada em 22 de julho de 2026 para validar a experiência pública de aprovação e recusa de orçamento. Os testes usaram dados sintéticos exclusivos e a evidência não contém endereço de e-mail, senha, JWT nem capability de decisão.

## Resultado

No encerramento da homologação, o Deployment `oficina-billing-service` estava disponível com uma réplica pronta e imagem `oficina-billing-service:1.10.16`, versão posterior à `1.10.0` mínima requerida pela tarefa.

| Cenário | Evidência sanitizada | Resultado |
| --- | --- | --- |
| Página completa e aprovação | OS `38814df7-43f5-413b-baf0-6dcb0cd4ddb7`; orçamento `f8ba9e12-3e0c-3aaa-84a7-7fb4e784560c`; total R$ 102,50 | A página exibiu itens, total e as ações de aprovar e recusar; aprovação retornou HTTP 200. |
| Notificação inicial | mesma OS | Exatamente um e-mail inicial foi entregue. |
| Reenvio e rotação | mesma OS | Reenvio retornou HTTP 204, entregou uma segunda mensagem e emitiu uma capability diferente. |
| Invalidação do link anterior | mesma OS | A consulta com o link substituído retornou HTTP 401. |
| Uso único | mesma OS | A reutilização do link já consumido retornou HTTP 409. |
| Recusa e retomada | OS `6491069e-8b06-4219-b9c7-bf03e3c6b789` | Recusa retornou HTTP 200, reutilização retornou HTTP 409 e a projeção do Execution voltou para `EM_DIAGNOSTICO`. |
| MailHog público e interno | 14 mensagens existentes no momento da coleta | A rota pública e o acesso interno por port-forward retornaram a mesma quantidade e o mesmo conjunto de identificadores de mensagens. |

O acesso interno foi temporário e encerrado após a comparação. Nenhuma mensagem ou workflow remoto foi criado apenas para produzir esta evidência.

## Evidências remotas existentes

Foram consultadas, em modo somente leitura, execuções já concluídas:

- Billing: `Service CI/CD`, execuções [29940448957](https://github.com/oficina-soat/oficina-billing-service/actions/runs/29940448957) em `main` e [29935556367](https://github.com/oficina-soat/oficina-billing-service/actions/runs/29935556367) em `develop`, ambas com sucesso;
- UI: `Deploy UI Lab`, execução [29943419021](https://github.com/oficina-soat/oficina-ui/actions/runs/29943419021) em `main`, e `UI Quality Gate`, execução [29943367820](https://github.com/oficina-soat/oficina-ui/actions/runs/29943367820) em `develop`, ambas com sucesso;
- Infra: `Deploy Lab`, execução [29945470515](https://github.com/oficina-soat/oficina-infra/actions/runs/29945470515) em `main`, com sucesso.

Essas execuções confirmam o estado remoto observado, mas não substituem os testes funcionais realizados nesta homologação.

## Conclusão

Os cenários de aprovação, recusa, expiração lógica por substituição, uso único, reenvio e retomada do diagnóstico funcionaram no ambiente `lab`. A tarefa de homologação da experiência de decisão de orçamento pode ser considerada concluída.
