# ---------------------------------------------------------------------------
# Autenticação
# ---------------------------------------------------------------------------

variable "do_token" {
  description = "Token de acesso pessoal da DigitalOcean com escopo de leitura e escrita."
  type        = string
  sensitive   = true
}

# ---------------------------------------------------------------------------
# Identidade do cluster
# ---------------------------------------------------------------------------

variable "cluster_name" {
  description = "Nome do cluster DOKS. Deve ser único dentro da conta."
  type        = string
  default     = "imersao-aiops"
}

variable "environment" {
  description = "Rótulo do ambiente de deploy (ex: dev, staging, prod). Usado nas tags."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "O ambiente deve ser um dos valores: dev, staging, prod."
  }
}

# ---------------------------------------------------------------------------
# Região e versão do Kubernetes
# ---------------------------------------------------------------------------

variable "region" {
  description = "Slug da região da DigitalOcean onde o cluster será criado."
  type        = string
  default     = "nyc3"
}

variable "kubernetes_version" {
  description = <<-EOT
    Prefixo da versão do Kubernetes a ser utilizada. O DOKS resolve automaticamente
    para o último patch disponível (ex: "1.29" → "1.29.x-do.y").
    Execute `doctl kubernetes options versions` para listar as versões disponíveis.
  EOT
  type        = string
  default     = "1.29"
}

# ---------------------------------------------------------------------------
# Node pool
# ---------------------------------------------------------------------------

variable "node_pool_name" {
  description = "Nome do node pool padrão."
  type        = string
  default     = "default-pool"
}

variable "node_size" {
  description = <<-EOT
    Slug do tamanho do Droplet para cada nó.
    s-2vcpu-4gb = 2 vCPUs compartilhadas, 4 GiB de RAM, 80 GiB SSD.
    Execute `doctl kubernetes options sizes` para listar todos os slugs válidos.
  EOT
  type        = string
  default     = "s-2vcpu-4gb"
}

variable "node_count" {
  description = "Número de nós no node pool padrão."
  type        = number
  default     = 3

  validation {
    condition     = var.node_count >= 1 && var.node_count <= 100
    error_message = "node_count deve estar entre 1 e 100."
  }
}

# ---------------------------------------------------------------------------
# Comportamento do cluster
# ---------------------------------------------------------------------------

variable "auto_upgrade" {
  description = "Quando true, o DOKS atualiza automaticamente o cluster durante a janela de manutenção."
  type        = bool
  default     = false
}

variable "surge_upgrade" {
  description = "Quando true, nós extras são provisionados durante atualizações para evitar interrupção das cargas de trabalho."
  type        = bool
  default     = true
}

variable "maintenance_start_time" {
  description = "Horário UTC (HH:MM) de início da janela de manutenção semanal."
  type        = string
  default     = "04:00"
}

variable "maintenance_day" {
  description = "Dia da semana para a janela de manutenção (any, monday ... sunday)."
  type        = string
  default     = "sunday"
}

# ---------------------------------------------------------------------------
# Tags adicionais
# ---------------------------------------------------------------------------

variable "extra_tags" {
  description = "Tags adicionais a serem aplicadas ao cluster. As tags de projeto e ambiente são sempre adicionadas automaticamente."
  type        = list(string)
  default     = []
}
