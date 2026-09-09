# Capability Matrix

This document specifies sets of capabilities a BMC needs to support to function with the metal-operator. Right now there is essentially one capability per method of the [`bmc.BMC`](https://github.com/ironcore-dev/metal-operator/blob/f5f9b8121c3180ee40f3c672476ab14f7109562f/bmc/bmc.go#L192)-interface of the metal-operator.

## Description of columns in capability tables

| Column | Description |
|---|---|
| **Capability id** | A key identifying the capability. |
| **`BMC` method** | The method of the `BMC` interface in the metal-operator the row stands for. |
| **Level** | How important the capability is. |
| **Redfish** | The Redfish path/action the BMC must expose for the capability to work. |
| **Redfish request body** | An example request payload for write operations. |
| **test** | The Chainsaw test under `tests/` that exercises this today (via metal-operator CRDs). |

## Conformance levels

| Level | Description |
|---|---|
| `MUST` | Core functions like `BMC`- `Server`- and `ServerClaim`-reconciliatio or power management cannot complete without it. |
| `SHOULD` | A first-class workflow like `BIOSSettings`- and `ServerMaintenance`-reconciliation or persistent boot order and locator LED depends on it.|
| `OPTIONAL` | Opt-in features like firmware upgrade, account management, event subscriptions and BMC settings. |

---

## PowerController - power on/off/cycle

| Capability id | `BMC` method | Level | Redfish API | Redfish request body | test |
|---|---|:---:|---|---|---|
| `power.on` | `PowerOn` | MUST | `POST` `#ComputerSystem.Reset` | `{"ResetType": "On"}` | `tests/03-power-annotation` |
| `power.off-graceful` | `PowerOff` | MUST | `POST` `#ComputerSystem.Reset` | `{"ResetType": "GracefulShutdown"}` | `tests/03-power-annotation` |
| `power.off-force` | `ForcePowerOff` | MUST | `POST` `#ComputerSystem.Reset` | `{"ResetType": "ForceOff"}` | `tests/03-power-annotation` |
| `power.wait-state` | `WaitForServerPowerState` | MUST | `GET` `ComputerSystem.PowerState` | - | `tests/03-power-annotation` |

## BootController - boot order & one-time override

| Capability id | `BMC` method | Level | Redfish API | Redfish request body | test |
|---|---|:---:|---|---|---|
| `boot.override-pxe` | `SetBootOverride` | MUST | `PATCH` `ComputerSystem` | `{"Boot": {"BootSourceOverrideEnabled": "Once", "BootSourceOverrideTarget": "Pxe", "BootSourceOverrideMode": "UEFI"}}` | `tests/02-discovery` |
| `boot.order-get` | `GetBootOrder` | SHOULD | `GET` `ComputerSystem.Boot.BootOrder` | - | `tests/09-persistent-boot-order` |
| `boot.order-set` | `SetBootOrder` | SHOULD | `PATCH` `ComputerSystem` | `{"Boot": {"BootOrder": ["<BootOptionReference>", "…"], "BootSourceOverrideEnabled": "Continuous", "BootSourceOverrideTarget": "None"}}` | `tests/09-persistent-boot-order` |

## SystemInspector - inventory

| Capability id | `BMC` method | Level | Redfish API | Redfish request body | test |
|---|---|:---:|---|---|---|
| `inventory.systems` | `GetSystems` | MUST | `GET` `/redfish/v1/Systems` collection; members need `UUID` and `Boot.BootSourceOverrideTarget` | - | `tests/02-discovery` |
| `inventory.system-info` | `GetSystemInfo` | MUST | `GET` `ComputerSystem` - `Manufacturer`, `Model`, `SerialNumber`, `SKU`, `PowerState`, `Status`, `MemorySummary.TotalSystemMemoryGiB`, `BiosVersion`, `IndicatorLED` | - | `tests/01-bmc-registration`, `tests/02-discovery` |
| `inventory.processors` | `GetProcessors` | SHOULD | `GET` `ComputerSystem/Processors` collection (`Processor`) | - | `tests/02-discovery` |
| `inventory.storages` | `GetStorages` | SHOULD | `GET` `ComputerSystem/Storage` (`Storage`, `Drives`, `Volumes`); fallback `GET` `ComputerSystem/SimpleStorage` | - | `tests/02-discovery` |

## BIOSManager - BIOS version & attributes

| Capability id | `BMC` method | Level | Redfish API | Redfish request body | test |
|---|---|:---:|---|---|---|
| `bios.version` | `GetBiosVersion` | MUST | `GET` `ComputerSystem.BiosVersion` | - | `tests/01-bmc-registration` |
| `bios.attr-get` | `GetBiosAttributeValues` | SHOULD | `GET` `ComputerSystem/Bios.Attributes` + `GET` `/redfish/v1/Registries` | - | `tests/06-biossettings-noreboot` |
| `bios.attr-pending` | `GetBiosPendingAttributeValues` | SHOULD | `GET` `Bios` `@Redfish.Settings` + `GET` settings object `.Attributes` | - | `tests/07-biossettings-reboot` |
| `bios.attr-set-on-reset` | `SetBiosAttributesOnReset` | SHOULD | `PATCH` the `Bios` `@Redfish.Settings` settings object| `{"Attributes": {"<AttrName>": "<value>", …}, "@Redfish.SettingsApplyTime": {"ApplyTime": "OnReset"}}` | `tests/06-biossettings-noreboot`, `tests/07-biossettings-reboot` |
| `bios.attr-check` | `CheckBiosAttributes` | SHOULD | `GET` `/redfish/v1/Registries` | - | `tests/06-biossettings-noreboot` |

## BMCSettingsManager - BMC version & Manager attributes

| Capability id | `BMC` method | Level | Redfish API | Redfish request body | test |
|---|---|:---:|---|---|---|
| `bmc.version` | `GetBMCVersion` | MUST | `GET` `Manager.FirmwareVersion` | - | `tests/08-bmcsettings` |
| `bmc-settings.attr-get` | `GetBMCAttributeValues` | OPTIONAL | Manager attribute resource / `Manager` `@Redfish.Settings` - vendor-specific implementation | - | `tests/08-bmcsettings` |
| `bmc-settings.attr-pending` | `GetBMCPendingAttributeValues` | OPTIONAL | `GET` `Manager` `@Redfish.Settings` | - | `tests/08-bmcsettings` |
| `bmc-settings.set-immediate` | `SetBMCAttributesImmediately` | OPTIONAL | `PATCH` the `Manager` settings object, vendor-specific implementation | `{"Attributes": {"<AttrName>": "<value>", …}, "@Redfish.SettingsApplyTime": {"ApplyTime": "Immediate"}}` | `tests/08-bmcsettings` |
| `bmc-settings.attr-check` | `CheckBMCAttributes` | OPTIONAL | `GET` `/redfish/v1/Registries` | - | `tests/08-bmcsettings` |

## FirmwareUpdater - BIOS/BMC firmware upgrade

| Capability id | `BMC` method | Level | Redfish API | Redfish request body | test |
|---|---|:---:|---|---|---|
| `firmware.bios.upgrade` | `UpgradeBiosVersion` | OPTIONAL | `POST` `#UpdateService.SimpleUpdate` | `{"ImageURI": "<uri>", "TransferProtocol": "<proto>", "Targets": ["<bios-inventory-uri>"], "@Redfish.OperationApplyTime": "Immediate"}` | uncovered |
| `firmware.bios.task` | `GetBiosUpgradeTask` | OPTIONAL | `GET` task monitor / `TaskService` `Task` (`TaskState`, `TaskStatus`) | - | uncovered |
| `firmware.bmc.upgrade` | `UpgradeBMCVersion` | OPTIONAL | `POST` `#UpdateService.SimpleUpdate` | `{"ImageURI": "<uri>", "TransferProtocol": "<proto>", "Targets": ["<bmc-inventory-uri>"], "@Redfish.OperationApplyTime": "Immediate"}` | uncovered |
| `firmware.bmc.task` | `GetBMCUpgradeTask` | OPTIONAL | `GET` task monitor / `Task` | - | uncovered |
| `firmware.pending-check` | `CheckBMCPendingComponentUpgrade` | OPTIONAL | `GET` `UpdateService/FirmwareInventory` | - | uncovered |

## ManagerController - the BMC's own Manager resource

| Capability id | `BMC` method | Level | Redfish API | Redfish request body | test |
|---|---|:---:|---|---|---|
| `manager.get` | `GetManager` | MUST | `GET` `/redfish/v1/Managers` collection; match `Manager.UUID` | - | `tests/01-bmc-registration` |
| `manager.discover` | `DiscoverManager` | SHOULD | `GET` `/redfish/v1/Managers`; `Manager.GraphicalConsole` (`MaxConcurrentSessions`, `ConnectTypesSupported`) | - | uncovered |
| `manager.reset` | `ResetManager` | SHOULD | `POST` `#Manager.Reset` - value must be in `Manager.SupportedResetTypes` | `{"ResetType": "GracefulRestart"}` | `tests/04-bmc-reset` |

## AccountManager - BMC user accounts

| Capability id | `BMC` method | Level | Redfish API | Redfish request body | test |
|---|---|:---:|---|---|---|
| `account.create-update` | `CreateOrUpdateAccount` | OPTIONAL | `POST` `AccountService/Accounts`; fallback `PATCH` an existing / empty slot with the same fields | `{"UserName": "<name>", "Password": "<pw>", "RoleId": "<role>", "Enabled": true}` | uncovered |
| `account.delete` | `DeleteAccount` | OPTIONAL | `DELETE` the `ManagerAccount` URI or fallback to `PATCH`ing the slot | `{"UserName": "", "Enabled": false}` for PATCH fallback | uncovered |
| `account.list` | `GetAccounts` | OPTIONAL | `GET` `AccountService/Accounts` collection | - | uncovered |
| `account.service` | `GetAccountService` | OPTIONAL | `GET` `/redfish/v1/AccountService` | - | uncovered |

## IndicatorController - locator LED

| Capability id | `BMC` method | Level | Redfish API | Redfish request body | test |
|---|---|:---:|---|---|---|
| `indicator.set-led` | `SetIndicatorLED` | SHOULD | `PATCH` `ComputerSystem` | `{"IndicatorLED": "Lit"}` | `tests/05-indicator-led` |

## EventSubscriber - Redfish event subscriptions

| Capability id | `BMC` method | Level | Redfish API | Redfish request body | test |
|---|---|:---:|---|---|---|
| `events.subscribe` | `CreateEventSubscription` | OPTIONAL | `GET` `EventService` (`ServiceEnabled`), then `POST` `EventService/Subscriptions`; read the new URI from the `Location` header | `{"Destination": "<url>", "Protocol": "Redfish", "EventFormatType": "Event", "Context": "metal-operator"}` | uncovered |
| `events.unsubscribe` | `DeleteEventSubscription` | OPTIONAL | `DELETE` the `EventDestination` URI | - | uncovered |

# Coverage summary

| Chainsaw test | Capabilities touched |
|---|---|
| `tests/01-bmc-registration` | `manager.get`, `inventory.system-info`, `bios.version`, `bmc.version` |
| `tests/02-discovery` | `inventory.systems`, `inventory.system-info`, `inventory.processors`, `inventory.storages`, `power.on`, `boot.override-pxe` |
| `tests/03-power-annotation` | `power.on`, `power.off-graceful`, `power.off-force`, `power.reset`, `power.wait-state` |
| `tests/04-bmc-reset` | `manager.reset` |
| `tests/05-indicator-led` | `indicator.set-led` |
| `tests/06-biossettings-noreboot` | `bios.attr-get`, `bios.attr-set-on-reset`, `bios.attr-check` |
| `tests/07-biossettings-reboot` | `bios.attr-get`, `bios.attr-pending`, `bios.attr-set-on-reset`, `power.reset` |
| `tests/08-bmcsettings` | `bmc.version`, `bmc-settings.attr-get`, `bmc-settings.attr-pending`, `bmc-settings.set-immediate`, `bmc-settings.attr-check` |
| `tests/09-persistent-boot-order` | `boot.order-get`, `boot.order-set` |
