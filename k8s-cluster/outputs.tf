output "cluster_id" {
  description = "Identificador único do cluster DOKS."
  value       = digitalocean_kubernetes_cluster.this.id
}

output "cluster_name" {
  description = "Nome do cluster conforme provisionado."
  value       = digitalocean_kubernetes_cluster.this.name
}

output "cluster_endpoint" {
  description = "Endpoint HTTPS do servidor de API do Kubernetes."
  value       = digitalocean_kubernetes_cluster.this.endpoint
}

output "cluster_status" {
  description = "Status atual do ciclo de vida do cluster (running, provisioning, etc.)."
  value       = digitalocean_kubernetes_cluster.this.status
}

output "kubeconfig_raw" {
  description = <<-EOT
    YAML do kubeconfig completo. Grave em um arquivo e configure KUBECONFIG para usar com kubectl:
      terraform output -raw kubeconfig_raw > ~/.kube/imersao-aiops.yaml
      export KUBECONFIG=~/.kube/imersao-aiops.yaml
      kubectl get nodes
  EOT
  value     = digitalocean_kubernetes_cluster.this.kube_config[0].raw_config
  sensitive = true
}

output "cluster_ca_certificate" {
  description = "Dados do certificado de autoridade (CA) do cluster, codificados em base64."
  value       = digitalocean_kubernetes_cluster.this.kube_config[0].cluster_ca_certificate
  sensitive   = true
}

output "kube_host" {
  description = "URL do host do servidor de API do Kubernetes (mesmo que cluster_endpoint, mas extraído do kubeconfig)."
  value       = digitalocean_kubernetes_cluster.this.kube_config[0].host
  sensitive   = true
}

output "node_pool_id" {
  description = "ID do node pool padrão."
  value       = digitalocean_kubernetes_cluster.this.node_pool[0].id
}

output "kubernetes_version" {
  description = "String completa da versão do Kubernetes resolvida pelo DOKS (ex: 1.32.2-do.0)."
  value       = digitalocean_kubernetes_cluster.this.version
}

output "kubernetes_version_available" {
  description = "Versão mais recente disponível no DOKS para o prefixo configurado."
  value       = data.digitalocean_kubernetes_versions.available.latest_version
}
