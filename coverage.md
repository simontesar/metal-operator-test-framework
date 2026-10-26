# Test Coverage

This document summarises what tests cover which capabilities in the [capability-matrix](capability-matrix.md).

* A capability is **covered** when running the test makes the operator invoke the method.
* A capability is **verified** when the test asserts that it has produced expected values.

## Common coverage

Some capabilities are covered by multiple tests implicitly because they share common workflows.
These rows/capabilities include the following placeholders in their `test` field:

| Placeholder        | Description                                                 | Capabilities covered                                                                                                                    |
|--------------------|-------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------|
| `BMC Registration` | Test creates a `BMC` that results in a `Server` resource.   | `manager.get`, `inventory.systems`, `inventory.system-info`                                                                             |
| `Discovery`        | Test waits for the `Server` to reach the `Available` state. | `power.on`, `power.off-graceful`, `power.wait-state`, `boot.override-pxe`, `bios.version`, `inventory.processors`, `inventory.storages` |

---

## Coverage by test

| Test                             | Capabilities covered                                                                                                                           |
|----------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------|
| `tests/01-bmc-registration`      | `BMC Registration`                                                                                                                             |
| `tests/02-discovery`             | `BMC Registration`, `Discovery`                                                                                                                |
| `tests/03-power-annotation`      | `BMC Registration`, `Discovery`, `power.reset`                                                                                                 |
| `tests/04-bmc-reset`             | `BMC Registration`, `manager.reset`                                                                                                            |
| `tests/05-indicator-led`         | `BMC Registration`, `Discovery`, `indicator.set-led`                                                                                           |
| `tests/06-biossettings-noreboot` | `BMC Registration`, `Discovery`, `bios.attr-get`, `bios.attr-pending`, `bios.attr-set-on-reset`, `bios.attr-check`                             |
| `tests/07-biossettings-reboot`   | `BMC Registration`, `Discovery`, `bios.attr-get`, `bios.attr-pending`, `bios.attr-set-on-reset`, `bios.attr-check`                             |
| `tests/08-bmcsettings`           | `BMC Registration`, `Discovery`, `bmc-settings.attr-get`, `bmc-settings.attr-pending`, `bmc-settings.set-immediate`, `bmc-settings.attr-check` |
| `tests/09-persistent-boot-order` | `BMC Registration`, `Discovery`, `boot.order-get`, `boot.order-set`, `power.on`, `power.off-graceful`                                          |
| `tests/10-bmcversion`            | `BMC Registration`, `Discovery`, `bmc.version`                                                                                                 |
| `tests/11-bmcuser`               | `BMC Registration`, `account.service`, `account.list`, `account.create-update`, `account.delete`                                               |
| `tests/12-force-power-off`       | `BMC Registration`, `Discovery`, `power.on`, `power.off-graceful`, `power.off-force`, `power.wait-state`, `boot.override-pxe`                  |
| `tests/13-event-subscriptions`   | `BMC Registration`, `events.subscribe`, `events.unsubscribe`, `events.list`, `events.test-event`, `events.delivery`                             |
| `tests/14-biosversion-upgrade`   | `BMC Registration`, `Discovery`, `bios.version`, `manager.reset`, `firmware.pending-check`, `firmware.bios.upgrade`, `firmware.bios.task`      |
| `tests/15-bmcversion-upgrade`    | `BMC Registration`, `Discovery`, `bmc.version`, `manager.reset`, `firmware.pending-check`, `firmware.bmc.upgrade`, `firmware.bmc.task`         |

## Coverage by capability

| Capability ID                | Covered by                                                                                                    | Verified |
|------------------------------|---------------------------------------------------------------------------------------------------------------|:--------:|
| `power.on`                   | `Discovery`                                                                                                   |   yes    |
| `power.off-graceful`         | `Discovery`                                                                                                   |   yes    |
| `power.off-force`            | `tests/12-force-power-off`, `tests/03-power-annotation` See **[0]**                                           |   yes    |
| `power.reset`                | `tests/03-power-annotation`                                                                                   |    no    |
| `power.wait-state`           | `Discovery`                                                                                                   |   yes    |
| `boot.override-pxe`          | `Discovery`                                                                                                   |   yes    |
| `boot.order-get`             | `tests/09-persistent-boot-order`                                                                              |   yes    |
| `boot.order-set`             | `tests/09-persistent-boot-order`                                                                              |   yes    |
| `inventory.systems`          | `BMC Registration`                                                                                            |   yes    |
| `inventory.system-info`      | `BMC Registration`                                                                                            |   yes    |
| `inventory.processors`       | `Discovery`                                                                                                   |   yes    |
| `inventory.storages`         | `Discovery`                                                                                                   |    no    |
| `bios.version`               | `Discovery`, `tests/06-biossettings-noreboot`, `tests/07-biossettings-reboot`, `tests/14-biosversion-upgrade` |   yes    |
| `bios.attr-get`              | `tests/06-biossettings-noreboot`, `tests/07-biossettings-reboot`                                              |   yes    |
| `bios.attr-pending`          | `tests/06-biossettings-noreboot`, `tests/07-biossettings-reboot`                                              |   yes    |
| `bios.attr-set-on-reset`     | `tests/06-biossettings-noreboot`, `tests/07-biossettings-reboot`                                              |   yes    |
| `bios.attr-check`            | `tests/06-biossettings-noreboot`, `tests/07-biossettings-reboot`                                              |   yes    |
| `bmc.version`                | `tests/10-bmcversion`, `tests/15-bmcversion-upgrade`                                                          |   yes    |
| `bmc-settings.attr-get`      | `tests/08-bmcsettings`                                                                                        |   yes    |
| `bmc-settings.attr-pending`  | `tests/08-bmcsettings`                                                                                        |    no    |
| `bmc-settings.set-immediate` | `tests/08-bmcsettings`                                                                                        |   yes    |
| `bmc-settings.attr-check`    | `tests/08-bmcsettings`                                                                                        |    no    |
| `firmware.bios.upgrade`      | `tests/14-biosversion-upgrade`                                                                                |   yes    |
| `firmware.bios.task`         | `tests/14-biosversion-upgrade`                                                                                |    no    |
| `firmware.bmc.upgrade`       | `tests/15-bmcversion-upgrade`                                                                                 |   yes    |
| `firmware.bmc.task`          | `tests/15-bmcversion-upgrade`                                                                                 |    no    |
| `firmware.pending-check`     | `tests/14-biosversion-upgrade`, `tests/15-bmcversion-upgrade`                                                 |    no    |
| `manager.get`                | `BMC Registration`                                                                                            |   yes    |
| `manager.discover`           | uncovered                                                                                                     |    -     |
| `manager.reset`              | `tests/04-bmc-reset`, `tests/14-biosversion-upgrade`, `tests/15-bmcversion-upgrade`                           |    no    |
| `account.create-update`      | `tests/11-bmcuser`                                                                                            |   yes    |
| `account.delete`             | `tests/11-bmcuser`                                                                                            |   yes    |
| `account.list`               | `tests/11-bmcuser`                                                                                            |   yes    |
| `account.service`            | `tests/11-bmcuser`                                                                                            |   yes    |
| `indicator.set-led`          | `tests/05-indicator-led`                                                                                      |   yes    |
| `events.subscribe`           | `tests/13-event-subscriptions`                                                                                |   yes    |
| `events.unsubscribe`         | `tests/13-event-subscriptions`                                                                                |   yes    |
| `events.list`                | `tests/13-event-subscriptions`                                                                                |   yes    |
| `events.test-event`          | `tests/13-event-subscriptions`                                                                                |   yes    |
| `events.delivery`            | `tests/13-event-subscriptions`                                                                                |   yes    |

#### Footnotes
**[0]**: The test is using the `Reset`-method of the `BMC` interface, but the result is the same capability being tested as using the `ForcePowerOff`-method.
