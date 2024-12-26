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

DEFWORD jump, 0b000, gotz
	xchg eax, ebx
	pop ebx
	jmp eax

; ( a b c -- b c a )
DEFWORD rot, 0b000, jump
	pop eax
	pop edx
	push eax
	push ebx
	xchg ebx, edx
	NEXT

; ( a b c -- c a b )
DEFWORD rot2, 'rot>', 0b000, rot
	pop eax
	pop edx
	push ebx
	push edx
	xchg ebx, eax
	NEXT

; ( a b -- a b a )
DEFWORD over, 0b000, rot2
	pop eax
	push eax
	push ebx
	xchg ebx, eax
	NEXT

; ( a b c -- a b c a )
DEFWORD dover, '2over', 0b000, over
	pop eax
	pop ecx
	push eax
	push ecx
	push ebx
	xchg ebx, ecx
	NEXT

; ( a -- )
DEFWORD drop, 'drop', 0b000, dover
	pop ebx
	NEXT

; ( a -- a a )
DEFWORD dup, 0b000, drop
	push ebx
	NEXT

; ( a -- a a? )
DEFWORD cdup, '?dup', 0b000, dup
	cmp ebx, 0
	jz nodup
	push ebx
nodup	NEXT

; ( a b -- a b a b )
DEFWORD ddup, '2dup', 0b000, cdup
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

; ( a b == a<<b )
DEFWORD lshift, 0b000, syscall
	pop ecx
	xchg ebx, ecx
	shl ebx, cl
	NEXT

; ( a b == a>>b )
DEFWORD rshift, 0b000, lshift
	pop ecx
	xchg ebx, ecx
	shr ebx, cl
	NEXT

; ( a b -- a&b )
DEFWORD band, 'and', 0b000, rshift
	pop eax
	and ebx, eax
	NEXT

; ( a b -- a|b )
DEFWORD bor, 'or', 0b000, band
	pop eax
	or ebx, eax
	NEXT

; ( a b -- a+b )
DEFWORD plus, '+', 0b000, bor
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
regetw	mov ebx, [wordfd]
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
	cmp ecx, ebx		; is /only/ whitespace?
	je regetw		; yes, try again
	push ebx
	sub ecx, ebx
	xchg ebx, ecx
	mov [wordlen], bl
goodrd	NEXT
badrd	xor ebx, ebx
	push ebx
	jmp goodrd

; ( c -- )
DEFWORD emit, 0b000, getword
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

; ( str len -- )
DEFWORD emits, 0b000, emit
	call enter
	dd swap
	dd lit, 1
	dd lit, 4
	dd syscall
	dd drop
	dd exit

DEFWORD cat, 'c@', 0b000, emits
	mov bl, [ebx]
	and ebx, 0xff
	NEXT

DEFWORD cput, 'c!', 0b000, cat
	pop eax
	mov [ebx], al
	pop ebx
	NEXT

DEFWORD dat, '@', 0b000, cput
	mov ebx, [ebx]
	NEXT

DEFWORD dput, '!', 0b000, dat
	pop eax
	mov [ebx], eax
	pop ebx
	NEXT

; ( c -- )
DEFWORD printhexc, '.xc', 0b000, dput
	call enter
	dd lit, 0xf
	dd band
	dd lit, hexchr
	dd plus
	dd cat
	dd emit
	dd exit
	
; ( c -- )
DEFWORD printhex1, '.x1', 0b000, printhexc
	call enter
	dd dup
	dd lit, 4
	dd rshift
	dd printhexc
	dd printhexc
	dd exit

; ( c -- )
DEFWORD printhex2, '.x2', 0b000, printhex1
	call enter
	dd dup
	dd lit, 8
	dd rshift
	dd printhex1
	dd printhex1
	dd exit

; ( c -- )
DEFWORD printhex, '.x', 0b000, printhex2
	call enter
	dd dup
	dd lit, 16
	dd rshift
	dd printhex2
	dd printhex2
	dd exit

; ( a b -- a==b )
DEFWORD eq, '=', 0b000, printhex
	pop eax
	xchg edx, ebx
	xor ebx, ebx
	cmp eax, edx
	jne eqneq
	inc ebx
eqneq	NEXT

; ( m1 m2 len -- m1==m2 )
DEFWORD memeq, 'mem=', 0b000, eq
	xchg ecx, ebx
	xor ebx, ebx
	inc ebx
	pop eax
	pop edx
lmemeq	mov edi, [eax+ecx]
	cmp edi, [edx+ecx]
	jne nmemeq
	loop lmemeq
	xor ebx, ebx
nmemeq	NEXT

; ( str1 len1 str2 len2 -- str1==str2 )
DEFWORD streq, 'str=', 0b000, memeq
	call enter
	dd rot
	dd over
	dd eq
	dd gotz, nstreq - $
	dd memeq
	dd exit
nstreq	dd drop
	dd drop
	dd drop
	dd lit, 0
	dd exit

DEFWORD find, 0b000, streq
	NEXT

DEFWORD wordaddr, `'`, 0b000, find
	call enter
	dd getword
	dd find
	dd exit

DEFWORD bye, 0b000, wordaddr
	call enter
	dd lit, 0 ; success
	dd lit, 1 ; nr_exit
	dd syscall

DEFWORD init, 0b000, bye
	call enter
	dd bye
