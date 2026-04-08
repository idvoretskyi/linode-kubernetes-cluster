# Retrieve the system username to use as a default cluster name prefix
data "external" "username" {
  program = ["sh", "-c", "echo '{\"username\":\"'$(whoami)'\"}'"]
}

locals {
  # Cluster naming: use provided prefix or fall back to system username
  cluster_prefix = var.cluster_name_prefix != "" ? var.cluster_name_prefix : replace(lower(data.external.username.result.username), "/[^a-z0-9-]/", "-")

  common_tags = concat(var.tags, [
    "managed-by:opentofu",
    "owner:${local.cluster_prefix}"
  ])

  # Kubeconfig parsing - decoded once and reused by providers, cluster, and merge resource
  kubeconfig_decoded = yamldecode(base64decode(linode_lke_cluster.cluster.kubeconfig))
  cluster_host       = local.kubeconfig_decoded.clusters[0].cluster.server
  cluster_token      = local.kubeconfig_decoded.users[0].user.token
  cluster_ca_cert    = base64decode(local.kubeconfig_decoded.clusters[0].cluster["certificate-authority-data"])
}
