# imersao-aiops

Repositório de infraestrutura e ferramentas da **Imersão AIOps** — provisionamento automatizado de um cluster Kubernetes na DigitalOcean com Terraform e deploy do Kubernetes Dashboard.

---

## Visão Geral

Este repositório reúne os manifestos e configurações necessários para subir e operar um ambiente Kubernetes completo na DigitalOcean, do zero ao cluster funcional.

| Componente       | Tecnologia           | Descrição                                              |
|------------------|----------------------|--------------------------------------------------------|
| `k8s-cluster/`   | Terraform + DOKS     | Provisionamento automatizado do cluster Kubernetes     |
| `k8s-dashboard/` | kubectl + YAML       | Dashboard web para visualização e gestão do cluster    |

---

## Estrutura do Repositório

```
imersao-aiops/
├── k8s-cluster/                    # Terraform — cluster DOKS
│   ├── versions.tf                 # Versões do Terraform e do provider DigitalOcean
│   ├── variables.tf                # Todas as variáveis configuráveis
│   ├── main.tf                     # Recurso principal do cluster
│   ├── outputs.tf                  # Valores exportados após o apply
│   ├── terraform.tfvars.example    # Template de configuração
│   └── README.md                   # Documentação detalhada do módulo
│
├── k8s-dashboard/                  # Kubernetes Dashboard
│   ├── 00-namespace.yaml           # Namespace kubernetes-dashboard
│   ├── 01-admin-user.yaml          # ServiceAccount admin + token
│   ├── 02-dashboard.yaml           # Deployment do Dashboard + scraper
│   └── README.md                   # Documentação detalhada do módulo
│
├── Makefile                        # Atalhos para operações comuns
├── .gitignore
└── README.md                       # Este arquivo
```

---

## Pré-requisitos

| Ferramenta  | Versão mínima | Instalação                                                                                |
|-------------|---------------|-------------------------------------------------------------------------------------------|
| Terraform   | `>= 1.6.0`   | [developer.hashicorp.com/terraform/install](https://developer.hashicorp.com/terraform/install) |
| kubectl     | qualquer      | [kubernetes.io/docs/tasks/tools](https://kubernetes.io/docs/tasks/tools/)                 |
| doctl       | qualquer      | `brew install doctl`                                                                      |

---

## Quick Start

### 1. Configurar o ambiente

```bash
make setup
# Cria o terraform.tfvars a partir do exemplo e roda terraform init.
# Edite k8s-cluster/terraform.tfvars com seu token da DigitalOcean.
```

### 2. Provisionar o cluster

```bash
make tf-plan-apply
# Equivale a: terraform plan -out=cluster.tfplan && terraform apply cluster.tfplan
```

> O cluster leva aproximadamente **5 a 10 minutos** para ficar disponível.

### 3. Configurar o kubectl

```bash
make kubeconfig
export KUBECONFIG=~/.kube/imersao-aiops.yaml

make nodes   # verifica se os 3 nós estão Ready
```

### 4. Deploy do Kubernetes Dashboard

```bash
make dashboard-deploy    # aplica os manifests
make dashboard-token     # exibe o token de acesso
make dashboard-open      # abre o túnel → https://localhost:8443
```

---

## Configuração do Cluster

| Parâmetro         | Valor              |
|-------------------|--------------------|
| Tipo de nó        | Basic (Shared)     |
| Tamanho           | `s-2vcpu-4gb`      |
| vCPUs por nó      | 2 (compartilhadas) |
| RAM por nó        | 4 GiB              |
| Armazenamento/nó  | 80 GiB SSD         |
| Quantidade de nós | 3                  |
| Região padrão     | `nyc3` (Nova York) |

---

## Makefile — Referência de Comandos

Execute `make` ou `make help` para listar todos os targets disponíveis.

### Setup e Terraform

| Comando           | Descrição                                              |
|-------------------|--------------------------------------------------------|
| `make setup`      | Copia o `tfvars.example` e inicializa o Terraform      |
| `make tf-init`    | Inicializa o Terraform (baixa providers)               |
| `make tf-validate`| Valida a sintaxe dos manifestos                        |
| `make tf-plan`    | Gera o plano de execução (`cluster.tfplan`)            |
| `make tf-apply`   | Aplica o plano salvo                                   |
| `make tf-plan-apply` | Gera e aplica o plano em sequência                  |
| `make tf-output`  | Exibe todos os outputs do Terraform                    |
| `make tf-versions`| Lista versões de Kubernetes disponíveis no DOKS        |
| `make tf-destroy` | Destroi o cluster (pede confirmação)                   |

### kubeconfig

| Comando                | Descrição                                          |
|------------------------|----------------------------------------------------|
| `make kubeconfig`      | Exporta o kubeconfig via `terraform output`        |
| `make kubeconfig-doctl`| Exporta o kubeconfig via `doctl`                   |

### Cluster

| Comando             | Descrição                                            |
|---------------------|------------------------------------------------------|
| `make nodes`        | Lista os nós do cluster                              |
| `make cluster-info` | Exibe informações gerais e namespaces                |
| `make all-resources`| Lista todos os recursos em todos os namespaces       |

### Dashboard

| Comando                  | Descrição                                        |
|--------------------------|--------------------------------------------------|
| `make dashboard-deploy`  | Faz o deploy do Kubernetes Dashboard             |
| `make dashboard-status`  | Verifica pods e serviços do Dashboard            |
| `make dashboard-token`   | Exibe o token de acesso                          |
| `make dashboard-open`    | Abre o túnel (`https://localhost:8443`)          |
| `make dashboard-delete`  | Remove o Dashboard do cluster                    |

---

## Documentação Detalhada

Cada módulo possui seu próprio README com instruções completas:

- **Cluster Kubernetes (Terraform):** [`k8s-cluster/README.md`](./k8s-cluster/README.md)
  - Autenticação na DigitalOcean
  - Todas as variáveis e seus padrões
  - Outputs disponíveis
  - Como destruir o cluster

- **Kubernetes Dashboard:** [`k8s-dashboard/README.md`](./k8s-dashboard/README.md)
  - Tipos de token de acesso
  - Observações de segurança
  - Como remover o Dashboard

---

## Segurança

- O arquivo `terraform.tfvars` está no `.gitignore` — **nunca faça commit dele**.
- Use variável de ambiente como alternativa ao arquivo de vars:
  ```bash
  export TF_VAR_do_token="dop_v1_SEU_TOKEN_AQUI"
  ```
- O `admin-user` do Dashboard possui `cluster-admin` — adequado para dev/estudos, **não para produção**.
- Acesse o Dashboard sempre via `port-forward`, nunca exposto publicamente.

---

## Destruir o Ambiente

```bash
make tf-destroy
```

> **Atenção:** Esta operação é irreversível e remove o cluster e todos os dados associados.
