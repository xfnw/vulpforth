all: vulpforth.bin

vulpforth.bin: elf.asm words.asm vars.asm

vulpforth.o: elf.asm words.asm vars.asm

vulpforth.zip: vulpforthzip files.zip
	cat $^ > $@
	zip -A $@
	chmod +x $@

files.zip: *.vf
	zip $@ $^

vulpforthzip: vulpforthzip.o zipfd.o zip/src/zip.o
	${CC} -m32 -static ${CFLAGS} -o $@ $^ ${LDFLAGS}

vulpforthzip.o: vulpforth.asm elf.asm words.asm vars.asm
	nasm -f elf -F dwarf -g -dZIPAPP -o $@ $<

zipfd.o: zip/src/zip.h

zip/src/zip.o: zip/src/zip.h zip/src/miniz.h

%.o: %.c
	${CC} -m32 -c ${CFLAGS} -o $@ $<

%.bin: %.asm
	nasm -f bin -o $@ $<
	chmod +x $@

%.o: %.asm
	nasm -f elf -F dwarf -g $<

%: %.o
	${LD} -m elf_i386 -o $@ $<

clean:
	rm -f *.bin *.o *.zip vulpforth vulpforthzip zip/src/zip.o
