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
	mov %1, [ebp]	; take value from top of return stack
	add ebp, -4	; decrement top of return stack
%endmacro

%macro PUSHRET 1
	mov [ebp], %1	; take value from top of return stack
	add ebp, 4	; increment top of return stack
%endmacro

DEFWORD enter, 0b010, 0
	PUSHRET esi	; save previous word in return stack
	pop esi		; grab new word pointer from call
	NEXT

DEFWORD exit, 0b000, enter
	POPRET esi	; switch to words at top of return stack
	NEXT

DEFWORD lit, 0b010, exit
	push ebx	; make room in working stack
	lodsw		; grab next colon-word token
	xchg ebx, eax	; put it on the stack
	NEXT

DEFWORD wpop, 'pop', 0b000, lit
	pop ebx
	NEXT

DEFWORD dup, 0b000, wpop
	push ebx
	NEXT

DEFWORD nth, 0b000, dup
	mov ebx, [esp+ebx]
	NEXT

DEFWORD syscall, 0b000, nth
	xchg eax, ebx	; get syscall number from top of stack
	pop ebx		; syscall args
	pop ecx
	pop edx
	int 0x80	; syscall
	xchg ebx, eax	; put return value at our top of stack
	NEXT

DEFWORD plus, '+', 0b000, syscall
	pop eax
	add ebx, eax
	NEXT

here	dd 0	; address of next unused memory
latest	dd plus	; address of newest defined word

_start:
	cld	; set direction to forwards

filesize equ $ - $$
