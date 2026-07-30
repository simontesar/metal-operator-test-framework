KUSTOMIZE ?= kustomize
KUBECTL   ?= kubectl

KIND_CLUSTER_NAME ?= metal
REDFISH_CLIENTS_DIR ?= ../../redfish-mockup-clients

METAL_OPERATOR_DIR ?= ../../../metal-operator
METAL_OPERATOR_STACK ?= ../../config/metal-operator
CERT_MANAGER_VERSION ?= v1.17.1
CERT_MANAGER_MANIFEST ?= https://github.com/cert-manager/cert-manager/releases/download/$(CERT_MANAGER_VERSION)/cert-manager.yaml
CONTROLLER_IMG ?= controller:latest
METALDATA_IMG ?= metaldata:latest
BMC_MOCK_SERVER_IMG ?= mock-server:latest
IMG ?= metalprobe-mock-controller:latest
METALPROBE_MOCK_CONTROLLER_BIN ?= $(METAL_OPERATOR_DIR)/bin/metalprobe-mock-controller
METALPROBE_MOCK_CONTROLLER_STACK ?= ../../config/metalprobe-mock-controller

MOCKUP_INSTANCES := r660 r770 r7725 xe9712 gpu-dpu basic
GO_MOCKUP_INSTANCES := r660 r770 r7725 xe9712 gpu-dpu basic contoso
REDFISH_MOCKUPS_STACK ?= ../../config/redfish-mockups/instances

.PHONY: help deploy destroy \
	kind-create kind-delete \
	cert-manager-install cert-manager-wait \
	metal-operator-images metal-operator-deploy metal-operator-delete \
	metal-operator-deploy-wait \
	bmc-mock-server-docker-build bmc-mock-server-kind-load \
	metalprobe-mock-controller-build metalprobe-mock-controller-run \
	metalprobe-mock-controller-docker-build metalprobe-mock-controller-kind-load \
	metalprobe-mock-controller-apply metalprobe-mock-controller-delete \
	dmtf-mock-apply-all dmtf-mock-delete-all \
	go-mock-apply-all go-mock-delete-all

define mockup_instance_targets
.PHONY: dmtf-mock-apply-$(1)
dmtf-mock-apply-$(1): ## Apply the $(1) DMTF Redfish mockup overlay
	$(KUSTOMIZE) build $(REDFISH_MOCKUPS_STACK)/$(1) | $(KUBECTL) apply -f -

.PHONY: dmtf-mock-delete-$(1)
dmtf-mock-delete-$(1): ## Delete the $(1) DMTF Redfish mockup overlay
	$(KUSTOMIZE) build $(REDFISH_MOCKUPS_STACK)/$(1) | $(KUBECTL) delete -f -
endef

define go_mockup_instance_targets
.PHONY: go-mock-apply-$(1)
go-mock-apply-$(1): ## Apply the $(1) Go Redfish mockup overlay
	$(KUSTOMIZE) build $(REDFISH_MOCKUPS_STACK)/$(1)-go | $(KUBECTL) apply -f -

.PHONY: go-mock-delete-$(1)
go-mock-delete-$(1): ## Delete the $(1) Go Redfish mockup overlay
	$(KUSTOMIZE) build $(REDFISH_MOCKUPS_STACK)/$(1)-go | $(KUBECTL) delete -f -
endef

$(foreach inst,$(MOCKUP_INSTANCES),$(eval $(call mockup_instance_targets,$(inst))))
$(foreach inst,$(GO_MOCKUP_INSTANCES),$(eval $(call go_mockup_instance_targets,$(inst))))

help: ## Show available targets
	@grep -E '^[a-zA-Z0-9_.-]+:.*##' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*## "}; {printf "  %-24s %s\n", $$1, $$2}'

kind-create: ## Create the local kind cluster, mounting REDFISH_CLIENTS_DIR
	@kind get clusters 2>/dev/null | grep -qx "$(KIND_CLUSTER_NAME)" || \
		printf 'kind: Cluster\napiVersion: kind.x-k8s.io/v1alpha4\nnodes:\n- role: control-plane\n  extraMounts:\n  - hostPath: %s\n    containerPath: /redfish-clients\n    readOnly: true\n' "$(REDFISH_CLIENTS_DIR)" | \
		kind create cluster --name $(KIND_CLUSTER_NAME) --config=-

kind-delete: ## Destroy the local kind cluster
	kind delete cluster --name $(KIND_CLUSTER_NAME)

cert-manager-install: ## Install cert-manager from upstream release manifest
	$(KUBECTL) apply -f $(CERT_MANAGER_MANIFEST)

cert-manager-wait: ## Wait for cert-manager deployments to become available
	@until $(KUBECTL) get ns cert-manager >/dev/null 2>&1; do \
		echo "Waiting for cert-manager namespace..."; sleep 5; \
	done
	$(KUBECTL) wait --for=condition=Available \
		deployment/cert-manager -n cert-manager --timeout=300s
	$(KUBECTL) wait --for=condition=Available \
		deployment/cert-manager-webhook -n cert-manager --timeout=300s
	$(KUBECTL) wait --for=condition=Available \
		deployment/cert-manager-cainjector -n cert-manager --timeout=300s

metal-operator-images: ## Build and load controller/metaldata images into Kind
	$(MAKE) -C $(METAL_OPERATOR_DIR) docker-build \
		CONTROLLER_IMG=$(CONTROLLER_IMG) METALDATA_IMG=$(METALDATA_IMG)
	kind load docker-image $(CONTROLLER_IMG) $(METALDATA_IMG) \
		--name $(KIND_CLUSTER_NAME)

metal-operator-deploy: ## Deploy metal-operator via kustomize overlay
	$(MAKE) -C $(METAL_OPERATOR_DIR) manifests
	$(KUSTOMIZE) build $(METAL_OPERATOR_STACK) | $(KUBECTL) apply -f -

metal-operator-delete: ## Delete metal-operator kustomize overlay
	$(KUSTOMIZE) build $(METAL_OPERATOR_STACK) | \
		$(KUBECTL) delete -f - --ignore-not-found

metal-operator-deploy-wait: ## Install cert-manager and metal-operator, then wait
metal-operator-deploy-wait: cert-manager-install cert-manager-wait \
	metal-operator-images metal-operator-deploy
	@until $(KUBECTL) get ns metal-operator-system >/dev/null 2>&1; do \
		echo "Waiting for metal-operator-system namespace..."; sleep 5; \
	done
	@until $(KUBECTL) -n metal-operator-system \
		get deploy metal-operator-controller-manager >/dev/null 2>&1; do \
		echo "Waiting for metal-operator deployment..."; sleep 5; \
	done
	$(KUBECTL) wait --for=condition=Available \
		deployment/metal-operator-controller-manager \
		-n metal-operator-system --timeout=600s

deploy: kind-create metal-operator-deploy-wait \
	bmc-mock-server-kind-load \
	metalprobe-mock-controller-kind-load metalprobe-mock-controller-apply \
	dmtf-mock-apply-all go-mock-apply-all ## Create the kind cluster, deploy metal-operator, and stand up all mocks

destroy: kind-delete ## Tear down the kind cluster

bmc-mock-server-docker-build: ## Build bmc-mock-server container image
	cd $(METAL_OPERATOR_DIR) && docker build --target mock-server -t $(BMC_MOCK_SERVER_IMG) .

bmc-mock-server-kind-load: bmc-mock-server-docker-build ## Load bmc-mock-server image into Kind
	kind load docker-image $(BMC_MOCK_SERVER_IMG) --name $(KIND_CLUSTER_NAME)

metalprobe-mock-controller-build: ## Build metalprobe-mock-controller binary in metal-operator
	cd $(METAL_OPERATOR_DIR) && go build -o bin/metalprobe-mock-controller ./cmd/metalprobe-mock-controller

metalprobe-mock-controller-run: metalprobe-mock-controller-build ## Run metalprobe-mock-controller locally
	$(METALPROBE_MOCK_CONTROLLER_BIN) --registry-url=http://localhost:30000

metalprobe-mock-controller-docker-build: ## Build metalprobe-mock-controller container image
	cd $(METAL_OPERATOR_DIR) && docker build -f Dockerfile.metalprobe-mock-controller -t $(IMG) .

metalprobe-mock-controller-kind-load: metalprobe-mock-controller-docker-build ## Load image into Kind cluster
	kind load docker-image $(IMG) --name $(KIND_CLUSTER_NAME)

metalprobe-mock-controller-apply: ## Apply metalprobe-mock-controller to the cluster
	$(KUSTOMIZE) build $(METALPROBE_MOCK_CONTROLLER_STACK) | $(KUBECTL) apply -f -

metalprobe-mock-controller-delete: ## Delete metalprobe-mock-controller from the cluster
	$(KUSTOMIZE) build $(METALPROBE_MOCK_CONTROLLER_STACK) | $(KUBECTL) delete -f -

dmtf-mock-apply-all: $(addprefix dmtf-mock-apply-,$(MOCKUP_INSTANCES)) ## Apply all registered DMTF mockup overlays

dmtf-mock-delete-all: $(addprefix dmtf-mock-delete-,$(MOCKUP_INSTANCES)) ## Delete all registered DMTF mockup overlays

go-mock-apply-all: $(addprefix go-mock-apply-,$(GO_MOCKUP_INSTANCES)) ## Apply all registered Go mockup overlays

go-mock-delete-all: $(addprefix go-mock-delete-,$(GO_MOCKUP_INSTANCES)) ## Delete all registered Go mockup overlays
