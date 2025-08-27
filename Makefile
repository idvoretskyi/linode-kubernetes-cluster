.PHONY: help init plan apply destroy validate fmt clean kubeconfig status cost-estimate dev prod

# Default target
help: ## Display this help message
	@echo "Linode Kubernetes Cluster - Modular OpenTofu Commands"
	@echo "====================================================="
	@echo ""
	@echo "Quick Start Commands:"
	@echo "  dev        Setup development environment"
	@echo "  prod       Setup production environment" 
	@echo ""
	@echo "Infrastructure Commands:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Infrastructure directory (new modular structure)
INFRA_DIR := infrastructure
TFVARS_FILE := $(INFRA_DIR)/terraform.tfvars

# Get LINODE_TOKEN dynamically from linode-cli config (can be overridden by environment variable)
LINODE_TOKEN ?= $(shell grep '^token' ~/.config/linode-cli | cut -d' ' -f3 2>/dev/null)

# Environment setup commands
dev: ## Setup development environment configuration
	@echo "Setting up development environment..."
	@cp $(INFRA_DIR)/environments/dev/terraform.tfvars $(INFRA_DIR)/terraform.tfvars
	@echo "Development configuration copied to $(INFRA_DIR)/terraform.tfvars"
	@echo "Next steps:"
	@echo "  1. Edit terraform.tfvars with your specific settings"
	@echo "  2. Run: make init plan apply"
	@echo "Note: LINODE_TOKEN will be automatically detected from linode-cli config"

prod: ## Setup production environment configuration
	@echo "Setting up production environment..."
	@cp $(INFRA_DIR)/environments/prod/terraform.tfvars $(INFRA_DIR)/terraform.tfvars
	@echo "⚠️  Production configuration copied to $(INFRA_DIR)/terraform.tfvars"
	@echo "⚠️  IMPORTANT: Review and customize security settings!"
	@echo "Next steps:"
	@echo "  1. Edit terraform.tfvars - especially firewall_allowed_ips!"
	@echo "  2. Run: make init plan apply"
	@echo "Note: LINODE_TOKEN will be automatically detected from linode-cli config"

# Check if terraform.tfvars exists
check-tfvars:
	@if [ ! -f "$(TFVARS_FILE)" ]; then \
		echo "Error: $(TFVARS_FILE) not found. Copy terraform.tfvars.example to terraform.tfvars and customize it."; \
		exit 1; \
	fi

# Check if LINODE_TOKEN is available
check-token:
	@if [ -z "$(LINODE_TOKEN)" ]; then \
		echo "Error: LINODE_TOKEN not found."; \
		echo "Please configure linode-cli: linode-cli configure"; \
		echo "Or set manually: export LINODE_TOKEN='your-token'"; \
		exit 1; \
	fi
	@echo "✓ Using LINODE_TOKEN from linode-cli config"

token-status: ## Show current token status
	@if [ -n "$(LINODE_TOKEN)" ]; then \
		echo "✓ LINODE_TOKEN detected (ends with: ...$(shell echo $(LINODE_TOKEN) | tail -c 5))"; \
		if [ -n "$$LINODE_TOKEN" ]; then \
			echo "  Source: Environment variable (manual override)"; \
		else \
			echo "  Source: linode-cli profile ($$(linode-cli profile view --text --no-headers | cut -f1))"; \
		fi; \
	else \
		echo "✗ No LINODE_TOKEN found"; \
		echo "  Run: linode-cli configure"; \
	fi

init: ## Initialize OpenTofu
	@cd $(INFRA_DIR) && /opt/homebrew/opt/opentofu/bin/tofu init

validate: init ## Validate OpenTofu configuration
	@cd $(INFRA_DIR) && /opt/homebrew/opt/opentofu/bin/tofu validate

fmt: ## Format OpenTofu files
	@cd $(INFRA_DIR) && /opt/homebrew/opt/opentofu/bin/tofu fmt -recursive

plan: check-tfvars check-token validate ## Plan infrastructure changes
	@cd $(INFRA_DIR) && LINODE_TOKEN=$(LINODE_TOKEN) /opt/homebrew/opt/opentofu/bin/tofu plan

apply: check-tfvars check-token validate ## Apply infrastructure changes
	@cd $(INFRA_DIR) && LINODE_TOKEN=$(LINODE_TOKEN) /opt/homebrew/opt/opentofu/bin/tofu apply

destroy: check-tfvars check-token ## Destroy infrastructure (with confirmation)
	@cd $(INFRA_DIR) && LINODE_TOKEN=$(LINODE_TOKEN) /opt/homebrew/opt/opentofu/bin/tofu destroy

destroy-auto: check-tfvars check-token ## Destroy infrastructure (auto-approve, dangerous!)
	@cd $(INFRA_DIR) && LINODE_TOKEN=$(LINODE_TOKEN) /opt/homebrew/opt/opentofu/bin/tofu destroy -auto-approve

status: ## Show current infrastructure status
	@cd $(INFRA_DIR) && LINODE_TOKEN=$(LINODE_TOKEN) /opt/homebrew/opt/opentofu/bin/tofu show

output: ## Show all outputs
	@cd $(INFRA_DIR) && LINODE_TOKEN=$(LINODE_TOKEN) /opt/homebrew/opt/opentofu/bin/tofu output

kubeconfig: ## Extract and save kubeconfig
	@cd $(INFRA_DIR) && \
	LINODE_TOKEN=$(LINODE_TOKEN) /opt/homebrew/opt/opentofu/bin/tofu output -raw kubeconfig | base64 -d > ../kubeconfig.yaml && \
	echo "Kubeconfig saved to ./kubeconfig.yaml" && \
	echo "Set KUBECONFIG=./kubeconfig.yaml to use the cluster"

clean: ## Clean up temporary files
	@cd $(INFRA_DIR) && rm -rf .terraform .terraform.lock.hcl terraform.tfstate.backup
	@rm -f kubeconfig.yaml

# Cluster management targets
cluster-info: kubeconfig ## Show cluster information
	@export KUBECONFIG=./kubeconfig.yaml && kubectl cluster-info

nodes: kubeconfig ## List cluster nodes
	@export KUBECONFIG=./kubeconfig.yaml && kubectl get nodes -o wide

pods: kubeconfig ## List all pods
	@export KUBECONFIG=./kubeconfig.yaml && kubectl get pods -A

cost-estimate: ## Display estimated monthly costs for current configuration
	@echo "Estimated Monthly Costs (USD):"
	@echo "=============================="
	@echo "Development Environment:"
	@echo "  g6-standard-1 (1 vCPU, 2GB): ~\$$24/month per node"
	@echo "  1 node baseline: ~\$$26/month total"
	@echo ""
	@echo "Production Environment:"
	@echo "  g6-standard-2 (2 vCPU, 4GB): ~\$$36/month per node"
	@echo "  Control Plane HA: ~\$$60/month"
	@echo "  3 nodes baseline: ~\$$168/month total"
	@echo ""
	@echo "LKE Control Plane (non-HA): Free"
	@echo "NodeBalancer (if used): ~\$$10/month"
	@echo "Note: Prices subject to change, check Linode pricing page"

quick-start: ## Quick start guide
	@echo "Quick Start Guide:"
	@echo "=================="
	@echo "1. Choose environment: make dev  (or make prod)"
	@echo "2. Edit terraform.tfvars with your settings"
	@echo "3. Initialize: make init"
	@echo "4. Plan changes: make plan"
	@echo "5. Apply changes: make apply"
	@echo "6. Get kubeconfig: make kubeconfig"
	@echo "7. Check cluster: make cluster-info"
	@echo ""
	@echo "Note: LINODE_TOKEN automatically detected from linode-cli config"
	@echo "If not configured, run: linode-cli configure"