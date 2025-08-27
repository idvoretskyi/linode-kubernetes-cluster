output "firewall_id" {
  description = "The ID of the created firewall"
  value       = linode_firewall.cluster_firewall.id
}

output "firewall_label" {
  description = "The label of the created firewall"
  value       = linode_firewall.cluster_firewall.label
}

output "firewall_status" {
  description = "The status of the firewall"
  value       = linode_firewall.cluster_firewall.status
}

output "inbound_policy" {
  description = "The default inbound policy"
  value       = linode_firewall.cluster_firewall.inbound_policy
}

output "outbound_policy" {
  description = "The default outbound policy"
  value       = linode_firewall.cluster_firewall.outbound_policy
}

output "inbound_rules" {
  description = "List of inbound rules applied to the firewall"
  value = [
    for rule in linode_firewall.cluster_firewall.inbound : {
      label    = rule.label
      action   = rule.action
      protocol = rule.protocol
      ports    = rule.ports
      ipv4     = rule.ipv4
      ipv6     = rule.ipv6
    }
  ]
}

output "outbound_rules" {
  description = "List of outbound rules applied to the firewall"
  value = [
    for rule in linode_firewall.cluster_firewall.outbound : {
      label    = rule.label
      action   = rule.action
      protocol = rule.protocol
      ports    = rule.ports
      ipv4     = rule.ipv4
      ipv6     = rule.ipv6
    }
  ]
}