# Capability Matrix

This document specifies sets of capabilities a BMC needs to support to function with the metal-operator. Right now there is essentially one capability per method of the [`bmc.BMC`](https://github.com/ironcore-dev/metal-operator/blob/4d2a4eb1a372c9a01602a5bda26f6c9489393918/bmc/bmc.go#L191)-interface of the metal-operator.

Which Chainsaw tests cover each capability is tracked in the [coverage document](coverage.md).

## Description of columns in capability tables

| Column | Description |
|---|---|
| **Capability id** | A key identifying the capability. |
| **`BMC` method** | The method of the `BMC` interface in the metal-operator the row stands for. |
| **Level** | How important the capability is. |
| **Redfish API** | The Redfish path/action the BMC must expose for the capability to work. |
| **Redfish request body** | An example request payload for write operations. |

## Conformance levels

| Level | Description |
|---|---|
| `MUST` | Core functions like `BMC`-, `Server`- and `ServerClaim`-reconciliation or power management cannot complete without it. |
| `SHOULD` | A first-class workflow like `BIOSSettings`- and `ServerMaintenance`-reconciliation or persistent boot order and locator LED depends on it. |
| `OPTIONAL` | Opt-in features like firmware upgrade, account management, event subscriptions and BMC settings. |

---
# Interfaces

## [PowerController](https://github.com/ironcore-dev/metal-operator/blob/4d2a4eb1a372c9a01602a5bda26f6c9489393918/bmc/bmc.go#L43)

| Capability id | `BMC` method | Level | Redfish API | Redfish request body |
|---|---|:---:|---|---|
| `power.on` | `PowerOn` | MUST | `POST` `#ComputerSystem.Reset` | `{"ResetType": "On"}` |
| `power.off-graceful` | `PowerOff` | MUST | `POST` `#ComputerSystem.Reset` | `{"ResetType": "GracefulShutdown"}` |
| `power.off-force` | `ForcePowerOff` | MUST | `POST` `#ComputerSystem.Reset` | `{"ResetType": "ForceOff"}` |
| `power.reset` | `Reset` | MUST | `POST` `#ComputerSystem.Reset` - reset type from `AnnotationToRedfishMapping` | `{"ResetType": "GracefulRestart" \| "ForceRestart" \| "PowerCycle" \| "ForceOff" \| "ForceOn"}` |
| `power.wait-state` | `WaitForServerPowerState` | MUST | `GET` `ComputerSystem.PowerState` | - |

## [BootController](https://github.com/ironcore-dev/metal-operator/blob/4d2a4eb1a372c9a01602a5bda26f6c9489393918/bmc/bmc.go#L61)

| Capability id | `BMC` method | Level | Redfish API | Redfish request body |
|---|---|:---:|---|---|
| `boot.override-pxe` | `SetBootOverride` | MUST | `PATCH` `ComputerSystem` | `{"Boot": {"BootSourceOverrideEnabled": "Once", "BootSourceOverrideTarget": "Pxe", "BootSourceOverrideMode": "UEFI"}}` |
| `boot.order-get` | `GetBootOrder` | SHOULD | `GET` `ComputerSystem.Boot.BootOrder` | - |
| `boot.order-set` | `SetBootOrder` | SHOULD | `PATCH` `ComputerSystem` | `{"Boot": {"BootOrder": ["<BootOptionReference>", "…"], "BootSourceOverrideEnabled": "Continuous", "BootSourceOverrideTarget": "None"}}` |

## [SystemInspector](https://github.com/ironcore-dev/metal-operator/blob/4d2a4eb1a372c9a01602a5bda26f6c9489393918/bmc/bmc.go#L75)

| Capability id | `BMC` method | Level | Redfish API | Redfish request body |
|---|---|:---:|---|---|
| `inventory.systems` | `GetSystems` | MUST | `GET` `/redfish/v1/Systems` collection; members need `UUID` and `Boot.BootSourceOverrideTarget` | - |
| `inventory.system-info` | `GetSystemInfo` | MUST | `GET` `ComputerSystem` - `Manufacturer`, `Model`, `SerialNumber`, `SKU`, `PowerState`, `Status`, `MemorySummary.TotalSystemMemoryGiB`, `BiosVersion`, `IndicatorLED` | - |
| `inventory.processors` | `GetProcessors` | SHOULD | `GET` `ComputerSystem/Processors` collection (`Processor`) | - |
| `inventory.storages` | `GetStorages` | SHOULD | `GET` `ComputerSystem/Storage` (`Storage`, `Drives`, `Volumes`); fallback `GET` `ComputerSystem/SimpleStorage` | - |

## [BIOSManager](https://github.com/ironcore-dev/metal-operator/blob/4d2a4eb1a372c9a01602a5bda26f6c9489393918/bmc/bmc.go#L90)

| Capability id | `BMC` method | Level | Redfish API | Redfish request body |
|---|---|:---:|---|---|
| `bios.version` | `GetBiosVersion` | MUST | `GET` `ComputerSystem.BiosVersion` | - |
| `bios.attr-get` | `GetBiosAttributeValues` | SHOULD | `GET` `ComputerSystem/Bios.Attributes` + `GET` `/redfish/v1/Registries` | - |
| `bios.attr-pending` | `GetBiosPendingAttributeValues` | SHOULD | `GET` `Bios` `@Redfish.Settings` + `GET` settings object `.Attributes` | - |
| `bios.attr-set-on-reset` | `SetBiosAttributesOnReset` | SHOULD | `PATCH` the `Bios` `@Redfish.Settings` settings object | `{"Attributes": {"<AttrName>": "<value>", …}, "@Redfish.SettingsApplyTime": {"ApplyTime": "OnReset"}}` |
| `bios.attr-check` | `CheckBiosAttributes` | SHOULD | `GET` `/redfish/v1/Registries` | - |

## [BMCSettingsManager](https://github.com/ironcore-dev/metal-operator/blob/4d2a4eb1a372c9a01602a5bda26f6c9489393918/bmc/bmc.go#L108)

| Capability id | `BMC` method | Level | Redfish API | Redfish request body |
|---|---|:---:|---|---|
| `bmc.version` | `GetBMCVersion` | MUST | `GET` `Manager.FirmwareVersion` | - |
| `bmc-settings.attr-get` | `GetBMCAttributeValues` | OPTIONAL | Manager attribute resource / `Manager` `@Redfish.Settings` - vendor-specific implementation | - |
| `bmc-settings.attr-pending` | `GetBMCPendingAttributeValues` | OPTIONAL | `GET` `Manager` `@Redfish.Settings` | - |
| `bmc-settings.set-immediate` | `SetBMCAttributesImmediately` | OPTIONAL | `PATCH` the `Manager` settings object, vendor-specific implementation | `{"Attributes": {"<AttrName>": "<value>", …}, "@Redfish.SettingsApplyTime": {"ApplyTime": "Immediate"}}` |
| `bmc-settings.attr-check` | `CheckBMCAttributes` | OPTIONAL | `GET` `/redfish/v1/Registries` | - |

## [FirmwareUpdater](https://github.com/ironcore-dev/metal-operator/blob/4d2a4eb1a372c9a01602a5bda26f6c9489393918/bmc/bmc.go#L127)

| Capability id | `BMC` method | Level | Redfish API | Redfish request body |
|---|---|:---:|---|---|
| `firmware.bios.upgrade` | `UpgradeBiosVersion` | OPTIONAL | `POST` `#UpdateService.SimpleUpdate` | `{"ImageURI": "<uri>", "TransferProtocol": "<proto>", "Targets": ["<bios-inventory-uri>"], "@Redfish.OperationApplyTime": "Immediate"}` |
| `firmware.bios.task` | `GetBiosUpgradeTask` | OPTIONAL | `GET` task monitor / `TaskService` `Task` (`TaskState`, `TaskStatus`) | - |
| `firmware.bmc.upgrade` | `UpgradeBMCVersion` | OPTIONAL | `POST` `#UpdateService.SimpleUpdate` | `{"ImageURI": "<uri>", "TransferProtocol": "<proto>", "Targets": ["<bmc-inventory-uri>"], "@Redfish.OperationApplyTime": "Immediate"}` |
| `firmware.bmc.task` | `GetBMCUpgradeTask` | OPTIONAL | `GET` task monitor / `Task` | - |
| `firmware.pending-check` | `CheckBMCPendingComponentUpgrade` | OPTIONAL | `GET` `UpdateService/FirmwareInventory` | - |

## [ManagerController](https://github.com/ironcore-dev/metal-operator/blob/4d2a4eb1a372c9a01602a5bda26f6c9489393918/bmc/bmc.go#L146)

| Capability id | `BMC` method | Level | Redfish API | Redfish request body |
|---|---|:---:|---|---|
| `manager.get` | `GetManager` | MUST | `GET` `/redfish/v1/Managers` collection; match `Manager.UUID` | - |
| `manager.discover` | `DiscoverManager` | SHOULD | `GET` `/redfish/v1/Managers`; `Manager.GraphicalConsole` (`MaxConcurrentSessions`, `ConnectTypesSupported`) | - |
| `manager.reset` | `ResetManager` | SHOULD | `POST` `#Manager.Reset` - value must be in `Manager.SupportedResetTypes` | `{"ResetType": "GracefulRestart"}` |

## [AccountManager](https://github.com/ironcore-dev/metal-operator/blob/4d2a4eb1a372c9a01602a5bda26f6c9489393918/bmc/bmc.go#L158)

| Capability id | `BMC` method | Level | Redfish API | Redfish request body |
|---|---|:---:|---|---|
| `account.create-update` | `CreateOrUpdateAccount` | OPTIONAL | `POST` `AccountService/Accounts`; fallback `PATCH` an existing / empty slot with the same fields | `{"UserName": "<name>", "Password": "<pw>", "RoleId": "<role>", "Enabled": true}` |
| `account.delete` | `DeleteAccount` | OPTIONAL | `DELETE` the `ManagerAccount` URI or fall back to `PATCH`ing the slot | `{"UserName": "", "Enabled": false}` for PATCH fallback |
| `account.list` | `GetAccounts` | OPTIONAL | `GET` `AccountService/Accounts` collection | - |
| `account.service` | `GetAccountService` | OPTIONAL | `GET` `/redfish/v1/AccountService` | - |

## [IndicatorController](https://github.com/ironcore-dev/metal-operator/blob/4d2a4eb1a372c9a01602a5bda26f6c9489393918/bmc/bmc.go#L173)

| Capability id | `BMC` method | Level | Redfish API | Redfish request body |
|---|---|:---:|---|---|
| `indicator.set-led` | `SetIndicatorLED` | SHOULD | `PATCH` `ComputerSystem` | `{"IndicatorLED": "Lit"}` |

## [EventSubscriber](https://github.com/ironcore-dev/metal-operator/blob/4d2a4eb1a372c9a01602a5bda26f6c9489393918/bmc/bmc.go#L179)

| Capability id | `BMC` method | Level | Redfish API | Redfish request body |
|---|---|:---:|---|---|
| `events.subscribe` | `CreateEventSubscription` | OPTIONAL | `GET` `EventService` (`ServiceEnabled`), then `POST` `EventService/Subscriptions`; read the new URI from the `Location` header | `{"Destination": "<url>", "Protocol": "Redfish", "EventFormatType": "Event", "Context": "metal-operator"}` |
| `events.unsubscribe` | `DeleteEventSubscription` | OPTIONAL | `DELETE` the `EventDestination` URI | - |
