SHELL := /usr/bin/env bash

COMPOSE ?= docker compose
RUN_USER ?= $(shell id -u 2>/dev/null || echo 1000):$(shell id -g 2>/dev/null || echo 1000)

.PHONY: help install composer-install up down restart ps logs shell up-mail up-dbadmin up-observability wp composer

help: ## Show available targets
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z0-9_.-]+:.*##/ {printf "\033[36m%-22s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

up: ## Start dev stack (build + up)
	$(COMPOSE) up -d --build

install: ## Install deps (Composer) then start stack
	$(MAKE) composer-install
	$(MAKE) up

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

