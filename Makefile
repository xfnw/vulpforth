all: vulpforth.bin

vulpforth.bin: elf.asm words.asm vars.asm

vulpforth: elf.asm words.asm vars.asm

%.bin: %.asm
	nasm -f bin -o $@ $<
	chmod +x $@

%.o: %.asm
	nasm -f elf -F dwarf -g $<

%: %.o
	ld -m elf_i386 -o $@ $<
