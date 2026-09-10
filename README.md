# metal-operator test framework

This repository aims to provide a set of capabilities a BMC-implementation needs to support to be usable with the [metal-operator](https://github.com/ironcore-dev/metal-operator), and a set of tests to verify these capabilities. Its goal is to enable BMC vendors or users to run these tests against a BMC with minimal effort and more easily determine what capabilities their BMC may be missing or implementing incorrectly.

## Capabilities
Refer to [capability matrix](capability-matrix.md) for a list of capabilities and their descriptions. Refer to the [coverage document](coverage.md) for what tests cover which capabilities. Determine what your BMC might not implement by referring to a failed test.

## Test suite
The `tests` directory contains a suite of tests based on [chainsaw](https://kyverno.github.io/chainsaw/latest/). Every test case creates k8s resources in steps and asserts their status before proceeding. Tests are independent of from the infrastructure they run on and respect `KUBECONFIG`.

### Requirements
* [chainsaw](https://kyverno.github.io/chainsaw/latest/)
* A metal-operator installation and BMC to run tests against. This repository usually uses the locally virtualised [metal-lab](https://github.com/simontesar/metal-lab) to develop or verify functionality of the actual tests. You can use the lab setup as a reference.

### Usage
The server to run a test against is configured by passing a values file to chainsaw via `VALUES`. There is no default, tests fail unless `VALUES` is set. To just see the suite run, use `infra/kind/values-basic-go.yaml`, which points to a Redfish mock setup in the [`kind` environment](environments.md).

```bash
# Examples
make test VALUES=infra/kind/values-basic-go.yaml                                       # Run all tests
make test/01-bmc-registration VALUES=infra/kind/values-basic-go.yaml                   # Run a specific test
make test/03-power-annotation VALUES=/path/to/metal-lab/values-containerlab-node1.yaml # Run against a specific BMC
```

The [`metal-lab`](https://github.com/simontesar/metal-lab) repository provides a standalone containerlab-based environment and ships its own `VALUES` `values-containerlab-node1.yaml` / `values-containerlab-node2.yaml`. Clone the metal-lab repository and refer to its `README` to try the suite of tests without your own BMC.

### Bring your own BMC
To run tests against your own BMC, copy these values into a new file:
```yaml
bmcIP: "172.16.100.11"
bmcPort: 443
bmcScheme: https
username: admin
password: password
model: "Standard PC (Q35 + ICH9, 2009)"
firmwareVersion: "1.0.0"
powerState: "On"
biosVersion: "1.0.0"
biosSettingNoRebootValue: "+1-555-0100"
biosSettingRebootValue: "Bios"
bootOrder: ["Hdd", "Pxe", "Cd"]
bmcSettingKey: "EmailAlert.1.Address"
bmcSettingValue: "alerts@example.com"
```

Adjust the credentials and expectations to your respective values and point the tests to it:

```bash
make test/02-discovery VALUES=/path/to/new/file.yaml
```
