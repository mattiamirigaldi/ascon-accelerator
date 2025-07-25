# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

MAKEFLAGS=-j1

# The following variants require "CCW = 32" in test.py:
VARIANT = V1
# VARIANT = V2
# VARIANT = V3

# The following variants require "CCW = 64" in test.py:
# VARIANT = V4
# VARIANT = V5
# VARIANT = V6

### Regtool ###
REGTOOL_SCRIPT = ./utils/regtool.py
REGTOOL_DEST_DIR = ./rtl/ascon_init_only
REGTOOL_SRC_FILE_ASCON = ./data/ascon_regs.hjson
REGTOOL_SRC_FILE_SBOX = ./data/ascon_sbox.hjson
REGTOOL_SW_DEST_DIR = ./sw

# Verilator arguments
SIM ?= verilator
TOPLEVEL_LANG ?= verilog
EXTRA_ARGS += --threads 8
EXTRA_ARGS += --trace
EXTRA_ARGS += --trace-fst
# EXTRA_ARGS += --trace-threads 2
EXTRA_ARGS += --relative-includes
EXTRA_ARGS += -Wno-UNOPTFLAT
EXTRA_ARGS += -D$(VARIANT)

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = ascon_init

# MODULE is the basename of the Python test file
MODULE = test_ascon_init

# Set source and config files
ifeq (1,$(syn))
SURFER_RON = surfer/syn.ron
VERILOG_SOURCES = $(PWD)/syn/cmos_cells.v $(PWD)/syn.v
else
SURFER_RON = surfer/sim.ron
VERILOG_SOURCES = $(PWD)/rtl/ascon_init_only/ascon_init.sv
endif

# Include cocotb makefile only if cocotb-config exists
ifneq ($(shell which cocotb-config 2>/dev/null),)
include $(shell cocotb-config --makefiles)/Makefile.sim
endif

regtool:
	@echo "Running regtool to generate ASCON registers ..."
	$(PYTHON) $(REGTOOL_SCRIPT) -r -t $(REGTOOL_DEST_DIR) $(REGTOOL_SRC_FILE_ASCON)
	$(PYTHON) $(REGTOOL_SCRIPT) -r -t $(REGTOOL_DEST_DIR) $(REGTOOL_SRC_FILE_SBOX)
	$(PYTHON) $(REGTOOL_SCRIPT) -D $(REGTOOL_SRC_FILE_ASCON) > $(REGTOOL_SW_DEST_DIR)/ascon_regs.h
	$(PYTHON) $(REGTOOL_SCRIPT) -D $(REGTOOL_SRC_FILE_SBOX) > $(REGTOOL_SW_DEST_DIR)/ascon_sbox.h

verible:
	utils/format-verible;

syn:
	yosys -D${VARIANT} syn/syn.ys

surf:
	surfer -s $(SURFER_RON) dump.fst

clean::
	rm -rf syn.v results.xml

.PHONY: syn
