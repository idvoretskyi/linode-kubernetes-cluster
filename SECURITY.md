# Security Policy

## Supported Versions

This repository provides an OpenTofu template, not a versioned product. The `main` branch represents the current recommended configuration. Security fixes are applied to `main` only.

## Reporting a Vulnerability

If you discover a security vulnerability in this repository — including insecure default configurations, exposed secrets, or IaC patterns that could lead to a compromised cluster — please report it responsibly.

**Do not open a public GitHub issue for security vulnerabilities.**

### Preferred method: GitHub Security Advisories

1. Go to the [Security Advisories](https://github.com/idvoretskyi/linode-kubernetes-cluster/security/advisories) tab.
2. Click **New draft security advisory**.
3. Fill in the title, description, affected component, and (if known) a suggested fix.
4. Submit the draft. It will be visible only to repository maintainers until disclosed.

### Response timeline

| Stage | Target |
|---|---|
| Initial acknowledgement | Within 72 hours |
| Triage and severity assessment | Within 7 days |
| Fix or mitigation published | Within 30 days for HIGH/CRITICAL |
| Public disclosure | After fix is available, or 90 days from report (whichever comes first) |

## Scope

In-scope for this policy:

- Insecure default variable values (e.g., overly permissive firewall rules)
- Secrets or credentials inadvertently committed or exposed via outputs
- IaC patterns that grant excessive RBAC permissions
- Pod Security or NetworkPolicy misconfigurations introduced by this template
- CI/CD workflow vulnerabilities (e.g., unpinned actions, secret exposure)

Out of scope:

- Vulnerabilities in upstream Helm charts (report to the respective project)
- Vulnerabilities in the Linode/Akamai control plane (report to [Akamai Bug Bounty](https://www.akamai.com/legal/compliance/bug-bounty))
- Vulnerabilities in OpenTofu itself (report to [OpenTofu Security](https://opentofu.org/docs/intro/community/))

## Security Defaults

This template is designed with secure defaults:

- Firewall `inbound_policy = DROP` with explicit allow rules
- Pod Security Standards (`baseline` enforce, `restricted` audit/warn) on all add-on namespaces
- Default-deny NetworkPolicies for monitoring and opencost namespaces
- node-exporter disabled by default (avoids privileged host access)
- `grafana_admin_password` is `sensitive = true` and flagged for change

See [docs/security/cis-compliance.md](docs/security/cis-compliance.md) for the full CIS Kubernetes Benchmark mapping.
