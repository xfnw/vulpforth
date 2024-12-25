; vulp forth, vulpine's weird opinionated forth thing
;
; word format:        V
; name flags previous code
;      db    dd
; 
; registers:
; eax - overwritable
; ebx - overwritable
; esp - top of working stack
; ebp - top of return stack
; edi - overwritable (stos target)
; esi - current word contents (lods source)
; ecx - overwritable
; edx - overwritable

%include "elf.asm"

here	dd 0	; pointer to next unused memory

_start:

filesize equ $ - $$
