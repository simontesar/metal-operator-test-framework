# metal-operator test framework

## Test suite
The `tests/compatibility` directory contains a suite of compatibility tests based on [chainsaw](https://kyverno.github.io/chainsaw/latest/). Every test case creates k8s resources in steps and asserts their status before proceeding to the next steps and implements common metal-operator workflows. Tests are independent from the infrastructure they run on and respect `KUBECONFIG`.

### Requirements
* [chainsaw](https://kyverno.github.io/chainsaw/latest/)
* A metal-operator installation and BMC to run tests against. This repository usually uses the locally virtualised [metal-lab](https://github.com/simontesar/metal-lab).

### Usage
The server to run a test against is configured by passing a values file to chainsaw. The default file is `infra/kind/values-basic-go.yaml` that points to a redfish mock setup in the `kind` environment and can be overridden via `COMPATIBILITY_VALUES`.

```bash
make test-compatibility                                                                    # Run all cases
make test-compatibility-01                                                                 # Run a specific case
make test-compatibility-03 COMPATIBILITY_VALUES=/path/to/metal-lab/values-containerlab-node1.yaml # Run against a specific BMC.
```

### Predefined values
A set of predefined values that point to BMCs deployed via this repository exist in their respective environment's directories:
- `infra/kind/values-basic-go.yaml`
- `infra/kind/values-contoso-go.yaml`

The `metal-lab` repository (a standalone containerlab-based environment, see below) ships its own equivalent `values-containerlab-node1.yaml` / `values-containerlab-node2.yaml`.

## Supporting Environments
This repository contains virtualised or containerised infrastructure environments that mock or emulate physical BMC/server nodes. Refer to the `make help` target in every environment's subdirectory for usage.

### KIND environment
Manages a [kind](https://kind.sigs.k8s.io/) cluster to run the metal-operator and its dependencies. To simulate BMCs and Servers, it runs a Go-based Redfish Mock Server (modified version of the metal-operator's `bmc/mock/main.go`) that supports using system-specific redfish client mock data like the [DMTF mockup server](https://github.com/DMTF/Redfish-Mockup-Server) but has support for dynamic functions like simulating reboots. The server runs once per client data, i.e. BMC.
To simulate booting Servers to run the `metalprobe` tool, a custom `boot-operator`-like implementation runs the metalprobe agent once per discovered `ServerBootConfiguration` and reports back bogus data. This works fine for simple tests.

### Vagrant environment
Manages a [vagrant](https://developer.hashicorp.com/vagrant)-based environment that provides a network setup as close to a physical environment as possible. Its primary focus is to provide a reference setup for a physical lab. It supports development for scripts, ansible playbooks etc. that can be used to setup actual infrastructure. It does not support running tests against its nodes. **Its current state is a work in progress. It can probably be replaced by a containerlab-based setup.**

## Caveats
### Dependencies on forks
#### Metal-operator
The `kind`-environment depends on two services that currently live in a [fork of the metal-operator](https://github.com/simontesar/metal-operator):
* A Go implementation of a [redfish mock server](https://github.com/simontesar/metal-operator/blob/dell/bmc/mock/main.go) that is included in the upstream metal-operator for testing but modified in the fork to support some dynamic features like `lastResetTime` and replaceable client mock data to be able to test against mocks of specific BMC models.
* The `metalprobe-mock-controller` that watches `ServerBootConfigs` for BMC mocks and runs a `metalprobe` agent for every instance. It simulates a server controlled by the BMC mock booting up and running `metalprobe` to report to the metal-operator's registry. The reason it lives in the fork is that the `probe`-package of the metal-operator is internal.
