KUBECONFIG ?= $(CURDIR)/kubeconfig
KUSTOMIZE  ?= kustomize
KUBECTL    ?= kubectl

METAL_OPERATOR_DIR ?= ../../../metal-operator
METAL_OPERATOR_STACK ?= ../../config/metal-operator
CERT_MANAGER_VERSION ?= v1.17.1
CERT_MANAGER_MANIFEST ?= https://github.com/cert-manager/cert-manager/releases/download/$(CERT_MANAGER_VERSION)/cert-manager.yaml
CONTROLLER_IMG ?= controller:latest
METALDATA_IMG ?= metaldata:latest

.PHONY: help host-vlans host-vlans-clean up-master up-workers up destroy clean \
	cert-manager-install cert-manager-wait \
	metal-operator-images metal-operator-deploy metal-operator-delete \
	metal-operator-deploy-wait

help: ## Show available targets
	@grep -E '^[a-zA-Z0-9_.-]+:.*##' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*## "}; {printf "  %-24s %s\n", $$1, $$2}'

host-vlans: ## Create host VLAN interfaces
	./scripts/setup-host-vlans.sh create

host-vlans-clean: ## Remove host VLAN interfaces
	./scripts/setup-host-vlans.sh cleanup

up-master: ## Start master VM (network + k3s via host trigger)
	vagrant up master

up-workers: ## Start node1 and node2 VMs
	vagrant up node1 node2

up: host-vlans up-master up-workers ## Bring up full lab environment

destroy: ## Destroy all VMs
	vagrant destroy -f

clean: destroy host-vlans-clean ## Destroy VMs and remove host VLANs

cert-manager-install: ## Install cert-manager from upstream release manifest
	KUBECONFIG=$(KUBECONFIG) $(KUBECTL) apply -f $(CERT_MANAGER_MANIFEST)

cert-manager-wait: ## Wait for cert-manager deployments to become available
	@until KUBECONFIG=$(KUBECONFIG) $(KUBECTL) get ns cert-manager >/dev/null 2>&1; do \
		echo "Waiting for cert-manager namespace..."; sleep 5; \
	done
	KUBECONFIG=$(KUBECONFIG) $(KUBECTL) wait --for=condition=Available \
		deployment/cert-manager -n cert-manager --timeout=300s
	KUBECONFIG=$(KUBECONFIG) $(KUBECTL) wait --for=condition=Available \
		deployment/cert-manager-webhook -n cert-manager --timeout=300s
	KUBECONFIG=$(KUBECONFIG) $(KUBECTL) wait --for=condition=Available \
		deployment/cert-manager-cainjector -n cert-manager --timeout=300s

metal-operator-images: ## Build controller/metaldata images (import into k3s separately)
	$(MAKE) -C $(METAL_OPERATOR_DIR) docker-build \
		CONTROLLER_IMG=$(CONTROLLER_IMG) METALDATA_IMG=$(METALDATA_IMG)

metal-operator-deploy: ## Deploy metal-operator via kustomize overlay
	$(MAKE) -C $(METAL_OPERATOR_DIR) manifests
	KUBECONFIG=$(KUBECONFIG) $(KUSTOMIZE) build $(METAL_OPERATOR_STACK) | \
		KUBECONFIG=$(KUBECONFIG) $(KUBECTL) apply -f -

metal-operator-delete: ## Delete metal-operator kustomize overlay
	KUBECONFIG=$(KUBECONFIG) $(KUSTOMIZE) build $(METAL_OPERATOR_STACK) | \
		KUBECONFIG=$(KUBECONFIG) $(KUBECTL) delete -f - --ignore-not-found

metal-operator-deploy-wait: ## Install cert-manager and metal-operator, then wait
metal-operator-deploy-wait: cert-manager-install cert-manager-wait \
	metal-operator-images metal-operator-deploy
	@until KUBECONFIG=$(KUBECONFIG) $(KUBECTL) get ns metal-operator-system >/dev/null 2>&1; do \
		echo "Waiting for metal-operator-system namespace..."; sleep 5; \
	done
	KUBECONFIG=$(KUBECONFIG) $(KUBECTL) wait --for=condition=Available \
		deployment/metal-operator-controller-manager \
		-n metal-operator-system --timeout=600s
