# CIS Kubernetes Benchmark — Compliance Reference

> **Benchmark version:** CIS Kubernetes Benchmark v1.10
> **Cluster:** Linode LKE (managed Kubernetes)
> **IaC:** OpenTofu

## Scope

Linode LKE is a managed Kubernetes service. The control plane (API server, etcd, controller-manager, scheduler) is fully managed by Akamai/Linode and is not accessible to cluster operators. This means:

- **CIS Sections 1–4** (control plane, etcd, control plane configuration, worker node configuration) are **Linode's responsibility** and cannot be configured via this repo.
- **CIS Section 5** (Policies: RBAC, Pod Security, Network Policies, Secrets) is **operator-configurable** and is the focus of this document.

---

## Section 5 — Policies

### 5.1 RBAC and Service Accounts

| Control | ID | Status | Implementation |
|---|---|---|---|
| Ensure cluster-admin is only used where required | 5.1.1 | Linode-managed | LKE does not grant cluster-admin to workloads by default |
| Minimize access to secrets | 5.1.2 | Upstream Helm | kube-prometheus-stack + opencost create scoped RBAC; no wildcard secret access |
| Minimize wildcard use in Roles and ClusterRoles | 5.1.3 | Upstream Helm | Helm charts use targeted RBAC; reviewed at install |
| Minimize access to create pods | 5.1.4 | Upstream Helm | No workload chart grants pod-create cluster-wide |
| Ensure default service accounts are not bound to active roles | 5.1.5 | Default K8s | Default SAs are not bound by this configuration |
| Ensure service account tokens are not auto-mounted where unnecessary | 5.1.6 | Upstream Helm | Charts set `automountServiceAccountToken: false` where applicable |

### 5.2 Pod Security Standards

| Control | ID | Status | Implementation |
|---|---|---|---|
| Ensure PSP/PSS is in use | 5.2.1 | **Enforced** | PSS labels applied to `monitoring` and `opencost` namespaces via OpenTofu |
| Minimize the admission of privileged containers | 5.2.2 | **Enforced** | `enforce: baseline` blocks privileged containers by default |
| Minimize the admission of containers wishing to share the host process ID namespace | 5.2.3 | **Enforced** | Blocked by PSS `baseline` |
| Minimize the admission of containers wishing to share the host IPC namespace | 5.2.4 | **Enforced** | Blocked by PSS `baseline` |
| Minimize the admission of containers wishing to share the host network namespace | 5.2.5 | **Enforced** | Blocked by PSS `baseline` (node-exporter disabled by default) |
| Minimize the admission of containers with allowPrivilegeEscalation | 5.2.6 | **Audit/Warn** | `audit: restricted` + `warn: restricted` surfaces violations |
| Minimize the admission of root containers | 5.2.7 | **Audit/Warn** | `audit: restricted` + `warn: restricted` |
| Minimize the admission of containers with added capabilities | 5.2.8 | **Audit/Warn** | `audit: restricted` + `warn: restricted` |
| Minimize the admission of containers with hostPath volumes | 5.2.9 | **Enforced** | Blocked by PSS `baseline` (node-exporter disabled by default) |

**PSS label configuration:**

```hcl
# monitoring and opencost namespaces — applied by OpenTofu
pod-security.kubernetes.io/enforce = "baseline"   # blocks policy violations
pod-security.kubernetes.io/audit   = "restricted" # logs restricted violations
pod-security.kubernetes.io/warn    = "restricted" # warns on restricted violations
```

When `monitoring_enable_node_exporter = true`, the `monitoring` namespace `enforce` label is downgraded to `privileged` automatically (node-exporter requires `hostNetwork`, `hostPID`, and `hostPath`). The `audit` and `warn` labels remain at `restricted` so violations are still visible.

### 5.3 Network Policies and CNI

| Control | ID | Status | Implementation |
|---|---|---|---|
| Ensure network policies are in place | 5.3.1 | **Enforced** | `install_network_policies = true` (default) deploys default-deny + selective allow policies |
| Ensure all namespaces have network policies defined | 5.3.2 | **Enforced** | `monitoring` and `opencost` namespaces get default-deny ingress + egress; allows scoped to known traffic patterns |

**Network policies applied (when `install_network_policies = true`):**

| Policy | Namespace | Effect |
|---|---|---|
| `default-deny-all` | `monitoring` | Deny all ingress + egress |
| `allow-intra-namespace` | `monitoring` | Allow pod-to-pod within namespace |
| `allow-dns-egress` | `monitoring` | Allow UDP/TCP 53 to any (CoreDNS) |
| `allow-kube-api-egress` | `monitoring` | Allow Prometheus → K8s API (443/6443) |
| `allow-ui-ingress` | `monitoring` | Allow ingress on 80/443/3000/9090 |
| `default-deny-all` | `opencost` | Deny all ingress + egress |
| `allow-prometheus-egress` | `opencost` | Allow OpenCost → Prometheus (9090) |
| `allow-dns-egress` | `opencost` | Allow UDP/TCP 53 to any |
| `allow-ui-ingress` | `opencost` | Allow ingress on 9090/9003 |

CNI: LKE uses **Calico**, which fully enforces `NetworkPolicy` resources.

### 5.4 Secrets Management

| Control | ID | Status | Implementation |
|---|---|---|---|
| Prefer using Secrets as files over Secrets as environment variables | 5.4.1 | Upstream Helm | Reviewed at chart install; not overridden |
| Consider external secret management | 5.4.2 | Out of scope | Recommended for production; not part of this template |

`grafana_admin_password` is marked `sensitive = true` in OpenTofu — it is never echoed in plan/apply output. The default value `"admin"` is clearly flagged for change in the example vars file and README.

### 5.5 Extensible Admission Control

| Control | ID | Status | Implementation |
|---|---|---|---|
| Configure image provenance | 5.5.1 | Out of scope | Requires admission webhook (e.g., Kyverno, OPA Gatekeeper) — beyond baseline scope |

### 5.7 General Policies

| Control | ID | Status | Implementation |
|---|---|---|---|
| Create administrative boundaries between resources using namespaces | 5.7.1 | **Enforced** | Separate namespaces for `monitoring` and `opencost` with distinct PSS labels |
| Ensure seccomp profile is set to docker/default or runtime/default | 5.7.2 | **Audit/Warn** | Surfaced via PSS `warn: restricted` |
| Apply Security Context to pods and containers | 5.7.3 | **Audit/Warn** | Surfaced via PSS `audit: restricted` + `warn: restricted` |
| Ensure default namespace is not actively used | 5.7.4 | Convention | All add-ons deploy to dedicated namespaces; no workloads in `default` |

---

## Linode-Managed Controls (Sections 1–4)

The following CIS sections apply to control plane components that Akamai/Linode manages on behalf of LKE customers. They are listed here for completeness and auditability.

| Section | Scope | Responsibility |
|---|---|---|
| 1 — Control Plane Node Configuration Files | kube-apiserver, etcd, scheduler, controller-manager config files | Linode |
| 2 — Etcd Node Configuration | etcd TLS, auth, data encryption | Linode |
| 3 — Control Plane Configuration | API server flags, admission plugins, audit logging | Linode |
| 4 — Worker Node Security Configuration | kubelet config, file permissions | Linode (node images) |

For details on Linode's shared-responsibility posture, see the [Akamai Cloud Security documentation](https://www.linode.com/docs/products/compute/kubernetes/).

---

## Running a Compliance Scan

To scan the IaC configuration locally:

```bash
# Blocking: fail on CRITICAL or HIGH findings
trivy config --severity CRITICAL,HIGH --exit-code 1 infrastructure/

# Informational: surface MEDIUM findings without failing
trivy config --severity MEDIUM --exit-code 0 infrastructure/
```

CI runs both passes automatically on every pull request and weekly schedule (`.github/workflows/security.yml`).
