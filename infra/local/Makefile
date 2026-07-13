KUBECONFIG ?= $(CURDIR)/kubeconfig
KUSTOMIZE  ?= kustomize
KUBECTL    ?= kubectl
MASTER_STACK ?= ../../config/master

.PHONY: help host-vlans host-vlans-clean up-master up-workers up destroy clean \
	master-kustomize-apply master-kustomize-delete master-kustomize-wait

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

master-kustomize-apply: ## Apply master kustomize stack
	KUBECONFIG=$(KUBECONFIG) $(KUSTOMIZE) build $(MASTER_STACK) | \
		KUBECONFIG=$(KUBECONFIG) $(KUBECTL) apply -f -

master-kustomize-delete: ## Delete master kustomize stack
	KUBECONFIG=$(KUBECONFIG) $(KUSTOMIZE) build $(MASTER_STACK) | \
		KUBECONFIG=$(KUBECONFIG) $(KUBECTL) delete -f -

master-kustomize-wait: master-kustomize-apply ## Apply stack and wait for readiness
	@until KUBECONFIG=$(KUBECONFIG) $(KUBECTL) get ns cert-manager >/dev/null 2>&1; do \
		echo "Waiting for cert-manager namespace..."; sleep 5; \
	done
	KUBECONFIG=$(KUBECONFIG) $(KUBECTL) wait --for=condition=Available \
		deployment/cert-manager -n cert-manager --timeout=300s
	KUBECONFIG=$(KUBECONFIG) $(KUBECTL) wait --for=condition=Available \
		deployment/cert-manager-webhook -n cert-manager --timeout=300s
	@until KUBECONFIG=$(KUBECONFIG) $(KUBECTL) get ns metal-operator-system >/dev/null 2>&1; do \
		echo "Waiting for metal-operator-system namespace..."; sleep 5; \
	done
	KUBECONFIG=$(KUBECONFIG) $(KUBECTL) wait --for=condition=Available \
		deployment/metal-operator-controller-manager \
		-n metal-operator-system --timeout=600s
