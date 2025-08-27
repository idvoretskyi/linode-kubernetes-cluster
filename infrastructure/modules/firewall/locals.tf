# Generate common firewall rules based on variables
locals {
  # Common rules for Kubernetes clusters
  common_inbound_rules = concat(
    var.enable_ssh ? [{
      label    = "ssh"
      action   = "ACCEPT"
      protocol = "TCP"
      ports    = "22"
      ipv4     = var.allowed_ips
      ipv6     = []
    }] : [],
    
    var.enable_http ? [{
      label    = "http"
      action   = "ACCEPT"
      protocol = "TCP"
      ports    = "80"
      ipv4     = var.allowed_ips
      ipv6     = []
    }] : [],
    
    var.enable_https ? [{
      label    = "https"
      action   = "ACCEPT"
      protocol = "TCP"
      ports    = "443"
      ipv4     = var.allowed_ips
      ipv6     = []
    }] : [],
    
    var.enable_k8s_api ? [{
      label    = "k8s-api"
      action   = "ACCEPT"
      protocol = "TCP"
      ports    = "6443"
      ipv4     = var.allowed_ips
      ipv6     = []
    }] : [],
    
    var.enable_nodeports ? [{
      label    = "nodeport"
      action   = "ACCEPT"
      protocol = "TCP"
      ports    = "30000-32767"
      ipv4     = var.allowed_ips
      ipv6     = []
    }] : []
  )

  # Combine common rules with custom rules
  final_inbound_rules = concat(local.common_inbound_rules, var.inbound_rules)
}