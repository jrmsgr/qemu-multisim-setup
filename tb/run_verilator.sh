#!/usr/bin/env bash

set -e

verilator --binary -j 0 --top-module top --trace-vcd \
    axi_pkg.sv \
    axe-dv-axi-adapter.sv \
    axe-dv-interrupt-adapter.sv \
    dv_axi_ram.sv \
    top.sv \
    -Wno-TIMESCALEMOD \
    -Wno-lint \
    +incdir+../multisim/src/core \
    +define+DV_AXI_RAM_UNBOUNDED \
    ../multisim/src/core/multisim_server.cpp \
    ../multisim/src/core/socket_server/server.cpp

./obj_dir/Vtop

