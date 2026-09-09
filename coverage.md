# Test Coverage

This document summarises what tests cover which capabilities in the [capability-matrix](capability-matrix.md).

* A capability is **covered** when running the test makes the operator invoke the method.
* A capability is verified when the test asserts that it has produced expected values.

## Common coverage

Some capabilities are covered by multiple tests implicitly because they share common workflows.
These rows/capabilities include the following placeholders in their `test` field:

| Placeholder | Description | Capability ids |
|---|---|---|
| `BMC Registration` | Test creates a `BMC` that results in a `Server` resource. | `manager.get`, `inventory.systems`, `inventory.system-info` |
| `Discovery` | Test waits for the `Server` to reach the `Available` state. | `power.on`, `power.off-graceful`, `power.wait-state`, `boot.override-pxe`, `bios.version`, `inventory.processors`, `inventory.storages` |

---

## Coverage by test

| Chainsaw test | Capability ids covered |
|---|---|
| `tests/01-bmc-registration` | `BMC Registration` |
| `tests/02-discovery` | `BMC Registration`, `Discovery` |
| `tests/03-power-annotation` | `BMC Registration`, `Discovery`, `power.reset` |
| `tests/04-bmc-reset` | `BMC Registration`, `manager.reset` |
| `tests/05-indicator-led` | `BMC Registration`, `Discovery`, `indicator.set-led` |
| `tests/06-biossettings-noreboot` | `BMC Registration`, `Discovery`, `bios.attr-get`, `bios.attr-pending`, `bios.attr-set-on-reset`, `bios.attr-check` |
| `tests/07-biossettings-reboot` | `BMC Registration`, `Discovery`, `bios.attr-get`, `bios.attr-pending`, `bios.attr-set-on-reset`, `bios.attr-check` |
| `tests/08-bmcsettings` | `BMC Registration`, `Discovery`, `bmc-settings.attr-get`, `bmc-settings.attr-pending`, `bmc-settings.set-immediate`, `bmc-settings.attr-check` |
| `tests/09-persistent-boot-order` | `BMC Registration`, `Discovery`, `boot.order-get`, `boot.order-set`, `power.reset` |

## Coverage by capability

| Capability id | test | verified |
|---|---|:---:|
| `power.on` | `Discovery` | yes |
| `power.off-graceful` | `Discovery` | yes |
| `power.off-force` | uncovered | - |
| `power.reset` | `tests/03-power-annotation`, `tests/09-persistent-boot-order` | no |
| `power.wait-state` | `Discovery` | yes |
| `boot.override-pxe` | `Discovery` | yes |
| `boot.order-get` | `tests/09-persistent-boot-order` | yes |
| `boot.order-set` | `tests/09-persistent-boot-order` | yes |
| `inventory.systems` | `BMC Registration` | yes |
| `inventory.system-info` | `BMC Registration` | yes |
| `inventory.processors` | `Discovery` | yes |
| `inventory.storages` | `Discovery` | no |
| `bios.version` | `Discovery`, `tests/06-biossettings-noreboot`, `tests/07-biossettings-reboot` | yes |
| `bios.attr-get` | `tests/06-biossettings-noreboot`, `tests/07-biossettings-reboot` | yes |
| `bios.attr-pending` | `tests/06-biossettings-noreboot`, `tests/07-biossettings-reboot` | yes |
| `bios.attr-set-on-reset` | `tests/06-biossettings-noreboot`, `tests/07-biossettings-reboot` | yes |
| `bios.attr-check` | `tests/06-biossettings-noreboot`, `tests/07-biossettings-reboot` | yes |
| `bmc.version` | uncovered | - |
| `bmc-settings.attr-get` | `tests/08-bmcsettings` | yes |
| `bmc-settings.attr-pending` | `tests/08-bmcsettings` | no |
| `bmc-settings.set-immediate` | `tests/08-bmcsettings` | yes |
| `bmc-settings.attr-check` | `tests/08-bmcsettings` | no |
| `firmware.bios.upgrade` | uncovered | - |
| `firmware.bios.task` | uncovered | - |
| `firmware.bmc.upgrade` | uncovered | - |
| `firmware.bmc.task` | uncovered | - |
| `firmware.pending-check` | uncovered | - |
| `manager.get` | `BMC Registration` | yes |
| `manager.discover` | uncovered | - |
| `manager.reset` | `tests/04-bmc-reset` | no |
| `account.create-update` | uncovered | - |
| `account.delete` | uncovered | - |
| `account.list` | uncovered | - |
| `account.service` | uncovered | - |
| `indicator.set-led` | `tests/05-indicator-led` | yes |
| `events.subscribe` | uncovered | - |
| `events.unsubscribe` | uncovered | - |
