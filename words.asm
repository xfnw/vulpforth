DEFWORD enter, 0b010, 0
	PUSHRET esi	; save previous word in return stack
	pop esi		; grab new word pointer from call
	NEXT

DEFWORD exit, 0b000, enter
	add ebp, -4	; switch to words at top of return stack
	mov esi, [ebp]
	NEXT

DEFWORD lit, 0b010, exit
	push ebx	; make room in working stack
	lodsd		; grab next colon-word token
	xchg ebx, eax	; put it on the stack
	NEXT

DEFWORD goto, 0b010, lit
	lodsd		; grab next colon-word token
	add esi, eax	; offset it
	NEXT

DEFWORD gotz, 0b010, goto
	cmp ebx, 0	; check if top of stack is 0
	pop ebx		; consume it
	lodsd		; grab next colon-word token
	jnz notgon	; skip if not zero
	add esi, eax	; offset it
notgon	NEXT

; ( a b c -- b c a )
DEFWORD rot, 0b000, gotz
	pop eax
	pop edx
	push eax
	push ebx
	xchg ebx, edx
	NEXT

; ( a -- )
DEFWORD drop, 'drop', 0b000, rot
	pop ebx
	NEXT

; ( a -- a a )
DEFWORD dup, 0b000, drop
	push ebx
	NEXT

; ( a b -- a b a b )
DEFWORD ddup, '2dup', 0b000, dup
	pop eax
	push eax	; pop+push is smaller than a mov
	push ebx
	push eax
	NEXT

; ( a b -- b a )
DEFWORD swap, 0b000, ddup
	pop eax
	xchg ebx, eax
	push eax
	NEXT

; ( a -- stack[a] )
DEFWORD nth, 0b000, swap
	mov ebx, [esp+ebx]
	NEXT

; ( arg3 arg2 arg1 num -- res )
; note that the 4 stack items will still be consumed even
; if the syscall takes less than 3 args.
; conversely, if the syscall takes more than 3 args, linux
; itself will grab a variable number of extra stack items.
DEFWORD syscall, 0b000, nth
	xchg eax, ebx	; get syscall number from top of stack
	pop ebx		; syscall args
	pop ecx
	pop edx
	int 0x80	; syscall
	xchg ebx, eax	; put return value at our top of stack
	NEXT

; ( a b -- a+b )
DEFWORD plus, '+', 0b000, syscall
	pop eax
	add ebx, eax
	NEXT

; ( a b -- b-a )
DEFWORD minusinv, '-^', 0b000, plus
	pop eax
	sub ebx, eax
	NEXT

; ( a b -- a-b )
DEFWORD minus, '-', 0b000, minusinv
	pop eax
	xchg ebx, eax
	sub ebx, eax
	NEXT

; ( a b -- a*b )
DEFWORD mulsigned, '*', 0b000, minus
	pop eax
	imul ebx, eax
	NEXT

; ( a b -- a/b a%b )
DEFWORD divmodsigned, '/mod', 0b000, mulsigned
	pop eax
	cdq
	idiv ebx
	push eax
	xchg ebx, edx
	NEXT

; ( -- waddr wsize )
DEFWORD getword, 'word', 0b000, divmodsigned
	push ebx
	mov ebx, [wordfd]
	mov ecx, wordbuf-1
readchr	xor edx, edx
	inc edx
	xor eax, eax
	mov al, 3		; read
	inc ecx			; the next byte
	int 0x80		; syscall
	cmp eax, 1		; did it error?
	jne badrd		; yes, give failed
	mov eax, [ecx]		; no, lets check it
	imul eax, 0xf641ae81
	and eax, 0xa00ac010
	cmp eax, 0x8000c000	; is whitespace?
	jne readchr		; no, loop some more
	mov ebx, wordbuf
	push ebx
	sub ecx, ebx
	xchg ebx, ecx
goodrd	NEXT
badrd	xor ebx, ebx
	push ebx
	jmp goodrd

; ( c -- )
DEFWORD putchar, 0b000, getword
	push ebx
	xor eax, eax
	mov al, 4
	xor ebx, ebx
	inc ebx
	mov ecx, esp
	mov edx, ebx
	int 0x80
	pop ebx
	pop ebx
	NEXT

DEFWORD bye, 0b000, putchar
	call enter
	dd lit, 0 ; success
	dd lit, 1 ; nr_exit
	dd syscall

DEFWORD init, 0b000, bye
	call enter
	dd bye
