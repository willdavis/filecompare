; Description: call ftw() on a file path and return the directory structure
; Author: Bill Davis
; Prototype: struct file_list* TreeWalker(const char* file_path)

; struct file_list {
;	struct file_list* next
;	const char *fpath
;	int typeflag
; }

; int ftw(
;	const char *dirpath,
;	int (*fn) (const char *fpath, const struct stat *sb, int typeflag),
;	int nopenfd);
; )

%define	MAX_OPEN_FILES 64		;more files = more memory, but faster ftw() speeds
%define SIZEOF_file_list 12		;file_list structure size in bytes

[SECTION .bss]
source_file_path: 	resd 1	;const char* file_path
file_list:			resd 1	;file_list* start_node
file_list_size:		resd 1	;int file_list_size

[SECTION .data]
;debug strings;
print_source_file_path: db "Checking directory structure: '%s'",10,0
print_file_list: 		db "DEBUG: file list pointer: %x  list size: %i",10,0
print_file_found:		db "Found: '%s' (size: UNKOWN bytes) (typeflag: %i)",10,0
print_ftw_success:		db "SUCCESS: directory structure scanned! (files found: %i)",10,0

;error strings
print_malloc_error: 	db "ERROR: malloc() returned NULL.  Unable to allocate required memory!",10,0
print_ftw_error:		db "ERROR: file tree walker encountered a problem...",10,0
	
section .txt
	extern ftw
	extern printf
	
	extern malloc
	extern free

	global TreeWalker

TreeWalker:
	push ebp
	mov ebp,esp		;setup stack frame for function
	
	mov eax, [ebp+8]					;store const char* file_path in eax
	mov dword [source_file_path], eax	;save const char* file_path for later
	xor eax,eax							;clear eax

	mov dword [file_list], 0		;initialize file list pointer to NULL
	mov dword [file_list_size], 0	;initialize file list size to zero

	; let the user know we're starting to walk the directory
	push dword [source_file_path]
	push print_source_file_path
	call printf
	add esp,8

	;; call ftw()
	; int ftw(
	;	const char *dirpath,
	;	int (*fn) (const char *fpath, const struct stat *sb, int typeflag),
	;	int nopenfd);
	; )
	push dword MAX_OPEN_FILES
	push dword callback
	push dword [source_file_path]
	call ftw
	add esp, 12
	
	; check for any errors in the ftw() call
	; error code is returned in EAX register
	cmp eax, -1
	je .error

	; yay! no errors.  let the user know and then exit.
	push dword [file_list_size]
	push print_ftw_success
	call printf
	add esp,8
	
	mov eax, dword [file_list]
	jmp .exit

.error:
	; errors were present.  warn the user and then exit.
	push print_ftw_error
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
	
	inc dword [file_list_size]	;increment the list size
	
	; allocate memory for new file_list structure
	push dword SIZEOF_file_list
	call malloc		;void *malloc(size_t size);
	add esp,4
	
	;EAX = void *ptr to new array memory address
	;check if malloc returned NULL
	cmp eax, 0
	je .callback_malloc_error
	
	;save root file_list* node to file_list->next [eax]
	mov edx, dword [file_list]
	mov dword [eax], edx
	
	;save const char *fpath to file_list->fpath [eax+4]
	mov ebx, dword [ebp+8]
	mov dword [eax+4], ebx
	
	;save int typeflag to file_list->typeflag [eax+8]
	mov ecx, dword [ebp+16]
	mov dword [eax+8], ecx
	
	;set the new node as the root node
	mov dword [file_list], eax
	
	; display file path, size, and typeflag
	push dword [eax+8]		;typeflag
	push dword [eax+4]		;path
	push print_file_found
	call printf
	add esp,12

	;debug: print the returned ptr and array size
	push dword [file_list_size]
	push dword [file_list]
	push print_file_list
	call printf
	add esp, 12

	mov eax,0
	jmp .callback_exit
	
.callback_malloc_error:
	push print_malloc_error	;print error message
	call printf
	add esp, 4
	
	mov eax, -1			;exit with error code (-1)

.callback_exit:
	leave
	ret