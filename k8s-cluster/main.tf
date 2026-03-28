data "digitalocean_kubernetes_versions" "available" {
  version_prefix = var.kubernetes_version
}

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
  version = data.digitalocean_kubernetes_versions.available.latest_version

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

  # Upgrades de versão são gerenciados manualmente (console/doctl) ou via auto_upgrade.
  # O endpoint de upgrade do DOKS exige capacidade de surge independente do flag surge_upgrade.
  lifecycle {
    ignore_changes = [version]
  }
}
