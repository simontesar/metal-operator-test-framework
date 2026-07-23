CLAB     ?= clab
QEMU_IMG ?= qemu-img
TOPO     ?= infra.clab.yaml
DISK_SIZE ?= 20G
NODES    ?= node1 node2
VM_DIR   ?= vm
# Set SUDO=sudo if your user cannot create Docker networks / veths.
SUDO     ?=

KUBECONFIG ?= $(CURDIR)/kubeconfig.yaml
KUSTOMIZE  ?= kustomize
KUBECTL    ?= kubectl
BMC_STACK ?= config/bmc

METAL_OPERATOR_DIR ?= ../../../metal-operator
METAL_OPERATOR_STACK ?= ../../config/metal-operator
BOOT_OPERATOR_DIR ?= ../../../boot-operator
BOOT_OPERATOR_STACK ?= ../../config/boot-operator
CERT_MANAGER_VERSION ?= v1.17.1
CERT_MANAGER_MANIFEST ?= https://github.com/cert-manager/cert-manager/releases/download/$(CERT_MANAGER_VERSION)/cert-manager.yaml
KIND_CLUSTER_NAME ?= k8s
CONTROLLER_IMG ?= controller:latest
METALDATA_IMG ?= metaldata:latest
BOOT_CONTROLLER_IMG ?= boot-controller:latest

.PHONY: help disks disks-clean dhcp-config deploy destroy inspect check \
	cert-manager-install cert-manager-wait \
	metal-operator-images metal-operator-deploy metal-operator-delete \
	metal-operator-deploy-wait \
	boot-operator-images boot-operator-deploy boot-operator-delete \
	boot-operator-deploy-wait \
	bmc-apply bmc-delete

help: ## Show available targets
	@grep -E '^[a-zA-Z0-9_.-]+:.*##' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*## "}; {printf "  %-24s %s\n", $$1, $$2}'

check: ## Fail if required tools are missing
	@command -v $(QEMU_IMG) >/dev/null || \
		{ echo "error: $(QEMU_IMG) not found" >&2; exit 1; }
	@command -v $(CLAB) >/dev/null || \
		{ echo "error: $(CLAB) (containerlab) not found" >&2; exit 1; }
	@command -v kind >/dev/null || \
		{ echo "error: kind CLI not found (required for k8s-kind)" >&2; exit 1; }
	@command -v $(KUSTOMIZE) >/dev/null || \
		{ echo "error: $(KUSTOMIZE) not found" >&2; exit 1; }
	@command -v $(KUBECTL) >/dev/null || \
		{ echo "error: $(KUBECTL) not found" >&2; exit 1; }

disks: ## Create missing qcow2 images for worker nodes
	@for n in $(NODES); do \
		mkdir -p $(VM_DIR)/$$n; \
		if [ ! -f $(VM_DIR)/$$n/disk.qcow2 ]; then \
			echo "Creating $(VM_DIR)/$$n/disk.qcow2 ($(DISK_SIZE))"; \
			$(QEMU_IMG) create -f qcow2 $(VM_DIR)/$$n/disk.qcow2 $(DISK_SIZE); \
		else \
			echo "Keeping existing $(VM_DIR)/$$n/disk.qcow2"; \
		fi; \
	done

disks-clean: ## Remove worker qcow2 disk images
	@for n in $(NODES); do \
		rm -f $(VM_DIR)/$$n/disk.qcow2; \
		echo "Removed $(VM_DIR)/$$n/disk.qcow2"; \
	done

dhcp-config: ## Regenerate config/dnsmasq.conf from SYSTEM_UUID MACs
	./scripts/gen-dhcp-leases.sh

deploy: check disks dhcp-config ## Create disks, DHCP config, and deploy lab
	$(SUDO) $(CLAB) deploy -t $(TOPO)

destroy: ## Tear down the lab
	$(SUDO) $(CLAB) destroy -t $(TOPO) --cleanup

inspect: ## Show lab status
	$(CLAB) inspect -t $(TOPO)

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

metal-operator-images: ## Build and load controller/metaldata images into Kind
	$(MAKE) -C $(METAL_OPERATOR_DIR) docker-build \
		CONTROLLER_IMG=$(CONTROLLER_IMG) METALDATA_IMG=$(METALDATA_IMG)
	kind load docker-image $(CONTROLLER_IMG) $(METALDATA_IMG) \
		--name $(KIND_CLUSTER_NAME)

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
	@until KUBECONFIG=$(KUBECONFIG) $(KUBECTL) -n metal-operator-system \
		get deploy metal-operator-controller-manager >/dev/null 2>&1; do \
		echo "Waiting for metal-operator deployment..."; sleep 5; \
	done
	KUBECONFIG=$(KUBECONFIG) $(KUBECTL) wait --for=condition=Available \
		deployment/metal-operator-controller-manager \
		-n metal-operator-system --timeout=600s

boot-operator-images: ## Build and load boot-operator controller image into Kind
	$(MAKE) -C $(BOOT_OPERATOR_DIR) docker-build IMG=$(BOOT_CONTROLLER_IMG)
	kind load docker-image $(BOOT_CONTROLLER_IMG) \
		--name $(KIND_CLUSTER_NAME)

boot-operator-deploy: ## Deploy boot-operator via kustomize overlay
	$(MAKE) -C $(BOOT_OPERATOR_DIR) manifests
	KUBECONFIG=$(KUBECONFIG) $(KUSTOMIZE) build $(BOOT_OPERATOR_STACK) | \
		KUBECONFIG=$(KUBECONFIG) $(KUBECTL) apply -f -

boot-operator-delete: ## Delete boot-operator kustomize overlay
	KUBECONFIG=$(KUBECONFIG) $(KUSTOMIZE) build $(BOOT_OPERATOR_STACK) | \
		KUBECONFIG=$(KUBECONFIG) $(KUBECTL) delete -f - --ignore-not-found

boot-operator-deploy-wait: ## Deploy boot-operator (after metal-operator), then wait
boot-operator-deploy-wait: metal-operator-deploy-wait \
	boot-operator-images boot-operator-deploy
	@until KUBECONFIG=$(KUBECONFIG) $(KUBECTL) get ns boot-operator-system >/dev/null 2>&1; do \
		echo "Waiting for boot-operator-system namespace..."; sleep 5; \
	done
	@until KUBECONFIG=$(KUBECONFIG) $(KUBECTL) -n boot-operator-system \
		get deploy boot-operator-controller-manager >/dev/null 2>&1; do \
		echo "Waiting for boot-operator deployment..."; sleep 5; \
	done
	KUBECONFIG=$(KUBECONFIG) $(KUBECTL) wait --for=condition=Available \
		deployment/boot-operator-controller-manager \
		-n boot-operator-system --timeout=600s

bmc-apply: ## Apply BMC + BMCSecret for node1 and node2
	KUBECONFIG=$(KUBECONFIG) $(KUSTOMIZE) build $(BMC_STACK) | \
		KUBECONFIG=$(KUBECONFIG) $(KUBECTL) apply -f -

bmc-delete: ## Delete BMC + BMCSecret for node1 and node2
	KUBECONFIG=$(KUBECONFIG) $(KUSTOMIZE) build $(BMC_STACK) | \
		KUBECONFIG=$(KUBECONFIG) $(KUBECTL) delete -f - --ignore-not-found
