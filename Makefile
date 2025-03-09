all: vulpforth

vulpforth.o: words.asm vars.asm

vulpforthtrace.o: vulpforth.asm words.asm vars.asm
	nasm -f elf -F dwarf -g -dTRACE -o $@ $<

vulpforth.zip: vulpforthzip files.zip
	cat $^ > $@
	zip -A $@
	chmod +x $@

files.zip: doc *.vf
	zip -r $@ $^

vulpforthzip: vulpforthzip.o zipfd.o zip/src/zip.o
	${CC} -m32 -static ${CFLAGS} -o $@ $^ ${LDFLAGS}

vulpforthzip.o: vulpforth.asm words.asm vars.asm
	nasm -f elf -F dwarf -g -dZIPAPP -o $@ $<

zipfd.o: zip/src/zip.h

zip/src/zip.o: zip/src/zip.h zip/src/miniz.h

%.o: %.c
	${CC} -m32 -c ${CFLAGS} -o $@ $<

%.o: %.asm
	nasm -f elf -F dwarf -g $<

%: %.o
	${LD} -m elf_i386 -o $@ $<

clean:
	rm -f *.o *.zip vulpforth vulpforthtrace vulpforthzip zip/src/zip.o
