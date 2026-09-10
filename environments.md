# Environments

This repository contains virtualised or containerised infrastructure environments that mock or emulate physical BMC/server nodes. They don't relate to running tests against a custom BMC.

 Refer to the `make help` target in every environment's subdirectory for usage.

## Supporting Environments

### KIND environment
Manages a [kind](https://kind.sigs.k8s.io/) cluster to run the metal-operator and its dependencies. To simulate BMCs and Servers, it runs a Go-based Redfish Mock Server (modified version of the metal-operator's `bmc/mock/main.go`) that supports using system-specific redfish client mock data like the [DMTF mockup server](https://github.com/DMTF/Redfish-Mockup-Server) but has support for dynamic functions like simulating reboots. The server runs once per client data, i.e. BMC.
To simulate booting Servers to run the `metalprobe` tool, a custom `boot-operator`-like implementation runs the metalprobe agent once per discovered `ServerBootConfiguration` and reports back bogus data. This works fine for simple tests.

### Vagrant environment
Manages a [vagrant](https://developer.hashicorp.com/vagrant)-based environment that provides a network setup as close to a physical environment as possible. Its primary focus is to provide a reference setup for a physical lab. It supports development for scripts, ansible playbooks etc. that can be used to setup actual infrastructure. It does not support running tests against its nodes. **Its current state is a work in progress. It can probably be replaced by a containerlab-based setup.**

## Predefined values
A set of predefined values that point to BMCs deployed via this repository exist in their respective environment's directories:
- `infra/kind/values-basic-go.yaml`
- `infra/kind/values-contoso-go.yaml`

## Caveats
### Dependencies on forks
#### Metal-operator
The `kind`-environment depends on two services that currently live in a [fork of the metal-operator](https://github.com/simontesar/metal-operator):
* A Go implementation of a [redfish mock server](https://github.com/simontesar/metal-operator/blob/dell/bmc/mock/main.go) that is included in the upstream metal-operator for testing but modified in the fork to support some dynamic features like `lastResetTime` and replaceable client mock data to be able to test against mocks of specific BMC models.
* The `metalprobe-mock-controller` that watches `ServerBootConfigs` for BMC mocks and runs a `metalprobe` agent for every instance. It simulates a server controlled by the BMC mock booting up and running `metalprobe` to report to the metal-operator's registry. The reason it lives in the fork is that the `probe`-package of the metal-operator is internal.
