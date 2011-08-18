#!/bin/sh
set -e
ghdl -i ../../core/tdc_package.vhd ../../core/tdc_divider.vhd tb_divider.vhd
ghdl -m tb_divider
ghdl -r tb_divider
