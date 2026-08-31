CHAINSAW ?= chainsaw

COMPATIBILITY_TEST_DIR := tests/compatibility
COMPATIBILITY_VALUES ?= infra/kind/values-basic-go.yaml
ASSERT_TIMEOUT ?= 15m
CHAINSAW_EXTRA_FLAGS ?=

.PHONY: help
help: ## Show available targets
	@echo "test framework targets:"
	@echo ""
	@echo "  compatibility tests:"
	@echo "    * values via COMPATIBILITY_VALUES (default infra/kind/values-basic-go.yaml)"
	@echo "    * assert timeout via ASSERT_TIMEOUT (default 15m; e.g. ASSERT_TIMEOUT=5m)"
	@echo "    * extra chainsaw flags via CHAINSAW_EXTRA_FLAGS (e.g. CHAINSAW_EXTRA_FLAGS=\"--skip-delete -v\")"
	@echo ""
	@echo "    test-compatibility           (A1, A2)"
	@echo "    test-compatibility-a1"
	@echo "    test-compatibility-a2"
	@echo "    test-compatibility-b         (B1-B3)"
	@echo "    test-compatibility-b1        (power ops via operation annotation)"
	@echo "    test-compatibility-b2        (BMC reset)"
	@echo "    test-compatibility-b3        (indicator LED)"
	@echo "    test-compatibility-d         (D1-D3)"
	@echo "    test-compatibility-d1        (BIOSSettings, non-reboot setting)"
	@echo "    test-compatibility-d2        (BIOSSettings, reboot-required setting)"
	@echo "    test-compatibility-d3        (BMCSettings, Manager attribute; needs a Dell BMC)"
	@echo ""

.PHONY: test-compatibility test-compatibility-a1 test-compatibility-a2
test-compatibility: ## Run A compatibility chainsaw tests (A1, A2)
	$(CHAINSAW) test --values $(COMPATIBILITY_VALUES) --parallel 1 --assert-timeout $(ASSERT_TIMEOUT) $(CHAINSAW_EXTRA_FLAGS) \
		$(COMPATIBILITY_TEST_DIR)/a1-bmc-registration \
		$(COMPATIBILITY_TEST_DIR)/a2-discovery

test-compatibility-a1: ## Run A1 BMC registration
	$(CHAINSAW) test --values $(COMPATIBILITY_VALUES) --parallel 1 --assert-timeout $(ASSERT_TIMEOUT) $(CHAINSAW_EXTRA_FLAGS) $(COMPATIBILITY_TEST_DIR)/a1-bmc-registration

test-compatibility-a2: ## Run A2 discovery
	$(CHAINSAW) test --values $(COMPATIBILITY_VALUES) --parallel 1 --assert-timeout $(ASSERT_TIMEOUT) $(CHAINSAW_EXTRA_FLAGS) $(COMPATIBILITY_TEST_DIR)/a2-discovery

.PHONY: test-compatibility-b test-compatibility-b1 test-compatibility-b2 test-compatibility-b3
test-compatibility-b: ## Run all B power-management tests (B1-B3)
	$(CHAINSAW) test --values $(COMPATIBILITY_VALUES) --parallel 1 --assert-timeout $(ASSERT_TIMEOUT) $(CHAINSAW_EXTRA_FLAGS) \
		$(COMPATIBILITY_TEST_DIR)/b1-power-annotation \
		$(COMPATIBILITY_TEST_DIR)/b2-bmc-reset \
		$(COMPATIBILITY_TEST_DIR)/b3-indicator-led

test-compatibility-b1: ## Run B1 power operations via operation annotation
	$(CHAINSAW) test --values $(COMPATIBILITY_VALUES) --parallel 1 --assert-timeout $(ASSERT_TIMEOUT) $(CHAINSAW_EXTRA_FLAGS) $(COMPATIBILITY_TEST_DIR)/b1-power-annotation

test-compatibility-b2: ## Run B2 BMC reset
	$(CHAINSAW) test --values $(COMPATIBILITY_VALUES) --parallel 1 --assert-timeout $(ASSERT_TIMEOUT) $(CHAINSAW_EXTRA_FLAGS) $(COMPATIBILITY_TEST_DIR)/b2-bmc-reset

test-compatibility-b3: ## Run B3 indicator LED
	$(CHAINSAW) test --values $(COMPATIBILITY_VALUES) --parallel 1 --assert-timeout $(ASSERT_TIMEOUT) $(CHAINSAW_EXTRA_FLAGS) $(COMPATIBILITY_TEST_DIR)/b3-indicator-led

.PHONY: test-compatibility-d test-compatibility-d1 test-compatibility-d2 test-compatibility-d3
test-compatibility-d: ## Run all D settings tests (D1-D3)
	$(CHAINSAW) test --values $(COMPATIBILITY_VALUES) --parallel 1 --assert-timeout $(ASSERT_TIMEOUT) $(CHAINSAW_EXTRA_FLAGS) \
		$(COMPATIBILITY_TEST_DIR)/d1-biossettings-noreboot \
		$(COMPATIBILITY_TEST_DIR)/d2-biossettings-reboot \
		$(COMPATIBILITY_TEST_DIR)/d3-bmcsettings

test-compatibility-d1: ## Run D1 BIOSSettings, non-reboot setting
	$(CHAINSAW) test --values $(COMPATIBILITY_VALUES) --parallel 1 --assert-timeout $(ASSERT_TIMEOUT) $(CHAINSAW_EXTRA_FLAGS) $(COMPATIBILITY_TEST_DIR)/d1-biossettings-noreboot

test-compatibility-d2: ## Run D2 BIOSSettings, reboot-required setting
	$(CHAINSAW) test --values $(COMPATIBILITY_VALUES) --parallel 1 --assert-timeout $(ASSERT_TIMEOUT) $(CHAINSAW_EXTRA_FLAGS) $(COMPATIBILITY_TEST_DIR)/d2-biossettings-reboot

test-compatibility-d3: ## Run D3 BMCSettings, Manager attribute change (requires a Dell-manufacturer BMC)
	$(CHAINSAW) test --values $(COMPATIBILITY_VALUES) --parallel 1 --assert-timeout $(ASSERT_TIMEOUT) $(CHAINSAW_EXTRA_FLAGS) $(COMPATIBILITY_TEST_DIR)/d3-bmcsettings
