; ELF header borrowed from muppet labs ~breadbox
; https://www.muppetlabs.com/~breadbox/software/tiny/teensy.html
;
; $Fur: elf.asm 2024-02-29T18:33:57Z xfnw $

BITS 32
	org 0x08048000

ehdr:					; Elf32_Ehdr
	db 0x7F, "ELF", 1, 1, 1, 0	; e_ident
times 8	db 0
	dw 2				; e_type
	dw 3				; e_machine
	dd 1				; e_version
	dd _start			; e_entry
	dd phdr - $$			; e_phoff
	dd 0				; e_shoff
	dd 0				; e_flags
	dw ehdrsize			; e_ehsize
	dw phdrsize			; e_phentsize
phdr:			; Elf32_Phdr
	dw 1		; p_type	; e_phnum
	dw 0				; e_shentsize
	dw 0		; p_offset	; e_shnum
	dw 0				; e_shstrndx

ehdrsize equ $ - ehdr

	dd $$		; p_vaddr
	dd $$		; p_paddr
	dd filesize	; p_filesz
	dd resvsize	; p_memsz
	dd 7		; p_flags
	dd 0x1000	; p_align

phdrsize equ $ - phdr

; put this at the end of your program:
;filesize equ $ - $$
;resvsize equ $ - $$

