; Description: call ftw() on a file path and return the directory structure
; Author: Bill Davis
; Prototype: void TreeWalker(const char* file_path)

; int ftw(
;	const char *dirpath,
;	int (*fn) (const char *fpath, const struct stat *sb, int typeflag),
;	int nopenfd);
; )

[SECTION .bss]
file_path: resd 1	;const char* file_path 

[SECTION .data]
debug_show_current_path: db "Checking directory structure: '%s'",10,0
printCompare:	db "I found %s",10,0
printFTWComplete:	db "SUCCESS: directory structure scanned without errors!",10,0
printFTWError:	db "ERROR: file tree walker encountered a problem...",10,0

	
section .txt
	extern ftw
	extern printf

	global TreeWalker

TreeWalker:
	push ebp
	mov ebp,esp		;setup stack frame for function
	
	mov eax, [ebp+8]
	mov dword [file_path], eax	;save file path in global variable

	push dword [file_path]
	push debug_show_current_path
	call printf
	add esp,8

	xor eax,eax		;clear eax

	;; call ftw()
	mov ebx, 10
	push ebx
	push dword Compare
	push dword [file_path]
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

	push dword [ebp+12]
	push printCompare
	call printf
	add esp,8

	mov eax,0
	leave
	ret