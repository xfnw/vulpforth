DEFWORD enter, 0b010, latest
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

DEFWORD litd, 0b010, lit
	push ebx
	lodsd
	mov ebx, [eax]	; same thing but dereferenced
	NEXT

DEFWORD goto, 0b010, litd
	lodsd		; grab next colon-word token
	xchg esi, eax	; jump to it
	NEXT

DEFWORD gotz, 0b010, goto
	cmp ebx, 0	; check if top of stack is 0
	pop ebx		; consume it
	lodsd		; grab next colon-word token
	jnz notgon	; skip if not zero
	xchg esi, eax	; jump to it
notgon	NEXT

DEFWORD gonz, 0b010, gotz
	cmp ebx, 0	; check if top of stack is 0
	pop ebx		; consume it
	lodsd		; grab next colon-word token
	jz yesgon	; skip if zero
	xchg esi, eax	; jump to it
yesgon	NEXT

; ( a -- )
DEFWORD jump, 0b000, gonz
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
DEFWORD drop, 0b000, dover
	pop ebx
	NEXT

; ( a a -- )
DEFWORD ddrop, '2drop', 0b000, drop
	pop ebx
	pop ebx
	NEXT

; ( a b -- b )
DEFWORD nip, 0b000, ddrop
	pop eax
	NEXT

; ( a b -- b a b )
DEFWORD tuck, 0b000, nip
	pop eax
	push ebx
	push eax
	NEXT

; ( a -- a a )
DEFWORD dup, 0b000, tuck
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

; ( a b c d -- c d a b )
DEFWORD dswap, '2swap', 0b000, swap
	pop eax
	pop ecx
	pop edx
	push eax
	push ebx
	push edx
	xchg ebx, ecx
	NEXT

; ( a -- stack[a] )
DEFWORD nth, 0b000, dswap
	mov ebx, [esp+ebx*4]
	NEXT

; ( arg3 arg2 arg1 num -- res )
; note that the 4 stack items will still be consumed even
; if the syscall takes less than 3 args.
DEFWORD syscall, 0b000, nth
	xchg eax, ebx	; get syscall number from top of stack
	pop ebx		; syscall args
	pop ecx
	pop edx
	int 0x80	; syscall
	xchg ebx, eax	; put return value at our top of stack
	NEXT

; ( arg6 arg5 arg4 arg3 arg2 arg1 num -- res )
DEFWORD syscall6, 0b000, syscall
	xchg eax, ebx	; get syscall number from top of stack
	pop ebx		; syscall args
	pop ecx
	pop edx
	xchg esi, [esp]
	xchg edi, [esp+4]
	xchg ebp, [esp+8]
	int 0x80	; syscall
	xchg ebx, eax	; put return value at our top of stack
	pop esi
	pop edi
	pop ebp
	NEXT

; ( a b -- a<<b )
DEFWORD lshift, 0b000, syscall6
	pop ecx
	xchg ebx, ecx
	shl ebx, cl
	NEXT

; ( a b -- a>>b )
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

; ( a b -- a^b )
DEFWORD bxor, 'xor', 0b000, bor
	pop eax
	xor ebx, eax
	NEXT

; ( a -- !a )
DEFWORD bnot, 'not', 0b000, bxor
	not ebx
	NEXT

; ( a b -- a+b )
DEFWORD plus, '+', 0b000, bnot
	pop eax
	add ebx, eax
	NEXT

; ( a b -- b-a )
DEFWORD minusinv, '-^', 0b000, plus
	pop eax
	sub ebx, eax
	NEXT

; ( a -- a+1 )
DEFWORD increment, '1+', 0b000, minusinv
	add ebx, 1
	NEXT

; ( a -- a-1 )
DEFWORD decrement, '1-', 0b000, increment
	sub ebx, 1
	NEXT

; ( a -- a+4 )
DEFWORD increment4, '4+', 0b000, decrement
	add ebx, 4
	NEXT

; ( a -- a-4 )
DEFWORD decrement4, '4-', 0b000, increment4
	sub ebx, 4
	NEXT

; ( a b -- a-b )
DEFWORD minus, '-', 0b000, decrement4
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

; ( a -- -a )
DEFWORD negate, '~', 0b000, divmodsigned
	neg ebx
	NEXT

; ( a -- a>>31 )
DEFWORD isneg, '?neg', 0b000, negate
	shr ebx, 31
	NEXT

; ( a -- |a| )
DEFWORD absv, 'abs', 0b000, isneg
	test ebx, 1<<31
	jz alrpos
	neg ebx
alrpos	NEXT

; ( -- waddr wsize )
DEFWORD getword, 'word', 0b000, absv
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
	mov al, [ecx]		; no, lets check it
	imul eax, 0x020268f8
	and eax, 0xa1201040
	cmp eax, 0x00001000	; is whitespace?
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

; ( -- str len )
; adds a lil null termination, as a treat (not included in length)
; so that its convenient to use with syscalls that take paths etc
; decrement here after using if you dont want this
DEFWORD string, '"', 0b000, getword
	push ebx
	mov edi, [here]
	push edi
	xor eax, eax
	mov ebx, [wordfd]
	mov ecx, edi
	xor edx, edx
	inc edx
strread	mov al, 3	; read
	int 0x80
	cmp [ecx], byte '"'
	je strbye
	inc ecx
	cmp al, 1
	je strread
strbye	mov ebx, ecx
	sub ebx, edi
	mov [ecx], byte 0
	inc ecx
	mov [here], ecx
	NEXT

; ( c -- )
DEFWORD emit, 0b000, string
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

DEFWORD spc, 0b000, emit
	call enter
	dd lit, ' '
	dd emit
	dd exit

DEFWORD nl, 0b000, spc
	call enter
	dd lit, `\n`
	dd emit
	dd exit

; ( str len -- )
DEFWORD emits, 0b000, nl
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

; ( c -- )
DEFWORD print, '.', 0b000, printhex
	call enter
	dd lit, -1
	dd swap
	dd dup
	dd isneg
	dd gotz, pnotn
	dd lit, '-'
	dd emit
pnotn	dd lit, 10
	dd divmodsigned
	dd absv
	dd lit, 0x30
	dd plus
	dd swap
	dd cdup
	dd gonz, pnotn
pprint	dd emit
	dd dup
	dd lit, -1
	dd eq
	dd gotz, pprint
	dd drop
	dd exit

; ( a b -- a==b )
DEFWORD eq, '=', 0b000, print
	pop eax
	xchg edx, ebx
	xor ebx, ebx
	cmp eax, edx
	jne eqneq
eqieq	inc ebx
eqneq	NEXT

; ( a b -- a>b )
DEFWORD gt, '>', 0b000, eq
	pop eax
	xchg edx, ebx
	xor ebx, ebx
	cmp eax, edx
	jg eqieq
	NEXT

; ( m1 m2 len -- m1==m2 )
DEFWORD memeq, 'mem=', 0b000, gt
	xchg ecx, ebx
	xor ebx, ebx
	pop eax
	pop edi
lmemeq	mov dl, [eax+ecx-1]
	cmp dl, [edi+ecx-1]
	jne nmemeq
	loop lmemeq
	inc ebx
nmemeq	NEXT

; ( m1 len m2 -- )
DEFWORD memcpy, 0b000, memeq
	pop ecx
	pop eax
memcl	mov dl, [eax+ecx-1]
	mov [ebx+ecx-1], dl
	loop memcl
	pop ebx
	NEXT

; ( str len -- )
DEFWORD strcom, 'str,', 0b000, memcpy
	call enter
	dd dup
	dd rot2
	dd litd, here
	dd memcpy
	dd alloc
	dd exit

; ( str1 len1 str2 len2 -- str1==str2 )
DEFWORD streq, 'str=', 0b000, strcom
	call enter
	dd rot
	dd over
	dd eq
	dd gotz, nstreq
	dd memeq
	dd exit
nstreq	dd ddrop
	dd drop
	dd lit, 0
	dd exit

; ( addr -- len )
DEFWORD dictlen, 0b000, streq
	call enter
	dd lit, 5
	dd minus
	dd cat
	dd lit, 0b00011111
	dd band
	dd exit

; ( addr -- str len )
DEFWORD dictname, 0b000, dictlen
	call enter
	dd dup
	dd dictlen
	dd dup
	dd rot
	dd minusinv
	dd lit, 5
	dd minus
	dd swap
	dd exit

; ( addr -- addr )
DEFWORD dictprev, 0b000, dictname
	call enter
	dd decrement4
	dd dat
	dd exit

; ( addr -- flags )
DEFWORD dictflags, 0b000, dictprev
	call enter
	dd lit, 5
	dd minus
	dd cat
	dd lit, 5
	dd rshift
	dd exit

; ( -- )
DEFWORD dictcom, 'dict,', 0b000, dictflags
	call enter
	dd getword
	dd cdup
	dd gotz, colabrt
	dd dup
	dd rot2
	dd strcom
	dd lit, 0b00011111
	dd band
	dd ccom
	dd litd, latest
	dd dcom
	dd litd, here
	dd lit, latest
	dd dput
	dd exit

; ( flags -- )
DEFWORD dictor, 0b000, dictcom
	mov eax, [latest]
	shl ebx, 5
	or [eax-5], bl
	pop ebx
	NEXT

; ( -- )
DEFWORD words, 0b000, dictor
	call enter
	dd litd, latest
wdsloop	dd dup
	dd dictname
	dd emits
	dd spc
	dd dictprev
	dd cdup
	dd gonz, wdsloop
	dd nl
	dd exit

; ( str len -- addr )
DEFWORD find, 0b000, words
	call enter
	dd litd, latest
findrep	dd rot2
	dd ddup
	dd lit, 4
	dd nth
	dd dictname
	dd streq
	dd gonz, findbye
	dd rot
	dd dictprev
	dd dup
	dd gonz, findrep
	dd rot2
findbye	dd ddrop
	dd exit

; ( -- addr )
DEFWORD wordaddr, `'`, 0b000, find
	call enter
	dd getword
	dd find
	dd exit

; ( -- b )
DEFWORD wordchar, `''`, 0b000, wordaddr
	call enter
	dd getword
	dd gotz, wnowc
	dd cat
wnowc	dd exit

; ( addr len -- )
DEFWORD dump, 0b000, wordchar
	call enter
dumploo	dd cdup
	dd gotz, dbye
	dd swap
	dd dup
	dd dat
	dd printhex
	dd spc
	dd increment4
	dd swap
	dd decrement
	dd goto, dumploo
dbye	dd drop
	dd exit

; ( -- h )
DEFWORD stackheight, 0b000, dump
	mov eax, esp
	push ebx
	mov ebx, [stackstart]
	sub ebx, eax
	shr ebx, 2
	NEXT

; ( -- p )
DEFWORD stackpos, 0b000, stackheight
	mov eax, esp
	push ebx
	xchg ebx, eax
	NEXT

DEFWORD printstack, '.S', 0b000, stackpos
	call enter
	dd stackheight
	dd stackpos
	dd swap
	dd dump
	dd nl
	dd exit

DEFWORD bye, 0b000, printstack
	call enter
	dd lit, 0 ; success
	dd lit, 1 ; nr_exit
	dd syscall

abrtstr	db ' '
DEFWORD abort, 0b000, bye
	call enter
	dd lit, abrtstr
	dd lit, 6
	dd emits
	dd restart

; ( str len -- str len b )
DEFWORD startsnum, '?num', 0b000, abort
	pop edx
	push edx
	push ebx
	xor ebx, ebx
	xor eax, eax
	mov al, [edx]
	imul eax, 0xff706015
	and eax, 0xe0001ee4
	cmp eax, 0xe00002c4
	jle notanum
	inc ebx
notanum	NEXT

; ( str len -- num )
DEFWORD parsenum, 0b000, startsnum
	pop edx		; str ptr
	xchg ecx, ebx	; length
	xor ebx, ebx	; result
	xor eax, eax
	mov al, '$'
	cmp al, [edx]	; is hex?
	mov al, 10	; decimal
	jne numst
	mov al, 16	; hex
	inc edx		; skip the $
	dec ecx
numst	mov edi, eax
numloop	imul ebx, edi
	mov al, [edx]
	cmp al, 0x41	; handle hex >9
	jl numnob
	add eax, 9
numnob	and eax, 15
	add ebx, eax
	inc edx
	loop numloop
	NEXT

stunstr	db ' stack underflow'
DEFWORD chkstack, 0b000, parsenum
	cmp esp, [stackstart]
	jle cstkok
	mov esp, [stackstart]
	xor ebx,ebx
	inc ebx
	mov eax, ebx
	shl eax, 2
	mov ecx, stunstr
	mov edx, eax
	shl edx, 2
	int 0x80
	jmp abort
cstkok	NEXT

wnfstr	db ' word not found'
intstr	db ' nointerpret'
DEFWORD repl, 0b000, chkstack
	call enter
inmore	dd chkstack
	dd getword
	dd ddup
	dd dup
	dd gonz, innote
	dd ddrop
	dd ddrop
	dd exit
innote	dd find
	dd cdup
	dd gonz, incii
	dd startsnum
	dd gotz, innonn
	dd parsenum
	dd goto, inmore
innonn	dd emits
	dd lit, wnfstr
	dd lit, 15
	dd emits
	dd abort
incii	dd dup
	dd dictflags
	dd lit, 0b010
	dd band
	dd gonz, innoin
	dd rot2
	dd ddrop
	dd jump
	dd goto, inmore
innoin	dd drop
	dd emits
	dd lit, intstr
	dd lit, 12
	dd emits
	dd abort

; ( flags str len -- fd )
; flags: 0 is read-only, 1 is write-only, 2 is read+write
DEFWORD open, 0b000, repl
	call enter
	dd swap
	dd dup
	dd rot
	dd plus
	dd lit, 0
	dd swap
	dd cput		; null the end of the path
	dd lit, 0	; dont specify mode
	dd rot2
	dd lit, 5	; open
	dd syscall
	dd exit

; ( fd -- )
badfd	db 'bad fd'
DEFWORD close, 0b000, open
	call enter
	dd lit, 6	; close
	dd ddup		; fill extra stuff with nonsense
	dd syscall
	dd gotz, clexit
	dd lit, badfd
	dd lit, 6
	dd emits
	dd abort
clexit	dd exit

; ( str len -- )
DEFWORD loadfrom, 0b000, close
	call enter
	dd lit, 0	; read-only
	dd rot2
	dd open
	dd lit, wordfd
	dd dput
	dd repl
	dd lit, wordfd
	dd dup
	dd dat
	dd close
	dd lit, 0
	dd swap
	dd dput
	dd exit

; ( -- )
DEFWORD load, 0b000, loadfrom
	call enter
	dd getword
	dd loadfrom
	dd exit

; ( n -- )
DEFWORD allochere, 0b000, load
	call enter
	dd lit, 0	; no offset
	dd lit, -1	; anonymous fd
	dd rot		; length
	dd lit, 34	; flags: private+anonymous
	dd lit, 7	; prot: read+write+execute
	dd rot		; still length
	dd lit, 0	; let kernel choose location
	dd lit, 192	; mmap2 (AAAAAAAAAAAAAAAAAA)
	dd syscall6
	dd lit, here
	dd dput
	dd exit

; ( n -- )
DEFWORD alloc, 0b000, allochere
	add [here], ebx
	pop ebx
	NEXT

; ( n -- )
DEFWORD dcom, ',', 0b000, alloc
	mov ecx, [here]
	mov [ecx], ebx
	add [here], dword 4
	pop ebx
	NEXT

; ( n -- )
DEFWORD ccom, 'c,', 0b000, dcom
	mov ecx, [here]
	mov [ecx], bl
	inc dword [here]
	pop ebx
	NEXT

; ( -- )
DEFWORD entercom, 'enter,', 0b000, ccom
	call enter
	dd lit, enter
	dd litd, here
	dd increment4
	dd minus
	dd dcom
	dd exit

; ( -- )
semicol	db ';'
DEFWORD colres, ':rs', 0b000, entercom
	call enter
colmode	dd getword
	dd cdup
	dd gotz, colabrt
	dd ddup
	dd lit, semicol
	dd lit, 1
	dd streq
	dd gotz, colpw
	dd ddrop
	dd lit, exit
	dd dcom
	dd exit
colpw	dd ddup
	dd find
	dd cdup
	dd gonz, colgtw
	dd startsnum
	dd gotz, innonn
	dd parsenum
	dd lit, lit
	dd dcom
colwrd	dd dcom
	dd goto, colmode
colabrt	dd drop
	dd abort
colgtw	dd rot2
	dd ddrop
	dd dup
	dd dictflags
	dd lit, 0b100
	dd band
	dd gotz, colwrd
	dd jump
	dd goto, colmode

; ( -- )
DEFWORD colon, ':', 0b000, colres
	call enter
	dd dictcom
	dd lit, 0xe8
	dd ccom
	dd entercom
	dd colres
	dd exit

; ( -- )
DEFWORD create, 0b000, colon
	call enter
	dd dictcom
	dd lit, 2
	dd dictor
	dd exit

; ( -- )
DEFWORD immediate, 0b000, create
	push ebx
	xor ebx, ebx
	mov bl, 4
	jmp dictor

; ( -- )
rbrack	db ']'
DEFWORD bracket, '[', 0b100, immediate
	call enter
braloop	dd getword
	dd cdup
	dd gotz, colabrt
	dd ddup
	dd lit, rbrack
	dd lit, 1
	dd streq
	dd gotz, bracpw
	dd ddrop
	dd exit
bracpw	dd ddup
	dd find
	dd cdup
	dd gonz, bragtw
	dd startsnum
	dd gotz, innonn
	dd parsenum
	dd goto, braloop
bragtw	dd dup
	dd dictflags
	dd lit, 0b010
	dd band
	dd gonz, innoin
	dd rot2
	dd ddrop
	dd jump
	dd goto, braloop

; ( -- )
parenc	db ')'
DEFWORD paren, '(', 0b100, bracket
	call enter
parenl	dd getword
	dd cdup
	dd gotz, dbye
	dd lit, parenc
	dd lit, 1
	dd streq
	dd gotz, parenl
	dd exit

DEFWORD backslash, '\', 0b100, paren
	push ebx
	xor eax, eax
	mov ebx, [wordfd]
	mov ecx, wordbuf+255	; last char of wordbuf
	xor edx, edx
	inc edx
bsloo	mov al, 3	; read
	int 0x80
	cmp [ecx], byte `\n`
	je bsend
	cmp al, 1
	je bsloo
bsend	pop ebx
	NEXT

vstr	db 'vulpforth says h'
okstr	db ` ok\n`
DEFWORD init, 0b000, backslash
	call enter
	dd lit, okstr
	dd lit, 4
	dd emits
	dd repl
	dd bye
