SHELL := /usr/bin/env bash

COMPOSE ?= docker compose
RUN_USER ?= $(shell id -u 2>/dev/null || echo 1000):$(shell id -g 2>/dev/null || echo 1000)

.PHONY: help install composer-install up down restart ps logs shell up-mail up-dbadmin up-observability wp composer
.PHONY: bootstrap env wait wp-install up-tls bootstrap-tls certs-mkcert up-tls-trusted bootstrap-tls-trusted doctor

help: ## Show available targets
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z0-9_.-]+:.*##/ {printf "\033[36m%-22s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

env: ## Create .env from .env.example if missing
	@if [ -f .env ]; then echo ".env exists"; else cp .env.example .env && echo "Created .env from .env.example"; fi

doctor: ## Preflight checks (docker, compose, ports, env, optional mkcert)
	@bash scripts/doctor.sh

up: ## Start dev stack (build + up)
	$(COMPOSE) up -d --build

install: ## Install deps (Composer) then start stack
	$(MAKE) composer-install
	$(MAKE) up

wait: ## Wait for php-fpm ping via Nginx
	@echo "Waiting for http://localhost:8080/ping ..."
	@for i in $$(seq 1 60); do \
		if command -v curl >/dev/null 2>&1; then \
			curl -fsS http://localhost:8080/ping >/dev/null 2>&1 && echo "Ready" && exit 0; \
		else \
			wget -qO- http://localhost:8080/ping >/dev/null 2>&1 && echo "Ready" && exit 0; \
		fi; \
		sleep 1; \
	done; \
	echo "Timed out waiting for web/php"; \
	exit 1

bootstrap: ## One-command local bootstrap (env + deps + up + wait + wp-install)
	$(MAKE) env
	$(MAKE) composer-install
	$(MAKE) up
	$(MAKE) wait
	$(MAKE) wp-install

up-tls: ## Start dev stack + local TLS proxy (https://wp.localhost:8443)
	$(COMPOSE) --profile tls up -d --build

bootstrap-tls: ## Bootstrap stack + local TLS proxy (requires WP_HOME/WP_SITEURL set to https://wp.localhost:8443)
	$(MAKE) env
	$(MAKE) composer-install
	$(MAKE) up-tls
	$(MAKE) wait
	$(MAKE) wp-install

certs-mkcert: ## Generate trusted local certs for wp.localhost using mkcert
	@command -v mkcert >/dev/null 2>&1 || { echo "mkcert not found. Install it first: https://github.com/FiloSottile/mkcert"; exit 1; }
	@mkdir -p .certs
	@mkcert -install
	@mkcert -cert-file .certs/wp.localhost.pem -key-file .certs/wp.localhost-key.pem wp.localhost
	@echo "Generated .certs/wp.localhost.pem and .certs/wp.localhost-key.pem"

up-tls-trusted: ## Start dev stack + trusted local TLS proxy (mkcert)
	$(COMPOSE) --profile tls-trusted up -d --build

bootstrap-tls-trusted: ## Bootstrap stack + trusted local TLS (runs mkcert first)
	$(MAKE) env
	$(MAKE) certs-mkcert
	$(MAKE) composer-install
	$(MAKE) up-tls-trusted
	$(MAKE) wait
	$(MAKE) wp-install

down: ## Stop dev stack
	$(COMPOSE) down --remove-orphans

restart: ## Restart dev stack
	$(COMPOSE) restart

ps: ## Show container status
	$(COMPOSE) ps

logs: ## Tail logs (set SERVICE=... to filter)
	@if [ -n "$(SERVICE)" ]; then $(COMPOSE) logs -f --tail=200 "$(SERVICE)"; else $(COMPOSE) logs -f --tail=200; fi

shell: ## Shell into PHP container
	$(COMPOSE) exec php sh

up-mail: ## Start stack with MailHog profile
	$(COMPOSE) --profile mail up -d --build

up-dbadmin: ## Start stack with phpMyAdmin profile
	$(COMPOSE) --profile dbadmin up -d --build

up-observability: ## Start stack with exporters profile
	$(COMPOSE) --profile observability up -d --build

wp: ## Run WP-CLI (example: make wp ARGS="core version")
	$(COMPOSE) --profile tools run --rm --user "$(RUN_USER)" wp $(ARGS)

composer: ## Run Composer in a container (example: make composer ARGS="install")
	$(COMPOSE) --profile tools run --rm --user "$(RUN_USER)" composer $(ARGS)

composer-install: ## Install Composer deps into the working tree
	$(COMPOSE) --profile tools run --rm --user "$(RUN_USER)" composer install --no-interaction --no-progress

wp-install: ## Install WordPress if not already installed (local dev)
	@set -euo pipefail; \
	if [ ! -f .env ]; then echo "Missing .env (run: make env)"; exit 1; fi; \
	set -a; . ./.env; set +a; \
	URL="$${WP_HOME:-http://localhost:8080}"; \
	TITLE="$${WP_SITE_TITLE:-Boilerplate}"; \
	ADMIN_USER="$${WP_ADMIN_USER:-admin}"; \
	ADMIN_PASSWORD="$${WP_ADMIN_PASSWORD:-admin}"; \
	ADMIN_EMAIL="$${WP_ADMIN_EMAIL:-admin@example.com}"; \
	$(COMPOSE) --profile tools run --rm --user "$(RUN_USER)" wp --path=web/wp core is-installed >/dev/null 2>&1 || \
	$(COMPOSE) --profile tools run --rm --user "$(RUN_USER)" wp --path=web/wp core install \
		--url="$$URL" \
		--title="$$TITLE" \
		--admin_user="$$ADMIN_USER" \
		--admin_password="$$ADMIN_PASSWORD" \
		--admin_email="$$ADMIN_EMAIL" \
		--skip-email

