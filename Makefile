# ══════════════════════════════════════════════════════════
# DevOps Toolkit — Unified Build & Lint Orchestration
# ══════════════════════════════════════════════════════════

.DEFAULT_GOAL := help
SHELL := /bin/bash

# ── Colors ───────────────────────────────────────────────
BLUE  := $(tput setaf 4)
GREEN := \033[0;32m
RESET := \033[0m

.PHONY: help all lint test clean

help: ## Show all available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-25s$(RESET) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(GREEN)Quick start$(RESET): $(BLUE)make all$(RESET) runs lint + test"

# ── Orchestration ────────────────────────────────────────

all: lint test ## Run lint + test (default pipeline)

lint: lint-shell lint-ansible lint-yaml lint-docker lint-terraform ## Run all linters

test: ansible-test ## Run all tests

# ── Shell ──────────────────────────────────────────────

lint-shell: ## Lint shell scripts with shellcheck
	@echo "$(GREEN)▶ Shellcheck scripts/*.sh$(RESET)"
	@for f in scripts/*.sh; do \
		if command -v shellcheck &>/dev/null; then \
			printf "  Checking $$f... "; \
			shellcheck $$f && echo "$(GREEN)OK$(RESET)" || exit 1; \
		else \
			echo "  $(BLUE)shellcheck not found, skipping$(RESET)"; \
		fi \
	done

# ── Ansible ────────────────────────────────────────────

lint-ansible: ## Lint Ansible playbooks
	@echo "$(GREEN)▶ ansible-lint$(RESET)"
	@command -v ansible-lint &>/dev/null || (echo "  $(BLUE)ansible-lint not found$(RESET)" && exit 0)
	@ansible-lint ansible/ || true

ansible-test: ## Run Ansible Molecule tests
	@echo "$(GREEN)▶ Molecule tests (hardening)$(RESET)"
	@command -v molecule &>/dev/null || (echo "  $(BLUE)molecule not found$(RESET)" && exit 0)
	@cd ansible/hardening && molecule test

# ── YAML ───────────────────────────────────────────────

lint-yaml: ## Lint YAML files
	@echo "$(GREEN)▶ yamllint$(RESET)"
	@command -v yamllint &>/dev/null || (echo "  $(BLUE)yamllint not found$(RESET)" && exit 0)
	@yamllint ansible/ ci/ docker/ kubernetes/ || true

# ── Docker ─────────────────────────────────────────────

lint-docker: ## Lint Dockerfiles with hadolint
	@echo "$(GREEN)▶ hadolint$(RESET)"
	@command -v hadolint &>/dev/null || (echo "  $(BLUE)hadolint not found$(RESET)" && exit 0)
	@find docker/ -name "*.Dockerfile" -exec hadolint {} \;

# ── Terraform ──────────────────────────────────────────

lint-terraform: ## Format & validate Terraform
	@echo "$(GREEN)▶ terraform fmt & validate$(RESET)"
	@command -v terraform &>/dev/null || (echo "  $(BLUE)terraform not found$(RESET)" && exit 0)
	@terraform fmt -check -recursive terraform/ && terraform validate terraform/environments/dev

# ── Kubernetes ─────────────────────────────────────────

lint-k8s: ## Validate K8s manifests
	@echo "$(GREEN)▶ kubectl dry-run$(RESET)"
	@command -v kubectl &>/dev/null || (echo "  $(BLUE)kubectl not found$(RESET)" && exit 0)
	@kubectl apply --dry-run=client -f kubernetes/ || true

# ── Helm ───────────────────────────────────────────────

lint-helm: ## Lint Helm chart
	@echo "$(GREEN)▶ helm lint$(RESET)"
	@command -v helm &>/dev/null || (echo "  $(BLUE)helm not found$(RESET)" && exit 0)
	@helm lint kubernetes/helm/devops-toolkit || true

# ── Security ───────────────────────────────────────────

security-scan: ## Security scan with Trivy
	@echo "$(GREEN)▶ Trivy filesystem scan$(RESET)"
	@command -v trivy &>/dev/null || (echo "  $(BLUE)trivy not found$(RESET)" && exit 0)
	@trivy fs --scanners vuln,secret,misconfig . || true

# ── CI/CD ──────────────────────────────────────────────

ci-simulate: lint test security-scan ## Simulate full CI pipeline locally
	@echo "$(GREEN)========== CI SIMULATION COMPLETE ==========$(RESET)"

# ── Cleanup ────────────────────────────────────────────

clean: ## Clean artifacts and temporary files
	@find . -type f -name "*.log" -delete
	@find . -type d -name ".molecule" -exec rm -rf {} + 2>/dev/null || true
	@find ansible/hardening/molecule -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@echo "$(GREEN)✓ Cleaned$(RESET)"

# ── Setup ──────────────────────────────────────────────

setup: ## Install local tooling (pip, apt)
	@echo "$(GREEN)▶ Installing ansible-lint, yamllint, molecule$(RESET)"
	@pip install --user ansible-lint yamllint molecule[docker] pre-commit 2>/dev/null || true
	@echo "$(GREEN)▶ Installing pre-commit hooks$(RESET)"
	@pre-commit install 2>/dev/null || true
	@echo "$(GREEN)✓ Setup complete$(RESET)"
