DEFWORD hexchr, 0b01, 0
	db '0123456789abcdef'

DEFWORD wordfd, 0b01, hexchr
	dd 0	; file descriptor to read words from

DEFWORD here, 0b01, wordfd
	dd defhere	; address of next unused memory

DEFWORD stackstart, 0b01, here
	dd 0	; address of start of working stack

DEFWORD latest, 0b01, stackstart
	dd init	; address of newest defined word
