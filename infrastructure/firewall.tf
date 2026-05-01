resource "linode_firewall" "cluster_firewall" {
  count = var.firewall_enabled ? 1 : 0
  label = "${local.cluster_prefix}-lke-firewall"
  tags  = local.common_tags

  inbound {
    label    = "allow-kubectl"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "443"
    ipv4     = var.allowed_kubectl_ips
  }

  inbound {
    label    = "allow-monitoring-ui"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "80,443,3000,9090"
    ipv4     = var.allowed_monitoring_ips
  }

  inbound {
    label    = "allow-kubelet-metrics"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "10250"
    ipv4     = ["0.0.0.0/0"]
  }

  dynamic "inbound" {
    for_each = var.firewall_enable_nodeports ? [1] : []
    content {
      label    = "allow-nodeports"
      action   = "ACCEPT"
      protocol = "TCP"
      ports    = "30000-32767"
      ipv4     = var.allowed_kubectl_ips
    }
  }

  inbound_policy  = "DROP"
  outbound_policy = "ACCEPT"
  linodes         = flatten([for pool in linode_lke_cluster.cluster.pool : [for node in pool.nodes : node.instance_id]])
  depends_on      = [linode_lke_cluster.cluster]
}

# Emit a non-blocking advisory when firewall IPs are left open to the world.
# OpenTofu preconditions are pass/fail only; this local-exec approach prints a
# visible warning without failing the apply — keeping zero-config defaults intact.
resource "terraform_data" "firewall_open_ip_warning" {
  count = var.firewall_enabled ? 1 : 0

  triggers_replace = [
    join(",", var.allowed_kubectl_ips),
    join(",", var.allowed_monitoring_ips),
  ]

  provisioner "local-exec" {
    interpreter = ["/bin/sh", "-c"]
    command     = <<-EOT
      warn=0
      for cidr in ${join(" ", var.allowed_kubectl_ips)} ${join(" ", var.allowed_monitoring_ips)}; do
        if [ "$cidr" = "0.0.0.0/0" ] || [ "$cidr" = "::/0" ]; then
          warn=1
        fi
      done
      if [ "$warn" = "1" ]; then
        echo ""
        echo "WARNING: One or more firewall allow-lists contain 0.0.0.0/0 or ::/0."
        echo "         This exposes kubectl API and/or monitoring UIs to the public internet."
        echo "         Set allowed_kubectl_ips and allowed_monitoring_ips to your actual CIDRs"
        echo "         before promoting this cluster to production."
        echo ""
      fi
    EOT
  }

  depends_on = [linode_firewall.cluster_firewall]
}
