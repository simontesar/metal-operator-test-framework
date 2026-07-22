CLAB     ?= clab
QEMU_IMG ?= qemu-img
TOPO     ?= infra.clab.yaml
DISK_SIZE ?= 20G
NODES    ?= node1 node2
VM_DIR   ?= vm
# Set SUDO=sudo if your user cannot create Docker networks / veths.
SUDO     ?=

.PHONY: help disks disks-clean dhcp-config deploy destroy inspect check

help: ## Show available targets
	@grep -E '^[a-zA-Z0-9_.-]+:.*##' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*## "}; {printf "  %-16s %s\n", $$1, $$2}'

check: ## Fail if required tools are missing
	@command -v $(QEMU_IMG) >/dev/null || \
		{ echo "error: $(QEMU_IMG) not found" >&2; exit 1; }
	@command -v $(CLAB) >/dev/null || \
		{ echo "error: $(CLAB) (containerlab) not found" >&2; exit 1; }

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
