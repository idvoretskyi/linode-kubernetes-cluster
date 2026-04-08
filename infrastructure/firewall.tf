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
      ipv4     = var.firewall_allowed_ips
    }
  }

  inbound_policy  = var.firewall_inbound_policy
  outbound_policy = var.firewall_outbound_policy
  linodes         = flatten([for pool in linode_lke_cluster.cluster.pool : [for node in pool.nodes : node.instance_id]])
  depends_on      = [linode_lke_cluster.cluster]
}
