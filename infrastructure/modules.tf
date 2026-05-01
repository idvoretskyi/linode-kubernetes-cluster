module "metrics_server" {
  count      = var.install_metrics_server ? 1 : 0
  source     = "./modules/metrics-server"
  namespace  = "kube-system"
  depends_on = [linode_lke_cluster.cluster, terraform_data.merge_kubeconfig]
}

module "kube_prometheus_stack" {
  count                     = var.install_monitoring ? 1 : 0
  source                    = "./modules/kube-prometheus-stack"
  namespace                 = var.monitoring_namespace
  grafana_admin_password    = var.grafana_admin_password
  prometheus_retention      = var.prometheus_retention
  prometheus_storage_size   = var.prometheus_storage_size
  grafana_storage_size      = var.grafana_storage_size
  alertmanager_storage_size = var.alertmanager_storage_size
  use_ephemeral_storage     = var.monitoring_use_ephemeral_storage
  depends_on                = [module.metrics_server, linode_lke_cluster.cluster, terraform_data.merge_kubeconfig]
}

module "opencost" {
  count                   = var.install_opencost ? 1 : 0
  source                  = "./modules/opencost"
  namespace               = var.opencost_namespace
  cluster_id              = linode_lke_cluster.cluster.id
  prometheus_service_name = "kube-prometheus-stack-prometheus"
  prometheus_namespace    = var.monitoring_namespace
  depends_on              = [module.kube_prometheus_stack, linode_lke_cluster.cluster, terraform_data.merge_kubeconfig]
}
