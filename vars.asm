DEFWORD hexchr, 0b010, 0
	db '0123456789abcdef'

DEFWORD wordfd, 0b010, hexchr
	dd 0	; file descriptor to read words from

DEFWORD here, 0b010, wordfd
	dd 0	; address of next unused memory

DEFWORD stackstart, 0b010, here
	dd 0	; address of start of working stack

DEFWORD latest, 0b010, stackstart
	dd init	; address of newest defined word
