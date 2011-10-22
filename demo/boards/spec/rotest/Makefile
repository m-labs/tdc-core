TDC_DIR=../../../..

SRC=rotest.vhd $(TDC_DIR)/core/tdc_package.vhd $(TDC_DIR)/core/tdc_ringosc.vhd

all: build/rotest.bit


build/rotest.prj: $(SRC)
	rm -f build/rotest.prj
	for i in `echo $(SRC)`; do \
		echo "vhdl work ../$$i" >> build/rotest.prj; \
	done

build/rotest.ngc: build/rotest.prj
	cd build && xst -ifn ../rotest.xst

build/rotest.ngd: build/rotest.ngc rotest.ucf
	cd build && ngdbuild -uc ../rotest.ucf rotest.ngc

build/rotest.ncd: build/rotest.ngd
	cd build && map -ol high -w rotest.ngd

build/rotest-routed.ncd: build/rotest.ncd
	cd build && par -ol high -w rotest.ncd rotest-routed.ncd

build/rotest.bit: build/rotest-routed.ncd
	cd build && bitgen -w rotest-routed.ncd rotest.bit

build/rotest-routed.twr: build/rotest-routed.ncd
	cd build && trce -v 10 rotest-routed.ncd rotest.pcf

clean:
	rm -rf build/*

.PHONY: timing clean
