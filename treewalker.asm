; Description: call ftw() on a file path and return the directory structure
; Author: Bill Davis
; Prototype: void TreeWalker(const char* file_path)

; int ftw(
;	const char *dirpath,
;	int (*fn) (const char *fpath, const struct stat *sb, int typeflag),
;	int nopenfd);
; )

[SECTION .bss]
source_file_path: resd 1	;const char* file_path 

[SECTION .data]
max_open_files: dd 20		; set maximum number of open files.

debug_show_current_path: db "Checking directory structure: '%s'",10,0
print_file_found:	db "Found: '%s' (typeflag: %i)",10,0
printFTWComplete:	db "SUCCESS: directory structure scanned without errors!",10,0
printFTWError:	db "ERROR: file tree walker encountered a problem...",10,0

	
section .txt
	extern ftw
	extern printf

	global TreeWalker

TreeWalker:
	push ebp
	mov ebp,esp		;setup stack frame for function
	
	mov eax, [ebp+8]					;store const char* file_path in eax
	mov dword [source_file_path], eax	;save const char* file_path for later
	xor eax,eax							;clear eax

	; let the user know we're starting to walk the directory
	push dword [source_file_path]
	push debug_show_current_path
	call printf
	add esp,8

	;; call ftw()
	; int ftw(
	;	const char *dirpath,
	;	int (*fn) (const char *fpath, const struct stat *sb, int typeflag),
	;	int nopenfd);
	; )
	push dword [max_open_files]
	push dword callback
	push dword [source_file_path]
	call ftw
	add esp, 12
	
	; check for any errors in the ftw() call
	; error code is returned in EAX register
	cmp eax, -1
	je .error

	; yay! no errors.  let the user know and then exit.
	push printFTWComplete
	call printf
	add esp,4
	jmp .exit

.error:
	; errors were present.  warn the user and then exit.
	push printFTWError
	call printf
	add esp,4

.exit:
	leave
	ret

; int (*fn) (const char *fpath, const struct stat *sb, int typeflag)
; [ebp+16] = int typeflag
; [ebp+12] = const struct stat *sb
; [ebp+8]  = const char *fpath
callback:
	push ebp
	mov ebp,esp
	
	; display file path and typeflag
	push dword [ebp+16]
	push dword [ebp+8]
	push print_file_found
	call printf
	add esp,12

	mov eax,0
	leave
	ret