# Contributing to DevOps Toolkit

Merci d'envisager de contribuer ! Ce repo est aussi un portfolio professionnel — chaque PR doit maintenir ce standard.

## Development Workflow

### 1. Setup

```bash
make setup      # Install pre-commit, linters
make lint       # Run all linters locally
make test       # Run Molecule tests
```

### 2. Pre-commit Hooks

```bash
pre-commit run --all-files
```

### 3. Commit Convention

We follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(terraform): add bastion host module
fix(ansible): correct sysctl typo
docs(readme): update architecture diagram
ci(github): add trivy scan
test(molecule): add auditd verification
```

### 4. Code Quality Gates

| Check            | Tool           | Fail? |
|-------------------|----------------|-------|
| Shell scripts     | shellcheck     | ✅   |
| Ansible playbooks | ansible-lint   | ✅   |
| YAML files        | yamllint       | ✅   |
| Dockerfiles       | hadolint       | ✅   |
| Terraform         | fmt + validate | ✅   |
| Security          | trivy          | ✅   |

### 5. PR Checklist

- [ ] `make all` passes locally
- [ ] ansible-lint returns 0 violations
- [ ] shellcheck clean (warnings accepted with justification)
- [ ] New code has comments for non-obvious logic
- [ ] README updated if adding new component
- [ ] Terraform README generated (`terraform-docs`)

## Directory Structure

```
devops-toolkit/
├── ansible/          # IaC with Ansible
├── terraform/        # IaC with Terraform
├── kubernetes/       # K8s manifests + Helm charts
├── docker/           # Docker/Compose templates
├── ci/               # CI/CD pipeline templates
└── scripts/          # Standalone shell utilities
```

## Contact

- Discussions: GitHub Discussions
- Urgent: mention @Mounik in issues
