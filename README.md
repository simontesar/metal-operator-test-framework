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
biosSettingNoRebootKey: "AssetTag"
biosSettingNoRebootValue: "compat-test-06"
biosSettingRebootValue: "Bios"
bmcSettingKey: "EmailAlert.1.Address"
bmcSettingValue: "alerts@example.com"
```

Adjust the credentials and expectations to your respective values and point the tests to it:

```bash
make ASSERT_TIMEOUT=2m VALUES=/path/to/new/file.yaml test/01-bmc-registration
```

You will probably encounter an error like:
```shell
chainsaw test --values /home/user/src/metal-operator-test-framework/values-t160.yaml --parallel 1 --assert-timeout 2m  tests/01-bmc-registration
Version: 0.2.15                                             
Loading default configuration...
- Using test file: chainsaw-test
- TestDirs [tests/01-bmc-registration]
- Quiet false                                               
- SkipDelete false                                          
- FailFast false                                            
- Namespace ''                                              
- FastNamespaceDeletion false                               
- FullName false                                            
- IncludeTestRegex ''                                       
- ExcludeTestRegex ''                                       
- ApplyTimeout 5s                                           
- AssertTimeout 2m0s                                        
- CleanupTimeout 30s                                        
- DeleteTimeout 15s                                         
- ErrorTimeout 30s                                          
- ExecTimeout 5s                                            
- DeletionPropagationPolicy Background
- Parallel 1                                                
- Values [/home/user/src/metal-operator-test-framework/values-t160.yaml]
- Template true                                             
- NoCluster false                                           
- PauseOnFailure false                                      
Loading tests...                                            
- 01-bmc-registration (tests/01-bmc-registration)
Loading values...                                           
Running tests...                                            
=== RUN   chainsaw                                          
=== PAUSE chainsaw                                          
=== CONT  chainsaw                                          
=== RUN   chainsaw/01-bmc-registration
    | 06:44:56 | 01-bmc-registration | @chainsaw          | CREATE    | OK    | v1/Namespace @ chainsaw-elegant-puma
    | 06:44:56 | 01-bmc-registration | register-bmc       | TRY       | BEGIN |
    | 06:44:56 | 01-bmc-registration | register-bmc       | APPLY     | RUN   | metal.ironcore.dev/v1alpha1/BMCSecret @ compatibility-chainsaw-elegant-puma
    | 06:44:56 | 01-bmc-registration | register-bmc       | CREATE    | OK    | metal.ironcore.dev/v1alpha1/BMCSecret @ compatibility-chainsaw-elegant-puma
    | 06:44:56 | 01-bmc-registration | register-bmc       | APPLY     | DONE  | metal.ironcore.dev/v1alpha1/BMCSecret @ compatibility-chainsaw-elegant-puma
    | 06:44:56 | 01-bmc-registration | register-bmc       | APPLY     | RUN   | metal.ironcore.dev/v1alpha1/BMC @ compatibility-chainsaw-elegant-puma
    | 06:44:56 | 01-bmc-registration | register-bmc       | CREATE    | OK    | metal.ironcore.dev/v1alpha1/BMC @ compatibility-chainsaw-elegant-puma
    | 06:44:56 | 01-bmc-registration | register-bmc       | APPLY     | DONE  | metal.ironcore.dev/v1alpha1/BMC @ compatibility-chainsaw-elegant-puma
    | 06:44:56 | 01-bmc-registration | register-bmc       | TRY       | END   |
    | 06:44:56 | 01-bmc-registration | assert-bmc-enabled | TRY       | BEGIN |
    | 06:44:56 | 01-bmc-registration | assert-bmc-enabled | ASSERT    | RUN   | metal.ironcore.dev/v1alpha1/BMC @ compatibility-chainsaw-elegant-puma
    | 06:46:56 | 01-bmc-registration | assert-bmc-enabled | ASSERT    | ERROR | metal.ironcore.dev/v1alpha1/BMC @ compatibility-chainsaw-elegant-puma
        === ERROR                                           
        -------------------------------------------------------------------
        metal.ironcore.dev/v1alpha1/BMC/compatibility-chainsaw-elegant-puma
        -------------------------------------------------------------------
        * status.firmwareVersion: Invalid value: "7.30.10.50": Expected value: "1.0.0"
        * status.model: Invalid value: "16G Monolithic": Expected value: "Standard PC (Q35 + ICH9, 2009)"

        --- expected                                        
        +++ actual                                          
        @@ -3,8 +3,8 @@                                     
         metadata:                                          
           name: compatibility-chainsaw-elegant-puma
         status:                                            
        -  firmwareVersion: 1.0.0
        -  model: Standard PC (Q35 + ICH9, 2009)
        +  firmwareVersion: 7.30.10.50
        +  model: 16G Monolithic
           powerState: "On"                                 
           state: Enabled                                   
    | 06:46:56 | 01-bmc-registration | assert-bmc-enabled | TRY       | END   |
    | 06:46:56 | 01-bmc-registration | register-bmc       | CLEANUP   | BEGIN |
    | 06:46:56 | 01-bmc-registration | register-bmc       | DELETE    | OK    | metal.ironcore.dev/v1alpha1/BMC @ compatibility-chainsaw-elegant-puma
    | 06:46:57 | 01-bmc-registration | register-bmc       | DELETE    | OK    | metal.ironcore.dev/v1alpha1/BMCSecret @ compatibility-chainsaw-elegant-puma
    | 06:46:57 | 01-bmc-registration | register-bmc       | CLEANUP   | END   |
    | 06:46:57 | 01-bmc-registration | @chainsaw          | CLEANUP   | BEGIN |
    | 06:46:57 | 01-bmc-registration | @chainsaw          | DELETE    | OK    | v1/Namespace @ chainsaw-elegant-puma
    | 06:47:02 | 01-bmc-registration | @chainsaw          | CLEANUP   | END   |
--- FAIL: chainsaw (125.32s)                                
    --- FAIL: chainsaw/01-bmc-registration (125.32s)
FAIL                                                        
Tests Summary...                                            
- Passed  tests 0                                           
- Failed  tests 1                                           
- Skipped tests 0                                           
Done with failures.                                         
Error: some tests failed                                    
make: *** [Makefile:59: test/01-bmc-registration] Error 1
```

A mismatch like this means the expectations in your `VALUES` file need to be adjusted to reality.
