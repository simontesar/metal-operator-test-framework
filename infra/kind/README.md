# Kind environment
The kind-based setup runs the following services in the cluster itself:
* The metal-operator, including its BMC mock server with the embedded "contoso" data
* One instance of the python-based [DMTF Redfish Mockup server](https://github.com/DMTF/Redfish-Mockup-Server) for every set of Dell client data
* One instance of the modified metal-operator BMC mock server for every set of Dell client data
* The `metalprobe-mock-controller` that simulates booting for a theoretical server attached to every BMC mock server by watching for `ServerBootConfigurations` and starting a `metalprobe` agent for every instance to mimic a real server reporting back data to the metal-operator's registry

Per default one BMC resource for every Dell mock server instance is created in the cluster.

## Usage
Deploy and inspect the complete setup:
```
$ make deploy
…
$ export KUBECONFIG=$PWD/kubeconfig.yaml
$ kubectl get pods -A
NAMESPACE               NAME                                                 READY   STATUS    RESTARTS   AGE
cert-manager            cert-manager-84b68949d9-8mwjj                        1/1     Running   0          6m20s
cert-manager            cert-manager-cainjector-77cb85f745-d48lt             1/1     Running   0          6m20s
cert-manager            cert-manager-webhook-967c999c4-pvncs                 1/1     Running   0          6m20s
kube-system             coredns-589f44dc88-2nx6r                             1/1     Running   0          6m20s
kube-system             coredns-589f44dc88-grss8                             1/1     Running   0          6m20s
kube-system             etcd-metal-control-plane                             1/1     Running   0          6m26s
kube-system             kindnet-rcmnq                                        1/1     Running   0          6m20s
kube-system             kube-apiserver-metal-control-plane                   1/1     Running   0          6m27s
kube-system             kube-controller-manager-metal-control-plane          1/1     Running   0          6m26s
kube-system             kube-proxy-d6jzp                                     1/1     Running   0          6m20s
kube-system             kube-scheduler-metal-control-plane                   1/1     Running   0          6m27s
local-path-storage      local-path-provisioner-855c7b7774-wfff7              1/1     Running   0          6m20s
metal-operator-system   metal-operator-controller-manager-789b89587c-5j5bl   1/1     Running   0          4m7s
metal-operator-system   metal-operator-metaldata-p48cb                       1/1     Running   0          4m7s
metal-operator-system   metalprobe-mock-controller-6f74c7bf58-dr2g4          1/1     Running   0          2m41s
metal-operator-system   redfish-basic-go-mockup-784b67c45c-gbc6s             1/1     Running   0          2m39s
metal-operator-system   redfish-basic-mockup-5c894b4cf8-9h675                1/1     Running   0          2m40s
metal-operator-system   redfish-contoso-go-mockup-b94dd58-h9lm6              1/1     Running   0          2m38s
metal-operator-system   redfish-gpu-dpu-go-mockup-dd99754c9-c78hh            1/1     Running   0          2m39s
metal-operator-system   redfish-gpu-dpu-mockup-7b6fb4898b-p9mf2              1/1     Running   0          2m40s
metal-operator-system   redfish-r660-go-mockup-64857469b7-9dsxj              1/1     Running   0          2m40s
metal-operator-system   redfish-r660-mockup-555d84fb5d-xl49v                 1/1     Running   0          2m41s
metal-operator-system   redfish-r770-go-mockup-7bff6db8cc-l7vdv              1/1     Running   0          2m39s
metal-operator-system   redfish-r770-mockup-74b987985b-7bps6                 1/1     Running   0          2m41s
metal-operator-system   redfish-r7725-go-mockup-687bf85694-d7bf6             1/1     Running   0          2m39s
metal-operator-system   redfish-r7725-mockup-6c7f949c98-bhr4m                1/1     Running   0          2m40s
metal-operator-system   redfish-xe9712-go-mockup-6d5849ddbf-8jg7k            1/1     Running   0          2m39s
metal-operator-system   redfish-xe9712-mockup-966fb558d-zvp5k                1/1     Running   0          2m40s
$ kubectl get bmc
NAME                        MACADDRESS   IP             MODEL            STATE     POWERSTATE   AGE
redfish-basic-go-mockup                  10.96.200.25   15G Monolithic   Enabled   On           3m
redfish-basic-mockup                     10.96.200.15   15G Monolithic   Enabled   On           3m1s
redfish-contoso-go-mockup                10.96.200.26   Joo Janta 200    Enabled   On           2m59s
redfish-gpu-dpu-go-mockup                10.96.200.24   16G Monolithic   Enabled   On           3m
redfish-gpu-dpu-mockup                   10.96.200.14   16G Monolithic   Enabled   On           3m1s
redfish-r660-go-mockup                   10.96.200.20   16G Monolithic   Enabled   On           3m1s
redfish-r660-mockup                      10.96.200.10   16G Monolithic   Enabled   On           3m2s
redfish-r770-go-mockup                   10.96.200.21   17G Monolithic   Enabled   On           3m
redfish-r770-mockup                      10.96.200.11   17G Monolithic   Enabled   On           3m2s
redfish-r7725-go-mockup                  10.96.200.22   17G Monolithic   Enabled   On           3m
redfish-r7725-mockup                     10.96.200.12   17G Monolithic   Enabled   On           3m1s
redfish-xe9712-go-mockup                 10.96.200.23   17G Monolithic   Enabled   On           3m
redfish-xe9712-mockup                    10.96.200.13   17G Monolithic   Enabled   On           3m1s
```

Run a test against the basic go instance:
```shell
$ cd ../..
$ export KUBECONFIG=$PWD/kubeconfig.yaml
$ make test-compatibility-b1 COMPATIBILITY_VALUES=infra/kind/values-basic-go.yaml CHAINSAW_EXTRA_FLAGS="--pause-on-failure"
```

Tear down:
```shell
$ cd -
$ make kind-delete
```