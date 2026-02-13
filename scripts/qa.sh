#!/usr/bin/env bash

set -euo pipefail

echo "== QA: Composer checks =="
composer validate --strict
composer lint
composer audit

docker_available=false
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  docker_available=true
fi

if [[ "$docker_available" == "false" ]]; then
  echo "== QA: Docker checks skipped =="
  echo "Docker CLI/daemon is not available. Skipping doctor/smoke-full."
  if [[ "${QA_DOCKER_REQUIRED:-0}" == "1" ]]; then
    echo "QA_DOCKER_REQUIRED=1 is set; failing because Docker is unavailable."
    exit 1
  fi
  exit 0
fi

echo "== QA: Docker checks =="
make smoke-full

