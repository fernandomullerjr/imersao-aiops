# Kubernetes Dashboard

Dashboard web oficial do Kubernetes para visualização e gerenciamento de recursos do cluster (DigitalOcean DOKS).

## Estrutura dos manifestos

| Arquivo | Descrição |
|---|---|
| `00-namespace.yaml` | Namespace `kubernetes-dashboard` |
| `01-admin-user.yaml` | ServiceAccount admin + ClusterRoleBinding + Secret do token |
| `02-dashboard.yaml` | Deployment completo do Dashboard + scraper de métricas |

---

## Deploy rápido

```bash
# 1. Autenticar e configurar o kubeconfig (DigitalOcean)
doctl auth init
doctl kubernetes cluster kubeconfig save <nome-do-cluster>

# 2. Aplicar os manifestos
kubectl apply -f k8s-dashboard/

# 3. Aguardar os pods ficarem Running
kubectl rollout status deployment/kubernetes-dashboard -n kubernetes-dashboard

# 4. Obter o token de acesso
kubectl get secret admin-user-token -n kubernetes-dashboard \
  -o jsonpath="{.data.token}" | base64 --decode

# 5. Abrir túnel local para o Dashboard
kubectl port-forward svc/kubernetes-dashboard -n kubernetes-dashboard 8443:443
# → Acesse: https://localhost:8443
```

---

## Pré-requisitos

- [`doctl`](https://docs.digitalocean.com/reference/doctl/how-to/install/) instalado e autenticado
- `kubectl` instalado

Instalar o `doctl` no macOS:

```bash
brew install doctl
```

## Configurar acesso ao cluster (DigitalOcean)

```bash
# Autenticar com o token da DO
doctl auth init

# Listar clusters disponíveis
doctl kubernetes cluster list

# Baixar e mesclar o kubeconfig do cluster
doctl kubernetes cluster kubeconfig save <nome-do-cluster>

# Verificar contexto ativo
kubectl config current-context
```

## Deploy

```bash
kubectl apply -f k8s-dashboard/
```

Verificar status:

```bash
kubectl get pods -n kubernetes-dashboard
kubectl get svc -n kubernetes-dashboard
```

## Acesso ao Dashboard

Como o cluster está na DigitalOcean (internet), o acesso é feito via **port-forward** — o tráfego passa pelo túnel `kubectl` autenticado, sem expor o Dashboard publicamente.

```bash
kubectl port-forward svc/kubernetes-dashboard -n kubernetes-dashboard 8443:443
```

Acessar em: `https://localhost:8443`

> O navegador vai alertar sobre o certificado auto-assinado — clique em "Avançado" e aceite para prosseguir.

## Autenticação — Obter o token de acesso

### Token de longa duração (Secret estático)

```bash
kubectl get secret admin-user-token -n kubernetes-dashboard \
  -o jsonpath="{.data.token}" | base64 --decode
```

### Token temporário (expira em 24h)

```bash
kubectl create token admin-user -n kubernetes-dashboard
```

### Token com TTL customizado

```bash
kubectl create token admin-user -n kubernetes-dashboard --duration=8h
```

Copie o token e cole na tela de login selecionando **"Token"**.

## Recursos visíveis no Dashboard

- Nodes e capacidade de recursos (CPU/memória)
- Namespaces, Pods, Deployments, ReplicaSets, StatefulSets
- Services, Ingresses, Endpoints
- ConfigMaps, Secrets (nomes apenas)
- PersistentVolumes e PersistentVolumeClaims
- Jobs, CronJobs
- Eventos e logs de pods em tempo real

## Remoção

```bash
kubectl delete -f k8s-dashboard/
kubectl delete clusterrolebinding admin-user
kubectl delete clusterrolebinding kubernetes-dashboard
kubectl delete clusterrole kubernetes-dashboard
```

## Observações de segurança

- O `admin-user` possui `cluster-admin` — adequado para dev/estudos, não para produção.
- Nunca exponha o Dashboard via `LoadBalancer` ou `NodePort` sem autenticação adicional.
- O `port-forward` é o método seguro para clusters remotos: o acesso é autenticado via kubeconfig e o Dashboard não fica acessível na internet.
- Em produção, prefira acesso via VPN ou OAuth2 Proxy na frente do Ingress.
