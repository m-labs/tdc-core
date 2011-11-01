#!/bin/bash

mkdir -p doc
wbgen2 -D ./doc/wrsw_helper_pll.html -V hpll_wb_slave.vhd -C ../../../software/include/hw/hpll_regs.h --cstyle defines --lang vhdl -K ../../sim/hpll_wb_regs.v hpll_wb.wb