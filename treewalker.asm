; Description: call ftw() on a file path and return the directory structure
; Author: Bill Davis
; Prototype: void TreeWalker(const char* file_path)

section .data
debug_show_current_path: db "Checking directory structure: %s",10,0
printCompare:	db "I found a file!",10,0
printFTWComplete:	db "SUCCESS: file tree walker completed without errors!",10,0
printFTWError:	db "ERROR: file tree walker encountered a problem...",10,0

	
section .txt
	extern ftw
	extern printf

	global TreeWalker

TreeWalker:
	push ebp
	mov ebp,esp

	push dword [ebp+8]
	push debug_show_current_path
	call printf
	add esp,8

	xor eax,eax

	;; call ftw()
	mov ebx, 100
	push ebx
	push dword [Compare]
	push dword [ebp+4]
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