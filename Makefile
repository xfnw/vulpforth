all: vulpforth.bin

%.bin: %.asm
	nasm -f bin -o $@ $<
	chmod +x $@

%.o: %.asm
	nasm -f elf $<

%: %.o
	ld -m elf_i386 -s -o $@ $<
