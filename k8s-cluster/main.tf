locals {
  # Tags base: sempre presentes independentemente de var.extra_tags
  base_tags = [
    "project:imersao-aiops",
    "env:${var.environment}",
    "managed-by:terraform",
  ]

  all_tags = distinct(concat(local.base_tags, var.extra_tags))
}

resource "digitalocean_kubernetes_cluster" "this" {
  name    = "${var.cluster_name}-${var.environment}"
  region  = var.region
  version = var.kubernetes_version

  auto_upgrade  = var.auto_upgrade
  surge_upgrade = var.surge_upgrade

  maintenance_policy {
    start_time = var.maintenance_start_time
    day        = var.maintenance_day
  }

  node_pool {
    name       = var.node_pool_name
    size       = var.node_size
    node_count = var.node_count

    tags = local.all_tags
  }

  tags = local.all_tags
}
