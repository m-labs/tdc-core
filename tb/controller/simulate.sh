#!/bin/sh
set -e
ghdl -i ../../core/tdc_package.vhd ../../core/tdc_divider.vhd ../../core/tdc_controller.vhd tb_controller.vhd
ghdl -m tb_controller
ghdl -r tb_controller
