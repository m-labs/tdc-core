# Mico32 toolchain
#
AS=lm32-rtems4.11-as
CC=lm32-rtems4.11-gcc
LD=lm32-rtems4.11-ld
OBJCOPY=lm32-rtems4.11-objcopy
AR=lm32-rtems4.11-ar
RANLIB=lm32-rtems4.11-ranlib


# Toolchain options
#
INCLUDES=-I$(MMDIR)/software/include -I$(MMDIR)/tools
ASFLAGS=$(INCLUDES)
CFLAGS=-O9 -Wall -fomit-frame-pointer -fno-builtin -fsigned-char -fsingle-precision-constant $(INCLUDES)
LDFLAGS=-nostdlib -nodefaultlibs
