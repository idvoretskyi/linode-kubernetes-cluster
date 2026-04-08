resource "linode_lke_cluster" "cluster" {
  label       = "${local.cluster_prefix}-lke"
  k8s_version = var.kubernetes_version
  region      = var.region
  tags        = local.common_tags

  dynamic "pool" {
    for_each = var.node_pools
    content {
      type  = pool.value.type
      count = pool.value.count
      dynamic "autoscaler" {
        for_each = pool.value.autoscaler != null ? [pool.value.autoscaler] : []
        content {
          min = autoscaler.value.min
          max = autoscaler.value.max
        }
      }
    }
  }

  control_plane {
    high_availability = var.ha_control_plane
  }
}

# Merges the cluster kubeconfig into ~/.kube/config and sets the active context
resource "terraform_data" "merge_kubeconfig" {
  triggers_replace = {
    kubeconfig_content = base64decode(linode_lke_cluster.cluster.kubeconfig)
    cluster_id         = linode_lke_cluster.cluster.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      mkdir -p ~/.kube
      if [ -f ~/.kube/config ]; then
        cp ~/.kube/config ~/.kube/config.backup.$(date +%Y%m%d-%H%M%S)
      fi
      TEMP_KUBECONFIG=$(mktemp)
      cat > $TEMP_KUBECONFIG << 'KUBECONFIGEOF'
${base64decode(linode_lke_cluster.cluster.kubeconfig)}
KUBECONFIGEOF
      chmod 600 $TEMP_KUBECONFIG
      KUBECONFIG=~/.kube/config:$TEMP_KUBECONFIG kubectl config view --flatten > ~/.kube/config.tmp
      mv ~/.kube/config.tmp ~/.kube/config
      chmod 600 ~/.kube/config
      rm -f $TEMP_KUBECONFIG
      kubectl config use-context lke${linode_lke_cluster.cluster.id}-ctx
    EOT
  }
}
