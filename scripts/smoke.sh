#!/usr/bin/env bash

set -euo pipefail

if ! command -v docker >/dev/null 2>&1; then
  echo "docker is required for smoke checks."
  exit 1
fi

if ! command -v rg >/dev/null 2>&1; then
  echo "rg is required for smoke checks."
  exit 1
fi

if ! docker compose ps --services --filter status=running | rg -q '^web$'; then
  echo "web service is not running. Start the stack first (for example: make bootstrap)."
  exit 1
fi

fetch_url() {
  local url="$1"
  if command -v curl >/dev/null 2>&1; then
    curl -fsS "$url"
    return
  fi

  if command -v wget >/dev/null 2>&1; then
    wget -qO- "$url"
    return
  fi

  echo "Neither curl nor wget is available."
  return 1
}

echo "Checking /ping endpoint ..."
for _ in $(seq 1 20); do
  if fetch_url "http://localhost:8080/ping" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

fetch_url "http://localhost:8080/ping" >/dev/null

echo "Checking WordPress login page ..."
login_page="$(fetch_url "http://localhost:8080/wp/wp-login.php")"
if ! printf '%s' "$login_page" | rg -qi "user_login|wordpress"; then
  echo "Unexpected response from wp-login page."
  exit 1
fi

echo "Checking WP installation state ..."
run_user="$(id -u 2>/dev/null || echo 1000):$(id -g 2>/dev/null || echo 1000)"
docker compose --profile tools run --rm --user "$run_user" wp --path=web/wp core is-installed >/dev/null

echo "Smoke checks passed."

