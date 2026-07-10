.PHONY: help host-vlans host-vlans-clean up-master up-workers up destroy clean

help: ## Show available targets
	@grep -E '^[a-zA-Z0-9_.-]+:.*##' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*## "}; {printf "  %-18s %s\n", $$1, $$2}'

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
