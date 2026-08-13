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
METAL_OPERATOR_STACK ?= config/metal-operator
BOOT_OPERATOR_DIR ?= ../../../boot-operator
BOOT_OPERATOR_STACK ?= config/boot-operator
FEDHCP_DIR ?= ../../../FeDHCP
FEDHCP_STACK ?= ../../config/fedhcp
TFTP_STACK ?= ../../config/tftp
CERT_MANAGER_VERSION ?= v1.17.1
CERT_MANAGER_MANIFEST ?= https://github.com/cert-manager/cert-manager/releases/download/$(CERT_MANAGER_VERSION)/cert-manager.yaml
KIND_CLUSTER_NAME ?= k8s
CONTROLLER_IMG ?= controller:latest
METALDATA_IMG ?= metaldata:latest
BOOT_CONTROLLER_IMG ?= boot-controller:latest
FEDHCP_IMG ?= fedhcp:latest
TFTP_IMG ?= tftp:latest
METALPROBE_IMAGE_DIR  ?= metalprobe-image
KERNEL_VERSION         ?= 6.12.100-1-cloud
METALPROBE_BOOT_IMAGE  ?= ghcr.io/simontesar/metal-operator-test-framework:dev

.PHONY: help deploy destroy clean-disks inspect check \
	cert-manager-install cert-manager-wait \
	metal-operator-images metal-operator-deploy metal-operator-delete \
	metal-operator-deploy-wait \
	boot-operator-images boot-operator-deploy boot-operator-delete \
	boot-operator-deploy-wait \
	fedhcp-images fedhcp-deploy fedhcp-delete fedhcp-deploy-wait \
	tftp-images tftp-deploy tftp-delete tftp-deploy-wait \
	bmc-apply bmc-delete \
	metalprobe-image-tools metalprobe-image-build metalprobe-image-push

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

deploy: check ## Create disks and deploy lab
	touch $(KUBECONFIG) # Initialises the kubeconfig with users' permissions
	$(SUDO) $(CLAB) deploy -t $(TOPO)

destroy: ## Tear down the lab
	$(SUDO) $(CLAB) destroy -t $(TOPO) --cleanup

clean-disks: ## Remove per-node VM disks and OVMF_VARS files
	@for node in $(NODES); do \
		$(SUDO) rm -f $(VM_DIR)/$$node/disk.qcow2 \
			$(VM_DIR)/$$node/OVMF_VARS.fd; \
	done

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

fedhcp-images: ## Build and load the FeDHCP image into Kind
	docker build -t $(FEDHCP_IMG) $(FEDHCP_DIR)
	kind load docker-image $(FEDHCP_IMG) \
		--name $(KIND_CLUSTER_NAME)

fedhcp-deploy: ## Deploy FeDHCP via kustomize overlay
	KUBECONFIG=$(KUBECONFIG) $(KUSTOMIZE) build $(FEDHCP_STACK) | \
		KUBECONFIG=$(KUBECONFIG) $(KUBECTL) apply -f -

fedhcp-delete: ## Delete FeDHCP kustomize overlay
	KUBECONFIG=$(KUBECONFIG) $(KUSTOMIZE) build $(FEDHCP_STACK) | \
		KUBECONFIG=$(KUBECONFIG) $(KUBECTL) delete -f - --ignore-not-found

fedhcp-deploy-wait: ## Deploy FeDHCP (after TFTP), then wait
fedhcp-deploy-wait: tftp-deploy-wait \
	fedhcp-images fedhcp-deploy
	@until KUBECONFIG=$(KUBECONFIG) $(KUBECTL) get ns fedhcp-system >/dev/null 2>&1; do \
		echo "Waiting for fedhcp-system namespace..."; sleep 5; \
	done
	@until KUBECONFIG=$(KUBECONFIG) $(KUBECTL) -n fedhcp-system \
		get deploy fedhcp >/dev/null 2>&1; do \
		echo "Waiting for fedhcp deployment..."; sleep 5; \
	done
	KUBECONFIG=$(KUBECONFIG) $(KUBECTL) wait --for=condition=Available \
		deployment/fedhcp \
		-n fedhcp-system --timeout=300s

tftp-images: ## Build and load the TFTP (iPXE chainload) image into Kind
	docker build -t $(TFTP_IMG) $(TFTP_STACK)
	kind load docker-image $(TFTP_IMG) \
		--name $(KIND_CLUSTER_NAME)

tftp-deploy: ## Deploy TFTP server via kustomize overlay
	KUBECONFIG=$(KUBECONFIG) $(KUSTOMIZE) build $(TFTP_STACK) | \
		KUBECONFIG=$(KUBECONFIG) $(KUBECTL) apply -f -

tftp-delete: ## Delete TFTP server kustomize overlay
	KUBECONFIG=$(KUBECONFIG) $(KUSTOMIZE) build $(TFTP_STACK) | \
		KUBECONFIG=$(KUBECONFIG) $(KUBECTL) delete -f - --ignore-not-found

tftp-deploy-wait: ## Deploy TFTP server (after boot-operator), then wait
tftp-deploy-wait: boot-operator-deploy-wait \
	tftp-images tftp-deploy
	@until KUBECONFIG=$(KUBECONFIG) $(KUBECTL) get ns tftp-system >/dev/null 2>&1; do \
		echo "Waiting for tftp-system namespace..."; sleep 5; \
	done
	@until KUBECONFIG=$(KUBECONFIG) $(KUBECTL) -n tftp-system \
		get deploy tftp >/dev/null 2>&1; do \
		echo "Waiting for tftp deployment..."; sleep 5; \
	done
	KUBECONFIG=$(KUBECONFIG) $(KUBECTL) wait --for=condition=Available \
		deployment/tftp \
		-n tftp-system --timeout=300s

bmc-apply: ## Apply BMC + BMCSecret for node1 and node2
	KUBECONFIG=$(KUBECONFIG) $(KUSTOMIZE) build $(BMC_STACK) | \
		KUBECONFIG=$(KUBECONFIG) $(KUBECTL) apply -f -

bmc-delete: ## Delete BMC + BMCSecret for node1 and node2
	KUBECONFIG=$(KUBECONFIG) $(KUSTOMIZE) build $(BMC_STACK) | \
		KUBECONFIG=$(KUBECONFIG) $(KUBECTL) delete -f - --ignore-not-found

metalprobe-image-tools: ## Install u-root, ironcore-image, and the kernel-fetch CLI
	cd $(METALPROBE_IMAGE_DIR) && go install github.com/u-root/u-root@v0.16.0
	cd $(METALPROBE_IMAGE_DIR) && go install github.com/ironcore-dev/ironcore-image/cmd/ironcore-image@v0.5.0
	cd $(METALPROBE_IMAGE_DIR)/hack/kernel && go install .

metalprobe-image-build: metalprobe-image-tools ## Build the metalprobe u-root boot image (kernel+initramfs)
	cd $(METALPROBE_IMAGE_DIR) && ./hack/build.sh -k "$(KERNEL_VERSION)" \
		-m failover -m net_failover -m virtio_net -m virtio_blk \
		-m button -m evdev -o ./bin/initramfs.cpio
	cd $(METALPROBE_IMAGE_DIR) && ironcore-image build --tag "$(METALPROBE_BOOT_IMAGE)" \
		--config "arch=amd64,initramfs=./bin/initramfs.cpio,kernel=$$(kernel use "$(KERNEL_VERSION)" --dir ./bin -f path)/vmlinuz"

metalprobe-image-push: ## Push the built metalprobe boot image (requires ghcr.io auth)
	cd $(METALPROBE_IMAGE_DIR) && ironcore-image push "$(METALPROBE_BOOT_IMAGE)"
