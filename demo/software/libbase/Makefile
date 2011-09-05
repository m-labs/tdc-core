MMDIR=../..
include $(MMDIR)/software/include.mak

OBJECTS=_ashlsi3.o _divsi3.o _modsi3.o _udivmodsi4.o _umodsi3.o _ashrsi3.o _lshrsi3.o _mulsi3.o _udivsi3.o
OBJECTS+=libc.o crc16.o crc32.o console.o system.o board.o irq.o vsnprintf-nofloat.o uart.o

all: libbase.a

libbase.a: $(OBJECTS)
	$(AR) clr libbase.a $(OBJECTS)
	$(RANLIB) libbase.a

.PHONY: clean depend

depend:
	makedepend -Y -- $(CFLAGS) -- *.c

clean:
	rm -f *.o libbase.a .*~ *~ Makefile.bak

# DO NOT DELETE

board.o: ../../software/include/hw/sysctl.h
board.o: ../../software/include/hw/common.h ../../software/include/stdlib.h
board.o: ../../software/include/board.h
console.o: ../../software/include/uart.h ../../software/include/console.h
console.o: ../../software/include/stdio.h ../../software/include/stdlib.h
console.o: ../../software/include/stdarg.h
crc16.o: ../../software/include/crc.h
crc32.o: ../../software/include/crc.h
_divsi3.o: libgcc_lm32.h
libc.o: ../../software/include/ctype.h ../../software/include/stdio.h
libc.o: ../../software/include/stdlib.h ../../software/include/stdarg.h
libc.o: ../../software/include/string.h ../../software/include/limits.h
_modsi3.o: libgcc_lm32.h
_mulsi3.o: libgcc_lm32.h
system.o: ../../software/include/irq.h ../../software/include/uart.h
system.o: ../../software/include/hw/sysctl.h
system.o: ../../software/include/hw/common.h ../../software/include/system.h
uart-async.o: ../../software/include/uart.h ../../software/include/irq.h
uart-async.o: ../../software/include/hw/uart.h
uart-async.o: ../../software/include/hw/common.h
uart-async.o: ../../software/include/hw/interrupts.h
uart.o: ../../software/include/uart.h ../../software/include/irq.h
uart.o: ../../software/include/hw/uart.h ../../software/include/hw/common.h
uart.o: ../../software/include/hw/interrupts.h
_udivmodsi4.o: libgcc_lm32.h
_udivsi3.o: libgcc_lm32.h
_umodsi3.o: libgcc_lm32.h
vsnprintf-nofloat.o: ../../software/include/stdlib.h
vsnprintf-nofloat.o: ../../software/include/stdio.h
vsnprintf-nofloat.o: ../../software/include/stdarg.h
vsnprintf-nofloat.o: ../../software/include/string.h
vsnprintf-nofloat.o: ../../software/include/ctype.h
