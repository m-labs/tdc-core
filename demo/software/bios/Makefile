MMDIR=../..
include $(MMDIR)/software/include.mak

OBJECTS=crt0.o main.o boot.o
SEGMENTS=-j .text -j .data -j .rodata

all: bios.bin bios.h0 bios.h1 bios.h2 bios.h3

bios.h0: bios.bin
	$(MMDIR)/tools/bin2hex $< $@ 4096 4

bios.h1: bios.bin
	$(MMDIR)/tools/bin2hex $< $@ 4096 3

bios.h2: bios.bin
	$(MMDIR)/tools/bin2hex $< $@ 4096 2

bios.h3: bios.bin
	$(MMDIR)/tools/bin2hex $< $@ 4096 1

%.bin: %.elf
	$(OBJCOPY) $(SEGMENTS) -O binary $< $@
	chmod -x $@
	$(MMDIR)/tools/crc32 $@ write

bios.elf: linker.ld $(OBJECTS)
	$(LD) $(LDFLAGS) -T linker.ld -N -o $@ $(OBJECTS) -L$(MMDIR)/software/libbase -lbase
	chmod -x $@

.PHONY: clean depend

depend:
	makedepend -Y -- $(CFLAGS) -- *.c

clean:
	rm -f *.o bios.elf bios.bin bios.h0 bios.h1 bios.h2 bios.h3 .*~ *~ Makefile.bak

# DO NOT DELETE

boot.o: ../../software/include/stdio.h ../../software/include/stdlib.h
boot.o: ../../software/include/console.h ../../software/include/uart.h
boot.o: ../../software/include/system.h ../../software/include/board.h
boot.o: ../../software/include/crc.h ../../tools/sfl.h boot.h
main.o: ../../software/include/stdio.h ../../software/include/stdlib.h
main.o: ../../software/include/console.h ../../software/include/string.h
main.o: ../../software/include/uart.h ../../software/include/crc.h
main.o: ../../software/include/system.h ../../software/include/board.h
main.o: ../../software/include/version.h ../../software/include/hw/sysctl.h
main.o: ../../software/include/hw/common.h ../../software/include/hw/gpio.h
main.o: ../../software/include/hw/uart.h boot.h
