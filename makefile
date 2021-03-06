PROJ=test
ASRC=filter.asm
CSRC=intel.c

AS=nasm
CC=gcc
LD=gcc
ASFLAGS=-felf -g -l filter.lst
CFLAGS+=-Wall -m32 -g
LDFLAGS=-m32 -g

AOBJ=$(ASRC:.asm=.o)
COBJ=$(CSRC:.c=.o)

default: $(PROJ)

$(PROJ): $(AOBJ) $(COBJ)
	$(LD) $(LDFLAGS) $(AOBJ) $(COBJ) -o	$@

%.o: %.asm
	$(AS) $(ASFLAGS) -o $@	$<

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@	$<

clean:
	rm -f $(AOBJ) $(COBJ) $(PROJ)

