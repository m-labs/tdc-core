#!/bin/sh
set -e
ghdl -i ../../core/tdc_lbc.vhd tb_lbc.vhd
ghdl -m tb_lbc
ghdl -r tb_lbc
