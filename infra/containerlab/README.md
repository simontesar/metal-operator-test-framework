# Containerlab environment
The containerlab setup runs the following services:
* Two `alpine`-based switches that act as bridges for the IB and OOB network
* A `kind`-based Kubernetes cluster that runs:
* * The metal-operator
* * The boot-operator
* * FeDHCP
* * A TFTP server for PXE
* Two [qemu-bmc](https://github.com/simontesar/qemu-bmc)-based server nodes

The environment supports booting via PXE and httpboot.
## Usage
```shell
# Deploy and run all services
$ make deploy metal-operator-deploy-wait boot-operator-deploy-wait fedhcp-deploy-wait tftp-deploy-wait
…
# Inspect the architecture
$  containerlab inspect
07:25:31 INFO Parsing & checking topology file=infra.clab.yaml
╭─────────────────────────────────────┬──────────────────────┬───────────┬───────────────────────╮
│                 Name                │      Kind/Image      │   State   │     IPv4/6 Address    │
├─────────────────────────────────────┼──────────────────────┼───────────┼───────────────────────┤
│ k8s-control-plane                   │ ext-container        │ running   │ 172.18.0.2            │
│                                     │ kindest/node:v1.35.0 │           │ fc00:f853:ccd:e793::2 │
├─────────────────────────────────────┼──────────────────────┼───────────┼───────────────────────┤
│ clab-metal-operator-test-ib-switch  │ linux                │ running   │ 172.30.30.3           │
│                                     │ alpine:latest        │           │ N/A                   │
├─────────────────────────────────────┼──────────────────────┼───────────┼───────────────────────┤
│ clab-metal-operator-test-node1      │ linux                │ running   │ 172.30.30.2           │
│                                     │ qemu-bmc:latest      │ (healthy) │ N/A                   │
├─────────────────────────────────────┼──────────────────────┼───────────┼───────────────────────┤
│ clab-metal-operator-test-node2      │ linux                │ running   │ 172.30.30.4           │
│                                     │ qemu-bmc:latest      │ (healthy) │ N/A                   │
├─────────────────────────────────────┼──────────────────────┼───────────┼───────────────────────┤
│ clab-metal-operator-test-oob-switch │ linux                │ running   │ 172.30.30.5           │
│                                     │ alpine:latest        │           │ N/A                   │
├─────────────────────────────────────┼──────────────────────┼───────────┼───────────────────────┤
│ k8s-control-plane                   │ k8s-kind             │ running   │ 172.18.0.2            │
│                                     │ kindest/node:v1.35.0 │           │ fc00:f853:ccd:e793::2 │
╰─────────────────────────────────────┴──────────────────────┴───────────┴───────────────────────╯
```

Once you start a test the machines should boot and their consoles should be accessible at the respective URLs:
* https://localhost:4431/novnc/vnc.html
* https://localhost:4432/novnc/vnc.html

Note that the "connect" button will not display a screen until the machine is booted.

```shell
$ cd ../..
$ export KUBECONFIG=$PWD/infra/containerlab/kubeconfig.yaml
$ make test-compatibility-b1 COMPATIBILITY_VALUES=infra/containerlab/values-containerlab-node1.yaml CHAINSAW_EXTRA_FLAGS="--pause-on-failure"
```

Tear down the setup and optionally remove the VMs' disks:
```shell
$ make destroy clean-disks
…
``` 

## Caveats
* Needs `sudo` at some point during deployment to chmod the `kind` cluster's kubeconfig accordingly
