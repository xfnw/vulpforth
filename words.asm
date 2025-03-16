DEFWORD enter, 0b01, loaded
	PUSHRET esi	; save previous word in return stack
	pop esi		; grab new word pointer from call
%ifdef TRACE
	push ebx
	mov eax, 4		; write
	mov ebx, 2		; to stderr
	mov edx, retstack+retsz
	sub edx, ebp
	shr edx, 2
	and edx, 255
	mov ecx, angles+1
	sub ecx, edx
	int 0x80
	mov eax, 4
	lea ecx, [esi-10]	; offset to flags from call enter
	mov dl, [ecx]
	and edx, 0b00111111	; get length from flags
	sub ecx, edx		; get address of name
	int 0x80
	mov eax, 4
	mov ecx, nlstr
	mov edx, 1
	int 0x80
	pop ebx
%endif
	NEXT

DEFWORD return, 0b00, enter
	POPRET esi	; switch to words at top of return stack
	NEXT

DEFWORD lit, 0b01, return
	push ebx	; make room in working stack
	lodsd		; grab next colon-word token
	xchg ebx, eax	; put it on the stack
	NEXT

DEFWORD litat, 'lit@', 0b01, lit
	push ebx
	lodsd
	mov ebx, [eax]	; same thing but dereferenced
	NEXT

DEFWORD litput, 'lit!', 0b01, litat
	lodsd
	mov [eax], ebx
	pop ebx
	NEXT

DEFWORD goto, 0b01, litput
	lodsd		; grab next colon-word token
	xchg esi, eax	; jump to it
	NEXT

DEFWORD gotz, 0b01, goto
	cmp ebx, 0	; check if top of stack is 0
	pop ebx		; consume it
	lodsd		; grab next colon-word token
	jnz notgon	; skip if not zero
	xchg esi, eax	; jump to it
notgon	NEXT

DEFWORD gonz, 0b01, gotz
	cmp ebx, 0	; check if top of stack is 0
	pop ebx		; consume it
	lodsd		; grab next colon-word token
	jz yesgon	; skip if zero
	xchg esi, eax	; jump to it
yesgon	NEXT

; ( a -- )
DEFWORD jump, 0b00, gonz
	xchg eax, ebx
	pop ebx
	jmp eax

; ( a b c -- b c a )
DEFWORD rot, 0b00, jump
	pop eax
	pop edx
	push eax
	push ebx
	xchg ebx, edx
	NEXT

; ( a b c -- c a b )
DEFWORD rot2, 'rot>', 0b00, rot
	pop eax
	pop edx
	push ebx
	push edx
	xchg ebx, eax
	NEXT

; ( a b -- a b a )
DEFWORD over, 0b00, rot2
	pop eax
	push eax
	push ebx
	xchg ebx, eax
	NEXT

; ( a b c -- a b c a )
DEFWORD dover, '2over', 0b00, over
	pop eax
	pop ecx
	push ecx
	push eax
	push ebx
	xchg ebx, ecx
	NEXT

; ( a -- )
DEFWORD drop, 0b00, dover
	pop ebx
	NEXT

; ( a a -- )
DEFWORD ddrop, '2drop', 0b00, drop
	pop ebx
	pop ebx
	NEXT

; ( a b -- b )
DEFWORD nip, 0b00, ddrop
	pop eax
	NEXT

; ( a b -- b a b )
DEFWORD tuck, 0b00, nip
	pop eax
	push ebx
	push eax
	NEXT

; ( a -- a a )
DEFWORD dup, 0b00, tuck
	push ebx
	NEXT

; ( a -- a a? )
DEFWORD cdup, '?dup', 0b00, dup
	cmp ebx, 0
	jz nodup
	push ebx
nodup	NEXT

; ( a b -- a b a b )
DEFWORD ddup, '2dup', 0b00, cdup
	pop eax
	push eax	; pop+push is smaller than a mov
	push ebx
	push eax
	NEXT

; ( a b -- b a )
DEFWORD swap, 0b00, ddup
	pop eax
	xchg ebx, eax
	push eax
	NEXT

; ( a b c d -- c d a b )
DEFWORD dswap, '2swap', 0b00, swap
	pop eax
	pop ecx
	pop edx
	push eax
	push ebx
	push edx
	xchg ebx, ecx
	NEXT

; ( a -- stack[a] )
DEFWORD nth, 0b00, dswap
	mov ebx, [esp+ebx*4]
	NEXT

; ( arg3 arg2 arg1 num -- res )
; note that the 4 stack items will still be consumed even
; if the syscall takes less than 3 args.
DEFWORD syscall, 0b00, nth
	xchg eax, ebx	; get syscall number from top of stack
	pop ebx		; syscall args
	pop ecx
	pop edx
	int 0x80	; syscall
	xchg ebx, eax	; put return value at our top of stack
	NEXT

; ( arg6 arg5 arg4 arg3 arg2 arg1 num -- res )
DEFWORD syscall6, 0b00, syscall
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
DEFWORD lshift, 0b00, syscall6
	pop ecx
	xchg ebx, ecx
	shl ebx, cl
	NEXT

; ( a b -- a>>b )
DEFWORD rshift, 0b00, lshift
	pop ecx
	xchg ebx, ecx
	shr ebx, cl
	NEXT

; ( a b -- a&b )
DEFWORD band, 'and', 0b00, rshift
	pop eax
	and ebx, eax
	NEXT

; ( a b -- a|b )
DEFWORD bor, 'or', 0b00, band
	pop eax
	or ebx, eax
	NEXT

; ( a b -- a^b )
DEFWORD bxor, 'xor', 0b00, bor
	pop eax
	xor ebx, eax
	NEXT

; ( a -- !a )
DEFWORD lnot, 'not', 0b00, bxor
	xchg eax, ebx
	xor ebx, ebx
	cmp eax, 0
	jnz lnotz
	inc ebx
lnotz	NEXT

; ( a -- ~a )
DEFWORD bnot, '~', 0b00, lnot
	not ebx
	NEXT

; ( a b -- a+b )
DEFWORD plus, '+', 0b00, bnot
	pop eax
	add ebx, eax
	NEXT

; ( a b -- b-a )
DEFWORD minusinv, '-^', 0b00, plus
	pop eax
	sub ebx, eax
	NEXT

; ( a -- a+1 )
DEFWORD increment, '1+', 0b00, minusinv
	add ebx, 1
	NEXT

; ( a -- a-1 )
DEFWORD decrement, '1-', 0b00, increment
	sub ebx, 1
	NEXT

; ( a -- a+4 )
DEFWORD increment4, '4+', 0b00, decrement
	add ebx, 4
	NEXT

; ( a -- a-4 )
DEFWORD decrement4, '4-', 0b00, increment4
	sub ebx, 4
	NEXT

; ( a b -- a-b )
DEFWORD minus, '-', 0b00, decrement4
	pop eax
	xchg ebx, eax
	sub ebx, eax
	NEXT

; ( a b -- a*b )
DEFWORD mulsigned, '*', 0b00, minus
	pop eax
	imul ebx, eax
	NEXT

; ( a b -- a%b a/b )
DEFWORD divmod, '/mod', 0b00, mulsigned
	pop eax
	xor edx, edx
	div ebx
	push edx
	xchg ebx, eax
	NEXT

; ( a -- -a )
DEFWORD negate, 'neg', 0b00, divmod
	neg ebx
	NEXT

; ( a -- a>>31 )
DEFWORD isneg, '?neg', 0b00, negate
	shr ebx, 31
	NEXT

; ( a -- |a| )
DEFWORD absv, 'abs', 0b00, isneg
	test ebx, 1<<31
	jz alrpos
	neg ebx
alrpos	NEXT

; ( -- waddr wsize )
DEFWORD getword, 'word', 0b00, absv
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
DEFWORD string, '"', 0b00, getword
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
DEFWORD emit, 0b00, string
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

DEFWORD spc, 0b00, emit
	call enter
	dd lit, ' '
	dd emit
	dd return

DEFWORD nl, 0b00, spc
	call enter
	dd lit, `\n`
	dd emit
	dd return

; ( str len -- )
DEFWORD emits, 0b00, nl
	call enter
	dd swap
	dd lit, 1
	dd lit, 4
	dd syscall
	dd drop
	dd return

; ( addr -- c )
DEFWORD cat, 'c@', 0b00, emits
	mov bl, [ebx]
	and ebx, 0xff
	NEXT

; ( c addr -- )
DEFWORD cput, 'c!', 0b00, cat
	pop eax
	mov [ebx], al
	pop ebx
	NEXT

; ( addr -- a )
DEFWORD dat, '@', 0b00, cput
	mov ebx, [ebx]
	NEXT

; ( a addr -- )
DEFWORD dput, '!', 0b00, dat
	pop eax
	mov [ebx], eax
	pop ebx
	NEXT

; ( c -- )
DEFWORD printhexc, '.xc', 0b00, dput
	call enter
	dd lit, 0xf
	dd band
	dd lit, hexchr
	dd plus
	dd cat
	dd emit
	dd return
	
; ( c -- )
DEFWORD printhex1, '.x1', 0b00, printhexc
	call enter
	dd dup
	dd lit, 4
	dd rshift
	dd printhexc
	dd printhexc
	dd return

; ( s -- )
DEFWORD printhex2, '.x2', 0b00, printhex1
	call enter
	dd dup
	dd lit, 8
	dd rshift
	dd printhex1
	dd printhex1
	dd return

; ( a -- )
DEFWORD printhex, '.x', 0b00, printhex2
	call enter
	dd dup
	dd lit, 16
	dd rshift
	dd printhex2
	dd printhex2
	dd return

; ( c -- )
DEFWORD print, '.', 0b00, printhex
	call enter
	dd lit, 10
	dd swap
	dd dup
	dd isneg
	dd gotz, pnotn
	dd lit, '-'
	dd emit
	dd absv
pnotn	dd lit, 10
	dd divmod
	dd cdup
	dd gonz, pnotn
pprint	dd lit, 0x30
	dd plus
	dd emit
	dd dup
	dd lit, 10
	dd eq
	dd gotz, pprint
	dd drop
	dd return

; ( a b -- a==b )
DEFWORD eq, '=', 0b00, print
	pop eax
	xchg edx, ebx
	xor ebx, ebx
	cmp eax, edx
	jne eqneq
eqieq	inc ebx
eqneq	NEXT

; ( a b -- a>b )
DEFWORD gt, '>', 0b00, eq
	pop eax
	xchg edx, ebx
	xor ebx, ebx
	cmp eax, edx
	jg eqieq
	NEXT

; ( m1 m2 len -- m1==m2 )
DEFWORD memeq, 'mem=', 0b00, gt
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
DEFWORD memcpy, 0b00, memeq
	pop ecx
	pop eax
memcl	mov dl, [eax+ecx-1]
	mov [ebx+ecx-1], dl
	loop memcl
	pop ebx
	NEXT

; ( str len -- )
DEFWORD strcom, 'str,', 0b00, memcpy
	call enter
	dd dup
	dd rot2
	dd litat, here
	dd memcpy
	dd allot
	dd return

; ( str1 len1 str2 len2 -- str1==str2 )
DEFWORD streq, 'str=', 0b00, strcom
	call enter
	dd rot
	dd over
	dd eq
	dd gotz, nstreq
	dd memeq
	dd return
nstreq	dd ddrop
	dd drop
	dd lit, 0
	dd return

; ( addr -- str len )
DEFWORD dictname, 0b00, streq
	call enter
	dd lit, 5
	dd minus
	dd dup
	dd cat
	dd lit, 0b00111111
	dd band
	dd tuck
	dd minus
	dd swap
	dd return

; ( addr -- addr )
DEFWORD dictprev, 0b00, dictname
	call enter
	dd decrement4
	dd dat
	dd return

; ( addr -- flags )
DEFWORD dictflags, 0b00, dictprev
	call enter
	dd lit, 5
	dd minus
	dd cat
	dd lit, 6
	dd rshift
	dd return

; ( flags -- )
DEFWORD dictor, 0b00, dictflags
	mov eax, [latest]
	shl ebx, 6
	or [eax-5], bl
	pop ebx
	NEXT

; ( -- )
DEFWORD dictcom, ':code', 0b00, dictor
	call enter
	dd getword
	dd cdup
	dd gotz, colabrt
	dd dup
	dd rot2
	dd strcom
	dd lit, 0b00111111
	dd band
	dd ccom
	dd litat, latest
	dd dcom
	dd litat, here
	dd litput, latest
	dd return

; ( -- )
DEFWORD endcode, ';code', 0b00, dictcom
	call enter
	dd lit, 0xad
	dd ccom
	dd lit, 0xff
	dd ccom
	dd lit, 0xe0
	dd ccom
	dd return

; ( -- )
DEFWORD words, 0b00, endcode
	call enter
	dd litat, latest
wdsloop	dd dup
	dd dictname
	dd emits
	dd spc
	dd dictprev
	dd cdup
	dd gonz, wdsloop
	dd nl
	dd return

; ( str len -- addr )
DEFWORD find, 0b00, words
	call enter
	dd litat, latest
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
	dd return

; ( -- addr )
DEFWORD wordaddr, `'`, 0b00, find
	call enter
	dd getword
	dd ddup
	dd find
	dd cdup
	dd gotz, innonn
	dd rot2
	dd ddrop
	dd return

; ( -- b )
DEFWORD wordchar, `''`, 0b00, wordaddr
	call enter
	dd getword
	dd gotz, wnowc
	dd cat
wnowc	dd return

; ( addr len -- )
DEFWORD wdump, 0b00, wordchar
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
	dd return

; ( -- h )
DEFWORD stackheight, 0b00, wdump
	mov eax, esp
	push ebx
	mov ebx, [stackstart]
	sub ebx, eax
	shr ebx, 2
	NEXT

; ( -- p )
DEFWORD stackpos, 0b00, stackheight
	mov eax, esp
	push ebx
	xchg ebx, eax
	NEXT

DEFWORD printstack, '.S', 0b00, stackpos
	call enter
	dd stackheight
	dd stackpos
	dd swap
	dd wdump
	dd nl
	dd return

DEFWORD bye, 0b00, printstack
	call enter
	dd lit, 0 ; success
	dd lit, 1 ; nr_exit
	dd syscall

abrtstr	db ' '
DEFWORD abort, 0b00, bye
	call enter
	dd lit, abrtstr
	dd lit, 6
	dd emits
	dd restart

; ( a -- a )
DEFWORD cabort, '?abort', 0b00, abort
	cmp ebx, 0
	jz abort
	NEXT

; ( str len -- str len b )
DEFWORD startsnum, '?num', 0b00, cabort
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
DEFWORD parsenum, 0b00, startsnum
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
DEFWORD chkstack, 0b00, parsenum
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
okstr	db ' ok'
nlstr	db `\n`
DEFWORD repl, 0b00, chkstack
	call enter
inmore	dd getword
	dd ddup
	dd dup
	dd gonz, innote
	dd ddrop
	dd ddrop
	dd return
innote	dd find
	dd cdup
	dd gonz, incii
	dd startsnum
	dd gotz, innonn
	dd parsenum
	dd goto, inndok
innonn	dd emits
	dd lit, wnfstr
	dd lit, 15
	dd emits
	dd abort
incii	dd dup
	dd dictflags
	dd lit, 0b01
	dd band
	dd gonz, innoin
	dd rot2
	dd ddrop
	dd jump
inndok	dd chkstack
	dd litat, wordfd
	dd gonz, inmore
	dd lit, wordbuf
	dd lit, wordlen
	dd cat
	dd plus
	dd cat
	dd lit, 0x20
	dd eq
	dd gonz, inmore
	dd lit, okstr
	dd lit, 4
	dd emits
	dd goto, inmore
innoin	dd drop
	dd emits
	dd lit, intstr
	dd lit, 12
	dd emits
	dd abort

; ( flags str len -- fd )
; flags: 0 is read-only, 1 is write-only, 2 is read+write
DEFWORD open, 0b00, repl
%ifdef ZIPAPP
	push ebx
	call zipfd_open
	add esp, 4*3	; throw away stack items fed to c
	xchg ebx, eax
	NEXT
%else
	call enter
	dd swap
	dd dup
	dd rot
	dd plus
	dd lit, 0
	dd swap
	dd cput		; null the end of the path
	dd lit, 420	; mode 644
	dd rot2
	dd lit, 5	; open
	dd syscall
	dd return
%endif

; ( fd -- )
badfd	db 'bad fd'
DEFWORD close, 0b00, open
	call enter
	dd lit, 6	; close
	dd ddup		; fill extra stuff with nonsense
	dd syscall
	dd gotz, clexit
	dd lit, badfd
	dd lit, 6
	dd emits
	dd abort
clexit	dd return

; ( str len -- )
DEFWORD loadfrom, 0b00, close
	call enter
	dd lit, 0	; read-only
	dd rot2
	dd open
	dd litput, wordfd
	dd repl
	dd litat, wordfd
	dd close
	dd lit, 0
	dd litput, wordfd
	dd return

; ( -- )
DEFWORD load, 0b00, loadfrom
	call enter
	dd getword
	dd loadfrom
	dd return

freestr	db ` bytes`
DEFWORD free, 0b00, load
	call enter
	dd litat, hereend
	dd litat, here
	dd minus
	dd print
	dd lit, freestr
	dd lit, 6
	dd emits
	dd return

; ( n -- )
DEFWORD newhere, 0b00, free
	call enter
	dd dup
	dd lit, 0	; no offset
	dd lit, -1	; anonymous fd
	dd rot		; length
	dd lit, 34	; flags: private+anonymous
	dd lit, 7	; prot: read+write+execute
	dd rot		; still length
	dd lit, 0	; let kernel choose location
	dd lit, 192	; mmap2 (AAAAAAAAAAAAAAAAAA)
	dd syscall6
	dd dup
	dd litput, here
	dd plus
	dd litput, hereend
	dd return

; ( n -- )
DEFWORD allot, 0b00, newhere
	add [here], ebx
	pop ebx
	NEXT

; ( n -- )
DEFWORD dcom, ',', 0b00, allot
	mov ecx, [here]
	mov [ecx], ebx
	add [here], dword 4
	pop ebx
	NEXT

; ( n -- )
DEFWORD ccom, 'c,', 0b00, dcom
	mov ecx, [here]
	mov [ecx], bl
	inc dword [here]
	pop ebx
	NEXT

; ( -- )
DEFWORD entercom, 'enter,', 0b00, ccom
	call enter
	dd lit, enter
	dd litat, here
	dd increment4
	dd minus
	dd dcom
	dd return

; ( -- )
semicol	db ';'
DEFWORD colres, ':rs', 0b00, entercom
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
	dd lit, return
	dd dcom
	dd return
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
	dd lit, 0b10
	dd band
	dd gotz, colwrd
	dd jump
	dd goto, colmode

; ( -- )
DEFWORD colon, ':', 0b00, colres
	call enter
	dd dictcom
	dd lit, 0xe8
	dd ccom
	dd entercom
	dd colres
	dd return

; ( -- )
DEFWORD create, 0b00, colon
	call enter
	dd dictcom
	dd lit, 1
	dd dictor
	dd return

; ( -- )
DEFWORD immediate, 0b00, create
	push ebx
	xor ebx, ebx
	mov bl, 2
	jmp dictor

; ( -- )
rbrack	db ']'
DEFWORD bracket, '[', 0b10, immediate
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
	dd return
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
	dd lit, 0b01
	dd band
	dd gonz, innoin
	dd rot2
	dd ddrop
	dd jump
	dd goto, braloop

; ( -- )
parenc	db ')'
DEFWORD paren, '(', 0b10, bracket
	call enter
parenl	dd getword
	dd cdup
	dd gotz, dbye
	dd lit, parenc
	dd lit, 1
	dd streq
	dd gotz, parenl
	dd return

DEFWORD backslash, '\', 0b10, paren
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

DEFWORD require, 0b00, backslash
	call enter
	dd litat, loaded
	dd getword
	dd cabort
reqlt	dd rot
	dd cdup
	dd gotz, reqgot
	dd rot2
	dd ddup
	dd lit, 4
	dd nth
	dd dictname
	dd streq
	dd dswap
	dd swap
	dd dictprev
	dd swap
	dd dswap
	dd gotz, reqlt
	dd ddrop
	dd drop
	dd return
reqgot	dd ddup
	dd strcom
	dd dup
	dd ccom
	dd litat, loaded
	dd dcom
	dd litat, here
	dd litput, loaded
	dd lit, 0
	dd rot2
	dd open
	dd litat, wordfd
	dd swap
	dd dup
	dd litput, wordfd
	dd repl
	dd close
	dd litput, wordfd
	dd return

nohere	db 'saving allocations not supported'
vimgh	db 'VULPIMG'
	dd defhere
	db loaded-here+4
	dd here
	dd init
vimgl	equ $ - vimgh
DEFWORD save, 0b00, require
	call enter
	dd litat, hereend
	dd lit, retstack
	dd eq
	dd gonz, sdhere
	dd lit, nohere
	dd lit, 32
	dd emits
	dd abort
sdhere	dd lit, 577	; O_WRONLY|O_CREAT|O_TRUNC
	dd getword
	dd open
	dd dup
	dd lit, vimgl
	dd lit, vimgh
	dd rot
	dd lit, 4
	dd syscall
	dd drop
	dd dup
	dd lit, loaded-here+4	; length of useful vars
	dd lit, here		; start of useful vars
	dd rot
	dd lit, 4		; write
	dd syscall
	dd drop
	dd dup
	dd lit, defhere
	dd dup
	dd litat, here
	dd minusinv
	dd swap
	dd rot
	dd lit, 4
	dd syscall
	dd drop
	dd close
	dd return

bmagic	db 'bad magic'
DEFWORD restore, 0b00, save
	call enter
	dd lit, 0	; read only
	dd getword
	dd open
	dd dup
	dd lit, vimgl
	dd litat, here
	dd rot
	dd lit, 3	; read
	dd syscall
	dd drop
	dd lit, vimgh
	dd litat, here
	dd lit, vimgl
	dd memeq
	dd gonz, resg
	dd close
	dd lit, bmagic
	dd lit, 9
	dd emits
	dd abort
resg	dd dup
	dd lit, loaded-here+4	; length of useful vars
	dd lit, here		; start of useful vars
	dd rot
	dd lit, 3		; read
	dd syscall
	dd drop
	dd dup
	dd lit, retstack-defhere
	dd lit, defhere
	dd rot
	dd lit, 3
	dd syscall
	dd drop
	dd close
	dd return

DEFWORD init, 0b00, restore
	call enter
	dd chkstack
	dd lit, okstr
	dd lit, 4
	dd emits
	dd repl
	dd bye
