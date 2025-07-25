all: vulpforth

vulpforth.o: words.asm vars.asm

vulpforth.zip: vulpforthzip files.zip
	cat $^ > $@
	zip -A $@
	chmod +x $@

files.zip: doc lib *.vf
	zip -r $@ $^

vulpforthzip: vulpforthzip.o zipfd.o zip/src/zip.o
	${CC} -m32 -static ${CFLAGS} -o $@ $^ ${LDFLAGS}

vulpforthzip.o: vulpforth.asm words.asm vars.asm
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
	rm -f *.o vulpforth vulpforthzip vulpforth.zip files.zip zip/src/zip.o
