# Ferramentas de validação local

## Objetivo

Este guia lista ferramentas recomendadas para validar workflows, scripts, Terraform, Dockerfiles e manifests Kubernetes antes de abrir PR, aceitar merge ou executar deploy.

As ferramentas abaixo são recomendadas, mas não devem bloquear trabalho em ambientes onde ainda não estejam instaladas. Quando uma ferramenta esperada não estiver disponível, registre a limitação e execute a validação equivalente mais próxima.

## Instalação recomendada

Os comandos abaixo assumem Linux x86_64, como Debian ou Ubuntu, com binários de usuário em `~/.local/bin`.

Para instalar de uma só vez todo o ferramental deste guia, incluindo Terraform e `kubectl`, execute o [instalador de ferramentas de validação](../../scripts/setup/install-validation-tools.sh):

```bash
scripts/setup/install-validation-tools.sh
```

O script suporta Linux x86_64 e ARM64, instala OpenJDK 25, Docker Engine e dependências do sistema com `apt-get`, e mantém os demais binários em `~/.local/bin`. Execute-o como usuário normal; ele solicitará `sudo` para os pacotes do sistema, para iniciar o daemon Docker quando systemd estiver ativo e para adicionar o usuário ao grupo `docker`. Ao final, a autenticação do GitHub CLI continua sendo uma ação explícita com `gh auth login`.

Após a primeira instalação do Docker, abra uma nova sessão para que a associação ao grupo `docker` seja aplicada. Esse grupo permite controlar o daemon e concede privilégios equivalentes a root; restrinja a associação aos usuários que realmente executam builds e testes com containers.

Para instalação manual, use os comandos a seguir.

```bash
mkdir -p ~/.local/bin
export PATH="$HOME/.local/bin:$PATH"
grep -qxF 'export PATH="$HOME/.local/bin:$PATH"' ~/.bashrc 2>/dev/null || echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
grep -qxF 'export PATH="$HOME/.local/bin:$PATH"' ~/.profile 2>/dev/null || echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.profile

sudo apt-get update
sudo apt-get install -y curl docker.io jq openjdk-25-jdk shellcheck shfmt tar unzip
sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"
```

Abra uma nova sessão e confirme os runtimes:

```bash
java -version
javac -version
docker version
```

Instale `yq` v4, compatível com os comandos `yq e` usados nos workflows:

```bash
curl -fsSL -o ~/.local/bin/yq \
  https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
chmod +x ~/.local/bin/yq

yq --version
```

Instale `actionlint` pelo script oficial:

```bash
bash <(curl -sSfL https://raw.githubusercontent.com/rhysd/actionlint/main/scripts/download-actionlint.bash) latest ~/.local/bin
actionlint -version
```

Instale `tflint` pelo binário publicado no GitHub Releases:

```bash
tmp="$(mktemp -d)"
curl -fsSL -o "$tmp/tflint.zip" \
  https://github.com/terraform-linters/tflint/releases/latest/download/tflint_linux_amd64.zip
unzip -p "$tmp/tflint.zip" tflint > ~/.local/bin/tflint
chmod +x ~/.local/bin/tflint
rm -rf "$tmp"

tflint --version
```

Instale `hadolint` pelo binário publicado no GitHub Releases:

```bash
curl -fsSL -o ~/.local/bin/hadolint \
  https://github.com/hadolint/hadolint/releases/latest/download/hadolint-linux-x86_64
chmod +x ~/.local/bin/hadolint

hadolint --version
```

Instale `kubeconform` pelo binário publicado no GitHub Releases:

```bash
tmp="$(mktemp -d)"
curl -fsSL \
  https://github.com/yannh/kubeconform/releases/latest/download/kubeconform-linux-amd64.tar.gz \
  | tar -xz -C "$tmp"
mv "$tmp/kubeconform" ~/.local/bin/kubeconform
chmod +x ~/.local/bin/kubeconform
rm -rf "$tmp"

kubeconform -v
```

Autentique o GitHub CLI quando precisar investigar PRs, runs ou logs de GitHub Actions:

```bash
sudo apt-get install -y gh
gh auth login
gh auth status
```

Se `gh` não estiver disponível no `apt` da distribuição, use as instruções oficiais do [GitHub CLI para Linux](https://github.com/cli/cli/blob/trunk/docs/install_linux.md).

## Quando usar

| Escopo alterado | Validação recomendada |
|---|---|
| GitHub Actions | `actionlint` |
| Scripts shell | `find scripts -type f -name '*.sh' -print0 | xargs -0 bash -n`, `shellcheck` e `shfmt -d` |
| Terraform | `terraform fmt -check -recursive`, `terraform validate` e `tflint` |
| Dockerfile | `hadolint Dockerfile` |
| Testes Java com containers | OpenJDK 25, `docker info` e `./mvnw -B clean verify ...` |
| Kubernetes YAML ou Kustomize | `yq`, `kubectl kustomize` e `kubeconform -strict -summary` |
| Microsserviço Java publicável | `./mvnw -B clean verify ...`, presença de `target/jacoco-report/jacoco.xml` e SonarCloud local quando `SONAR_TOKEN` existir |
| CI/CD remoto | `gh run view`, `gh run view --log` e `gh pr checks` |

## Exemplos por repositório

No `oficina-infra`:

```bash
terraform fmt -check -recursive terraform
TERRAFORM_ACTION=validate scripts/actions/ci-terraform.sh
tflint --chdir terraform/environments/lab
find scripts -type f -name '*.sh' -print0 | xargs -0 bash -n
find scripts -type f -name '*.sh' -print0 | xargs -0 shellcheck
shfmt -d scripts
kubectl kustomize k8s/base/microservices | kubeconform -strict -summary
kubectl kustomize k8s/overlays/lab | kubeconform -strict -summary
actionlint
```

Nos microsserviços:

```bash
MAVEN_PROFILE="${MAVEN_PROFILE:-postgresql}"
./mvnw -B clean verify -P"${MAVEN_PROFILE}" -DskipITs=false -DfailIfNoTests=false
test -s target/jacoco-report/jacoco.xml
actionlint
hadolint Dockerfile
```

Para o `oficina-execution-service`, use o profile DynamoDB:

```bash
MAVEN_PROFILE=dynamodb ./mvnw -B clean verify -Pdynamodb -DskipITs=false -DfailIfNoTests=false
test -s target/jacoco-report/jacoco.xml
```

Quando `SONAR_TOKEN` estiver disponível localmente, execute também o SonarCloud antes de criar commit em microsserviço. Informe a branch explicitamente para não atualizar a análise da `main` por acidente:

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

Use `-Dsonar.qualitygate.wait=true -Dsonar.qualitygate.timeout=300` apenas em `main`, branch longa com Quality Gate habilitado ou PR real configurado com `sonar.pullrequest.*`. Em branch local curta, o SonarCloud pode aceitar a análise, mas bloquear a consulta do Quality Gate com 403.

## Referências oficiais

- [actionlint](https://github.com/rhysd/actionlint/blob/main/docs/install.md)
- [TFLint](https://github.com/terraform-linters/tflint)
- [Hadolint](https://github.com/hadolint/hadolint)
- [Kubeconform](https://kubeconform.mandragor.org/docs/installation/)
- [yq](https://github.com/mikefarah/yq)
- [GitHub CLI](https://github.com/cli/cli/blob/trunk/docs/install_linux.md)
