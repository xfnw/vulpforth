all: vulpforth.bin

vulpforth.bin: elf.asm words.asm vars.asm

vulpforth.o: elf.asm words.asm vars.asm

%.bin: %.asm
	nasm -f bin -o $@ $<
	chmod +x $@

%.o: %.asm
	nasm -f elf -F dwarf -g $<

%: %.o
	ld -m elf_i386 -o $@ $<

clean:
	rm -f vulpforth.bin vulpforth.o vulpforth
