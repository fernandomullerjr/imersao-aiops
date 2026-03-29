SHELL := /bin/bash
CLUSTER_DIR := k8s-cluster
DASHBOARD_DIR := k8s-dashboard
KUBECONFIG_FILE := ~/.kube/imersao-aiops.yaml

.DEFAULT_GOAL := help

# ---------------------------------------------------------------------------
# Help
# ---------------------------------------------------------------------------

.PHONY: help
help: ## Exibe esta mensagem de ajuda
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-28s\033[0m %s\n", $$1, $$2}' \
		| sort

# ---------------------------------------------------------------------------
# Terraform — cluster
# ---------------------------------------------------------------------------

.PHONY: tf-init
tf-init: ## Inicializa o Terraform (baixa providers)
	cd $(CLUSTER_DIR) && terraform init

.PHONY: tf-validate
tf-validate: ## Valida a sintaxe dos manifestos Terraform
	cd $(CLUSTER_DIR) && terraform validate

.PHONY: tf-plan
tf-plan: ## Gera o plano de execução e salva em cluster.tfplan
	cd $(CLUSTER_DIR) && terraform plan -out=cluster.tfplan

.PHONY: tf-apply
tf-apply: ## Aplica o plano salvo (cluster.tfplan)
	cd $(CLUSTER_DIR) && terraform apply cluster.tfplan

.PHONY: tf-plan-apply
tf-plan-apply: tf-plan tf-apply ## Gera o plano e aplica em sequência

.PHONY: tf-destroy
tf-destroy: ## Destroi o cluster e todos os recursos (pede confirmação)
	cd $(CLUSTER_DIR) && terraform destroy

.PHONY: tf-output
tf-output: ## Exibe todos os outputs do Terraform
	cd $(CLUSTER_DIR) && terraform output

.PHONY: tf-versions
tf-versions: ## Lista as versões de Kubernetes disponíveis no DOKS
	doctl kubernetes options versions

# ---------------------------------------------------------------------------
# kubeconfig
# ---------------------------------------------------------------------------

.PHONY: kubeconfig
kubeconfig: ## Exporta o kubeconfig do cluster via Terraform output
	@mkdir -p ~/.kube
	cd $(CLUSTER_DIR) && terraform output -raw kubeconfig_raw > $(KUBECONFIG_FILE)
	@echo "kubeconfig salvo em $(KUBECONFIG_FILE)"
	@echo "Execute: export KUBECONFIG=$(KUBECONFIG_FILE)"

.PHONY: kubeconfig-doctl
kubeconfig-doctl: ## Exporta o kubeconfig do cluster via doctl
	doctl kubernetes cluster kubeconfig save imersao-aiops-dev
	@echo "Contexto ativo: $$(kubectl config current-context)"

# ---------------------------------------------------------------------------
# Kubernetes — cluster info
# ---------------------------------------------------------------------------

.PHONY: nodes
nodes: ## Lista os nós do cluster
	kubectl get nodes -o wide

.PHONY: cluster-info
cluster-info: ## Exibe informações gerais do cluster
	kubectl cluster-info
	@echo ""
	kubectl get namespaces

.PHONY: all-resources
all-resources: ## Lista todos os recursos em todos os namespaces
	kubectl get all -A

# ---------------------------------------------------------------------------
# Dashboard
# ---------------------------------------------------------------------------

.PHONY: dashboard-deploy
dashboard-deploy: ## Faz o deploy do Kubernetes Dashboard
	kubectl apply -f $(DASHBOARD_DIR)/

.PHONY: dashboard-status
dashboard-status: ## Verifica o status dos pods do Dashboard
	kubectl get pods -n kubernetes-dashboard
	@echo ""
	kubectl get svc -n kubernetes-dashboard

.PHONY: dashboard-token
dashboard-token: ## Exibe o token de acesso ao Dashboard
	@kubectl get secret admin-user-token -n kubernetes-dashboard \
		-o jsonpath="{.data.token}" | base64 --decode
	@echo ""

.PHONY: dashboard-open
dashboard-open: ## Abre o túnel para o Dashboard (https://localhost:8443)
	@echo "Abrindo túnel para o Dashboard em https://localhost:8443"
	@echo "Use Ctrl+C para encerrar."
	kubectl port-forward svc/kubernetes-dashboard -n kubernetes-dashboard 8443:443

.PHONY: dashboard-delete
dashboard-delete: ## Remove o Kubernetes Dashboard do cluster
	kubectl delete -f $(DASHBOARD_DIR)/

# ---------------------------------------------------------------------------
# Setup inicial completo
# ---------------------------------------------------------------------------

.PHONY: setup
setup: tf-init ## Configura o ambiente local (copia tfvars.example se necessário)
	@if [ ! -f $(CLUSTER_DIR)/terraform.tfvars ]; then \
		cp $(CLUSTER_DIR)/terraform.tfvars.example $(CLUSTER_DIR)/terraform.tfvars; \
		echo "Arquivo terraform.tfvars criado a partir do exemplo."; \
		echo "Edite $(CLUSTER_DIR)/terraform.tfvars e adicione seu token da DigitalOcean."; \
	else \
		echo "terraform.tfvars já existe — nenhuma alteração feita."; \
	fi
