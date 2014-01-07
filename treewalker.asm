; Description: call ftw() on a file path and return the directory structure
; Author: Bill Davis
; Prototype: struct data file_data[]* TreeWalker(const char* file_path)

; int ftw(
;	const char *dirpath,
;	int (*fn) (const char *fpath, const struct stat *sb, int typeflag),
;	int nopenfd);
; )

%define	MAX_OPEN_FILES 64			;more files = more memory, but faster ftw() speeds
%define SIZEOF_FILE_DATA_ELEMENT 12	;sizeof struct data{} (12 bytes)

[SECTION .bss]
source_file_path: 		resd 1	;const char* file_path
file_data_array_ptr:	resd 1	;struct data file_data[]*
file_data_array_size:	resd 1	;int file_data_array_size

; struct data {
;	const char *fpath
;	const struct stat *sb
;	int typeflag
; }

[SECTION .data]
;debug strings;
show_input_file_path: db "Checking directory structure: '%s'",10,0
show_current_file_array: db "DEBUG: file array ptr: %x  array size: %i",10,0
print_file_found:	db "Found: '%s' (size: UNKOWN bytes) (typeflag: %i)",10,0
printFTWComplete:	db "SUCCESS: directory structure scanned without errors! (files found: %i)",10,0

;error strings
calloc_error: db "ERROR: calloc() returned NULL.  Unable to allocate required memory!",10,0
printFTWError:	db "ERROR: file tree walker encountered a problem...",10,0

	
section .txt
	extern ftw
	extern printf
	
	extern calloc
	extern free

	global TreeWalker

TreeWalker:
	push ebp
	mov ebp,esp		;setup stack frame for function
	
	mov eax, [ebp+8]					;store const char* file_path in eax
	mov dword [source_file_path], eax	;save const char* file_path for later
	xor eax,eax							;clear eax

	mov dword [file_data_array_size], 0	;initialize file_data_array_size to zero
	mov dword [file_data_array_ptr], 0	;initialize file_data_array_ptr to null

	; let the user know we're starting to walk the directory
	push dword [source_file_path]
	push show_input_file_path
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
	push dword [file_data_array_size]
	push printFTWComplete
	call printf
	add esp,8
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
	
	; display file path, size, and typeflag
	push dword [ebp+16]		;typeflag
	push dword [ebp+8]		;path
	push print_file_found
	call printf
	add esp,12
	
	; increment size and allocate new file_data[] with calloc
	inc dword [file_data_array_size]
	
	; void *calloc(size_t nmemb, size_t size);
	push dword SIZEOF_FILE_DATA_ELEMENT
	push dword [file_data_array_size]
	call calloc
	add esp,8
	
	;EAX = void *ptr to new array memory address
	;check if calloc returned NULL
	cmp eax, 0
	je .callback_calloc_error
	
	push eax	;save EAX

	;debug: print the returned ptr and array size
	push dword [file_data_array_size]
	push esi
	push show_current_file_array
	call printf
	add esp, 12
	
	pop eax		;restore EAX
	
	; get previous file_data[] if available
	; copy previous file_data[] elements to new file_data[]
	; add new data from this callback

	; free the memory allocated by calloc
	; void free(void *ptr)
	push eax
	call free
	add esp,4

	mov eax,0
	jmp .callback_exit
	
.callback_calloc_error:
	push calloc_error	;print error message
	call printf
	add esp, 4
	
	mov eax, -1			;exit with error code (-1)

.callback_exit:
	leave
	ret