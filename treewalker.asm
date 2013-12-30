	;; Runs the linux file tree walker
	;; and runs Hexdump comparison
section .data
debug:	db "File Tree Walking",10,0
printCompare:	db "I found a file!",10,0

printFTWComplete:	db "ftw is complete with no errors",10,0

printFTWError:	db "Error in the file tree walker",10,0

	
section .txt
	extern ftw
	extern printf

	global TreeWalker

	;; int TreeWalker(const char* fileName)
	;; return val of -1 = error
TreeWalker:
	push ebp
	mov ebp,esp

	push debug
	call printf
	add esp,4

	xor eax,eax

	;; call ftw()
	mov ebx, 100
	push ebx
	push dword [Compare]
	push dword [ebp+8]
	call ftw
	add esp, 12
	cmp eax, -1
	je .error

	push printFTWComplete
	call printf
	add esp,4
	
	jmp .exit

.error:
	push printFTWError
	call printf
	add esp,4

.exit:
	leave
	ret

Compare:
	push ebp
	mov ebp,esp

	push printCompare
	call printf
	add esp,4

	leave
	ret