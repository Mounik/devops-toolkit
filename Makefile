.PHONY: install lint test syntax-check shellcheck yamllint ansible-lint molecule molecule-test pre-commit-install help

ANSIBLE_DIRS    = ansible/
SCRIPTS_DIR     = scripts/
COLLECTIONS     = requirements.yml

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

install: ## Install Ansible collections
	ansible-galaxy collection install -r $(COLLECTIONS)

pre-commit-install: ## Install pre-commit hooks
	pre-commit install

lint: shellcheck yamllint ansible-lint ## Run all linters

shellcheck: ## Lint shell scripts
	shellcheck -x $(SCRIPTS_DIR)*.sh

yamllint: ## Lint YAML files
	yamllint -d relaxed $(ANSIBLE_DIRS) ci/ docker/

ansible-lint: ## Lint Ansible playbooks
	ansible-lint $(ANSIBLE_DIRS)

syntax-check: ## Ansible playbook syntax check
	@for pb in $(ANSIBLE_DIRS)*/main.yml; do \
		echo "==> Checking $$pb"; \
		ansible-playbook --syntax-check "$$pb" || exit 1; \
	done

test: lint syntax-check ## Run all checks

molecule: ## Run Molecule tests (default: hardening)
	cd ansible/hardening && molecule test

molecule-test: ## Run Molecule test for a specific playbook (usage: make molecule-test PLAYBOOK=backup)
	cd ansible/$(or $(PLAYBOOK),hardening) && molecule test