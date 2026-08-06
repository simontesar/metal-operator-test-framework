# metal-operator test framework

## Test suite
The `tests/compatibility` directory contains a suite of compatibility tests based on [chainsaw](https://kyverno.github.io/chainsaw/latest/). Every test case creates k8s resources in steps and and asserts their status before proceeding to the next steps and implements common metal-operator workflows. Tests are independent from the infrastructure they run on and respect `KUBECONFIG`.

### Requirements
* [chainsaw](https://kyverno.github.io/chainsaw/latest/)

### Usage
The server to run a test against is configured by passing a values file to chainsaw. The default file is `basic-go` that points to a redfish mock setup in the `kind` environment and can be overridden via `COMPATIBILITY_VALUES`.

```bash
make test-compatibility                                            # Run all tests
make test-compatibility-b                                          # Run a specific category of tests
make test-compatibility-a1                                         # Run a specific case
make test-compatibility-b2 COMPATIBILITY_VALUES=containerlab-node1 # Run against a specific BMC.
```

### Predefined values
A set of predefinied values that point to BMCs deployed via this repository also exist in the test directory:
- `tests/compatibility/values-basic-go.yaml`
- `tests/compatibility/values-contoso-go.yaml`
- `tests/compatibility/values-containerlab-node1.yaml`
- `tests/compatibility/values-containerlab-node1.yaml`

## Environments
This repository contains three virtualized or containerised infrastructure environments that mock or emulate pyhsical BMC/server nodes. Refer to the `make help` target in every environments subdirectory for usage.

### KIND environment
Manages a [kind](https://kind.sigs.k8s.io/) cluster to run the metal-operator and its dependencies. To simulate BMCs and Servers, it runs a Go-based Redfish Mock Server (modified version of the metal-operator's `bmc/mock/main.go`) that supports using system-specfic redfish client mock data like the [DMTF mockup server](https://github.com/DMTF/Redfish-Mockup-Server) but has support for dynamic functions like simulating reboots. The server runs once per client data, i.e. BMC.
To simulate booting Servers to run the `metalprobe` tool, a custom `boot-operator`-like implementation runs the metalprobe agent once per discovered `ServerBootConfiguration` and reports back bogus data. This works fine for simple tests.

### Containerlab environment
Manages a [containerlab](https://containerlab.dev/)-based environment that mimics a more sophisticated network setup and and introduces two [qemu-bmc](https://github.com/simontesar/qemu-bmc)-based BMCs/Servers to test against. One Go-based and redfish-compatible BMC pernode manages a virtual machine via qemu that supports booting via PXE or httpboot. This setup aims to support all features of the metal-operator without the need for additional physical infrastructure.

### Vagrant environment
Manages a [vagrant](https://developer.hashicorp.com/vagrant)-based environment that provides a network setup as close to a physical environment as possible. Its primary focus is to provide a reference setup for a physical lab. It supports development for scripts, ansible playbooks etc. that can be used to setup actual infrastructure. It does not support running tests against its nodes. **Its current state is a work in progress. In can probably be replaced by a separate containerlab setup or my modifying the existing containerlab setup to use manual k8s installation.**
