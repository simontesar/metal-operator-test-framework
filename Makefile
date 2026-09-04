CHAINSAW ?= chainsaw

COMPATIBILITY_TEST_DIR := tests/compatibility
COMPATIBILITY_VALUES ?= infra/kind/values-basic-go.yaml
ASSERT_TIMEOUT ?= 15m
CHAINSAW_EXTRA_FLAGS ?=

CHAINSAW_RUN = $(CHAINSAW) test --values $(COMPATIBILITY_VALUES) --parallel 1 --assert-timeout $(ASSERT_TIMEOUT) $(CHAINSAW_EXTRA_FLAGS)

COMPATIBILITY_CASES := \
	01-bmc-registration \
	02-discovery \
	03-power-annotation \
	04-bmc-reset \
	05-indicator-led \
	06-biossettings-noreboot \
	07-biossettings-reboot \
	08-bmcsettings \
	09-persistent-boot-order

.PHONY: help
help: ## Show available targets
	@echo "test framework targets:"
	@echo ""
	@echo "  compatibility tests:"
	@echo "    * values via COMPATIBILITY_VALUES (default infra/kind/values-basic-go.yaml)"
	@echo "    * assert timeout via ASSERT_TIMEOUT (default 15m; e.g. ASSERT_TIMEOUT=5m)"
	@echo "    * extra chainsaw flags via CHAINSAW_EXTRA_FLAGS (e.g. CHAINSAW_EXTRA_FLAGS=\"--skip-delete -v\")"
	@echo ""
	@echo "    test-compatibility           (run every case)"
	@echo "    test-compatibility-all       (alias of test-compatibility)"
	@echo "    test-compatibility-01        (BMC registration)"
	@echo "    test-compatibility-02        (server discovery and inventory)"
	@echo "    test-compatibility-03        (power ops via operation annotation)"
	@echo "    test-compatibility-04        (BMC reset)"
	@echo "    test-compatibility-05        (indicator LED)"
	@echo "    test-compatibility-06        (BIOSSettings, non-reboot setting)"
	@echo "    test-compatibility-07        (BIOSSettings, reboot-required setting)"
	@echo "    test-compatibility-08        (BMCSettings, Manager attribute; needs a Dell BMC)"
	@echo "    test-compatibility-09        (persistent boot order)"
	@echo ""

.PHONY: test-compatibility test-compatibility-all
test-compatibility: ## Run every compatibility case
	$(CHAINSAW_RUN) $(addprefix $(COMPATIBILITY_TEST_DIR)/,$(COMPATIBILITY_CASES))

test-compatibility-all: test-compatibility ## Alias of test-compatibility

.PHONY: test-compatibility-01 test-compatibility-02 test-compatibility-03 test-compatibility-04 test-compatibility-05 test-compatibility-06 test-compatibility-07 test-compatibility-08 test-compatibility-09

test-compatibility-01: ## Run 01 BMC registration
	$(CHAINSAW_RUN) $(COMPATIBILITY_TEST_DIR)/01-bmc-registration

test-compatibility-02: ## Run 02 server discovery and inventory
	$(CHAINSAW_RUN) $(COMPATIBILITY_TEST_DIR)/02-discovery

test-compatibility-03: ## Run 03 power operations via operation annotation
	$(CHAINSAW_RUN) $(COMPATIBILITY_TEST_DIR)/03-power-annotation

test-compatibility-04: ## Run 04 BMC reset
	$(CHAINSAW_RUN) $(COMPATIBILITY_TEST_DIR)/04-bmc-reset

test-compatibility-05: ## Run 05 indicator LED
	$(CHAINSAW_RUN) $(COMPATIBILITY_TEST_DIR)/05-indicator-led

test-compatibility-06: ## Run 06 BIOSSettings, non-reboot setting
	$(CHAINSAW_RUN) $(COMPATIBILITY_TEST_DIR)/06-biossettings-noreboot

test-compatibility-07: ## Run 07 BIOSSettings, reboot-required setting
	$(CHAINSAW_RUN) $(COMPATIBILITY_TEST_DIR)/07-biossettings-reboot

test-compatibility-08: ## Run 08 BMCSettings, attribute change
	$(CHAINSAW_RUN) $(COMPATIBILITY_TEST_DIR)/08-bmcsettings

test-compatibility-09: ## Run 09 persistent boot order
	$(CHAINSAW_RUN) $(COMPATIBILITY_TEST_DIR)/09-persistent-boot-order
