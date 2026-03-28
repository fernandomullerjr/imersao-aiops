# Cluster Kubernetes na DigitalOcean — Terraform

Manifesto Terraform para provisionamento de um cluster Kubernetes gerenciado (DOKS — DigitalOcean Kubernetes Service) de forma completamente automatizada.

---

## Configuração do Cluster

| Parâmetro         | Valor                  |
|-------------------|------------------------|
| Tipo de nó        | Basic (Shared)         |
| Tamanho           | `s-2vcpu-4gb`          |
| vCPUs por nó      | 2 (compartilhadas)     |
| RAM por nó        | 4 GiB                  |
| Armazenamento/nó  | 80 GiB SSD             |
| Quantidade de nós | 3                      |
| Região padrão     | `nyc3` (Nova York)     |
| Versão K8s padrão | `1.29`                 |

---

## Pré-requisitos

Antes de começar, instale as ferramentas abaixo:

- **Terraform** `>= 1.6.0` — [https://developer.hashicorp.com/terraform/install](https://developer.hashicorp.com/terraform/install)
- **doctl** (CLI da DigitalOcean, opcional mas recomendado) — [https://docs.digitalocean.com/reference/doctl/how-to/install/](https://docs.digitalocean.com/reference/doctl/how-to/install/)
  - Apenas rodar o comando: `brew install doctl`
- **kubectl** — [https://kubernetes.io/docs/tasks/tools/](https://kubernetes.io/docs/tasks/tools/)

---

## Autenticação na DigitalOcean

### 1. Gerar um Token de Acesso Pessoal

1. Acesse o painel da DigitalOcean: **API > Tokens**
2. Clique em **"Generate New Token"**
3. Dê um nome ao token (ex: `terraform-imersao-aiops`)
4. Selecione o escopo **Read + Write**
5. Copie o token gerado — ele começa com `dop_v1_...`

> **Importante:** O token é exibido apenas uma vez. Guarde-o em local seguro.

### 2. Configurar o Token no Terraform

Copie o arquivo de exemplo e adicione seu token:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edite `terraform.tfvars` e substitua o valor de `do_token`:

```hcl
do_token = "dop_v1_SEU_TOKEN_AQUI"
```

> **Nunca faça commit do arquivo `terraform.tfvars`** — ele já está no `.gitignore` para sua proteção.

### Alternativa: Variável de Ambiente

Você também pode autenticar via variável de ambiente, sem precisar do `terraform.tfvars`:

```bash
export TF_VAR_do_token="dop_v1_SEU_TOKEN_AQUI"
```

---

## Configuração e Deploy

### 1. Copiar e editar as variáveis

```bash
cd k8s-cluster/
cp terraform.tfvars.example terraform.tfvars
# Edite terraform.tfvars com seu token e configurações desejadas
```

### 2. Inicializar o Terraform

```bash
terraform init
```

Isso baixa o provider `digitalocean/digitalocean` e prepara o ambiente local.

### 3. Validar a configuração

```bash
terraform validate
```

Deve retornar: `Success! The configuration is valid.`

### 4. Visualizar o plano de execução

```bash
terraform plan -out=cluster.tfplan
```

Revise os recursos que serão criados antes de aplicar.

### 5. Aplicar e criar o cluster

```bash
terraform apply cluster.tfplan
```

O provisionamento leva aproximadamente **5 a 10 minutos**.

---

## Pós-provisionamento

### Configurar o kubectl

Após o `apply`, extraia o kubeconfig e configure o kubectl:

```bash
terraform output -raw kubeconfig_raw > ~/.kube/imersao-aiops.yaml
export KUBECONFIG=~/.kube/imersao-aiops.yaml
```

Para tornar a configuração permanente, adicione a linha `export` ao seu `~/.bashrc` ou `~/.zshrc`.

### Verificar os nós do cluster

```bash
kubectl get nodes
```

Saída esperada (3 nós com status `Ready`):

```
NAME              STATUS   ROLES    AGE   VERSION
default-pool-xxx  Ready    <none>   2m    v1.29.x
default-pool-yyy  Ready    <none>   2m    v1.29.x
default-pool-zzz  Ready    <none>   2m    v1.29.x
```

### Verificar informações do cluster

```bash
kubectl cluster-info
kubectl get namespaces
```

---

## Variáveis de Referência

| Variável                | Tipo     | Padrão          | Descrição                                                        |
|-------------------------|----------|-----------------|------------------------------------------------------------------|
| `do_token`              | string   | —               | **Obrigatório.** Token de acesso pessoal da DigitalOcean.        |
| `cluster_name`          | string   | `imersao-aiops` | Nome base do cluster (sufixo do ambiente é adicionado).          |
| `environment`           | string   | `dev`           | Ambiente: `dev`, `staging` ou `prod`.                            |
| `region`                | string   | `nyc3`          | Região da DigitalOcean onde o cluster será criado.               |
| `kubernetes_version`    | string   | `1.29`          | Prefixo da versão do Kubernetes (DOKS resolve o patch).          |
| `node_pool_name`        | string   | `default-pool`  | Nome do node pool padrão.                                        |
| `node_size`             | string   | `s-2vcpu-4gb`   | Tamanho do Droplet por nó (2 vCPUs, 4 GiB RAM, 80 GiB SSD).     |
| `node_count`            | number   | `3`             | Quantidade de nós no pool.                                       |
| `auto_upgrade`          | bool     | `false`         | Atualização automática do cluster na janela de manutenção.       |
| `surge_upgrade`         | bool     | `true`          | Nós extras durante upgrades para evitar indisponibilidade.       |
| `maintenance_start_time`| string   | `04:00`         | Início da janela de manutenção (horário UTC, formato HH:MM).     |
| `maintenance_day`       | string   | `sunday`        | Dia da semana para a janela de manutenção.                       |
| `extra_tags`            | list     | `[]`            | Tags adicionais a serem aplicadas ao cluster e aos nós.          |

### Regiões disponíveis

| Slug    | Localização         |
|---------|---------------------|
| `nyc1`  | Nova York 1         |
| `nyc3`  | Nova York 3         |
| `sfo3`  | São Francisco 3     |
| `ams3`  | Amsterdã 3          |
| `sgp1`  | Singapura 1         |
| `lon1`  | Londres 1           |
| `fra1`  | Frankfurt 1         |
| `tor1`  | Toronto 1           |
| `blr1`  | Bangalore 1         |
| `syd1`  | Sydney 1            |

> Liste todas as regiões disponíveis para DOKS com: `doctl kubernetes options regions`

---

## Outputs Disponíveis

Após o `apply`, os seguintes valores estão disponíveis:

```bash
terraform output cluster_id          # ID único do cluster
terraform output cluster_name        # Nome do cluster
terraform output cluster_endpoint    # Endpoint da API do Kubernetes
terraform output cluster_status      # Status atual do cluster
terraform output kubernetes_version  # Versão completa do K8s provisionada
terraform output kube_host           # Host da API (para uso em outros módulos)
terraform output node_pool_id        # ID do node pool padrão

# Outputs sensíveis (requerem a flag -raw):
terraform output -raw kubeconfig_raw         # kubeconfig completo em YAML
terraform output -raw cluster_ca_certificate # Certificado CA em base64
```

---

## Destruir o Cluster

> **Atenção:** Esta operação remove o cluster e todos os seus recursos permanentemente.

```bash
terraform destroy
```

Confirme digitando `yes` quando solicitado.

---

## Estrutura dos Arquivos

```
k8s-cluster/
├── versions.tf              # Versões do Terraform e do provider DigitalOcean
├── variables.tf             # Declaração de todas as variáveis configuráveis
├── main.tf                  # Recurso principal do cluster DOKS
├── outputs.tf               # Valores exportados após o provisionamento
├── terraform.tfvars.example # Template de configuração (copiar para terraform.tfvars)
└── README.md                # Esta documentação
```
