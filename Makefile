CHAINSAW ?= chainsaw

TEST_DIR := tests
VALUES ?= infra/kind/values-basic-go.yaml
ASSERT_TIMEOUT ?= 15m
CHAINSAW_EXTRA_FLAGS ?=

CHAINSAW_RUN = $(CHAINSAW) test --values $(VALUES) --parallel 1 --assert-timeout $(ASSERT_TIMEOUT) $(CHAINSAW_EXTRA_FLAGS)

TESTS := \
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
	@echo "  tests:"
	@echo "    * values via VALUES (default infra/kind/values-basic-go.yaml)"
	@echo "    * assert timeout via ASSERT_TIMEOUT (default 15m; e.g. ASSERT_TIMEOUT=5m)"
	@echo "    * extra chainsaw flags via CHAINSAW_EXTRA_FLAGS (e.g. CHAINSAW_EXTRA_FLAGS=\"--skip-delete -v\")"
	@echo ""
	@echo "    test                             (run every test)"
	@echo "    test/01-bmc-registration         (BMC registration)"
	@echo "    test/02-discovery                (server discovery and inventory)"
	@echo "    test/03-power-annotation         (power ops via operation annotation)"
	@echo "    test/04-bmc-reset                (BMC reset)"
	@echo "    test/05-indicator-led            (indicator LED)"
	@echo "    test/06-biossettings-noreboot    (BIOSSettings, non-reboot setting)"
	@echo "    test/07-biossettings-reboot      (BIOSSettings, reboot-required setting)"
	@echo "    test/08-bmcsettings              (BMCSettings, Manager attribute; needs a Dell BMC)"
	@echo "    test/09-persistent-boot-order    (persistent boot order)"
	@echo ""

.PHONY: test $(addprefix test/,$(TESTS))

test: ## Run every test
	$(CHAINSAW_RUN) $(addprefix $(TEST_DIR)/,$(TESTS))

$(addprefix test/,$(TESTS)): test/%: ## Run a single test
	$(CHAINSAW_RUN) $(TEST_DIR)/$*
