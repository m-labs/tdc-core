timing: build/system-routed.twr

load: build/system.bit
	cd build && impact -batch ../load.cmd

build/system.ncd: build/system.ngd
	cd build && map -ol high -w system.ngd

build/system-routed.ncd: build/system.ncd
	cd build && par -ol high -w system.ncd system-routed.ncd

build/system.bit: build/system-routed.ncd
	cd build && bitgen -w system-routed.ncd system.bit

build/system-routed.twr: build/system-routed.ncd
	cd build && trce -v 10 system-routed.ncd system.pcf

clean:
	rm -rf build/*

.PHONY: timing usage load clean
