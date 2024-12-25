DEFWORD enter, 0b010, 0
	PUSHRET esi	; save previous word in return stack
	pop esi		; grab new word pointer from call
	NEXT

DEFWORD exit, 0b000, enter
	POPRET esi	; switch to words at top of return stack
	NEXT

DEFWORD lit, 0b010, exit
	push ebx	; make room in working stack
	lodsd		; grab next colon-word token
	xchg ebx, eax	; put it on the stack
	NEXT

DEFWORD drop, 'drop', 0b000, lit
	pop ebx
	NEXT

DEFWORD dup, 0b000, drop
	push ebx
	NEXT

DEFWORD ddup, '2dup', 0b000, dup
	pop eax
	push eax	; pop+push is smaller than a mov
	push ebx
	push eax
	NEXT

DEFWORD swap, 0b000, ddup
	pop eax
	xchg ebx, eax
	push eax
	NEXT

DEFWORD nth, 0b000, swap
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

DEFWORD minusinv, '-^', 0b000, plus
	pop eax
	sub ebx, eax
	NEXT

DEFWORD minus, '-', 0b000, minusinv
	pop eax
	xchg ebx, eax
	sub ebx, eax
	NEXT

DEFWORD mulsigned, '*', 0b000, minus
	pop eax
	imul ebx, eax
	NEXT

DEFWORD divmodsigned, '/mod', 0b000, mulsigned
	pop eax
	cdq
	idiv ebx
	push eax
	xchg ebx, edx
	NEXT

DEFWORD bye, 0b000, divmodsigned
	call enter
	dd lit, 0 ; success
	dd lit, 1 ; nr_exit
	dd syscall

DEFWORD init, 0b000, bye
	call enter
	dd bye
