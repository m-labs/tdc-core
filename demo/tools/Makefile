TARGETS=bin2hex crc32 flterm

all: $(TARGETS)

%: %.c
	gcc -O2 -Wall -I. -s -o $@ $<

.PHONY: clean

clean:
	rm -f $(TARGETS) *.o
