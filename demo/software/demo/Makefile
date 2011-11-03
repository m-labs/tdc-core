MMDIR=../..
include $(MMDIR)/software/include.mak

OBJECTS=crt0.o main.o tdc.o udelay.o temperature.o dac.o
SEGMENTS=-j .text -j .data -j .rodata

all: demo.bin demo.h0 demo.h1 demo.h2 demo.h3

demo.h0: demo.bin
	$(MMDIR)/tools/bin2hex $< $@ 8192 4

demo.h1: demo.bin
	$(MMDIR)/tools/bin2hex $< $@ 8192 3

demo.h2: demo.bin
	$(MMDIR)/tools/bin2hex $< $@ 8192 2

demo.h3: demo.bin
	$(MMDIR)/tools/bin2hex $< $@ 8192 1

%.bin: %.elf
	$(OBJCOPY) $(SEGMENTS) -O binary $< $@
	chmod -x $@
	$(MMDIR)/tools/crc32 $@ write

demo.elf: linker.ld $(OBJECTS)
	$(LD) $(LDFLAGS) -T linker.ld -N -o $@ $(OBJECTS) -L$(MMDIR)/software/libbase -lbase
	chmod -x $@

.PHONY: clean depend

depend:
	makedepend -Y -- $(CFLAGS) -- *.c

clean:
	rm -f *.o demo.elf demo.bin demo.h0 demo.h1 demo.h2 demo.h3 .*~ *~ Makefile.bak

# DO NOT DELETE

main.o: ../../software/include/stdio.h ../../software/include/stdlib.h
main.o: ../../software/include/console.h ../../software/include/string.h
main.o: ../../software/include/uart.h ../../software/include/crc.h
main.o: ../../software/include/system.h ../../software/include/hw/sysctl.h
main.o: ../../software/include/hw/common.h ../../software/include/hw/gpio.h
main.o: ../../software/include/hw/uart.h
