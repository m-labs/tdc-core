#!/bin/sh
set -e
ghdl -i ../../core/tdc_package.vhd ../../core/tdc_psync.vhd ../../core/tdc_freqc.vhd tb_freqc.vhd
ghdl -m tb_freqc
ghdl -r tb_freqc
