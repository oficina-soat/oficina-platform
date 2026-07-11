#!/usr/bin/env bash

set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
API_GATEWAY_NAME="${API_GATEWAY_NAME:-eks-lab-http-api}"
AUTH_BASE_URL="${AUTH_BASE_URL:-${OFICINA_AUTH_BASE_URL:-}}"
AUTH_CPF="${AUTH_CPF:-${ADMIN_CPF:-84191404067}}"
AUTH_PASSWORD="${AUTH_PASSWORD:-${OFICINA_AUTH_PASSWORD:-}}"
AUTH_PASSWORD_FILE="${AUTH_PASSWORD_FILE:-}"
OUTPUT_FORMAT="${OUTPUT_FORMAT:-header}"

usage() {
	cat <<EOF
Uso:
  $(basename "$0") [opcoes]

Gera um Bearer token chamando POST /auth/token da auth-lambda do ambiente lab.

Opcoes:
  --base-url <url>        URL base da auth-lambda/API Gateway.
  --cpf <cpf>             CPF do usuario. Default: 84191404067
  --password <senha>      Senha do usuario. Prefira AUTH_PASSWORD ou --password-file.
  --password-file <path>  Arquivo contendo a senha.
  --raw                   Imprime apenas o access_token.
  --header                Imprime "Authorization: Bearer <token>". Default.
  --export                Imprime "export AUTH_TOKEN=<token>".
  -h, --help              Exibe esta ajuda.

Variaveis suportadas:
  AUTH_BASE_URL ou OFICINA_AUTH_BASE_URL
  AUTH_CPF ou ADMIN_CPF
  AUTH_PASSWORD ou OFICINA_AUTH_PASSWORD
  AUTH_PASSWORD_FILE
  API_GATEWAY_NAME        Default: eks-lab-http-api
  AWS_REGION              Default: us-east-1
  OUTPUT_FORMAT           header|raw|export. Default: header

Se AUTH_BASE_URL nao for informado, o script tenta resolver o endpoint do
HTTP API pelo AWS CLI usando API_GATEWAY_NAME e AWS_REGION.
EOF
}

fail() {
	printf '[oficina-platform] erro: %s\n' "$*" >&2
	exit 1
}

require_cmd() {
	command -v "$1" >/dev/null 2>&1 || fail "comando obrigatorio nao encontrado: $1"
}

normalize_base_url() {
	local value="$1"

	value="${value%/}"
	[[ -n "${value}" ]] || return 0
	printf '%s' "${value}"
}

resolve_auth_base_url() {
	if [[ -n "${AUTH_BASE_URL}" ]]; then
		normalize_base_url "${AUTH_BASE_URL}"
		return 0
	fi

	if ! command -v aws >/dev/null 2>&1; then
		fail "AUTH_BASE_URL nao informado e AWS CLI nao encontrado para resolver ${API_GATEWAY_NAME}"
	fi

	local endpoint
	endpoint="$(aws apigatewayv2 get-apis \
		--region "${AWS_REGION}" \
		--query "Items[?Name=='${API_GATEWAY_NAME}'].ApiEndpoint | [0]" \
		--output text 2>/dev/null || true)"

	if [[ -z "${endpoint}" || "${endpoint}" == "None" ]]; then
		fail "nao foi possivel resolver o endpoint do API Gateway ${API_GATEWAY_NAME}; informe AUTH_BASE_URL"
	fi

	normalize_base_url "${endpoint}"
}

read_password() {
	if [[ -n "${AUTH_PASSWORD_FILE}" ]]; then
		[[ -f "${AUTH_PASSWORD_FILE}" ]] || fail "AUTH_PASSWORD_FILE nao encontrado: ${AUTH_PASSWORD_FILE}"
		tr -d '\r\n' <"${AUTH_PASSWORD_FILE}"
		return 0
	fi

	if [[ -n "${AUTH_PASSWORD}" ]]; then
		printf '%s' "${AUTH_PASSWORD}"
		return 0
	fi

	fail "senha nao informada; use AUTH_PASSWORD, OFICINA_AUTH_PASSWORD ou --password-file"
}

parse_args() {
	while [[ $# -gt 0 ]]; do
		case "$1" in
		--base-url)
			AUTH_BASE_URL="${2:-}"
			shift 2
			;;
		--cpf)
			AUTH_CPF="${2:-}"
			shift 2
			;;
		--password)
			AUTH_PASSWORD="${2:-}"
			shift 2
			;;
		--password-file)
			AUTH_PASSWORD_FILE="${2:-}"
			shift 2
			;;
		--raw)
			OUTPUT_FORMAT="raw"
			shift
			;;
		--header)
			OUTPUT_FORMAT="header"
			shift
			;;
		--export)
			OUTPUT_FORMAT="export"
			shift
			;;
		-h | --help)
			usage
			exit 0
			;;
		*)
			usage >&2
			fail "opcao invalida: $1"
			;;
		esac
	done
}

token_payload() {
	local cpf="$1"
	local password="$2"

	jq -nc --arg cpf "${cpf}" --arg password "${password}" '{cpf: $cpf, password: $password}'
}

request_token() {
	local base_url="$1"
	local cpf="$2"
	local password="$3"
	local response_file status token

	response_file="$(mktemp)"
	trap 'rm -f "${response_file}"' EXIT

	status="$(
		token_payload "${cpf}" "${password}" |
			curl --silent --show-error --location \
				--request POST "${base_url}/auth/token" \
				--header "Content-Type: application/json" \
				--header "Accept: application/json" \
				--data-binary @- \
				--output "${response_file}" \
				--write-out '%{http_code}'
	)"

	if [[ "${status}" != "200" ]]; then
		printf '[oficina-platform] resposta de /auth/token (%s):\n' "${status}" >&2
		jq . "${response_file}" >&2 2>/dev/null || sed -n '1,20p' "${response_file}" >&2
		fail "falha ao gerar token"
	fi

	token="$(jq -r '.access_token // empty' "${response_file}")"
	[[ -n "${token}" ]] || fail "access_token nao retornado pela auth-lambda"

	printf '%s' "${token}"
}

print_token() {
	local token="$1"

	case "${OUTPUT_FORMAT}" in
	header)
		printf 'Authorization: Bearer %s\n' "${token}"
		;;
	raw)
		printf '%s\n' "${token}"
		;;
	export)
		printf 'export AUTH_TOKEN=%q\n' "${token}"
		;;
	*)
		fail "OUTPUT_FORMAT deve ser header, raw ou export"
		;;
	esac
}

parse_args "$@"
require_cmd curl
require_cmd jq

[[ -n "${AUTH_CPF}" ]] || fail "CPF nao informado"

auth_base_url="$(resolve_auth_base_url)"
auth_password="$(read_password)"
access_token="$(request_token "${auth_base_url}" "${AUTH_CPF}" "${auth_password}")"

print_token "${access_token}"
