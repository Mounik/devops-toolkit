# Security Policy

## Supported Versions

| Version | Status       | Notes               |
|---------|--------------|---------------------|
| >= 1.0  | ✅ Supported | Active maintenance   |
| < 1.0   | ❌ EOL        | Upgrade recommended  |

## Security Architecture Decisions

This project follows defense-in-depth principles:

- **Ansible**: Idempotent, least-privilege, check mode support
- **Terraform**: Encrypted root volumes, IMDSv2 enforced, no hardcoded secrets
- **Kubernetes**: Non-root containers, read-only root FS, NetworkPolicies, PodSecurityStandards restricted
- **Docker**: Distroless/minimal images, no root, health checks, resource limits
- **Scripts**: `set -euo pipefail`, quoted variables, no eval

## Secrets Management

Never commit secrets. Use:
- Ansible Vault for playbook variables
- AWS Secrets Manager / Parameter Store for Terraform
- Kubernetes Sealed Secrets / External Secrets Operator for K8s

## Reporting a Vulnerability

If you discover a security issue:

1. **Do NOT** open a public issue
2. Email security@mounik.dev (replace with real contact)
3. Include repro steps and potential impact
4. Expect initial response within 48h
5. Coordinated disclosure timeline: 90 days

## Compliance Notes

Playbooks reference CIS Benchmarks but are not CIS-certified. Always audit in your environment.
