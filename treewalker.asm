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
debug_show_current_path: db "Checking directory structure: '%s'",10,0
print_file_found:	db "Found: '%s' (typeflag: %i)",10,0
printFTWComplete:	db "SUCCESS: directory structure scanned without errors! (files found: %i)",10,0
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
	
	; display file path and typeflag
	push dword [ebp+16]
	push dword [ebp+8]
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
	mov dword [file_data_array_ptr],eax
	
	;temporary debug! free the memory!
	push dword [file_data_array_ptr]
	call free
	add esp,4
	mov dword [file_data_array_ptr], 0

	; get previous file_data[] if available
	; copy previous file_data[] elements to new file_data[]
	; add new data from this callback
	; free previous file_data[]'s memory

	mov eax,0
	leave
	ret