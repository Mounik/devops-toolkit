# 🛠️ DevOps Toolkit

**Production-ready Ansible playbooks, shell scripts, and CI/CD pipelines** for Linux server hardening, Docker management, monitoring, and automation.

Collected and battle-tested from 7+ years of sysadmin & DevOps work.

## 📂 What's Inside

### 🔒 Ansible Playbooks

| Playbook | Description |
|----------|-------------|
| [hardening](./ansible/hardening/) | Full Linux server hardening (SSH, firewall, auditd, sysctl) |
| [docker-install](./ansible/docker-install/) | Install Docker + Compose on Debian/Ubuntu |
| [monitoring-setup](./ansible/monitoring-setup/) | Deploy Prometheus node exporter + Grafana agent |
| [backup](./ansible/backup/) | Automated backup with restic + cron |

### 📜 Shell Scripts

| Script | Description |
|--------|-------------|
| [server-init.sh](./scripts/server-init.sh) | New server bootstrap (user, SSH keys, updates, Docker) |
| [docker-cleanup.sh](./scripts/docker-cleanup.sh) | Safe Docker system cleanup (images, volumes, builder cache) |
| [ssl-check.sh](./scripts/ssl-check.sh) | Check SSL certificate expiry for domains |
| [backup-db.sh](./scripts/backup-db.sh) | PostgreSQL/MySQL backup with rotation |
| [health-check.sh](./scripts/health-check.sh) | Comprehensive server health report |

### 🔄 CI/CD Pipelines

| Pipeline | Platform | Description |
|----------|----------|-------------|
| [docker-build](./ci/docker-build/) | GitHub Actions | Build, tag & push Docker images with multi-arch |
| [deploy-ansible](./ci/deploy-ansible/) | GitHub Actions | Run Ansible playbooks from CI |
| [lint-and-test](./ci/lint-and-test/) | GitLab CI | Lint + test for shell/Ansible/YAML |

### 🐳 Docker Utilities

| Utility | Description |
|---------|-------------|
| [compose-template](./docker/compose-template/) | Template docker-compose with best practices |
| [healthcheck-images](./docker/healthcheck-images/) | Dockerfiles with proper health checks |

## 🚀 Quick Start

### Run a playbook

```bash
# Hardening a new server
ansible-playbook ansible/hardening/main.yml -i inventory.ini --limit production

# Install Docker
ansible-playbook ansible/docker-install/main.yml -i inventory.ini
```

### Run a script

```bash
# Bootstrap a fresh server
curl -sL https://raw.githubusercontent.com/Mounik/devops-toolkit/main/scripts/server-init.sh | bash

# Docker cleanup (safe, doesn't remove running containers)
bash scripts/docker-cleanup.sh
```

### Use CI/CD templates

Copy the workflow files into your `.github/workflows/` or `.gitlab-ci.yml`.

## 📁 Structure

```
devops-toolkit/
├── ansible/
│   ├── hardening/
│   │   ├── main.yml
│   │   ├── tasks/
│   │   ├── defaults/
│   │   └── README.md
│   ├── docker-install/
│   ├── monitoring-setup/
│   └── backup/
├── scripts/
│   ├── server-init.sh
│   ├── docker-cleanup.sh
│   ├── ssl-check.sh
│   ├── backup-db.sh
│   └── health-check.sh
├── ci/
│   ├── docker-build/
│   ├── deploy-ansible/
│   └── lint-and-test/
├── docker/
│   ├── compose-template/
│   └── healthcheck-images/
└── README.md
```

## 🔒 Security

All playbooks follow CIS Benchmark guidelines where applicable. The hardening playbook includes:

- SSH key-only authentication
- Fail2ban configuration
- UFW firewall rules
- Sysctl hardening (sysctl.conf)
- Auditd rules
- Automatic security updates

## 🤝 Contributing

PRs welcome! Each contribution should include:
- Working test/playbook run output
- Updated README if adding new functionality

## 📜 License

MIT