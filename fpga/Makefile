export REPORT_DIR =
export VIVADO_VERSION = 2021

CURR_DIR  = $(PWD)
BUILD_DIR = $(CURR_DIR)/build
TCL_DIR   = $(CURR_DIR)/tcl

TRACE_OPT  = "-notrace"
DATE_STR   = $(shell date +%y%m%d_%H%M%S)
REPORT_DIR = $(CURR_DIR)/reports/$(DATE_STR)_util_reports

.PHONY: build
build: clean_build
	mkdir -p $(BUILD_DIR) $(REPORT_DIR)
	cd $(BUILD_DIR) && \
	vivado -mode batch $(TRACE_OPT) -source $(TCL_DIR)/synth.tcl

.PHONY: clean_build
clean_build:
	rm -rf $(BUILD_DIR) $(REPORT_DIR)

.PHONY: clean_reports
clean_reports:
	rm -rf $(CURR_DIR)/reports/*
