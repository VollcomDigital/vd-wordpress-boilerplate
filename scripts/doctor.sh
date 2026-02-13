#!/usr/bin/env bash

set -euo pipefail

errors=()
warnings=()

add_error() {
  errors+=("$1")
}

add_warning() {
  warnings+=("$1")
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    add_error "Missing required command: $cmd"
  fi
}

check_port_free() {
  local port="$1"
  local label="$2"
  local severity="${3:-error}"

  if ! command -v ss >/dev/null 2>&1; then
    add_warning "Cannot check port $port ($label): 'ss' command not found."
    return
  fi

  if ss -ltnH "sport = :$port" | grep -q .; then
    if [[ "$severity" == "warning" ]]; then
      add_warning "Port $port is already in use ($label)."
    else
      add_error "Port $port is already in use ($label)."
    fi
  fi
}

print_section() {
  local title="$1"
  printf "\n== %s ==\n" "$title"
}

print_section "WordPress Boilerplate Doctor"

require_cmd docker
require_cmd make

if command -v docker >/dev/null 2>&1; then
  if ! docker info >/dev/null 2>&1; then
    add_error "Docker daemon is not reachable (is Docker running?)."
  fi

  if ! docker compose version >/dev/null 2>&1; then
    add_error "Docker Compose v2 plugin is not available (docker compose)."
  fi
fi

if ! command -v mkcert >/dev/null 2>&1; then
  add_warning "mkcert not found (only needed for trusted local TLS profile)."
fi

if [[ ! -f ".env" ]]; then
  add_warning ".env is missing. Run: cp .env.example .env"
else
  wp_home="$(awk -F= '/^WP_HOME=/{print $2; exit}' .env | tr -d '\r' || true)"
  wp_siteurl="$(awk -F= '/^WP_SITEURL=/{print $2; exit}' .env | tr -d '\r' || true)"

  if [[ -z "$wp_home" ]]; then
    add_warning "WP_HOME is not set in .env."
  fi

  if [[ -z "$wp_siteurl" ]]; then
    add_warning "WP_SITEURL is not set in .env."
  fi

  if [[ "$wp_home" == "https://wp.localhost:8443" ]]; then
    if [[ ! -f ".certs/wp.localhost.pem" || ! -f ".certs/wp.localhost-key.pem" ]]; then
      add_warning "Trusted TLS is configured but cert files are missing. Run: make certs-mkcert"
    fi
  fi
fi

check_port_free 8080 "local HTTP (web)"
check_port_free 8443 "local HTTPS (caddy profile)" warning
check_port_free 8081 "phpMyAdmin profile" warning
check_port_free 8025 "MailHog profile" warning

print_section "Summary"

if ((${#errors[@]} > 0)); then
  printf "Errors:\n"
  for message in "${errors[@]}"; do
    printf "  - %s\n" "$message"
  done
fi

if ((${#warnings[@]} > 0)); then
  printf "Warnings:\n"
  for message in "${warnings[@]}"; do
    printf "  - %s\n" "$message"
  done
fi

if ((${#errors[@]} == 0)); then
  printf "Doctor checks passed.\n"
  if ((${#warnings[@]} > 0)); then
    printf "Proceed with caution and review warnings above.\n"
  fi
  exit 0
fi

printf "Doctor checks failed. Fix errors before running bootstrap.\n"
exit 1

