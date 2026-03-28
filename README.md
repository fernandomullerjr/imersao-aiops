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

### 1. Provisionar o cluster (Terraform)

```bash
# Entre na pasta do módulo Terraform
cd k8s-cluster/

# Copie e edite as variáveis (inclua seu token da DigitalOcean)
cp terraform.tfvars.example terraform.tfvars

# Inicialize, planeje e aplique
terraform init
terraform plan -out=cluster.tfplan
terraform apply cluster.tfplan
```

> O cluster leva aproximadamente **5 a 10 minutos** para ficar disponível.

### 2. Configurar o kubectl

```bash
# Via output do Terraform
terraform output -raw kubeconfig_raw > ~/.kube/imersao-aiops.yaml
export KUBECONFIG=~/.kube/imersao-aiops.yaml

# Ou via doctl
doctl auth init
doctl kubernetes cluster kubeconfig save imersao-aiops-dev

# Verifique os nós
kubectl get nodes
```

### 3. Deploy do Kubernetes Dashboard

```bash
# Na raiz do repositório
kubectl apply -f k8s-dashboard/

# Aguarde os pods subirem
kubectl rollout status deployment/kubernetes-dashboard -n kubernetes-dashboard

# Obtenha o token de acesso
kubectl get secret admin-user-token -n kubernetes-dashboard \
  -o jsonpath="{.data.token}" | base64 --decode

# Abra o túnel
kubectl port-forward svc/kubernetes-dashboard -n kubernetes-dashboard 8443:443
# Acesse: https://localhost:8443
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
# Remove todos os recursos do cluster na DigitalOcean
cd k8s-cluster/
terraform destroy
```

> **Atenção:** Esta operação é irreversível e remove o cluster e todos os dados associados.
