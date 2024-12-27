; vulp forth, vulpine's weird opinionated forth thing
;
; word format:        V
; name flags previous code
;      db    dd
; 
; flags:
; immediate nointerpret TBD namelen*5
;
; registers:
; eax - overwritable
; ebx - value of top of working stack
; esp - address to after top of working stack
; ebp - address top of return stack
; edi - overwritable (stos target)
; esi - current word contents (lods source)
; ecx - overwritable
; edx - overwritable

%include "elf.asm"

%macro DEFWORD 4
	db %2			; name
	db %3<<5|%strlen(%2)	; flags & length
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
	add ebp, -4	; decrement top of return stack
	mov %1, [ebp]	; take value from top of return stack
%endmacro

%macro PUSHRET 1
	mov [ebp], %1	; take value from top of return stack
	add ebp, 4	; increment top of return stack
%endmacro

section .text
global _start

%include "vars.asm"
%include "words.asm"

_start:
	mov [stackstart], esp	; keep initial stack position
restart	mov ebp, retstack	; initialize return stack
	mov [wordfd], dword 0	; read words from stdin
	cld			; set direction to forwards
	call enter
	dd init

section .bss
wordlen resb 1		; length of last read word
wordbuf resb 256	; last read word
retstack resd 1024	; the return stack

filesize equ $ - $$
