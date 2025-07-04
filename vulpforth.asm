%macro DEFWORD 4
	db %2			; name
	db %3<<6|%strlen(%2)	; flags & length
	dd %4			; previous word
%1:
%endmacro

%macro DEFWORD 3
DEFWORD %1, %str(%1), %2, %3
%endmacro

%macro NEXT 0
	lodsd	; increment esi
	jmp eax	; jump to old esi value
%endmacro

%macro POPRET 1
	mov %1, [ebp]	; take value from top of return stack
	add ebp, 4	; increment top of return stack
%endmacro

%macro PUSHRET 1
	add ebp, -4	; decrement top of return stack
	mov [ebp], %1	; take value from top of return stack
%endmacro

section .data
%ifdef ZIPAPP
initfn	db 'init.vf', 0
%endif

%include "vars.asm"

section .text
starttext:
%ifdef ZIPAPP
	global main
	extern zipfd_init
	extern zipfd_open
%else
	global _start
%endif

%include "words.asm"

%ifdef ZIPAPP
main:
	call zipfd_init
	; linking a c object makes the bss section stop being
	; executable, set it executable ourself with mprotect
	; FIXME: figure out how to not need this
	xor eax, eax
	mov al, 125			; mprotect
	mov ebx, astart			; start of bss
	mov ecx, retstack+retsz-astart	; length of bss
	xor edx, edx
	mov dl, 7	; PROT_READ|PROT_WRITE|PROT_EXEC
	int 0x80
%else
_start:
%endif
	xor ecx, ecx
aloop	dec cl
	mov [astart+ecx], byte '>'
	jnz aloop
	mov [angles], byte ' '
	mov [stackstart], esp	; keep initial stack position
%ifdef ZIPAPP
	mov ebp, retstack+retsz	; initialize return stack
	cld			; set direction to forwards
	call enter
	dd lit, initfn
	dd lit, 7
	dd loadfrom
	dd init
%endif
restart	mov ebp, retstack+retsz	; initialize return stack
	mov [wordfd], dword 0	; read words from stdin
	cld			; set direction to forwards
	jmp init

endtext:

section .bss
astart	resb 255
angles	resb 1
wordlen resb 1		; length of last read word
wordbuf resb 256	; last read word

defhere alignb 4096
resb 65536

retstack resd 1024	; the return stack
retsz equ $ - retstack

resvsize equ $ - $$
