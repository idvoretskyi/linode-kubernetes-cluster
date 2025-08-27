output "cluster_id" {
  description = "The ID of the LKE cluster"
  value       = linode_lke_cluster.cluster.id
}

output "cluster_label" {
  description = "The label of the LKE cluster"
  value       = linode_lke_cluster.cluster.label
}

output "cluster_endpoint" {
  description = "The API server endpoint of the LKE cluster"
  value       = length(linode_lke_cluster.cluster.api_endpoints) > 0 ? linode_lke_cluster.cluster.api_endpoints[0] : ""
}

output "cluster_status" {
  description = "The status of the LKE cluster"
  value       = linode_lke_cluster.cluster.status
}

output "cluster_region" {
  description = "The region where the cluster is deployed"
  value       = linode_lke_cluster.cluster.region
}

output "k8s_version" {
  description = "The Kubernetes version of the cluster"
  value       = linode_lke_cluster.cluster.k8s_version
}

output "kubeconfig" {
  description = "Base64 encoded kubeconfig for the cluster"
  value       = linode_lke_cluster.cluster.kubeconfig
  sensitive   = true
}

output "cluster_token" {
  description = "The cluster access token for Kubernetes provider"
  value       = yamldecode(base64decode(linode_lke_cluster.cluster.kubeconfig))["users"][0]["user"]["token"]
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "The cluster CA certificate for Kubernetes provider"
  value       = yamldecode(base64decode(linode_lke_cluster.cluster.kubeconfig))["clusters"][0]["cluster"]["certificate-authority-data"]
  sensitive   = true
}

output "node_pools" {
  description = "Information about the node pools"
  value = [
    for pool in linode_lke_cluster.cluster.pool : {
      id    = pool.id
      type  = pool.type
      count = pool.count
      nodes = pool.nodes
    }
  ]
}

output "dashboard_url" {
  description = "The dashboard URL for the cluster"
  value       = linode_lke_cluster.cluster.dashboard_url
}