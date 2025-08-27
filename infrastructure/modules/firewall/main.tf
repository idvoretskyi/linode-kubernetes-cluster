terraform {
  required_providers {
    linode = {
      source  = "linode/linode"
      version = "~> 2.0"
    }
  }
}

resource "linode_firewall" "cluster_firewall" {
  label           = var.firewall_name
  tags            = var.tags
  inbound_policy  = var.inbound_policy
  outbound_policy = var.outbound_policy

  dynamic "inbound" {
    for_each = local.final_inbound_rules
    content {
      label    = inbound.value.label
      action   = inbound.value.action
      protocol = inbound.value.protocol
      ports    = inbound.value.ports
      ipv4     = inbound.value.ipv4
      ipv6     = length(try(inbound.value.ipv6, [])) > 0 ? inbound.value.ipv6 : null
    }
  }

  dynamic "outbound" {
    for_each = var.outbound_rules
    content {
      label    = outbound.value.label
      action   = outbound.value.action
      protocol = outbound.value.protocol
      ports    = outbound.value.ports
      ipv4     = outbound.value.ipv4
      ipv6     = length(try(outbound.value.ipv6, [])) > 0 ? outbound.value.ipv6 : null
    }
  }

  # Note: For LKE clusters, firewall rules are managed by Linode
  # This firewall provides additional security for exposed services
}