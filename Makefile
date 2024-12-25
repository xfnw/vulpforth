all: vulpforth.bin

vulpforth.bin: elf.asm words.asm

%.bin: %.asm
	nasm -f bin -o $@ $<
	chmod +x $@

%.o: %.asm
	nasm -f elf $<

%: %.o
	ld -m elf_i386 -s -o $@ $<
