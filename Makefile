CHAINSAW ?= chainsaw

COMPATIBILITY_TEST_DIR := tests/compatibility
COMPATIBILITY_VALUES ?= basic-go
COMPATIBILITY_VALUES_FILE = $(COMPATIBILITY_TEST_DIR)/values-$(COMPATIBILITY_VALUES).yaml
ASSERT_TIMEOUT ?= 15m
CHAINSAW_EXTRA_FLAGS ?=

.PHONY: help
help: ## Show available targets
	@echo "test framework targets:"
	@echo ""
	@echo "  compatibility tests:"
	@echo "    values via COMPATIBILITY_VALUES (default basic-go;"
	@echo "      e.g. contoso-go, containerlab-node1, containerlab-node2)"
	@echo "    assert timeout via ASSERT_TIMEOUT (default 15m; e.g. ASSERT_TIMEOUT=5m)"
	@echo "    extra chainsaw flags via CHAINSAW_EXTRA_FLAGS (e.g. CHAINSAW_EXTRA_FLAGS=\"--skip-delete -v\")"
	@echo "    test-compatibility           (A1, A2)"
	@echo "    test-compatibility-a1"
	@echo "    test-compatibility-a2"
	@echo "    test-compatibility-b         (B1-B4)"
	@echo "    test-compatibility-b1        (power on/off via Server spec)"
	@echo "    test-compatibility-b2        (power ops via operation annotation)"
	@echo "    test-compatibility-b3        (BMC reset)"
	@echo "    test-compatibility-b4        (indicator LED)"
	@echo ""

.PHONY: test-compatibility test-compatibility-a1 test-compatibility-a2
test-compatibility: ## Run A compatibility chainsaw tests (A1, A2)
	$(CHAINSAW) test --values $(COMPATIBILITY_VALUES_FILE) --parallel 1 --assert-timeout $(ASSERT_TIMEOUT) $(CHAINSAW_EXTRA_FLAGS) \
		$(COMPATIBILITY_TEST_DIR)/a1-bmc-registration \
		$(COMPATIBILITY_TEST_DIR)/a2-discovery

test-compatibility-a1: ## Run A1 BMC registration
	$(CHAINSAW) test --values $(COMPATIBILITY_VALUES_FILE) --parallel 1 --assert-timeout $(ASSERT_TIMEOUT) $(CHAINSAW_EXTRA_FLAGS) $(COMPATIBILITY_TEST_DIR)/a1-bmc-registration

test-compatibility-a2: ## Run A2 discovery
	$(CHAINSAW) test --values $(COMPATIBILITY_VALUES_FILE) --parallel 1 --assert-timeout $(ASSERT_TIMEOUT) $(CHAINSAW_EXTRA_FLAGS) $(COMPATIBILITY_TEST_DIR)/a2-discovery

.PHONY: test-compatibility-b test-compatibility-b1 test-compatibility-b2 test-compatibility-b3 test-compatibility-b4
test-compatibility-b: ## Run all B power-management tests (B1-B4)
	$(CHAINSAW) test --values $(COMPATIBILITY_VALUES_FILE) --parallel 1 --assert-timeout $(ASSERT_TIMEOUT) $(CHAINSAW_EXTRA_FLAGS) \
		$(COMPATIBILITY_TEST_DIR)/b1-power-spec \
		$(COMPATIBILITY_TEST_DIR)/b2-power-annotation \
		$(COMPATIBILITY_TEST_DIR)/b3-bmc-reset \
		$(COMPATIBILITY_TEST_DIR)/b4-indicator-led

test-compatibility-b1: ## Run B1 power on/off via Server spec
	$(CHAINSAW) test --values $(COMPATIBILITY_VALUES_FILE) --parallel 1 --assert-timeout $(ASSERT_TIMEOUT) $(CHAINSAW_EXTRA_FLAGS) $(COMPATIBILITY_TEST_DIR)/b1-power-spec

test-compatibility-b2: ## Run B2 power operations via operation annotation
	$(CHAINSAW) test --values $(COMPATIBILITY_VALUES_FILE) --parallel 1 --assert-timeout $(ASSERT_TIMEOUT) $(CHAINSAW_EXTRA_FLAGS) $(COMPATIBILITY_TEST_DIR)/b2-power-annotation

test-compatibility-b3: ## Run B3 BMC reset
	$(CHAINSAW) test --values $(COMPATIBILITY_VALUES_FILE) --parallel 1 --assert-timeout $(ASSERT_TIMEOUT) $(CHAINSAW_EXTRA_FLAGS) $(COMPATIBILITY_TEST_DIR)/b3-bmc-reset

test-compatibility-b4: ## Run B4 indicator LED
	$(CHAINSAW) test --values $(COMPATIBILITY_VALUES_FILE) --parallel 1 --assert-timeout $(ASSERT_TIMEOUT) $(CHAINSAW_EXTRA_FLAGS) $(COMPATIBILITY_TEST_DIR)/b4-indicator-led
