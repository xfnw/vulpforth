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
