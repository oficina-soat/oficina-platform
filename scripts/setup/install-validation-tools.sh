#!/usr/bin/env bash

set -Eeuo pipefail

readonly BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
# shellcheck disable=SC2016 # A linha deve ser persistida com as variáveis literais.
readonly PATH_EXPORT='export PATH="$HOME/.local/bin:$PATH"'

tmp_dir=""
docker_group_changed="false"

log() {
  printf '\n==> %s\n' "$*"
}

fail() {
  printf 'Erro: %s\n' "$*" >&2
  exit 1
}

cleanup() {
  if [[ -n "$tmp_dir" && -d "$tmp_dir" ]]; then
    rm -rf "$tmp_dir"
  fi
}

trap cleanup EXIT

configure_path() {
  local profile

  mkdir -p "$BIN_DIR"
  for profile in "$HOME/.bashrc" "$HOME/.profile"; do
    touch "$profile"
    if ! grep -qxF "$PATH_EXPORT" "$profile"; then
      printf '%s\n' "$PATH_EXPORT" >>"$profile"
    fi
  done

  export PATH="$BIN_DIR:$PATH"
}

install_system_packages() {
  local -a privilege=()

  command -v apt-get >/dev/null 2>&1 ||
    fail "este instalador requer uma distribuição Debian ou Ubuntu com apt-get"

  if ((EUID != 0)); then
    command -v sudo >/dev/null 2>&1 ||
      fail "sudo é necessário para instalar os pacotes do sistema"
    privilege=(sudo)
  fi

  log "Instalando dependências do sistema"
  "${privilege[@]}" apt-get update
  "${privilege[@]}" apt-get install -y \
    ca-certificates \
    curl \
    docker.io \
    jq \
    openjdk-25-jdk \
    shellcheck \
    shfmt \
    tar \
    unzip
}

configure_docker() {
  local target_user="${SUDO_USER:-${USER:-$(id -un)}}"
  local -a privilege=()

  if ((EUID != 0)); then
    privilege=(sudo)
  fi

  log "Configurando Docker"
  if command -v systemctl >/dev/null 2>&1 && [[ -d /run/systemd/system ]]; then
    "${privilege[@]}" systemctl enable --now docker
  else
    printf 'Aviso: systemd não está ativo; inicie o daemon Docker conforme o gerenciador de serviços do ambiente.\n'
  fi

  getent group docker >/dev/null 2>&1 ||
    fail "o pacote docker.io não criou o grupo docker esperado"
  if ! id -nG "$target_user" | tr ' ' '\n' | grep -qx docker; then
    "${privilege[@]}" usermod -aG docker "$target_user"
    docker_group_changed="true"
  fi
}

download() {
  local url="$1"
  local destination="$2"

  curl --proto '=https' --tlsv1.2 -fsSL "$url" -o "$destination"
}

install_yq() {
  local source="$tmp_dir/yq"

  log "Instalando yq"
  download \
    "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${release_arch}" \
    "$source"
  install -m 0755 "$source" "$BIN_DIR/yq"
}

install_actionlint() {
  local installer="$tmp_dir/install-actionlint.bash"
  local destination="$tmp_dir/actionlint"

  log "Instalando actionlint"
  mkdir -p "$destination"
  download \
    "https://raw.githubusercontent.com/rhysd/actionlint/main/scripts/download-actionlint.bash" \
    "$installer"
  bash "$installer" latest "$destination"
  install -m 0755 "$destination/actionlint" "$BIN_DIR/actionlint"
}

install_tflint() {
  local archive="$tmp_dir/tflint.zip"
  local source="$tmp_dir/tflint"

  log "Instalando tflint"
  download \
    "https://github.com/terraform-linters/tflint/releases/latest/download/tflint_linux_${release_arch}.zip" \
    "$archive"
  unzip -p "$archive" tflint >"$source"
  install -m 0755 "$source" "$BIN_DIR/tflint"
}

install_hadolint() {
  local source="$tmp_dir/hadolint"

  log "Instalando hadolint"
  download \
    "https://github.com/hadolint/hadolint/releases/latest/download/hadolint-Linux-${hadolint_arch}" \
    "$source"
  install -m 0755 "$source" "$BIN_DIR/hadolint"
}

install_kubeconform() {
  local archive="$tmp_dir/kubeconform.tar.gz"
  local destination="$tmp_dir/kubeconform"

  log "Instalando kubeconform"
  mkdir -p "$destination"
  download \
    "https://github.com/yannh/kubeconform/releases/latest/download/kubeconform-linux-${release_arch}.tar.gz" \
    "$archive"
  tar -xzf "$archive" -C "$destination" kubeconform
  install -m 0755 "$destination/kubeconform" "$BIN_DIR/kubeconform"
}

install_terraform() {
  local version archive source

  log "Instalando terraform"
  version="$(
    curl --proto '=https' --tlsv1.2 -fsSL \
      https://checkpoint-api.hashicorp.com/v1/check/terraform |
      jq -er '.current_version'
  )"
  archive="$tmp_dir/terraform.zip"
  source="$tmp_dir/terraform"
  download \
    "https://releases.hashicorp.com/terraform/${version}/terraform_${version}_linux_${release_arch}.zip" \
    "$archive"
  unzip -p "$archive" terraform >"$source"
  install -m 0755 "$source" "$BIN_DIR/terraform"
}

install_kubectl() {
  local version source

  log "Instalando kubectl"
  version="$(curl --proto '=https' --tlsv1.2 -fsSL https://dl.k8s.io/release/stable.txt)"
  [[ "$version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
    fail "versão inesperada do kubectl: $version"
  source="$tmp_dir/kubectl"
  download \
    "https://dl.k8s.io/release/${version}/bin/linux/${release_arch}/kubectl" \
    "$source"
  install -m 0755 "$source" "$BIN_DIR/kubectl"
}

install_gh() {
  local version archive destination

  log "Instalando GitHub CLI"
  version="$(
    curl --proto '=https' --tlsv1.2 -fsSL \
      https://api.github.com/repos/cli/cli/releases/latest |
      jq -er '.tag_name | ltrimstr("v")'
  )"
  [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
    fail "versão inesperada do GitHub CLI: $version"
  archive="$tmp_dir/gh.tar.gz"
  destination="$tmp_dir/gh"
  mkdir -p "$destination"
  download \
    "https://github.com/cli/cli/releases/download/v${version}/gh_${version}_linux_${release_arch}.tar.gz" \
    "$archive"
  tar -xzf "$archive" -C "$destination" --strip-components=2 \
    "gh_${version}_linux_${release_arch}/bin/gh"
  install -m 0755 "$destination/gh" "$BIN_DIR/gh"
}

show_versions() {
  log "Ferramentas instaladas"
  jq --version
  shellcheck --version | sed -n '1,2p'
  shfmt --version
  yq --version
  actionlint -version
  tflint --version
  hadolint --version
  kubeconform -v
  terraform version | sed -n '1p'
  kubectl version --client=true
  gh --version | sed -n '1p'
  java -version 2>&1 | sed -n '1p'
  javac -version
  docker --version

  printf '\nInstalação concluída em %s.\n' "$BIN_DIR"
  printf 'Abra um novo shell ou execute: %s\n' "$PATH_EXPORT"
  printf 'Para autenticar o GitHub CLI, execute: gh auth login\n'
  if [[ "$docker_group_changed" == "true" ]]; then
    printf 'Abra uma nova sessão para usar Docker sem sudo; o grupo docker concede privilégios equivalentes a root.\n'
  fi
}

main() {
  [[ "$(uname -s)" == "Linux" ]] || fail "somente Linux é suportado"
  if ((EUID == 0)) && [[ "$HOME" == "/root" ]]; then
    fail "execute como usuário normal; o script solicitará sudo quando necessário"
  fi

  case "$(uname -m)" in
  x86_64 | amd64)
    readonly release_arch="amd64"
    readonly hadolint_arch="x86_64"
    ;;
  aarch64 | arm64)
    readonly release_arch="arm64"
    readonly hadolint_arch="arm64"
    ;;
  *)
    fail "arquitetura não suportada: $(uname -m)"
    ;;
  esac

  tmp_dir="$(mktemp -d)"
  configure_path
  install_system_packages
  configure_docker
  install_yq
  install_actionlint
  install_tflint
  install_hadolint
  install_kubeconform
  install_terraform
  install_kubectl
  install_gh
  show_versions
}

main "$@"
